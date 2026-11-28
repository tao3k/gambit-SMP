import unittest

from gambit_smp import evidence_index as index
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify
from tests.protocol_current import assert_current_status


class GCWaitNotificationTests(unittest.TestCase):
    def setUp(self):
        self.manifest = verify.load_manifest(index.ROOT / "evidence/gc-wait-notification.json")
        self.case = self.manifest["cases"][0]

    def test_source_and_single_sided_repairs_have_independent_controls(self):
        self.assertEqual([
            ("old", "notificationSafe", "initOld"),
            ("old", "signalOnlyWakeSafe", "initSignalOnly"),
            ("old", "recheckOnlyWakeSafe", "initRecheckOnly"),
            ("protocol", "guardSound", "init"),
        ], verify.model_checks(self.case))
        self.assertEqual("characterization", self.case["mode"])
        self.assertEqual("progress", self.case["temporal"])

    def test_characterization_does_not_close_repair_memory_or_native_gates(self):
        for name in ("gc_notification_source_repair",
                     "gc_notification_queue_recheck_lock_order",
                     "gc_unbounded_spurious_wake_fairness", "gc_condition_error_handling",
                     "gc_multiple_producer_notification", "gc_copy_queue_memory_order",
                     "gc_scan_sync_resource_initialization"):
            self.assertIn(name, self.case["openObligations"])
        facts, _ = evidence.facts(index.ROOT)
        assert_current_status(self, index.ROOT, "evidence/gc-wait-notification.json", facts)
        self.assertIn((self.case["id"], "include/gambit.h:___CONDVAR_WAIT"),
                      facts["protocol_source"])
        self.assertEqual(["eager_chain_work_closure", "gc_work_closure"], self.case["composes"])


if __name__ == "__main__":
    unittest.main()
