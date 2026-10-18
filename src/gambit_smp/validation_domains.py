"""Isolated, identity-bound unittest domains; never a research capability."""
from concurrent.futures import ThreadPoolExecutor
from contextlib import closing
import json
import os
import sqlite3
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


def subtest_outcome(test, err):
    if err is None:
        return None
    return "failure" if issubclass(err[0], test.failureException) else "error"


def partition(suite):
    local, domains = [], {}
    for test in leaves(suite):
        domain = getattr(test, "validation_domain", None)
        if domain is None:
            local.append(test)
            continue
        if (not isinstance(domain, dict) or not {"kind", "budgetSeconds", "workers"} <= set(domain)
                or set(domain) - {"kind", "budgetSeconds", "workers", "processesPerWorker"}
                or domain["kind"] != "sealed-research"
                or type(domain["budgetSeconds"]) is not int or domain["budgetSeconds"] <= 0
                or not (domain["workers"] == "auto" or
                        (type(domain["workers"]) is int and 1 <= domain["workers"] <= 4))
                or type(domain.get("processesPerWorker", 1)) is not int
                or domain.get("processesPerWorker", 1) < 1):
            raise ValueError("invalid validation execution domain")
        key = json.dumps(domain, sort_keys=True)
        domains.setdefault(key, []).append(test)
    return unittest.TestSuite(local), [(json.loads(key), tests) for key, tests in domains.items()]


def claim_test(connection, lane):
    """A killed worker's claim is retained, never reassigned within a run."""
    connection.execute("BEGIN IMMEDIATE")
    try:
        row = connection.execute("SELECT id FROM jobs WHERE lane IS NULL ORDER BY ordinal LIMIT 1").fetchone()
        if row:
            connection.execute("UPDATE jobs SET lane=? WHERE id=? AND lane IS NULL", (lane, row[0]))
        connection.commit()
        return row[0] if row else None
    except BaseException:
        connection.rollback()
        raise


