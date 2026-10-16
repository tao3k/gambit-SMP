"""Actual declarative view transport, source withdrawal and action selection."""
import unittest
import uuid

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT
from gambit_smp import research_actions

VIEW = "evidence/scenarios/concurrent-gc/fdset-captured-032.view.json"


class ConcurrentGCViewTests(unittest.TestCase):
    def test_new_source_candidate_does_not_inherit_historical_products(self):
        document, facts, catalog, inputs = load(ROOT,
            "evidence/scenarios/concurrent-gc/darwin-source-032.view.json")
        self.assertEqual(facts["candidate"][0][0], "darwin-dynamic-modulo-scope")
        self.assertEqual(facts["flag"], [])
        self.assertEqual(facts["evidence"], [])
        self.assertFalse(any("foreign-origin-public-cleanup" in path for path in inputs))
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(answers["configured"], [])
            self.assertEqual(len(answers["missing_flag"]), 3)
            self.assertEqual(len(answers["open"]), 9)

    def test_captured_source_bytes_keep_original_hashes(self):
        import json
        from gambit_smp.framework import digest
        original = json.loads((ROOT / "evidence/scenarios/concurrent-gc/current.view.json").read_text())
        captured = json.loads((ROOT / VIEW).read_text())
        expected = {ref["id"]: ref["sha256"] for ref in original["references"]}
        for ref in captured["references"]:
            self.assertEqual(ref["sha256"], expected[ref["id"]])
            self.assertEqual(digest(ROOT / ref["path"]), ref["sha256"])
            self.assertTrue(ref["path"].startswith("evidence/source-results/view-custody/"))

    def test_flags_model_sources_and_unclosed_native_obligations(self):
        document, facts, catalog, inputs = load(ROOT, VIEW)
        self.assertGreaterEqual(len(inputs), 30)
        with engine_api() as (engine, _):
            before, first = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(before["missing_flag"], [])
            self.assertEqual(len(before["configured"]), 1)
            self.assertEqual(len(before["open"]), 8)
            self.assertEqual(len(before["model_context"]), 5)
            self.assertEqual(len(before["missing_metric"]), 6)
            withdrawn = dict(facts, flag=facts["flag"][:-1],
                source=[r for r in facts["source"] if r[0] != "RelocationEpochRoots"])
            changed, _ = evaluate(engine, withdrawn, catalog, document["queries"])
            self.assertEqual(changed["configured"], [])
            self.assertEqual(len(changed["missing_flag"]), 1)
            self.assertEqual(len(changed["model_context"]), 1)
            self.assertEqual(changed["open"], before["open"])
            restored, last = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(restored, before)
            self.assertEqual(first["sessionOwner"], last["sessionOwner"])
            self.assertGreater(last["sourceGeneration"], first["sourceGeneration"])

    def test_actual_action_discovery_selection_and_observation(self):
        catalog = research_actions.discover(ROOT, {"views": [VIEW]})
        self.assertEqual(len(catalog["actions"]), 11)
        selected = next(r for r in catalog["actions"] if r["query"] == "missing_metric")
        self.assertEqual(selected["risk"], "read-only")
        self.assertFalse(selected["explanation"]["executionAuthorized"])
        handle = str(uuid.uuid4())
        with self.assertRaisesRegex(ValueError, "host execution authorization required"):
            research_actions.select(ROOT, catalog, selected["id"], {}, handle)
        result = research_actions.select(ROOT, catalog, selected["id"], {}, handle,
                                         authorize_execution=True)
        self.assertEqual(result["result"]["outcome"], "RECORDED")
        observed = research_actions.observe(ROOT, handle)
        self.assertEqual(observed["result"]["inspection"]["status"], "CURRENT")


if __name__ == "__main__":
    unittest.main()
