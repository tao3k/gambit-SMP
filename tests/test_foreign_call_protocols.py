"""Qualified foreign-call designs and source observations, not SMP admission."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import bundle_facts


BASE = "evidence/fixtures/callback-return-owned-result"
RESULTS = "evidence/model-results/fixtures/callback-return-owned-result"
SOURCE_RESULTS = "evidence/source-results/fixtures/callback-return-owned-result"


class ForeignCallProtocolTests(unittest.TestCase):
    def check_bundle(self, manifest_name, result_name, controls):
        manifest = f"{BASE}/{manifest_name}.json"
        receipt_path = f"{RESULTS}/{result_name}/receipt.json"
        facts, _ = bundle_facts(ROOT, manifest, receipt_path)
        self.assertEqual(len(facts["protocol_control"]), len(controls))
        self.assertEqual(len(facts["protocol_checked"]), 1)
        receipt = json.loads((ROOT / receipt_path).read_text())
        negative = [row for row in receipt["results"] if row["variant"] == "old"]
        self.assertEqual({row["invariant"] for row in negative}, controls)
        for row in negative:
            self.assertTrue(row["accepted"])
            self.assertFalse(row["timeout"])
            self.assertEqual(digest((ROOT / receipt_path).parent / row["trace"]),
                             row["traceSha256"])
        positive = [row for row in receipt["results"] if row["variant"] == "protocol"]
        self.assertEqual(len(positive), 1)
        self.assertTrue(positive[0]["accepted"])
        self.assertFalse(positive[0]["timeout"])
        self.assertEqual(positive[0]["temporal"], "completion")
        self.assertEqual(positive[0]["states"]["queued"], 0)
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])

    def test_admission_races_and_failure_cleanup_have_counterexamples(self):
        self.check_bundle("admission-contract", "foreign-call-admission", {
            "admissionSafe", "progressEnabled", "allocationRollback",
            "unwindRollback", "retirementSafe"})
        manifest = json.loads((ROOT / f"{BASE}/admission-contract.json").read_text())
        obligations = manifest["cases"][0]["openObligations"]
        self.assertIn("current_origin_exception_cleanup_source_refinement", obligations)
        self.assertIn("atomic_acquire_close_memory_order", obligations)
        self.assertIn("full_native_bootstrap_gerbil_performance_stability", obligations)

    def test_retirement_composes_actual_models_without_native_claim(self):
        self.check_bundle("retirement-contract", "retirement-composition", {
            "ownerAlive", "markerLifetime", "ownerGeneration", "progressEnabled"})

    def test_nested_unwind_keeps_origin_and_vm_fatal_routing_distinct(self):
        self.check_bundle("nested-unwind-contract", "nested-unwind-contract", {
            "innerDrained", "ownerCleanup", "exactOnce", "honestError", "retirementSafe"})
        manifest = json.loads((ROOT / f"{BASE}/nested-unwind-contract.json").read_text())
        case = manifest["cases"][0]
        self.assertEqual(case["composes"], [])
        self.assertIn("recoverable_origin_route_source_refinement", case["openObligations"])
        self.assertIn("fatal_vm_shutdown_versus_callback_unwind", case["openObligations"])

    def test_sfun_nonlocal_throw_observation_remains_a_resource_gap(self):
        folder = ROOT / SOURCE_RESULTS / "sfun-tail-unwind"
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        self.assertFalse(archive["runtimeAdmitted"])
        for path, expected in archive["files"].items():
            self.assertEqual(digest(folder / path), expected)
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertTrue(receipt["checksPassed"])
        self.assertTrue(receipt["identityUnchanged"])
        self.assertFalse(receipt["accepted"])
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertFalse(receipt["releaseAdmitted"])
        self.assertEqual(receipt["sourceLockSha256"], digest(ROOT / BASE / "source.lock.json"))
        self.assertEqual(receipt["sourceSha256"],
                         digest(ROOT / "models/gambit/native/sfun_tail_unwind.c"))
        for field in ("build", "observation"):
            row = receipt[field]
            self.assertEqual(row["exit"], 0)
            self.assertFalse(row["timeout"])
            self.assertTrue(row["group_quiescent"])
            self.assertEqual(row["stderr"], "")
        self.assertEqual(receipt["observation"]["stdout"].splitlines(), [
            "SFUN-TAIL:mode=0,made=1,killed=1,live=0,caught=0",
            "SFUN-TAIL:mode=1,made=0,killed=0,live=0,caught=1",
            "SFUN-TAIL:mode=2,made=1,killed=0,live=1,caught=1"])

    def test_real_relocation_preserves_payload_in_all_four_controls(self):
        folder = ROOT / SOURCE_RESULTS / "physical-relocation-controls"
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        for path, expected in archive["files"].items():
            self.assertEqual(digest(folder / path), expected)
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertTrue(receipt["controlsPassed"])
        self.assertTrue(receipt["identityUnchanged"])
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertEqual({(r["migrate"], r["collect"]) for r in receipt["runs"]},
                         {(0, 0), (0, 1), (1, 0), (1, 1)})
        for row in receipt["runs"]:
            obs = row["observation"]
            self.assertEqual(obs["exit"], 0)
            self.assertFalse(obs["timeout"])
            self.assertTrue(obs["group_quiescent"])
            self.assertEqual(obs["stderr"], "")
            moved = int(bool(row["migrate"] and row["collect"]))
            self.assertIn(f"moved={moved},intact=1,threw=0,error=0", obs["stdout"])

    def test_exact_generated_result_slot_is_in_root_map(self):
        folder = ROOT / SOURCE_RESULTS / "generated-result-root-map"
        receipt = json.loads((folder / "receipt.json").read_text())
        for path, expected in receipt["files"].items():
            self.assertEqual(digest(folder / path), expected)
        frame = receipt["frame"]
        space = ((frame["size"] + frame["reserve"] + frame["alignment"] - 1)
                 // frame["alignment"]) * frame["alignment"]
        self.assertEqual(space, frame["frameSpace"])
        self.assertEqual(frame["resultSavedSlot"], frame["resultReloadedSlot"])
        self.assertTrue(frame["gcmap"] & (1 << (frame["resultSavedSlot"] - 1)))
        helper = (folder / "return-helper.c").read_text()
        self.assertIn("___SET_STK(2,___R2)", helper)
        self.assertIn("___SET_R1(___STK(-5))", helper)
        self.assertEqual(1 + 2, frame["resultSavedSlot"])
        self.assertEqual(space - 5, frame["resultReloadedSlot"])
        self.assertEqual(receipt["physicalRelocationReceiptSha256"],
                         digest(ROOT / SOURCE_RESULTS / "physical-relocation-controls/receipt.json"))
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertIn("all_generated_root_sites_and_registers", receipt["openObligations"])

    def test_native_nested_errors_arrive_but_sfun_tail_cleanup_is_bypassed(self):
        for name in ("nested-unwind-controls", "nested-marker-controls"):
            folder = ROOT / SOURCE_RESULTS / name
            archive = json.loads((folder / "archive.json").read_text())
            self.assertTrue(archive["archiveOnly"])
            for path, expected in archive["files"].items():
                self.assertEqual(digest(folder / path), expected)
            receipt = json.loads((folder / "receipt.json").read_text())
            self.assertFalse(receipt["accepted"])
            self.assertFalse(receipt["runtimeAdmitted"])
            self.assertTrue(receipt["identityUnchanged"])
            self.assertEqual(receipt["build"]["exit"], 0)
            self.assertEqual({(r["migrate"], r["fail"]) for r in receipt["runs"]},
                             {(0, 0), (0, 1), (1, 0), (1, 1)})
            for row in receipt["runs"]:
                obs = row["observation"]
                self.assertEqual(obs["exit"], 0)
                self.assertFalse(obs["timeout"])
                self.assertTrue(obs["group_quiescent"])
                self.assertEqual(obs["stderr"], "")
                self.assertIn("result=-1,threw=1,error=" if row["fail"] else
                              "result=42,threw=0,error=0", obs["stdout"])
                if name == "nested-marker-controls":
                    self.assertEqual(obs["stdout"].count(
                        f"made=2,killed={0 if row['fail'] else 2}"), 2)
