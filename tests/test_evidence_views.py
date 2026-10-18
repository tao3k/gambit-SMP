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
    validation_after_domains = True

    def test_stack_entry_view_separates_current_and_historical_causality(self):
        context = json.loads((ROOT / "evidence/scenarios/stack-header/action-context.json").read_text())
        self.assertEqual(context, {"views": [
            "evidence/scenarios/stack-header/entry-preflight.view.json",
            "evidence/scenarios/stack-header/failed-paths.view.json",
            "evidence/scenarios/stack-header/causal-links.view.json",
            "evidence/scenarios/stack-header/clues.view.json",
            "evidence/scenarios/stack-header/navigation.view.json"],
            "navigator": "evidence/scenarios/stack-header/navigation.view.json"})
        snapshot = research_actions.discover(ROOT, context)
        view, failed, links, progressive, navigation = snapshot["evidenceViews"]
        self.assertEqual(navigation["answers"]["question"], [])
        self.assertIn(str(ROOT / "evidence/fixtures/darwin-stack-call-preflight-label-base/source.lock.json"),
                      progressive["inputs"])
        answers = view["answers"]
        self.assertEqual((len(answers["open"]), len(answers["observed"]),
                          len(answers["source_gap"])), (6, 6, 11))
        outcomes = {row[1] for row in answers["observed"]}
        self.assertIn("PASS_BOOTSTRAP_ONLY_STRESS_NOT_STARTED", outcomes)
        self.assertIn("DENY_NATURAL_STARTUP_GSI_EXIT_139", outcomes)
        self.assertTrue(all(not value.startswith("PASS_NATIVE") for value in outcomes))
        self.assertFalse(snapshot["runtimeAdmitted"])
        self.assertEqual(snapshot["actions"], [])
        sources = {row[0]: row for row in view["facts"]["source"]}
        self.assertNotEqual(sources["candidate-lock"][2], sources["prior-lock"][2])
        self.assertNotEqual(sources["candidate-lock"][2], sources["prior-poll-lock"][2])
        self.assertEqual(sources["prior-observation"][3], "different-historical-candidate")
        self.assertTrue(any("Different source lock" in row[5]
                            for row in answers["source_gap"]))
        self.assertTrue(any("pushes before limit comparison" in row[5]
                            for row in answers["source_gap"]))
        self.assertEqual(len(failed["answers"]["unresolved"]), 8)
        self.assertEqual(len(failed["answers"]["denied"]), 5)
        self.assertEqual(failed["answers"]["reviewable"], [])
        self.assertEqual(len(links["answers"]["shared_tag_zero_distinct_base_lock"]), 1)
        self.assertEqual(len(links["answers"]["historical_refutation"]), 2)
        self.assertEqual(len(links["answers"]["unresolved"]), 4)
        self.assertIn(("call-preflight-diagnostic",
                       "traceable-frame-chain-image-or-new-source-locked-candidate"),
                      links["answers"]["unresolved"])
        self.assertEqual([row[1] for row in links["answers"]["established_diagnostic"]],
                         ["manual-label-base-mismatch"])
        shared = links["answers"]["shared_tag_zero_distinct_base_lock"][0]
        self.assertEqual(shared[2:5], (40, 32, 0))
        self.assertIn("not-native-admission", shared[7])
        for candidate, lock_sha in failed["facts"]["candidate"]:
            failure_sha = next(sha for name, sha in failed["facts"]["failure"]
                               if name == candidate)
            source_by_sha = {sha: path for path, sha in failed["inputs"].items()}
            failure = json.loads(Path(source_by_sha[failure_sha]).read_text())
            self.assertEqual(failure.get("sourceLockSha256",
                                         failure.get("sourceLockUnderTestSha256")), lock_sha)
        document, facts, catalog, _ = load(ROOT, failed["path"])
        poll_requirements = [row[1] for row in facts["premise"]
                             if row[0] == next(sha for name, sha in facts["failure"]
                                               if name == "poll-kind")]
        model_identity = "hypothetical-checked-model"
        changed = dict(facts,
            changed=[["poll-kind", premise, "hypothetical-source-change"]
                     for premise in poll_requirements],
            checked=[["poll-kind", premise, "hypothetical-review"]
                     for premise in poll_requirements],
            model_support=[["poll-kind", premise, model_identity]
                           for premise in poll_requirements],
            model_checked=[[model_identity, "hypothetical-model-result"]],
            source_refined=[["poll-kind", premise, "hypothetical-refinement"]
                            for premise in poll_requirements])
        with engine_api() as (engine, _):
            hypothetical, _ = evaluate(engine, changed, catalog, document["queries"])
        self.assertEqual(len(hypothetical["reviewable"]), 1)
        self.assertEqual(len(hypothetical["denied"]), 4)
        from ascent import Engine
        from gambit_smp.trajectory_exploration import read_view
        with Engine() as engine:
            packet = read_view(ROOT, snapshot, view["id"], "source_gap", engine)
        self.assertEqual(packet["answers"], view["answers"]["source_gap"])
        self.assertEqual(len(packet["answers"]), 11)
        self.assertEqual(packet["sourceInputs"], {
            str(Path(path).relative_to(ROOT)): sha for path, sha in view["inputs"].items()})
        self.assertFalse(packet["executionAuthorized"])

    def test_causal_links_withdraw_when_tag_or_lock_changes(self):
        path = "evidence/scenarios/stack-header/causal-links.view.json"
        document, facts, catalog, _ = load(ROOT, path)
        with engine_api() as (engine, _):
            matched, _ = evaluate(engine, facts, catalog, document["queries"])
            changed_tag = dict(facts, probe=[
                list(row[:3]) + [6] + list(row[4:]) if row[0] == "floor-push" else row
                for row in facts["probe"]])
            unmatched, _ = evaluate(engine, changed_tag, catalog, document["queries"])
            same_lock = dict(facts, candidate=[
                [row[0], facts["candidate"][0][1], row[2]]
                if row[0] == "floor-push" else row for row in facts["candidate"]])
            conflated, _ = evaluate(engine, same_lock, catalog, document["queries"])
            forgotten = dict(facts, resolved=[])
            rediscovered, _ = evaluate(engine, forgotten, catalog, document["queries"])
        self.assertEqual(len(matched["shared_tag_zero_distinct_base_lock"]), 1)
        self.assertEqual(unmatched["shared_tag_zero_distinct_base_lock"], [])
        self.assertEqual(unmatched["historical_refutation"], [])
        self.assertEqual(conflated["shared_tag_zero_distinct_base_lock"], [])
        self.assertEqual(conflated["historical_refutation"], [])
        self.assertEqual(len(matched["unresolved"]), 4)
        self.assertEqual(rediscovered["established_diagnostic"], [])
        self.assertIn(("call-preflight-diagnostic", "manual-label-base-mismatch"),
                      rediscovered["unresolved"])

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
        from gambit_smp.artifact_storage import cache_path, database_path
        parent = cache_path(ROOT, 'tests')
        parent.mkdir(parents=True, exist_ok=True)
        scratch = tempfile.TemporaryDirectory(prefix='evidence-actions-', dir=parent)
        self.addCleanup(scratch.cleanup)
        def isolated_database(root, name, previous):
            if name == 'research-actions/requests.sqlite':
                return Path(scratch.name) / 'requests.sqlite'
            return database_path(root, name, previous)
        isolation = patch('gambit_smp.artifact_storage.database_path', side_effect=isolated_database)
        isolation.start()
        self.addCleanup(isolation.stop)
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
