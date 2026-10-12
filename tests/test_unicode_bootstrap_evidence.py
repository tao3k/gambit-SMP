import json
import unittest

from gambit_smp.framework import ROOT, digest


class UnicodeBootstrapEvidenceTests(unittest.TestCase):
    def test_full_scalar_observation_and_typed_controls(self):
        folder = ROOT / "evidence/source-results/fixtures/sfun-owned-unwind/unicode-scalar-bootstrap"
        archive = json.loads((folder / "archive.json").read_text())
        for name, expected in archive["files"].items():
            self.assertEqual(digest(folder / name), expected)
            self.assertNotIn("/Users/", (folder / name).read_text())
        receipt = json.loads((folder / "receipt.json").read_text())
        validation = json.loads((folder / "record-validation.json").read_text())
        self.assertEqual(receipt["status"], "PASS")
        self.assertEqual(receipt["rawReceiptSha256"], validation["rawReceiptSha256"])
        self.assertEqual(validation["fixtureSha256"], digest(folder / "unicode_scalar_semantics.scm"))
        self.assertEqual(validation["checkerSha256"], digest(folder / "unicode_scalar_records.py"))
        self.assertEqual(validation["result"]["records"], 1112064)
        self.assertEqual(validation["result"]["bytes"], 1112064 * 22)
        self.assertTrue(validation["recordValidationPassed"])
        self.assertEqual({row["name"] for row in validation["controls"]},
                         {"truncated", "duplicate", "semantic-upcase"})
        self.assertTrue(all(row["rejected"] for row in validation["controls"]))
        self.assertEqual({row["name"] for row in receipt["observations"]}, {"seed", "bootstrap"})
        for runtime in receipt["observations"]:
            self.assertTrue(runtime["sourceStable"])
            for stage in runtime["observations"]:
                observed = stage["observation"]
                self.assertEqual(observed["exit"], 0)
                self.assertFalse(observed["timeout"])
                self.assertTrue(observed["group_quiescent"])
        for document in (archive, receipt, validation):
            for flag in ("runtimeAdmitted", "releaseAdmitted", "performanceAdmitted"):
                self.assertFalse(document[flag])
        self.assertFalse(archive["generatedByteParity"])
        prior = json.loads((folder / "prior-titlecase-denial.json").read_text())
        self.assertEqual(prior["firstRejectedScalar"], 305)


if __name__ == "__main__":
    unittest.main()
