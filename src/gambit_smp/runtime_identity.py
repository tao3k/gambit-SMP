from gambit_smp.task_processes import run as _task_run
#!/usr/bin/env python3
"""Bind a locally rebuilt candidate; inventories do not prove generated-source parity."""
import argparse
import difflib
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from gambit_smp.framework import digest
from gambit_smp.source_unit import shutdown_function
from gambit_smp.source_binding import queue_acquire_handoff, postcopy_headroom

REPAIR_BINDINGS = {"ticket_queue_handoff": queue_acquire_handoff,
                   "gc_postcopy_headroom": postcopy_headroom}


def create(runtime, prior, unit, patch):
    identity = json.loads(prior.read_text())
    receipt = json.loads(unit.read_text())
    if receipt["status"] != "source-unit-pass" or not receipt["sourceStable"]:
        raise ValueError("shutdown source-unit admission required")
    source = (runtime / "lib/setup.c").read_text()
    guarded = "if (id == 0 && ___err != ___FIX(___NO_ERR) && ___GSTATE->setup_state != 2)"
    original = "if (id == 0 && ___err != ___FIX(___NO_ERR))"
    if source.count(guarded) != 1:
        raise ValueError("cleanup guard identity changed")
    reverse_hash = hashlib.sha256(source.replace(guarded, original).encode()).hexdigest()
    if reverse_hash != receipt["sourceSha256"] or reverse_hash != identity["sourceFiles"]["lib/setup.c"]:
        raise ValueError("source changed beyond the admitted cleanup guard")
    for name, expected in identity["sourceFiles"].items():
        if name != "lib/setup.c" and digest(runtime / name) != expected:
            raise ValueError("prior candidate source drift: " + name)
    pr793 = next(r for r in receipt["results"] if r["variant"] == "pr793")
    if hashlib.sha256(shutdown_function(source).encode()).hexdigest() != pr793["functionSha256"]:
        raise ValueError("runtime function differs from source-unit candidate")
    files = [p for folder in ("lib", "include", "gsi", "gsc") for p in (runtime / folder).iterdir()
             if p.is_file() and (p.suffix in (".c", ".h", ".scm") or p.name.endswith(".h.in") or p.name in ("Makefile", "config.h"))]
    identity["sourceFiles"] = {str(p.relative_to(runtime)): digest(p) for p in sorted(files)}
    identity.update(binarySha256=digest(runtime / "gsi/gsi"), gscSha256=digest(runtime / "gsc/gsc"),
                    librarySha256=digest(runtime / "lib/libgambit.a"))
    identity["patches"].append("candidate-pr793-processor-zero-cleanup-error-guard")
    identity["candidatePatchSha256"] = digest(patch)
    identity["sourceUnitReceiptSha256"] = digest(unit)
    identity["priorIdentitySha256"] = digest(prior)
    identity["build"] = "observed make -j12 core exit 0; GNU GCC 16.2.0; setup.o rebuilt and gsi/gsc relinked"
    identity["admission"] = "candidate-only; incremental rebuild and current input inventory, not generated-source parity or whole bootstrap"
    identity["shutdownProtocolScope"] = "PR793 cleanup guard only; not the modeled seal/drain design or unproved pre-cleanup dispatch repair"
    return identity


def check(runtime, identity):
    if any(digest(runtime / name) != expected for name, expected in identity["sourceFiles"].items()):
        raise ValueError("candidate input inventory changed")
    for field, name in (("binarySha256", "gsi/gsi"), ("gscSha256", "gsc/gsc"), ("librarySha256", "lib/libgambit.a")):
        if digest(runtime / name) != identity[field]:
            raise ValueError("candidate artifact changed: " + name)


