"""Real Library inference and action transport, not collector qualification."""
import unittest
import uuid
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT
from gambit_smp import research_actions

VIEW = "evidence/scenarios/concurrent-gc/reasons.view.json"


class DesignReasonsTests(unittest.TestCase):
    def test_current_lifecycle_keeps_uncovered_obligations_open(self):
        document, facts, catalog, _ = load(ROOT, "evidence/scenarios/concurrent-gc/lifecycle-024.view.json")
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(len(answers["why"]), 3)
            self.assertEqual(len(answers["unknown"]), 4)
            self.assertEqual(len(answers["tradeoff"]), 1)
            self.assertEqual(answers["missing_flag"], [])
            withdrawn = dict(facts, source=[row for row in facts["source"] if row[0] != "moving-run"])
            changed, _ = evaluate(engine, withdrawn, catalog, document["queries"])
            self.assertEqual(len(changed["why"]), 1)
            self.assertEqual(len(changed["unknown"]), 6)

    def test_compiled_ffi_closes_only_its_exact_requirement(self):
        document, facts, catalog, _ = load(ROOT, "evidence/scenarios/concurrent-gc/stable-ffi-023.view.json")
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(len(answers["why"]), 1)
            self.assertEqual(answers["why"][0][1], "stable-payload-ffi")
            self.assertEqual(len(answers["unknown"]), 3)
            self.assertEqual(answers["missing_flag"], [])
            self.assertEqual(answers["why_not"], [])
            withdrawn = dict(facts, source=[row for row in facts["source"] if row[0] != "bootstrap-config"])
            changed, _ = evaluate(engine, withdrawn, catalog, document["queries"])
            self.assertEqual(len(changed["missing_flag"]), 3)
    def test_scoped_reasons_withdraw_and_restore(self):
        document, facts, catalog, inputs = load(ROOT, VIEW)
        self.assertGreater(len(inputs), 5)
        with engine_api() as (engine, _):
            answers, first = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(len(answers["why"]), 5)
            self.assertEqual(len(answers["why_not"]), 3)
            self.assertEqual(len(answers["unknown"]), 7)
            self.assertEqual(len(answers["missing_flag"]), 3)
            self.assertEqual(len(answers["tradeoff"]), 4)
            self.assertTrue(all("native" in row[3] or row[3] in
                                ("handoff-conservation", "ffi-producer-custody", "ffi-original-budget")
                                for row in answers["unknown"]))
            changed = dict(facts, source=[r for r in facts["source"] if r[0] != "chez"])
            withdrawn, _ = evaluate(engine, changed, catalog, document["queries"])
            self.assertEqual(len(withdrawn["why"]), 4)
            self.assertEqual(len(withdrawn["unknown"]), 8)
            self.assertEqual(withdrawn["why_not"], answers["why_not"])
            restored, last = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(restored, answers)
            self.assertEqual(first["sessionOwner"], last["sessionOwner"])

    def test_action_discovery_has_no_adoption_or_execution(self):
        snapshot = research_actions.discover(ROOT, {"views": [VIEW]})
        actions = [r for r in snapshot["actions"] if r.get("query") in
                   ("why", "why_not", "unknown", "tradeoff")]
        self.assertEqual(len(actions), 4)
        for action in actions:
            self.assertEqual(action["risk"], "read-only")
            self.assertFalse(action["explanation"]["executionAuthorized"])
        selected = next(r for r in actions if r["query"] == "why_not")
        handle = str(uuid.uuid4())
        result = research_actions.select(ROOT, snapshot, selected["id"], {}, handle,
                                         authorize_execution=True)
        self.assertEqual(result["result"]["outcome"], "RECORDED")
        observed = research_actions.observe(ROOT, handle)
        self.assertEqual(observed["result"]["inspection"]["status"], "CURRENT")


if __name__ == "__main__":
    unittest.main()
