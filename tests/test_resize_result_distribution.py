import unittest

from gambit_smp import evidence_index as index
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify
from tests.protocol_current import assert_current_status


class ResizeResultDistributionTests(unittest.TestCase):
    def setUp(self):
        self.manifest = verify.load_manifest(index.ROOT / "evidence/resize-result-distribution.json")
        self.case = self.manifest["cases"][0]

    def test_local_error_publication_epoch_and_ack_controls_are_independent(self):
        self.assertEqual([
            ("old", "resultSafe", "initOld"),
            ("old", "publicationSafe", "initEarly"),
            ("old", "epochSafe", "initStale"),
            ("old", "replySafe", "initOverwrite"),
            ("fixed", "safe", "initFixed"),
        ], verify.model_checks(self.case))
        self.assertEqual("progress", self.case["temporal"])

    def test_verified_contract_does_not_close_source_retirement_or_native_gates(self):
        for name in ("resize_result_source_refinement", "resize_result_release_acquire",
                     "resize_requester_retirement", "resize_concurrent_request_arbitration",
                     "resize_error_origin_contract", "quarantined_vm_teardown"):
            self.assertIn(name, self.case["openObligations"])
        parent = verify.load_manifest(index.ROOT / "evidence/pstate-retirement-generation.json")
        self.assertIn("resize_result_distribution", parent["cases"][0]["openObligations"])
        facts, _ = evidence.facts(index.ROOT)
        assert_current_status(self, index.ROOT, "evidence/resize-result-distribution.json", facts)
        self.assertIn((self.case["id"], "resize_result_source_refinement"),
                      facts["protocol_obligation"])
        self.assertIn((self.case["id"], "lib/setup.c:execute_sync_op_loop"),
                      facts["protocol_source"])


if __name__ == "__main__":
    unittest.main()
