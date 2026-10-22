"""Native runtime branches require their own exact-source observations."""
import json
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
                if witness != "runtime-retirement-formal":
                    continue
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

    def test_cached_runtime_reports_are_not_reproducible_current_qualification(self):
        document, facts, catalog, _ = load(ROOT,
            "evidence/scenarios/runtime-lifecycle/runtime-retirement.view.json")
        self.assertNotIn("native-result", {r["id"] for r in document["references"]})
        self.assertEqual({row[2] for row in facts["binding"] if row[1] == "native-result"},
                         {"481643cbb68cd447bab22ed540df96f596d9e91b9a5e410af0a8aa577e5bb81e"})
        native = {row[0] for row in facts["receipt"] if row[0].endswith("-native")}
        self.assertTrue(native.isdisjoint(row[0] for row in facts["verified"]))
        self.assertTrue(native.isdisjoint(row[0] for row in facts["command_observation"]))
        self.assertEqual(native, {row[0] for row in facts["withdrawn"]})
        queries = dict(document["queries"], applicable="applicable")
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, queries)
            for receipt, claim, _, _ in facts["receipt"]:
                if receipt in native:
                    self.assertIn((claim,), answers["unclosed"])
                    self.assertNotIn((claim, receipt), answers["applicable"])
        for name in ("runtime_join_quarantine.scm", "terminal_registry_drain.scm"):
            self.assertTrue((ROOT / "models/gambit/native" / name).is_file())
