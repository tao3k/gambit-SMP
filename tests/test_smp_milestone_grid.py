"""The existing native DSL must reject a partial SMP milestone."""
import unittest

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.framework import ROOT


class MilestoneGridTests(unittest.TestCase):
    def setUp(self):
        self.catalog = load_catalog(
            ROOT / "evidence/research/execution-rules.ss",
            ROOT / "evidence/research/smp-threaded-vm-native-grid/milestone-rules.ss")

    def evaluate(self, observations):
        return query({"required_step": [["independent-vms"]],
                      "observed_step": observations}, self.catalog,
                     {"required": "grid_required", "open": "milestone_open"})

    def test_partial_default_suite_and_vm_smoke_leave_all_obligations_open(self):
        answer = self.evaluate([["native-gsi", "PASS", "gambit.suite"],
                                ["native-gsc", "PASS", "gambit.suite"],
                                ["independent-vms", "PASS", "gambit.executable-test"]])
        self.assertEqual(9, len(answer["open"]))
        self.assertEqual({row[0] for row in answer["required"]},
                         {row[0] for row in answer["open"]})

    def test_finite_model_pass_cannot_discharge_native_lifetime(self):
        answer = self.evaluate([["registry-lifetime-native", "PASS", "quint.verify"]])
        self.assertIn(("registry-lifetime-native",), answer["open"])

    def test_denied_native_stage_remains_open(self):
        answer = self.evaluate([["registry-lifetime-native", "DENY", "gambit.executable-test"]])
        self.assertIn(("registry-lifetime-native",), answer["open"])

    def test_exact_stage_inventory_is_only_coverage_not_runtime_admission(self):
        required = self.evaluate([])["required"]
        answer = self.evaluate([[stage, "PASS", capability] for stage, capability in required])
        self.assertEqual([], answer["open"])
        self.assertEqual({"required", "open"}, set(answer))
