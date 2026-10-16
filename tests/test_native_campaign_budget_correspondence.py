"""Actual native policy controls for exact whole-wall-clock correspondence."""
import copy
import unittest

from gambit_smp.ascent_program import engine_api, load_catalog, query
from gambit_smp.framework import ROOT


class NativeCampaignBudgetPolicyTests(unittest.TestCase):
    validation_domain = {"kind": "sealed-research", "budgetSeconds": 60, "workers": "auto", "processesPerWorker": 2}

    def setUp(self):
        self.catalog = load_catalog(ROOT / "evidence/research/suite-review-rules.ss")
        self.facts = {
            "retry_marker": [[True]], "known_failure": [["old", "gsi"]],
            "selected_failure": [["old"]], "failure_category": [["old", "assertion"]],
            "review_present": [["old"]], "campaign_bound": [["old"]],
            "budget_regime": [["old", "whole-sequential", "whole-parallel"]],
            "exact_whole_inventory": [["old"]],
            "required_budget": [["old", "suite-step"]],
            "original_budget": [["old", "suite-step", 300000]],
            "requested_budget": [["old", "suite-step", 300000]],
            "changed_input": [["old", "repair", "source", "lib/setup.c", "before", "after"]],
            "claim_evidence": [["old", label, "causal-review", "reviewed", "hash"] for label in
                ("failure-scope-review", "change-relevance-review", "assumptions-review")],
            "claim_change": [["old", "change-relevance-review", "repair"]],
        }

    def evaluate(self):
        with engine_api(retain=True) as (engine, _):
            return query(self.facts, self.catalog,
                         {"decision": "retry_decision", "denied": "retry_denied"}, engine=engine,
                         reuse_program=True)

    def test_exact_whole_topology_only_grants_conditional_review(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])

    def test_same_whole_regime_requires_exact_scope(self):
        for regime in ("whole-sequential", "whole-parallel"):
            with self.subTest(regime=regime):
                self.facts["budget_regime"] = [["old", regime, regime]]
                self.facts["exact_whole_inventory"] = [["old"]]
                self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
                self.facts["exact_whole_inventory"] = []
                result = self.evaluate()
                self.assertEqual([("DENY",)], result["decision"])
                self.assertIn(("old", "budget-regime-changed"), result["denied"])

    def test_correspondence_does_not_waive_scope_budget_or_review(self):
        original = copy.deepcopy(self.facts)
        controls = [("exact_whole_inventory", []),
                    ("budget_regime", [["old", "atomic-coverage", "whole-parallel"]]),
                    ("requested_budget", [["old", "suite-step", 300001]]),
                    ("claim_evidence", original["claim_evidence"][:-1])]
        for field, value in controls:
            with self.subTest(field=field):
                self.facts = copy.deepcopy(original)
                self.facts[field] = value
                self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_atomic_regime_alone_does_not_authorize_changed_scope(self):
        self.facts["budget_regime"] = [["old", "atomic-coverage", "atomic-coverage"]]
        self.facts["required_budget"] = [["old", "atomic-batch"]]
        self.facts["original_budget"] = [["old", "atomic-batch", 2000]]
        self.facts["requested_budget"] = [["old", "atomic-batch", 2000]]
        self.facts["exact_whole_inventory"] = []
        self.assertEqual([("DENY",)], self.evaluate()["decision"])
        self.facts["exact_atomic_inventory"] = [["old"]]
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
