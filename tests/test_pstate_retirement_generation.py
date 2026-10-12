import unittest

from gambit_smp.ascent_program import load_catalog
from gambit_smp import evidence_index as index
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify


class PStateRetirementGenerationTests(unittest.TestCase):
    def setUp(self):
        self.manifest = verify.load_manifest(
            index.ROOT / "evidence/pstate-retirement-generation.json")
        self.case = self.manifest["cases"][0]

    def test_distinct_controls_cover_reuse_rounds_and_join_errors(self):
        checks = verify.model_checks(self.case)
        self.assertEqual([
            ("old", "initializationSafe", "initOld"),
            ("old", "generationSafe", "initStaleGeneration"),
            ("old", "roundSafe", "initStaleRound"),
            ("old", "failedJoinSafe", "initIgnoredJoin"),
            ("fixed", "safe", "initFixed"),
        ], checks)
        self.assertEqual("progress", self.case["temporal"])

    def test_composition_does_not_close_source_or_native_gaps(self):
        self.assertEqual(["sync_retirement_round_closure", "pstate_setup_transaction"],
                         self.case["composes"])
        for obligation in ("pstate_retirement_generation_source",
                           "resize_result_distribution", "pthread_join_error_identity",
                           "quarantined_vm_teardown", "pstate_grow_failure_retirement",
                           "gc_resize_c_memory_order"):
            self.assertIn(obligation, self.case["openObligations"])
        facts, _ = evidence.facts(index.ROOT)
        checked = [row for row in facts["protocol_checked"]
                   if row[0] == self.case["id"]]
        self.assertEqual(1, len(checked))
        result = index.query(index.export()["facts"],
                             load_catalog(index.ROOT / "evidence/catalog.ss"))
        self.assertTrue(any(row[0] == self.case["id"]
                            for row in result["contract_dependencies_without_native_adapters"]))


if __name__ == "__main__":
    unittest.main()
