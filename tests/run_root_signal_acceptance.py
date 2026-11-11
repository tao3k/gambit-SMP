"""Auditor's bounded before/after runner; never mutates the retained producer."""
import argparse
import json
import os
from pathlib import Path
import shutil
import time

from gambit_smp.framework import ROOT, available_processors, digest, execute, gnu_build_driver
from gambit_smp.suite_primitives import check_runtime


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--formal-receipt", type=Path, required=True)
    parser.add_argument("--dsl-log", type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    runtime = ROOT / ".cache/fixtures/abandonment-gc-publication-reader-repaired/run/source/source"
    identity_path = ROOT / ".cache/processor-interrupt-collective-wait/native/run/core/identity.json"
    identity = json.loads(identity_path.read_text())
    model = ROOT / "models/gambit/root_signal_retirement.qnt"
    program = ROOT / "models/gambit/native/root_signal_retirement.scm"
    patch = ROOT / "patches/candidates/root-signal-retirement.patch"
    formal = json.loads(args.formal_receipt.read_text())
    if not formal.get("accepted") or not formal.get("contextStable"):
        raise ValueError("current accepted formal receipt required before native execution")
    if formal["inputs"].get(str(model.relative_to(ROOT))) != digest(model):
        raise ValueError("formal receipt has a different model")
    if "\nOK\n" not in args.dsl_log.read_text():
        raise ValueError("successful declarative evidence test log required before native execution")
    check_runtime(runtime, identity)
    cpus = available_processors()
    if cpus < 2:
        raise ValueError("host-derived concurrent owner population required")
    env = dict(os.environ, PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
               GAMBIT_SMP_AVAILABLE_CPUS=str(cpus), GAMBIT_SMP_EXPECTED_PROCESSORS="1")
    started = time.monotonic()
    receipt = {"schema": "root-signal-native-comparison.v1", "status": "RUNNING",
               "scope": "research-registry-controls-real-SIGINT-not-whole-lifecycle",
               "availableProcessors": cpus, "bootstrapRepeated": False,
               "runtimeAdmitted": False, "releaseAdmitted": False, "commands": [],
               "inputs": {str(p.relative_to(ROOT)): digest(p) for p in
                          (identity_path, model, program, patch)},
               "formalReceiptSha256": digest(args.formal_receipt),
               "dslLogSha256": digest(args.dsl_log), "baselineIdentity": identity}
    journal = out / "receipt.json"

    def save():
        receipt["seconds"] = time.monotonic() - started
        journal.write_text(json.dumps(receipt, indent=2) + "\n")

    def run(name, argv, cwd, cap, expected=0, expected_output=None):
        # The campaign has one finite wall budget; individual caps never extend it.
        remaining = min(cap, 300 - (time.monotonic() - started))
        if remaining <= 0:
            raise ValueError("whole 300-second campaign budget exhausted")
        metadata = {}
        code, output, timeout, seconds = execute(argv, cwd, remaining, env, metadata)
        log = out / (name + ".log")
        log.write_text(output)
        row = dict(stage=name, argv=[str(x) for x in argv], cwd=str(cwd),
                   exit=code, timeout=timeout, seconds=seconds, budgetSeconds=remaining,
                   log=log.name, logSha256=digest(log), **metadata)
        receipt["commands"].append(row)
        save()
        if (code != expected or timeout or not metadata.get("processGroupQuiescent")
                or (expected_output is not None and output != expected_output)):
            raise ValueError(f"{name}: unexpected exit/output or nonquiescent process group")
        return output

    def fixture(name, tree, source, expected=0, marker=None):
        directory = out / name
        directory.mkdir()
        copied = directory / "fixture.scm"
        shutil.copy2(source, copied)
        env["GAMBOPT"] = (f"p1,~~lib={tree / 'lib'},~~bin={tree / 'bin'},"
                          f"~~include={tree / 'include'}")
        compiler = tree / "gsc/gsc"
        output = directory / "fixture"
        run(name + "-compile", [compiler, "-exe", "-o", output,
            "-cc-options", "-pthread", "-ld-options", "-pthread", copied], directory, 30)
        if digest(copied) != digest(source):
            raise ValueError("fixture bytes changed during compilation")
        receipt.setdefault("executables", {})[name] = {
            "sourceSha256": digest(copied), "executableSha256": digest(output)}
        run(name + "-execute", [output], directory, 15, expected, marker)

    try:
        save()
        compiler_path = next(line.split("=", 1)[1].strip() for line in
                             (runtime / "lib/Makefile").read_text().splitlines()
                             if line.startswith("C_COMPILER ="))
        gnu_build_driver(runtime, compiler_path)
        receipt["compilerSha256"] = digest(Path(compiler_path))
        run("compiler-version", [compiler_path, "--version"], ROOT, 10)
        fixture("baseline", runtime, program, expected=75,
                marker="ROOT-SIGNAL-CLOSED-TOUCH\n")
        repaired = out / "candidate-runtime"
        run("copy-checkpoint", ["/bin/cp", "-cR", runtime, repaired], ROOT, 30)
        check_runtime(repaired, identity)
        run("apply-repair", ["/usr/bin/patch", "--batch", "--fuzz=0", "-p1", "-i", patch], repaired, 10)
        allowed = {"lib/setup.c", "lib/os_setup.c"}
        changed = {name for name, sha in identity["sourceFiles"].items()
                   if digest(repaired / name) != sha}
        if changed != allowed:
            raise ValueError(f"unexpected repaired source inventory: {sorted(changed)}")
        source_expected = {name: digest(repaired / name) for name in identity["sourceFiles"]}
        run("incremental-library", ["make", "-C", repaired / "lib", "setup.o", "os_setup.o", "libgambit.a"], repaired, 90)
        run("link-gsi", ["make", "-C", repaired / "gsi", "gsi"], repaired, 30)
        run("link-gsc", ["make", "-C", repaired / "gsc", "gsc"], repaired, 30)
        candidate = dict(identity, sourceFiles=source_expected)
        for key, name in (("binarySha256", "gsi/gsi"), ("gscSha256", "gsc/gsc"),
                          ("librarySha256", "lib/libgambit.a")):
            candidate[key] = digest(repaired / name)
            if candidate[key] == identity[key]:
                raise ValueError("source repair did not reach linked artifact: " + name)
        check_runtime(repaired, candidate)
        receipt["repairedIdentity"] = candidate
        fixture("repaired", repaired, program, marker="ROOT-SIGNAL-RETIREMENT:PASS\n")
        fixture("external-producers", repaired,
                ROOT / "models/gambit/native/procedural_interrupt_retirement.scm",
                marker="PROCEDURAL-INTERRUPT-RETIREMENT:PASS\n")
        check_runtime(repaired, candidate)
        receipt["status"] = "PASS"
    except BaseException as error:
        receipt.update(status="FAIL", error=str(error))
        raise
    finally:
        try:
            check_runtime(runtime, identity)
            receipt["originalCheckpointUnchanged"] = True
        finally:
            save()
    print(json.dumps({"status": receipt["status"], "receipt": str(journal),
                      "seconds": receipt["seconds"]}))


if __name__ == "__main__":
    main()
