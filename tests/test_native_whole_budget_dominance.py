"""Native Scheme policy controls for a stronger containing suite deadline."""
import copy
import unittest

from gambit_smp.ascent_program import engine_api, load_catalog, query
from gambit_smp.framework import ROOT


class WholeBudgetDominanceTests(unittest.TestCase):
    validation_domain = {"kind": "sealed-research", "budgetSeconds": 60, "workers": "auto", "processesPerWorker": 2}

    def setUp(self):
        self.catalog = load_catalog(ROOT / "evidence/research/suite-review-rules.ss")
        self.facts = {
            "retry_marker": [[True]], "known_failure": [["old", "gsc"]],
            "selected_failure": [["old"]], "failure_category": [["old", "budget"]],
            "review_present": [["old"]], "campaign_bound": [["old"]],
            "budget_regime": [["old", "atomic-coverage", "whole-parallel"]],
            "whole_budget_interval": [["old"]],
            "review_original_file": [["old", "a"], ["old", "b"]],
            "review_current_file": [["old", "a"], ["old", "b"], ["old", "c"]],
            "required_budget": [["old", "atomic-batch"]],
            "original_budget": [["old", "atomic-batch", 300000]],
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

    def test_complete_superset_under_original_cap_is_conditional(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])

    def test_original_file_cannot_be_omitted(self):
        self.facts["review_current_file"] = [["old", "a"], ["old", "c"]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_preparation_interval_cannot_be_detached(self):
        self.facts["whole_budget_interval"] = []
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_caps_cannot_be_multiplied_or_expanded(self):
        original = copy.deepcopy(self.facts)
        for cap in (300001, 600000):
            with self.subTest(cap=cap):
                self.facts = copy.deepcopy(original)
                self.facts["requested_budget"] = [["old", "suite-step", cap]]
                answer = self.evaluate()
                self.assertEqual([("DENY",)], answer["decision"])
                self.assertIn(("old", "budget-expanded"), answer["denied"])

    def test_empty_original_inventory_does_not_vacuously_cover(self):
        self.facts["review_original_file"] = []
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_dominance_does_not_replace_causal_review(self):
        self.facts["claim_evidence"] = self.facts["claim_evidence"][:-1]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_whole_superset_also_preserves_original_whole_cap(self):
        self.facts["budget_regime"] = [["old", "whole-parallel", "whole-parallel"]]
        self.facts["required_budget"] = [["old", "suite-step"]]
        self.facts["original_budget"] = [["old", "suite-step", 300000]]
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        self.facts["requested_budget"] = [["old", "suite-step", 300001]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])


if __name__ == "__main__":
    unittest.main()
