"""Produce and recheck input-bound Python evidence-pipeline test receipts."""
import argparse
from contextlib import ExitStack, contextmanager
import hashlib
import importlib.metadata
import io
import json
import math
import os
from pathlib import Path
import platform
import secrets
import signal
import sys
import time
import unittest
from concurrent.futures import ProcessPoolExecutor
from multiprocessing import get_context

from gambit_smp.framework import ROOT, digest, execute, positive_int
from gambit_smp.research_audit import local


EVIDENCE_TESTS = (
    "tests.test_ascent_program", "tests.test_ascent_review", "tests.test_evidence_index",
    "tests.test_research_audit", "tests.test_reasoning_history", "tests.test_retry_gate",
    "tests.test_protocol_evidence", "tests.test_protocol_report_links", "tests.test_recover_model",
    "tests.test_review_graph", "tests.test_review_validation", "tests.test_agent_context",
    "tests.test_history_journal", "tests.test_history_recovery", "tests.test_history_protocol",
    "tests.test_progressive_clues", "tests.test_trajectory_exploration", "tests.test_evidence_views",
)


def python_files(root):
    return sorted(str(path.relative_to(root)) for directory in ("src", "tests")
                  for path in (root / directory).rglob("*.py") if path.is_file())


def asset_files(root):
    assets = {str(path.relative_to(root))
              for directory in ("tests/fixtures", "evidence/dsl", "evidence/scenarios", "models/library")
              for path in (root / directory).rglob("*")
              if path.is_file() and (path.suffix in (".ss", ".json", ".qnt", ".lean")
                                     or path.name == "lean-toolchain")}
    assets.update(str(path.relative_to(root))
                  for directory in (".github", "integrations")
                  for path in (root / directory).rglob("*")
                  if path.is_file() and not path.is_symlink()
                  and not any(part in {".venv", ".data", ".cache", "__pycache__"}
                              for part in path.relative_to(root).parts))
    return sorted(assets)


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
        self.timings = {}
        self.started = {}

    def startTest(self, test):
        self.started[test.id()] = time.monotonic()
        super().startTest(test)

    def stopTest(self, test):
        elapsed = time.monotonic() - self.started.pop(test.id())
        self.timings[test.id()] = elapsed
        self.stream.write("  elapsed " + json.dumps({"test": test.id(), "seconds": elapsed}) + "\n")
        self.stream.flush()
        super().stopTest(test)

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
    if domains and (domain_out is None or not os.environ.get("GAMBIT_SMP_TEST_ENGINE")):
        raise ValueError("declared validation domain requires a sealed engine and receipt directory")
    output = ValidationOutput(journal)
    # Spawn avoids sharing loaded Library state or unittest patches with domains.
    domain_started = time.monotonic()
    from contextlib import ExitStack
    resources=ExitStack()
    pool=None
    try:
        if domains and os.environ.get('GAMBIT_SMP_TASK_ID') and not os.environ.get('GAMBIT_SMP_TASK_SOCKET'):
            from gambit_smp.task_broker import serve
            resources.enter_context(serve(root,os.environ['GAMBIT_SMP_TASK_ID'],os.environ['GAMBIT_SMP_TASK_RUN'],int(os.environ['GAMBIT_SMP_TASK_LOCK_FD'])))
        pool = ProcessPoolExecutor(max_workers=len(domains), mp_context=get_context("spawn")) if domains else None
        futures = [pool.submit(run_domain, root, tests, policy,
                               Path(os.environ["GAMBIT_SMP_TEST_ENGINE"]).resolve(),
                               Path(domain_out) / str(index), started=domain_started)
                   for index, (policy, tests) in enumerate(domains)]
        from gambit_smp.validation_domains import leaves
        early, deferred = [], []
        for test in leaves(local_suite):
            (deferred if getattr(test, "validation_after_domains", False) else early).append(test)
        domain_results, domains_joined = [], False

        def join_domains():
            nonlocal domain_results, domains_joined
            if not domains_joined:
                domain_results = [future.result() for future in futures]
                domains_joined = True

        class DomainBarrier(unittest.TestSuite):
            def run(self, result, debug=False):
                join_domains()
                return super().run(result, debug)

        scheduled = unittest.TestSuite([unittest.TestSuite(early), DomainBarrier(deferred)])
        from gambit_smp.validation_domains import isolated_test_context
        with isolated_test_context():
            result = unittest.TextTestRunner(stream=output, verbosity=2, resultclass=Outcomes).run(scheduled)
        join_domains()
    finally:
        if pool is not None:
            pool.shutdown(wait=True, cancel_futures=True)
        resources.close()
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
            "localTestSeconds": result.timings,
            "failures": counts["failure"], "errors": counts["error"],
            "skipped": counts["skip"], "expectedFailures": counts["expected-failure"],
            "unexpectedSuccesses": counts["unexpected-success"],
            "executionDomains": domain_results,
            "validationSchedule": {"kind": "spawn-domain-overlap", "deferredTestIds": sorted(t.id() for t in deferred),
                                   "domainBudgetOrigin": "parent-submission"},
            "completeTestInventory": complete, "changedInputs": changed,
            "pythonFiles": python_before, "assetFiles": assets_before,
            "testFiles": selected_files, "inputs": inputs,
            "engineInputs": engine_inputs, "environment": environment(),
            "executionAuthorized": False, "runtimeAdmitted": False,
            "scope": "Python framework tests and real ASCENT inference. Native Gambit candidate gates remain open."}, output.getvalue()


