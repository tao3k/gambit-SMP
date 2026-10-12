import unittest

from gambit_smp.ascent_program import load_catalog
from gambit_smp import evidence_index as index
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify


class EagerChainWorkClosureTests(unittest.TestCase):
    def test_source_split_model_is_checked_without_claiming_native_acceptance(self):
        manifest = verify.load_manifest(index.ROOT / "evidence/eager-tail-scan-partition.json")
        receipt = index.ROOT / "evidence/model-results/eager-tail-scan-partition/receipt.json"
        self.assertEqual("eager_tail_scan_partition",
                         evidence.checked_rows(index.ROOT, manifest, receipt)[0][0])
        facts, _ = evidence.facts(index.ROOT)
        self.assertTrue(any(row[0] == "eager_tail_scan_partition"
                            for row in facts["protocol_checked"]))
        self.assertIn(("eager_tail_scan_partition", "gc_scan_claim_transfer"),
                      facts["protocol_composes"])
        self.assertIn(("eager_tail_scan_partition", "gc_copy_queue_memory_order"),
                      facts["protocol_obligation"])

    def test_recursive_chain_has_distinct_termination_and_phase_controls(self):
        manifest = verify.load_manifest(index.ROOT / "evidence/eager-chain-work-closure.json")
        case = manifest["cases"][0]
        self.assertEqual([
            ("old", "terminationSafe", "initOld"),
            ("old", "phaseSafe", "initEarlyPhase"),
            ("fixed", "safe", "initFixed"),
        ], verify.model_checks(case))
        self.assertEqual(["eager_tail_scan_partition", "gc_work_closure"], case["composes"])
        self.assertIn("gc_eager_general_graph_closure", case["openObligations"])
        self.assertIn("gc_scan_condition_wait_source", case["openObligations"])
        self.assertIn("gc_body_rescan_origin", case["openObligations"])
        self.assertEqual("progress", case["temporal"])

    def test_composition_keeps_general_graph_wait_and_native_requirements_open(self):
        facts = index.export()["facts"]
        result = index.query(facts, load_catalog(index.ROOT / "evidence/catalog.ss"))
        self.assertTrue(any(row[0] == "eager_chain_work_closure"
                            for row in facts["protocol_checked"]))
        self.assertIn(("eager_chain_work_closure", "gc_scan_claim_transfer"),
                      result["model_contract_dependencies"])
        self.assertIn(("eager_chain_work_closure", "ticket_queue_handoff"),
                      result["contract_dependencies_without_native_adapters"])
        self.assertIn(("eager_chain_work_closure", "gc_scan_condition_wait_source"),
                      result["protocol_open_obligations"])


if __name__ == "__main__":
    unittest.main()
