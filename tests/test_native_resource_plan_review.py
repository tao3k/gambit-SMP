"""Recorded topology projection and real Scheme causal-policy controls."""
import copy
import unittest

from gambit_smp.native_review import resource_plan_change
from tests import test_native_environment_correspondence as environment_fixture


class ResourcePlanProjectionTests(unittest.TestCase):
    def setUp(self):
        self.old = {"schema": "gambit-upstream-suite.v1", "modes": ["gsc"],
                    "processors": 12, "jobs": 12,
                    "results": [{"mode": "gsc", "process": {"shards": [{}] * 12}}]}
        self.current = {"mode": "gsc", "regime": "whole-parallel", "hostCpuCapacity": 12,
                        "effectiveJobs": 3, "effectiveProcessors": 3,
                        "selectedFiles": [str(i) for i in range(379)]}

    def test_original_child_lower_bound_and_current_complete_demand_are_distinct(self):
        plan, identity = resource_plan_change(self.old, self.current)
        self.assertEqual(144, plan["originalChildDemand"])
        self.assertEqual(12, plan["currentTotalDemand"])
        self.assertEqual(64, len(identity))
        self.assertNotIn("originalHostCpuCapacity", plan)
        changed = dict(self.current, hostCpuCapacity=8, effectiveJobs=2)
        self.assertNotEqual(identity, resource_plan_change(self.old, changed)[1])

    def test_missing_original_population_or_shards_cannot_be_inferred(self):
        for key, value in (("jobs", None), ("processors", True),
                           ("results", [{"mode": "gsc", "process": {"shards": []}}])):
            with self.subTest(key=key), self.assertRaises(ValueError):
                resource_plan_change(dict(self.old, **{key: value}), self.current)

    def test_foreign_mode_or_current_scheduler_drift_is_rejected(self):
        for change in ({"mode": "gsi"}, {"effectiveJobs": 4}, {"regime": "atomic-coverage"}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                resource_plan_change(self.old, dict(self.current, **change))


class ResourcePlanPolicyTests(unittest.TestCase):
    validation_domain = environment_fixture.NativeEnvironmentPolicyTests.validation_domain
    evaluate = environment_fixture.NativeEnvironmentPolicyTests.evaluate

    def setUp(self):
        environment_fixture.NativeEnvironmentPolicyTests.setUp(self)
        self.facts["failure_category"] = [["old", "budget"]]
        self.facts["changed_input"] = [["old", "plan", "resource-plan", "shared-cpu-capacity", "before", "after"]]
        self.facts["resource_plan_observation"] = [["old", 144, 12, 12]]
        self.facts["claim_evidence"][-1][1] = "resource-plan-cause-review"
        self.facts["claim_change"] = [["old", "change-relevance-review", "plan"]]

    def test_bound_reduction_only_allows_conditional_budget_investigation(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])

    def test_nonreduction_overcapacity_and_zero_demand_are_denied(self):
        for old, new, host in ((12, 12, 12), (144, 13, 12), (144, 0, 12)):
            with self.subTest(old=old, new=new, host=host):
                self.facts["resource_plan_observation"] = [["old", old, new, host]]
                self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_resource_plan_cannot_waive_assertion_or_signal_or_missing_review(self):
        original = copy.deepcopy(self.facts)
        for category in ("assertion", "signal", "environment"):
            with self.subTest(category=category):
                self.facts["failure_category"] = [["old", category]]
                self.assertEqual([("DENY",)], self.evaluate()["decision"])
        self.facts = original
        self.facts["claim_evidence"].pop()
        self.assertEqual([("DENY",)], self.evaluate()["decision"])
