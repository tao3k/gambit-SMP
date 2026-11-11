"""Identity regressions for the integrated source candidate, not SMP admission."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.recipes import load


class ForeignOriginBootstrapBindingTests(unittest.TestCase):
    def test_successor_binds_actual_locked_bytes_and_historical_baselines(self):
        directory = ROOT / "evidence/research/vm-registry-reader-lease"
        recipe, _ = load(ROOT, directory / "foreign-origin-lease-admission-bootstrap.recipe.json")
        review = next(s for s in recipe["steps"] if s["id"] == "review")
        intent_path = review["arguments"]["intent"]
        self.assertIn(intent_path, recipe["inputs"])
        intent = json.loads((ROOT / intent_path).read_text())
        lock = json.loads((ROOT / "evidence/fixtures/foreign-origin-lease-admission/source.lock.json").read_text())
        self.assertEqual(3, len(intent["failures"]))
        for failure in intent["failures"]:
            baseline_ref = failure["baselineIdentity"]
            archive = baseline_ref["path"].split("/thread-completion-contract/", 1)[1]
            baseline_path = ROOT / "tests/fixtures/historical-bootstrap" / archive
            self.assertEqual(baseline_ref["sha256"], digest(baseline_path))
            baseline = json.loads(baseline_path.read_text())
            self.assertEqual({"lib/setup.c", "include/gambit.h.in"},
                             {c["path"] for c in failure["changes"]})
            for change in failure["changes"]:
                self.assertEqual(baseline["sourceFiles"][change["path"]], change["before"])
                self.assertEqual(lock["files"][change["path"]]["candidateSha256"], change["after"])
            for claim in failure["claims"]:
                evidence = claim["evidence"]
                self.assertIn(evidence["path"], recipe["inputs"])
                self.assertEqual(evidence["sha256"], digest(ROOT / evidence["path"]))
                if evidence["path"].endswith("bootstrap-causal-review.json"):
                    index = int(claim["pointer"].split("/")[-1])
                    row = json.loads((ROOT / evidence["path"]).read_text())["claims"][index]
                    self.assertEqual(failure["receiptSha256"], row["failureReceiptSha256"])
                    self.assertEqual({c["id"] for c in failure["changes"]}, set(row["changes"]))
                    for ref in row["references"]:
                        self.assertIn(ref["path"], recipe["inputs"])
                        self.assertEqual(ref["sha256"], digest(ROOT / ref["path"]))


if __name__ == "__main__":
    unittest.main()
