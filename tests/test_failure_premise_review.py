"""Use the real Scheme DSL/ASCENT review without granting native execution."""
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_catalog
from gambit_smp.evidence_capabilities import facts as execution_facts
from gambit_smp.evidence_views import load
from gambit_smp.framework import ROOT
from gambit_smp import research_actions

VIEW = "evidence/scenarios/concurrent-gc/btq-retry-review.view.json"


class FailurePremiseReviewTests(unittest.TestCase):
    def test_current_producer_retires_accounting_history_without_erasing_native_failure(self):
        receipt_sha = "a" * 64
        receipt = {"steps": [
            {"id": "producer", "capability": "gambit.completed-runtime", "outcome": "PASS",
             "arguments": {}, "dependsOn": [], "producerDecisionSupersession": {
                 "historicalReceiptSha256": receipt_sha, "recordedOutcome": "DENY",
                 "historicalDecision": "expired-total-wall-clock-owner-teardown",
                 "currentDecision": "completed-stages-and-reaped-owner"}},
            {"id": "stress", "capability": "gambit.suite", "outcome": "PASS",
             "arguments": {}, "dependsOn": ["producer"]}]}
        catalog = load_catalog(ROOT / "evidence/research/execution-rules.ss",
                               ROOT / "evidence/research/producer-decision-rules.ss")
        queries = {"retired": "retired_producer_decision", "active": "active_historical_producer_denial",
                   "current": "current_producer_admitted", "missing": "missing_step"}
        with engine_api() as (engine, _):
            answer = evaluate(engine, execution_facts(receipt), catalog, queries)[0]
            self.assertEqual([("producer", receipt_sha)], answer["retired"])
            self.assertEqual([], answer["active"])
            self.assertEqual([("producer",)], answer["current"])
            self.assertEqual([], answer["missing"])
            receipt["steps"][1]["outcome"] = "DENY"
            failed = evaluate(engine, execution_facts(receipt), catalog, queries)[0]
            self.assertEqual(answer["retired"], failed["retired"])
            self.assertEqual([("stress",)], failed["missing"])
            invalid = execution_facts(receipt)
            invalid["producer_decision_supersedes"] = []
            incomplete = evaluate(engine, invalid, catalog, queries)[0]
            self.assertEqual([], incomplete["current"])
            self.assertEqual([("producer", receipt_sha)], incomplete["active"])
            unrelated = execution_facts(receipt)
            unrelated["producer_decision_current"] = [("producer", "b" * 64, "PASS")]
            mismatched = evaluate(engine, unrelated, catalog, queries)[0]
            self.assertEqual([], mismatched["retired"])
            self.assertEqual([], mismatched["current"])
            self.assertEqual([("producer", receipt_sha)], mismatched["active"])
            self.assertEqual([("stress",)], mismatched["missing"])

    def review(self, mutate=lambda facts: facts):
        document, facts, catalog, _ = load(ROOT, VIEW)
        with engine_api() as (engine, _):
            return evaluate(engine, mutate(facts), catalog, document["queries"])[0]

    def test_current_model_pass_does_not_admit_unchanged_native_retry(self):
        answer = self.review()
        self.assertTrue(answer["denied"])
        self.assertTrue(answer["unresolved"])
        self.assertFalse(answer["reviewable"])

    def test_missing_failure_classification_fails_closed(self):
        answer = self.review(lambda f: dict(f, premise=[]))
        self.assertTrue(answer["missing"])
        self.assertTrue(answer["denied"])
        self.assertFalse(answer["reviewable"])

    def test_identifiers_are_opaque_and_not_ordered_candidate_numbers(self):
        expected = self.review()
        for name in ("source-001", "source-999", "semantic-repair"):
            def mutate(f):
                result = dict(f)
                for relation in ("candidate", "failure", "changed", "checked", "model_support", "source_refined"):
                    result[relation] = [[name, *row[1:]] for row in f[relation]]
                return result
            answer = self.review(mutate)
            self.assertEqual(expected["reviewable"], answer["reviewable"])
            self.assertEqual({name}, {row[0] for row in answer["denied"]})
            self.assertEqual({row[1:] for row in map(tuple, expected["unresolved"])},
                             {row[1:] for row in map(tuple, answer["unresolved"])})

    def test_declared_actions_query_the_same_view(self):
        document, _, _, _ = load(ROOT, VIEW)
        for row in self.review()["actions"]:
            self.assertIn(row[1], document["queries"])

    def test_existing_action_discovery_exposes_inspection_not_native_retry(self):
        catalog = research_actions.discover(ROOT, {"views": [VIEW]})
        selected = [row for row in catalog["actions"] if row.get("view") == VIEW]
        self.assertTrue(selected)
        self.assertTrue(all(row["operation"] == "evidence-view" for row in selected))
        self.assertTrue(all(row["risk"] == "read-only" for row in selected))

    def test_every_declared_premise_requires_all_supports(self):
        # Synthetic contract rows exercise logic; they are not native evidence.
        for removed in (None, "changed", "checked", "model_support", "model_checked", "source_refined"):
            def mutate(f):
                candidate = f["candidate"][0][0]
                requirement = f["premise"][0][1]
                populated = dict(f, changed=[[candidate, requirement, "synthetic-change"]],
                    checked=[[candidate, requirement, "synthetic-review"]],
                    source_refined=[[candidate, requirement, "synthetic-refinement"]])
                if removed:
                    populated[removed] = []
                return populated
            with self.subTest(removed=removed):
                answer = self.review(mutate)
                self.assertEqual(removed is None, bool(answer["reviewable"]))
                self.assertEqual(removed is not None, bool(answer["denied"]))

    def test_additional_unresolved_premise_prevents_partial_admission(self):
        def mutate(f):
            candidate = f["candidate"][0][0]
            failure, requirement = f["premise"][0]
            return dict(f, premise=f["premise"] + [[failure, "other-source-precondition"]],
                changed=[[candidate, requirement, "synthetic-change"]],
                checked=[[candidate, requirement, "synthetic-review"]],
                source_refined=[[candidate, requirement, "synthetic-refinement"]])
        answer = self.review(mutate)
        self.assertTrue(answer["denied"])
        self.assertFalse(answer["reviewable"])
