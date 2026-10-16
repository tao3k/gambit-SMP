import json
from pathlib import Path
import re
import unittest

from gambit_smp.framework import ROOT, digest


class FixtureIdentityTests(unittest.TestCase):
    def test_all_active_fixture_assets_use_semantic_names(self):
        fixture_root = ROOT / "evidence/fixtures"
        fixtures = sorted(path for path in fixture_root.iterdir() if path.is_dir())
        self.assertTrue(fixtures)
        for fixture in fixtures:
            with self.subTest(fixture=fixture.name):
                self.assertRegex(fixture.name, r"^[a-z]+(?:-[a-z]+)*$")
                for path in fixture.rglob("*"):
                    self.assertFalse(any(char.isdigit() for char in path.relative_to(fixture_root).as_posix()), path)
                lock_path = fixture / "source.lock.json"
                if lock_path.is_file():
                    lock = json.loads(lock_path.read_text())
                    self.assertEqual(f"patches/fixtures/{fixture.name}.patch", lock["patch"])
                    self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
                elif (fixture / "profile.json").is_file():
                    from gambit_smp.build_profile import read_profile
                    # A source-bound build profile is data, not a runtime patch.
                    self.assertEqual(["profile.json"], sorted(p.name for p in fixture.iterdir()))
                    read_profile(fixture / "profile.json")
                else:
                    # Protocol-only fixtures do not pretend to own a C overlay.
                    self.assertTrue(list(fixture.glob("*.json")))
                    for path in fixture.iterdir():
                        self.assertEqual(path.suffix, ".json")
                        contract = json.loads(path.read_text())
                        self.assertEqual(contract["schema"], "gambit-protocol-extensions.v1")
                        self.assertTrue(contract["contextInputs"])
                        self.assertTrue(contract["cases"])
                        for case in contract["cases"]:
                            self.assertRegex(case["id"], r"^[a-z]+(?:_[a-z]+)*$")
                            self.assertTrue((ROOT / "models/gambit" / (case["id"] + ".qnt")).is_file())
                            self.assertTrue(case.get("invariants"))
                for manifest_path in fixture.glob("*.json"):
                    manifest = json.loads(manifest_path.read_text())
                    for context_path in manifest.get("contextInputs", {}):
                        self.assertIsNone(re.search(r"(?:source|candidate)[-_]?\d+", context_path, re.I), context_path)
                recipe_root = ROOT / "evidence/research" / fixture.name
                for recipe_path in recipe_root.glob("*.recipe.json"):
                    recipe = json.loads(recipe_path.read_text())
                    self.assertRegex(recipe["id"], r"^[a-z]+(?:-[a-z]+)*$")
                    for input_path in recipe["inputs"]:
                        self.assertIsNone(re.search(r"(?:source|candidate)[-_]?\d+", input_path, re.I), input_path)
                    for step in recipe["steps"]:
                        if step["capability"] == "gambit.materialize":
                            source_lock = step["arguments"]["sourceLock"]
                            self.assertRegex(source_lock, r"^evidence/fixtures/[a-z]+(?:-[a-z]+)*/(?:source|[a-z]+(?:-[a-z]+)*-source)\.lock\.json$")
                            self.assertIn(source_lock, recipe["inputs"])
                            self.assertTrue((ROOT / source_lock).is_file())
                            selected_lock = json.loads((ROOT / source_lock).read_text())
                            self.assertEqual("vendor/gambit", selected_lock["submodule"])
                            self.assertRegex(selected_lock["patch"], r"^patches/fixtures/[a-z]+(?:-[a-z]+)*\.patch$")
                            self.assertEqual(selected_lock["patchSha256"], digest(ROOT / selected_lock["patch"]))

    def test_owned_log_fixture_has_semantic_and_content_bound_identity(self):
        base = "evidence/fixtures/pstate-log-owned-rollback/"
        lock_name = base + "source.lock.json"
        lock = json.loads((ROOT / lock_name).read_text())
        self.assertEqual("vendor/gambit", lock["submodule"])
        self.assertEqual("patches/fixtures/pstate-log-owned-rollback.patch", lock["patch"])
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        self.assertEqual(13, len(lock["files"]))
        for name in (base + "processor-log-contract.json", base + "vm-memory-contract.json",
                     "evidence/vm-constructor-rollback-composition.json"):
            manifest = json.loads((ROOT / name).read_text())
            self.assertEqual(digest(ROOT / lock_name), manifest["contextInputs"][lock_name])
            for path in manifest["contextInputs"]:
                self.assertIsNone(re.search(r"(?:source|candidate)[-_]?\d+", path), path)

    def test_materialization_recipe_uses_the_fixture_not_an_experiment_number(self):
        recipe = json.loads((ROOT / "evidence/research/pstate-log-owned-rollback/source.recipe.json").read_text())
        self.assertEqual("pstate-log-owned-rollback-materialization", recipe["id"])
        lock = "evidence/fixtures/pstate-log-owned-rollback/source.lock.json"
        self.assertIn(lock, recipe["inputs"])
        self.assertEqual(lock, recipe["steps"][0]["arguments"]["sourceLock"])

