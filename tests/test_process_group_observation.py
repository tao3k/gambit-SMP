import time
import unittest
from unittest.mock import Mock, patch

from gambit_smp.process_observation import probe_group, capture_batch, capture, communicate_progress


class ProcessGroupObservationTests(unittest.TestCase):
    def test_invalid_process_budget_cannot_start_or_journal_a_child(self):
        for budget in (float("nan"), float("inf"), -float("inf"), True, False, 0, -1):
            with self.subTest(budget=budget), patch("gambit_smp.process_observation._task_spawn") as spawn:
                recorder = Mock()
                with self.assertRaisesRegex(ValueError, "positive finite process budget"):
                    capture(["unused"], ".", budget, None, recorder=recorder)
                spawn.assert_not_called()
                recorder.assert_not_called()

    def test_invalid_progress_window_cannot_poll_or_admit_progress(self):
        for window in (float("nan"), float("inf"), -float("inf"), True, False, 0, -1):
            with self.subTest(window=window):
                process, progress, recorder = Mock(), Mock(), Mock()
                with self.assertRaisesRegex(ValueError, "positive finite progress window"):
                    communicate_progress(process, window, progress, recorder=recorder)
                process.communicate.assert_not_called()
                progress.assert_not_called()
                recorder.assert_not_called()

    def test_failed_launch_is_not_a_started_process_and_does_not_hide_other_jobs(self):
        import os
        import sys
        from pathlib import Path
        jobs = [{"argv": argv, "cwd": Path.cwd(), "environment": dict(os.environ), "budget": 3}
                for argv in (["/missing/framework-contract-executable"], [sys.executable, "-c", "pass"])]
        result = capture_batch(jobs, workers=2, budget=3)
        self.assertFalse(result["runs"][0]["started"])
        self.assertIsNone(result["runs"][0]["observation"])
        self.assertEqual("FileNotFoundError", result["runs"][0]["launchError"]["type"])
        self.assertEqual(0, result["runs"][1]["observation"]["exit"])
    def test_absence_after_permission_error_requires_a_real_absence_probe(self):
        with patch("gambit_smp.process_observation.os.killpg",
                   side_effect=[PermissionError(), ProcessLookupError()]) as kill:
            result, probes = probe_group(123, time.monotonic() + 1)
        self.assertTrue(result)
        self.assertEqual(("permission-denied", "absent"), probes)
        self.assertEqual(2, kill.call_count)
        self.assertTrue(all(call.args == (123, 0) for call in kill.call_args_list))

    def test_continuous_permission_denial_remains_unknown(self):
        with patch("gambit_smp.process_observation.os.killpg", side_effect=PermissionError()):
            result, probes = probe_group(123, time.monotonic() + 0.001)
        self.assertIsNone(result)
        self.assertTrue(probes)
        self.assertEqual({"permission-denied"}, set(probes))

    def test_present_group_is_not_retried_or_admitted(self):
        with patch("gambit_smp.process_observation.os.killpg") as kill:
            result, probes = probe_group(123, time.monotonic() + 1)
        self.assertFalse(result)
        self.assertEqual(("present",), probes)
        kill.assert_called_once_with(123, 0)

    def test_expired_budget_does_not_wait_on_unknown(self):
        with patch("gambit_smp.process_observation.os.killpg", side_effect=PermissionError()), \
                patch("gambit_smp.process_observation.time.sleep") as sleep:
            result, probes = probe_group(123, time.monotonic() - 1)
        self.assertIsNone(result)
        self.assertEqual(("permission-denied",), probes)
        sleep.assert_not_called()

    def test_interruption_needs_a_subsequent_authoritative_probe(self):
        with patch("gambit_smp.process_observation.os.killpg",
                   side_effect=[InterruptedError(), ProcessLookupError()]):
            result, probes = probe_group(123, time.monotonic() + 1)
        self.assertTrue(result)
        self.assertEqual(("interrupted", "absent"), probes)
