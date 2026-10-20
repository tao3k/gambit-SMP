"""Real OS-failure scope, current bindings and incremental evidence reuse."""
import json
import unittest

from gambit_smp import repository_clues
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT, digest
from gambit_smp.reflection import validate


class ConstructorSameStorageEvidenceTests(unittest.TestCase):
    def test_native_prefix_is_supported_without_admitting_all_failures(self):
        document, facts, catalog, _ = load(
            ROOT, "evidence/scenarios/runtime-lifecycle/constructor-same-storage.view.json")
        queries = dict(document["queries"], applicable="applicable")
        target = ("constructor-os-same-storage-retry", "constructor-native")
        with engine_api() as (engine, _):
            before, _ = evaluate(engine, facts, catalog, queries)
            self.assertIn(target, before["applicable"])
            self.assertIn(("constructor-unqualified-failures",), before["unclosed"])
            for name in ("candidate", "model", "callee", "program", "patch"):
                changed = dict(facts, current_binding=[
                    (key, "changed" if key == name else value)
                    for key, value in facts["current_binding"]])
                after, _ = evaluate(engine, changed, catalog, queries)
                self.assertNotIn(target, after["applicable"])
                self.assertEqual(changed["receipt"], facts["receipt"])

    def test_first_query_and_checkpoint_reuse_preserve_open_scope(self):
        bindings = (("entity", "lifecycle"),
                    ("phase", "constructor-os-same-storage-native-pass"))
        first = repository_clues(ROOT, bindings=bindings)
        family = first["brief"]["families"][0]
        self.assertEqual(family["claim"], "constructor-os-same-storage-retry")
        self.assertFalse(family["unknown"])
        self.assertEqual(first["brief"]["counts"]["support"], 1)
        continued = repository_clues(ROOT, checkpoint=first["checkpoint"])
        self.assertEqual(continued["brief"]["families"], [])
        self.assertEqual(first["brief"]["sourceIdentity"], continued["brief"]["sourceIdentity"])
        self.assertFalse(continued["brief"]["executionAuthorized"])
        expanded = repository_clues(ROOT, "constructor-unqualified-failures",
                                    checkpoint=continued["checkpoint"])
        self.assertTrue(expanded["brief"]["explorationOpen"])
        self.assertFalse(expanded["brief"]["runtimeAdmitted"])

    def test_callback_reflection_keeps_original_design_bytes(self):
        audit = json.loads((ROOT / "evidence/research-audit.json").read_text())
        name = "docs/callback-context-performance-reliability-stability.md"
        matches = [issue["reflection"] for issue in audit["issues"]
                   if "reflection" in issue and any(
                       artifact["path"] == name
                       for ref in issue["reflection"]["references"]
                       for artifact in ref.get("artifacts", []))]
        self.assertEqual(len(matches), 1)
        self.assertIn(name, validate(ROOT, matches[0]))
        self.assertEqual(digest(ROOT / name),
                         "d279cc7f7973b72ca71052c50799248fda7c6c750afd82d88681cbf47bb157cc")
        self.assertNotEqual(digest(ROOT / name),
                            digest(ROOT / "docs/high-performance-reliability-stability.md"))
