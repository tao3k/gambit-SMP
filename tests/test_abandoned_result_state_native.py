import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_archive import validate


class AbandonedResultStateNativeTests(unittest.TestCase):
    def test_rebuilt_runtime_and_complete_selected_native_matrix(self):
        folder = ROOT / "evidence/source-results/fixtures/abandoned-result-state"
        summary = json.loads((folder / "sealed-source-core-summary.json").read_text())
        self.assertEqual(summary["outcome"], "PASS")
        self.assertEqual(summary["observedParentExit"], 0)
        self.assertTrue(summary["parentReaped"])
        self.assertTrue(summary["processGroupQuiescent"])
        self.assertLessEqual(summary["wholeSeconds"], summary["wholeBudgetSeconds"])
        for path, expected in summary["inputs"].items():
            self.assertEqual(digest(ROOT / path), expected)
        for stage in summary["stages"]:
            self.assertEqual(stage["outcome"], "PASS")
            for command in stage["commands"]:
                self.assertEqual(command["exit"], 0)
                self.assertFalse(command["timeout"])
        for flag in ("--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"):
            self.assertIn(flag, summary["configurationOptions"])
        native = folder / "native-sync"
        validate(ROOT, str((native / "archive.json").relative_to(ROOT)))
        receipt = json.loads((native / "receipt.json").read_text())
        identity = json.loads((native / "identity.json").read_text())
        self.assertEqual(summary["identitySha256"], digest(native / "identity.json"))
        for field in ("binarySha256", "gscSha256", "librarySha256"):
            self.assertEqual(summary[field], identity[field])
        self.assertEqual(len(receipt["selectedFiles"]), 9)
        self.assertEqual({row["mode"] for row in receipt["results"]}, {"gsi", "gsc"})
        fixture = "99-regressions/ended_interrupt_result_lifecycle.scm"
        self.assertIn(fixture, receipt["selectedFiles"])
        self.assertEqual(receipt["extraFixtures"][fixture]["sha256"],
                         digest(ROOT / "models/gambit/native/ended_interrupt_result_lifecycle.scm"))
        for row in receipt["results"]:
            self.assertTrue(row["accepted"])
            self.assertTrue(row["sourceStable"])
            self.assertLessEqual(row["seconds"], receipt["wholeSuiteBudgetPerMode"])
            covered = [name for shard in row["process"]["shards"] for name in shard["files"]]
            self.assertEqual(sorted(covered), sorted(receipt["selectedFiles"]))
        for field in ("runtimeAdmitted", "releaseAdmitted", "sourceRefinementAdmitted", "performanceAdmitted"):
            self.assertFalse(summary[field])


if __name__ == "__main__":
    unittest.main()
