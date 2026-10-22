"""Retain a real two-pass result without claiming full runtime qualification."""
import json
import unittest

from gambit_smp.framework import ROOT, digest, relative
from tests.support import published_digest


class SfunBootstrapEvidenceTests(unittest.TestCase):
    def test_two_pass_inventory_flags_and_source_authority(self):
        folder = ROOT / "evidence/source-results/fixtures/sfun-owned-unwind/two-pass-bootstrap"
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        for path, expected in archive["files"].items():
            self.assertEqual(published_digest(ROOT, folder / path), expected)
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertEqual(receipt["status"], "PASS")
        self.assertEqual(receipt["target"], "from-scratch")
        self.assertEqual(receipt["observedParentExit"], 0)
        self.assertEqual(receipt["wholeBootstrapBudget"], 600)
        self.assertEqual(len(receipt["steps"]), 1)
        row = receipt["steps"][0]
        self.assertEqual(row["name"], "from-scratch")
        self.assertEqual(row["exit"], 0)
        self.assertFalse(row["timeout"])
        self.assertLessEqual(row["seconds"], receipt["wholeBootstrapBudget"])
        self.assertTrue(row["process"]["parentReaped"])
        self.assertTrue(row["process"]["processGroupQuiescent"])
        self.assertEqual(receipt["processorSelection"], "host-auto")
        self.assertGreater(receipt["processors"], 0)
        self.assertEqual(set(receipt["requestedFeatures"]), {
            "--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"})
        for flag in receipt["requestedFeatures"]:
            self.assertIn(flag, receipt["configurationOptions"])
        self.assertIn("--enable-c-opt=-O0", receipt["configurationOptions"])
        seed = folder.parent / "historical-seed-inputs"
        seed_archive = json.loads((seed / "archive.json").read_text())
        self.assertEqual(seed_archive["schema"], "gambit-historical-seed-input-archive.v1")
        self.assertTrue(seed_archive["archiveOnly"])
        self.assertEqual(seed_archive["bootstrapReceiptSha256"], digest(folder / "receipt.json"))
        self.assertEqual(seed_archive["files"], receipt["seedSourceInputs"])
        for path, expected in seed_archive["files"].items():
            self.assertEqual(digest(relative(seed, path)), expected)
        for field in ("runtimeAdmitted", "releaseAdmitted", "sourceRefinementAdmitted"):
            self.assertFalse(seed_archive[field])
        for field in ("originalSourceStable", "immutableSourceStable", "generatedSourcePresent",
                      "compilerWorkObserved", "repairProofInputsStable"):
            self.assertTrue(receipt[field])
        self.assertEqual(receipt["recursiveBuildErrors"], [])
        identity = json.loads((folder / "candidate.json").read_text())
        self.assertEqual(digest(folder / "candidate.json"), receipt["candidateIdentitySha256"])
        for key, expected in receipt["artifacts"].items():
            self.assertEqual(identity[key], expected)
        from gambit_smp.output_observations import recorded
        output = recorded(ROOT, folder / "bootstrap.log")
        for phase in range(1, 5):
            self.assertEqual(output['buildPhases'][str(phase)], 2)
        self.assertTrue(output['bootstrapBeforeCore'])
        for field in ("runtimeAdmitted", "releaseAdmitted", "performanceAdmitted", "generatedByteParity"):
            self.assertFalse(receipt[field])
        self.assertEqual(set(receipt["changedSourceFiles"]), {"lib/_std.c", "lib/_module.c"})


if __name__ == "__main__":
    unittest.main()
