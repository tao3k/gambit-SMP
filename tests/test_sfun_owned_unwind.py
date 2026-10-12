"""Exception-owned SFUN cleanup candidate, not full runtime admission."""
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import bundle_facts
from gambit_smp.source_materialize import locked_source


BASE = "evidence/source-results/fixtures/sfun-owned-unwind"
LOCK = "evidence/fixtures/sfun-owned-unwind/source.lock.json"


class SfunOwnedUnwindTests(unittest.TestCase):
    def test_only_three_header_wrapper_pairs_change_against_parent(self):
        parent = json.loads((ROOT / "evidence/fixtures/callback-return-owned-result/source.lock.json").read_text())
        candidate = json.loads((ROOT / LOCK).read_text())
        self.assertEqual(parent["revision"], candidate["revision"])
        self.assertEqual(set(parent["files"]), set(candidate["files"]))
        self.assertEqual([p for p in candidate["files"]
                          if candidate["files"][p] != parent["files"][p]],
                         ["include/gambit.h.in"])
        with locked_source(ROOT, LOCK) as (source, _):
            lines = (source / "include/gambit.h.in").read_text().splitlines()
            for suffix in ("_VOID", "_SCMOBJ", ""):
                begin = next(line for line in lines if line.startswith(
                    "#define ___BEGIN_SFUN" + suffix + "("))
                end = next(line for line in lines if line.startswith(
                    "#define ___END_SFUN" + suffix + " "))
                self.assertTrue(begin.endswith("{ ___BEGIN_TRY"))
                self.assertIn("___END_TRY ___EXT(___kill_sfun_stack_marker)", end)
                self.assertLess(end.index("___kill_sfun_stack_marker"), end.index("___propagate_error"))

    def test_five_invalid_repairs_and_joint_completion_are_qualified(self):
        manifest = "evidence/fixtures/sfun-owned-unwind/contract.json"
        receipt = "evidence/model-results/fixtures/sfun-owned-unwind/catcher-cleanup/receipt.json"
        facts, _ = bundle_facts(ROOT, manifest, receipt)
        self.assertEqual(len(facts["protocol_control"]), 5)
        self.assertEqual(len(facts["protocol_checked"]), 1)
        saved = json.loads((ROOT / receipt).read_text())
        self.assertFalse(saved["runtimeAdmitted"])
        self.assertFalse(saved["releaseAdmitted"])
        positive = [r for r in saved["results"] if r["variant"] == "protocol"]
        self.assertEqual(positive[0]["temporal"], "completion")
        self.assertEqual(positive[0]["states"]["queued"], 0)

    def receipt(self, name):
        folder = ROOT / BASE / name
        archive = json.loads((folder / "archive.json").read_text())
        self.assertTrue(archive["archiveOnly"])
        for path, expected in archive["files"].items():
            self.assertEqual(digest(folder / path), expected)
        receipt = json.loads((folder / "receipt.json").read_text())
        self.assertTrue(receipt["controlsPassed"])
        self.assertTrue(receipt["identityUnchanged"])
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertEqual(receipt["sourceLockSha256"], digest(ROOT / LOCK))
        summary = json.loads((ROOT / BASE / "sealed-source-core-summary.json").read_text())
        self.assertEqual(receipt["identitySha256"], summary["identitySha256"])
        for row in receipt["runs"]:
            obs = row["observation"]
            self.assertEqual(obs["exit"], 0)
            self.assertFalse(obs["timeout"])
            self.assertTrue(obs["group_quiescent"])
            self.assertEqual(obs["stderr"], "")
        return receipt

    def test_nested_cleanup_and_moving_roots_both_remain_correct(self):
        receipt = self.receipt("native-controls")
        self.assertEqual(len(receipt["runs"]), 22)
        for row in receipt["runs"]:
            text = row["observation"]["stdout"]
            if row["program"] == "nested-marker":
                self.assertEqual(text.count("made=2,killed=2"), 2)
            elif row["program"] == "sfun-families":
                self.assertIn("made=1,killed=1", text)
                self.assertIn("SFUN-FAMILY-CLEANUP:error=0", text)
            else:
                self.assertIn("intact=1,threw=0,error=0", text)
                if row["arguments"] == [1, 1]:
                    self.assertIn("moved=1", text)

    def test_optimized_all_wrapper_and_conversion_controls_pass(self):
        receipt = self.receipt("optimized-native-controls")
        self.assertEqual(receipt["fixtureCcOptions"], ["-D___LIBRARY", "-O2", "-Wclobbered"])
        self.assertEqual(receipt["runtimeOptimization"], "O0 diagnostic")
        self.assertEqual(receipt["build"]["exit"], 0)
        self.assertEqual(receipt["build"]["stderr"], "")
        expected = {(k, m, f) for k in range(3) for m in range(2) for f in range(2)}
        expected.update({(2, 0, 2), (2, 1, 2)})
        self.assertEqual({tuple(r["arguments"]) for r in receipt["runs"]}, expected)
        for row in receipt["runs"]:
            self.assertIn("made=1,killed=1", row["observation"]["stdout"])

    def test_source_core_and_sandbox_denial_are_not_full_admission(self):
        summary = json.loads((ROOT / BASE / "sealed-source-core-summary.json").read_text())
        self.assertEqual(summary["outcome"], "PASS")
        self.assertFalse(summary["runtimeAdmitted"])
        self.assertFalse(summary["sourceRefinementAdmitted"])
        for path, expected in summary["inputs"].items():
            self.assertEqual(digest(ROOT / path), expected)
        denied = json.loads((ROOT / BASE / "configure-sandbox-denial/summary.json").read_text())
        self.assertEqual(denied["outcome"], "DENY")
        self.assertFalse(denied["accepted"])
