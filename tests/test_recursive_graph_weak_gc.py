"""Exact cyclic payload/weak-key observations, not full collector admission."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.review_validation import changed_inputs


BASE = "evidence/source-results/fixtures/sfun-owned-unwind"


class RecursiveGraphWeakGcTests(unittest.TestCase):
    def receipt(self, name):
        folder = ROOT / BASE / name
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        for path, expected in archive["files"].items():
            self.assertEqual(digest(folder / path), expected)
        return folder, json.loads((folder / "receipt.json").read_text())

    def test_complete_historical_inventory_reports_current_transport_drift(self):
        folder, receipt = self.receipt("recursive-graph-weak-controls")
        self.assertTrue(receipt["controlsPassed"])
        self.assertTrue(receipt["identityUnchanged"])
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])
        self.assertFalse(receipt["performanceAdmitted"])
        self.assertEqual(receipt["observedParentExit"], 0)
        summary = ROOT / BASE / "sealed-source-core-summary.json"
        self.assertEqual(receipt["sourceCoreSummarySha256"], digest(summary))
        self.assertEqual(receipt["identitySha256"], digest(folder / "identity.json"))
        # The receipt predates thread-pool transport. Its archived observations
        # remain historical; a changed producer cannot become current evidence.
        drift = changed_inputs(ROOT, receipt["inputs"])
        self.assertEqual(drift, ["src/gambit_smp/process_observation.py"])
        for path, expected in receipt["inputs"].items():
            if path in drift:
                self.assertNotEqual(digest(ROOT / path), expected)
            else:
                self.assertEqual(digest(ROOT / path), expected)
        self.assertTrue(receipt["archiveOnly"])
        population = receipt["cpuCapacity"]
        self.assertEqual(receipt["runtimePopulation"], population)
        self.assertEqual(receipt["compilerPopulation"], 1)
        self.assertGreaterEqual(population, 2)
        expected = (f"RECURSIVE-GC:processors={population},nodes=1024,forced={population * 3},"
                    f"checks={population * 4 * (1024 * 7 + 1)}\n"
                    "NATIVE-OK:recursive_graph_weak_gc\n")
        rows = receipt["observations"]
        self.assertEqual([r["stage"] for r in rows], ["compile"] +
                         [f"{mode}-{i}" for mode in ("compiled", "interpreted") for i in range(1, 4)])
        for row in rows:
            observed = row["observation"]
            self.assertEqual(observed["exit"], 0)
            self.assertFalse(observed["timeout"])
            self.assertTrue(observed["group_quiescent"])
            self.assertEqual(observed["stderr"], "")
            self.assertEqual(row["budgetSeconds"], 60 if row["stage"] == "compile" else 30)
            if row["stage"] != "compile":
                self.assertEqual(observed["stdout"], expected)

    def test_fault_controls_preserve_fixture_except_one_declared_mutation(self):
        folder, receipt = self.receipt("recursive-graph-weak-controls")
        self.assertTrue(receipt["negativeControlsPassed"])
        original = (folder / "source/recursive_graph_weak_gc.scm").read_text()
        self.assertEqual(original, (ROOT / "models/gambit/native/recursive_graph_weak_gc.scm").read_text())
        self.assertEqual({r["name"] for r in receipt["negativeControls"]},
                         {"broken-alias", "wrong-weak-value"})
        for control in receipt["negativeControls"]:
            mutation = control["mutation"]
            self.assertEqual(original.count(mutation["old"]), 1)
            path = folder / "source" / control["name"] / "recursive_graph_weak_gc.scm"
            self.assertEqual(path.read_text(), original.replace(mutation["old"], mutation["new"]))
            self.assertEqual(digest(path), control["sourceSha256"])
            self.assertEqual(control["compile"]["observation"]["exit"], 0)
            self.assertEqual([r["mode"] for r in control["runs"]], ["compiled", "interpreted"])
            for row in control["runs"]:
                observed = row["observation"]
                self.assertEqual(observed["exit"], 70)
                self.assertFalse(observed["timeout"])
                self.assertTrue(observed["group_quiescent"])
                self.assertIn("recursive graph/weak key changed", observed["stderr"])
                self.assertNotIn("NATIVE-OK", observed["stdout"])

    def test_wrapped_error_observation_is_not_typed_control_acceptance(self):
        _, denied = self.receipt("recursive-graph-untyped-control-denial")
        self.assertEqual(denied["observedParentExit"], 1)
        self.assertNotIn("negativeControlsPassed", denied)
        observed = denied["negativeControls"][0]["runs"][0]["observation"]
        self.assertEqual(observed["exit"], 70)
        self.assertEqual(observed["stderr"], "")
        self.assertIn("Uncaught exception", observed["stdout"])


if __name__ == "__main__":
    unittest.main()
