import json
import unittest
from tests.fixture_history import historical_observation

from gambit_smp.framework import ROOT, digest


class SyncAtomicPublicationFixtureTests(unittest.TestCase):
    fixture = "sync-message-atomic-publication"

    def test_delta_preserves_header_and_lifecycle(self):
        parent = json.loads((ROOT / "evidence/fixtures/resize-result-startup-commit/source.lock.json").read_text())
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        self.assertEqual(parent["revision"], lock["revision"])
        self.assertEqual(set(parent["files"]), set(lock["files"]))
        self.assertEqual({"lib/setup.c"}, {p for p in lock["files"] if parent["files"][p] != lock["files"][p]})
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        patch = (ROOT / lock["patch"]).read_text()
        self.assertIn("+__atomic_store_n (&(var), SYNC_WAITING, __ATOMIC_RELAXED)", patch)
        self.assertIn("+#define SYNC_LOAD_MSG(var) __atomic_load_n (&(var), __ATOMIC_ACQUIRE)", patch)
        self.assertIn("+     __atomic_store_n (&ps->field, val, __ATOMIC_RELEASE);", patch)
        self.assertFalse(lock["runtimeAdmitted"])

    def test_real_fields_and_no_concurrent_parent_control(self):
        recipe = json.loads((ROOT / f"evidence/research/{self.fixture}/tree-loop.recipe.json").read_text())
        steps = {s["id"]: s for s in recipe["steps"]}
        for role in ("candidate", "parent"):
            files = steps[role + "-workspace"]["arguments"]["files"]
            self.assertEqual(digest(ROOT / "models/gambit/native/sync_atomic_tree.c"), files[0]["sha256"])
            row = next(r for r in files if r["target"] == "flag-fields-source.inc")
            self.assertEqual("include/gambit.h.in", row["origin"]["path"])
        control = steps["parent-test"]["arguments"]["cases"]
        self.assertEqual(1, len(control))
        self.assertEqual([4], control[0]["integers"])
        self.assertEqual(1, control[0]["expectedExit"])
        source = (ROOT / "models/gambit/native/sync_atomic_tree.c").read_text()
        self.assertNotIn("_Atomic int sync_id", source)
        self.assertIn('#include "flag-fields-source.inc"', source)
        self.assertIn("scenario >= 5 ? 1000 : 1", source)
        self.assertIn("atomic_fetch_add(&bad_results, 1)", source)

    def test_evidence_boundary_and_repeated_round_results(self):
        summary = historical_observation(self, self.fixture)
        self.assertNotRegex(json.dumps(summary), r"/(?:Users|home)/")
        for key in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"):
            self.assertFalse(summary[key])
        self.assertEqual({"reads": 1, "writes": 2, "invalid": 0}, summary["cases"]["atomic-access-contract"])
        self.assertEqual({"reads": 0, "writes": 0, "invalid": 1}, summary["parentCase"])
        self.assertEqual(11, summary["cases"]["alternating-status-1000-rounds"]["result"])
        self.assertTrue(all(case["invalid"] == 0 for case in summary["cases"].values()))
        self.assertTrue(all(r["outcome"] == "PASS" for r in summary["runs"].values()))
        seed = summary["runs"]["seed"]
        self.assertEqual("host-auto", seed["processorSelection"])
        self.assertGreater(seed["processors"], 0)
        self.assertFalse(seed["scmRegenerationEstablished"])
        self.assertEqual([], seed["recursiveBuildErrors"])
        self.assertEqual({"gsi/gsi", "gsc/gsc", "lib/libgambit.a"}, set(seed["artifacts"]))
        regenerated = summary["runs"]["system-regeneration"]
        self.assertEqual("lib/_system.scm", regenerated["module"])
        self.assertTrue(regenerated["inputsStable"])
        self.assertFalse(regenerated["generatedCLinked"])
        self.assertFalse(regenerated["fullTwoPassBootstrapEstablished"])
        self.assertRegex(regenerated["generatedSha256"], r"^[0-9a-f]{64}$")
        core = summary["runs"]["source-core"]
        self.assertTrue(core["scmRegenerationEstablished"])
        self.assertTrue(core["schemeInputsStable"])
        self.assertEqual(46, len(core["generatedSources"]))
        self.assertEqual(set(core["generatedSources"]), set(core["generatedHashes"]))
        self.assertEqual([], core["missingGeneratedSources"])
        self.assertEqual([], core["recursiveBuildErrors"])
        self.assertFalse(core["fullTwoPassBootstrapEstablished"])
        attempted = summary["attempts"]["source-core-shared-budget"]
        self.assertEqual("DENY", attempted["outcome"])
        self.assertEqual("evidence-provider-interface", attempted["denialClass"])
        self.assertTrue(attempted["scmRegenerationEstablished"])
        self.assertFalse(attempted["runtimeAdmitted"])
        self.assertEqual(attempted["capacity"]["availableProcessors"], attempted["capacity"]["makeJobs"])
        self.assertEqual(1, attempted["capacity"]["compilerProcessors"])
        model = json.loads((ROOT / summary["modelReceipt"]).read_text())
        self.assertTrue(model["accepted"])
        self.assertFalse(model["runtimeAdmitted"])
