import json
from pathlib import Path
import tempfile
import shutil
import unittest

from gambit_smp.framework import digest, ROOT
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
        for name in ("evidence/dsl/observation-contract.ss",
                     "evidence/research/source-schedule-revalidation/observations.json",
                     "evidence/dsl/source-review-contract.ss",
                     "evidence/protocol-source-requirements.json"):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        declared = json.loads((self.root / "evidence/research/source-schedule-revalidation/observations.json").read_text())
        self.receipt = dict(schema="gambit-sync-retirement-schedule.v1",
            compile=dict(exit=0, timeout=False), status="source-schedule-observed", sourceStable=True,
            runtimeAdmitted=False, inputs={"source/setup.c": self.sha},
            results=declared["cases"])
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

    def test_historical_unit_receipt_does_not_become_current_source_input(self):
        self.data.pop("sourceUnitReceipt")
        self.data.pop("sourceUnitReceiptSha256")
        self.data["nativeGates"].append("source-unit-observation-unavailable")
        self.save(audit.MANIFEST, self.data)
        (self.root / "evidence/unit.json").unlink()
        rows, inputs = audit.facts(self.root)
        self.assertEqual(len(rows["source_review"]), 4)
        self.assertIn(("source-unit-observation-unavailable",), rows["source_native_pending"])
        self.assertNotIn("evidence/unit.json", inputs)
        self.data["sourceUnitReceiptSha256"] = "a" * 64
        self.save(audit.MANIFEST, self.data)
        with self.assertRaisesRegex(ValueError, "fields require a current receipt"):
            audit.facts(self.root)

    def historical_context(self):
        for directory in ("source/lib", "src", "patches", "evidence/source-results/history"):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        (self.root / "source/lib/setup.c").write_text("reviewed source\n")
        (self.root / "patches/overlay.patch").write_text("locked patch")
        self.save("evidence/lock.json", {"patch": "patches/overlay.patch"})
        (self.root / "src/tool.py").write_text("current review tool")
        archived = self.root / "evidence/source-results/history/tool.py"
        archived.write_text("original producer tool")
        self.receipt.update(sourceLock="evidence/lock.json", sourceFileIdentities={"lib/setup.c": self.sha})
        self.receipt["inputs"].update({
            "evidence/lock.json": digest(self.root / "evidence/lock.json"),
            "patches/overlay.patch": digest(self.root / "patches/overlay.patch"),
            "src/tool.py": digest(archived)})
        self.save("evidence/unit.json", self.receipt)
        self.data.update(sourceLock="evidence/lock.json", contextInputs={"lib/setup.c": self.sha},
                         sourceUnitReceiptSha256=digest(self.root / "evidence/unit.json"),
                         sourceUnitInputArchive="evidence/history.json")
        for row in self.data["observations"]:
            row["anchors"] = ["lib/setup.c:1"]
        self.archive = {"schema": "historical-source-inputs.v1",
                        "receiptSha256": self.data["sourceUnitReceiptSha256"],
                        "inputs": [{"original": "src/tool.py", "sha256": digest(archived),
                                    "archive": archived.relative_to(self.root).as_posix()}]}
        self.save("evidence/history.json", self.archive)
        self.save(audit.MANIFEST, self.data)
        return {name: digest(self.root / name) for name in
                (audit.MANIFEST, "evidence/lock.json", "patches/overlay.patch", "src/tool.py")}

    def test_historical_tool_and_current_reconstruction_bind_separately(self):
        inputs = self.historical_context()
        old_receipt = digest(self.root / "evidence/unit.json")
        _, bound = audit.source_facts(self.root, self.data, self.root / "source", inputs, locked=True)
        self.assertEqual(digest(self.root / "src/tool.py"), bound["src/tool.py"])
        self.assertEqual(self.receipt["inputs"]["src/tool.py"],
                         bound["evidence/source-results/history/tool.py"])
        self.assertEqual(old_receipt, digest(self.root / "evidence/unit.json"))

    def test_historical_tool_archive_drift_is_rejected(self):
        inputs = self.historical_context()
        (self.root / "evidence/source-results/history/tool.py").write_text("not the original")
        with self.assertRaisesRegex(ValueError, "exact versioned historical source"):
            audit.source_facts(self.root, self.data, self.root / "source", inputs, locked=True)

    def test_history_cannot_replace_current_source_lock(self):
        inputs = self.historical_context()
        target = self.root / "evidence/source-results/history/old-lock.json"
        target.write_text('{"patch":"patches/overlay.patch","different":true}')
        old_sha = digest(target)
        self.receipt["inputs"]["evidence/lock.json"] = old_sha
        self.save("evidence/unit.json", self.receipt)
        self.data["sourceUnitReceiptSha256"] = digest(self.root / "evidence/unit.json")
        self.archive["receiptSha256"] = self.data["sourceUnitReceiptSha256"]
        self.archive["inputs"].append({"original": "evidence/lock.json", "sha256": old_sha,
                                       "archive": target.relative_to(self.root).as_posix()})
        self.save("evidence/history.json", self.archive)
        with self.assertRaisesRegex(ValueError, "omits locked source inputs"):
            audit.source_facts(self.root, self.data, self.root / "source", inputs, locked=True)

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
        with self.assertRaisesRegex(ValueError, "MissingModel"):
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
        with self.assertRaisesRegex(ValueError, "MissingCase"):
            audit.facts(self.root)

    def test_runtime_claim_rejected(self):
        self.data["runtimeAdmitted"] = True
        self.save(audit.MANIFEST, self.data)
        with self.assertRaisesRegex(ValueError, "cannot admit"):
            audit.facts(self.root)

    def test_duplicate_or_invented_pass_rejected(self):
        self.receipt["results"][1] = self.receipt["results"][0]
        with self.assertRaisesRegex(ValueError, "DuplicateCase"):
            audit.check_schedule(self.receipt, self.root)
        self.receipt["results"][0]["actual"] = {"invalid": 0}
        with self.assertRaisesRegex(ValueError, "observation"):
            audit.check_schedule(self.receipt, self.root)


if __name__ == "__main__":
    unittest.main()
