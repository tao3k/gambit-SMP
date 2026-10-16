"""Real ASCENT prerequisite inference; transport fault tests do not admit runs."""
import json
import contextlib
import io
from pathlib import Path
import tempfile
import threading
import sys
import unittest
import uuid
from unittest.mock import patch

from gambit_smp import research_actions as actions
from gambit_smp.ascent_program import engine_api, evaluate, load_evidence_catalog
from gambit_smp.framework import ROOT


class ActionInferenceTests(unittest.TestCase):
    def test_scheme_generates_and_withdraws_the_study_action_catalog(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/actions.ss",
                                       constructor="make-actions", trusted=True)
        facts = {"StudyDeclaration": [["incident", "study.json"]],
                 "StudyHypothesis": [["incident", "none"]],
                 "SnapshotIdentity": [["snapshot"]]}
        queries = {"actions": "StudyActionSpec", "expected": "StudyExpected", "ready": "Eligible"}
        with engine_api() as (engine, _):
            first, before = evaluate(engine, facts, catalog, queries)
            withdrawn, _ = evaluate(engine, dict(facts, StudyDeclaration=[]), catalog, queries)
            restored, after = evaluate(engine, facts, catalog, queries)
        self.assertEqual(4, len(first["actions"]))
        self.assertEqual({"inspect-study", "trace-source", "dynamic-origin", "design-experiment"},
                         {row[1] for row in first["actions"]})
        self.assertEqual([( "study:incident:inspect",), ("study:incident:none:design",)], first["ready"])
        self.assertEqual({"actions": [], "expected": [], "ready": []}, withdrawn)
        self.assertEqual(first, restored)
        self.assertEqual(before["sessionOwner"], after["sessionOwner"])
        self.assertGreater(after["sourceGeneration"], before["sourceGeneration"])

    def test_duplicate_study_ids_are_rejected_before_native_set_deduplication(self):
        with self.assertRaisesRegex(ValueError, "duplicate study identity"):
            actions.discover(ROOT, {"studies": ["evidence/scenarios/sigbus-origin/study.json"] * 2})

    def test_receipt_observation_changes_real_menu_without_establishing_root_cause(self):
        from gambit_smp.framework import digest
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            study = json.loads((ROOT / "evidence/scenarios/sigbus-origin/study.json").read_text())
            # A test study asks for a field actually present in the original
            # SIGBUS receipt, not a fabricated allocation measurement.
            study["hypotheses"][0]["predictions"][0]["observation"] = "compiler-exit"
            for name in {ref["path"] for ref in study["references"]} | {
                    study["sourceTrace"]["path"], "evidence/dsl/actions.ss", "evidence/native-failures.json"}:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes((ROOT / name).read_bytes())
            target = root / "study.json"
            target.write_text(json.dumps(study))
            original = next(ref for ref in study["references"] if ref["id"] == "compiler-exit")
            original = {key: value for key, value in original.items() if key != "id"}
            record = {"schema": "research-observation.v1", "study": study["id"],
                      "observation": "compiler-exit", "sourceSha256": next(
                          row["value"] for row in actions._study(root, "study.json")[2]
                          if row["id"] == "candidate-mem"), "receipt": original, "value": -10}
            observed = root / "observation.json"
            observed.write_text(json.dumps({"observations": [record]}))
            context = {"studies": ["study.json"], "observations": [{
                "path": "observation.json", "sha256": digest(observed), "pointer": "/observations/0"}]}
            state = actions.discover(root, context)
            self.assertEqual(2, len(state["research"]["openPredictions"]))
            self.assertEqual(1, len(state["research"]["recordedObservations"]))
            self.assertFalse(state["research"]["causalEstablished"])
            self.assertFalse(state["research"]["coverageEstablished"])
            record["sourceSha256"] = "unrelated"
            observed.write_text(json.dumps({"observations": [record]}))
            context["observations"][0]["sha256"] = digest(observed)
            with self.assertRaisesRegex(ValueError, "source identity mismatch"):
                actions.discover(root, context)

    def test_real_why_not_tracks_exact_reference_withdrawal(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/actions.ss", constructor="make-actions", trusted=True)
        facts = {"DeclaredAction": [["inspect"], ["run"]], "DeclaredRequires": [["run", "review"]],
                 "PremiseDepends": [["review", "source"]], "DeclaredSatisfied": [["review"]],
                 "PremiseEvidence": [["review", "ref"]],
                 "EvidenceReference": [["ref", "receipt.json", "sha", "/results/0"]]}
        queries = {"supported": "Supported", "missing": "Missing", "gaps": "ExplanationGap", "reused": "ReusedEvidence"}
        with engine_api() as (engine, _):
            bound, _ = evaluate(engine, facts, catalog, queries)
            withdrawn, _ = evaluate(engine, dict(facts, EvidenceReference=[]), catalog, queries)
            restored, _ = evaluate(engine, facts, catalog, queries)
        self.assertEqual(bound["supported"], [("run", "review", "ref")])
        self.assertEqual(bound["missing"], [("run", "source")])
        self.assertEqual(withdrawn["supported"], [])
        self.assertEqual(withdrawn["reused"], [])
        self.assertEqual(withdrawn["gaps"], [("run", "review")])
        self.assertEqual(restored, bound)

    def test_actual_sigbus_explanations_bind_original_receipts_and_source(self):
        state = actions.discover(ROOT, {"studies": ["evidence/scenarios/sigbus-origin/study.json"]})
        trace = next(row for row in state["actions"] if row["operation"] == "trace-source")
        explanation = trace["explanation"]
        self.assertEqual([], explanation["unboundPremises"])
        self.assertTrue(explanation["supportedPremises"])
        from gambit_smp.framework import digest
        for ref in explanation["reusedEvidence"]:
            self.assertEqual(ref["sha256"], digest(Path(ref["path"])))
        self.assertTrue(any(ref["pointer"] for ref in explanation["reusedEvidence"]))
        self.assertFalse(explanation["executionAuthorized"])
        self.assertFalse(explanation["causalEstablished"])
        self.assertEqual([-10], [row["exit"] for row in explanation["existingFailedEvidence"]])
        self.assertEqual("/native/compile/exit", explanation["existingFailedEvidence"][0]["reference"]["pointer"])
        dynamic = next(row for row in state["actions"] if row["operation"] == "dynamic-origin")
        self.assertIn("capability:source.reference-origin", dynamic["explanation"]["missingPremises"])

    def test_catalog_denial_does_not_hide_bound_read_only_inquiry(self):
        with patch("gambit_smp.ascent_review.collect", side_effect=ValueError("stale inventory")):
            state = actions.discover(ROOT, {"studies": ["evidence/scenarios/sigbus-origin/study.json"],
                                            "graph": {"model": "gc_recursive_queue_wait"}})
        graph = next(row for row in state["actions"] if row["operation"] == "current-graph")
        self.assertIn("current-catalog", graph["blockers"])
        self.assertEqual(graph["budgetSeconds"], 300)
        self.assertIn("stale inventory", str(graph["blockingEvidence"]))
        inspect = next(row for row in state["actions"] if row["operation"] == "inspect-study")
        self.assertEqual(inspect["eligibility"], "PREFLIGHT_READY")

    def test_transitive_missing_premise_blocks_execution_not_investigation(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/actions.ss", constructor="make-actions", trusted=True)
        facts = {"DeclaredAction": [["inspect"], ["execute"]], "DeclaredRequires": [["execute", "review"]],
                 "PremiseDepends": [["review", "source"], ["source", "exact-bytes"]],
                 "DeclaredSatisfied": [["review"], ["source"]]}
        with engine_api() as (engine, _):
            rows, _ = evaluate(engine, facts, catalog, {"ready": "Eligible", "blocked": "Blocked"})
        self.assertEqual(rows["ready"], [("inspect",)])
        self.assertEqual(rows["blocked"], [("execute", "exact-bytes")])

    def test_real_incident_discovery_keeps_predictions_and_dynamic_trace_gap_separate(self):
        state = actions.discover(ROOT, {"studies": ["evidence/scenarios/sigbus-origin/study.json"]})
        self.assertEqual(len(state["research"]["openPredictions"]), 3)
        self.assertEqual(len(state["research"]["discriminators"]), 2)
        trace = next(row for row in state["actions"] if row["operation"] == "trace-source")
        self.assertEqual(trace["eligibility"], "PREFLIGHT_READY")
        self.assertTrue(all(row["eligibility"] == "PREFLIGHT_READY" for row in state["actions"] if row["operation"] in ("inspect-study", "design-experiment")))
        dynamic = next(row for row in state["actions"] if row["operation"] == "dynamic-origin")
        self.assertIn("capability:source.reference-origin", dynamic["blockers"])
        self.assertFalse(state["research"]["causalEstablished"])

    def test_real_prediction_withdrawal_does_not_prove_hypothesis(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/actions.ss", constructor="make-actions", trusted=True)
        facts = {"Hypothesis": [["h"]], "Prediction": [["h", "field", "outside"]], "Observation": [],
                 "ObservationEvidence": [["field", "ref"]],
                 "EvidenceReference": [["ref", "observation.json", "sha", "/results/0"]]}
        with engine_api() as (engine, _):
            missing, _ = evaluate(engine, facts, catalog, {"open": "OpenPrediction"})
            observed, _ = evaluate(engine, dict(facts, Observation=[["field"]]), catalog, {"open": "OpenPrediction"})
            unbound, _ = evaluate(engine, dict(facts, Observation=[["field"]], EvidenceReference=[]), catalog, {"open": "OpenPrediction"})
            restored, _ = evaluate(engine, facts, catalog, {"open": "OpenPrediction"})
        self.assertEqual(missing["open"], [("h", "field", "outside")])
        self.assertEqual(observed["open"], [])
        self.assertEqual(unbound, missing)
        self.assertEqual(restored, missing)
        # No accepted/causal relation is inferred by presence of an observation.

    def test_incident_pointer_correspondence_and_sha_fail_closed(self):
        from gambit_smp.framework import digest
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            study = json.loads((ROOT / "evidence/scenarios/sigbus-origin/study.json").read_text())
            for name in {ref["path"] for ref in study["references"]}:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes((ROOT / name).read_bytes())
            source = root / study["sourceTrace"]["path"]
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_bytes((ROOT / study["sourceTrace"]["path"]).read_bytes())
            target = root / "study.json"
            target.write_text(json.dumps(study))
            actions._study(root, "study.json")
            document = root / study["references"][1]["path"]
            value = json.loads(document.read_text())
            value["native"]["compile"]["process"]["pid"] += 1
            document.write_text(json.dumps(value))
            with self.assertRaisesRegex(ValueError, "digest"):
                actions._study(root, "study.json")
            for ref in study["references"]:
                if ref["path"] == study["references"][1]["path"]:
                    ref["sha256"] = digest(document)
            target.write_text(json.dumps(study))
            with self.assertRaisesRegex(ValueError, "correspondence"):
                actions._study(root, "study.json")

    def test_real_recipe_discovery_without_seal_is_blocked(self):
        context = {"recipes": ["evidence/research/source-schedule-revalidation/control.recipe.json"]}
        first = actions.discover(ROOT, context)
        second = actions.discover(ROOT, context)
        self.assertEqual(first["revision"], second["revision"])
        self.assertEqual(first["actions"][0]["eligibility"], "BLOCKED")
        self.assertIn("sealed-engine", first["actions"][0]["blockers"])
        self.assertEqual(first["actions"][0]["budgetSeconds"], 90)
        self.assertFalse(first["executionAuthorized"])

    def test_real_dsl_withdrawal_and_restore(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/actions.ss",
                                       constructor="make-actions", trusted=True)
        facts = {"DeclaredAction": [["run"]], "DeclaredRequires": [["run", "seal"], ["run", "source"]],
                 "DeclaredSatisfied": [["seal"], ["source"]]}
        with engine_api() as (engine, _):
            ready, first = evaluate(engine, facts, catalog, {"ready": "Eligible", "blocked": "Blocked"})
            blocked, second = evaluate(engine, dict(facts, DeclaredSatisfied=[["source"]]), catalog,
                                       {"ready": "Eligible", "blocked": "Blocked"})
            restored, third = evaluate(engine, facts, catalog, {"ready": "Eligible", "blocked": "Blocked"})
        self.assertEqual(ready["ready"], [("run",)])
        self.assertEqual(blocked["ready"], [])
        self.assertEqual(blocked["blocked"], [("run", "seal")])
        self.assertEqual(restored, ready)
        self.assertGreater(third["sourceGeneration"], second["sourceGeneration"])
        self.assertEqual(first["sessionOwner"], third["sessionOwner"])

    def test_real_dsl_unchanged_failure_is_not_retry_authorization(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/actions.ss",
                                       constructor="make-actions", trusted=True)
        facts = {"DeclaredAction": [["run"]], "DeclaredCurrent": [["run", "bytes"]],
                 "RecordedOutcome": [["run", "bytes", "DENY"]]}
        with engine_api() as (engine, _):
            blocked, _ = evaluate(engine, facts, catalog, {"ready": "Eligible", "blocked": "Blocked"})
            changed, _ = evaluate(engine, dict(facts, DeclaredCurrent=[["run", "new-bytes"]]), catalog,
                                  {"ready": "Eligible", "blocked": "Blocked"})
        self.assertEqual(blocked["blocked"], [("run", "unchanged-failed-action")])
        self.assertEqual(blocked["ready"], [])
        self.assertEqual(changed["ready"], [("run",)])
        # This is preliminary eligibility only, never causal review or authorization.

    def test_study_source_policy_is_derived_and_retracted_in_scheme(self):
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/actions.ss",
                                       constructor="make-actions", trusted=True)
        facts = {"DeclaredAction": [["inspect"], ["trace"], ["dynamic"]],
                 "DeclaredKind": [["inspect", "inspect-study"], ["trace", "trace-source"],
                                ["dynamic", "dynamic-origin"]],
                 "DeclaredStudyMember": [["s", "inspect"], ["s", "trace"], ["s", "dynamic"]],
                 "DeclaredSourcePremise": [["s", "exact-source"]],
                 "StudySourceBinding": [["s", "ref"]],
                 "EvidenceReference": [["ref", "source.c", "sha", ""]]}
        queries = {"ready": "Eligible", "needs": "Need", "supported": "Supported", "gaps": "ActionGap"}
        with engine_api() as (engine, _):
            first, before = evaluate(engine, facts, catalog, queries)
            withdrawn, _ = evaluate(engine, dict(facts, EvidenceReference=[]), catalog, queries)
            foreign, _ = evaluate(engine, dict(facts, StudySourceBinding=[["other-study", "ref"]]), catalog, queries)
            restored, after = evaluate(engine, facts, catalog, queries)
        self.assertEqual([("inspect",), ("trace",)], first["ready"])
        self.assertEqual([("dynamic", "capability:source.reference-origin"),
                          ("dynamic", "exact-source"), ("trace", "exact-source")], first["needs"])
        self.assertEqual([("inspect",)], withdrawn["ready"])
        self.assertEqual(withdrawn, foreign)
        self.assertEqual(first, restored)
        self.assertEqual(before["sessionOwner"], after["sessionOwner"])
        self.assertGreater(after["sourceGeneration"], before["sourceGeneration"])
        self.assertEqual([], withdrawn["supported"])
        self.assertEqual(["dynamic"], [row[0] for row in first["gaps"]])


class ActionTransportTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.snapshot = {"revision": "rev", "sourceIdentity": "source", "context": {"engine": "/unused", "recipes": ["one"]},
                         "inputs": {}, "backend": {}, "recordedOutcomes": [],
                         "actions": [{"id": "run", "recipe": "one",
                                  "eligibility": "PREFLIGHT_READY"}]}
        self.request = str(uuid.uuid4())

    def select(self, **kwargs):
        return actions.select(self.root, self.snapshot, "run", {}, self.request, **kwargs)

    def test_no_authorization_never_launches(self):
        with patch.object(actions, "discover", return_value=self.snapshot), \
                patch("gambit_smp.research_kernel.run_sealed") as run:
            with self.assertRaisesRegex(ValueError, "authorization"):
                self.select()
            run.assert_not_called()

    def test_stale_revision_never_launches(self):
        with patch.object(actions, "discover", return_value=dict(self.snapshot, revision="new")), \
                patch("gambit_smp.research_kernel.run_sealed") as run:
            with self.assertRaisesRegex(ValueError, "STALE"):
                self.select(authorize_execution=True)
            run.assert_not_called()

    def test_backend_logical_names_resolve_through_artifact_inventory(self):
        artifact = self.root / "library"
        artifact.write_bytes(b"actual-library")
        from gambit_smp.framework import digest
        self.snapshot["backend"] = {"extension": digest(artifact)}
        with patch.object(actions, "discover", return_value=self.snapshot), \
                patch("gambit_smp.ascent_program.artifact_paths", return_value={"extension": artifact}), \
                patch("gambit_smp.research_kernel.run_sealed", side_effect=RuntimeError("launched")) as run:
            with self.assertRaisesRegex(RuntimeError, "launched"):
                self.select(authorize_execution=True)
            run.assert_called_once()

    def test_failed_request_retained_and_duplicate_does_not_relaunch(self):
        with patch.object(actions, "discover", return_value=self.snapshot), \
                patch("gambit_smp.research_kernel.run_sealed", side_effect=RuntimeError("failure")) as run:
            with self.assertRaisesRegex(RuntimeError, "failure"):
                self.select(authorize_execution=True)
            result = self.select(authorize_execution=True)
            self.assertEqual(result["result"]["status"], "FAILED")
            self.assertFalse(result["runtimeAdmitted"])
            run.assert_called_once()
        with self.assertRaisesRegex(ValueError, "different content"):
            self.select()

    def test_interrupted_request_is_not_a_running_or_success_claim(self):
        body = {"revision": "rev", "action": "run", "inputs": {},
                "authorization": True, "sourceIdentity": "source", "context": self.snapshot["context"]}
        db = actions._database(self.root)
        db.execute("INSERT INTO requests VALUES (?, ?, NULL)", (self.request, json.dumps(body, sort_keys=True)))
        db.commit()
        db.close()
        with patch("gambit_smp.research_kernel.run_sealed") as run:
            result = self.select(authorize_execution=True)
            self.assertEqual(result["result"]["status"], "PENDING_OR_INTERRUPTED")
            run.assert_not_called()

    def test_unexpected_inputs_are_not_runner_arguments(self):
        with self.assertRaises(ValueError):
            actions.select(self.root, self.snapshot, "run", {"argv": ["sh"]}, self.request,
                           authorize_execution=True)

    def test_cli_selection_propagates_kernel_denial(self):
        path = self.root / "request.json"
        path.write_text(json.dumps({"snapshot": self.snapshot, "action": "run", "inputs": {},
                                    "requestId": self.request}))
        with patch.object(sys, "argv", ["actions", "select", "--request", str(path)]), \
                patch.object(actions, "select", return_value={"result": {"outcome": "DENY"}}), \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(actions.main(), 2)

    def test_concurrent_duplicate_observes_reserved_request_without_second_launch(self):
        entered, release = threading.Event(), threading.Event()
        errors = []
        def running(*args, **kwargs):
            entered.set()
            if not release.wait(3):
                raise RuntimeError("test coordination timeout")
            raise RuntimeError("retained failure")
        def first_request():
            try:
                self.select(authorize_execution=True)
            except RuntimeError as error:
                errors.append(str(error))
        with patch.object(actions, "discover", return_value=self.snapshot), \
                patch("gambit_smp.research_kernel.run_sealed", side_effect=running) as run:
            thread = threading.Thread(target=first_request)
            thread.start()
            try:
                self.assertTrue(entered.wait(3))
                duplicate = self.select(authorize_execution=True)
                self.assertEqual(duplicate["result"]["status"], "PENDING_OR_INTERRUPTED")
            finally:
                release.set()
                thread.join(3)
            self.assertFalse(thread.is_alive())
            run.assert_called_once()
            self.assertEqual(errors, ["retained failure"])


if __name__ == "__main__":
    unittest.main()
