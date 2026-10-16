"""Bind cleanup recovery probes to the immutable all-flags producer."""
import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESEARCH = ROOT / "evidence/research/vm-registry-reader-lease"


class GlobalCleanupCandidateTests(unittest.TestCase):
    def test_preflight_successor_changes_only_setup(self):
        old = json.loads((ROOT / "evidence/fixtures/vm-pending-join-retention/source.lock.json").read_text())
        new = json.loads((ROOT / "evidence/fixtures/vm-global-cleanup-preflight/source.lock.json").read_text())
        self.assertEqual(old["revision"], new["revision"])
        self.assertEqual(set(old["files"]), set(new["files"]))
        changed = []
        for name, row in new["files"].items():
            self.assertEqual(old["files"][name]["baseSha256"], row["baseSha256"])
            if old["files"][name]["candidateSha256"] != row["candidateSha256"]:
                changed.append(name)
        self.assertEqual(["lib/setup.c"], changed)
        self.assertEqual(new["patchSha256"], hashlib.sha256((ROOT / new["patch"]).read_bytes()).hexdigest())

    def test_both_native_recipes_use_current_completed_producer_without_wider_budget(self):
        for name in ("global-cleanup-host-topology-grid", "pending-join-native-recovery"):
            recipe = json.loads((RESEARCH / (name + ".recipe.json")).read_text())
            steps = {s["id"]: s for s in recipe["steps"]}
            self.assertEqual(300, recipe["budgetSeconds"])
            self.assertEqual(120, steps["independent-vms"]["budgetSeconds"])
            self.assertEqual("evidence/research/vm-registry-reader-lease/global-cleanup-completed-producer.json",
                             steps["producer"]["arguments"]["producer"])
            self.assertEqual("evidence/fixtures/vm-global-cleanup-preflight/source.lock.json",
                             steps["source"]["arguments"]["sourceLock"])
            self.assertFalse(any(s["capability"] in {"gambit.configure", "gambit.bootstrap"}
                                 for s in recipe["steps"]))

    def test_fault_recipe_requires_both_models_and_observed_native_success(self):
        recipe = json.loads((RESEARCH / "pending-join-native-recovery.recipe.json").read_text())
        steps = {s["id"]: s for s in recipe["steps"]}
        native = steps["independent-vms"]
        for prefix in ("pending", "global"):
            self.assertIn(prefix + "-safe", native["dependsOn"])
            self.assertIn(prefix + "-count-only-control", native["dependsOn"])
            self.assertTrue(steps[prefix + "-count-only-control"]["arguments"]["negative"])
        self.assertEqual("PENDING-JOIN-RECOVERY:PASS\n", native["arguments"]["stdout"])
        fixture = (ROOT / native["arguments"]["program"]).read_text()
        self.assertIn('getenv("GAMBIT_SMP_AVAILABLE_CPUS")', fixture)
        self.assertIn("injected != 1", fixture)
        self.assertIn("injected != 2", fixture)
        self.assertIn("___cleanup_checked()", fixture)

    def test_vm_owned_fault_successor_arms_current_vm_not_os_thread(self):
        recipe = json.loads((RESEARCH / "vm-owned-pending-join-native-recovery.recipe.json").read_text())
        step = next(s for s in recipe["steps"] if s["id"] == "independent-vms")
        fixture = (ROOT / step["arguments"]["program"]).read_text()
        self.assertIn('(define arm! (c-lambda () void "arm_current_vm();"))', fixture)
        self.assertNotIn('"armed = 1;"', fixture)
        self.assertIn("atomic_exchange(&w->armed, 0)", fixture)
        self.assertIn("atomic_load(&w->injected) != 2", fixture)
        self.assertEqual(120, step["budgetSeconds"])

    def test_errno_successor_checks_returned_error_not_exception(self):
        recipe = json.loads((RESEARCH / "pending-join-errno-native-recovery.recipe.json").read_text())
        step = next(s for s in recipe["steps"] if s["id"] == "independent-vms")
        fixture = (ROOT / step["arguments"]["program"]).read_text()
        self.assertIn("___FIX(___ERRNO_ERR(EINVAL))", fixture)
        self.assertIn("(equal? (##current-vm-resize ##startup-processor! 1) expected-join-error)", fixture)
        self.assertNotIn("with-exception-catcher", fixture)
        self.assertIn("atomic_load(&w->injected) != 2", fixture)
        self.assertIn("___GSTATE->setup_state != 1", fixture)
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertEqual(120, step["budgetSeconds"])

    def test_complete_interpreted_successor_preserves_every_file_and_budget(self):
        grid = ROOT / "evidence/research/smp-threaded-vm-native-grid"
        old = json.loads((grid / "bazel-profile-interpreted.recipe.json").read_text())
        new = json.loads((grid / "global-cleanup-interpreted.recipe.json").read_text())
        old_steps = {s["id"]: s for s in old["steps"]}
        new_steps = {s["id"]: s for s in new["steps"]}
        self.assertEqual(old_steps["native-gsi"], new_steps["native-gsi"])
        self.assertEqual(379, len(new_steps["native-gsi"]["arguments"]["expectedFiles"]))
        self.assertEqual(300, new["budgetSeconds"])
        intent = json.loads((grid / "global-cleanup-gsi-intent.json").read_text())
        lock = json.loads((ROOT / "evidence/fixtures/vm-global-cleanup-preflight/source.lock.json").read_text())
        for entry in intent["failures"]:
            for change in entry["changes"]:
                if change["kind"] == "source":
                    self.assertEqual(lock["files"][change["path"]]["candidateSha256"], change["after"])
            for claim in entry["claims"]:
                self.assertEqual(hashlib.sha256((ROOT / claim["evidence"]["path"]).read_bytes()).hexdigest(),
                                 claim["evidence"]["sha256"])

    def test_topology_observation_preserves_cycles_and_assertions(self):
        recipe = json.loads((RESEARCH / "global-cleanup-topology-observation.recipe.json").read_text())
        step = next(s for s in recipe["steps"] if s["id"] == "independent-vms")
        fixture = (ROOT / step["arguments"]["program"]).read_text()
        self.assertEqual(300, recipe["budgetSeconds"])
        self.assertEqual(120, step["budgetSeconds"])
        self.assertIn("fixture_cycles = cpu > 16 ? (int)cpu : 16", fixture)
        self.assertIn("count <= maximum", fixture)
        self.assertIn("cross-VM root corruption", fixture)
        self.assertIn("CLOCK_MONOTONIC", fixture)
        self.assertIn("cycle * 100 + phase", fixture)
