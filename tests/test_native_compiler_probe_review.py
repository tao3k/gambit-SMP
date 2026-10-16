"""Stopped compiler phases remain diagnostic, source-bound single-file scopes."""
import copy
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.native_review import compiler_probe_failure, failure_modes
from tests import test_native_whole_budget_dominance as budget_fixture


class CompilerProbeTransportTests(unittest.TestCase):
    def setUp(self):
        self.receipt = {
            "schema": "gambit-compiler-cost.v1", "diagnosticOnly": True,
            "status": "DENY", "sourceStable": True, "selection": "control.scm",
            "wholeProbeBudget": 90,
            "stages": [
                {"name": "scheme-to-c", "exit": 0, "timeout": False, "accepted": True},
                {"name": "c-to-dynamic-module", "exit": -9, "timeout": True, "accepted": False},
            ],
        }

    def phase(self, receipt=None, path="/stages/1/accepted", file="control.scm", mode="gsc"):
        return compiler_probe_failure(self.receipt if receipt is None else receipt, path, file, mode)

    def test_actual_canonical_failure_projects_without_synthetic_results(self):
        receipt = json.loads((ROOT / "evidence/model-results/native-compiler-cost-num-021-deny.json").read_text())
        self.assertNotIn("results", receipt)
        self.assertEqual("c-to-dynamic-module",
                         self.phase(receipt, file="03-number/_num.scm"))

    def test_exact_failed_phase_is_required(self):
        self.assertEqual("c-to-dynamic-module", self.phase())
        self.assertIsNone(self.phase(path="/stages/0/accepted"))
        self.assertIsNone(self.phase(path="/results/0/accepted"))

    def test_source_mode_and_fixture_cannot_drift(self):
        original = copy.deepcopy(self.receipt)
        for field, value in (("sourceStable", False), ("diagnosticOnly", False),
                             ("status", "PASS"), ("selection", "other.scm")):
            with self.subTest(field=field):
                receipt = copy.deepcopy(original)
                receipt[field] = value
                self.assertIsNone(self.phase(receipt))
        self.assertIsNone(self.phase(mode="gsi"))
        self.assertIsNone(self.phase(file="../control.scm"))

    def test_missing_reordered_or_unknown_prior_phases_are_rejected(self):
        original = copy.deepcopy(self.receipt)
        for value in ("unknown", "compiled-assertions"):
            self.receipt = copy.deepcopy(original)
            self.receipt["stages"][0]["name"] = value
            self.assertIsNone(self.phase())
        self.receipt = copy.deepcopy(original)
        self.receipt["stages"][0]["accepted"] = False
        self.assertIsNone(self.phase())

    def test_final_assertion_failure_is_a_compiled_failure_not_success(self):
        self.receipt["stages"][1].update(exit=0, timeout=False, accepted=True)
        self.receipt["stages"].append(
            {"name": "compiled-assertions", "exit": 1, "timeout": False, "accepted": False})
        self.assertEqual({"gsc"}, failure_modes(self.receipt))
        self.assertEqual("compiled-assertions", self.phase(path="/stages/2/accepted"))


class CompilerProbeNativePolicyTests(unittest.TestCase):
    validation_domain = budget_fixture.WholeBudgetDominanceTests.validation_domain
    evaluate = budget_fixture.WholeBudgetDominanceTests.evaluate

    def setUp(self):
        budget_fixture.WholeBudgetDominanceTests.setUp(self)
        self.facts.update(
            budget_regime=[["old", "compiler-probe", "whole-parallel"]],
            compiler_probe_failure=[["old", "c-to-dynamic-module"]],
            scoped_single_file=[["old", "a"]], required_budget=[["old", "file-step"]],
            original_budget=[["old", "file-step", 90000]],
            requested_budget=[["old", "file-step", 90000]],
            whole_budget_interval=[], review_original_file=[], review_current_file=[])

    def test_probe_keeps_original_file_cap(self):
        self.assertEqual([("RETRY_ELIGIBLE",)], self.evaluate()["decision"])
        self.facts["requested_budget"] = [["old", "file-step", 90001]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_probe_cannot_replace_nested_cap_with_whole_cap(self):
        self.facts["requested_budget"] = [["old", "suite-step", 90000]]
        self.assertEqual([("DENY",)], self.evaluate()["decision"])

    def test_probe_cannot_be_relabelled_or_have_unknown_phase(self):
        original = copy.deepcopy(self.facts)
        for changes in ({"known_failure": [["old", "gsi"]]},
                        {"compiler_probe_failure": [["old", "unknown"]]},
                        {"scoped_single_file": []}):
            self.facts = {**copy.deepcopy(original), **changes}
            self.assertEqual([("DENY",)], self.evaluate()["decision"])


if __name__ == "__main__":
    unittest.main()
