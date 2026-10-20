"""Native runtime branches require their own exact-source observations."""
import json
import re
import unittest

from gambit_smp import repository_clues
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest


class RuntimeRetirementEvidenceTests(unittest.TestCase):
    def test_formal_context_binds_current_sources(self):
        proof = json.loads((ROOT / "evidence/model-results/processor-interrupt-collective-wait/runtime-retirement-qualified-01/receipt.json").read_text())
        self.assertTrue(proof["accepted"])
        self.assertTrue(proof["contextStable"])
        for name, sha in proof["inputs"].items():
            if name.startswith(("models/", "patches/", "evidence/research/")):
                self.assertEqual(digest(ROOT / name), sha, name)
        self.assertEqual(proof["native"]["status"], "not-run")

    def test_source_or_command_change_revokes_only_supported_scope(self):
        doc, facts, catalog, _ = load(ROOT,
            "evidence/scenarios/runtime-lifecycle/runtime-retirement.view.json")
        queries = dict(doc["queries"], applicable="applicable")
        with engine_api() as (engine, _):
            initial, _ = evaluate(engine, facts, catalog, queries)
            for witness, claim, contract, _ in facts["receipt"]:
                self.assertIn((claim, witness), initial["applicable"])
                for c, k, name in facts["required_binding"]:
                    if (c, k) != (claim, contract):
                        continue
                    changed = dict(facts, current_binding=[
                        (key, "changed" if key == name else value)
                        for key, value in facts["current_binding"]])
                    after, _ = evaluate(engine, changed, catalog, queries)
                    self.assertNotIn((claim, witness), after["applicable"], name)
                for c, k, stage, _ in facts.get("required_command", []):
                    if (c, k) != (claim, contract):
                        continue
                    changed = dict(facts, command_observation=[
                        row for row in facts["command_observation"]
                        if (row[0], row[1]) != (witness, stage)])
                    after, _ = evaluate(engine, changed, catalog, queries)
                    self.assertNotIn((claim, witness), after["applicable"], stage)
            for claim in ("runtime-supported-error-reachability",
                          "runtime-detached-join-successful-recovery"):
                self.assertIn((claim,), initial["unclosed"])

    def test_model_support_does_not_assert_native_or_recovery(self):
        first = repository_clues(ROOT, bindings=(
            ("entity", "lifecycle"), ("mechanism", "runtime-retirement-quarantine"),
            ("phase", "formal-qualified-native-not-run")))
        self.assertEqual(first["brief"]["families"][0]["claim"], "runtime-retirement-model")
        again = repository_clues(ROOT, "runtime-supported-error-reachability",
                                  checkpoint=first["checkpoint"])
        self.assertGreater(again["brief"]["counts"]["counter"], 0)
        self.assertFalse(again["brief"]["runtimeAdmitted"])

    def test_native_runtime_witness_and_logs_match_current_sources(self):
        directory = ROOT / "evidence/source-results/runtime-retirement"
        result = json.loads((directory / "receipt.json").read_text())
        self.assertEqual(result["status"], "PASS")
        self.assertFalse(result["bootstrapRepeated"])
        self.assertFalse(result["naturalJoinFailureReachabilityAdmitted"])
        self.assertTrue(result["originalCheckpointUnchanged"])
        for name, sha in result["inputs"].items():
            self.assertEqual(digest(ROOT / name), sha, name)
        for row in result["commands"]:
            self.assertEqual(row["exit"], 0, row["stage"])
            self.assertFalse(row["timeout"])
            self.assertTrue(row["parentReaped"])
            self.assertTrue(row["processGroupQuiescent"])
            self.assertEqual(digest(directory / row["log"]), row["logSha256"])
        for variant in ("baseline", "candidate"):
            for mode in ("normal", "pending", "sticky"):
                self.assertEqual((directory / f"{variant}-{mode}.log").read_text(),
                                 f"RUNTIME-JOIN-QUARANTINE:{mode}:PASS\n")
        witness = result["terminalWitness"]
        self.assertGreater(witness["captured"], 0)
        self.assertEqual(witness["captured"] % 4, 0)
        self.assertEqual(witness["drained"], 0)
        self.assertEqual(witness["gate"], 3)
        match = re.fullmatch(r"DRAIN-WITNESS captured=(\d+) drained=(\d+) gate=(\d+)\nTERMINAL-REGISTRY-DRAIN:PASS\n",
                             (directory / "terminal-drain-execute.log").read_text())
        self.assertIsNotNone(match)
        self.assertEqual(tuple(map(int, match.groups())),
                         (witness["captured"], witness["drained"], witness["gate"]))
        self.assertEqual(result["executables"]["baseline"]["programSha256"],
                         result["executables"]["candidate"]["programSha256"])
