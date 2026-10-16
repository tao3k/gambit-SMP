"""Real Scheme policy: command differences are not correctness waivers."""
import copy
import unittest

from tests import test_native_environment_correspondence as environment_fixture


class CompilerOptionsPolicyTests(unittest.TestCase):
    validation_domain = environment_fixture.NativeEnvironmentPolicyTests.validation_domain
    evaluate = environment_fixture.NativeEnvironmentPolicyTests.evaluate

    def setUp(self):
        environment_fixture.NativeEnvironmentPolicyTests.setUp(self)
        self.facts["known_failure"] = [["old", "gsc"]]
        self.facts["failure_category"] = [["old", "budget"]]
        self.facts["changed_input"] = [["old", "options", "compiler-options", "dynamic-c-optimization", "before", "after"]]
        self.facts["compiler_options_observation"] = [["old", 1, 0]]
        self.facts["compiler_probe_failure"] = [["old", "c-to-dynamic-module"]]
        self.facts["claim_evidence"][-1][1] = "compiler-options-cause-review"
        self.facts["claim_evidence"].append(["old", "compiler-command-association-review", "causal-review", "reviewed", "hash"])
        self.facts["claim_change"] = [["old", "change-relevance-review", "options"]]

    def test_reviewed_command_difference_is_conditional(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])

    def test_equal_increased_or_unknown_level_is_denied(self):
        for old, new in ((0, 0), (1, 2), (4, 0), (1, -1)):
            with self.subTest(old=old, new=new):
                self.facts["compiler_options_observation"] = [["old", old, new]]
                self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_wrong_phase_category_missing_review_and_expanded_budget_are_denied(self):
        original = copy.deepcopy(self.facts)
        for field, value in (
            ("compiler_probe_failure", [["old", "scheme-to-c"]]),
            ("failure_category", [["old", "assertion"]]),
            ("failure_category", [["old", "signal"]]),
            ("claim_evidence", original["claim_evidence"][:-1]),
            ("requested_budget", [["old", "suite-step", 20001]]),
        ):
            with self.subTest(field=field, value=value):
                self.facts = copy.deepcopy(original)
                self.facts[field] = value
                self.assertEqual([("DENY",)], self.evaluate()["decision"])