def selected_workers(policy, cpu_capacity, test_count):
    if type(cpu_capacity) is not int or cpu_capacity < 1 or type(test_count) is not int or test_count < 1:
        raise ValueError("positive observed capacity and nonempty inventory required")
    requested = policy["workers"]
    processes = policy.get("processesPerWorker", 1)
    if type(processes) is not int or processes < 1:
        raise ValueError("positive declared process demand required")
    if requested != "auto" and (type(requested) is not int or not 1 <= requested <= 4):
        raise ValueError("invalid validation worker selection")
    capacity = max(1, cpu_capacity // processes)
    return min(capacity, test_count, capacity if requested == "auto" else requested)


def owner_complete(owner, engine_id):
    if (owner.get("exit") != 0 or owner.get("forcedTermination") is not False
            or owner.get("parentReaped") is not True or owner.get("terminalIdentityError") is not None):
        return False
    delegated = owner.get("requestIdentityAuthority") == "sealed-child-full-before-and-after"
    return (not delegated or owner.get("engineId") == engine_id) and all(
        row.get("requestCompleted") is True and row.get("timeout") is False
        and (not delegated or (row.get("response", {}).get("engineId") == engine_id
                              and row.get("response", {}).get("outcome") == "PASS"))
        for row in owner["requests"])


def owner_artifacts_match(owner):
    from gambit_smp.framework import digest
    if owner.get("requestIdentityAuthority") != "sealed-child-full-before-and-after":
        return True
    try:
        for row in owner["requests"]:
            request = Path(row["requestArchive"]["archivePath"])
            response = Path(row["responseArchive"]["archivePath"])
            if (digest(request) != row["requestSha256"] or digest(response) != row["responseSha256"]
                    or json.loads(response.read_bytes()) != row["response"]):
                return False
            for item in [row["requestArchive"], row["responseArchive"], row["metadataArchive"], *row["sourceArchives"]]:
                if digest(Path(item["archivePath"])) != item["sha256"]:
                    return False
            metadata = json.loads(Path(row["metadataArchive"]["archivePath"]).read_bytes())
            sources = {item["originalPath"]: item["sha256"] for item in row["sourceArchives"]}
            if (any(sources.get(path) != sha for path, sha in metadata["ruleSourceInputs"].items())
                    or any(sources.get(path) != sha for path, sha in json.loads(request.read_bytes()).get("observationInputs", {}).items())):
                return False
    except (OSError, ValueError, KeyError, TypeError):
        return False
    return True


def run_domain(root, tests, policy, engine, out, *, started=None):
    from gambit_smp.framework import available_processors, digest, execute
    from gambit_smp.research_kernel import manifest_paths
    now = time.monotonic()
    if started is None:
        started = now
    elif type(started) not in (int, float) or not 0 < started <= now:
        raise ValueError("domain launch time cannot renew or extend its budget")
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
    cpu_capacity = available_processors()
    workers = selected_workers(policy, cpu_capacity, len(expected))
    queue = out / "queue.sqlite"
    with closing(sqlite3.connect(queue)) as db, db:
        db.execute("CREATE TABLE jobs (ordinal INTEGER UNIQUE, id TEXT PRIMARY KEY, lane INTEGER)")
        db.executemany("INSERT INTO jobs VALUES (?, ?, NULL)", enumerate(expected))
    deadline = started + policy["budgetSeconds"]

    def launch(index):
        lane = out / str(index)
        lane.mkdir()
        request = {"schema": "sealed-validation-request.v1", "root": str(root),
                   "engineId": manifest["engineId"], "inputs": inputs,
                   "testIds": expected, "queue": str(queue), "lane": index,
                   "hostCpuCapacity": cpu_capacity, "selectedWorkers": workers,
                   "processesPerWorker": policy.get("processesPerWorker", 1),
                   "deadline": deadline,
                   "result": str(lane / "result.json")}
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
        with closing(sqlite3.connect(queue)) as db:
            selected = [row[0] for row in db.execute("SELECT id FROM jobs WHERE lane=? ORDER BY ordinal", (index,))]
        complete = (result.get("engineId") == manifest["engineId"]
                    and result.get("requestSHA") == digest(path)
                    and result.get("expectedTestIds") == selected
                    and result.get("testsRun") == len(selected)
                    and set(result.get("outcomes", {})) == set(selected))
        owner_path = lane / "evaluation-owner/receipt.json"
        owner = json.loads(owner_path.read_text()) if owner_path.is_file() else None
        owner_valid = owner is None or (owner_complete(owner, manifest["engineId"]) and owner_artifacts_match(owner))
        passed = (complete and code == 0 and not timeout
                  and metadata.get("parentReaped") is True
                  and metadata.get("processGroupQuiescent") is True
                  and owner_valid and all(value == "pass" for value in result["outcomes"].values()))
        return {"argv": argv, "environment": env, "exit": code, "timeout": timeout,
                "seconds": seconds, "budgetSeconds": budget, **metadata,
                "complete": complete, "ownerComplete": owner_valid, "passed": passed, "result": result,
                "expectedTestIds": selected}

    with ThreadPoolExecutor(max_workers=workers) as pool:
        lanes = list(pool.map(launch, range(workers)))
    manifest_paths(engine)
    stable = all(digest(root / name) == sha for name, sha in inputs.items())
    outcomes = {name: "error" for name in expected}
    for lane in lanes:
        actual = lane["result"].get("outcomes", {})
        for name in lane["expectedTestIds"]:
            outcomes[name] = actual.get(name, "error")
    artifacts = {str(p.relative_to(out)): digest(p) for p in out.rglob("*") if p.is_file()}
    seconds = time.monotonic() - started
    receipt = {"schema": "sealed-validation-domain.v1", "engine": str(engine),
               "engineId": manifest["engineId"], "policy": policy, "seconds": seconds,
               "hostCpuCapacity": cpu_capacity, "selectedWorkers": workers,
               "inputs": inputs, "expectedTestIds": expected, "outcomes": outcomes,
               "passed": stable and seconds <= policy["budgetSeconds"] and all(l["passed"] for l in lanes)
                         and all(value == "pass" for value in outcomes.values()),
               "lanes": lanes, "artifacts": artifacts}
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
    if saved["policy"].get("workers") == "auto":
        workers = selected_workers(saved["policy"], saved.get("hostCpuCapacity"), len(expected))
        if saved.get("selectedWorkers") != workers or len(lanes) != workers:
            return False
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
                or request.get("testIds") != (expected if "queue" in request else lane["expectedTestIds"])):
            raise ValueError("validation domain parent differs from raw child result")
        if "queue" in request:
            if saved["policy"].get("workers") == "auto" and (
                    request.get("hostCpuCapacity") != saved["hostCpuCapacity"]
                    or request.get("selectedWorkers") != saved["selectedWorkers"]
                    or request.get("processesPerWorker", 1) != saved["policy"].get("processesPerWorker", 1)):
                return False
            with closing(sqlite3.connect("file:" + str(out / "queue.sqlite") + "?mode=ro", uri=True)) as db:
                actual = [row[0] for row in db.execute("SELECT id FROM jobs WHERE lane=? ORDER BY ordinal", (index,))]
            if actual != lane["expectedTestIds"]:
                raise ValueError("validation queue assignment differs from terminal child inventory")
            owner_path = out / str(index) / "evaluation-owner/receipt.json"
            if owner_path.is_file():
                owner = json.loads(owner_path.read_text())
                if not owner_complete(owner, saved["engineId"]) or not owner_artifacts_match(owner):
                    return False
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
            self.stream.writeln(self._exc_info_to_string(err, test))
        def addError(self, test, err):
            super().addError(test, err)
            self.outcomes[test.id()] = "error"
            self.stream.writeln(self._exc_info_to_string(err, test))
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
                outcome = subtest_outcome(test, err)
                if self.outcomes.get(test.id()) != "error":
                    self.outcomes[test.id()] = outcome
                self.stream.writeln(self._exc_info_to_string(err, subtest))
    outcomes, selected, count = {}, [], 0
    if "queue" in request:
        queue = Path(request["queue"]).resolve(strict=True)
        if queue != path.parent.parent / "queue.sqlite" or type(request.get("lane")) is not int:
            raise ValueError("validation queue escaped the run directory")
        by_id = {test.id(): test for test in tests}
        from gambit_smp.evidence_capabilities import evaluation_owner
        from gambit_smp.ascent_program import session_construction_slot, sealed_api_boundary
        with sealed_api_boundary(engine), \
                session_construction_slot(queue.parent / "session-construction.lock", request["deadline"]), \
                evaluation_owner(engine, path.parent / "evaluation-owner", request["deadline"]) as owner, \
                closing(sqlite3.connect(queue, timeout=1)) as db, (path.parent / "observations.jsonl").open("x") as log:
            inventory = [row[0] for row in db.execute("SELECT id FROM jobs ORDER BY ordinal")]
            if inventory != request["testIds"]:
                raise ValueError("validation queue inventory differs from bound request")
            while (name := claim_test(db, request["lane"])) is not None:
                selected.append(name)
                started = time.monotonic()
                log.write(json.dumps({"test": name, "event": "started"}) + "\n")
                log.flush()
                result = unittest.TextTestRunner(verbosity=2, resultclass=Result).run(unittest.TestSuite([by_id[name]]))
                count += result.testsRun
                outcomes.update(result.outcomes)
                log.write(json.dumps({"test": name, "event": "finished", "seconds": time.monotonic() - started,
                                      "outcome": result.outcomes.get(name, "error")}) + "\n")
                log.flush()
        if owner.receipt is not None and (owner.receipt["exit"] != 0 or owner.receipt["forcedTermination"]):
            raise ValueError("sealed evaluation owner did not exit cleanly")
    else:
        from gambit_smp.ascent_program import sealed_api_boundary
        with sealed_api_boundary(engine):
            result = unittest.TextTestRunner(verbosity=2, resultclass=Result).run(suite)
        selected, count, outcomes = request["testIds"], result.testsRun, result.outcomes
    execution_identity(engine)
    if any(digest(source) != request["inputs"][name] for name, source in files.items()):
        raise ValueError("validation test fixture changed during execution")
    body = {"engineId": manifest["engineId"], "requestSHA": digest(path),
            "expectedTestIds": selected, "testsRun": count, "outcomes": outcomes}
    with Path(request["result"]).open("x") as stream:
        json.dump(body, stream, indent=2)
    return 0 if count == len(selected) and all(v == "pass" for v in outcomes.values()) else 1


if __name__ == "__main__":
    raise SystemExit(worker(Path(sys.argv[1]).resolve()))
