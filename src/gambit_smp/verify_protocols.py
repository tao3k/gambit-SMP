"""Verify an isolated protocol manifest using the shared Quint/TLC framework.

Only new protocol checks run; no native candidate or known failed route runs.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time

from gambit_smp.check_gambit import admitted_model, counterexample, model_checks, model_stable, snapshot_model
from gambit_smp.framework import ROOT, available_processors, digest, execute
from gambit_smp.quint_backend import check as check_model, isolated_endpoint, summarize
from gambit_smp.research_audit import local
from gambit_smp.model_schedule import batches, physical_memory, resources, run_batch
from gambit_smp.framework import positive_int


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
        if not re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]*", case.get("step", "step")):
            raise ValueError("invalid protocol step")
        dependencies = case.get("dependencies", [])
        if (len(dependencies) != len(set(dependencies)) or any(
                Path(name).name != name or not name.endswith(".qnt")
                or name == case["id"] + ".qnt" for name in dependencies)):
            raise ValueError("protocol dependencies must be unique sibling models")
        checks = model_checks(case)
        if "registrationOnly" in case and type(case["registrationOnly"]) is not bool:
            raise ValueError("registration-only marker must be boolean")
        if len(set(checks)) != len(checks):
            raise ValueError("unique checks and explicit progress property required")
        if case.get("registrationOnly") is True:
            if case.get("temporal") is not None:
                raise ValueError("registration-only case cannot declare temporal acceptance")
            continue
        if not case.get("temporal"):
            raise ValueError("unique checks and explicit progress property required")
    return manifest


def retain_reused_artifacts(source, destination, row):
    """A resumed verdict retains its checked compiler artifacts, not just logs."""
    inputs = {}
    for name, expected in row.get("checker", {}).get("artifacts", {}).items():
        original, target = local(source, name), local(destination, name)
        if digest(original) != expected:
            raise ValueError("resumed checker artifact changed")
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() and digest(target) != expected:
            raise ValueError("resumed checker artifact collision")
        target.write_bytes(original.read_bytes())
        if digest(original) != expected or digest(target) != expected:
            raise ValueError("resumed checker artifact changed during retention")
        inputs[str(original)] = expected
    return inputs


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
            or row.get("step", "step") != case.get("step", "step")
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
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", required=True, type=runtime_argument)
    parser.add_argument("--case")
    parser.add_argument("--resume-from", type=Path,
                        help="reuse same-model checks; reparse valid negative-control logs without rerunning TLC")
    parser.add_argument("--timeout", type=float, default=90)
    parser.add_argument("--jobs", type=positive_int,
                        help="independent control jobs; default CPU/memory auto; positives stay serial")
    parser.add_argument("--controls-only", action="store_true",
                        help="diagnostic control timing only; never an admitted whole-model receipt")
    parser.add_argument("--tlc-liveness", choices=("default", "final"), default="default",
                        help="final defers intermediate checks, retaining final temporal validation")
    parser.add_argument("--tlc-jar", type=Path,
                        help="explicit bundled TLC artifact required for final scheduling")
    args = parser.parse_args()
    if not 0 < args.timeout < float("inf"):
        parser.error("finite positive timeout required")
    if (args.tlc_liveness == "final") != (args.tlc_jar is not None):
        parser.error("--tlc-liveness final requires --tlc-jar; default uses Quint's backend")
    jar_hash = digest(args.tlc_jar) if args.tlc_jar else None
    manifest = load_manifest(args.manifest)
    cases = [case for case in manifest["cases"] if args.case is None or case["id"] == args.case]
    if not cases:
        parser.error("unknown case")
    if any(case.get("registrationOnly") is True for case in cases):
        parser.error("registration-only metadata is not executable protocol acceptance; use its declared safety recipe")
    version = subprocess.check_output(["quint", "--version"], text=True, timeout=10).strip()
    if version != manifest["quintVersion"]:
        raise ValueError("Quint version differs from reviewed version")
    plan = resources(available_processors(), physical_memory(), args.jobs)
    inputs = {str(args.manifest.resolve().relative_to(ROOT)): digest(args.manifest)}
    if args.resume_from:
        args.resume_from = args.resume_from.resolve()
        path = args.resume_from / "receipt.json"
        inputs[str(path.relative_to(ROOT))] = digest(path)
    for name, expected in manifest["contextInputs"].items():
        if digest(local(ROOT, name)) != expected:
            raise ValueError("reviewed context changed: " + name)
        inputs[name] = expected
    for name in ("verify_protocols.py", "check_gambit.py", "framework.py", "tlc_values.py", "quint_backend.py", "model_schedule.py"):
        inputs["src/gambit_smp/" + name] = digest(ROOT / "src/gambit_smp" / name)
    if args.tlc_liveness == "final":
        inputs["src/gambit_smp/tlc_execution.py"] = digest(ROOT / "src/gambit_smp/tlc_execution.py")
    args.out.mkdir(parents=True, exist_ok=False)
    configs = {}
    for kind, workers in (("old", plan["controlTlcWorkers"]), ("protocol", plan["positiveTlcWorkers"])):
        config = args.out.resolve() / ("tlc-config-" + kind + ".json")
        config.write_text(json.dumps({"workers": workers, "maxHeap": plan["perCheckTlcHeap"]}) + "\n")
        configs[kind] = config
        inputs[str(config.relative_to(ROOT))] = digest(config)
    receipt = {"schema": "gambit-smp-model-receipt.v1", "quintVersion": version,
               "scope": "bounded-protocol-extensions-not-source-refinement",
               "workers": plan["availableProcessors"], "scheduling": plan,
               "livenessSchedule": args.tlc_liveness, "tlcJarSha256": jar_hash,
               "controlsOnly": args.controls_only, "inputs": inputs, "results": [],
               "native": {"status": "not-run"}, "runtimeAdmitted": False,
               "releaseAdmitted": False}
    ok = True
    started = time.monotonic()
    for case in cases:
        source = ROOT / "models/gambit" / (case["id"] + ".qnt")
        for name in case.get("dependencies", []):
            dependency = ROOT / "models/gambit" / name
            key = str(dependency.relative_to(ROOT))
            if manifest["contextInputs"].get(key) != digest(dependency):
                raise ValueError("imported model must be explicitly context-bound")
            target = args.out.resolve() / name
            if target.exists() and digest(target) != digest(dependency):
                raise ValueError("imported model snapshot collision")
            target.write_bytes(dependency.read_bytes())
        snapshot, sha = snapshot_model(source, args.out.resolve())
        inputs[str(source.relative_to(ROOT))] = sha
        checks = [check for check in model_checks(case) if not args.controls_only or check[0] == "old"]
        if args.controls_only and not checks:
            raise ValueError("controls-only requires actual negative controls")
        def worker(check):
            variant, invariant, initializer = check
            old = variant == "old"
            name = f"{case['id']}-{variant}-{invariant}"
            reused = (reusable_check(args.resume_from, manifest, case, variant, invariant, initializer, sha)
                      if args.resume_from else None)
            if reused:
                row, output, trace = reused
                old_log = args.resume_from / row["log"]
                inputs[str(old_log.relative_to(ROOT))] = digest(old_log)
                inputs.update({str(Path(path).relative_to(ROOT)): expected
                    for path, expected in retain_reused_artifacts(
                        args.resume_from, args.out, row).items()})
                (args.out / (name + ".log")).write_text(output)
                row.update(log=name + ".log", reusedFromReceiptSha256=digest(args.resume_from / "receipt.json"))
                if trace:
                    (args.out / (name + ".trace.json")).write_text(json.dumps(trace, indent=2) + "\n")
                return row, f"{name}: REUSED"
            directory = args.out.resolve() / "checks" / name
            directory.mkdir(parents=True, exist_ok=False)
            result, output, trace = check_model(snapshot, initializer=initializer,
                invariant=invariant, negative=old, cwd=directory, timeout=args.timeout,
                config=configs["old" if old else "protocol"], temporal=None if old else case["temporal"],
                step=case.get("step"),
                liveness_schedule=args.tlc_liveness, tlc_jar=args.tlc_jar)
            artifacts = {}
            for artifact_name, expected in result.get("checker", {}).get("artifacts", {}).items():
                artifact = local(directory, artifact_name)
                inputs[str(artifact.relative_to(ROOT))] = expected
                artifacts[str(artifact.relative_to(args.out.resolve()))] = expected
            if "checker" in result:
                result["checker"]["artifacts"] = artifacts
            (args.out / (name + ".log")).write_text(output)
            stable = model_stable(source, snapshot, sha)
            accepted = result["accepted"] and stable
            if trace is not None:
                trace.update({"case": case["id"], "invariant": invariant, "modelSha256": sha})
                (args.out / (name + ".trace.json")).write_text(json.dumps(trace, indent=2) + "\n")
            row = {**result, "case": case["id"], "variant": variant,
                "initializer": initializer, "invariant": invariant,
                "step": case.get("step", "step"),
                "modelSha256": sha, "sourceStable": stable, "accepted": accepted,
                "evidence": "finite-state-TLC", "log": name + ".log",
                "tlcWorkers": plan["controlTlcWorkers"] if old else plan["positiveTlcWorkers"]}
            return row, f"{name}: {'OK' if accepted else 'DENY'} ({result['seconds']:.3f}s)"
        for batch in batches(checks, plan["parallelControls"]):
            for row, message in run_batch(batch, worker):
                receipt["results"].append(row)
                print(message, flush=True)
            if not all(row["accepted"] for row in receipt["results"]):
                ok = False
                break
        if not ok:
            break
    stable = all(digest(local(ROOT, name)) == expected for name, expected in inputs.items()) and (
        args.tlc_jar is None or digest(args.tlc_jar) == jar_hash)
    receipt.update({"contextStable": stable, "accepted": ok and stable and not args.controls_only,
                    "controlChecksPassed": ok and stable if args.controls_only else None,
                    "campaignSeconds": round(time.monotonic() - started, 3)})
    (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if ok and stable else 1


if __name__ == "__main__":
    raise SystemExit(main())
