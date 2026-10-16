"""Recipe admission boundaries; protocol semantics are checked by Quint."""
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp import recipes


class ForeignOriginRetirementRecipeTests(unittest.TestCase):
    def setUp(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/foreign-origin-retirement-admission.recipe.json"
        recipes.load(ROOT, path)
        self.recipe = json.loads(path.read_text())

    def test_model_only_no_bootstrap_or_injection_capability(self):
        self.assertEqual(300, self.recipe["budgetSeconds"])
        allowed = {"gambit.materialize", "quint.parse", "quint.typecheck",
                   "quint.verify", "quint.test", "evidence.evaluate"}
        self.assertLessEqual({s["capability"] for s in self.recipe["steps"]}, allowed)

    def test_controls_and_trajectories_are_required_by_verdict(self):
        steps = {s["id"]: s for s in self.recipe["steps"]}
        controls = {s["arguments"]["initializer"] for s in steps.values()
                    if s["capability"] == "quint.verify" and s["arguments"]["negative"]}
        self.assertEqual({"initSplit", "initGlobalBan", "initUncheckedGeneration"}, controls)
        self.assertEqual(6, len(steps["trajectories"]["arguments"]["expectedTests"]))
        self.assertEqual(set(steps) - {"verdict"}, set(steps["verdict"]["dependsOn"]))
        self.assertEqual({"missing": []}, steps["verdict"]["arguments"]["expected"])

    def test_word_bounds_refinement_is_model_only_and_keeps_controls(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/foreign-origin-word-bounds.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertFalse(any(s["capability"] in {"gambit.bootstrap", "gambit.executable-test"}
                             for s in recipe["steps"]))
        controls = {s["arguments"]["initializer"] for s in recipe["steps"]
                    if s["capability"] == "quint.verify" and s["arguments"]["negative"]}
        self.assertEqual({"initGateWrap", "initLeaseWrap"}, controls)
        verdict = next(s for s in recipe["steps"] if s["id"] == "verdict")
        self.assertEqual({s["id"] for s in recipe["steps"]} - {"verdict"},
                         set(verdict["dependsOn"]))

    def test_vm_teardown_composition_keeps_negative_controls_and_full_inventory(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/foreign-origin-vm-teardown.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        self.assertEqual(300, recipe["budgetSeconds"])
        controls = {s["arguments"]["initializer"] for s in recipe["steps"]
                    if s["capability"] == "quint.verify" and s["arguments"]["negative"]}
        self.assertEqual({"initPopulationOnly", "initEarlyCommit"}, controls)
        trajectories = next(s for s in recipe["steps"] if s["id"] == "trajectories")
        self.assertEqual(4, len(trajectories["arguments"]["expectedTests"]))
        self.assertFalse(any(s["capability"] == "gambit.executable-test"
                             for s in recipe["steps"]))


if __name__ == "__main__":
    unittest.main()