def create_from_source_build(runtime, receipt_path, root):
    """Bind regenerated core artifacts, without claiming bootstrap or model admission."""
    receipt = json.loads(receipt_path.read_text())
    regenerated = receipt.get("sourceRegeneration", {})
    if (receipt.get("schema") != "gambit-locked-object.v1"
            or receipt.get("status") != "source-core-rebuilt"
            or receipt.get("contextStable") is not True
            or regenerated.get("scmRegenerationEstablished") is not True
            or regenerated.get("schemeInputsStable") is not True
            or regenerated.get("missingGeneratedSources")
            or regenerated.get("recursiveBuildErrors")
            or receipt.get("recursiveBuildErrors")):
        raise ValueError("stable regenerated source-core receipt required")
    stages = receipt.get("results", [])
    if ([row.get("stage") for row in stages] !=
            ["autoconf", "configure", "seed-core", "bootclean", "source-core"]
            or any(row.get("exit") != 0 or row.get("timeout") for row in stages)):
        raise ValueError("complete successful source-build stages required")
    flags = {"--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"}
    if not flags.issubset(stages[1]["argv"]):
        raise ValueError("all three concurrency configuration flags required")
    def bound(base, name, expected):
        path = Path(name)
        resolved = (base / path).resolve()
        if path.is_absolute() or ".." in path.parts or not resolved.is_relative_to(base.resolve()):
            raise ValueError("source-build binding escapes root")
        if digest(resolved) != expected:
            raise ValueError("source-build input drift: " + name)
    for name, expected in receipt["inputs"].items():
        bound(root, name, expected)
    lock = json.loads((root / receipt["sourceLock"]).read_text())
    bound(root, lock["patch"], lock["patchSha256"])
    for name, row in lock["files"].items():
        bound(runtime, name, row["candidateSha256"])
    for key in ("schemeInputs", "generatedHashes"):
        if not regenerated.get(key):
            raise ValueError("generated-source inventories required")
        for name, expected in regenerated[key].items():
            bound(runtime, name, expected)
    bound(runtime, "include/gambit.h", receipt["generatedHeaderSha256"])
    bound(runtime, "lib/makefile", receipt["configuredMakefileSha256"])
    artifacts = regenerated["artifacts"]
    if set(artifacts) != {"gsi/gsi", "gsc/gsc", "lib/libgambit.a"}:
        raise ValueError("all final linked artifacts required")
    for name, expected in artifacts.items():
        bound(runtime, name, expected)
    files = [p for folder in ("lib", "include", "gsi", "gsc")
             for p in (runtime / folder).iterdir() if p.is_file()
             and (p.suffix in (".c", ".h", ".scm") or p.name.endswith(".h.in")
                  or p.name.lower() == "makefile")]
    files.append(runtime / "configure.ac")
    return {"schema": "gambit-runtime-source-identity.v1",
            "sourceRevision": lock["revision"], "sourceLockSha256": digest(root / receipt["sourceLock"]),
            "sourceBuildReceiptSha256": digest(receipt_path),
            "sourceFiles": {p.relative_to(runtime).as_posix(): digest(p) for p in sorted(files)},
            "binarySha256": artifacts["gsi/gsi"], "gscSha256": artifacts["gsc/gsc"],
            "librarySha256": artifacts["lib/libgambit.a"],
            "multipleThreadedVms": True, "patches": [lock["patch"]], "modeledCases": [],
            "scmRegenerationEstablished": True, "fullTwoPassBootstrapEstablished": False,
            "runtimeAdmitted": False, "releaseAdmitted": False,
            "admission": "source-core identity only; native, composed-model and full bootstrap acceptance pending"}


def create_delta(runtime, prior, patch, repair_model=None, repair_case="ticket_queue_handoff"):
    """Reverse an exact source delta in isolation; reject all other input drift."""
    identity = json.loads(prior.read_text())
    patch_bytes = patch.read_bytes()
    stats = _task_run(["git", "--git-dir=/dev/null", "apply", "--numstat", "-z"], input=patch_bytes,
                           capture_output=True, check=True).stdout
    names = []
    for row in stats.decode().split("\0"):
        if not row:
            continue
        added, removed, name = row.split("\t", 2)
        path = Path(name)
        if (not added.isdecimal() or not removed.isdecimal() or path.is_absolute()
                or ".." in path.parts or name not in identity["sourceFiles"]
                or name in names):
            raise ValueError("delta requires unique existing inventory source files")
        if not (runtime / name).resolve().is_relative_to(runtime.resolve()):
            raise ValueError("source delta escapes runtime")
        names.append(name)
    if not names:
        raise ValueError("empty source delta")
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        for name in names:
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes((runtime / name).read_bytes())
        _task_run(["git", "apply", "--reverse", "--whitespace=error"],
                       input=patch_bytes, cwd=root, capture_output=True, check=True)
        for name, expected in identity["sourceFiles"].items():
            path = root / name if name in names else runtime / name
            if digest(path) != expected:
                raise ValueError("unadmitted source delta: " + name)
    identity["sourceFiles"] = {name: digest(runtime / name) for name in identity["sourceFiles"]}
    identity.update(binarySha256=digest(runtime / "gsi/gsi"),
                    gscSha256=digest(runtime / "gsc/gsc"),
                    librarySha256=digest(runtime / "lib/libgambit.a"),
                    priorIdentitySha256=digest(prior), candidatePatchSha256=digest(patch))
    if repair_model is None:
        identity["patches"] = identity["patches"] + ["diagnostic-only:" + patch.stem]
        identity["admission"] = "diagnostic-only; not a repair, stability or performance admission"
    else:
        from gambit_smp.check_gambit import reuse_model_receipt, MODELS
        if repair_case not in REPAIR_BINDINGS:
            raise ValueError("unsupported repair source binding")
        case = next(row for row in json.loads((MODELS / "cases.json").read_text())["cases"]
                    if row["id"] == repair_case)
        reuse_model_receipt(repair_model, case)
        if names != ["lib/mem.c"]:
            raise ValueError("GC candidate must only change lib/mem.c")
        binding = REPAIR_BINDINGS[repair_case]((runtime / "lib/mem.c").read_text())
        identity["queueAcquireBinding" if repair_case == "ticket_queue_handoff"
                 else "postcopyHeadroomBinding"] = binding
        identity["patches"] = identity["patches"] + ["candidate-repair:" + patch.stem]
        identity["admission"] = "candidate repair; bounded model and lexical binding, native and bootstrap acceptance pending"
        identity["repairModelReceiptSha256"] = digest(repair_model)
        identity["modeledCases"] = sorted(set(identity["modeledCases"] + [repair_case]))
    identity["build"] = "incremental core; rebuild exit status must be admitted separately"
    identity["diagnosticSourceFiles"] = names
    return identity