def _producer_completed(producer):
    return (producer.get("exit") == 0 and producer.get("timeout") is False
            and producer.get("parentReaped") is True
            and producer.get("processGroupQuiescent") is True)


def load(root, path, required_inputs, engine_inputs, required_profile=None):
    """Recheck test coverage, output bytes and current identities before reuse."""
    path = Path(path).resolve()
    if path.is_dir():
        path = path / "receipt.json"
    content = path.read_bytes()
    saved = json.loads(content)
    for name, label in (("log", "process"), ("progressLog", "progress")):
        if name in saved.get("producer", {}):
            reference = saved["producer"][name]
            observed = (path.parent / reference["path"]).resolve()
            observed.relative_to(path.parent)
            if digest(observed) != reference["sha256"]:
                raise ValueError("validation " + label + " log identity mismatch")
    if saved.get("schema") == "gambit-framework-validation-launch.v1":
        return {"status": ("INTERRUPTED" if saved["producer"].get("interruptionSignal") is not None
                           else "TIMEOUT" if saved["producer"]["timeout"] else "ERROR"),
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
    expected, outcomes = saved["expectedTestIds"], saved["outcomes"]
    complete = (bool(expected) and len(expected) == len(set(expected)) and
                type(saved["testsRun"]) is int and
                saved["testsRun"] == len(expected) and set(outcomes) == set(expected))
    positive = complete and all(status == "pass" for status in outcomes.values())
    positive = positive and all(saved.get(field) == 0 for field in (
        "failures", "errors", "skipped", "expectedFailures", "unexpectedSuccesses"))
    positive = positive and saved.get("completeTestInventory") is True and not saved.get("changedInputs")
    positive = positive and saved.get("status") == "PASS" and saved.get("frameworkValidated") is True
    positive = positive and _producer_completed(producer) and "log" in producer
    from gambit_smp.validation_domains import check_domain
    for index, domain in enumerate(saved.get("executionDomains", [])):
        positive = positive and check_domain(Path(root).resolve(), path.parent / "domains" / str(index), domain)
    if _producer_completed(producer) and any(saved.get(key) != value for key, value in child.items()):
        raise ValueError("validation parent differs from child test result")
    changed = changed_inputs(root, saved["inputs"])
    uncovered = sorted(name for name, sha in required_inputs.items() if saved["inputs"].get(name) != sha)
    added_python = sorted(set(python_files(root)) ^ set(saved["pythonFiles"]))
    changed_assets = sorted(set(asset_files(root)) ^ set(saved.get("assetFiles", [])))
    backend_changed = saved["engineInputs"] != engine_inputs
    environment_changed = saved["environment"] != environment()
    profile_mismatch = required_profile is not None and saved["profile"] not in (required_profile, "full")
    accepted = positive and not changed and not uncovered and not added_python and not changed_assets and not backend_changed and not environment_changed and not profile_mismatch
    status = ("PASS" if accepted else "INTERRUPTED" if producer.get("interruptionSignal") is not None
              else "STALE" if (changed or uncovered or added_python or changed_assets or backend_changed or environment_changed)
              else "INCOMPLETE_PROFILE" if profile_mismatch else "DENY")
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


class ValidationProgress:
    """Decode the owned journal; registered Scheme rules admit each frontier."""
    def __init__(self, root, out, process, epoch):
        self.root, self.out, self.process, self.epoch = root, out, process, epoch
        self.resources = ExitStack()
        self.session = self.progress = None
        self.inputs, self.position, self.pending = {}, 0, ""
        self.inventory = None
        self.witness = None

    def policy(self):
        if self.session is None:
            from gambit_smp.ascent_program import definitions, load_component_catalog
            catalog = load_component_catalog(self.root / "evidence/dsl/components.json",
                entry="validation-progress", constructor="make-validation-progress", trusted=True)
            module, binding = self.resources.enter_context(definitions(catalog))
            with module.call("make-validation-progress") as value:
                self.session = value.open_session()
            self.resources.callback(self.session.close)
            self.inputs = binding["sourceInputs"]
        self.session.replace({})
        result = self.session.run()
        handle = self.session.result(result)
        try:
            windows = result["relations"]["watchdog_window"]
            if (not result["complete"] or len(windows) != 1
                    or type(windows[0][0]) is not int or windows[0][0] <= 0):
                raise ValueError("one positive registered inactivity window required")
            return windows[0][0]
        finally:
            handle.close()

    def observe(self, kind):
        self.policy()
        self.session.replace({"watchdog_observation": [(kind,)]})
        result = self.session.run()
        handle = self.session.result(result)
        try:
            if not result["complete"]:
                raise ValueError("incomplete watchdog assessment")
            return result["relations"]["watchdog_assessment"]
        finally:
            handle.close()

    def __call__(self, _stdout, _stderr):
        path = self.out / "inventory.json"
        if not path.is_file():
            return 0
        if self.inventory is None:
            inventory = json.loads(path.read_bytes())
            if (inventory.get("schema") != "gambit-validation-inventory.v1"
                    or inventory.get("epoch") != self.epoch
                    or inventory.get("actor") != str(self.process.get("pid"))
                    or not isinstance(inventory.get("tests"), list)
                    or any(not isinstance(name, str) or not name for name in inventory["tests"])
                    or len(set(inventory["tests"])) != len(inventory["tests"])
                    or not isinstance(inventory.get("source"), str)):
                raise ValueError("validation journal producer/inventory identity mismatch")
            self.policy()
            from gambit_smp.process_observation import EvidenceProgress
            actor, source = inventory["actor"], inventory["source"]
            contracts = [(test, actor, self.epoch, "completed-test", source)
                         for test in inventory["tests"]]
            facts = {"progress_contract": contracts,
                     "progress_active": [row[:3] for row in contracts],
                     "progress_cursor": [(*row, 0) for row in contracts]}
            self.progress = EvidenceProgress(self.session, facts, lambda *_: self.sample)
            self.inventory = digest(path)
        elif digest(path) != self.inventory:
            raise ValueError("validation progress inventory changed")
        journal = self.out / "tests.log"
        if not journal.exists():
            return self.progress.renewals
        with journal.open() as stream:
            stream.seek(self.position)
            self.pending += stream.read()
            self.position = stream.tell()
        lines = self.pending.split("\n")
        self.pending = lines.pop()
        self.sample = {"progress_sample": [], "progress_attested": [], "progress_completed": []}
        for index, line in enumerate(lines):
            if not line.startswith("  elapsed "):
                continue
            try:
                event = json.loads(line.removeprefix("  elapsed "))
            except json.JSONDecodeError:
                continue
            if (not isinstance(event, dict) or not isinstance(event.get("test"), str)
                    or type(event.get("seconds")) not in (int, float)
                    or not math.isfinite(event["seconds"]) or event["seconds"] < 0):
                continue
            identity = f"{self.position}:{index}"
            contract = self.progress.facts["progress_contract"]
            actor = str(self.process["pid"])
            source = contract[0][-1] if contract else "unbound"
            self.sample["progress_sample"].append(
                (identity, event["test"], actor, self.epoch, "completed-test", source, 1))
            self.sample["progress_attested"].append((identity,))
            self.sample["progress_completed"].append((identity,))
        if self.sample["progress_sample"]:
            self.progress("", "")
            self.witness = self.progress.witness
            record = {key: value for key, value in self.witness.items()
                      if key not in ("cursorBefore", "cursorAfter")}
            record.update(cursorProjection="changed-keys",
                          cursorBefore=[row[:6] for row in self.witness["advanced"]],
                          cursorAfter=[[*row[:5], row[6]] for row in self.witness["advanced"]])
            with (self.out / "progress.jsonl").open("a") as stream:
                stream.write(json.dumps(record, sort_keys=True) + "\n")
        return self.progress.renewals

    def close(self):
        self.resources.close()


class _ValidationInterrupted(BaseException):
    def __init__(self, signum):
        self.signum = signum


@contextmanager
def _interruptible_validation():
    def interrupt(signum, _frame):
        raise _ValidationInterrupted(signum)
    previous = signal.signal(signal.SIGTERM, interrupt)
    try:
        yield
    finally:
        signal.signal(signal.SIGTERM, previous)


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
    epoch = secrets.token_hex(16)
    (out / "context.json").write_text(json.dumps({"epoch": epoch}) + "\n")
    progress = ValidationProgress(root, out, process, epoch)
    interruption = None
    started = time.monotonic()
    try:
        configured_window = progress.policy()
        window = configured_window if timeout is None else timeout
        with _interruptible_validation():
            code, output, timed_out, seconds = execute(command, root, window, metadata=process,
                                                      progress_check=progress)
        assessment = progress.observe("inactivity-expired") if timed_out else []
    except (KeyboardInterrupt, _ValidationInterrupted) as error:
        interruption = getattr(error, "signum", signal.SIGINT)
        code, timed_out, seconds = None, False, time.monotonic() - started
        output = "Supervisor externally interrupted; partial worker output is retained in tests.log.\n"
        assessment = progress.observe("external-interruption")
    finally:
        progress.close()
    log = out / "process.log"
    with log.open("x") as stream:
        stream.write(output)
    producer = {**process, "exit": code, "timeout": timed_out, "seconds": seconds,
                "budgetSeconds": window, "watchdog": "scheme-admitted-test-inactivity",
                "watchdogAssessment": assessment, "interruptionSignal": interruption,
                "progressInputs": progress.inputs,
                "log": {"path": log.name, "sha256": digest(log)}}
    progress_log = out / "progress.jsonl"
    if progress_log.is_file():
        producer["progressLog"] = {"path": progress_log.name, "sha256": digest(progress_log)}
    result_path = out / "test-result.json"
    if result_path.is_file():
        result = json.loads(result_path.read_text())
        result["producer"] = producer
        result["testResultSha256"] = digest(result_path)
        if not _producer_completed(producer):
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
    parser.add_argument("--timeout", type=positive_int,
                        help="explicit inactivity-window override; default comes from the registered Scheme policy")
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
    context = json.loads((args.out / "context.json").read_text())
    inventory = {"schema": "gambit-validation-inventory.v1", "epoch": context["epoch"],
                 "actor": str(os.getpid()), "tests": sorted(test_ids(suite)),
                 "source": hashlib.sha256(json.dumps(inputs, sort_keys=True).encode()).hexdigest()}
    pending_inventory = args.out / "inventory.pending"
    pending_inventory.write_text(json.dumps(inventory, sort_keys=True) + "\n")
    pending_inventory.replace(args.out / "inventory.json")
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


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('validate-review')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('validate-review', main))
