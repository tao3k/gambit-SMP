"""Checked file-coverage projection; never native or performance authorization."""
import re
import argparse
import json
import sys
from pathlib import Path
from gambit_smp.artifact_storage import fixture_root, fixture_name, fixture_path

from gambit_smp.framework import ROOT, digest
from gambit_smp.recipes import read_json


def _sha(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def project_suite_files(receipt):
    """Project validated executor results, not caller-supplied PASS labels alone."""
    result = {"observed_suite": [], "observed_suite_file": []}
    for step in receipt.get("steps", []):
        if step.get("capability") != "gambit.suite" or step.get("outcome") != "PASS":
            continue
        if "passedFiles" not in step:
            continue
        name, args = step["id"], step["arguments"]
        passed, expected = step["passedFiles"], args["expectedFiles"]
        if (not isinstance(passed, list) or not passed or not isinstance(expected, list) or
                any(not isinstance(file, str) or Path(file).is_absolute() or ".." in Path(file).parts for file in passed)
                or len(passed) != len(set(passed)) or sorted(passed) != sorted(expected)
                or step.get("mode") != args["mode"] or args["mode"] not in {"gsi", "gsc"}):
            raise ValueError("suite coverage requires exact complete declared file results")
        groups, covered = step.get("suiteGroups"), []
        if not isinstance(groups, list) or not groups:
            raise ValueError("suite coverage requires actual completed groups")
        phase_files = set(args.get("compilerPhaseFiles", []))
        if not phase_files <= set(passed) or phase_files and args["mode"] != "gsc":
            raise ValueError("compiled phases must belong to the declared compiled inventory")
        for group in groups:
            if (group.get("accepted") is not True or type(group.get("exit")) is not int
                    or group["exit"] != 0 or group.get("timeout") is not False):
                raise ValueError("failed or uncompleted suite group cannot qualify")
            files = group["files"]
            if not isinstance(files, list) or not files or any(not isinstance(file, str) for file in files):
                raise ValueError("exact completed group file list required")
            covered.extend(files)
            requested_phases = phase_files.intersection(files)
            if requested_phases:
                rows = group.get("compilerPhases", [])
                if (len(files) != 1 or group.get("assertionProtocol") != "original-gsi-loader-and-unit-test-exit"
                        or group.get("phaseInactivitySeconds") != args["fileBudgetSeconds"][files[0]]
                        or [row.get("phase") for row in rows] !=
                           ["scheme-to-c", "c-to-dynamic-module", "compiled-execution"]
                        or any(row.get("accepted") is not True or type(row.get("exit")) is not int
                               or row["exit"] != 0 or row.get("timeout") is not False for row in rows)
                        or not all(_sha(row.get("artifactSha256")) for row in rows[:2])):
                    raise ValueError("compiled phase coverage requires original loader and all real phase artifacts")
            elif "compilerPhases" in group:
                raise ValueError("undeclared compiled phase protocol")
        if sorted(covered) != sorted(passed):
            raise ValueError("suite groups must cover the exact file inventory once")
        artifacts = step.get("artifacts", {})
        for file in passed:
            sha = artifacts.get(name + "/runtime/tests/unit-tests/" + file)
            additional = args.get("additionalFixtures", {}).get(file)
            if not _sha(sha) or additional is not None and sha != additional["sha256"]:
                raise ValueError("suite fixture hash is missing or differs from its declared source")
            result["observed_suite_file"].append([name, file, sha])
        whole = args["selection"] == ["."] and args["regime"] in {"whole-parallel", "whole-sequential"}
        result["observed_suite"].append([name, args["mode"], args.get("inventory", "unit"), whole])
    return result


def checked_suite_coverage(run):
    """Require current sealed receipt custody before projecting observed coverage."""
    from gambit_smp.research_kernel import inspect
    run = Path(run).resolve(strict=True)
    root = ROOT.resolve()
    fixture_root(root, run)
    before = digest(run / "receipt.json")
    outer, child = read_json(run / "receipt.json"), read_json(run / "run/receipt.json")
    if (outer.get("outcome") != "PASS" or outer.get("exit") != 0
            or Path(outer.get("root", "")).resolve() != root
            or outer.get("timeout") is not False or outer.get("parentReaped") is not True
            or outer.get("processGroupQuiescent") is not True
            or digest(run / "run/receipt.json") != outer.get("childReceiptSha256")
            or child.get("outcome") != "PASS" or inspect(run).get("identityStatus") != "CURRENT"):
        raise ValueError("suite coverage requires current complete quiescent sealed evidence")
    facts = project_suite_files(child)
    if digest(run / "receipt.json") != before or digest(run / "run/receipt.json") != outer["childReceiptSha256"]:
        raise ValueError("suite receipt changed during projection")
    return {"schema": "checked-native-suite-coverage.v1", "run": run.relative_to(root).as_posix(),
            "outerReceiptSha256": before, "childReceiptSha256": outer["childReceiptSha256"],
            "engineId": outer["engineId"], "facts": facts,
            "runtimeAdmitted": False, "sourceRefinementAdmitted": False, "performanceAdmitted": False}


def main():
    from gambit_smp.framework import execute
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.recipes import fields, source_path
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", required=True, type=Path)
    parser.add_argument("--contract", required=True)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", required=True, type=runtime_argument)
    args = parser.parse_args()
    contract_path = source_path(ROOT, args.contract)
    contract_sha = digest(contract_path)
    contract = read_json(contract_path)
    if digest(contract_path) != contract_sha:
        raise ValueError("coverage contract changed during read")
    fields(contract, ("schema", "rules", "queries", "expected", "evaluationSeconds"))
    if contract["schema"] != "native-suite-coverage-contract.v1":
        raise ValueError("typed suite coverage contract required")
    rules = [source_path(ROOT, path) for path in contract["rules"]]
    out = args.out.resolve()
    if out.exists():
        raise ValueError("fresh same-project coverage output required")
    bindings = {str(path.relative_to(ROOT)): digest(path)
                for path in [contract_path, *rules, Path(__file__).resolve()]}
    record = checked_suite_coverage(args.run)
    outer = read_json(args.run / "receipt.json")
    engine = Path(outer["engine"])
    manifest = manifest_paths(engine)
    if manifest["engineId"] != record["engineId"]:
        raise ValueError("coverage engine differs from the sealed native run")
    out.mkdir(parents=True)
    request = {"rules": [str(path) for path in rules], "facts": record["facts"],
               "queries": contract["queries"], "engineId": record["engineId"], "output": str(out)}
    request_path = out / "evaluation.json"
    request_path.write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
    process = {}
    code, output, timeout, seconds = execute(
        [sys.executable, "-I", "-B", str(engine / "runner.py"), "rules", str(request_path)],
        ROOT, contract["evaluationSeconds"], metadata=process)
    (out / "evaluation.log").write_text(output)
    answers = read_json(out / "answers.json") if code == 0 and not timeout else {}
    accepted = code == 0 and not timeout and set(answers) == set(contract["expected"]) and all(
        sorted(map(tuple, answers[name])) == sorted(map(tuple, expected))
        for name, expected in contract["expected"].items())
    if digest(args.run / "receipt.json") != record["outerReceiptSha256"]:
        raise ValueError("suite source receipt changed during coverage query")
    if any(digest(ROOT / path) != sha for path, sha in bindings.items()):
        raise ValueError("coverage rule or checker changed during query")
    record.update(outcome="PASS" if accepted else "DENY", answers=answers,
        execution={"exit": code, "timeout": timeout, "seconds": seconds, **process},
        contract=args.contract, sourceInputs=bindings,
        scope="checked sealed suite file coverage only; not whole SMP or performance acceptance")
    (out / "receipt.json").write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"outcome": record["outcome"], "answers": answers,
                      "runtimeAdmitted": False, "performanceAdmitted": False}))
    return 0 if accepted else 2
