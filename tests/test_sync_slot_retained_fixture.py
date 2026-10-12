import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import checked_rows
from gambit_smp.verify_protocols import load_manifest


class RetainedSyncFixtureTests(unittest.TestCase):
    fixture = "sync-slot-retained-resources"

    def test_interrupt_prefix_composes_sync_actions_and_preserves_early_global_owner(self):
        manifest = load_manifest(ROOT / f"evidence/fixtures/{self.fixture}/interrupt-prefix-design-contract.json")
        receipt = ROOT / f"evidence/model-results/fixtures/{self.fixture}/interrupt-prefix-early-global-contract/receipt.json"
        rows = checked_rows(ROOT, manifest, receipt)[0][1]
        self.assertEqual(5, len(rows))
        self.assertEqual(4, sum(row["variant"] == "old" and row["exit"] == 1 for row in rows))
        positive = next(row for row in rows if row["variant"] == "protocol")
        self.assertEqual({"generated": 340, "distinct": 208, "queued": 0}, positive["states"])
        self.assertEqual("progress", positive["temporal"])
        self.assertEqual(0, positive["exit"])
        dependency = "models/gambit/sync_slot_retained_resources.qnt"
        self.assertEqual(digest(ROOT / dependency), manifest["contextInputs"][dependency])
        self.assertEqual(["sync_slot_retained_resources.qnt"], manifest["cases"][0]["dependencies"])
        model = (ROOT / "models/gambit/interrupt_prefix_retained_composition.qnt").read_text()
        for action in ("lock", "publish", "unlock", "signal", "receiveOld", "childExit", "joinAndReuse", "receiveNew", "newChildExit", "sealVmAdmission", "destroyVmResources"):
            self.assertIn("S::" + action, model)
        self.assertIn("early_global_prefix_failure_cleanup", manifest["cases"][0]["openObligations"])
        self.assertIn("interrupt_ownership_source_repair", manifest["cases"][0]["openObligations"])

    def test_failed_composition_conversions_are_not_accepted_counterexamples(self):
        base = ROOT / f"evidence/model-results/fixtures/{self.fixture}"
        for name in ("interrupt-prefix-conversion-deny", "interrupt-prefix-dependency-deny", "interrupt-prefix-binding-deny"):
            record = json.loads((base / name / "receipt.json").read_text())
            self.assertFalse(record["accepted"])
            self.assertFalse(record["runtimeAdmitted"])
            self.assertTrue((base / name / "archive.json").is_file())

    def test_source_delta_preserves_parent_and_changes_only_sync_setup_and_abi(self):
        parent = json.loads((ROOT / "evidence/fixtures/pstate-scan-lock-owned-lifecycle/source.lock.json").read_text())
        lock = json.loads((ROOT / f"evidence/fixtures/{self.fixture}/source.lock.json").read_text())
        self.assertEqual(parent["revision"], lock["revision"])
        self.assertEqual(set(parent["files"]), set(lock["files"]))
        self.assertEqual({"lib/setup.c", "include/gambit.h.in"},
                         {name for name in lock["files"] if lock["files"][name] != parent["files"][name]})
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        self.assertFalse(lock["runtimeAdmitted"])
        self.assertFalse(lock["releaseAdmitted"])
        patch = (ROOT / lock["patch"]).read_text()
        self.assertIn("+    ___BOOL sync_resources_ready;", patch)
        self.assertIn("+      ___PSTATE_FROM_PROCESSOR_ID(i,___vms)->sync_resources_ready = 0;", patch)
        self.assertIn("+      cleanup_sync_op_pstate (___PSTATE_FROM_PROCESSOR_ID(i,___vms));", patch)

    def test_native_receipts_keep_denial_and_real_posix_reuse_distinct(self):
        summary = json.loads((ROOT / f"evidence/source-results/fixtures/{self.fixture}/observation.json").read_text())
        for path, expected in summary["inputs"].items():
            self.assertEqual(expected, digest(ROOT / path), path)
        self.assertFalse(summary["runtimeAdmitted"])
        self.assertFalse(summary["nativeGcPassed"])
        self.assertNotRegex(json.dumps(summary), r"/(?:Users|home)/")
        denied = summary["runs"]["callees"]
        self.assertEqual("DENY", denied["outcome"])
        self.assertEqual(["verdict"], [step["id"] for step in denied["steps"] if step["outcome"] != "PASS"])
        accepted = summary["runs"]["callees-exact-inventory"]
        self.assertEqual("PASS", accepted["outcome"])
        cases = [step for step in accepted["steps"] if step["id"].endswith("-test")]
        self.assertEqual(4, len(cases))
        for step in cases:
            self.assertEqual([1 if step["id"].startswith("parent-") else 0], [c["exit"] for c in step["commands"]])
            self.assertTrue(all(not c["timeout"] for c in step["commands"]))
        self.assertEqual("PASS", summary["runs"]["objects"]["outcome"])
        harness = (ROOT / "models/gambit/native/sync_slot_retained_resources.c").read_text()
        for call in ("pthread_mutex_lock", "pthread_cond_signal", "pthread_join"):
            self.assertIn(call, harness)

    def test_correction_changes_only_expected_inventory_not_source_or_budgets(self):
        root = ROOT / f"evidence/research/{self.fixture}"
        rejected = json.loads((root / "callees-inventory-deny.json").read_text())
        corrected = json.loads((root / "callees.recipe.json").read_text())
        self.assertNotEqual(rejected["steps"][-1]["arguments"]["expected"], corrected["steps"][-1]["arguments"]["expected"])
        rejected["steps"][-1]["arguments"]["expected"] = corrected["steps"][-1]["arguments"]["expected"]
        self.assertEqual(rejected, corrected)
        expected = corrected["steps"][-1]["arguments"]["expected"]
        self.assertEqual(2, len(expected["bindings"]))
        self.assertEqual(4, len(expected["controls"]))
        self.assertTrue(all(len(row) == 4 and type(row[2]) is bool for row in expected["controls"]))
