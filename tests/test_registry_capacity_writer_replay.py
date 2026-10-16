"""Source and recipe correspondence; finite verification runs in the framework."""
import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp import recipes


class RegistryCapacityWriterReplayTests(unittest.TestCase):
    def test_recipe_binds_source_and_exact_controls_without_building(self):
        path = ROOT / "evidence/research/vm-registry-reader-lease/capacity-writer-replay.recipe.json"
        recipes.load(ROOT, path)
        recipe = json.loads(path.read_text())
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertEqual("gambit.materialize", recipe["steps"][0]["capability"])
        self.assertFalse(any(row["capability"] in {
            "gambit.configure", "gambit.seed-core", "gambit.bootstrap"
        } for row in recipe["steps"]))
        controls = [row["arguments"]["initializer"] for row in recipe["steps"]
                    if row["capability"] == "quint.verify" and row["arguments"]["negative"]]
        self.assertEqual(["initNoReleaseReplay", "initNoRecordRecheck"], controls)
        lock = json.loads((ROOT / recipe["steps"][0]["arguments"]["sourceLock"]).read_text())
        self.assertIn(lock["patch"], recipe["inputs"])

    def test_selected_source_has_release_and_publication_rechecks(self):
        lock = json.loads((ROOT / "evidence/fixtures/vector-increment-arity-parity/source.lock.json").read_text())
        patch = (ROOT / lock["patch"]).read_text()
        for fragment in (
            "old > (~(___UWORD)0) - 4",
            "if (__atomic_load_n(&vm_registry_pending, __ATOMIC_SEQ_CST) != 0)",
            "/* The raw release below avoids recursive release/flush calls. */",
            "/* A writer may have reopened and flushed before this publication. */",
        ):
            self.assertIn(fragment, patch)
