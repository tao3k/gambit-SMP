"""Identity and admission controls for the actual-start ranking bridge."""
import json
import unittest
from pathlib import Path

from gambit_smp.framework import ROOT, digest


class GcRankInitialBridgeTests(unittest.TestCase):
    base = ROOT / "evidence/model-results/gc-rank-initial-bridge"

    def receipt(self, name):
        return json.loads((self.base / name / "receipt.json").read_text())

    def test_all_archives_are_complete_and_non_admitted(self):
        for name in ("initial-import-denial", "actual-initial", "invalid-history-control"):
            folder = self.base / name
            archive = json.loads((folder / "archive.json").read_text())
            self.assertTrue(archive["archiveOnly"])
            for path, expected in archive["files"].items():
                self.assertEqual(Path(path).name, path)
                self.assertEqual(digest(folder / path), expected)
            receipt = self.receipt(name)
            for flag in ("accepted", "runtimeAdmitted", "releaseAdmitted",
                         "temporalProved", "generatorCoverageProved"):
                self.assertIs(receipt[flag], False)
            self.assertTrue(receipt["contextStable"])
            for path, expected in receipt["inputs"].items():
                self.assertEqual(digest(folder / Path(path).name), expected)
            self.assertEqual(digest(folder / receipt["log"]), receipt["logSha256"])

    def test_actual_start_is_a_zero_step_pass_not_temporal_admission(self):
        receipt = self.receipt("actual-initial")
        result = receipt["observation"]
        self.assertTrue(receipt["obligationProved"])
        self.assertTrue(result["obligationProved"])
        self.assertEqual((result["initializer"], result["length"], result["exit"]),
                         ("initActual", 0, 0))
        self.assertFalse(result["timeout"])

    def test_negative_control_is_an_actual_counterexample(self):
        receipt = self.receipt("invalid-history-control")
        result = receipt["observation"]
        self.assertTrue(receipt["expectedCounterexample"])
        self.assertTrue(result["counterexample"])
        self.assertFalse(result["obligationProved"])
        self.assertFalse(result["timeout"])
        self.assertNotEqual(result["exit"], 0)

    def test_import_failure_is_not_a_counterexample(self):
        result = self.receipt("initial-import-denial")["observation"]
        self.assertFalse(result["counterexample"])
        self.assertFalse(result["obligationProved"])
        log = (self.base / "initial-import-denial/initial.log").read_text()
        self.assertIn("QNT404", log)

    def test_positive_bridge_is_unchanged_when_control_is_added(self):
        name = "gc_rank_actual_initial.qnt"
        prior = (self.base / "actual-initial" / name).read_text()
        current = (ROOT / "models/gambit" / name).read_text()
        marker = "\n\n  // Negative control:"
        self.assertEqual(current.split(marker, 1)[0] + "\n}\n", prior)
        self.assertIn('Set("source", "combined").oneOf()', prior)
        self.assertIn('s\' = initial(policy, "none")', prior)
        self.assertIn("advanced' = false", prior)

    def test_protocol_dependencies_are_still_exact(self):
        receipt = self.receipt("actual-initial")
        for path, expected in receipt["inputs"].items():
            if Path(path).name != "gc_rank_actual_initial.qnt":
                self.assertEqual(digest(ROOT / path), expected)
