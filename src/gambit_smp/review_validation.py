"""Produce and recheck input-bound Python evidence-pipeline test receipts."""
import argparse
import hashlib
import importlib.metadata
import io
import json
import os
from pathlib import Path
import platform
import sys
import time
import unittest

from gambit_smp.framework import ROOT, digest, execute, positive_int
from gambit_smp.research_audit import local


EVIDENCE_TESTS = (
    "tests.test_ascent_program", "tests.test_ascent_review", "tests.test_evidence_index",
    "tests.test_research_audit", "tests.test_reasoning_history", "tests.test_retry_gate",
    "tests.test_protocol_evidence", "tests.test_protocol_report_links", "tests.test_recover_model",
    "tests.test_review_graph", "tests.test_review_validation", "tests.test_agent_context",
    "tests.test_history_journal", "tests.test_history_recovery", "tests.test_history_protocol",
)


def python_files(root):
    return sorted(str(path.relative_to(root)) for directory in ("src", "tests")
                  for path in (root / directory).rglob("*.py") if path.is_file())


def asset_files(root):
    return sorted(str(path.relative_to(root))
                  for directory in ("tests/fixtures", "evidence/dsl", "evidence/scenarios", "models/library")
                  for path in (root / directory).rglob("*")
                  if path.is_file() and path.suffix in (".ss", ".json", ".qnt"))


def environment():
    return {"python": sys.version, "executableSha256": digest(Path(sys.executable).resolve()),
            "platform": platform.platform(),
            "distributions": sorted([item.metadata.get("Name", "unknown"), item.version]
                                    for item in importlib.metadata.distributions())}


def changed_inputs(root, inputs):
    changed = []
    for path, expected in inputs.items():
        source = local(root, path)
        if not source.is_file() or digest(source) != expected:
            changed.append(path)
    return sorted(changed)


