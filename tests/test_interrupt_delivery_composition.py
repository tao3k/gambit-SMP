import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import checked_rows, load_bundles


class InterruptDeliveryCompositionTests(unittest.TestCase):
    def test_combined_model_has_current_source_bound_controls_and_completion(self):
        manifest_path = ROOT / "evidence/fixtures/abandoned-result-state/interrupt-delivery-contract.json"
        manifest = json.loads(manifest_path.read_text())
        folder = ROOT / "evidence/model-results/fixtures/abandoned-result-state/interrupt-delivery-composition"
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertIn((str(manifest_path.relative_to(ROOT)),
                       str((folder / "receipt.json").relative_to(ROOT))), load_bundles(ROOT))
        checked_rows(ROOT, manifest, folder / "receipt.json")
        for name, expected in manifest["contextInputs"].items():
            self.assertEqual(digest(ROOT / name), expected)
        controls = [row for row in receipt["results"] if row["variant"] == "old"]
        self.assertEqual({row["invariant"] for row in controls},
                         {"detachedHandoff", "deliverySafe", "releaseSafe", "outcomeSafe"})
        self.assertEqual(len(controls), 4)
        positives = [row for row in receipt["results"] if row["variant"] == "protocol"]
        self.assertEqual(len(positives), 1)
        self.assertEqual(positives[0]["temporal"], "completion")
        self.assertEqual(positives[0]["states"]["distinct"], 28)
        self.assertEqual(positives[0]["states"]["queued"], 0)
        self.assertTrue(receipt["accepted"])
        self.assertTrue(receipt["contextStable"])
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])
        self.assertEqual(receipt["native"]["status"], "not-run")
        case = manifest["cases"][0]
        self.assertIn("gc_roots_and_relocation", case["openObligations"])
        self.assertIn("requester_cancellation_callback_exception_retirement", case["openObligations"])
        source = (folder / "source/interrupt_delivery_result_composition.qnt").read_text()
        self.assertIn("not(s.ended), not(s.locked)", source)
        self.assertIn("s.outcomeA == 0 or s.outcomeA == s.resultA", source)
        self.assertIn("dead target's retained queue", source)
