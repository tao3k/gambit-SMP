#!/usr/bin/env python3
"""Bounded original-fixture phase timings, diagnostic only, never suite admission."""
import argparse
import json
from pathlib import Path
import shutil
import time

from gambit_smp.bootstrap_runtime import compiler_binding
from gambit_smp.framework import available_processors, digest, execute, gnu_compiler, gnu_build_driver
from gambit_smp.native_suite import runtime_view, selected_files
from gambit_smp.runtime_identity import check


from gambit_smp.compiler_phase_primitives import EXECUTION_WITNESS, LOAD_PROBE, stage_accepted, phase_commands


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, required=True)
    parser.add_argument("--toolchain-receipt", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--timeout", type=float, required=True)
    parser.add_argument("selection")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("positive whole probe budget required")
    runtime, out = args.runtime.resolve(), args.out.resolve()
    identity = json.loads(args.toolchain_receipt.read_text())
    check(runtime, identity)
    compiler, environment, version = gnu_compiler(args.gcc)
    compiler_binding(runtime, compiler)
    driver = gnu_build_driver(runtime, compiler)
    files = selected_files(runtime / "tests/unit-tests", [args.selection])
    if len(files) != 1:
        parser.error("phase probe requires one original upstream fixture")
    sources = {p.relative_to(runtime / "tests").as_posix(): digest(p)
               for p in (runtime / "tests/unit-tests").rglob("*") if p.is_file()}
    out.mkdir(parents=True, exist_ok=False)
    work = runtime_view(runtime, out / "runtime")
    shutil.copytree(runtime / "tests/unit-tests", work / "unit-tests")
    processors = available_processors()
    option = f"p{processors},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    environment["GAMBOPT"] = option
    receipt = dict(schema="gambit-compiler-cost.v2", diagnosticOnly=True,
                   adapterSha256=digest(Path(__file__)),
                   executionContract="explicit probe linker, initialized original failure flag and unique witness",
                   scope="one unchanged upstream fixture, split compile/execute phases; not suite or bootstrap admission",
                   status="RUNNING", candidateReceiptSha256=digest(args.toolchain_receipt),
                   gsiSha256=identity["binarySha256"], gscSha256=identity["gscSha256"],
                   processors=processors, processorSelection="host-auto",
                   compiler=version.splitlines()[0], buildDriver=driver, sourceFiles=sources,
                   selection=str(files[0]), wholeProbeBudget=args.timeout, stages=[])
    receipt_path = out / "receipt.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    stages = phase_commands(files[0], work)
    start = time.monotonic()
    deadline = start + args.timeout
    for name, executable, options, artifact in stages:
        remaining = deadline - time.monotonic()
        metadata = {}
        if remaining <= 0:
            code, output, timed_out, seconds = -9, "whole probe budget exhausted\n", True, 0
        else:
            code, output, timed_out, seconds = execute(
                [str(runtime / executable), "-:" + option] + options, work,
                remaining, env=environment, metadata=metadata)
        (out / (name + ".log")).write_text(output)
        accepted = stage_accepted(code, timed_out, output, artifact,
                                  EXECUTION_WITNESS if name == "compiled-execution" else None)
        receipt["stages"].append(dict(name=name, exit=code, timeout=timed_out,
            seconds=round(seconds, 3), accepted=accepted, process=metadata,
            artifactSha256=digest(artifact) if artifact and artifact.is_file() else None))
        receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
        print(f"{name}: {'PASS' if accepted else 'DENY'}; {seconds:.3f}s", flush=True)
        if not accepted:
            break
    stable = all(digest(runtime / "tests" / name) == sha and digest(work / name) == sha
                 for name, sha in sources.items()) and gnu_build_driver(runtime, compiler) == driver
    check(runtime, identity)
    receipt.update(sourceStable=stable, seconds=round(time.monotonic() - start, 3))
    accepted = stable and len(receipt["stages"]) == len(stages) and all(row["accepted"] for row in receipt["stages"]) and receipt["seconds"] <= args.timeout
    receipt["status"] = "PASS" if accepted else "DENY"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if accepted else 1


if __name__ == "__main__":
    raise SystemExit(main())
