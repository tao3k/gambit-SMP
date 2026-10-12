import json
import unittest
from tests.fixture_history import historical_observation

from gambit_smp.framework import ROOT, digest


class ResizeResultStartupFixtureTests(unittest.TestCase):
    fixture = "resize-result-startup-commit"

    def test_delta_preserves_parent_except_dispatcher(self):
        parent = json.loads((ROOT / "evidence/fixtures/pthread-returned-error-identity/source.lock.json").read_text())
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        self.assertEqual(parent["revision"], lock["revision"])
        self.assertEqual(set(parent["files"]), set(lock["files"]))
        self.assertEqual({"lib/setup.c"}, {p for p in lock["files"] if parent["files"][p] != lock["files"][p]})
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        patch = (ROOT / lock["patch"]).read_text()
        self.assertIn("+#define OP_VM_RESIZE_RESULT        OP_MAKE( 4,0)", patch)
        self.assertIn("+        barrier_sync_op (___PSP &result);", patch)
        self.assertNotIn("-              ___thread_join (t); /* ignore error */", patch)
        self.assertFalse(lock["runtimeAdmitted"])

    def test_full_function_projections_and_parent_control(self):
        recipe = json.loads((ROOT / f"evidence/research/{self.fixture}/tree-loop.recipe.json").read_text())
        steps = {s["id"]: s for s in recipe["steps"]}
        for role in ("candidate", "parent"):
            files = steps[role + "-workspace"]["arguments"]["files"]
            self.assertEqual(digest(ROOT / "models/gambit/native/resize_result_startup.c"), files[0]["sha256"])
            self.assertEqual({"tree-source.inc", "execute-source.inc", "loop-source.inc", "startup-source.inc"},
                             {r["target"] for r in files[1:]})
            self.assertTrue(steps[role + "-build"]["arguments"]["pthread"])
        self.assertEqual("evidence/fixtures/pthread-returned-error-identity/source.lock.json",
                         steps["parent-source"]["arguments"]["sourceLock"])
        self.assertEqual(1, steps["parent-test"]["arguments"]["cases"][0]["expectedExit"])

    def test_model_and_native_summary_remain_nonadmitted(self):
        summary = historical_observation(self, self.fixture)
        self.assertNotRegex(json.dumps(summary), r"/(?:Users|home)/")
        for key in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"):
            self.assertFalse(summary[key])
        self.assertEqual("DENY", summary["runs"]["projection-deny"]["outcome"])
        self.assertEqual("PASS", summary["runs"]["tree-loop"]["outcome"])
        self.assertEqual("PASS", summary["runs"]["objects"]["outcome"])
        self.assertEqual({"result": 11, "population": 2, "bodies": 0, "invalid": 0},
                         summary["cases"]["setup-error"])
        self.assertEqual({"result": 0, "population": 3, "bodies": 1, "invalid": 0},
                         summary["cases"]["growth-startup"])
        receipt = json.loads((ROOT / summary["modelReceipt"]).read_text())
        self.assertTrue(receipt["accepted"])
        self.assertFalse(receipt["runtimeAdmitted"])
        source = (ROOT / "models/gambit/resize_commit_startup_round.qnt").read_text()
        self.assertIn('action initLocalResult = round\' = initial(1, true, 1, 11)', source)
