"""Current Working context uses real model revisions, not fixed workflow steps."""
import json
import unittest
import uuid
from pathlib import Path
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load, registry
from gambit_smp.framework import ROOT, digest
from gambit_smp import research_actions

VIEW = "evidence/scenarios/concurrent-gc/working-modeling.view.json"


class WorkingModelingTests(unittest.TestCase):
    def test_actual_context_preserves_choice_and_stale_model_identity(self):
        context = json.loads((ROOT / "evidence/scenarios/concurrent-gc/action-context.json").read_text())
        snapshot = research_actions.discover(ROOT, context)
        btq = next(row for row in snapshot["evidenceViews"]
                   if row["path"] == "evidence/scenarios/concurrent-gc/btq-working.view.json")
        self.assertEqual(len(btq["answers"]["open"]), 3)
        self.assertTrue(all(row[1] in btq["queries"] for row in btq["answers"]["actions"]))
        view = next(row for row in snapshot["evidenceViews"] if row["path"] == VIEW)
        self.assertEqual(view["answers"]["revision_gaps"], [])
        self.assertEqual(len(view["answers"]["recommendations"]), 7)
        self.assertTrue(all(row[2] in ("extend-model", "collect-discriminating-evidence")
                            for row in view["answers"]["recommendations"]))
        self.assertEqual({row[3] for row in view["answers"]["recommendations"]},
                         {"QNT", "Lean", "source-correspondence", "source-observation"})
        action = next(row for row in snapshot["actions"] if row.get("view") == VIEW
                      and row.get("query") == "recommendations")
        self.assertEqual(action["risk"], "read-only")
        self.assertFalse(action["explanation"]["executionAuthorized"])
        request = str(uuid.uuid4())
        result = research_actions.select(ROOT, snapshot, action["id"], {}, request,
                                         authorize_execution=True)
        self.assertEqual(result["result"]["outcome"], "RECORDED")
        self.assertEqual(research_actions.observe(ROOT, request)["result"]["inspection"]["status"], "CURRENT")
        self.assertTrue(all(digest(Path(p)) == sha for p, sha in snapshot["inputs"].items()))

    def test_registered_graph_view_retains_history_and_withdraws_on_source_loss(self):
        self.assertIn(VIEW, registry(ROOT)[0])
        self.assertIn("evidence/scenarios/concurrent-gc/btq-edge-integrity.view.json", registry(ROOT)[0])
        self.assertIn("evidence/scenarios/concurrent-gc/btq-working.view.json", registry(ROOT)[0])
        document, facts, catalog, inputs = load(ROOT, VIEW)
        historical = str((ROOT / "evidence/scenarios/concurrent-gc/btq-edge-integrity.view.json").resolve())
        self.assertIn(historical, inputs)
        self.assertIn(str((ROOT / "evidence/scenarios/concurrent-gc/action-context.json").resolve()), inputs)
        self.assertEqual(json.loads((ROOT / "evidence/scenarios/concurrent-gc/action-context-fdset-history.json").read_text()),
                         {"views": ["evidence/scenarios/concurrent-gc/current.view.json"]})
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(answers["revision_gaps"], [])
            stale = dict(facts, model_revision=[["gc-chunk-cursor-operations", "old-model-sha", "chunk-review"]])
            stale_answers, _ = evaluate(engine, stale, catalog, document["queries"])
            self.assertEqual(len(stale_answers["revision_gaps"]), 4)
            self.assertIn("review-model-delta", {row[2] for row in stale_answers["recommendations"]})
            self.assertNotIn("extend-model", {row[2] for row in stale_answers["recommendations"]})
            self.assertEqual({row[3] for row in stale_answers["model_gaps"]}, {"revision-unreviewed"})
            changed = dict(facts, source=[row for row in facts["source"] if row[0] != "chunk-review"])
            answers, _ = evaluate(engine, changed, catalog, document["queries"])
            self.assertEqual(answers["revision_gaps"], [])
            self.assertEqual({row[2] for row in answers["recommendations"]}, {"collect-discriminating-evidence"})


if __name__ == "__main__":
    unittest.main()
