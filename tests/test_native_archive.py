import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_archive import archive, archive_bootstrap, source_unit_checked, validate


NAME = "evidence/source-results/gc-notification-source-schedules-031/archive.json"


class NativeArchiveTests(unittest.TestCase):
    def test_atomic_history_preserves_unexecuted_scope_and_original_batch_cap(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            identity = root / "identity.json"
            identity.write_text("{}")
            (root / "processor-probe.log").write_text("2\n")
            (root / "gsc.log").write_text("partial compiled campaign\n")
            nested = root / "batches/gsc/0/gsc-0.log"
            nested.parent.mkdir(parents=True)
            nested.write_text("actual partial batch\n")
            receipt = {"schema": "gambit-upstream-atomic-coverage.v1", "status": "DENY",
                       "modes": ["gsc"], "atomicBatchBudgetPerMode": 300,
                       "candidateReceiptSha256": digest(identity),
                       "selectedFiles": ["first.scm", "unexecuted.scm"], "filesPerMode": 2,
                       "results": [{"mode": "gsc", "accepted": False, "exit": -9, "timeout": True,
                           "process": {"batches": [{"batch": 0, "files": ["first.scm"],
                               "accepted": False, "exit": -9, "timeout": True,
                               "shards": [{"shard": 0}]}]}}]}
            path = root / "receipt.json"
            path.write_text(json.dumps(receipt))
            original = path.read_bytes()
            result = archive(root, root / "archive", None, identity)
            self.assertEqual(original, (root / "archive/receipt.json").read_bytes())
            self.assertIsNone(result["observedParentExit"])
            self.assertIn("batches/gsc/0/gsc-0.log", result["files"])
            self.assertEqual(6, len(validate(root, "archive/archive.json")))
            with self.assertRaisesRegex(ValueError, "parent outcome"):
                archive(root, root / "invented", 1, identity)
            for key, value in (("selectedFiles", ["unexecuted.scm"]),
                               ("atomicBatchBudgetPerMode", 601), ("filesPerMode", 1)):
                path.write_text(json.dumps(dict(receipt, **{key: value})))
                with self.assertRaises(ValueError):
                    archive(root, root / "bad", None, identity)

    def test_failed_suite_preserves_unknown_parent_and_missing_admission_fields(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            identity = source / "identity.json"
            identity.write_text("{}")
            (source / "gsi.log").write_text("partial suite failure\n")
            (source / "processor-probe.log").write_text("2\n")
            receipt = {"schema": "gambit-upstream-suite.v1", "status": "DENY",
                       "modes": ["gsi"], "wholeSuiteBudgetPerMode": 300,
                       "candidateReceiptSha256": digest(identity),
                       "results": [{"mode": "gsi", "accepted": False,
                                    "exit": -9, "timeout": True}]}
            path = source / "receipt.json"
            path.write_text(json.dumps(receipt))
            original = path.read_bytes()
            result = archive(source, root / "archive", None, identity)
            self.assertIsNone(result["observedParentExit"])
            self.assertFalse(result["rawLogsBoundByOriginalReceipt"]["gsi"])
            self.assertEqual(original, (root / "archive/receipt.json").read_bytes())
            self.assertEqual(5, len(validate(root, "archive/archive.json")))
            for field, value in (("performanceAdmitted", True), ("wholeSuiteBudgetPerMode", 601)):
                broken = dict(receipt, **{field: value})
                path.write_text(json.dumps(broken))
                with self.assertRaises(ValueError):
                    archive(source, root / "bad", None, identity)
            manifest = root / "archive/archive.json"
            result["observedParentExit"] = 1
            manifest.write_text(json.dumps(result))
            with self.assertRaises(ValueError):
                validate(root, "archive/archive.json")

    def test_failed_suite_rejects_invented_original_log_binding(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            identity = root / "identity.json"
            identity.write_text("{}")
            (root / "gsi.log").write_text("actual partial failure")
            (root / "processor-probe.log").write_text("2")
            (root / "receipt.json").write_text(json.dumps({
                "schema": "gambit-upstream-suite.v1", "status": "DENY", "modes": ["gsi"],
                "wholeSuiteBudgetPerMode": 300, "candidateReceiptSha256": digest(identity),
                "results": [{"mode": "gsi", "accepted": False, "exit": -9,
                             "timeout": True, "rawLogSha256": "0" * 64}]}))
            with self.assertRaisesRegex(ValueError, "raw-log binding"):
                archive(root, root / "archive", None, identity)
            self.assertFalse((root / "archive").exists())

    def test_failed_bootstrap_histories_preserve_unknown_parent_and_original_seed(self):
        for fixture in ("bootstrap-second-core-history", "bootstrap-gc-iteration-history", "bootstrap-serialization-history"):
            name = f"tests/fixtures/historical-bootstrap/{fixture}/archive.json"
            bound = validate(ROOT, name)
            self.assertEqual(4, len(bound))
            saved = json.loads((ROOT / name).read_text())
            self.assertIsNone(saved["observedParentExit"])
            self.assertFalse(saved["rawLogBoundByOriginalReceipt"])
            self.assertFalse(saved["runtimeAdmitted"])
            self.assertFalse(saved["nativeGcPassed"])
            receipt = json.loads((ROOT / Path(name).parent / "receipt.json").read_text())
            self.assertEqual(600, receipt["wholeBootstrapBudget"])
            self.assertEqual("DENY", receipt["status"])
            self.assertEqual(receipt["seedReceiptSha256"], saved["files"]["identity.json"])
            log = (ROOT / Path(name).parent / "bootstrap.log").read_text()
            self.assertNotIn("/Users/", log)
            self.assertNotIn("/private/var/folders/", log)

    def test_bootstrap_archiver_rejects_invented_raw_log_binding(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            identity = source / "identity.json"
            identity.write_text("{}")
            (source / "bootstrap.log").write_text("retained actual failure")
            (source / "receipt.json").write_text(json.dumps({
                "schema": "gambit-two-pass-bootstrap.v1", "status": "DENY",
                "wholeBootstrapBudget": 600, "seedReceiptSha256": digest(identity),
                "steps": [{"name": "from-scratch", "exit": -9}], "rawLogSha256": "0" * 64}))
            with self.assertRaisesRegex(ValueError, "raw-log binding"):
                archive_bootstrap(source, root / "archive", identity)
            self.assertFalse((root / "archive").exists())

    def test_actlog_source_unit_archive_binds_all_branches_without_admission(self):
        name = "evidence/source-results/vm-actlog-abort-source031/archive.json"
        bound = validate(ROOT, name)
        self.assertEqual(16, len(bound))
        saved = json.loads((ROOT / name).read_text())
        self.assertFalse(saved["nativeGcPassed"])
        self.assertFalse(saved["runtimeAdmitted"])
        receipt = json.loads((ROOT / Path(name).parent / "receipt.json").read_text())
        self.assertEqual(6, len(receipt["results"]))

    def test_actlog_negative_control_cannot_be_promoted_to_success(self):
        source = ROOT / "evidence/source-results/vm-actlog-abort-source031"
        receipt = json.loads((source / "receipt.json").read_text())
        row = next(row for row in receipt["results"]
                   if row["label"] == "ignored-mutex-error-control")
        row["observation"]["exit"] = 0
        with self.assertRaisesRegex(ValueError, "negative control"):
            source_unit_checked(source, receipt)

    def test_actlog_archive_rejects_changed_observation(self):
        name = "evidence/source-results/vm-actlog-abort-source031/archive.json"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / Path(name).parent
            shutil.copytree((ROOT / name).parent, target)
            (target / "posix-observe.log").write_text("{}\n")
            with self.assertRaises(ValueError):
                validate(root, name)

    def test_source031_scoped_native_logs_and_identity_remain_non_admitted(self):
        name = "evidence/source-results/source031-native-gc-fixtures/archive.json"
        bound = validate(ROOT, name)
        self.assertEqual(12, len(bound))
        saved = json.loads((ROOT / name).read_text())
        self.assertFalse(saved["nativeGcPassed"])
        receipt = json.loads((ROOT / Path(name).parent / "receipt.json").read_text())
        self.assertEqual("PASS", receipt["status"])
        self.assertEqual(4, len(receipt["selectedFiles"]))
        self.assertEqual({"gsi", "gsc"}, set(receipt["modes"]))

    def test_scoped_archive_rejects_identity_drift_and_parent_exit_mismatch(self):
        source = ROOT / "evidence/source-results/source031-native-gc-fixtures"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(ValueError, "consistent parent exit"):
                archive(source, root / "wrong-exit", 1, source / "identity.json")
            wrong = root / "identity.json"
            wrong.write_text("{}")
            with self.assertRaisesRegex(ValueError, "bound identity"):
                archive(source, root / "wrong-identity", 0, wrong)

    def test_all_actual_component_artifacts_are_bound_without_cache(self):
        inputs = validate(ROOT, NAME)
        self.assertEqual(len(inputs), 28)
        self.assertTrue(all(".data" not in Path(name).parts for name in inputs))
        saved = json.loads((ROOT / NAME).read_text())
        self.assertFalse(saved["nativeGcPassed"])
        self.assertEqual(saved["observedParentExit"], 0)

    def test_changed_or_missing_component_log_is_rejected(self):
        for fault in ("change", "missing"):
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                target = root / Path(NAME).parent
                shutil.copytree((ROOT / NAME).parent, target)
                log = target / "candidate/point-1.log"
                if fault == "change":
                    log.write_text("not the observed output\n")
                else:
                    log.unlink()
                with self.subTest(fault=fault), self.assertRaises((ValueError, FileNotFoundError)):
                    validate(root, NAME)

    def test_parent_exit_cannot_contradict_pass_or_be_a_boolean(self):
        with tempfile.TemporaryDirectory() as directory:
            for value in (1, False):
                with self.subTest(value=value), self.assertRaises(ValueError):
                    archive((ROOT / NAME).parent, Path(directory) / "new", value)


if __name__ == "__main__":
    unittest.main()
