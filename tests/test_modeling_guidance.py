"""Real DSL inference and Action transport, not proof or native admission."""
import unittest
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT
from gambit_smp import research_actions

VIEW = "evidence/scenarios/concurrent-gc/modeling-024.view.json"


class ModelingGuidanceTests(unittest.TestCase):
    def test_current_gaps_choose_methods_without_granting_execution(self):
        document, facts, catalog, _ = load(ROOT, VIEW)
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, document["queries"])
            rows = answers["recommendations"]
            self.assertEqual(len(rows), 4)
            self.assertEqual(sorted(row[3] for row in rows),
                             ["Lean", "QNT", "QNT", "matched-measurement"])
            self.assertEqual(answers["unbound"], [])
            withdrawn = dict(facts, source=[row for row in facts["source"] if row[0] != "audit"])
            changed, _ = evaluate(engine, withdrawn, catalog, document["queries"])
            self.assertEqual(changed["recommendations"], [])
            self.assertEqual(len(changed["unbound"]), 4)
            wrong_candidate = dict(facts, focus=[["current-gambit-lifecycle", "candidate", "wrong-sha"]])
            stale, _ = evaluate(engine, wrong_candidate, catalog, document["queries"])
            self.assertEqual(stale["recommendations"], [])

    def test_reported_inspection_stall_and_model_refutation_are_distinct(self):
        document, facts, catalog, _ = load(ROOT, VIEW)
        focused = dict(facts, signal=[["current-gambit-lifecycle", "callback-retirement-races",
                                      "non-discriminating-inspection", "audit"]], assessment=[])
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, focused, catalog, document["queries"])
            self.assertEqual([row[2] for row in answers["recommendations"]], ["review-model-fit"])
            # Coverage is a declared review, not derived from a PASS receipt.
            refuted = dict(focused, signal=[], assessment=[["current-gambit-lifecycle",
                "callback-retirement-races", "continuation-vm-transfer", "refuted-by-execution", "audit"]])
            answers, _ = evaluate(engine, refuted, catalog, document["queries"])
            self.assertEqual([row[2] for row in answers["recommendations"]], ["refine-model"])
            covered = dict(refuted, assessment=[["current-gambit-lifecycle",
                "callback-retirement-races", "continuation-vm-transfer", "covered", "audit"]])
            answers, _ = evaluate(engine, covered, catalog, document["queries"])
            self.assertEqual(answers["recommendations"], [])

    def test_actions_discover_and_select_the_real_view(self):
        import uuid
        snapshot = research_actions.discover(ROOT, {"views": [VIEW]})
        action = next(row for row in snapshot["actions"] if row.get("query") == "recommendations")
        self.assertEqual(action["risk"], "read-only")
        self.assertFalse(action["explanation"]["executionAuthorized"])
        result = research_actions.select(ROOT, snapshot, action["id"], {}, str(uuid.uuid4()),
                                         authorize_execution=True)
        self.assertEqual(result["result"]["outcome"], "RECORDED")

    def test_methods_are_options_not_an_exclusive_ordered_workflow(self):
        document, facts, catalog, _ = load(ROOT, VIEW)
        focused = dict(facts, signal=[["current-gambit-lifecycle", "callback-retirement-races",
                                      "protocol-unclear", "audit"]],
                       assessment=[["current-gambit-lifecycle", "callback-retirement-races",
                                    "continuation-vm-transfer", "covered", "audit"]],
                       method=[*facts["method"], ["finite-transition", "Lean", "Alternative invariant investigation"]])
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, focused, catalog, document["queries"])
            self.assertEqual({row[3] for row in answers["recommendations"]}, {"QNT", "Lean"})
            # A reported covered model does not suppress a new protocol question.
            self.assertTrue(all(row[2] == "model-protocol" for row in answers["recommendations"]))
            quiet = dict(focused, signal=[], assessment=[])
            answers, _ = evaluate(engine, quiet, catalog, document["queries"])
            self.assertEqual(answers["actions"], [])


if __name__ == "__main__":
    unittest.main()
