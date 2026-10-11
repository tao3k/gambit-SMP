#!/usr/bin/env python3
"""Source-bound schedule refinement of sync_retirement_drain; not runtime admission."""
import argparse
import json
from pathlib import Path
import shutil

from gambit_smp.framework import ROOT, digest, execute, gnu_compiler
from gambit_smp.source_unit import sync_resource_functions


def extract(source):
    start = "#define SYNC_WAITING -1\n"
    end = "\n\n___HIDDEN void ___sync_wait\n"
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("sync macro boundaries changed; audit required")
    left, right = source.index(start), source.index(end)
    if left >= right:
        raise ValueError("sync macro boundaries reversed")
    return source[left:right] + "\n" + sync_resource_functions(source)


def expected(mode, point):
    if mode not in range(4) or point not in (1, 2):
        raise ValueError("unknown schedule")
    return dict(invalid=(2 if point == 1 else 1) if mode == 1 else 0,
        busyDestroy=int(mode == 1 and point == 1), signals=int(mode != 3),
        receiverDone=int(mode != 3), receiverLocks=0,
        destroyed=2 if mode in (1, 2) else 0,
        mutexLive=int(mode == 0 or (mode == 3 and point == 2)),
        cvLive=int(mode == 0 or (mode == 3 and point == 1)), attempts=2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    source = args.source.resolve(strict=True)
    compiler, env, version = gnu_compiler(args.gcc)
    fixture = ROOT / "models/gambit/native/sync_retirement_schedule.c"
    adapter = Path(__file__).resolve()
    helpers = [ROOT / "src/gambit_smp" / name for name in ("framework.py", "source_unit.py")]
    model = ROOT / "models/gambit/sync_retirement_drain.qnt"
    manifest = ROOT / "evidence/protocol-extensions.json"
    model_receipt = ROOT / "evidence/model-results/protocol-extensions/receipt.json"
    source_hash = digest(source)
    context = json.loads(manifest.read_text())["contextInputs"]
    if context.get(source.relative_to(ROOT).as_posix()) != source_hash:
        raise ValueError("source differs from model context; audit before execution")
    inputs = {p.relative_to(ROOT).as_posix(): digest(p)
              for p in (source, fixture, adapter, model, manifest, model_receipt, *helpers)}
    function = extract(source.read_text())
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    (out / "sync-schedule-source.inc").write_text(function)
    shutil.copyfile(fixture, out / fixture.name)
    receipt = dict(schema="gambit-sync-retirement-schedule.v1", inputs=inputs,
        diagnosticOnly=True, runtimeAdmitted=False, releaseAdmitted=False,
        scope="Unchanged macros/setup/cleanup; mock scheduling and resource accounting. "
              "Naive destruction and deferred drain are fixture policies, not candidate patches. "
              "Does not prove C memory ordering, native reachability or whole-runtime quiescence.",
        compiler=version.splitlines()[0], functionSha256=digest(out / "sync-schedule-source.inc"),
        results=[])
    code, log, timed_out, seconds = execute([compiler, "-std=c11", "-O1", "-Wall", "-Wextra",
        "-Werror", str(out / fixture.name), "-o", str(out / "schedule")], out, 30, env=env)
    (out / "compile.log").write_text(log)
    receipt["compile"] = dict(exit=code, timeout=timed_out, seconds=seconds)
    if code == 0 and not timed_out:
        for mode, name in enumerate(("existing-no-destroy", "naive-child-destroy",
                                     "deferred-drain-contract", "initialization-failure")):
            for point in (1, 2):
                code, log, timed_out, seconds = execute(
                    [str(out / "schedule"), str(mode), str(point)], out, 5, env=env)
                (out / f"{name}-{point}.log").write_text(log)
                try:
                    actual = json.loads(log)
                except ValueError:
                    actual = None
                receipt["results"].append(dict(policy=name, point=point, actual=actual,
                    expected=expected(mode, point), exit=code, timeout=timed_out, seconds=seconds,
                    matched=code == 0 and not timed_out and actual == expected(mode, point)))
    stable = all(digest(ROOT / p) == sha for p, sha in inputs.items())
    stable = stable and (out / "sync-schedule-source.inc").read_text() == function
    stable = stable and digest(out / fixture.name) == inputs[fixture.relative_to(ROOT).as_posix()]
    admitted = stable and len(receipt["results"]) == 8 and all(r["matched"] for r in receipt["results"])
    receipt.update(sourceStable=stable, status="source-schedule-observed" if admitted else "DENY")
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"status": receipt["status"], "schedules": len(receipt["results"]),
                      "runtimeAdmitted": False}))
    return 0 if admitted else 1


if __name__ == "__main__":
    raise SystemExit(main())
