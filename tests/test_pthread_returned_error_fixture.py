import json
import unittest
from tests.fixture_history import historical_observation

from gambit_smp.framework import ROOT, digest


class PthreadReturnedErrorFixtureTests(unittest.TestCase):
    fixture = "pthread-returned-error-identity"

    def test_source_lock_preserves_parent(self):
        parent = json.loads((ROOT / "evidence/fixtures/interrupt-prefix-owned-lifecycle/source.lock.json").read_text())
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        self.assertEqual(parent["revision"], lock["revision"])
        self.assertEqual(set(parent["files"]) | {"lib/os_thread.c"}, set(lock["files"]))
        for name, identity in parent["files"].items():
            self.assertEqual(identity, lock["files"][name])
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        patch = (ROOT / lock["patch"]).read_text()
        self.assertIn("+  int err = pthread_join (thread->thread_id, NULL);", patch)
        self.assertIn("+    return ___FIX(___ERRNO_ERR(err));", patch)
        self.assertFalse(lock["runtimeAdmitted"])

    def test_recipe_uses_locked_parent_and_same_assertions(self):
        recipe = json.loads((ROOT / f"evidence/research/{self.fixture}/wrappers.recipe.json").read_text())
        steps = {s["id"]: s for s in recipe["steps"]}
        self.assertEqual("evidence/fixtures/interrupt-prefix-owned-lifecycle/source.lock.json",
                         steps["parent-source"]["arguments"]["sourceLock"])
        for role in ("candidate", "parent"):
            rows = steps[role + "-workspace"]["arguments"]["files"]
            self.assertEqual("models/gambit/native/pthread_returned_error.c", rows[0]["origin"]["path"])
            self.assertEqual(digest(ROOT / rows[0]["origin"]["path"]), rows[0]["sha256"])
            self.assertEqual({"lib/os_thread.c", "lib/os_base.c", "include/gambit.h.in"},
                             {r["origin"]["path"] for r in rows[1:]})
        self.assertEqual(1, steps["parent-test"]["arguments"]["cases"][0]["expectedExit"])

    def test_observations_do_not_grant_runtime_admission(self):
        summary = historical_observation(self, self.fixture)
        self.assertNotRegex(json.dumps(summary), r"/(?:Users|home)/")
        for key in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"):
            self.assertFalse(summary[key])
        self.assertEqual({"checks": 18, "invalid": 0}, summary["wrapperCases"]["candidate"])
        self.assertEqual({"checks": 18, "invalid": 12}, summary["wrapperCases"]["parent"])
        self.assertEqual("DENY", summary["runs"]["objects-sandbox-deny"]["outcome"])
        self.assertEqual("PASS", summary["runs"]["objects"]["outcome"])
        for step in summary["runs"]["objects"]["steps"]:
            self.assertEqual("PASS", step["outcome"])
