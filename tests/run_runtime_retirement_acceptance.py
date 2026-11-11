"""Bounded auditor integration: existing runtime branches, no bootstrap."""
import argparse
import json
import os
import re
from pathlib import Path
import shutil
import time

from gambit_smp.framework import ROOT, available_processors, digest, execute
from gambit_smp.suite_primitives import check_runtime


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--formal-receipt", type=Path, required=True)
    parser.add_argument("--dsl-log", type=Path, required=True)
    parser.add_argument("--mode-env", default="RUNTIME_RETIREMENT_MODE")
    args = parser.parse_args()
    parent = ROOT / "evidence/source-results/root-signal-retirement/comparison/receipt.json"
    inherited = json.loads(parent.read_text())
    assert inherited["status"] == "PASS"
    baseline = ROOT / ".cache/processor-interrupt-collective-wait/root-signal-acceptance-01/candidate-runtime"
    old_identity = inherited["repairedIdentity"]
    check_runtime(baseline, old_identity)
    model = ROOT / "models/gambit/runtime_retirement_quarantine.qnt"
    join_program = ROOT / "models/gambit/native/runtime_join_quarantine.scm"
    drain_program = ROOT / "models/gambit/native/terminal_registry_drain.scm"
    patch = ROOT / "patches/candidates/runtime-retirement-observation.patch"
    formal = json.loads(args.formal_receipt.read_text())
    if (not formal.get("accepted") or not formal.get("contextStable") or
            formal["inputs"].get(str(model.relative_to(ROOT))) != digest(model)):
        raise ValueError("current accepted QNT contract required")
    if "\nOK\n" not in args.dsl_log.read_text():
        raise ValueError("successful source-bound Scheme evidence test required")
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    env = dict(os.environ, PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
               GAMBIT_SMP_AVAILABLE_CPUS=str(available_processors()),
               GAMBIT_SMP_EXPECTED_PROCESSORS="1")
    receipt = {"schema": "runtime-retirement-acceptance.v1", "status": "RUNNING",
        "scope": "normal-runtime-join-and-Darwin-adversarial-retention-and-observed-terminal-drain",
        "bootstrapRepeated": False, "runtimeAdmitted": False, "releaseAdmitted": False,
        "naturalJoinFailureReachabilityAdmitted": False, "availableProcessors": available_processors(),
        "parentReceiptSha256": digest(parent), "formalReceiptSha256": digest(args.formal_receipt),
        "dslLogSha256": digest(args.dsl_log), "baselineIdentity": old_identity,
        "inputs": {str(p.relative_to(ROOT)): digest(p) for p in
                   (model, join_program, drain_program, patch)}, "commands": []}

    def save():
        receipt["seconds"] = time.monotonic() - started
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")

    def run(name, argv, cwd, cap, expected=0, output=None):
        budget = min(cap, 300 - (time.monotonic() - started))
        if budget <= 0:
            raise ValueError("whole campaign budget exhausted")
        meta = {}
        code, log, timeout, seconds = execute(argv, cwd, budget, env, meta)
        path = out / (name + ".log")
        path.write_text(log)
        receipt["commands"].append(dict(stage=name, argv=[str(x) for x in argv],
            exit=code, timeout=timeout, seconds=seconds, budgetSeconds=budget,
            log=path.name, logSha256=digest(path), **meta))
        save()
        if (code != expected or timeout or not meta.get("processGroupQuiescent") or
                (output is not None and log != output)):
            raise ValueError(f"{name}: exit {code}, timeout {timeout}; inspect retained log")
        return log

    def compile_program(name, tree, program):
        directory = out / name
        directory.mkdir()
        copied = directory / "fixture.scm"
        shutil.copy2(program, copied)
        env["GAMBOPT"] = f"p1,~~lib={tree / 'lib'},~~bin={tree / 'bin'},~~include={tree / 'include'}"
        binary = directory / "fixture"
        run(name + "-compile", [tree / "gsc/gsc", "-exe", "-o", binary,
            "-cc-options", "-pthread", "-ld-options", "-pthread", copied], directory, 30)
        if digest(program) != digest(copied):
            raise ValueError("fixture source changed")
        receipt.setdefault("executables", {})[name] = {
            "programSha256": digest(copied), "binarySha256": digest(binary)}
        return binary

    def join_modes(label, tree):
        binary = compile_program(label, tree, join_program)
        for mode in ("normal", "pending", "sticky"):
            env[args.mode_env] = mode
            run(label + "-" + mode, [binary], binary.parent, 20,
                output=f"RUNTIME-JOIN-QUARANTINE:{mode}:PASS\n")
        env.pop(args.mode_env, None)

    try:
        save()
        join_modes("baseline", baseline)
        candidate = out / "candidate-runtime"
        run("clone-checkpoint", ["/bin/cp", "-cR", baseline, candidate], ROOT, 30)
        check_runtime(candidate, old_identity)
        run("apply-observation", ["/usr/bin/patch", "--batch", "--fuzz=0", "-p1", "-i", patch], candidate, 10)
        source_map = {name: digest(candidate / name) for name in old_identity["sourceFiles"]}
        if {name for name, sha in source_map.items()
                if sha != old_identity["sourceFiles"][name]} != {"lib/setup.c"}:
            raise ValueError("observation changed unexpected source inputs")
        run("incremental-library", ["make", "-C", candidate / "lib", "setup.o", "libgambit.a"], candidate, 90)
        for directory in ("gsi", "gsc"):
            run("link-" + directory, ["make", "-C", candidate / directory, directory], candidate, 30)
        identity = dict(old_identity, sourceFiles=source_map)
        for key, name in (("binarySha256", "gsi/gsi"), ("gscSha256", "gsc/gsc"),
                          ("librarySha256", "lib/libgambit.a")):
            identity[key] = digest(candidate / name)
        check_runtime(candidate, identity)
        receipt["candidateIdentity"] = identity
        join_modes("candidate", candidate)
        binary = compile_program("terminal-drain", candidate, drain_program)
        log = run("terminal-drain-execute", [binary], binary.parent, 20)
        witness = re.fullmatch(r"DRAIN-WITNESS captured=(\d+) drained=(\d+) gate=(\d+)\nTERMINAL-REGISTRY-DRAIN:PASS\n", log)
        if witness is None:
            raise ValueError("typed native drain witness is missing")
        receipt["terminalWitness"] = dict(zip(("captured", "drained", "gate"), map(int, witness.groups())))
        for name, program, marker in (
            ("root-signal", "root_signal_retirement.scm", "ROOT-SIGNAL-RETIREMENT:PASS\n"),
            ("constructor", "constructor_same_storage_emfile.scm", "CONSTRUCTOR-SAME-STORAGE-EMFILE:PASS\n")):
            binary = compile_program(name, candidate, ROOT / "models/gambit/native" / program)
            run(name + "-execute", [binary], binary.parent, 20, output=marker)
        check_runtime(candidate, identity)
        receipt["status"] = "PASS"
    except BaseException as error:
        receipt.update(status="FAIL", error=str(error))
        raise
    finally:
        try:
            check_runtime(baseline, old_identity)
            receipt["originalCheckpointUnchanged"] = True
        finally:
            save()
    print(json.dumps({"status": receipt["status"], "receipt": str(out / "receipt.json")}))


if __name__ == "__main__":
    main()