class Outcomes(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.outcomes = {}

    def record(self, test, status):
        previous = self.outcomes.get(test.id())
        if previous is None or previous == "pass":
            self.outcomes[test.id()] = status

    def addSuccess(self, test):
        super().addSuccess(test)
        self.record(test, "pass")

    def addFailure(self, test, error):
        super().addFailure(test, error)
        self.record(test, "failure")

    def addError(self, test, error):
        super().addError(test, error)
        self.record(test, "error")

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        self.record(test, "skip")

    def addExpectedFailure(self, test, error):
        super().addExpectedFailure(test, error)
        self.record(test, "expected-failure")

    def addUnexpectedSuccess(self, test):
        super().addUnexpectedSuccess(test)
        self.record(test, "unexpected-success")

    def addSubTest(self, test, subtest, error):
        super().addSubTest(test, subtest, error)
        if error is not None:
            self.record(test, "failure" if issubclass(error[0], test.failureException) else "error")


def test_ids(suite):
    return [identity for test in suite for identity in (
        test_ids(test) if isinstance(test, unittest.TestSuite) else [test.id()])]


def test_files(suite, root):
    files = set()
    for test in suite:
        if isinstance(test, unittest.TestSuite):
            files.update(test_files(test, root))
            continue
        path = Path(sys.modules[type(test).__module__].__file__).resolve()
        if path.is_relative_to(root):
            files.add(str(path.relative_to(root)))
    return sorted(files)


class ValidationOutput(io.StringIO):
    def __init__(self, journal=None):
        super().__init__()
        self.journal = journal

    def write(self, text):
        count = super().write(text)
        if self.journal is not None:
            self.journal.write(text)
            self.journal.flush()
        return count


def run_suite(root, suite, inputs, engine_inputs, profile, *, domain_out=None, journal=None):
    root = Path(root).resolve()
    expected = sorted(test_ids(suite))
    if len(expected) != len(set(expected)):
        raise ValueError("duplicate validation test identity")
    selected_files = test_files(suite, root)
    python_before = python_files(root)
    assets_before = asset_files(root)
    started = time.monotonic()
    from gambit_smp.validation_domains import partition, run_domain
    local_suite, domains = partition(suite)
    domain_results = []
    for index, (policy, tests) in enumerate(domains):
        if domain_out is None or not os.environ.get("GAMBIT_SMP_TEST_ENGINE"):
            raise ValueError("declared validation domain requires a sealed engine and receipt directory")
        engine = Path(os.environ["GAMBIT_SMP_TEST_ENGINE"]).resolve()
        domain_results.append(run_domain(root, tests, policy, engine, Path(domain_out) / str(index)))
    output = ValidationOutput(journal)
    result = unittest.TextTestRunner(stream=output, verbosity=2, resultclass=Outcomes).run(local_suite)
    for domain in domain_results:
        if set(result.outcomes) & set(domain["outcomes"]):
            raise ValueError("validation domain duplicated a test identity")
        result.outcomes.update(domain["outcomes"])
        result.testsRun += len(domain["expectedTestIds"])
        for lane in domain["lanes"]:
            output.write(lane["result"].get("log", ""))
        output.write(json.dumps(domain, sort_keys=True) + "\n")
    changed = sorted(set(changed_inputs(root, inputs)) | (set(python_before) ^ set(python_files(root)))
                     | (set(assets_before) ^ set(asset_files(root))))
    complete = (bool(expected) and bool(selected_files) and set(selected_files).issubset(inputs) and
                set(assets_before).issubset(inputs) and
                result.testsRun == len(expected) and set(result.outcomes) == set(expected))
    passed = (complete and not changed and all(status == "pass" for status in result.outcomes.values())
              and all(domain["passed"] for domain in domain_results))
    counts = {status: list(result.outcomes.values()).count(status) for status in
              ("failure", "error", "skip", "expected-failure", "unexpected-success")}
    return {"schema": "gambit-framework-validation.v1", "profile": profile,
            "status": "PASS" if passed else "DENY", "frameworkValidated": passed,
            "seconds": time.monotonic() - started, "testsRun": result.testsRun,
            "expectedTestIds": expected, "outcomes": dict(sorted(result.outcomes.items())),
            "failures": counts["failure"], "errors": counts["error"],
            "skipped": counts["skip"], "expectedFailures": counts["expected-failure"],
            "unexpectedSuccesses": counts["unexpected-success"],
            "executionDomains": domain_results,
            "completeTestInventory": complete, "changedInputs": changed,
            "pythonFiles": python_before, "assetFiles": assets_before,
            "testFiles": selected_files, "inputs": inputs,
            "engineInputs": engine_inputs, "environment": environment(),
            "executionAuthorized": False, "runtimeAdmitted": False,
            "scope": "Python framework tests and real ASCENT inference. Native Gambit candidate gates remain open."}, output.getvalue()


def load(root, path, required_inputs, engine_inputs, required_profile=None):
    """Recheck test coverage, output bytes and current identities before reuse."""
    path = Path(path).resolve()
    if path.is_dir():
        path = path / "receipt.json"
    content = path.read_bytes()
    saved = json.loads(content)
    if saved.get("schema") == "gambit-framework-validation-launch.v1":
        log = (path.parent / saved["producer"]["log"]["path"]).resolve()
        log.relative_to(path.parent)
        if digest(log) != saved["producer"]["log"]["sha256"]:
            raise ValueError("validation process log identity mismatch")
        return {"status": "TIMEOUT" if saved["producer"]["timeout"] else "ERROR",
                "frameworkValidated": False, "profile": saved["profile"],
                "receiptPath": str(path), "receiptSha256": hashlib.sha256(content).hexdigest(),
                "producer": saved["producer"], "testFiles": [], "testInputHashes": {}}
    if saved.get("schema") != "gambit-framework-validation.v1":
        raise ValueError("unknown framework validation receipt schema")
    if saved.get("profile") not in ("evidence-review", "full") or not saved.get("engineInputs"):
        raise ValueError("validation lacks a known profile or native ASCENT identity")
    log = (path.parent / saved["log"]["path"]).resolve()
    log.relative_to(path.parent)
    if digest(log) != saved["log"]["sha256"]:
        raise ValueError("validation log identity mismatch")
    child_path = path.parent / "test-result.json"
    if saved.get("testResultSha256") != digest(child_path):
        raise ValueError("validation child result identity mismatch")
    child = json.loads(child_path.read_text())
    producer = saved.get("producer", {})
    if "log" in producer:
        process_log = (path.parent / producer["log"]["path"]).resolve()
        process_log.relative_to(path.parent)
        if digest(process_log) != producer["log"]["sha256"]:
            raise ValueError("validation process log identity mismatch")
    expected, outcomes = saved["expectedTestIds"], saved["outcomes"]
    complete = (bool(expected) and len(expected) == len(set(expected)) and
                type(saved["testsRun"]) is int and
                saved["testsRun"] == len(expected) and set(outcomes) == set(expected))
    positive = complete and all(status == "pass" for status in outcomes.values())
    positive = positive and all(saved.get(field) == 0 for field in (
        "failures", "errors", "skipped", "expectedFailures", "unexpectedSuccesses"))
    positive = positive and saved.get("completeTestInventory") is True and not saved.get("changedInputs")
    positive = positive and saved.get("status") == "PASS" and saved.get("frameworkValidated") is True
    positive = positive and producer.get("exit") == 0 and producer.get("timeout") is False and "log" in producer
    from gambit_smp.validation_domains import check_domain
    for index, domain in enumerate(saved.get("executionDomains", [])):
        positive = positive and check_domain(Path(root).resolve(), path.parent / "domains" / str(index), domain)
    if producer.get("exit") == 0 and any(saved.get(key) != value for key, value in child.items()):
        raise ValueError("validation parent differs from child test result")
    changed = changed_inputs(root, saved["inputs"])
    uncovered = sorted(name for name, sha in required_inputs.items() if saved["inputs"].get(name) != sha)
    added_python = sorted(set(python_files(root)) ^ set(saved["pythonFiles"]))
    changed_assets = sorted(set(asset_files(root)) ^ set(saved.get("assetFiles", [])))
    backend_changed = saved["engineInputs"] != engine_inputs
    environment_changed = saved["environment"] != environment()
    profile_mismatch = required_profile is not None and saved["profile"] not in (required_profile, "full")
    accepted = positive and not changed and not uncovered and not added_python and not changed_assets and not backend_changed and not environment_changed and not profile_mismatch
    status = "PASS" if accepted else "STALE" if (changed or uncovered or added_python or changed_assets or backend_changed or environment_changed) else "INCOMPLETE_PROFILE" if profile_mismatch else "DENY"
    selected_files = saved["testFiles"]
    if not selected_files or not set(selected_files).issubset(saved["pythonFiles"]) or not set(selected_files).issubset(saved["inputs"]):
        raise ValueError("validation test files are not identity-bound")
    return {"schema": "gambit-framework-validation-summary.v1", "status": status,
            "frameworkValidated": accepted, "profile": saved["profile"],
            "receiptPath": str(path), "receiptSha256": hashlib.sha256(content).hexdigest(),
            "logSha256": saved["log"]["sha256"], "testsRun": saved["testsRun"],
            "seconds": saved["seconds"], "completeTestInventory": complete,
            "changedInputs": changed, "uncoveredInputs": uncovered,
            "changedPythonInventory": added_python, "changedAssetInventory": changed_assets,
            "backendChanged": backend_changed,
            "environmentChanged": environment_changed,
            "profileMismatch": profile_mismatch, "producer": producer,
            "testFiles": selected_files,
            "testInputHashes": {name: saved["inputs"][name] for name in selected_files},
            "testCurrentHashes": {name: digest(local(root, name)) if local(root, name).is_file() else None
                                  for name in selected_files},
            "testIds": expected, "executionAuthorized": False, "runtimeAdmitted": False}


def supervise(root, profile, model, out, timeout):
    """The parent records the real exit after native runtime teardown."""
    from gambit_smp.artifact_storage import runtime_output
    out = runtime_output(root, out)
    out.mkdir(parents=True, exist_ok=False)
    command = [sys.executable, "-m", "gambit_smp.review_validation", "--worker",
               "--profile", profile, "--out", str(out.resolve())]
    if model is not None:
        command.extend(("--model", model))
    process = {}
    code, output, timed_out, seconds = execute(command, root, timeout, metadata=process)
    log = out / "process.log"
    with log.open("x") as stream:
        stream.write(output)
    producer = {**process, "exit": code, "timeout": timed_out, "seconds": seconds,
                "budgetSeconds": timeout, "log": {"path": log.name, "sha256": digest(log)}}
    result_path = out / "test-result.json"
    if result_path.is_file():
        result = json.loads(result_path.read_text())
        result["producer"] = producer
        result["testResultSha256"] = digest(result_path)
        if code != 0 or timed_out:
            result["childStatus"] = result["status"]
            result.update(status="DENY", frameworkValidated=False)
    else:
        result = {"schema": "gambit-framework-validation-launch.v1", "profile": profile,
                  "status": "DENY", "frameworkValidated": False, "producer": producer}
    path = out / "receipt.json"
    with path.open("x") as stream:
        stream.write(json.dumps(result, indent=2) + "\n")
    return path, result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", choices=("evidence-review", "full"), default="evidence-review")
    parser.add_argument("--model")
    parser.add_argument("--timeout", type=positive_int, default=300)
    parser.add_argument("--worker", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    from gambit_smp.artifact_storage import runtime_output
    args.out = runtime_output(ROOT, args.out)
    if args.out.exists() and not args.worker:
        parser.error("validation output directory must be new")
    if not args.worker:
        path, receipt = supervise(ROOT.resolve(), args.profile, args.model, args.out, args.timeout)
        print(json.dumps({"status": receipt["status"], "profile": args.profile,
                          "testsRun": receipt.get("testsRun"), "receiptPath": str(path),
                          "producerExit": receipt["producer"]["exit"],
                          "timeout": receipt["producer"]["timeout"]}, sort_keys=True))
        return 0 if receipt["frameworkValidated"] else 2
    from gambit_smp.ascent_review import collect
    from gambit_smp.ascent_program import engine_api

    root = ROOT.resolve()
    inputs = collect(root, task_model=args.model)[1]
    for name in python_files(root) + asset_files(root) + ["pyproject.toml", "uv.lock", ".python-version"]:
        source = root / name
        if source.is_file():
            inputs[name] = digest(source)
    loader = unittest.TestLoader()
    suite = (loader.discover(str(root / "tests"), top_level_dir=str(root)) if args.profile == "full"
             else loader.loadTestsFromNames(EVIDENCE_TESTS))
    args.out.mkdir(parents=True, exist_ok=True)
    log = args.out / "tests.log"
    with log.open("x") as stream:
        with engine_api() as (_, engine_inputs):
            receipt, output = run_suite(root, suite, inputs, engine_inputs, args.profile,
                                        domain_out=args.out / "domains", journal=stream)
    receipt["log"] = {"path": log.name, "sha256": digest(log)}
    with (args.out / "test-result.json").open("x") as stream:
        stream.write(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({key: receipt[key] for key in ("status", "profile", "testsRun", "seconds",
                     "failures", "errors", "skipped", "changedInputs")}, sort_keys=True))
    return 0 if receipt["frameworkValidated"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
