"""Configured compiler bytes allow only reviewed budget investigations."""
import copy
import tempfile
import unittest
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp.native_review import build_driver_change
from tests import test_native_whole_budget_dominance as budget_fixture


class BuildDriverTransportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.driver = self.root / "bin/gambuild-C"
        self.driver.parent.mkdir()
        self.driver.write_text("current configured driver fixture\n")
        self.before = "a" * 64
        self.previous = {"buildDriver": {"relativePath": "bin/gambuild-C",
            "sha256": self.before, "configuredCompilerVerified": True}}
        self.change = {"path": "bin/gambuild-C", "before": self.before,
                       "after": digest(self.driver)}

    def test_exact_recorded_driver_binds_current_bytes(self):
        self.assertEqual((self.before, self.driver.resolve()),
                         build_driver_change(self.previous, self.change, self.root))

    def test_missing_original_driver_is_not_invented_from_current_flags(self):
        for previous in ({}, {"buildDriver": None}):
            with self.subTest(previous=previous), self.assertRaises(ValueError):
                build_driver_change(previous, self.change, self.root)

    def test_path_hash_and_configured_identity_cannot_be_substituted(self):
        for key, value in (("relativePath", "bin/other"), ("sha256", "b" * 64),
                           ("configuredCompilerVerified", False)):
            previous = copy.deepcopy(self.previous)
            previous["buildDriver"][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                build_driver_change(previous, self.change, self.root)

    def test_current_byte_drift_fails_closed(self):
        self.driver.write_text("edited after the review intent\n")
        with self.assertRaises(ValueError):
            build_driver_change(self.previous, self.change, self.root)

    def test_bad_original_hash_and_path_boundary_fail_closed(self):
        previous = copy.deepcopy(self.previous)
        previous["buildDriver"]["sha256"] = "unknown"
        change = {**self.change, "before": "unknown"}
        with self.assertRaises(ValueError):
            build_driver_change(previous, change, self.root)
        with self.assertRaises(ValueError):
            build_driver_change(self.previous, {**self.change, "path": "../gambuild-C"}, self.root)


class BuildDriverNativePolicyTests(unittest.TestCase):
    validation_domain = budget_fixture.WholeBudgetDominanceTests.validation_domain
    evaluate = budget_fixture.WholeBudgetDominanceTests.evaluate

    def setUp(self):
        budget_fixture.WholeBudgetDominanceTests.setUp(self)
        self.facts["changed_input"] = [["old", "driver", "build-driver", "bin/gambuild-C", "before", "after"]]
        self.facts["claim_change"] = [["old", "change-relevance-review", "driver"]]
        self.facts["claim_evidence"].append(
            ["old", "build-driver-cause-review", "causal-review", "reviewed", "bound"])

    def test_budget_only_and_explicit_driver_cause_are_required(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        for category in ("assertion", "signal", "environment"):
            self.facts["failure_category"] = [["old", category]]
            self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_unreviewed_driver_does_not_enable_retry(self):
        self.facts["claim_evidence"] = self.facts["claim_evidence"][:-1]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_driver_change_cannot_waive_original_scope_or_cap(self):
        original = copy.deepcopy(self.facts)
        for changes in ({"review_current_file": [["old", "a"]]},
                        {"requested_budget": [["old", "suite-step", 300001]]}):
            self.facts = {**copy.deepcopy(original), **changes}
            self.assertEqual([("DENY",)], self.evaluate()["decision"])
