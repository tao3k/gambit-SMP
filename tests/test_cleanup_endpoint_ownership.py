"""Source/fixture identity boundaries, not native cleanup semantics."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.recipes import load


class CleanupEndpointOwnershipTests(unittest.TestCase):
    def test_successor_preserves_prior_lock_and_only_changes_setup_bytes(self):
        prior = json.loads((ROOT / "evidence/fixtures/foreign-origin-lease-admission/source.lock.json").read_text())
        current = json.loads((ROOT / "evidence/fixtures/foreign-origin-lifecycle-ownership/source.lock.json").read_text())
        self.assertEqual(prior["revision"], current["revision"])
        self.assertEqual(set(prior["files"]), set(current["files"]))
        changed = {name for name in prior["files"] if prior["files"][name] != current["files"][name]}
        self.assertEqual({"lib/setup.c"}, changed)
        self.assertEqual(current["patchSha256"], digest(ROOT / current["patch"]))
        self.assertFalse(current["runtimeAdmitted"])
        self.assertFalse(current["releaseAdmitted"])

    def test_model_inventory_preserves_both_faulty_policy_controls(self):
        recipe, _ = load(ROOT, ROOT / "evidence/research/vm-registry-reader-lease/cleanup-endpoint-ownership.recipe.json")
        controls = {s["arguments"]["initializer"] for s in recipe["steps"]
                    if s["capability"] == "quint.verify" and s["arguments"]["negative"]}
        self.assertEqual({"initReacquire", "initLegacyReturns"}, controls)
        tests = next(s for s in recipe["steps"] if s["capability"] == "quint.test")
        self.assertEqual(5, len(tests["arguments"]["expectedTests"]))

    def test_supplemental_object_does_not_change_default_profile(self):
        recipe, _ = load(ROOT, ROOT / "evidence/research/vm-registry-reader-lease/foreign-origin-lifecycle-ownership-objects.recipe.json")
        configure = next(s for s in recipe["steps"] if s["id"] == "configure")
        self.assertEqual("evidence/fixtures/gerbil-bazel-build-profile/profile.json",
                         configure["arguments"]["buildProfile"])
        objects = [s for s in recipe["steps"] if s["capability"] == "gambit.object"]
        self.assertEqual(4, len(objects))
        self.assertEqual(1, sum(bool(s["arguments"].get("defines")) for s in objects))
        self.assertFalse(any(s["capability"] in {"gambit.bootstrap", "gambit.executable-test"}
                             for s in recipe["steps"]))


if __name__ == "__main__":
    unittest.main()
