import re
import tomllib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEAN = ROOT / "models/gambit/lean"


class LeanDependencyContractTests(unittest.TestCase):
    """Configuration guards, not Lean elaboration or proof admission."""

    def test_lean_poo_is_an_immutable_git_dependency(self):
        package = tomllib.loads((LEAN / "lakefile.toml").read_text())
        requirements = package["require"]
        self.assertEqual(len(requirements), 1)
        dependency = requirements[0]
        self.assertEqual(dependency["name"], "LeanPoo")
        self.assertEqual(dependency["git"], "https://github.com/tao3k/lean-poo.git")
        self.assertRegex(dependency["rev"], r"^[0-9a-f]{40}$")
        self.assertNotIn("path", dependency)

    def test_positive_target_reuses_lean_poo_resource_composition(self):
        package = tomllib.loads((LEAN / "lakefile.toml").read_text())
        self.assertEqual(package["defaultTargets"], ["WorkAccounting"])
        source = (LEAN / "WorkAccounting.lean").read_text()
        self.assertIn("import LeanPoo.Functional.TransformationResources", source)
        self.assertIn("LeanPoo.Functional.Transformation.resource_compose_cost", source)
        self.assertIsNone(re.search(r"\b(sorry|axiom|admit)\b", source))
        self.assertEqual(source.count("#print axioms "), 4)

    def test_toolchain_is_versioned_and_controls_are_not_positive_targets(self):
        toolchain = (LEAN / "lean-toolchain").read_text().strip()
        self.assertRegex(toolchain, r"^leanprover/lean4:v\d+\.\d+\.\d+$")
        package = tomllib.loads((LEAN / "lakefile.toml").read_text())
        self.assertEqual([lib["name"] for lib in package["lean_lib"]], ["WorkAccounting"])
        self.assertTrue((LEAN / "controls/OmittedLifetime.lean").is_file())
        self.assertTrue((LEAN / "controls/SorryWitness.lean").is_file())


if __name__ == "__main__":
    unittest.main()
