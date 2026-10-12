import unittest

from gambit_smp import evidence_index as index
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify


class GCNotificationLockOrderTests(unittest.TestCase):
    def setUp(self):
        self.manifest = verify.load_manifest(
            index.ROOT / "evidence/gc-notification-lock-order.json"
        )
        self.case = self.manifest["cases"][0]

    def test_lock_inversion_has_a_separate_negative_control(self):
        self.assertEqual([
            ("old", "noLockCycle", "initOld"),
            ("protocol", "safe", "init"),
        ], verify.model_checks(self.case))
        self.assertEqual("characterization", self.case["mode"])
        self.assertEqual("progress", self.case["temporal"])

    def test_queue_snapshot_memory_and_runtime_obligations_remain_open(self):
        for obligation in ("gc_notification_source_repair",
                           "gc_multiple_waiter_notification",
                           "gc_recheck_predicate_queue_snapshot",
                           "gc_copy_queue_memory_order",
                           "gc_scan_sync_resource_initialization"):
            self.assertIn(obligation, self.case["openObligations"])
        self.assertEqual(["gc_wait_notification", "gc_wait_count_restore"],
                         self.case["composes"])

    def test_registered_checked_models_do_not_grant_native_admission(self):
        facts, _ = evidence.facts(index.ROOT)
        checked = {row[0] for row in facts["protocol_checked"]}
        self.assertTrue({"gc_wait_count_restore", "gc_notification_lock_order"} <= checked)
        self.assertIn(("gc_notification_lock_order", "gc_wait_count_restore"),
                      facts["protocol_composes"])
        self.assertNotIn("native_observation", facts)


if __name__ == "__main__":
    unittest.main()
