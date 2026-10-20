"""Real DSL inference and Action transport, not proof or native admission."""
import unittest
from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT
from gambit_smp import research_actions

VIEW = "evidence/scenarios/concurrent-gc/modeling-024.view.json"


class ModelingGuidanceTests(unittest.TestCase):
    def test_current_collective_candidate_keeps_native_gap_and_report_review_distinct(self):
        path = "evidence/scenarios/concurrent-gc/processor-interrupt-collective.view.json"
        _, facts, catalog, _ = load(ROOT, path)
        with engine_api() as (engine, _):
            state, _ = evaluate(engine, facts, catalog,
                                {name: name for name in ("applicable", "unclosed", "clue", "factor")})
        self.assertIn(("collective-native-report-review", "collective-report-reviewed"), state["applicable"])
        self.assertIn(("collective-interpreted-qualification",), state["unclosed"])
        self.assertFalse(any(row[1] == "collective-original-gsi" for row in state["applicable"]))
        from gambit_smp.trajectory_exploration import repository_clues
        bindings = [["entity", "tfib"], ["requirement", "collective-interpreted-qualification"]]
        packet = repository_clues(ROOT, bindings=bindings)
        self.assertIn("collective-interpreted-qualification",
                      {row["claim"] for row in packet["brief"]["families"]})
        self.assertFalse(packet["brief"]["runtimeAdmitted"])
        resumed = repository_clues(ROOT, bindings=bindings, checkpoint=packet["checkpoint"])
        self.assertEqual(resumed["brief"]["families"], [])
        self.assertTrue(resumed["brief"]["explorationOpen"])

    def scope_fixture(self):
        _, _, catalog, _ = load(ROOT, VIEW)
        facts = {
            "focus": [["candidate", "candidate-source", "candidate-sha"]],
            "source": [["candidate-source", "candidate", "candidate-sha"],
                       ["proposal-source", "proposal", "proposal-v1"],
                       ["model-source", "model", "model-v1"],
                       ["assumption-source", "assumptions", "assumptions-v1"],
                       ["checked", "model-check", "check-v1"],
                       ["review", "scope-review", "review-v1"]],
            "proposal": [["candidate", "inline-observer", "proposal-source"]],
            "proposal_change": [["candidate", "inline-observer", "snapshot", "slot-version",
                                 "version-source", "per-slot"]],
            "model": [["snapshot", "model-source"]],
            "model_revision": [["snapshot", "model-v1", "checked"]],
            "model_assumption": [["snapshot", "version-source", "global", "assumption-source"]],
            "scope_review": [],
        }
        queries = {name: name for name in ("applicability_gaps", "assumption_deltas",
                    "current_scope_review", "clue", "factor", "link")}
        return facts, catalog, queries

    def test_unchanged_model_pass_does_not_cover_changed_mechanism(self):
        facts, catalog, queries = self.scope_fixture()
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, queries)
        self.assertEqual(len(answers["applicability_gaps"]), 1)
        self.assertEqual(len(answers["assumption_deltas"]), 1)
        self.assertEqual(answers["current_scope_review"], [])
        self.assertEqual(answers["clue"][0][2:5],
                         ("slot-version", "counter", "observation"))
        self.assertIn(("slot-version", "proposal-v1", "expected-value", "global"),
                      answers["factor"])

    def test_scope_review_is_bound_to_model_proposal_and_assumption_bytes(self):
        facts, catalog, queries = self.scope_fixture()
        facts["model_assumption"][0][2] = "per-slot"
        facts["scope_review"] = [["candidate", "inline-observer", "snapshot", "version-source",
            "per-slot", "model-v1", "proposal-v1", "assumptions-v1", "review"]]
        with engine_api() as (engine, _):
            matched, _ = evaluate(engine, facts, catalog, queries)
            self.assertEqual(matched["applicability_gaps"], [])
            self.assertEqual(matched["clue"], [])
            self.assertEqual(len(matched["current_scope_review"]), 1)
            for identity in ("model-source", "proposal-source", "assumption-source"):
                with self.subTest(identity=identity):
                    changed = dict(facts, source=[
                        [sid, path, sha + "-changed" if sid == identity else sha]
                        for sid, path, sha in facts["source"]])
                    result, _ = evaluate(engine, changed, catalog, queries)
                    self.assertEqual(result["current_scope_review"], [])
                    self.assertEqual(len(result["applicability_gaps"]), 1)
            withdrawn = dict(facts, source=[r for r in facts["source"] if r[0] != "review"])
            result, _ = evaluate(engine, withdrawn, catalog, queries)
            self.assertEqual(result["current_scope_review"], [])
            self.assertEqual(len(result["applicability_gaps"]), 1)

    def test_missing_dimensions_and_unknown_models_remain_visible(self):
        facts, catalog, queries = self.scope_fixture()
        facts["proposal_change"].append(["candidate", "inline-observer", "unmapped-model",
            "owner-stack", "owner-identity", "stack-overlap"])
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, queries)
        self.assertEqual(len(answers["applicability_gaps"]), 2)
        self.assertEqual({r[0] for r in answers["clue"]}, {"slot-version", "owner-stack"})
        self.assertNotIn(("owner-stack", "proposal-v1", "dimension", "version-source"),
                         answers["factor"])

    def test_bound_model_review_reaches_the_existing_proposal_exchange(self):
        facts, catalog, queries = self.scope_fixture()
        facts["assessment"] = [["candidate", "ownership-review", "snapshot", "insufficient", "review"]]
        with engine_api() as (engine, _):
            answers, _ = evaluate(engine, facts, catalog, queries)
            self.assertIn(("ownership-review", "review-v1", "ownership-review",
                           "counter", "observation", "scope-review"), answers["clue"])
            self.assertIn(("ownership-review", "review-v1", "proposal", "inline-observer"),
                          answers["factor"])
            self.assertIn(("ownership-review", "review-v1", "status", "insufficient"),
                          answers["factor"])
            facts["source"] = [row for row in facts["source"] if row[0] != "review"]
            withdrawn, _ = evaluate(engine, facts, catalog, queries)
        self.assertFalse(any(row[0] == "ownership-review" for row in withdrawn["clue"]))

    def test_actual_ticket_proposal_returns_gaps_and_resumes_without_repeating(self):
        from gambit_smp.trajectory_exploration import repository_clues
        bindings = [["proposal", "low-perturbation-ticket-observer"]]
        expected = {"ticket-observer-slot-version", "ticket-observer-owner-identity",
                    "ticket-observer-barrier-election", "ticket-observer-observation-effect",
                    "ticket-observer-record-expiry"}
        packet = repository_clues(ROOT, bindings=bindings)
        self.assertTrue(packet["brief"]["families"])
        seen = set()
        while True:
            self.assertFalse(packet["brief"]["runtimeAdmitted"])
            self.assertFalse(packet["brief"]["executionAuthorized"])
            self.assertTrue(packet["brief"]["explorationOpen"])
            for family in packet["brief"]["families"]:
                self.assertIn(family["claim"], expected)
                self.assertNotIn(family["claim"], seen)
                seen.add(family["claim"])
                self.assertTrue(all(row["polarity"] == "counter"
                                    for row in family["observations"]))
            if packet["brief"]["presentationComplete"]:
                break
            self.assertTrue(packet["brief"]["families"])
            packet = repository_clues(ROOT, bindings=bindings, checkpoint=packet["checkpoint"])
        self.assertEqual(seen, expected)
        again = repository_clues(ROOT, bindings=bindings, checkpoint=packet["checkpoint"])
        self.assertEqual(again["brief"]["families"], [])
        self.assertEqual(again["brief"]["delta"]["added"], 0)

    def test_withdrawn_owner_rule_is_not_recovered_as_a_current_proposal(self):
        from gambit_smp.trajectory_exploration import repository_clues
        proposal = ["proposal", "offpath-serving-ticket-witness"]
        rejected = "unique-residual-slot-equals-stable-serving-word"
        old = repository_clues(ROOT, bindings=[proposal, ["proposed-value", rejected]])
        self.assertEqual(old["brief"]["families"], [])
        self.assertIn(["proposed-value", rejected],
                      old["brief"]["association"]["unknown_binding"])
        current = repository_clues(ROOT, checkpoint=old["checkpoint"], bindings=[proposal,
            ["proposed-value", "residual-word-equality-is-not-acquisition-provenance"]])
        owner = next(row for row in current["brief"]["families"]
                     if row["claim"] == "offpath-witness-owner-identity")
        self.assertTrue(any(rejected in row["factors"].get("expected-value", [])
                            for row in owner["observations"]))
        self.assertFalse(current["brief"]["runtimeAdmitted"])
        self.assertTrue(current["brief"]["explorationOpen"])

    def test_real_native_goal_exposes_dependency_gaps_without_promoting_model_results(self):
        from gambit_smp.trajectory_exploration import repository_clues
        anchored = repository_clues(ROOT, bindings=[["entity", "ticket-lock"]])
        self.assertIn("actual-owner-paths",
                      {row["claim"] for row in anchored["brief"]["families"]})
        self.assertFalse(anchored["brief"]["runtimeAdmitted"])
        request = [["goal", "native-lock-wait-resolution"]]
        packet = repository_clues(ROOT, bindings=request)
        families = []
        while True:
            self.assertFalse(packet["brief"]["executionAuthorized"])
            self.assertFalse(packet["brief"]["runtimeAdmitted"])
            self.assertTrue(packet["brief"]["explorationOpen"])
            families.extend(packet["brief"]["families"])
            if packet["brief"]["presentationComplete"]:
                break
            packet = repository_clues(ROOT, bindings=request, checkpoint=packet["checkpoint"])
        self.assertEqual(len({row["claim"] for row in families}), 8)
        model = next(row for row in families if row["claim"] == "record-model-evidence")
        self.assertEqual({row["polarity"] for row in model["observations"]}, {"support"})
        goal = next(row for row in families if row["claim"] == "native-lock-wait-resolution")
        self.assertTrue(all(row["polarity"] == "counter" for row in goal["observations"]))
        self.assertTrue(any("unclosed" in row["factors"]["evidence-state"]
                            for row in goal["observations"]))
        resumed = repository_clues(ROOT, bindings=request, checkpoint=packet["checkpoint"])
        self.assertEqual(resumed["brief"]["families"], [])
        self.assertTrue(resumed["brief"]["presentationComplete"])
        # Reading every item has not changed the source-derived native gap.
        _, facts, catalog, _ = load(ROOT, "evidence/scenarios/concurrent-gc/ticket-model-scope.view.json")
        self.assertEqual({parent for requirement, parent in facts["dependency"]
                          if requirement == "source-repair"},
                         {"ownership-source-coverage", "lock-collective-progress"})
        with engine_api() as (engine, _):
            state, _ = evaluate(engine, facts, catalog, {"unclosed": "unclosed"})
        self.assertIn(("native-lock-wait-resolution",), state["unclosed"])

        import json
        from gambit_smp.task_processes import run
        import sys
        import os
        for seed in ("1", "2"):
            child = run([sys.executable, "-c",
                "import json,sys; from gambit_smp import repository_clues; "
                "print(json.dumps(repository_clues(bindings=[['goal','native-lock-wait-resolution']], checkpoint=sys.argv[1])))",
                packet["checkpoint"]], cwd=ROOT, capture_output=True, text=True,
                env={**os.environ, "PYTHONHASHSEED": seed}, timeout=30, check=False)
            self.assertEqual(child.returncode, 0, child.stderr)
            fresh = json.loads(child.stdout)
            self.assertEqual(fresh["brief"]["mode"], "incremental")
            self.assertEqual(fresh["brief"]["families"], [])
            self.assertFalse(fresh["brief"]["runtimeAdmitted"])

    def test_component_transport_preserves_registered_source_order(self):
        _, _, catalog, _ = load(ROOT, "evidence/scenarios/concurrent-gc/ticket-model-scope.view.json")
        self.assertEqual(list(catalog["nativeComponents"]["sources"]),
                         ["package:ascent/checkpoint_rules.ss", "modeling-guidance.ss"])

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
