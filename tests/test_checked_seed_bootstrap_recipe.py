"""Declaration preservation, not native or model qualification."""
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.recipes import load


class CheckedSeedBootstrapRecipeTests(unittest.TestCase):
    def setUp(self):
        self.directory = ROOT / "evidence/research/vm-registry-reader-lease"
        self.original, _ = load(ROOT, self.directory / "foreign-origin-lease-admission-bootstrap.recipe.json")
        self.candidate, _ = load(ROOT, self.directory / "foreign-origin-lease-checked-seed-bootstrap.recipe.json")
        self.old = {step["id"]: step for step in self.original["steps"]}
        self.new = {step["id"]: step for step in self.candidate["steps"]}
        self.reference = json.loads((self.directory / "foreign-origin-lease-seed-checkpoint.json").read_text())

    def test_full_bootstrap_and_native_inventory_are_unchanged(self):
        for name in ("source", "bootstrap", "native-arity"):
            self.assertEqual(self.old[name], self.new[name])
        self.assertLess(self.candidate["budgetSeconds"], self.original["budgetSeconds"])
        self.assertTrue(set(self.original["inputs"]) <= set(self.candidate["inputs"]))

    def test_import_is_seed_only_and_requires_fresh_review(self):
        self.assertEqual("gambit.seed-checkpoint", self.new["seed"]["capability"])
        self.assertEqual(self.old["configure"]["arguments"]["buildProfile"],
                         self.new["seed"]["arguments"]["buildProfile"])
        self.assertEqual(self.old["review"]["arguments"], self.new["review"]["arguments"])
        self.assertIn("seed", self.new["review"]["dependsOn"])
        self.assertIn("review", self.new["bootstrap"]["dependsOn"])
        self.assertFalse(any(step["capability"] in {"gambit.configure", "gambit.seed-core"}
                             for step in self.candidate["steps"]))

    def test_original_seed_dependencies_and_deny_are_not_omitted(self):
        proof = self.reference["checkpoint"]
        self.assertEqual("DENY", proof["campaignOutcome"])
        self.assertIs(proof["runtimeAdmitted"], False)
        self.assertIs(proof["resumptionAuthorized"], False)
        by_id = {item["id"]: item for item in proof["ancestry"]}
        for name in self.old["configure"]["dependsOn"] + ["configure", "seed"]:
            self.assertIn(name, by_id)
        self.assertEqual(2, len(self.reference["expenditures"]))
        self.assertEqual(proof["outerReceiptSha256"], self.reference["expenditures"][-1]["sha256"])
        for record in self.reference["expenditures"]:
            self.assertFalse(record["run"].startswith("/"))
            self.assertNotIn("..", record["run"].split("/"))

    def test_verdict_depends_on_every_new_step(self):
        self.assertEqual(set(self.new) - {"verdict"}, set(self.new["verdict"]["dependsOn"]))
        self.assertEqual(self.old["verdict"]["arguments"], self.new["verdict"]["arguments"])


if __name__ == "__main__":
    unittest.main()
