"""Diagnostic scope guards, not native correctness qualification."""
import hashlib
import json
import unittest

from gambit_smp.framework import ROOT


class PrimPortReporterTests(unittest.TestCase):
    def test_source_successor_changes_only_reporter(self):
        old = json.loads((ROOT / "evidence/fixtures/vm-global-cleanup-preflight/source.lock.json").read_text())
        new = json.loads((ROOT / "evidence/fixtures/vm-reporter-preservation/source.lock.json").read_text())
        self.assertEqual(old["revision"], new["revision"])
        self.assertEqual({name: new["files"][name] for name in old["files"]}, old["files"])
        self.assertEqual(set(new["files"]) - set(old["files"]), {"tests/unit-tests/13-modules/#.scm"})
        inherited = (ROOT / old["patch"]).read_bytes()
        patch = (ROOT / new["patch"]).read_bytes()
        self.assertTrue(patch.startswith(inherited))
        self.assertEqual(hashlib.sha256(patch).hexdigest(), new["patchSha256"])
        suffix = patch[len(inherited):].decode()
        self.assertEqual([line for line in suffix.splitlines() if line.startswith("-") and not line.startswith("---")], ["-           (##failed-check"])
        self.assertEqual([line for line in suffix.splitlines() if line.startswith("+") and not line.startswith("+++")], ["+           (##failed-test"])

    def test_complete_successor_preserves_original_scope_and_budgets(self):
        base = ROOT / "evidence/research/smp-threaded-vm-native-grid"
        old = json.loads((base / "global-cleanup-interpreted.recipe.json").read_text())
        new = json.loads((base / "reporter-preservation-interpreted.recipe.json").read_text())
        self.assertEqual(old["budgetSeconds"], new["budgetSeconds"])
        old_step = next(step for step in old["steps"] if step["id"] == "native-gsi")
        new_step = next(step for step in new["steps"] if step["id"] == "native-gsi")
        self.assertEqual(old_step, new_step)
        self.assertEqual(len(new_step["arguments"]["expectedFiles"]), 379)
        self.assertNotIn("13-modules/prim_port_reporter.scm", new_step["arguments"].get("additionalFixtures", {}))

    def test_reporter_delegates_to_original_failure_flag(self):
        source = ROOT / "models/gambit/native/prim_port_reporter.scm"
        forms = [line for line in source.read_text().splitlines()
                 if line and not line.startswith(";")]
        self.assertEqual(forms, [
            '(include "#.scm")',
            '(define (##failed-check message)',
            '  (##failed-test message))',
            '(include "prim_port.scm")',
        ])

    def test_recipe_uses_current_producer_and_unchanged_file_budget(self):
        recipe = json.loads((ROOT / "evidence/research/vm-registry-reader-lease/prim-port-reporter.recipe.json").read_text())
        steps = {step["id"]: step for step in recipe["steps"]}
        args = steps["reporter"]["arguments"]
        self.assertEqual(recipe["budgetSeconds"], 300)
        self.assertEqual(steps["reporter"]["budgetSeconds"], 120)
        self.assertEqual(args["mode"], "gsi")
        self.assertEqual(args["fileBudgetSeconds"], {"13-modules/prim_port_reporter.scm": 20})
        self.assertNotIn("processors", args)
        self.assertNotIn("jobs", args)
        self.assertEqual(args["failures"], "evidence/native-failures.json")
        fixture = args["additionalFixtures"]["13-modules/prim_port_reporter.scm"]
        self.assertEqual(fixture["sha256"], hashlib.sha256((ROOT / fixture["source"]).read_bytes()).hexdigest())
        self.assertIn(fixture["source"], recipe["inputs"])
        self.assertEqual(steps["producer"]["arguments"]["producer"],
                         "evidence/research/vm-registry-reader-lease/global-cleanup-completed-producer.json")
        self.assertIn("Does not replace", recipe["scope"])


if __name__ == "__main__":
    unittest.main()
