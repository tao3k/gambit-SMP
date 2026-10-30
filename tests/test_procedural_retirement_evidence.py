"""Scoped native witnesses must not become a whole-lifecycle admission."""
import unittest

from gambit_smp import repository_clues
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT


class ProceduralRetirementEvidenceTests(unittest.TestCase):
    def test_witness_depends_on_each_source_and_leaves_quiescence_open(self):
        document, facts, catalog, _ = load(
            ROOT, "evidence/scenarios/runtime-lifecycle/procedural-retirement.view.json")
        queries = dict(document["queries"], applicable="applicable")
        target = ("procedural-retirement-reachability", "procedural-native")
        with engine_api() as (engine, _):
            before, _ = evaluate(engine, facts, catalog, queries)
            self.assertIn(target, before["applicable"])
            self.assertIn(("all-async-producers-quiescent",), before["unclosed"])
            for name, _ in facts["current_binding"]:
                changed = dict(facts, current_binding=[
                    (key, "changed" if key == name else value)
                    for key, value in facts["current_binding"]])
                after, _ = evaluate(engine, changed, catalog, queries)
                self.assertNotIn(target, after["applicable"], name)
                self.assertIn(("all-async-producers-quiescent",), after["unclosed"])
                self.assertEqual(changed["receipt"], facts["receipt"])

    def test_first_hit_continues_without_repeating_or_prescribing_direction(self):
        first = repository_clues(ROOT, bindings=(
            ("entity", "lifecycle"),
            ("phase", "native-witness-pass-not-whole-lifecycle")))
        brief = first["brief"]
        self.assertEqual(brief["counts"]["support"], 1)
        self.assertEqual(brief["families"][0]["claim"],
                         "procedural-retirement-reachability")
        self.assertFalse(brief["families"][0]["unknown"])
        continued = repository_clues(ROOT, checkpoint=first["checkpoint"])
        self.assertEqual(continued["brief"]["families"], [])
        expanded = repository_clues(ROOT, "all-async-producers-quiescent",
                                    checkpoint=continued["checkpoint"])
        self.assertGreater(expanded["brief"]["counts"]["counter"], 0)
        self.assertTrue(expanded["brief"]["explorationOpen"])
        self.assertFalse(expanded["brief"]["runtimeAdmitted"])
        self.assertFalse(expanded["brief"]["executionAuthorized"])
