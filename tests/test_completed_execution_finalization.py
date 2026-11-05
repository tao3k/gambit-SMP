"""Completed commands may retain evidence beyond a performance wall limit."""
import json
from pathlib import Path
import sys
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest, execute
from gambit_smp.research_kernel import completed_stage_frontier
from gambit_smp.research_kernel import evaluation_teardown_deadline
from gambit_smp.research_kernel import begin_evaluation_teardown
from gambit_smp.research_kernel import completed_work
from types import SimpleNamespace


class DeclaredInputProgressTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.out = self.root / 'run'
        self.out.mkdir()
        self.inputs = {'model.qnt': 'a' * 64}
        header = self.root / 'run-header.json'
        header.write_text(json.dumps({'inputs': self.inputs}))
        self.journal = {'path': str(header), 'sha256': digest(header)}

    def observe(self):
        return completed_work(self.root, [], journal=self.journal, required_inputs=self.inputs)

    def publish(self, inputs=None):
        from gambit_smp.recipes import retain_input_validation
        observed = {str(self.root / name): sha for name, sha in self.inputs.items()} if inputs is None else inputs
        retain_input_validation(self.root, self.out, self.journal, observed, {})

    def test_completed_declared_checks_advance_once_not_with_polls(self):
        self.assertEqual(0, self.observe())
        self.publish()
        self.assertEqual(1, self.observe())
        self.assertEqual(1, self.observe())
        self.assertEqual(0, completed_work(self.root, []))

    def test_explicit_empty_declaration_remains_a_valid_scoped_check(self):
        self.inputs.clear()
        header = Path(self.journal['path'])
        header.write_text(json.dumps({'inputs': {}}))
        self.journal['sha256'] = digest(header)
        self.publish()
        self.assertEqual(1, self.observe())

    def test_missing_declaration_member_is_not_published(self):
        with self.assertRaisesRegex(ValueError, 'cover the run declaration'):
            self.publish({})
        self.assertEqual(0, self.observe())

    def test_path_alias_preserves_the_same_validated_input(self):
        alias = self.root / 'alias'
        alias.symlink_to(self.root, target_is_directory=True)
        self.publish({str(alias / name): sha for name, sha in self.inputs.items()})
        self.assertEqual(1, self.observe())

    def test_conflicting_aliases_cannot_publish_validation(self):
        alias = self.root / 'alias'
        alias.symlink_to(self.root, target_is_directory=True)
        observed = {str(self.root / 'model.qnt'): 'a' * 64,
                    str(alias / 'model.qnt'): 'b' * 64}
        with self.assertRaisesRegex(ValueError, 'conflicting validated input aliases'):
            self.publish(observed)
        self.assertEqual(0, self.observe())

    def test_wrong_header_or_incomplete_or_changed_input_cannot_renew(self):
        self.publish()
        target = self.out / 'input-validation.json'
        original = json.loads(target.read_text())
        for key, value in (('header', {}), ('completed', False), ('requiredInputs', {}),
                           ('observedInputs', {}), ('scope', 'native-work')):
            with self.subTest(key=key):
                target.write_text(json.dumps({**original, key: value}))
                self.assertEqual(0, self.observe())

    def test_relocated_record_and_symlink_are_not_current_validation(self):
        self.publish()
        target = self.out / 'input-validation.json'
        saved = self.root / 'old-validation.json'
        target.rename(saved)
        target.symlink_to(saved)
        self.assertEqual(0, self.observe())

    def test_completed_checker_process_counts_before_stage_publication(self):
        directory = self.out / 'parse'
        directory.mkdir()
        target = directory / 'raw.process.json'
        row = dict(schema='recipe-process-observation.v1', state='OBSERVED',
                   completionObserved=True, parentReaped=True, processGroupQuiescent=True,
                   exit=2, timeout=False, runtimeAdmitted=False)
        target.write_text(json.dumps(row))
        self.assertEqual(1, completed_work(self.root, [dict(id='parse')]))
        for field in ('completionObserved', 'parentReaped', 'processGroupQuiescent'):
            target.write_text(json.dumps({**row, field: False}))
            self.assertEqual(0, completed_work(self.root, [dict(id='parse')]))


