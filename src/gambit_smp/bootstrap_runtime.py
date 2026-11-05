from gambit_smp.task_processes import run as _task_run
#!/usr/bin/env python3
"""Source-bound two-pass bootstrap in an isolated copy, never a release claim."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import shlex
import hashlib

from gambit_smp.framework import ROOT, available_processors, digest, execute, gnu_compiler
from gambit_smp.runtime_identity import check
from gambit_smp.source_binding import gc_table_snapshot, checked_negate_header_hash, ended_interrupt_source_hash, shared_pipe_source_hash, serialization_snapshot_source_hash, vector_increment_source_hash

GENERATED_REPAIR_SOURCE = {"gc_table_iteration": "lib/_system.c",
                          "gc_table_serialization": "lib/_system.c",
                          "ended_interrupt_lock": "lib/_thread.c",
                          "pipe_wait": "lib/_io.c",
                          "vector_increment_guard": "gsc/_prims.c"}


def generated_c(name):
    path = Path(name)
    return len(path.parts) == 2 and path.parts[0] in ("lib", "gsi", "gsc") and path.name.startswith("_") and path.suffix == ".c"


def seed_source_binding(runtime, identity, source_lock=None):
    if source_lock is None:
        if not identity.get("sourceRevision"):
            raise ValueError("seed identity has no revision; explicit versioned source lock required")
        return identity["sourceRevision"], {}
    from gambit_smp.source_materialize import locked_source
    lock_path = source_lock.resolve(strict=True)
    name = lock_path.relative_to(ROOT).as_posix()
    lock = json.loads(lock_path.read_text())
    with locked_source(ROOT, name) as (source, inputs):
        for path, row in lock["files"].items():
            if (digest(source / path) != row["candidateSha256"]
                    or digest(runtime / path) != row["candidateSha256"]):
                raise ValueError("bootstrap seed differs from locked candidate: " + path)
        if identity.get("sourceRevision", lock["revision"]) != lock["revision"]:
            raise ValueError("bootstrap seed revision conflicts with source lock")
    return lock["revision"], inputs


def compiler_binding(runtime, compiler):
    for directory in ("lib", "gsi", "gsc"):
        rows = re.findall(r"^C_COMPILER = (.+)$", (runtime / directory / "Makefile").read_text(), re.MULTILINE)
        if len(rows) != 1 or Path(rows[0]).resolve() != Path(compiler).resolve():
            raise ValueError("configured compiler differs from admitted GNU GCC")


def build_errors(output):
    # The upstream phase loop can mask an earlier recursive make failure.
    pattern = re.compile(r"(?:^|\n)(?:[^\n]*\*\*\*[^\n]*(?:Error|Stop\.)|[^\n]*(?:fatal error:|Segmentation fault|Bus error))")
    return [match.group(0).strip() for match in pattern.finditer(output)]


def object_compilation_observed(output, compilers):
    for line in output.splitlines():
        try:
            words = shlex.split(line)
        except ValueError:
            continue
        if words and words[0] in compilers and "-c" in words and "-o" in words:
            return True
    return False


def archive_members(path):
    names = _task_run(["ar", "t", str(path)], capture_output=True, check=True, timeout=10).stdout.decode().splitlines()
    if not names or len(names) != len(set(names)) or any(not name or name.startswith("-") or "/" in name for name in names):
        raise ValueError("archive members must have unique plain names")
    # Darwin ar lists its generated symbol index; its offsets are container
    # metadata, not an object member. Actual rebuilt binaries must still link.
    names = [name for name in names if name not in ("__.SYMDEF", "__.SYMDEF SORTED", "__.SYMDEF_64", "__.SYMDEF_64 SORTED")]
    if not names or any(not name.endswith(".o") for name in names):
        raise ValueError("runtime archive must contain object members")
    return {name: hashlib.sha256(_task_run(["ar", "p", str(path), name], capture_output=True,
                                                check=True, timeout=10).stdout).hexdigest() for name in names}


def repair_artifacts_rebuilt(model, artifacts, identity, compiler_work, archive_members_stable=False):
    if model == "checked_negate_return":
        return compiler_work
    if model == "vector_increment_guard":
        return (compiler_work and len(artifacts) == 3
                and artifacts["gscSha256"] != identity["gscSha256"]
                and artifacts["binarySha256"] == identity["binarySha256"]
                and archive_members_stable)
    return len(artifacts) == 3 and all(value != identity[key] for key, value in artifacts.items())


def generated_stamp(name, runtime, output):
    return (name == "include/stamp.h" and not (runtime / ".git").exists()
            and (runtime / name).read_bytes() == b"\n"
            and "Gambit is not being built from a Git clone. Creating empty stamp.h." in output)


def apply_source_patch(runtime, identity, patch, model="gc_table_iteration"):
    from gambit_smp.framework import apply_untracked_patch
    if model not in (*GENERATED_REPAIR_SOURCE, "checked_negate_return"):
        raise ValueError("source repair model has no audited binding")
    if model == "vector_increment_guard":
        expected = vector_increment_source_hash((runtime / "gsc/_prims.scm").read_bytes())
        hashes = apply_untracked_patch(runtime, patch.read_bytes(), {"gsc/_prims.scm"} & set(identity["sourceFiles"]))
        if hashes != {"gsc/_prims.scm": expected}:
            raise ValueError("vector increment patch changes more than the audited public delta guard")
        return hashes, {"publicIncrementFixnumGuard": True, "scope": "exact compiler expander delta; not semantic proof"}
    if model == "gc_table_serialization":
        expected = serialization_snapshot_source_hash((runtime / "lib/_system.scm").read_bytes())
        hashes = apply_untracked_patch(runtime, patch.read_bytes(), {"lib/_system.scm"} & set(identity["sourceFiles"]))
        if hashes != {"lib/_system.scm": expected}:
            raise ValueError("serializer patch changes more than its audited snapshot cursor and metadata")
        return hashes, {"rootedSerializationSnapshot": True, "scope": "exact serializer delta; not semantic proof"}
    if model == "pipe_wait":
        expected = shared_pipe_source_hash((runtime / "lib/_io.scm").read_bytes())
        hashes = apply_untracked_patch(runtime, patch.read_bytes(), {"lib/_io.scm"} & set(identity["sourceFiles"]))
        if hashes != {"lib/_io.scm": expected}:
            raise ValueError("pipe patch changes more than the audited endpoint mutex")
        return hashes, {"sharedEndpointPredicateMutex": True, "scope": "exact constructor change; not semantic proof"}
    if model == "ended_interrupt_lock":
        expected = ended_interrupt_source_hash((runtime / "lib/_thread.scm").read_bytes())
        hashes = apply_untracked_patch(runtime, patch.read_bytes(), {"lib/_thread.scm"} & set(identity["sourceFiles"]))
        if hashes != {"lib/_thread.scm": expected}:
            raise ValueError("interrupt patch changes more than the audited terminal branch")
        return hashes, {"endedTargetUnlock": True, "scope": "exact terminal branch; not semantic proof"}
    if model == "checked_negate_return":
        expected = checked_negate_header_hash((runtime / "include/gambit.h").read_bytes())
        hashes = apply_untracked_patch(runtime, patch.read_bytes(), {"include/gambit.h"} & set(identity["sourceFiles"]))
        if hashes != {"include/gambit.h": expected}:
            raise ValueError("checked-negation patch changes more than the audited branch")
        return hashes, {"checkedNegationReturn": True, "scope": "exact header branch; not semantic proof"}
    hashes = apply_untracked_patch(runtime, patch.read_bytes(), {"lib/_system.scm"} & set(identity["sourceFiles"]))
    if set(hashes) != {"lib/_system.scm"}:
        raise ValueError("table snapshot candidate must only change lib/_system.scm")
    binding = gc_table_snapshot((runtime / "lib/_system.scm").read_text())
    return hashes, binding


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--toolchain-receipt", type=Path, required=True)
    parser.add_argument("--source-lock", type=Path,
                        help="versioned source authority for sealed seed identities without revision")
    parser.add_argument("--gcc", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--timeout", type=float, required=True,
                        help="whole source-bootstrap budget, not a package performance gate")
    parser.add_argument("--target", choices=("from-scratch", "core"), default="from-scratch")
    parser.add_argument("--patch", type=Path)
    parser.add_argument("--model-receipt", type=Path)
    parser.add_argument("--support-model", nargs=2, action="append", default=[],
                        metavar=("MODEL", "RECEIPT"), help="required source-audited companion model proof")
    parser.add_argument("--patch-model", choices=(*GENERATED_REPAIR_SOURCE, "checked_negate_return"), default="gc_table_iteration")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("positive bootstrap budget required")
    if bool(args.patch) != bool(args.model_receipt) or (args.target == "core" and not args.patch):
        parser.error("source candidate core rebuild requires both patch and model receipt")
    required_support = ({"pipe_close_wait"} if args.patch_model == "pipe_wait" else
                        {"gc_table_iteration"} if args.patch_model == "gc_table_serialization" else set()) if args.patch else set()
    supplied_support = [model for model, _ in args.support_model]
    if set(supplied_support) != required_support or len(supplied_support) != len(set(supplied_support)):
        parser.error("source repair companion proofs do not match its audited obligations")
    runtime, out = args.runtime.resolve(), args.out.resolve()
    identity = json.loads(args.toolchain_receipt.read_text())
    check(runtime, identity)
    source_revision, seed_inputs = seed_source_binding(runtime, identity, args.source_lock)
    compiler, environment, version = gnu_compiler(args.gcc)
    compiler_binding(runtime, compiler)
    environment.pop("GAMBOPT", None)
    out.mkdir(parents=True, exist_ok=False)
    copy = out / "source"
    from gambit_smp.fixture_storage import source_capacity
    with source_capacity(copy):
        shutil.copytree(runtime, copy, symlinks=True, ignore=shutil.ignore_patterns(".git", ".hg"))
    check(copy, identity)
    patched_hashes, binding, proof_inputs, support = {}, None, [(ROOT / name, sha) for name, sha in seed_inputs.items()], {}
    if args.patch:
        from gambit_smp.check_gambit import MODELS, reuse_model_receipt
        case = next(c for c in json.loads((MODELS / "cases.json").read_text())["cases"]
                    if c["id"] == args.patch_model)
        reuse_model_receipt(args.model_receipt, case)
        proof_inputs.extend((path, digest(path)) for path in (args.patch, args.model_receipt, MODELS / (args.patch_model + ".qnt")))
        cases = {case["id"]: case for case in json.loads((MODELS / "cases.json").read_text())["cases"]}
        for model, receipt_name in args.support_model:
            model_receipt = Path(receipt_name)
            reuse_model_receipt(model_receipt, cases[model])
            model_path = MODELS / (model + ".qnt")
            proof_inputs.extend((path, digest(path)) for path in (model_receipt, model_path))
            support[model] = {"modelSha256": digest(model_path), "receiptSha256": digest(model_receipt)}
        patched_hashes, binding = apply_source_patch(copy, identity, args.patch, args.patch_model)
        # A copied generated file must not qualify as regeneration of the new SCM.
        if args.patch_model in GENERATED_REPAIR_SOURCE:
            (copy / GENERATED_REPAIR_SOURCE[args.patch_model]).unlink()
    shutil.copyfile(copy / "gsc/gsc", copy / "gsc-boot")
    compiler_only = bool(args.patch and args.patch_model == "vector_increment_guard")
    seed_archive = archive_members(runtime / "lib/libgambit.a") if compiler_only else None
    jobs = available_processors()
    receipt = {"schema": "gambit-two-pass-bootstrap.v1" if args.target == "from-scratch" else "gambit-source-core-candidate.v1", "status": "RUNNING",
               "seedReceiptSha256": digest(args.toolchain_receipt),
               "seedGscSha256": identity["gscSha256"], "sourceRevision": source_revision,
               "seedSourceInputs": seed_inputs,
               "processors": jobs, "processorSelection": "host-auto",
               "compiler": version.splitlines()[0], "wholeBootstrapBudget": args.timeout,
               "scope": "upstream two-pass bootstrap" if args.target == "from-scratch" else "isolated patched source core rebuild; not a complete bootstrap or native acceptance",
               "target": args.target, "sourceBinding": binding,
               "patchedSourceFiles": patched_hashes,
               "patchSha256": digest(args.patch) if args.patch else None,
               "repairModelReceiptSha256": digest(args.model_receipt) if args.model_receipt else None,
               "supportingModels": support,
               "forcedGeneratedSources": [GENERATED_REPAIR_SOURCE[args.patch_model]] if args.patch and args.patch_model in GENERATED_REPAIR_SOURCE else [],
               "artifactPolicy": "compiler-only-repair-new-gsc-unchanged-gsi-and-ordered-archive-members" if compiler_only else "installed-header-repair-binary-bytes-may-remain-identical" if args.patch and args.patch_model == "checked_negate_return" else "source-core-change-requires-new-artifacts",
               "steps": []}
    receipt_path = out / "receipt.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    metadata = {}
    code, output, timed_out, seconds = execute(["make", "-j" + str(jobs), args.target],
                                              copy, args.timeout, env=environment, metadata=metadata)
    (out / "bootstrap.log").write_text(output)
    receipt["steps"].append(dict(name=args.target, exit=code, timeout=timed_out,
                                seconds=round(seconds, 3), process=metadata))
    original_stable = all((runtime / name).is_file() and digest(runtime / name) == sha
                          for name, sha in identity["sourceFiles"].items())
    changed = [name for name, sha in identity["sourceFiles"].items()
               if not (copy / name).is_file() or digest(copy / name) != sha]
    metadata_changes = [name for name in changed if (copy / name).is_file() and generated_stamp(name, copy, output)]
    immutable_stable = all(generated_c(name) or name in metadata_changes
                           or (name in patched_hashes and (copy / name).is_file()
                               and digest(copy / name) == patched_hashes[name])
                           for name in changed)
    immutable_stable = immutable_stable and all((copy / name).is_file() and digest(copy / name) == sha
                                              for name, sha in patched_hashes.items())
    generated_present = all((copy / name).is_file() for name in identity["sourceFiles"] if generated_c(name))
    artifacts = {key: digest(copy / name) for key, name in (("binarySha256", "gsi/gsi"),
                 ("gscSha256", "gsc/gsc"), ("librarySha256", "lib/libgambit.a")) if (copy / name).is_file()}
    errors = build_errors(output)
    compiler_work = object_compilation_observed(output, {compiler, str(args.gcc.absolute())})
    rebuilt_archive = archive_members(copy / "lib/libgambit.a") if compiler_only and "librarySha256" in artifacts else None
    archive_stable = (compiler_only and digest(runtime / "lib/libgambit.a") == identity["librarySha256"]
                      and rebuilt_archive is not None and list(seed_archive.items()) == list(rebuilt_archive.items()))
    artifacts_rebuilt = not args.patch or repair_artifacts_rebuilt(args.patch_model, artifacts, identity, compiler_work, archive_stable)
    proof_stable = all(path.is_file() and digest(path) == sha for path, sha in proof_inputs)
    accepted = code == 0 and not timed_out and not errors and original_stable and immutable_stable and generated_present and len(artifacts) == 3 and artifacts_rebuilt and proof_stable
    receipt.update(status="PASS" if accepted else "DENY", originalSourceStable=original_stable,
                   immutableSourceStable=immutable_stable, changedSourceFiles=changed,
                   generatedSourcePresent=generated_present, artifacts=artifacts,
                   recursiveBuildErrors=errors, generatedMetadataChanges=metadata_changes,
                   artifactsRebuilt=artifacts_rebuilt, compilerWorkObserved=compiler_work,
                   repairProofInputsStable=proof_stable)
    if compiler_only:
        receipt.update(seedArchiveMembers=seed_archive, rebuiltArchiveMembers=rebuilt_archive,
                       archiveMembersStable=archive_stable)
    if accepted:
        rebuilt = dict(identity)
        rebuilt.update(artifacts)
        rebuilt["sourceFiles"] = {name: digest(copy / name) for name in identity["sourceFiles"]}
        rebuilt["build"] = "observed isolated " + args.target + " exit zero; source/artifact inventory bound"
        rebuilt["admission"] = "bootstrap candidate; complete native and Gerbil acceptance still required"
        rebuilt["bootstrapSeedReceiptSha256"] = digest(args.toolchain_receipt)
        if args.patch:
            rebuilt["patches"] = identity["patches"] + ["candidate-repair:" + args.patch.stem]
            rebuilt["modeledCases"] = sorted(set(identity["modeledCases"] + [args.patch_model] + list(support)))
            rebuilt["supportingModelReceipts"] = support
            rebuilt["candidatePatchSha256"] = digest(args.patch)
            rebuilt["repairModelReceiptSha256"] = digest(args.model_receipt)
            binding_key = {"checked_negate_return": "checkedNegationReturnBinding",
                           "gc_table_iteration": "gcTableSnapshotBinding",
                           "gc_table_serialization": "gcTableSerializationSnapshotBinding",
                           "vector_increment_guard": "vectorIncrementGuardBinding",
                           "pipe_wait": "sharedPipePredicateLockBinding",
                           "ended_interrupt_lock": "endedInterruptLockBinding"}[args.patch_model]
            rebuilt[binding_key] = binding
        (out / "candidate.json").write_text(json.dumps(rebuilt, indent=2) + "\n")
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    label = "BOOTSTRAP" if args.target == "from-scratch" else "CORE"
    print(f"{label}-{'PASS' if accepted else 'DENY'}; {seconds:.3f}s", flush=True)
    return 0 if accepted else 1


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('bootstrap')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('bootstrap', main))
