import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.model_projection import render
from gambit_smp.protocol_evidence import BUNDLES, bundle_facts, checked_rows
from gambit_smp.verify_protocols import load_manifest


class ResizeResultMembershipCompositionTests(unittest.TestCase):
    base = "evidence/fixtures/interrupt-prefix-owned-lifecycle/"
    receipt = "evidence/model-results/fixtures/interrupt-prefix-owned-lifecycle/resize-result-membership-design-contract/receipt.json"

    def test_complete_model_and_datalog_binding_preserve_native_boundary(self):
        path = self.base + "resize-result-membership-design-contract.json"
        manifest = load_manifest(ROOT / path)
        self.assertIn((path, self.receipt), BUNDLES)
        rows = checked_rows(ROOT, manifest, ROOT / self.receipt)[0][1]
        self.assertEqual(4, len(rows))
        self.assertEqual(3, sum(r["variant"] == "old" and r["exit"] == 1 for r in rows))
        positive = next(r for r in rows if r["variant"] == "protocol")
        self.assertEqual({"generated": 5648, "distinct": 2128, "queued": 0}, positive["states"])
        self.assertEqual("progress", positive["temporal"])
        facts, inputs = bundle_facts(ROOT, path, self.receipt)
        self.assertTrue(facts)
        for name in (path, self.receipt, "src/gambit_smp/model_projection.py"):
            self.assertEqual(digest(ROOT / name), inputs[name])
        self.assertIn("permanent_join_failure_vm_protocol", manifest["cases"][0]["openObligations"])
        saved = json.loads((ROOT / self.receipt).read_text())
        self.assertFalse(saved["runtimeAdmitted"])
        self.assertFalse(saved["releaseAdmitted"])

    def test_projection_uses_canonical_actions_and_new_member_ack_gate(self):
        saved = json.loads((ROOT / (self.base + "resize-result-membership-projection.json")).read_text())
        model = render(ROOT, saved)
        self.assertEqual((ROOT / saved["target"]).read_text(), model)
        for name in ("receiverStep", "recoverJoin", "reuseSlot", "cleanupVm"):
            self.assertIn("retire_" + name, model)
        self.assertIn("S::s.phase != 4 or R::terminal", model)
        self.assertIn("population: if (control.policy == 2) 2 else 3", model)

    def test_conversion_failures_are_not_model_counterexamples(self):
        names = (
            "resize-result-membership-import-deny", "retirement-join-interface-signature-deny",
            "resize-result-membership-effect-deny", "resize-result-membership-empty-instance-deny",
            "resize-result-membership-init-conversion-deny",
            "resize-result-membership-uninitialized-nested-state-deny",
            "resize-result-membership-nested-alias-deny", "retirement-join-export-conversion-deny",
            "resize-result-membership-export-conversion-deny", "retirement-join-instance-flatten-deny",
            "resize-result-membership-type-name-deny",
        )
        for name in names:
            directory = ROOT / "evidence/model-results/fixtures/interrupt-prefix-owned-lifecycle" / name
            saved = json.loads((directory / "receipt.json").read_text())
            self.assertFalse(saved["accepted"], name)
            self.assertFalse(saved["runtimeAdmitted"], name)
            self.assertTrue((directory / "archive.json").is_file(), name)