def export_observer_delta(runtime, prior, patch):
    source = (runtime / "lib/mem.c").read_text()
    baseline = source
    for token in ("#include <stdio.h>\n\n#define ___GC_TABLE_HEADER_DIAGNOSTICS\n",
                  '          gc_table_header_observe("scan-enter", body);\n',
                  '          gc_table_header_observe("scan-enqueue", body);\n',
                  '  gc_table_header_observe("rehash-enter", body);\n',
                  '      gc_table_header_observe("cleanup-dequeue", body);\n'):
        if baseline.count(token) != 1:
            raise ValueError("observer layout missing or ambiguous")
        baseline = baseline.replace(token, "")
    start = "#ifdef ___GC_TABLE_HEADER_DIAGNOSTICS\n"
    end = "#define gc_table_header_observe(stage, body) ((void)0)\n#endif\n\n\n"
    if baseline.count(start) != 1 or baseline.count(end) != 1:
        raise ValueError("observer helper boundary missing or ambiguous")
    left, right = baseline.index(start), baseline.index(end) + len(end)
    if left >= right:
        raise ValueError("observer helper boundaries out of order")
    baseline = baseline[:left] + baseline[right:]
    expected = json.loads(prior.read_text())["sourceFiles"]["lib/mem.c"]
    if hashlib.sha256(baseline.encode()).hexdigest() != expected:
        raise ValueError("observer delta does not recover the admitted prior source")
    if patch.exists():
        raise ValueError("refusing to overwrite diagnostic patch")
    patch.write_text("".join(difflib.unified_diff(baseline.splitlines(True),
                    source.splitlines(True), "a/lib/mem.c", "b/lib/mem.c")))


def export_source_delta(runtime, prior, patch, name, baseline):
    path = Path(name)
    inventory = json.loads(prior.read_text())["sourceFiles"]
    if (path.is_absolute() or ".." in path.parts or name not in inventory
            or not (runtime / name).resolve().is_relative_to(runtime.resolve())):
        raise ValueError("source delta must target an inventoried runtime file")
    if digest(baseline) != inventory[name]:
        raise ValueError("baseline does not match the admitted prior source")
    if patch.exists():
        raise ValueError("refusing to overwrite source delta")
    before, after = baseline.read_text(), (runtime / name).read_text()
    delta = "".join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                                      "a/" + name, "b/" + name))
    if not delta:
        raise ValueError("empty source delta")
    patch.write_text(delta)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--prior", type=Path)
    parser.add_argument("--source-unit", type=Path)
    parser.add_argument("--patch", type=Path)
    parser.add_argument("--check", type=Path)
    parser.add_argument("--source-build", type=Path,
                        help="bind final regenerated core from a locked-source build receipt")
    parser.add_argument("--diagnostic-delta", action="store_true")
    parser.add_argument("--repair-model", type=Path,
                        help="explicit repair delta with admitted TLC receipt")
    parser.add_argument("--repair-case", choices=sorted(REPAIR_BINDINGS), default="ticket_queue_handoff")
    parser.add_argument("--export-observer-delta", action="store_true")
    parser.add_argument("--export-source-delta")
    parser.add_argument("--baseline-source", type=Path)
    args = parser.parse_args()
    if args.source_build:
        if not args.out or args.out.exists():
            parser.error("fresh identity output required")
        identity = create_from_source_build(args.runtime, args.source_build, Path(__file__).resolve().parents[2])
        check(args.runtime, identity)
        args.out.write_text(json.dumps(identity, indent=2) + "\n")
    elif args.export_source_delta:
        if not all((args.prior, args.patch, args.baseline_source)):
            parser.error("prior, new patch and admitted baseline source required")
        export_source_delta(args.runtime, args.prior, args.patch,
                            args.export_source_delta, args.baseline_source)
    elif args.export_observer_delta:
        if not args.prior or not args.patch:
            parser.error("prior and new patch required")
        export_observer_delta(args.runtime, args.prior, args.patch)
    elif args.check:
        check(args.runtime, json.loads(args.check.read_text()))
    else:
        if not all((args.out, args.prior, args.patch)) or args.out.exists():
            parser.error("new output, prior identity, source-unit and patch required")
        if args.diagnostic_delta or args.repair_model:
            if args.diagnostic_delta and args.repair_model:
                parser.error("diagnostic and repair deltas are distinct")
            identity = create_delta(args.runtime, args.prior, args.patch, args.repair_model, args.repair_case)
        else:
            if not args.source_unit:
                parser.error("source-unit required for the cleanup guard")
            identity = create(args.runtime, args.prior, args.source_unit, args.patch)
        check(args.runtime, identity)
        args.out.write_text(json.dumps(identity, indent=2) + "\n")
    print("CANDIDATE-INVENTORY-OK")


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('identity')(main)

if __name__ == "__main__":
    main()
