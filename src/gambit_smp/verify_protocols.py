"""Verify an isolated protocol manifest using the shared Quint/TLC framework.

Only new protocol checks run; no native candidate or known failed route runs.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess

from gambit_smp.check_gambit import admitted_model, counterexample, model_checks, model_stable, snapshot_model
from gambit_smp.framework import ROOT, available_processors, digest, execute
from gambit_smp.quint_backend import check as check_model, isolated_endpoint, summarize
from gambit_smp.research_audit import local


def load_manifest(path):
    manifest = json.loads(path.read_text())
    if manifest.get("schema") != "gambit-protocol-extensions.v1":
        raise ValueError("unknown protocol manifest")
    names = [row["id"] for row in manifest["cases"]]
    if len(set(names)) != len(names) or not names:
        raise ValueError("unique nonempty cases required")
    for case in manifest["cases"]:
        if not re.fullmatch(r"[a-z][a-z0-9_]*", case["id"]):
            raise ValueError("invalid case name")
        checks = model_checks(case)
        if len(set(checks)) != len(checks) or not case.get("temporal"):
            raise ValueError("unique checks and explicit progress property required")
    return manifest


def reusable_check(directory, manifest, case, variant, invariant, initializer, sha):
    saved = json.loads((directory / "receipt.json").read_text())
    if saved.get("quintVersion") != manifest["quintVersion"] or saved.get("contextStable") is not True:
        raise ValueError("resume context is not stable")
    if any(saved.get("inputs", {}).get(name) != expected
           for name, expected in manifest["contextInputs"].items()):
        raise ValueError("resume source/paper context differs")
    rows = [row for row in saved["results"] if (row["case"], row["variant"], row["invariant"])
            == (case["id"], variant, invariant)]
    if not rows:
        return None
    if len(rows) != 1:
        raise ValueError("ambiguous resumed check")
    row = rows[0]
    recovering = row.get("accepted") is not True
    if recovering and variant != "old":
        return None
    if (row["modelSha256"] != sha or row.get("initializer") != initializer
            or row.get("sourceStable") is not True):
        raise ValueError("resume model/initializer differs")
    log = local(directory, row["log"])
    output = log.read_text()
    old = variant == "old"
    if not admitted_model(row["exit"], output, row["timeout"], old):
        if recovering:
            return None
        raise ValueError("resume log contradicts verdict")
    trace = None
    if old:
        trace = counterexample(output)
        trace.update({"case": case["id"], "invariant": invariant, "modelSha256": sha})
    elif row.get("temporal") != case["temporal"] or "Finished checking temporal properties" not in output:
        raise ValueError("resume requires temporal evidence")
    recovered = dict(row)
    if recovering:
        recovered.update(accepted=True, recoveredCounterexampleParse=True)
    return recovered, output, trace


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=ROOT / "evidence/protocol-extensions.json")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--case")
    parser.add_argument("--resume-from", type=Path,
                        help="reuse same-model checks; reparse valid negative-control logs without rerunning TLC")
    parser.add_argument("--timeout", type=float, default=90)
    args = parser.parse_args()
    if not 0 < args.timeout < float("inf"):
        parser.error("finite positive timeout required")
    manifest = load_manifest(args.manifest)
    cases = [case for case in manifest["cases"] if args.case is None or case["id"] == args.case]
    if not cases:
        parser.error("unknown case")
    version = subprocess.check_output(["quint", "--version"], text=True, timeout=10).strip()
    if version != manifest["quintVersion"]:
        raise ValueError("Quint version differs from reviewed version")
    inputs = {str(args.manifest.resolve().relative_to(ROOT)): digest(args.manifest)}
    if args.resume_from:
        args.resume_from = args.resume_from.resolve()
        path = args.resume_from / "receipt.json"
        inputs[str(path.relative_to(ROOT))] = digest(path)
    for name, expected in manifest["contextInputs"].items():
        if digest(local(ROOT, name)) != expected:
            raise ValueError("reviewed context changed: " + name)
        inputs[name] = expected
    for name in ("verify_protocols.py", "check_gambit.py", "framework.py", "tlc_values.py", "quint_backend.py"):
        inputs["src/gambit_smp/" + name] = digest(ROOT / "src/gambit_smp" / name)
    args.out.mkdir(parents=True, exist_ok=False)
    config = args.out.resolve() / "tlc-config.json"
    config.write_text(json.dumps({"workers": available_processors()}) + "\n")
    receipt = {"schema": "gambit-smp-model-receipt.v1", "quintVersion": version,
               "scope": "bounded-protocol-extensions-not-source-refinement",
               "workers": available_processors(), "inputs": inputs, "results": [],
               "native": {"status": "not-run"}, "runtimeAdmitted": False,
               "releaseAdmitted": False}
    ok = True
    for case in cases:
        source = ROOT / "models/gambit" / (case["id"] + ".qnt")
        snapshot, sha = snapshot_model(source, args.out.resolve())
        inputs[str(source.relative_to(ROOT))] = sha
        for variant, invariant, initializer in model_checks(case):
            old = variant == "old"
            name = f"{case['id']}-{variant}-{invariant}"
            reused = (reusable_check(args.resume_from, manifest, case, variant, invariant, initializer, sha)
                      if args.resume_from else None)
            if reused:
                row, output, trace = reused
                old_log = args.resume_from / row["log"]
                inputs[str(old_log.relative_to(ROOT))] = digest(old_log)
                (args.out / (name + ".log")).write_text(output)
                row.update(log=name + ".log", reusedFromReceiptSha256=digest(args.resume_from / "receipt.json"))
                if trace:
                    (args.out / (name + ".trace.json")).write_text(json.dumps(trace, indent=2) + "\n")
                receipt["results"].append(row)
                print(f"{name}: REUSED", flush=True)
                continue
            result, output, trace = check_model(snapshot, initializer=initializer,
                invariant=invariant, negative=old, cwd=args.out.resolve(), timeout=args.timeout,
                config=config, temporal=None if old else case["temporal"])
            (args.out / (name + ".log")).write_text(output)
            stable = model_stable(source, snapshot, sha)
            accepted = result["accepted"] and stable
            if trace is not None:
                trace.update({"case": case["id"], "invariant": invariant, "modelSha256": sha})
                (args.out / (name + ".trace.json")).write_text(json.dumps(trace, indent=2) + "\n")
            receipt["results"].append({**result, "case": case["id"], "variant": variant,
                "initializer": initializer, "invariant": invariant,
                "modelSha256": sha, "sourceStable": stable, "accepted": accepted,
                "evidence": "finite-state-TLC", "log": name + ".log"})
            print(f"{name}: {'OK' if accepted else 'DENY'} ({result['seconds']:.3f}s)", flush=True)
            if not accepted:
                ok = False
                break
        if not ok:
            break
    stable = all(digest(local(ROOT, name)) == expected for name, expected in inputs.items())
    receipt.update({"contextStable": stable, "accepted": ok and stable})
    (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if ok and stable else 1


if __name__ == "__main__":
    raise SystemExit(main())
