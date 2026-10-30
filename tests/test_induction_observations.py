import json
from pathlib import Path
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import relative
from gambit_smp.output_observations import recorded


class InductionObservationTests(unittest.TestCase):
    def test_observations_bind_portable_receipts_without_whole_model_admission(self):
        catalog = json.loads((ROOT / "evidence/induction-observations.json").read_text())
        self.assertFalse(catalog["overallAccepted"])
        self.assertEqual("gc_recursive_queue_wait", catalog["protocolModel"])
        self.assertEqual(16, len(catalog["observations"]))
        self.assertEqual(16, len({row["id"] for row in catalog["observations"]}))
        for row in catalog["observations"]:
            with self.subTest(observation=row["id"]):
                self.assertNotIn(".data", Path(row["receipt"]).parts)
                path = relative(ROOT, row["receipt"])
                self.assertEqual(row["receiptSha256"], digest(path))
                saved = json.loads(path.read_text())
                self.assertFalse(saved["accepted"])
                self.assertFalse(saved["runtimeAdmitted"])
                self.assertFalse(saved["releaseAdmitted"])
                self.assertFalse(saved["temporalProved"])
                if row["kind"] in ("preservation-matrix", "ranking-matrix"):
                    self.assertTrue(saved["initialProved"] and saved["preservationComplete"] and saved["implicationProved"])
                    self.assertEqual(22, len(saved["provedActions"]))
                    self.assertFalse(saved["generatorCoverageProved"])
                    self.assertFalse(saved["inductiveSafetyAdmitted"])
                    if row["kind"] == "ranking-matrix":
                        self.assertEqual("ranking", saved["proofKind"])
                        self.assertTrue(saved["safetyObligationsRevalidated"])
                        self.assertTrue(saved["ghostUpdatesChecked"])
                        self.assertTrue(all(item["step"] == "ranked_" + item["originalStep"]
                            for item in saved["results"] if item["kind"] == "preservation"))
                elif row["kind"] == "ranking-composition":
                    self.assertTrue(saved["auditPassed"] and saved["contextStable"])
                    self.assertEqual("boundedAndStrict", saved["results"][0]["invariant"])
                    self.assertTrue(saved["results"][0]["obligationProved"])
                    self.assertTrue(saved["results"][1]["counterexample"])
                    self.assertFalse(any(item["timeout"] for item in saved["results"]))
                elif row["kind"] in ("necessary-guard-coverage", "defined-transition-coverage"):
                    self.assertTrue(saved["auditPassed"] and saved["contextStable"] and saved["projectionVerified"])
                    self.assertEqual(22, len(saved["originalActions"]))
                    self.assertTrue(saved["results"][0]["obligationProved"])
                    self.assertTrue(saved["results"][1]["counterexample"])
                    self.assertFalse(saved["enablednessProved"] or saved["rhsDefinednessProved"])
                    archive = json.loads((path.parent / "archive.json").read_text())
                    for name in ("protocol-ir.json", "proof-ir.json"):
                        self.assertIn(name, archive["files"])
                    if row["kind"] == "defined-transition-coverage":
                        self.assertEqual("conservative-defined-transition", saved["projectionKind"])
                        self.assertEqual(["get", "nth", "set"], saved["partialOperationsCovered"])
                        self.assertTrue(saved["generatorContract"]["contractVerified"])
                        self.assertEqual(22, saved["generatorContract"]["independentChoices"])
                        self.assertFalse(saved["generatorContract"]["solverCoverageProved"])
                elif row["kind"] == "definedness-semantic-controls":
                    self.assertTrue(saved["auditPassed"] and saved["contextStable"] and saved["projectionVerified"])
                    self.assertTrue(saved["conflictingAssignmentRejected"])
                    self.assertEqual("QNT202", saved["results"][0]["expectedRejection"])
                    self.assertEqual(8, len(saved["results"]))
                    self.assertTrue(all(item["obligationProved"] for item in saved["results"][1:3]))
                    self.assertTrue(all(item["counterexample"] for item in saved["results"][3:]))
                    self.assertFalse(saved["enablednessProved"])
                elif row["kind"] == "original-evaluation-controls":
                    self.assertTrue(saved["auditPassed"] and saved["contextStable"])
                    self.assertEqual(4, len(saved["results"]))
                    self.assertEqual(0, saved["results"][0]["exit"])
                    self.assertEqual(["QNT507", "QNT507", "QNT510"],
                                     [item["expectedError"] for item in saved["results"][1:]])
                    self.assertTrue(all(item["exit"] != 0 for item in saved["results"][1:]))
                    self.assertFalse(saved["enablednessProved"])
                elif row["kind"] == "fairness-controls":
                    self.assertTrue(saved["auditPassed"] and saved["contextStable"])
                    self.assertEqual(len(saved["results"]), 6)
                    for item in saved["results"]:
                        self.assertFalse(item["timeout"])
                        self.assertEqual(item["states"]["queued"], 0)
                        self.assertTrue(item["expectedOutcomeMatched"])
                        self.assertEqual(item["counterexample"], item["kind"] == "unbounded")
                    self.assertFalse(row["obligationProved"])
                elif row["kind"] == "fairness-ir-correspondence":
                    self.assertTrue(saved["auditPassed"] and saved["fullDisjunctionCorrespondence"])
                    self.assertEqual(saved["importedOriginalBranches"], 21)
                    self.assertFalse(saved["sourceFairnessProved"] or saved["wakeBodyEquivalenceProved"])
                else:
                    self.assertEqual(row["obligationProved"], saved.get("obligationProved", False))
                if row["kind"] == "counterexample":
                    if "results" in saved and saved.get("schema") == "gambit-induction-matrix-result.v1":
                        failures = [item for item in saved["results"] if item["counterexample"]]
                        self.assertTrue(failures)
                        output = recorded(ROOT, relative(path.parent, failures[0]['log']))
                    else:
                        self.assertTrue(saved["closureCounterexample"])
                        output = recorded(ROOT, relative(path.parent, saved['log']))
                    self.assertIn(0, output['traceStateIndices'])
                    self.assertIn(1, output['traceStateIndices'])

    def test_preservation_is_only_the_named_original_transition(self):
        catalog = json.loads((ROOT / "evidence/induction-observations.json").read_text())
        rows = [row for row in catalog["observations"] if row["kind"] == "transition-preservation"]
        self.assertEqual(1, len(rows))
        self.assertEqual(["countOrRetry"], rows[0]["coveredTransitions"])
        saved = json.loads(relative(ROOT, rows[0]["receipt"]).read_text())
        self.assertEqual("termination-step", saved["obligationKind"])
        self.assertEqual("countOrRetry", saved["targetStep"])
        self.assertFalse(saved["timeout"])
        self.assertEqual(0, saved["exit"])


if __name__ == "__main__":
    unittest.main()
