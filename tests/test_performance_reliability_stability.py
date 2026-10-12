"""Joint design qualification, explicitly separate from native admission."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import bundle_facts
from gambit_smp.verify_protocols import load_manifest


MANIFEST = "evidence/performance-reliability-stability-model.json"
RECEIPT = "evidence/model-results/performance-reliability-stability/joint-contract/receipt.json"


class PerformanceReliabilityStabilityTests(unittest.TestCase):
    def test_current_context_and_no_claimed_source_composition(self):
        manifest = load_manifest(ROOT / MANIFEST)
        for name, expected in manifest["contextInputs"].items():
            self.assertEqual(digest(ROOT / name), expected)
        case = manifest["cases"][0]
        self.assertEqual(case["invariants"], ["simultaneous"])
        self.assertEqual(case["composes"], [])
        self.assertIn("matched_native_performance_and_repeated_stability", case["openObligations"])
        self.assertIn("whole_gc_phase_composition", case["openObligations"])

    def test_every_invalid_strategy_has_a_checked_counterexample(self):
        facts, _ = bundle_facts(ROOT, MANIFEST, RECEIPT)
        self.assertEqual(len(facts["protocol_control"]), 8)
        receipt = json.loads((ROOT / RECEIPT).read_text())
        controls = [r for r in receipt["results"] if r["variant"] == "old"]
        self.assertEqual({r["invariant"] for r in controls}, {
            "parallelPublication", "boundedWork", "rootsOwned", "honestOutcome",
            "resultsCurrent", "progressEnabled", "configurationFixed", "budgetUnchanged"})
        for row in controls:
            self.assertTrue(row["accepted"])
            self.assertFalse(row["timeout"])
            self.assertEqual(digest((ROOT / RECEIPT).parent / row["trace"]), row["traceSha256"])

    def test_joint_safety_and_temporal_exploration_complete(self):
        facts, _ = bundle_facts(ROOT, MANIFEST, RECEIPT)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        receipt = json.loads((ROOT / RECEIPT).read_text())
        positive = [r for r in receipt["results"] if r["variant"] == "protocol"]
        self.assertEqual(len(positive), 1)
        row = positive[0]
        self.assertEqual(row["invariant"], "simultaneous")
        self.assertEqual(row["temporal"], "completion")
        self.assertEqual(row["states"]["queued"], 0)
        self.assertTrue(row["accepted"])
        self.assertFalse(row["timeout"])
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])

    def test_initial_state_parser_denial_is_retained_not_admitted(self):
        folder = ROOT / "evidence/model-results/performance-reliability-stability/initial-state-denial"
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        self.assertFalse(archive["accepted"])
        for name, expected in archive["files"].items():
            self.assertEqual(digest(folder / name), expected["portableSha256"])
        denied = json.loads((folder / "receipt.json").read_text())
        self.assertFalse(denied["accepted"])
        self.assertEqual({r["invariant"] for r in denied["results"] if not r["accepted"]},
                         {"configurationFixed", "budgetUnchanged"})
