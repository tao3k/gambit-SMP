import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_archive import validate


class BootstrapSyncEvidenceTests(unittest.TestCase):
    def test_exact_mode_and_file_coverage_on_rebuilt_artifacts(self):
        name = "evidence/source-results/fixtures/sfun-owned-unwind/bootstrap-sync-suite/archive.json"
        validate(ROOT, name)
        folder = (ROOT / name).parent
        receipt = json.loads((folder / "receipt.json").read_text())
        candidate = json.loads((folder / "identity.json").read_text())
        rebuilt = json.loads((ROOT / "evidence/source-results/fixtures/sfun-owned-unwind/two-pass-bootstrap/candidate.json").read_text())
        for field in ("binarySha256", "gscSha256", "librarySha256"):
            self.assertEqual(candidate[field], rebuilt[field])
        self.assertEqual(receipt["candidateReceiptSha256"], digest(folder / "identity.json"))
        self.assertEqual(receipt["status"], "PASS")
        expected = {"06-thread/" + name + ".scm" for name in (
            "mutex_race_timeout", "make_mutex", "mutex_unlock_plain", "mutex_race",
            "mutex_lock", "thread_join", "thread_state", "current_processor")}
        self.assertEqual(set(receipt["selectedFiles"]), expected)
        self.assertEqual({row["mode"] for row in receipt["results"]}, {"gsi", "gsc"})
        for row in receipt["results"]:
            self.assertTrue(row["accepted"])
            self.assertTrue(row["sourceStable"])
            self.assertFalse(row["timeout"])
            self.assertEqual(row["exit"], 0)
            self.assertLessEqual(row["seconds"], receipt["wholeSuiteBudgetPerMode"])
            files = [name for shard in row["process"]["shards"] for name in shard["files"]]
            self.assertEqual(len(files), len(set(files)))
            self.assertEqual(set(files), expected)
        self.assertFalse(receipt["performanceAdmitted"])


if __name__ == "__main__":
    unittest.main()