class CompletedExecutionFinalizationTests(unittest.TestCase):
    # Keep real-process timing controls behind the owner-wave barrier.
    validation_after_domains = True

    def owner_shutdown(self, *, window, finalization, stale_slot=False, teardown_policy=None):
        from gambit_smp.evidence_capabilities import EvaluationOwner
        from gambit_smp.ascent_program import session_construction_slot
        from contextlib import nullcontext
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            owner = EvaluationOwner(root, root, time.monotonic() + window)
            owner.engine_id = "fixture"
            owner.log = (root / "stderr.log").open("wb")
            owner.argv = [sys.executable, "-c",
                          "import sys,time; sys.stdin.read(); time.sleep(" + str(finalization) + ")"]
            owner.process = subprocess.Popen(owner.argv, stdin=subprocess.PIPE,
                stdout=subprocess.PIPE, stderr=owner.log)
            owner.records = [{"requestCompleted": True, 'timeout': False}]
            if teardown_policy is not None:
                begin_evaluation_teardown(teardown_policy, owner.deadline, owner)
            slot = session_construction_slot(root / "slot", time.monotonic() - 1) if stale_slot else nullcontext()
            with patch("gambit_smp.research_kernel.execution_identity", return_value={"engineId": "fixture"}), slot:
                return owner.close()

    def test_owner_finalizes_within_renewed_stage_deadline_not_one_second(self):
        result = self.owner_shutdown(window=4, finalization=1.2, stale_slot=True)
        self.assertEqual(result["exit"], 0)
        self.assertFalse(result["forcedTermination"])
        self.assertTrue(result["parentReaped"])

    def test_owner_finalization_still_stops_at_actual_deadline(self):
        result = self.owner_shutdown(window=.05, finalization=10)
        self.assertNotEqual(result["exit"], 0)
        self.assertTrue(result["forcedTermination"])
        self.assertTrue(result["parentReaped"])

    def test_completed_review_can_expire_before_its_configured_close_phase(self):
        result = self.owner_shutdown(window=-1, finalization=.05,
            teardown_policy={'timeoutPolicy': {'mode': 'progress', 'overheadSeconds': 2}})
        self.assertEqual(0, result['exit'])
        self.assertFalse(result['forcedTermination'])

    def test_configured_close_phase_still_reaps_a_stalled_owner(self):
        result = self.owner_shutdown(window=-1, finalization=10,
            teardown_policy={'timeoutPolicy': {'mode': 'progress', 'overheadSeconds': .05}})
        self.assertNotEqual(0, result['exit'])
        self.assertTrue(result['forcedTermination'])

    def test_only_close_clock_changes_not_review_or_native_budgets(self):
        owner = SimpleNamespace(deadline=42, process=None, records=[])
        policy = {'timeoutPolicy': {'mode': 'progress', 'overheadSeconds': 7},
                  'steps': [{'budgetSeconds': 3600}]}
        with patch('gambit_smp.research_kernel.time.monotonic', return_value=100):
            scope = begin_evaluation_teardown(policy, 42, owner)
            self.assertEqual(107, scope['deadline'])
            self.assertEqual('fresh-configured-phase', scope['mode'])
        self.assertEqual(3600, policy['steps'][0]['budgetSeconds'])
        self.assertEqual(7, policy['timeoutPolicy']['overheadSeconds'])
        self.assertEqual(42, begin_evaluation_teardown({}, 42, owner)['deadline'])

    def test_unfinished_review_does_not_receive_a_fresh_execution_window(self):
        owner = SimpleNamespace(deadline=42, process=object(),
            records=[{'requestCompleted': False, 'timeout': True}])
        scope = begin_evaluation_teardown({'timeoutPolicy': {'mode': 'progress', 'overheadSeconds': 7}}, 42, owner)
        self.assertEqual(42, owner.deadline)
        self.assertEqual(42, scope['deadline'])
        self.assertEqual('unfinished-request', scope['mode'])

    def test_progress_owner_uses_renewed_review_deadline_not_old_total_wall(self):
        owner = SimpleNamespace(deadline=420)
        self.assertEqual(420, evaluation_teardown_deadline(
            {"timeoutPolicy": {"mode": "progress"}}, 300, owner))
        self.assertEqual(300, evaluation_teardown_deadline(
            {"timeoutPolicy": {"mode": "wall"}}, 300, owner))
        self.assertEqual(300, evaluation_teardown_deadline({}, 300, owner))

    def test_completed_execution_is_not_killed_during_finalization(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            marker = root / "completed"
            metadata = {}
            command = [sys.executable, "-c",
                       "from pathlib import Path; import sys,time; "
                       "Path(sys.argv[1]).touch(); time.sleep(.2); print('FINALIZED')", str(marker)]
            code, output, timeout, _ = execute(command, root, .1, metadata=metadata,
                completion_check=marker.is_file, completion_grace=2)
            self.assertEqual(code, 0)
            self.assertEqual(output.strip(), "FINALIZED")
            self.assertFalse(timeout)
            self.assertTrue(metadata["wallBudgetExceeded"])
            self.assertTrue(metadata["finalizationGraceGranted"])
            self.assertTrue(metadata["processGroupQuiescent"])

    def test_incomplete_execution_still_terminates(self):
        metadata = {}
        code, _, timeout, _ = execute([sys.executable, "-c", "import time; time.sleep(10)"],
            Path.cwd(), .05, metadata=metadata, completion_check=lambda: False, completion_grace=2)
        self.assertNotEqual(code, 0)
        self.assertTrue(timeout)
        self.assertFalse(metadata["finalizationGraceGranted"])
        self.assertTrue(metadata["processGroupQuiescent"])

    def test_stalled_finalizer_still_terminates(self):
        metadata = {}
        code, _, timeout, _ = execute([sys.executable, "-c", "import time; time.sleep(10)"],
            Path.cwd(), .05, metadata=metadata, completion_check=lambda: True, completion_grace=.05)
        self.assertNotEqual(code, 0)
        self.assertTrue(timeout)
        self.assertTrue(metadata["processGroupQuiescent"])

    def test_invalid_limits_are_rejected_before_launch(self):
        with patch("gambit_smp.framework.subprocess.Popen") as launch:
            for value in (True, -1, float("nan"), float("inf")):
                with self.assertRaises(ValueError):
                    execute([], Path.cwd(), 1, completion_grace=value)
            launch.assert_not_called()

    def test_completion_check_failure_reaps_child(self):
        children = []
        original = subprocess.Popen
        def launch(*args, **kwargs):
            child = original(*args, **kwargs)
            children.append(child)
            return child
        with patch("gambit_smp.framework.subprocess.Popen", side_effect=launch):
            def failed_check():
                raise ValueError("damaged completion evidence")
            with self.assertRaisesRegex(ValueError, "damaged completion evidence"):
                execute([sys.executable, "-c", "import time; time.sleep(10)"],
                        Path.cwd(), .05, completion_check=failed_check, completion_grace=1)
            self.assertIsNotNone(children[0].returncode)

    def test_frontier_retains_failures_but_rejects_missing_drifted_or_live_command(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "run").mkdir()
            header = root / "header.json"
            header.write_text(json.dumps({"runId": "unit"}))
            journal = {"path": str(header), "sha256": digest(header)}
            declaration = {"id": "native", "capability": "gambit.executable-test", "arguments": {"unit": True}}
            path = root / "run/native.observation.json"
            record = {"schema": "research-step-observation.v1", "runId": "unit", "header": journal,
                      "step": {**declaration, "outcome": "PASS", "commands": [
                          {"parentReaped": True, "processGroupQuiescent": True}]}}
            self.assertFalse(completed_stage_frontier(root, [declaration], journal))
            path.write_text(json.dumps(record))
            self.assertTrue(completed_stage_frontier(root, [declaration], journal))
            for outcome in ("DENY", "STALE", "TIMEOUT", "FAIL", "BLOCKED"):
                changed = json.loads(json.dumps(record))
                changed["step"]["outcome"] = outcome
                path.write_text(json.dumps(changed))
                self.assertTrue(completed_stage_frontier(root, [declaration], journal))
            for field, value in (("outcome", "RUNNING"), ("arguments", {"unit": False})):
                changed = json.loads(json.dumps(record))
                changed["step"][field] = value
                path.write_text(json.dumps(changed))
                self.assertFalse(completed_stage_frontier(root, [declaration], journal))
            record["step"]["commands"][0]["processGroupQuiescent"] = False
            path.write_text(json.dumps(record))
            self.assertFalse(completed_stage_frontier(root, [declaration], journal))
