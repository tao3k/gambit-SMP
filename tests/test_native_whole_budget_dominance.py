"""Native Scheme policy controls for a stronger containing suite deadline."""
import copy
import json
import unittest

from gambit_smp.ascent_program import engine_api, load_catalog, load_evidence_catalog, query
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

    def test_official_make_bridge_requires_containment_and_original_cap(self):
        self.facts["budget_regime"] = [["old", "whole-sequential", "upstream-make"]]
        self.facts["required_budget"] = [["old", "suite-step"]]
        self.facts["original_budget"] = [["old", "suite-step", 300000]]
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        self.facts["review_current_file"] = [["old", "a"]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])
        self.facts["review_current_file"] = [["old", "a"], ["old", "b"]]
        self.facts["requested_budget"] = [["old", "suite-step", 300001]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_official_check_scope_projects_gsi_without_false_gsc(self):
        contract = json.loads((ROOT / "evidence/research/ci/upstream-tests.json").read_text())
        targets = contract["targets"]
        facts = {
            "selected_make_target": [["check"]],
            "make_dependency": [[name, child] for name, row in targets.items()
                                for child in row["dependencies"]],
            "make_unit_selection": [[name, selection] for name, row in targets.items()
                                    for selection in row["unitSelections"]],
            "make_unit_mode": [[name, mode] for name, modes in contract["unitModes"].items()
                               for mode in modes],
        }
        catalog = load_evidence_catalog(ROOT / "evidence/dsl/upstream-test-scope.ss",
                                        constructor="make-upstream-test-scope", trusted=True)
        with engine_api(retain=True) as (engine, _):
            observed = query(facts, catalog,
                             {"mode": "review_unit_mode", "scope": "review_make_scope",
                              "cycle": "scope_cycle"}, engine=engine, reuse_program=True)
        self.assertEqual([("gsi",)], observed["mode"])
        self.assertIn(("test11",), observed["scope"])
        self.assertEqual([], observed["cycle"])

    def test_budget_toolchain_disjoint_does_not_waive_assertion_failures(self):
        facts = {"retry_marker": [[True]], "known_failure": [["budget", "gsc"], ["assertion", "gsc"]],
                 "selected_failure": [["budget"], ["assertion"]],
                 "failure_category": [["budget", "budget"], ["assertion", "assertion"]],
                 "failure_scope": [["budget", "tests/run-unit-tests.scm"],
                                   ["assertion", "06-thread/thread_start.scm"]],
                 "budget_toolchain_distinct": [["budget"], ["assertion"]]}
        with engine_api(retain=True) as (engine, _):
            observed = query(facts, self.catalog,
                             {"disjoint": "failure_campaign_disjoint", "review": "review_required"},
                             engine=engine, reuse_program=True)
        self.assertEqual([("budget", "gsc")], observed["disjoint"])
        self.assertEqual([("assertion", "gsc")], observed["review"])


if __name__ == "__main__":
    unittest.main()
