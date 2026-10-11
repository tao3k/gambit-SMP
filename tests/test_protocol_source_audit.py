import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import digest
from gambit_smp import protocol_source_audit as audit
from unittest.mock import patch


class CorrespondenceTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        (self.root / "evidence").mkdir()
        (self.root / "source").mkdir()
        (self.root / "source/setup.c").write_text("reviewed source\n")
        self.sha = digest(self.root / "source/setup.c")
        self.receipt = dict(schema="gambit-sync-retirement-schedule.v1",
            compile=dict(exit=0, timeout=False), status="source-schedule-observed", sourceStable=True,
            runtimeAdmitted=False, inputs={"source/setup.c": self.sha},
            results=[dict(matched=True, policy=name, point=point,
                actual=audit.expected(mode, point), expected=audit.expected(mode, point),
                exit=0, timeout=False)
                for mode, name in enumerate(("existing-no-destroy", "naive-child-destroy",
                    "deferred-drain-contract", "initialization-failure")) for point in (1, 2)])
        self.save("evidence/unit.json", self.receipt)
        self.data = dict(schema="gambit-protocol-source-correspondence.v1",
            runtimeAdmitted=False, releaseAdmitted=False, sourceRoot="source",
            contextInputs={"setup.c": self.sha}, sourceUnitReceipt="evidence/unit.json",
            sourceUnitReceiptSha256=digest(self.root / "evidence/unit.json"),
            nativeGates=["bootstrap"], observations=[dict(id=model, model=model,
                status="repair-required", finding="reviewed", next="repair", avoid=["known-failure"],
                anchors=["setup.c:1"]) for model in ("gc_epoch_work_bridge",
                    "gc_scan_claim_transfer", "sync_retirement_drain", "vm_configuration_contract")])
        self.save(audit.MANIFEST, self.data)

    def save(self, name, data):
        (self.root / name).write_text(json.dumps(data))

    def test_complete_facts_do_not_admit_native(self):
        rows, inputs = audit.facts(self.root)
        self.assertEqual(len(rows["source_review"]), 4)
        self.assertEqual(rows["source_native_pending"], [("bootstrap",)])
        self.assertIn("source/setup.c", inputs)

    def test_source_drift_rejected(self):
        (self.root / "source/setup.c").write_text("changed\n")
        with self.assertRaisesRegex(ValueError, "stale"):
            audit.facts(self.root)

    def test_cache_source_cannot_be_a_current_correspondence_input(self):
        self.data["sourceRoot"] = ".data/source"
        (self.root / ".data/source").mkdir(parents=True)
        self.save(audit.MANIFEST, self.data)
        with self.assertRaisesRegex(ValueError, "versioned"):
            audit.facts(self.root)

    def test_real_locked_correspondence_does_not_access_candidate026_cache(self):
        from gambit_smp.framework import ROOT
        original = audit.relative
        def no_cache(root, name):
            if ".data" in Path(name).parts:
                raise AssertionError("cache input accessed: " + name)
            return original(root, name)
        with patch.object(audit, "relative", side_effect=no_cache):
            rows, inputs = audit.facts(ROOT)
        self.assertEqual({row[0] for row in rows["source_review"]},
                         {"gc_epoch_work_bridge", "gc_scan_claim_transfer",
                          "sync_retirement_drain", "vm_configuration_contract"})
        self.assertTrue(all(".data" not in Path(name).parts for name in inputs))
        self.assertIn("evidence/runtime-source-026.lock.json", inputs)

    def test_missing_model_and_wrong_anchor_rejected(self):
        self.data["observations"].pop()
        self.save(audit.MANIFEST, self.data)
        with self.assertRaisesRegex(ValueError, "four"):
            audit.facts(self.root)
        self.data["observations"][0]["anchors"] = ["setup.c:2"]
        self.save(audit.MANIFEST, self.data)
        with self.assertRaisesRegex(ValueError, "anchor"):
            audit.facts(self.root)

    def test_incomplete_receipt_even_with_updated_hash_rejected(self):
        self.receipt["results"].pop()
        self.save("evidence/unit.json", self.receipt)
        self.data["sourceUnitReceiptSha256"] = digest(self.root / "evidence/unit.json")
        self.save(audit.MANIFEST, self.data)
        with self.assertRaisesRegex(ValueError, "incomplete"):
            audit.facts(self.root)

    def test_runtime_claim_rejected(self):
        self.data["runtimeAdmitted"] = True
        self.save(audit.MANIFEST, self.data)
        with self.assertRaisesRegex(ValueError, "cannot admit"):
            audit.facts(self.root)

    def test_duplicate_or_invented_pass_rejected(self):
        self.receipt["results"][1] = self.receipt["results"][0]
        with self.assertRaisesRegex(ValueError, "duplicate"):
            audit.check_schedule(self.receipt)
        self.receipt["results"][0]["actual"] = {"invalid": 0}
        with self.assertRaisesRegex(ValueError, "observation"):
            audit.check_schedule(self.receipt)


if __name__ == "__main__":
    unittest.main()
