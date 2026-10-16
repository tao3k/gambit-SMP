"""Actual native policy controls; observations never substitute for causal review."""
import copy
import unittest

from gambit_smp.ascent_program import engine_api, load_catalog, query
from gambit_smp.framework import ROOT


class NativeEnvironmentPolicyTests(unittest.TestCase):
    validation_domain = {"kind": "sealed-research", "budgetSeconds": 60, "workers": "auto", "processesPerWorker": 2}

    def setUp(self):
        self.catalog = load_catalog(ROOT / "evidence/research/suite-review-rules.ss")
        self.facts = {
            "retry_marker": [[True]], "known_failure": [["old", "gsi"]], "selected_failure": [["old"]],
            "failure_category": [["old", "environment"]], "failure_scope": [["old", "11-network"]],
            "review_present": [["old"]], "campaign_bound": [["old"]],
            "budget_regime": [["old", "whole-parallel", "whole-parallel"]],
            "exact_whole_inventory": [["old"]],
            "required_budget": [["old", "suite-step"]], "original_budget": [["old", "suite-step", 20000]],
            "requested_budget": [["old", "suite-step", 20000]],
            "changed_input": [["old", "permission", "environment", "udp-open", "before", "after"]],
            "environment_observation": [["old", "udp-open"]],
            "claim_evidence": [["old", label, "causal-review", "reviewed", "hash"] for label in
                ("failure-scope-review", "change-relevance-review", "assumptions-review", "environment-cause-review")],
            "claim_change": [["old", "change-relevance-review", "permission"]],
        }

    def evaluate(self):
        with engine_api(retain=True) as (engine, _):
            return query(self.facts, self.catalog, {"decision": "retry_decision"}, engine=engine,
                         reuse_program=True)

    def test_matching_current_permission_and_review_are_conditional_only(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])

    def test_exact_udp_close_scope_requires_its_current_operation(self):
        self.facts["failure_scope"] = [["old", "11-network/udp_close.scm"]]
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        self.facts["environment_observation"] = [["old", "user-info"]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_unreviewed_udp_file_does_not_inherit_directory_permission(self):
        self.facts["failure_scope"] = [["old", "11-network/udp_io.scm"]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_host_identity_requires_the_matching_current_operation(self):
        self.facts["failure_scope"] = [["old", "12-os/user_info.scm"]]
        self.facts["changed_input"][0][3] = "user-info"
        self.facts["environment_observation"] = [["old", "user-info"]]
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        self.facts["environment_observation"] = [["old", "udp-open"]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_permission_does_not_waive_operation_review_or_budget(self):
        original = copy.deepcopy(self.facts)
        for field, value in (("environment_observation", []),
                             ("failure_scope", [["old", "unknown"]]),
                             ("claim_evidence", original["claim_evidence"][:-1]),
                             ("requested_budget", [["old", "suite-step", 20001]])):
            with self.subTest(field=field):
                self.facts = copy.deepcopy(original)
                self.facts[field] = value
                self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_budget_environment_cause_requires_exact_counterfactual(self):
        self.facts["failure_category"] = [["old", "budget"]]
        self.facts["failure_scope"] = [["old", "13-modules/prim_port.scm"]]
        self.facts["changed_input"][0][3] = "process-pipe-sort"
        self.facts["environment_observation"] = [["old", "process-pipe-sort"]]
        row = ["old", "process-pipe-sort", "DENY", "PASS", 0, False, True, True, True, True, True, 20000, 20000]
        self.facts["environment_control"] = [row]
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        for index in range(7, 11):
            with self.subTest(boundField=index):
                row[index] = False
                self.assertEqual([("DENY",)], self.evaluate()["decision"])
                row[index] = True
        row[-1] = 21000
        self.assertEqual([("DENY",)], self.evaluate()["decision"])
