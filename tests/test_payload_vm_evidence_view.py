"""Real Library source-gap/action transport; no runtime acceptance logic."""
import unittest
import uuid

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT
from gambit_smp import research_actions
from tests.historical_view import projection

VIEW = "evidence/scenarios/concurrent-gc/payload-transfer.view.json"


class PayloadVMViewTests(unittest.TestCase):
    def test_source_counterexamples_do_not_admit_new_candidate(self):
        document, facts, catalog, inputs = projection(ROOT, VIEW)
        self.assertGreater(len(inputs), 50)
        with engine_api() as (engine, _):
            answer, first = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(len(answer["open"]), 9)
            self.assertEqual(len(answer["source_gap"]), 6)
            self.assertEqual(len(answer["missing_metric"]), 6)
            self.assertEqual(len(answer["missing_flag"]), 3)
            self.assertEqual(answer["configured"], [])
            changed = dict(facts, source=[r for r in facts["source"]
                if r[0] != "candidate:lib/_thread.scm"])
            withdrawn, _ = evaluate(engine, changed, catalog, document["queries"])
            self.assertEqual(len(withdrawn["source_gap"]), 4)
            self.assertEqual(withdrawn["open"], answer["open"])
            restored, last = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(restored, answer)
            self.assertEqual(first["sessionOwner"], last["sessionOwner"])
            self.assertGreater(last["sourceGeneration"], first["sourceGeneration"])

    def test_source_investigation_is_read_only_and_generation_bound(self):
        with self.assertRaisesRegex(ValueError, "historical Evidence view"):
            research_actions.discover(ROOT, {"views": [VIEW]})
        snapshot = research_actions.discover(ROOT, {"views": [
            "evidence/scenarios/concurrent-gc/darwin-source-032.view.json"]})
        selected = next(r for r in snapshot["actions"] if r["query"] == "missing_flag")
        self.assertEqual(selected["risk"], "read-only")
        self.assertFalse(selected["explanation"]["executionAuthorized"])
        handle = str(uuid.uuid4())
        result = research_actions.select(ROOT, snapshot, selected["id"], {}, handle,
                                         authorize_execution=True)
        self.assertEqual(result["result"]["outcome"], "RECORDED")
        observed = research_actions.observe(ROOT, handle)
        self.assertEqual(observed["result"]["inspection"]["status"], "CURRENT")


if __name__ == "__main__":
    unittest.main()
