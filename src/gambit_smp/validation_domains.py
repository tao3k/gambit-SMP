"""Isolated, identity-bound unittest domains; never a research capability."""
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import sys
import time
import unittest


def leaves(suite):
    for test in suite:
        if isinstance(test, unittest.TestSuite):
            yield from leaves(test)
        else:
            yield test


def partition(suite):
    local, domains = [], {}
    for test in leaves(suite):
        domain = getattr(test, "validation_domain", None)
        if domain is None:
            local.append(test)
            continue
        if (not isinstance(domain, dict) or set(domain) != {"kind", "budgetSeconds", "workers"}
                or domain["kind"] != "sealed-research"
                or type(domain["budgetSeconds"]) is not int or domain["budgetSeconds"] <= 0
                or type(domain["workers"]) is not int or not 1 <= domain["workers"] <= 4):
            raise ValueError("invalid validation execution domain")
        key = json.dumps(domain, sort_keys=True)
        domains.setdefault(key, []).append(test)
    return unittest.TestSuite(local), [(json.loads(key), tests) for key, tests in domains.items()]


def run_domain(root, tests, policy, engine, out):
    from gambit_smp.framework import digest, execute
    from gambit_smp.research_kernel import manifest_paths
    started = time.monotonic()
    manifest = manifest_paths(engine)
    for name, sha in manifest["files"].items():
        if name.startswith("python/gambit_smp/"):
            original = root / "src" / name.removeprefix("python/")
            if not original.is_file() or digest(original) != sha:
                raise ValueError("validation engine does not match current implementation")
    expected = sorted(test.id() for test in tests)
    files = {str(Path(sys.modules[type(test).__module__].__file__).resolve().relative_to(root))
             for test in tests}
    inputs = {name: digest(root / name) for name in files}
    out.mkdir(parents=True, exist_ok=False)
    workers = min(policy["workers"], len(expected))
    selections = [expected[index::workers] for index in range(workers)]
    deadline = started + policy["budgetSeconds"]

    def launch(index):
        lane = out / str(index)
        lane.mkdir()
        request = {"schema": "sealed-validation-request.v1", "root": str(root),
                   "engineId": manifest["engineId"], "inputs": inputs,
                   "testIds": selections[index], "result": str(lane / "result.json")}
        path = lane / "request.json"
        path.write_text(json.dumps(request, sort_keys=True) + "\n")
        env = {"PATH": "/usr/bin:/bin", "HOME": os.environ.get("HOME", str(root)),
               "GAMBIT_SMP_ROOT": str(root), "GAMBIT_SMP_TEST_ENGINE": str(engine),
               "GAMBIT_SMP_TEST_ARTIFACTS": str(lane / "fixtures"),
               "LANG": "C", "LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"}
        metadata = {}
        argv = [manifest["hostTools"]["python"]["path"], "-I", "-B",
                str(engine / "python/gambit_smp/validation_domains.py"), str(path)]
        budget = max(.001, deadline - time.monotonic())
        code, log, timeout, seconds = execute(argv, root, budget, env=env, metadata=metadata)
        (lane / "process.log").write_text(log)
        result_path = lane / "result.json"
        result = json.loads(result_path.read_text()) if result_path.exists() else {}
        complete = (result.get("engineId") == manifest["engineId"]
                    and result.get("requestSHA") == digest(path)
                    and result.get("expectedTestIds") == selections[index]
                    and result.get("testsRun") == len(selections[index])
                    and set(result.get("outcomes", {})) == set(selections[index]))
        passed = (complete and code == 0 and not timeout
                  and metadata.get("parentReaped") is True
                  and metadata.get("processGroupQuiescent") is True
                  and all(value == "pass" for value in result["outcomes"].values()))
        return {"argv": argv, "environment": env, "exit": code, "timeout": timeout,
                "seconds": seconds, "budgetSeconds": budget, **metadata,
                "complete": complete, "passed": passed, "result": result,
                "expectedTestIds": selections[index]}

    with ThreadPoolExecutor(max_workers=workers) as pool:
        lanes = list(pool.map(launch, range(workers)))
    seconds = time.monotonic() - started
    manifest_paths(engine)
    stable = all(digest(root / name) == sha for name, sha in inputs.items())
    outcomes = {}
    for lane in lanes:
        actual = lane["result"].get("outcomes", {})
        for name in lane["expectedTestIds"]:
            outcomes[name] = actual.get(name, "error")
    receipt = {"schema": "sealed-validation-domain.v1", "engine": str(engine),
               "engineId": manifest["engineId"], "policy": policy, "seconds": seconds,
               "inputs": inputs, "expectedTestIds": expected, "outcomes": outcomes,
               "passed": stable and seconds <= policy["budgetSeconds"] and all(l["passed"] for l in lanes),
               "lanes": lanes, "artifacts": {str(p.relative_to(out)): digest(p)
                       for p in out.rglob("*") if p.is_file()}}
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


