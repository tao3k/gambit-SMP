import json
from concurrent.futures import ThreadPoolExecutor
from contextlib import closing
import sqlite3
import sys
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, MagicMock
from types import SimpleNamespace
import time

from gambit_smp.framework import digest
from gambit_smp.validation_domains import check_domain, partition, claim_test, run_domain, owner_complete, owner_artifacts_match, selected_workers, subtest_outcome
from gambit_smp.evidence_capabilities import EvaluationOwner, evaluation_owner, evaluate_observations, archive_bytes


class ValidationDomainTests(unittest.TestCase):
    def test_owner_metadata_reuse_is_not_a_request_completion(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'engine.json').write_text('exact manifest bytes')
            owner = EvaluationOwner(root, root / 'owner', time.monotonic() + 10)
            with patch('gambit_smp.research_kernel.execution_origin'), \
                    patch('gambit_smp.research_kernel.execution_identity',
                          return_value={'engineId': 'bound', 'files': {}}) as check:
                self.assertEqual(owner.policy_identity()['engineId'], 'bound')
                self.assertEqual(owner.policy_identity()['engineId'], 'bound')
                self.assertEqual(check.call_count, 1)
                self.assertEqual(owner.records, [])
                self.assertIsNone(owner.process)
                self.assertIsNone(owner.receipt)
                (root / 'engine.json').write_text('changed manifest')
                with self.assertRaisesRegex(ValueError, 'manifest changed'):
                    owner.policy_identity()
                owner.closed = True
                with self.assertRaisesRegex(ValueError, 'closed'):
                    owner.policy_identity()

    def test_subtest_assertions_and_runtime_errors_keep_distinct_outcomes(self):
        self.assertIsNone(subtest_outcome(self, None))
        for exception, expected in ((AssertionError, 'failure'),
                                    (TimeoutError, 'error'), (ValueError, 'error')):
            try:
                raise exception('retained diagnostic')
            except exception:
                self.assertEqual(expected, subtest_outcome(self, sys.exc_info()))

    def test_unfinished_owner_does_not_wait_on_its_child_construction_permit(self):
        from gambit_smp.ascent_program import session_construction_slot
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            owner = EvaluationOwner(root, root, time.monotonic() + 1)
            owner.process = MagicMock(returncode=0, pid=123)
            owner.log = MagicMock()
            owner.argv = ['bound-worker']
            owner.engine_id = 'bound'
            owner.records = [{'requestCompleted': False}]
            (root / 'stderr.log').write_bytes(b'')
            with session_construction_slot(root / 'lock', owner.deadline), \
                    patch('gambit_smp.ascent_program.construction_admission') as admission, \
                    patch('gambit_smp.research_kernel.execution_identity', return_value={'engineId': 'bound'}):
                owner.close()
                admission.assert_not_called()
            self.assertFalse(owner.receipt['forcedTermination'])
            self.assertLessEqual(owner.process.wait.call_args.kwargs['timeout'], 1)

    def test_construction_admission_preserves_deadline_and_releases_after_error(self):
        import fcntl
        from gambit_smp.ascent_program import session_construction_slot, construction_admission, construction_slot
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "construction.lock"
            with session_construction_slot(path, time.monotonic() + 1):
                with self.assertRaisesRegex(RuntimeError, "construction"):
                    with construction_admission():
                        with self.assertRaises(BlockingIOError):
                            with path.open("rb") as other:
                                fcntl.flock(other.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                        raise RuntimeError("construction failed")
                with construction_admission():
                    self.assertEqual(path, construction_slot()[0])
                    with construction_admission():
                        with path.open('rb') as other, self.assertRaises(BlockingIOError):
                            fcntl.flock(other.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                with self.assertRaisesRegex(ValueError, "nested"):
                    with session_construction_slot(path, time.monotonic() + 1):
                        self.fail("nested admission")
            self.assertIsNone(construction_slot())
            with session_construction_slot(path, time.monotonic() - 1):
                with self.assertRaisesRegex(TimeoutError, "deadline"):
                    with construction_admission():
                        self.fail("expired construction")
            self.assertIsNone(construction_slot())

    def test_cold_api_permit_cannot_cross_a_caller_or_child_request(self):
        import fcntl
        from gambit_smp import ascent_program as api
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'construction.lock'
            files = {'ascent._core': path, 'package:ascent/_core.abi3.so': path}
            build = {'schema': 'ascent.rust-build.v1', 'rayon': True,
                     'sourceInputs': {}, 'runtimeInputs': {}, 'extensionSha256': 'bound',
                     'installedInputs': {'ascent/_core.abi3.so': 'bound'}}
            fake = MagicMock()
            def checked_digest(_):
                # Byte validation is independent of the native initialization permit.
                with path.open('ab') as other:
                    fcntl.flock(other.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                    fcntl.flock(other.fileno(), fcntl.LOCK_UN)
                return 'bound'
            def construct(*, backend):
                self.assertEqual(backend, 'rust')
                with path.open('rb') as other, self.assertRaises(BlockingIOError):
                    fcntl.flock(other.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                return fake
            with api.session_construction_slot(path, time.monotonic() + 1), \
                    patch.object(api, '_api_inventory', return_value=(files, build, 'bound')), \
                    patch.object(api, 'artifact_paths', return_value=files), \
                    patch.object(api, 'digest', side_effect=checked_digest), \
                    patch.object(api, 'close_queries'), patch('ascent.Engine', side_effect=construct), \
                    patch.object(api, '_loaded_identity', None):
                with api.engine_api():
                    with path.open('rb') as other:
                        fcntl.flock(other.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                        fcntl.flock(other.fileno(), fcntl.LOCK_UN)
                with patch.object(api, '_loaded_identity', dict.fromkeys(files, 'bound')), \
                        patch.object(api, 'construction_admission') as admission:
                    with api.engine_api(engine=fake):
                        pass
                    admission.assert_not_called()

    def test_worker_selection_accounts_for_sealed_child_processes(self):
        policy = {'workers': 'auto', 'processesPerWorker': 2}
        self.assertEqual(6, selected_workers(policy, 12, 105))
        self.assertEqual(1, selected_workers(policy, 1, 105))
        self.assertEqual(2, selected_workers(policy, 12, 2))
        for invalid in (0, -1, True, '2'):
            with self.assertRaisesRegex(ValueError, 'process demand'):
                selected_workers({**policy, 'processesPerWorker': invalid}, 12, 105)

    def test_delegated_reply_requires_its_complete_original_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            request, response = root / "evaluation.json", root / "evaluation-response.jsonl"
            source = root / "source.ss"
            source.write_text("actual source bytes\n")
            request.write_text(json.dumps({"engineId": "bound", "observationInputs": {str(source): digest(source)}}))
            reply = {"engineId": "bound", "outcome": "PASS"}
            response.write_text(json.dumps(reply) + '\n')
            row = {"request": str(request), "requestSha256": digest(request),
                   "responseSha256": digest(response), "response": reply}
            archive = root / "archive"
            archive.mkdir()
            metadata = root / "native-engine.json"
            metadata.write_text(json.dumps({"ruleSourceInputs": {str(source): digest(source)}}))
            row.update(requestArchive=archive_bytes(archive, "request.json", request, digest(request)),
                       responseArchive=archive_bytes(archive, "response.jsonl", response, digest(response)),
                       metadataArchive=archive_bytes(archive, "metadata.json", metadata, digest(metadata)),
                       sourceArchives=[archive_bytes(archive, "source.ss", source, digest(source))])
            owner = {"requestIdentityAuthority": "sealed-child-full-before-and-after", "requests": [row]}
            self.assertTrue(owner_artifacts_match(owner))
            request.unlink()
            response.unlink()
            metadata.unlink()
            source.unlink()
            self.assertTrue(owner_artifacts_match(owner))
            saved_response = Path(row["responseArchive"]["archivePath"])
            saved_response.chmod(0o644)
            saved_response.write_text(json.dumps(reply) + '\n\n')
            self.assertFalse(owner_artifacts_match(owner))
            saved_response.unlink()
            self.assertFalse(owner_artifacts_match(owner))

    def test_delegated_request_identity_does_not_hide_a_failed_terminal_or_reply(self):
        owner = {"exit": 0, "forcedTermination": False, "parentReaped": True,
                 "terminalIdentityError": None, "engineId": "bound",
                 "requestIdentityAuthority": "sealed-child-full-before-and-after",
                 "requests": [{"requestCompleted": True, "timeout": False,
                               "response": {"engineId": "bound", "outcome": "PASS"}}]}
        self.assertTrue(owner_complete(owner, "bound"))
        for field, value in (("engineId", "foreign"), ("exit", 1),
                             ("terminalIdentityError", "source changed"), ("parentReaped", False)):
            self.assertFalse(owner_complete({**owner, field: value}, "bound"))
        for reply in ({"outcome": "PASS"}, {"engineId": "foreign", "outcome": "PASS"},
                      {"engineId": "bound", "outcome": "DENY"}):
            broken = {**owner, "requests": [{**owner["requests"][0], "response": reply}]}
            self.assertFalse(owner_complete(broken, "bound"))

    def test_response_must_bind_the_validated_child_seal_and_terminal_drift_is_denied(self):
        for response_identity, terminal_error in ((None, None), ("foreign", None), ("bound", "changed source")):
            with self.subTest(response_identity=response_identity, terminal_error=terminal_error), \
                    tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                request = root / "evaluation.json"
                request.write_text('{}')
                (root / "native-engine.json").write_text('{"ruleSourceInputs": {}}')
                (root / "engine").mkdir()
                (root / "engine/engine.json").write_text('{"engineId": "bound"}')
                reply = {"requestSha256": digest(request), "outcome": "PASS"}
                if response_identity is not None:
                    reply["engineId"] = response_identity
                process = MagicMock(returncode=0)
                process.pid = 12345
                process.stdout.fileno.return_value = 1
                checks = [{"engineId": "bound"}, ValueError(terminal_error) if terminal_error else {"engineId": "bound"}]
                owner = EvaluationOwner(root / "engine", root / "owner", time.monotonic() + 10)
                with patch("gambit_smp.research_kernel.execution_origin") as origin, \
                        patch("gambit_smp.research_kernel.execution_identity", side_effect=checks) as identity, \
                        patch("gambit_smp.evidence_capabilities.subprocess.Popen", return_value=process), \
                        patch("gambit_smp.evidence_capabilities.selectors.DefaultSelector"), \
                        patch("gambit_smp.evidence_capabilities.os.read", return_value=(json.dumps(reply) + '\n').encode()):
                    if terminal_error:
                        owner.evaluate(request, 1)
                        with self.assertRaisesRegex(ValueError, terminal_error):
                            owner.close()
                    else:
                        with self.assertRaisesRegex(ValueError, "response identity mismatch"):
                            owner.evaluate(request, 1)
                    self.assertEqual(2, identity.call_count)
                    self.assertGreaterEqual(origin.call_count, 1)
                self.assertTrue(owner.closed)
                self.assertTrue(owner.receipt["parentReaped"])
                self.assertEqual(terminal_error, owner.receipt["terminalIdentityError"])
                process.wait.assert_called_once()

    def test_retained_dispatch_owns_identity_boundary_and_rejects_a_foreign_seal(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            context = SimpleNamespace(root=root, directory=root,
                                      receipt={"engine": {"path": str(root / "engine"), "engineId": "bound"}},
                                      remaining=lambda: 1, progress_mode=False)
            with evaluation_owner(root / "engine", root / "owner", 0) as owner, \
                    patch("gambit_smp.research_kernel.execution_identity") as identity:
                def dispatch(target, cap):
                    self.assertEqual(1, cap)
                    request = json.loads(target.read_text())
                    self.assertEqual("bound", request["engineId"])
                    (target.parent / "answers.json").write_text('{"answer": []}')
                with patch.object(owner, "evaluate", side_effect=dispatch) as call:
                    self.assertEqual({"answer": []}, evaluate_observations(
                        context, [], {}, {"answer": "Answer"}, "request"))
                    call.assert_called_once()
                    identity.assert_not_called()
                context.receipt["engine"]["path"] = str(root / "different-engine")
                with self.assertRaisesRegex(ValueError, "another seal"):
                    evaluate_observations(context, [], {}, {}, "foreign")
                self.assertFalse((root / "foreign").exists())

    def test_closed_evaluation_owner_cannot_reopen_or_restart_a_request(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            owner = EvaluationOwner(root, root / "owner", 0)
            self.assertIsNone(owner.close())
            self.assertIsNone(owner.close())
            with self.assertRaisesRegex(ValueError, "closed"):
                owner.evaluate(root / "request.json", 1)
            self.assertIsNone(owner.process)

    def test_owner_scope_cannot_be_nested_or_leak_after_exception(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(RuntimeError, "caller"):
                with evaluation_owner(root, root / "owner", 0):
                    with self.assertRaisesRegex(ValueError, "nested"):
                        with evaluation_owner(root, root / "other", 0):
                            self.fail("nested scope accepted")
                    raise RuntimeError("caller")
            with evaluation_owner(root, root / "new-owner", 0) as owner:
                self.assertFalse(owner.closed)
            self.assertTrue(owner.closed)

    def test_queue_claims_once_and_does_not_retry_an_interrupted_claim(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "queue.sqlite"
            expected = [str(i) for i in range(40)]
            with closing(sqlite3.connect(path)) as db:
                db.execute("CREATE TABLE jobs (ordinal INTEGER UNIQUE, id TEXT PRIMARY KEY, lane INTEGER)")
                db.executemany("INSERT INTO jobs VALUES (?, ?, NULL)", enumerate(expected))
                db.commit()
                interrupted = claim_test(db, 0)
            def consume(lane):
                actual = []
                with closing(sqlite3.connect(path)) as db:
                    while (name := claim_test(db, lane)) is not None:
                        actual.append(name)
                return actual
            with ThreadPoolExecutor(max_workers=2) as pool:
                lanes = list(pool.map(consume, (0, 1)))
            assigned = [name for lane in lanes for name in lane]
            self.assertNotIn(interrupted, assigned)
            self.assertEqual(len(assigned), len(set(assigned)))
            self.assertEqual(set(expected), set(assigned) | {interrupted})

    def test_parent_commits_full_queue_before_starting_a_worker(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(__file__).resolve().parents[1]
            out = Path(directory) / "result"
            test = self.fixture()
            observed = []
            inherited_start = time.monotonic() - 5

            def rejected_worker(argv, cwd, budget, *, env, metadata):
                self.assertLessEqual(budget, 55)
                request = json.loads(Path(argv[-1]).read_text())
                self.assertEqual(request["deadline"], inherited_start + 60)
                with closing(sqlite3.connect(request["queue"])) as db:
                    observed.extend(row[0] for row in db.execute("SELECT id FROM jobs ORDER BY ordinal"))
                metadata.update(parentReaped=True, processGroupQuiescent=True)
                return 1, "worker rejected before any test", False, 0.001

            with patch("gambit_smp.research_kernel.manifest_paths",
                       return_value={"engineId": "fixture-engine", "files": {},
                                     "hostTools": {"python": {"path": sys.executable}}}), \
                    patch("gambit_smp.framework.execute", side_effect=rejected_worker):
                saved = run_domain(root, [test], {"budgetSeconds": 60, "workers": 1},
                                   Path(directory) / "engine", out, started=inherited_start)
            self.assertEqual([test.id()], observed)
            self.assertFalse(saved["passed"])
            self.assertEqual({test.id(): "error"}, saved["outcomes"])
            self.assertGreaterEqual(saved["seconds"], 5)

    def test_spawn_cannot_supply_a_future_or_nonfinite_launch_time(self):
        for invalid in (True, 0, -1, float("nan"), float("inf"), time.monotonic() + 3600):
            with self.subTest(started=invalid), self.assertRaisesRegex(ValueError, "launch time"):
                run_domain(Path("unused"), [], {}, Path("unused"), Path("unused"), started=invalid)

    def fixture(self, domain=None):
        class Fixture(unittest.TestCase):
            def runTest(self):
                pass
        test = Fixture()
        if domain is not None:
            test.validation_domain = domain
        return test

    def test_partition_preserves_all_original_instances(self):
        local = self.fixture()
        selected = self.fixture({"kind": "sealed-research", "budgetSeconds": 60, "workers": 3})
        ordinary, domains = partition(unittest.TestSuite([unittest.TestSuite([local, selected])]))
        self.assertEqual([local], list(ordinary))
        self.assertEqual([selected], domains[0][1])
        self.assertEqual(60, domains[0][0]["budgetSeconds"])

    def test_auto_workers_use_observed_capacity_and_preserve_deadline(self):
        policy = {"kind": "sealed-research", "budgetSeconds": 60, "workers": "auto"}
        ordinary, domains = partition(unittest.TestSuite([self.fixture(policy)]))
        self.assertEqual(0, ordinary.countTestCases())
        self.assertEqual(policy, domains[0][0])
        self.assertEqual(12, selected_workers(policy, 12, 94))
        self.assertEqual(3, selected_workers(policy, 3, 94))
        self.assertEqual(2, selected_workers(policy, 12, 2))
        self.assertEqual(1, selected_workers({"workers": 4}, 1, 94))
        for capacity, count in ((True, 94), (0, 94), (12, 0)):
            with self.subTest(capacity=capacity, count=count), self.assertRaises(ValueError):
                selected_workers(policy, capacity, count)

    def test_invalid_execution_domains_are_not_silently_local(self):
        for policy in ({}, {"kind": "editable", "budgetSeconds": 60, "workers": 3},
                       {"kind": "sealed-research", "budgetSeconds": True, "workers": 3},
                       {"kind": "sealed-research", "budgetSeconds": 60, "workers": 0}):
            with self.subTest(policy=policy), self.assertRaises(ValueError):
                partition(unittest.TestSuite([self.fixture(policy)]))

    def test_receipt_recheck_requires_complete_inventory_deadline_and_teardown(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "fixture.py"
            source.write_text("fixture\n")
            log = root / "process.log"
            log.write_text("complete raw process log\n")
            lane = root / "0"
            lane.mkdir()
            request = {"engineId": "fixture-engine", "inputs": {"fixture.py": digest(source)},
                       "testIds": ["a", "b"]}
            (lane / "request.json").write_text(json.dumps(request))
            result = {"engineId": "fixture-engine", "requestSHA": digest(lane / "request.json"),
                      "expectedTestIds": ["a", "b"]}
            (lane / "result.json").write_text(json.dumps(result))
            saved = {"schema": "sealed-validation-domain.v1", "engine": str(root / "engine"),
                     "engineId": "fixture-engine", "policy": {"budgetSeconds": 60}, "seconds": 59,
                     "inputs": {"fixture.py": digest(source)}, "expectedTestIds": ["a", "b"],
                     "outcomes": {"a": "pass", "b": "pass"}, "passed": True,
                     "lanes": [{"expectedTestIds": ["a", "b"], "exit": 0, "timeout": False,
                                "passed": True, "parentReaped": True, "processGroupQuiescent": True,
                                "result": result}],
                     "artifacts": {"process.log": digest(log)}}
            with patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "fixture-engine"}):
                self.assertTrue(check_domain(root, root, saved))
                for update in ({"seconds": 61}, {"expectedTestIds": ["a"]},
                               {"outcomes": {"a": "pass", "b": "skip"}}):
                    self.assertFalse(check_domain(root, root, {**saved, **update}))
                changed = json.loads(json.dumps(saved))
                changed["lanes"][0]["processGroupQuiescent"] = False
                self.assertFalse(check_domain(root, root, changed))
                source.write_text("different fixture\n")
                self.assertFalse(check_domain(root, root, saved))
                log.write_text("tampered\n")
                with self.assertRaisesRegex(ValueError, "artifact identity mismatch"):
                    check_domain(root, root, saved)


if __name__ == "__main__":
    unittest.main()
