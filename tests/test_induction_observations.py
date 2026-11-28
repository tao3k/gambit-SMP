import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.output_observations import observe
from gambit_smp import review_inputs


class InductionObservationTests(unittest.TestCase):
    def test_observations_bind_portable_receipts_without_whole_model_admission(self):
        catalog = json.loads((ROOT / "evidence/induction-observations.json").read_text())
        self.assertEqual("gambit-induction-observations.v1", catalog["schema"])
        self.assertFalse(catalog["overallAccepted"])
        self.assertEqual("gc_recursive_queue_wait", catalog["protocolModel"])
        self.assertTrue((ROOT / catalog["proofLayer"]).is_file())
        self.assertTrue((ROOT / catalog["notes"]).is_file())
        for row in catalog["observations"]:
            self.assertTrue(row["receipt"].startswith("evidence/"))

    def test_preservation_is_only_the_named_original_transition(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            (root / "docs").mkdir(parents=True)
            (root / "docs/notes.md").write_text("induction audit notes\n")
            (root / "models/gambit").mkdir(parents=True)
            model = root / "models/gambit/gc_ind.qnt"
            model.write_text("module gc_ind {}\n")
            obs_dir = root / "evidence/model-results/obs-step"
            obs_dir.mkdir(parents=True)
            log_obs = observe(b"The outcome is: NoError\n[ok] No violation found\n")
            receipt = obs_dir / "receipt.json"
            receipt.write_text(json.dumps({
                "schema": "gambit-induction-matrix-result.v1",
                "accepted": False, "runtimeAdmitted": False,
                "releaseAdmitted": False, "temporalProved": False,
                "obligationKind": "termination-step", "targetStep": "countOrRetry",
                "exit": 0, "timeout": False,
                "results": [{"step": "countOrRetry", "log": "step.log",
                             "logSha256": log_obs["sha256"], "exit": 0,
                             "timeout": False, "obligationProved": True}],
            }))
            rsha = digest(receipt)
            (obs_dir / "archive.json").write_text(json.dumps({
                "schema": "gambit-model-attempt-archive.v1",
                "archiveOnly": True, "accepted": False,
                "runtimeAdmitted": False, "releaseAdmitted": False,
                "originalReceiptSha256": rsha,
                "files": {"receipt.json": {"rawSha256": rsha, "portableSha256": rsha}},
                "outputs": {"step.log": log_obs},
            }))
            cat = {
                "schema": "gambit-induction-observations.v1",
                "protocolModel": "gc_recursive_queue_wait",
                "proofLayer": "models/gambit/gc_ind.qnt",
                "notes": "docs/notes.md",
                "overallAccepted": False,
                "observations": [{
                    "id": "induction-termination-step-preservation",
                    "kind": "transition-preservation",
                    "receipt": "evidence/model-results/obs-step/receipt.json",
                    "receiptSha256": rsha,
                    "obligationProved": True,
                    "coveredTransitions": ["countOrRetry"],
                    "finding": "Single-step preservation only.",
                }],
            }
            cat_path = root / "evidence/induction-observations.json"
            cat_path.write_text(json.dumps(cat))
            parsed, inputs = review_inputs.proof_observations(root)
            self.assertEqual(1, len(parsed["observations"]))
            self.assertEqual(["countOrRetry"], parsed["observations"][0]["coveredTransitions"])
            self.assertIn("evidence/model-results/obs-step/archive.json", inputs)
            cat["observations"][0]["receipt"] = ".cache/legacy/receipt.json"
            cat_path.write_text(json.dumps(cat))
            with self.assertRaisesRegex(ValueError, "persistent evidence"):
                review_inputs.proof_observations(root)


if __name__ == "__main__":
    unittest.main()
