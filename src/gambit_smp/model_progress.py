"""Check progress of unchanged QNT models with explicit finite fault controls."""
import argparse
import json
from pathlib import Path
import re
import subprocess

from gambit_smp.check_gambit import admitted_model, counterexample
from gambit_smp.framework import ROOT, available_processors, digest, execute
from gambit_smp.quint_backend import check as check_model


def generated(source, case, blocked):
    name = case["id"]
    if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
        raise ValueError("invalid progress model name")
    if not source.startswith("module " + name + " {") or not source.rstrip().endswith("}"):
        raise ValueError("one matching model module required")
    if "obligation" in source:
        raise ValueError("progress overlay identifiers already present")
    variables = case["stateVariables"]
    if not variables or any(not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", var) for var in variables):
        raise ValueError("explicit model state variables required")
    flag = "true" if blocked else "false"
    return source.rstrip()[:-1] + f"""
  // Verification-only overlay; the original state transitions are unchanged.
  val obligationTerminal = {case['terminal']}
  action obligationStep = all {{ not({flag} and ({case['blockedWhen']})), step }}
  val obligationEnabled = obligationTerminal or enabled(obligationStep)
  temporal obligationProgress = always(obligationEnabled) and
    weakFair(obligationStep, Set({', '.join(variables)})).implies(eventually(obligationTerminal))
}}
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument, required=True)
    parser.add_argument("--timeout", type=float, default=90)
    args = parser.parse_args()
    if not 0 < args.timeout < float("inf"):
        parser.error("finite positive timeout required")
    manifest_path = ROOT / "evidence/progress-obligations.json"
    manifest = json.loads(manifest_path.read_text())
    case = next((row for row in manifest["cases"] if row["id"] == args.case), None)
    if manifest.get("schema") != "gambit-progress-obligations.v1" or case is None:
        parser.error("known progress obligation required")
    version = subprocess.check_output(["quint", "--version"], text=True, timeout=10).strip()
    if version != manifest["quintVersion"]:
        raise ValueError("progress verifier version differs")
    source = ROOT / "models/gambit" / (case["id"] + ".qnt")
    original = source.read_text()
    inputs = {str(path.relative_to(ROOT)): digest(path) for path in
              (source, manifest_path, Path(__file__),
               ROOT / "src/gambit_smp/framework.py", ROOT / "src/gambit_smp/check_gambit.py",
               ROOT / "src/gambit_smp/tlc_values.py", ROOT / "src/gambit_smp/quint_backend.py")}
    args.out.mkdir(parents=True, exist_ok=False)
    config = args.out.resolve() / "tlc-config.json"
    workers = available_processors()
    config.write_text(json.dumps({"workers": workers}) + "\n")
    receipt = {"schema": "gambit-model-progress-receipt.v1", "case": case["id"],
               "scope": case["scope"], "quintVersion": version, "workers": workers,
               "inputs": inputs, "runtimeAdmitted": False, "results": []}
    ok = True
    for blocked in (True, False):
        variant = "blocked" if blocked else "protocol"
        snapshot = args.out.resolve() / (variant + ".qnt")
        snapshot.write_text(generated(original, case, blocked))
        sha = digest(snapshot)
        result, output, trace = check_model(snapshot, initializer=case["initializer"],
            step="obligationStep", invariant="obligationEnabled", negative=blocked,
            temporal=None if blocked else "obligationProgress", config=config,
            cwd=args.out.resolve(), timeout=args.timeout)
        log = args.out / (variant + ".log")
        log.write_text(output)
        accepted = result["accepted"]
        row = {**result, "variant": variant,
               "snapshot": snapshot.name, "snapshotSha256": sha,
               "log": log.name, "logSha256": digest(log),
               "temporal": None if blocked else "obligationProgress"}
        if trace is not None:
            trace.update(case=case["id"], generatedSha256=sha)
            target = args.out / "blocked.trace.json"
            target.write_text(json.dumps(trace, indent=2) + "\n")
            row.update(trace=target.name, traceSha256=digest(target))
        receipt["results"].append(row)
        print(f"PROGRESS-{variant}: {'OK' if accepted else 'DENY'} ({result['seconds']:.3f}s)", flush=True)
        ok = ok and accepted
        if not ok:
            break
    stable = all(digest(ROOT / name) == sha for name, sha in inputs.items())
    receipt.update(sourceStable=stable, accepted=ok and stable)
    (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if receipt["accepted"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
