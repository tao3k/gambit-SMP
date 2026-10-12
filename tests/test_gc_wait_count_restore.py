import unittest

from gambit_smp import evidence_index as index
from gambit_smp import verify_protocols as verify


class GCWaitCountRestoreTests(unittest.TestCase):
    def setUp(self):
        self.case = verify.load_manifest(
            index.ROOT / "evidence/gc-wait-count-restore.json"
        )["cases"][0]

    def test_independent_restore_and_zero_exit_controls(self):
        self.assertEqual([
            ("old", "nonzeroRestoreSafe", "initOld"),
            ("old", "zeroExitSafe", "initRestoreZero"),
            ("protocol", "safe", "init"),
        ], verify.model_checks(self.case))
        self.assertEqual("characterization", self.case["mode"])
        self.assertEqual("progress", self.case["temporal"])

    def test_source_characterization_keeps_composition_gaps_open(self):
        self.assertEqual(["gc_wait_notification"], self.case["composes"])
        self.assertIn("gc_multiple_producer_notification", self.case["openObligations"])
        self.assertIn("gc_notification_queue_recheck_lock_order", self.case["openObligations"])
        self.assertIn("gc_unbounded_spurious_wake_fairness", self.case["openObligations"])
        self.assertIn("gc_copy_queue_memory_order", self.case["openObligations"])
        self.assertIn("not a runtime repair", self.case["scope"])


if __name__ == "__main__":
    unittest.main()