def check_domain(root, out, saved):
    from gambit_smp.framework import digest, relative
    from gambit_smp.research_kernel import manifest_paths
    engine = Path(saved["engine"])
    manifest = manifest_paths(engine)
    if saved.get("schema") != "sealed-validation-domain.v1" or manifest["engineId"] != saved["engineId"]:
        raise ValueError("validation domain engine identity mismatch")
    if any(digest(relative(out, name)) != sha for name, sha in saved["artifacts"].items()):
        raise ValueError("validation domain artifact identity mismatch")
    if any(digest(relative(root, name)) != sha for name, sha in saved["inputs"].items()):
        return False
    expected = saved["expectedTestIds"]
    lanes = saved["lanes"]
    for index, lane in enumerate(lanes):
        result_path, request_path = out / str(index) / "result.json", out / str(index) / "request.json"
        if not result_path.is_file() or not request_path.is_file():
            return False
        result, request = json.loads(result_path.read_text()), json.loads(request_path.read_text())
        if (result != lane["result"] or result.get("requestSHA") != digest(request_path)
                or result.get("engineId") != saved["engineId"]
                or request.get("engineId") != saved["engineId"]
                or request.get("inputs") != saved["inputs"]
                or result.get("expectedTestIds") != lane["expectedTestIds"]
                or request.get("testIds") != lane["expectedTestIds"]):
            raise ValueError("validation domain parent differs from raw child result")
    inventory = [name for lane in lanes for name in lane["expectedTestIds"]]
    return (saved["passed"] is True and saved["seconds"] <= saved["policy"]["budgetSeconds"]
            and len(expected) == len(set(expected)) and sorted(inventory) == expected
            and len(inventory) == len(set(inventory)) and set(saved["outcomes"]) == set(expected)
            and all(status == "pass" for status in saved["outcomes"].values())
            and all(lane["exit"] == 0 and not lane["timeout"] and lane["passed"]
                    and lane.get("parentReaped") is True and lane.get("processGroupQuiescent") is True
                    for lane in lanes))


def worker(path):
    engine = Path(__file__).resolve().parents[2]
    sys.path[:0] = [str(engine / "python"), str(engine / "native")]
    from gambit_smp.framework import digest, relative
    from gambit_smp.research_kernel import execution_identity
    manifest = execution_identity(engine)
    request = json.loads(path.read_text())
    if request.get("schema") != "sealed-validation-request.v1" or request["engineId"] != manifest["engineId"]:
        raise ValueError("unknown or mismatched validation request")
    root = Path(request["root"]).resolve()
    files = {name: relative(root, name) for name in request["inputs"]}
    if not files or any(not name.startswith("tests/") or not name.endswith(".py") for name in files):
        raise ValueError("identity-bound Python test fixtures required")
    if any(digest(source) != request["inputs"][name] for name, source in files.items()):
        raise ValueError("validation test fixture changed before loading")
    sys.path.insert(2, str(root))
    loader = unittest.TestLoader()
    suite = unittest.TestSuite(loader.loadTestsFromName(name) for name in request["testIds"])
    tests = list(leaves(suite))
    if (len(tests) != len(request["testIds"]) or sorted(t.id() for t in tests) != request["testIds"]
            or any(str(Path(sys.modules[type(t).__module__].__file__).resolve().relative_to(root)) not in files
                   for t in tests)):
        raise ValueError("validation selection escaped bound test inventory")
    class Result(unittest.TextTestResult):
        def __init__(self, *args):
            super().__init__(*args)
            self.outcomes = {}
        def addSuccess(self, test):
            super().addSuccess(test)
            self.outcomes.setdefault(test.id(), "pass")
        def addFailure(self, test, err):
            super().addFailure(test, err)
            self.outcomes[test.id()] = "failure"
        def addError(self, test, err):
            super().addError(test, err)
            self.outcomes[test.id()] = "error"
        def addSkip(self, test, reason):
            super().addSkip(test, reason)
            self.outcomes[test.id()] = "skip"
        def addExpectedFailure(self, test, err):
            super().addExpectedFailure(test, err)
            self.outcomes[test.id()] = "expected-failure"
        def addUnexpectedSuccess(self, test):
            super().addUnexpectedSuccess(test)
            self.outcomes[test.id()] = "unexpected-success"
        def addSubTest(self, test, subtest, err):
            super().addSubTest(test, subtest, err)
            if err is not None:
                self.outcomes[test.id()] = "failure"
    result = unittest.TextTestRunner(verbosity=2, resultclass=Result).run(suite)
    execution_identity(engine)
    if any(digest(source) != request["inputs"][name] for name, source in files.items()):
        raise ValueError("validation test fixture changed during execution")
    body = {"engineId": manifest["engineId"], "requestSHA": digest(path),
            "expectedTestIds": request["testIds"], "testsRun": result.testsRun, "outcomes": result.outcomes}
    with Path(request["result"]).open("x") as stream:
        json.dump(body, stream, indent=2)
    return 0 if result.wasSuccessful() and all(v == "pass" for v in result.outcomes.values()) else 1


if __name__ == "__main__":
    raise SystemExit(worker(Path(sys.argv[1]).resolve()))
