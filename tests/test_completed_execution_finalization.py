"""Completed commands may retain evidence beyond a performance wall limit."""
import json
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest, execute
from gambit_smp.research_kernel import completed_stage_frontier
from gambit_smp.research_kernel import evaluation_teardown_deadline
from types import SimpleNamespace


class CompletedExecutionFinalizationTests(unittest.TestCase):
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
