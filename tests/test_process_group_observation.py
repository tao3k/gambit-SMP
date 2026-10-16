import time
import unittest
from unittest.mock import patch

from gambit_smp.process_observation import probe_group


class ProcessGroupObservationTests(unittest.TestCase):
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
