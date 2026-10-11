#!/usr/bin/env python3
"""Extract a pinned foreign-call C boundary; deterministic GC mocks, not ABI proof."""
import argparse
import json
from pathlib import Path
import shutil
from gambit_smp.framework import ROOT, digest, execute, gnu_compiler


def boundary(source):
    signature = "(define-prim (##os-condvar-select! devices timeout)\n"
    if source.count(signature) != 1:
        raise ValueError("foreign-call source identity changed")
    section = source.split(signature)[1].split("\n(define-prim", 1)[0]
    begin, end = "#<<end-of-code\n", "\nend-of-code\n"
    if section.count(begin) != 1 or section.count(end) != 1:
        raise ValueError("foreign-call embedded C boundaries changed")
    code = section.split(begin)[1].split(end)[0]
    operations = ["___FRAME_STORE_RA(___R0)", "___W_ALL",
                  "result = ___os_condvar_select (___ARG1, ___ARG2);",
                  "___R_ALL", "___SET_R0(___FRAME_FETCH_RA)", "___RESULT = result;"]
    if any(code.count(op) != 1 for op in operations):
        raise ValueError("foreign-call operations changed; source audit required")
    if [code.index(op) for op in operations] != sorted(code.index(op) for op in operations):
        raise ValueError("foreign-call protocol ordering changed")
    return code + "\n"


def variants(code):
    return {"fixed": code, "no-writeback": code.replace("___W_ALL", ""),
            "no-reload": code.replace("___R_ALL", ""),
            "no-return-root": code.replace("___FRAME_STORE_RA(___R0)", "")}


def expected_pass(variant, gc_count):
    if variant not in ("fixed", "no-writeback", "no-reload", "no-return-root") or gc_count not in range(3):
        raise ValueError("unknown source-unit control")
    return variant == "fixed" or (variant != "no-writeback" and gc_count == 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kernel-source", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    source = args.kernel_source.resolve()
    code = boundary(source.read_text())
    compiler, environment, version = gnu_compiler(args.gcc)
    args.out.mkdir(parents=True, exist_ok=False)
    fixture = ROOT / "models/gambit/native/ffi_gc_frame_protocol.c"
    receipt = {"schema": "gambit-ffi-source-unit.v1", "diagnosticOnly": True,
               "scope": "unchanged embedded C with mocked macros/collector; no real GC, threads or ABI acceptance",
               "sourceSha256": digest(source), "fixtureSha256": digest(fixture),
               "compiler": version.splitlines()[0], "results": []}
    for variant, text in variants(code).items():
        out = args.out.resolve() / variant
        out.mkdir()
        include = out / "ffi-source.inc"
        include.write_text(text)
        shutil.copyfile(fixture, out / fixture.name)
        code_exit, log, timeout, seconds = execute([compiler, "-std=c11", "-O1", "-Wall", "-Wextra",
            "-Werror", str(out / fixture.name), "-o", str(out / "ffi-unit")], out, 30, env=environment)
        (out / "compile.log").write_text(log)
        row = {"variant": variant, "embeddedCSha256": digest(include),
               "compile": dict(exit=code_exit, timeout=timeout, seconds=seconds), "runs": []}
        if code_exit == 0 and not timeout:
            for gc_count in range(3):
                exit_code, output, timed_out, elapsed = execute([str(out / "ffi-unit"), str(gc_count)], out, 5, env=environment)
                (out / f"gc-{gc_count}.log").write_text(output)
                should_pass = expected_pass(variant, gc_count)
                expected_marker = "SOURCE-UNIT-OK" if should_pass else "SOURCE-UNIT-DENY"
                accepted = not timed_out and exit_code == (0 if should_pass else 1) and output.splitlines().count(expected_marker) == 1
                row["runs"].append(dict(collections=gc_count, expectedPass=should_pass,
                    accepted=accepted, exit=exit_code, timeout=timed_out, seconds=elapsed, output=output))
        receipt["results"].append(row)
    receipt["status"] = "source-unit-pass" if all(len(r["runs"]) == 3 and all(x["accepted"] for x in r["runs"])
        for r in receipt["results"]) else "DENY"
    (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"FFI-SOURCE-UNIT: {receipt['status']}")
    return 0 if receipt["status"] == "source-unit-pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
