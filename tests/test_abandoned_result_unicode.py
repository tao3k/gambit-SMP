import json
import unittest

from gambit_smp.framework import ROOT, digest


class AbandonedResultUnicodeTests(unittest.TestCase):
    def test_new_bootstrap_artifact_scalar_equivalence_is_bound(self):
        folder = ROOT / "evidence/source-results/fixtures/abandoned-result-state/unicode-scalar-bootstrap"
        archive = json.loads((folder / "archive.json").read_text())
        for name, expected in archive["files"].items():
            self.assertEqual(digest(folder / name), expected)
            self.assertNotIn("/Users/", (folder / name).read_text())
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertEqual(receipt["status"], "PASS")
        self.assertTrue(receipt["fixtureStable"])
        self.assertLessEqual(receipt["nativeSeconds"], receipt["wholeCampaignBudget"])
        self.assertEqual(receipt["wholeCampaignBudget"], 90)
        self.assertLessEqual(receipt["jobs"] * receipt["populationPerRuntime"], receipt["cpuCapacity"])
        self.assertEqual(receipt["processorSelection"], "host-auto")
        self.assertEqual(receipt["sourceLockSha256"],
                         digest(ROOT / "evidence/fixtures/abandoned-result-state/source.lock.json"))
        for row, name in zip(receipt["observations"], ("seed-identity.json", "bootstrap-identity.json")):
            self.assertEqual(row["identitySha256"], digest(folder / name))
            self.assertTrue(row["sourceStable"])
            self.assertEqual([stage["stage"] for stage in row["stages"]], ["compile", "execute"])
            for stage in row["stages"]:
                self.assertTrue(stage["accepted"])
                self.assertEqual(stage["observation"]["exit"], 0)
                self.assertFalse(stage["observation"]["timeout"])
                self.assertTrue(stage["observation"]["group_quiescent"])
        self.assertEqual(len(receipt["observations"]), 2)
        bootstrap = ROOT / "evidence/source-results/fixtures/abandoned-result-state/two-pass-bootstrap/candidate.json"
        self.assertEqual(digest(folder / "bootstrap-identity.json"), digest(bootstrap))
        self.assertEqual(receipt["adapterSha256"], digest(folder / "unicode_campaign.py"))
        self.assertEqual(receipt["fixtureSha256"], digest(folder / "unicode_scalar_semantics.scm"))
        self.assertEqual(receipt["equivalence"]["records"], 1112064)
        self.assertEqual(receipt["equivalence"]["bytes"], 24465408)
        self.assertEqual({row["name"] for row in receipt["recordControls"]},
                         {"truncated", "duplicate", "semantic-upcase"})
        self.assertTrue(all(row["rejected"] for row in receipt["recordControls"]))
        for document in (receipt, archive):
            for flag in ("runtimeAdmitted", "releaseAdmitted", "performanceAdmitted"):
                self.assertFalse(document[flag])
        self.assertFalse(archive["generatedByteParity"])
