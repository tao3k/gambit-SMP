"""Real lifecycle inference and action transport; no native repair admission."""
import json
from pathlib import Path
import tempfile
import unittest
import uuid
from unittest.mock import patch

from gambit_smp.framework import ROOT
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load, evaluate as view_query
from gambit_smp import research_actions


VIEW = "evidence/scenarios/runtime-lifecycle/continuation-source-015.view.json"


class EvidenceViewTests(unittest.TestCase):
    def test_historical_view_and_missing_sources_remain_denied(self):
        from gambit_smp.framework import digest
        history = json.loads((ROOT / "evidence/scenarios/runtime-lifecycle/history-015.json").read_text())
        self.assertEqual(digest(ROOT / history["priorView"]), history["priorViewSha256"])
        self.assertEqual(history["outcome"], "DENY")
        self.assertEqual(len(history["missingReferences"]), 6)
        with self.assertRaisesRegex(ValueError, "regular observed artifact required"):
            load(ROOT, history["priorView"])
        document, facts, _, inputs = load(ROOT, VIEW)
        self.assertEqual(facts["satisfies"], [])
        observation = next(ref for ref in document["references"] if ref["id"] == "candidate-identity")
        observed = json.loads((ROOT / observation["path"]).read_text())
        self.assertFalse(observed["runtimeAdmitted"])
        self.assertFalse(observed["sourceRefinementAdmitted"])
        self.assertEqual(len(observed["sourceFiles"]), 958)
        self.assertIn("gsc/_gambitgsc.c", observed["unavailablePriorSeedSourcePaths"])
        self.assertIn(str(ROOT / observation["path"]), inputs)

    def test_delegated_api_boundary_checks_before_after_and_resets(self):
        from gambit_smp.ascent_program import sealed_api_boundary, _verified_api
        with tempfile.TemporaryDirectory() as directory:
            with patch("gambit_smp.research_kernel.execution_identity",
                       side_effect=[{"engineId": "first"}, {"engineId": "changed"}]) as checked:
                with self.assertRaisesRegex(ValueError, "seal changed"):
                    with sealed_api_boundary(Path(directory)):
                        self.assertIsNotNone(_verified_api.get())
                self.assertEqual(checked.call_count, 2)
                self.assertIsNone(_verified_api.get())
            with patch("gambit_smp.research_kernel.execution_identity",
                       return_value={"engineId": "first"}) as checked:
                with self.assertRaisesRegex(RuntimeError, "body failure"):
                    with sealed_api_boundary(Path(directory)):
                        raise RuntimeError("body failure")
                self.assertEqual(checked.call_count, 2)
                self.assertIsNone(_verified_api.get())

    def test_shared_qnt_import_is_bound_and_drift_rejected(self):
        from gambit_smp import review_inputs
        from gambit_smp.framework import digest
        manifest = json.loads((ROOT / review_inputs.RAW_LOG_MANIFEST).read_text())
        entry = next(row for row in manifest["receipts"] if row["model"] == "gc_work_closure")
        arguments = (ROOT, entry["model"], entry["receipt"], entry["receiptSha256"], entry)
        bound = review_inputs._checked_raw_logs(*arguments)
        shared = "models/library/gc/WorkObligations.qnt"
        self.assertEqual(bound[shared], digest(ROOT / shared))
        def changed(path):
            return "0" * 64 if path == ROOT / shared else digest(path)
        with patch.object(review_inputs, "digest", side_effect=changed):
            with self.assertRaisesRegex(ValueError, "input closure identity mismatch"):
                review_inputs._checked_raw_logs(*arguments)

    def test_three_flags_lifecycle_and_withdrawal(self):
        document, facts, catalog, inputs = load(ROOT, VIEW)
        with engine_api() as (engine, _):
            before, first = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(len(before["configured"]), 1)
            self.assertEqual(before["missing_flag"], [])
            self.assertEqual(len(before["missing"]), 10)
            self.assertEqual(len(before["missing_metric"]), 6)
            self.assertIn(("vm-destruction", "work-publication"), before["dependency_path"])
            self.assertEqual(len(before["comparison"]), 4)
            changed, _ = evaluate(engine, dict(facts, flag=facts["flag"][:-1]), catalog, document["queries"])
            self.assertEqual(changed["configured"], [])
            self.assertEqual(len(changed["missing_flag"]), 1)
            restored, last = evaluate(engine, facts, catalog, document["queries"])
            self.assertEqual(before, restored)
            self.assertEqual(first["sessionOwner"], last["sessionOwner"])
            self.assertGreater(last["sourceGeneration"], first["sourceGeneration"])
        self.assertGreater(len(inputs), 950)

    def test_real_actions_select_and_observe(self):
        context = {"views": [VIEW]}
        first = research_actions.discover(ROOT, context)
        repeated = research_actions.discover(ROOT, context)
        self.assertEqual(first["revision"], repeated["revision"])
        initial_owner = next(iter(first["viewExplanations"].values()))["sessionOwner"]
        reused_owner = next(iter(repeated["viewExplanations"].values()))["sessionOwner"]
        self.assertEqual(initial_owner, reused_owner)
        self.assertEqual(len(first["actions"]), 14)
        chosen = next(row for row in first["actions"] if row["query"] == "missing_metric")
        self.assertEqual(chosen["risk"], "read-only")
        self.assertFalse(chosen["explanation"]["executionAuthorized"])
        handle = str(uuid.uuid4())
        result = research_actions.select(ROOT, first, chosen["id"], {}, handle, authorize_execution=True)
        self.assertEqual(result["result"]["outcome"], "RECORDED")
        observation = research_actions.observe(ROOT, handle)
        self.assertEqual(observation["result"]["inspection"]["status"], "CURRENT")
        receipt = json.loads(Path(result["result"]["receipt"]).read_text())
        self.assertEqual(len(receipt["answers"]), 6)
        self.assertFalse(receipt["runtimeAdmitted"])

    def test_digest_failure_precedes_inference(self):
        document = json.loads((ROOT / VIEW).read_text())
        document["references"][0]["sha256"] = "0" * 64
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", dir=ROOT / "evidence") as file:
            json.dump(document, file)
            file.flush()
            with self.assertRaisesRegex(ValueError, "reference changed"):
                load(ROOT, str(Path(file.name).relative_to(ROOT)))


if __name__ == "__main__":
    unittest.main()
