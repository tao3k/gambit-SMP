"""Embedded configuration permits reviewed investigation, not a native pass."""
import copy
import unittest

from tests import test_native_environment_correspondence as environment_fixture


class CompilerConfigurationPolicyTests(unittest.TestCase):
    validation_domain = environment_fixture.NativeEnvironmentPolicyTests.validation_domain
    evaluate = environment_fixture.NativeEnvironmentPolicyTests.evaluate

    def setUp(self):
        environment_fixture.NativeEnvironmentPolicyTests.setUp(self)
        self.facts["known_failure"] = [["old", "gsc"]]
        self.facts["failure_category"] = [["old", "budget"]]
        self.facts["changed_input"] = [["old", "configuration", "compiler-configuration", "image-build-configuration", "before", "after"]]
        self.facts["compiler_configuration_observation"] = [["old", 1, 0]]
        self.facts["claim_evidence"][-1][1] = "compiler-configuration-cause-review"
        self.facts["claim_evidence"].append(["old", "compiler-configuration-association-review", "causal-review", "reviewed", "hash"])
        self.facts["claim_change"] = [["old", "change-relevance-review", "configuration"]]

    def test_exact_configured_compiled_budget_is_conditional_only(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])

    def test_equal_increased_or_unknown_level_is_denied(self):
        for old, new in ((0, 0), (1, 2), (4, 0), (1, -1)):
            with self.subTest(old=old, new=new):
                self.facts["compiler_configuration_observation"] = [["old", old, new]]
                self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_wrong_mode_category_missing_review_or_expanded_budget_is_denied(self):
        original = copy.deepcopy(self.facts)
        for field, value in (
            ("known_failure", [["old", "gsi"]]),
            ("failure_category", [["old", "assertion"]]),
            ("failure_category", [["old", "signal"]]),
            ("failure_category", [["old", "environment"]]),
            ("claim_evidence", original["claim_evidence"][:-1]),
            ("requested_budget", [["old", "suite-step", 20001]]),
        ):
            with self.subTest(field=field, value=value):
                self.facts = copy.deepcopy(original)
                self.facts[field] = value
                self.assertEqual([("DENY",)], self.evaluate()["decision"])
