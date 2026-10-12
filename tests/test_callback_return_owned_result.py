"""Source and model controls for callback result ownership, not full SMP."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.source_materialize import locked_source


class CallbackReturnOwnedResultTests(unittest.TestCase):
    lock = "evidence/fixtures/callback-return-owned-result/source.lock.json"

    def test_only_kernel_changes_against_cumulative_parent(self):
        parent = json.loads((ROOT / "evidence/fixtures/checked-cleanup-retained-error/source.lock.json").read_text())
        candidate = json.loads((ROOT / self.lock).read_text())
        self.assertEqual(parent["revision"], candidate["revision"])
        self.assertEqual(set(parent["files"]), set(candidate["files"]))
        changed = [name for name in candidate["files"] if
                   candidate["files"][name] != parent["files"][name]]
        self.assertEqual(changed, ["lib/_kernel.scm"])
        self.assertFalse(candidate["runtimeAdmitted"])
        self.assertFalse(candidate["releaseAdmitted"])

    def test_materialized_return_preserves_value_and_hook_arity(self):
        with locked_source(ROOT, self.lock) as (source, _):
            kernel = (source / "lib/_kernel.scm").read_text()
            self.assertIn("___SET_R2(___R1)\n         ___SET_R1(___VECTORELEM(unwind_destination, 1))\n         ___JUMPPRM(___SET_NARGS(2)", kernel)
            self.assertIn("(define-prim (##c-return-on-other-processor id result)", kernel)
            self.assertIn("(begin\n          (proc id)\n          result)", kernel)
            thread = (source / "lib/_thread.scm").read_text()
            self.assertIn("(##c-return-on-other-processor-hook-set!\n (lambda (id)\n   (##thread-migrate-to! id)))", thread)

    def test_model_manifest_keeps_native_and_gc_root_gaps(self):
        contract = json.loads((ROOT / "evidence/fixtures/callback-return-owned-result/contract.json").read_text())
        case = contract["cases"][0]
        self.assertEqual(case["oldInvariants"], ["resultPreserved", "rootCurrent"])
        self.assertIn("scheme_argument_root_and_generated_stack_map", case["openObligations"])
        self.assertIn("full_native_bootstrap_gerbil_acceptance", case["openObligations"])

    def native_receipt(self, name):
        folder = ROOT / "evidence/source-results/fixtures/callback-return-owned-result" / name
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        self.assertFalse(archive["runtimeAdmitted"])
        for path, expected in archive["files"].items():
            self.assertEqual(digest(folder / path), expected)
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertTrue(receipt["identityUnchanged"])
        self.assertEqual(receipt["build"]["exit"], 0)
        self.assertEqual({(r["migrate"], r["collect"]) for r in receipt["runs"]},
                         {(0, 0), (0, 1), (1, 0), (1, 1)})
        return receipt

    def test_baseline_migration_denials_remain_negative(self):
        receipt = self.native_receipt("forced-migration-baseline")
        for row in receipt["runs"]:
            obs = row["observation"]
            self.assertFalse(obs["timeout"])
            self.assertTrue(obs["group_quiescent"])
            self.assertEqual(obs["exit"], 4 if row["migrate"] else 0)
            if row["migrate"]:
                self.assertIn("threw=1,error=71", obs["stdout"])

    def test_repaired_integer_and_heap_controls_are_complete(self):
        for name in ("repaired-integer-controls", "repaired-hook-gc-controls"):
            receipt = self.native_receipt(name)
            for row in receipt["runs"]:
                obs = row["observation"]
                self.assertEqual(obs["exit"], 0)
                self.assertFalse(obs["timeout"])
                self.assertTrue(obs["group_quiescent"])
                self.assertEqual(obs["stderr"], "")
                self.assertIn("result=42,threw=0,error=0", obs["stdout"])
                if name == "repaired-hook-gc-controls":
                    self.assertIn("length=4096,intact=1", obs["stdout"])
