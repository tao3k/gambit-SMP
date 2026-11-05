"""Scoped lifecycle support never promotes work bounds to native admission."""
import unittest

from gambit_smp import repository_clues
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT


class CleanupAdmissionEvidenceTests(unittest.TestCase):
    def test_partial_native_support_and_work_proof_withdrawal(self):
        document, facts, catalog, _ = load(
            ROOT, "evidence/scenarios/runtime-lifecycle/cleanup-admission.view.json")
        queries = dict(document["queries"], applicable="applicable")
        target = ("admission-prefix-rollback", "admission-native")
        with engine_api() as (engine, _):
            before, _ = evaluate(engine, facts, catalog, queries)
            self.assertIn(target, before["applicable"])
            self.assertIn(("complete-lifecycle-faults",), before["unclosed"])
            self.assertIn(("admission-work-bound",), before["unclosed"])
            for name in ("model", "work-proof", "program"):
                changed = dict(facts, current_binding=[
                    (key, "changed" if key == name else value)
                    for key, value in facts["current_binding"]])
                after, _ = evaluate(engine, changed, catalog, queries)
                self.assertNotIn(target, after["applicable"])
                self.assertEqual(changed["receipt"], facts["receipt"])

    def test_first_relational_query_finds_scoped_rollback_evidence(self):
        result = repository_clues(ROOT, bindings=(
            ("entity", "lifecycle"), ("phase", "native-precommit-rollback-pass")))
        brief = result["brief"]
        family = brief["families"][0]
        self.assertEqual(family["claim"], "admission-prefix-rollback")
        self.assertFalse(family["unknown"])
        self.assertFalse(brief["executionAuthorized"])
        self.assertFalse(brief["runtimeAdmitted"])
