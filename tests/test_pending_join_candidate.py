"""Keep the pending-join candidate separate and reproducible."""
import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class PendingJoinCandidateTests(unittest.TestCase):
    def test_source_lock_preserves_base_and_changes_only_two_candidate_files(self):
        old = json.loads((ROOT / "evidence/fixtures/vm-registry-reader-lease/"
                         "resize-grace-source.lock.json").read_text())
        new = json.loads((ROOT / "evidence/fixtures/vm-pending-join-retention/"
                         "source.lock.json").read_text())
        self.assertEqual(old["revision"], new["revision"])
        self.assertEqual(set(old["files"]), set(new["files"]))
        changed = set()
        for name, row in new["files"].items():
            self.assertEqual(old["files"][name]["baseSha256"], row["baseSha256"])
            if old["files"][name]["candidateSha256"] != row["candidateSha256"]:
                changed.add(name)
        self.assertEqual({"include/gambit.h.in", "lib/setup.c"}, changed)
        self.assertEqual(hashlib.sha256((ROOT / new["patch"]).read_bytes()).hexdigest(),
                         new["patchSha256"])
        for key in ("runtimeAdmitted", "releaseAdmitted", "configuredToolchainReproduced"):
            self.assertFalse(new[key])

    def test_object_recipe_keeps_default_profile_and_negative_control(self):
        recipe = json.loads((ROOT / "evidence/research/vm-registry-reader-lease/"
                            "pending-join-bazel-objects.recipe.json").read_text())
        steps = {step["id"]: step for step in recipe["steps"]}
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertEqual("evidence/fixtures/gerbil-bazel-build-profile/profile.json",
                         steps["configure"]["arguments"]["buildProfile"])
        self.assertNotIn("cOptimization", steps["configure"]["arguments"])
        self.assertTrue(steps["pending-count-only-control"]["arguments"]["negative"])
        self.assertIn("pending-safe", steps["configure"]["dependsOn"])
        self.assertEqual(90, steps["setup-object"]["budgetSeconds"])
        self.assertEqual(90, steps["mem-object"]["budgetSeconds"])
