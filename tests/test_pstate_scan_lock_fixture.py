import json
import unittest
from tests.fixture_history import historical_observation

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import checked_rows
from gambit_smp.verify_protocols import load_manifest


class ScanLockFixtureTests(unittest.TestCase):
    fixture = "pstate-scan-lock-owned-lifecycle"

    def test_retained_sync_design_is_checked_without_source_repair_admission(self):
        manifest = load_manifest(ROOT / f"evidence/fixtures/{self.fixture}/retained-sync-design-contract.json")
        receipt = ROOT / f"evidence/model-results/fixtures/{self.fixture}/retained-sync-design-contract/receipt.json"
        rows = checked_rows(ROOT, manifest, receipt)[0][1]
        self.assertEqual(4, len(rows))
        self.assertEqual(3, sum(row["variant"] == "old" and row["exit"] == 1 for row in rows))
        positive = next(row for row in rows if row["variant"] == "protocol")
        self.assertEqual({"generated": 73, "distinct": 41, "queued": 0}, positive["states"])
        self.assertEqual("progress", positive["temporal"])
        self.assertEqual(0, positive["exit"])
        self.assertIn("once_initialized_slot_source_repair", manifest["cases"][0]["openObligations"])
        self.assertIn("full_vm_admission_and_sender_drain", manifest["cases"][0]["openObligations"])

    def test_modified_system_module_is_regenerated_by_same_campaign_compiler(self):
        summary = historical_observation(self, self.fixture)
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        generated = summary["systemRegeneration"]
        observation = generated["observation"]
        self.assertEqual("lib/_system.scm", observation["module"])
        self.assertEqual(lock["files"]["lib/_system.scm"]["candidateSha256"], observation["inputs"]["lib/_system.scm"])
        self.assertEqual(generated["sameCampaignSeedArtifacts"]["gsc/gsc"], observation["inputs"]["gsc/gsc"])
        self.assertTrue(observation["inputsStable"])
        self.assertGreater(generated["generatedBytes"], 0)
        self.assertRegex(observation["generatedSha256"], r"^[0-9a-f]{64}$")
        self.assertFalse(observation["runtimeAdmitted"])
        run = summary["runs"]["system-regeneration"]
        self.assertEqual("PASS", run["outcome"])
        self.assertLess(run["wholeSeconds"], run["budgetSeconds"])
        command = next(command for step in run["steps"] if step["id"] == "system"
                       for command in step["commands"] if command["stage"] == "regenerate-module")
        self.assertEqual(0, command["exit"])
        self.assertFalse(command["timeout"])
        for flag in ("--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"):
            self.assertIn(flag, generated["configuredFlags"])

    def test_linked_seed_does_not_qualify_scheme_regeneration(self):
        summary = json.loads((ROOT / f"evidence/source-results/fixtures/{self.fixture}/observation.json").read_text())
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        seed = summary["linkedSeed"]
        self.assertEqual("host-auto", seed["processorSelection"])
        self.assertGreater(seed["processors"], 0)
        self.assertEqual({"gsi/gsi", "gsc/gsc", "lib/libgambit.a"}, set(seed["artifacts"]))
        self.assertEqual({name: value["candidateSha256"] for name, value in lock["files"].items()}, seed["lockedSourceFiles"])
        for name, value in seed["runtimeSourceFiles"].items():
            self.assertEqual(seed["lockedSourceFiles"][name], value)
        self.assertEqual([], seed["recursiveBuildErrors"])
        self.assertFalse(seed["scmRegenerationEstablished"])
        self.assertFalse(seed["runtimeAdmitted"])
        self.assertFalse(seed["releaseAdmitted"])
        accepted = summary["runs"]["seed"]
        self.assertEqual("PASS", accepted["outcome"])
        self.assertLess(accepted["wholeSeconds"], accepted["budgetSeconds"])
        for step in accepted["steps"]:
            self.assertEqual("PASS", step["outcome"])
            self.assertTrue(all(command["exit"] == 0 and not command["timeout"] for command in step["commands"]))
        recipe = json.loads((ROOT / f"evidence/research/{self.fixture}/seed.recipe.json").read_text())
        self.assertIn("gambit.seed-core", json.dumps(recipe))
        for flag in ("--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"):
            self.assertIn(flag, seed["configuredFlags"])

    def test_barrier_contract_checks_retained_live_queues_without_full_gc_admission(self):
        manifest = load_manifest(ROOT / f"evidence/fixtures/{self.fixture}/barrier-contract.json")
        receipt = ROOT / f"evidence/model-results/fixtures/{self.fixture}/barrier-contract/receipt.json"
        rows = checked_rows(ROOT, manifest, receipt)[0][1]
        self.assertEqual(3, len(rows))
        self.assertEqual(2, sum(row["variant"] == "old" and row["exit"] == 1 for row in rows))
        positive = next(row for row in rows if row["variant"] == "protocol")
        self.assertEqual(696, positive["states"]["distinct"])
        self.assertEqual(0, positive["states"]["queued"])
        self.assertEqual(0, positive["exit"])
        self.assertIn("gc_callback_scan_user_return", manifest["cases"][0]["openObligations"])

    def test_actual_barrier_native_control_is_not_a_compile_failure(self):
        summary = json.loads((ROOT / f"evidence/source-results/fixtures/{self.fixture}/observation.json").read_text())
        for name in ("barrier", "barrier-definition-range"):
            failed = summary["runs"][name]
            self.assertEqual("DENY", failed["outcome"])
            self.assertTrue(any(command["exit"] == 1 and command["stage"] == "c-build"
                for step in failed["steps"] for command in step["commands"]))
        accepted = summary["runs"]["barrier-locked-definition"]
        self.assertEqual("PASS", accepted["outcome"])
        cases = {step["id"]: step for step in accepted["steps"] if step["id"].endswith("-test")}
        self.assertEqual({"candidate-test", "negative-test"}, set(cases))
        for name, expected in (("candidate-test", 0), ("negative-test", 1)):
            self.assertEqual([expected], [command["exit"] for command in cases[name]["commands"]])
            self.assertTrue(all(not command["timeout"] for command in cases[name]["commands"]))
        fixture = (ROOT / "models/gambit/native/scan_barrier_quiescence.c").read_text()
        self.assertIn("sysconf(_SC_NPROCESSORS_ONLN)", fixture)
        self.assertNotRegex(json.dumps(summary), r"/(?:Users|home)/")
        self.assertFalse(summary["runtimeAdmitted"])

    def test_source_delta_keeps_the_preceding_constructor_and_binds_two_changes(self):
        parent = json.loads((ROOT / "evidence/fixtures/vm-constructor-owned-rollback/source.lock.json").read_text())
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        self.assertEqual(parent["revision"], lock["revision"])
        self.assertEqual(set(parent["files"]), set(lock["files"]))
        changed = {name for name in lock["files"] if lock["files"][name] != parent["files"][name]}
        self.assertEqual({"lib/mem.c", "include/gambit.h.in"}, changed)
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        self.assertFalse(lock["runtimeAdmitted"])

    def test_lifecycle_model_is_complete_but_not_caller_quiescence_proof(self):
        manifest = load_manifest(ROOT / f"evidence/fixtures/{self.fixture}/scan-lock-lifecycle-contract.json")
        receipt = ROOT / f"evidence/model-results/fixtures/{self.fixture}/scan-lock-lifecycle-contract/receipt.json"
        rows = checked_rows(ROOT, manifest, receipt)[0][1]
        self.assertEqual(5, len(rows))
        self.assertEqual(4, sum(row["variant"] == "old" and row["exit"] == 1 for row in rows))
        positive = next(row for row in rows if row["variant"] == "protocol")
        self.assertEqual({"generated": 271, "distinct": 203, "queued": 0}, positive["states"])
        self.assertEqual(0, positive["exit"])
        self.assertEqual("progress", positive["temporal"])
        self.assertIn("sync_barrier_scan_quiescence", manifest["cases"][0]["openObligations"])

    def test_actual_callee_receipts_preserve_control_and_inventory_denial(self):
        summary = json.loads((ROOT / f"evidence/source-results/fixtures/{self.fixture}/observation.json").read_text())
        self.assertFalse(summary["runtimeAdmitted"])
        self.assertFalse(summary["nativeGcPassed"])
        self.assertEqual("DENY", summary["runs"]["callees"]["outcome"])
        self.assertEqual("PASS", summary["runs"]["objects"]["outcome"])
        accepted = summary["runs"]["callees-exact-inventory"]
        self.assertEqual("PASS", accepted["outcome"])
        tests = [step for step in accepted["steps"] if step["id"].endswith("-test")]
        self.assertEqual(5, len(tests))
        for step in tests:
            expected = 1 if step["id"].startswith("negative") else 0
            self.assertEqual([expected], [command["exit"] for command in step["commands"]])
            self.assertTrue(all(not command["timeout"] for command in step["commands"]))
