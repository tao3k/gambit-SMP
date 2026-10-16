"""CI graph contracts and real Evidence evaluation, not native acceptance."""
from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp import recipes
from gambit_smp.evidence_capabilities import facts, native_evaluate
from gambit_smp.framework import ROOT, digest


PATH = ROOT / "evidence/research/ci/three-flag-core.recipe.json"


class CIRecipeContracts(unittest.TestCase):
    def setUp(self):
        self.recipe, self.steps = recipes.load(ROOT, PATH)

    def test_build_is_an_existing_typed_graph_not_a_ci_handler(self):
        self.assertEqual("evidence-recipe.v2", self.recipe["schema"])
        self.assertEqual(600, self.recipe["budgetSeconds"])
        self.assertNotIn("timeoutPolicy", self.recipe)
        self.assertTrue(all(step["budgetSeconds"] <= 600 for step in self.steps))
        self.assertEqual(["gambit.materialize", "gambit.configure", "gambit.seed-core",
                          "gambit.source-core", "evidence.evaluate"],
                         [step["capability"] for step in self.steps])
        self.assertNotIn(".github/gambit/runner.py", self.recipe["inputs"])
        self.assertEqual(3, self.steps[1]["arguments"]["cOptimization"])
        self.assertEqual(3, self.steps[1]["arguments"]["rtsOptimization"])
        self.assertIn("not full bootstrap", self.recipe["scope"])

    def test_dsl_bytes_are_bound_and_every_build_step_is_required(self):
        entry = recipes.read_json(ROOT / self.steps[-1]["arguments"]["dsl"])
        for source in entry["sources"]:
            self.assertIn(source["path"], self.recipe["inputs"])
            self.assertEqual(source["sha256"], digest(ROOT / source["path"]))
        self.assertEqual([step["id"] for step in self.steps[:-1]],
                         self.steps[-1]["dependsOn"])
        self.assertEqual({"missing": []}, self.steps[-1]["arguments"]["expected"])

    def test_wrong_artifact_type_and_untyped_commands_are_rejected(self):
        from gambit_smp.native_capabilities import graph, validate_configure
        invalid = deepcopy(self.steps[3])
        invalid["arguments"]["runtime"] = {"step": "configure", "output": "source"}
        invalid["dependsOn"] = ["configure"]
        with self.assertRaises(ValueError):
            graph(invalid, {step["id"]: step for step in self.steps}, recipes.CAPABILITIES)
        invalid = dict(self.steps[1]["arguments"], argv=["make", "check"])
        with self.assertRaises(ValueError):
            validate_configure(invalid, self.recipe["inputs"])

    def test_actual_dsl_keeps_failed_and_unstarted_steps_missing(self):
        # Exercise the declared production DSL using the normal Library boundary.
        # These are observation-contract controls, not fabricated native results.
        steps = [dict(step, outcome="PASS") for step in self.steps[:-1]]
        steps[2]["outcome"] = "DENY"
        steps[3]["outcome"] = "BLOCKED"
        projected = facts({"steps": steps})
        entry_path = ROOT / self.steps[-1]["arguments"]["dsl"]
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            request = {"rules": [], "dsl": recipes.read_json(entry_path),
                       "dslInput": str(entry_path), "dslRoot": str(ROOT),
                       "dslInputSha256": digest(entry_path), "facts": projected,
                       "queries": {"missing": "missing_step", "checked": "checked_step"},
                       "output": str(directory)}
            native_evaluate(request)
            answers = json.loads((directory / "answers.json").read_text())
            self.assertEqual([["seed"], ["source-core"]], sorted(answers["missing"]))
            self.assertEqual([["candidate"], ["configure"]], sorted(answers["checked"]))
            explanation = json.loads((directory / "explanations.json").read_text())
            self.assertFalse(explanation["runtimeAdmitted"])
            self.assertFalse(explanation["sourceRefinementAdmitted"])

    def test_official_scope_is_inferred_by_the_actual_library_dsl(self):
        from gambit_smp.upstream_tests import CONTRACT, ENTRY
        contract = recipes.read_json(ROOT / CONTRACT)
        entry_path = ROOT / ENTRY
        declarations = contract["targets"]
        with tempfile.TemporaryDirectory() as name:
            for index, (target, expected, mutation) in enumerate((
                    ("test9", ["test7", "test9"], False),
                    ("check", sorted(declarations), False),
                    ("check", sorted(declarations), True))):
                directory = Path(name) / str(index)
                directory.mkdir()
                dependencies = [[parent, child] for parent, row in declarations.items() for child in row["dependencies"]]
                if mutation:
                    dependencies.append(["core-pre", "check"])
                request = {"rules": [], "dsl": recipes.read_json(entry_path),
                    "dslInput": str(entry_path), "dslRoot": str(ROOT), "dslInputSha256": digest(entry_path),
                    "facts": {"selected_make_target": [[target]], "make_dependency": dependencies,
                              "make_unit_selection": [[parent, selection] for parent, row in declarations.items()
                                                      for selection in row["unitSelections"]]},
                    "queries": {"scope": "review_make_scope", "selections": "review_unit_selection", "cycles": "scope_cycle"},
                    "output": str(directory)}
                native_evaluate(request)
                answers = json.loads((directory / "answers.json").read_text())
                self.assertEqual([[value] for value in expected], sorted(answers["scope"]))
                self.assertEqual([["."]] if target == "check" else [], answers["selections"])
                self.assertEqual(mutation, bool(answers["cycles"]))


if __name__ == "__main__":
    unittest.main()
