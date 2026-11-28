import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_archive import archive, archive_bootstrap, source_unit_checked, validate
from gambit_smp.output_observations import REGISTRY, TRANSCRIPT_SUFFIXES


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

    def test_actlog_negative_control_cannot_be_promoted_to_success(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            results = [
                {"label": "object-enabled", "accepted": True, "exit": 0, "timeout": False},
                {"label": "object-disabled", "accepted": True, "exit": 0, "timeout": False},
            ]
            for label, count in (("posix", 3), ("void-init", 2), ("disabled", 1)):
                log = source / f"{label}-observe.log"
                log.write_text(json.dumps({"checks": count, "arrayLive": 0, "mutexLive": 0}) + "\n")
                results.append({
                    "label": label, "accepted": True,
                    "compile": {"exit": 0, "timeout": False},
                    "observation": {"exit": 0, "timeout": False,
                                    "log": log.name, "logSha256": digest(log)},
                })
            ctrl_log = source / "ignored-mutex-error-control-observe.log"
            ctrl_log.write_text("EXPECTED-MUTEX-ERROR\n")
            results.append({
                "label": "ignored-mutex-error-control", "accepted": True,
                "compile": {"exit": 0, "timeout": False},
                "observation": {"exit": 0, "timeout": False,
                                "log": ctrl_log.name, "logSha256": digest(ctrl_log)},
            })
            receipt = {
                "schema": "gambit-actlog-abort-source-unit.v1",
                "status": "source-unit-pass", "sourceStable": True,
                "runtimeAdmitted": False, "releaseAdmitted": False,
                "results": results,
            }
            with self.assertRaisesRegex(ValueError, "negative control"):
                source_unit_checked(source, receipt, root=source)

    def test_scoped_archive_rejects_identity_drift_and_parent_exit_mismatch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            identity = source / "identity.json"
            identity.write_text('{"tree":"a"}')
            (source / "gsi.log").write_text("passed\n")
            (source / "processor-probe.log").write_text("2\n")
            (source / "receipt.json").write_text(json.dumps({
                "schema": "gambit-upstream-suite.v1", "status": "PASS",
                "modes": ["gsi"], "wholeSuiteBudgetPerMode": 300,
                "candidateReceiptSha256": digest(identity),
                "results": [{"mode": "gsi", "accepted": True, "exit": 0, "timeout": False}]}))
            for bad_exit in (1, False):
                with self.subTest(bad_exit=bad_exit), self.assertRaisesRegex(ValueError, "consistent parent exit|parent"):
                    archive(source, root / f"wrong-exit-{bad_exit}", bad_exit, identity)
            wrong = root / "wrong-identity.json"
            wrong.write_text("{}")
            with self.assertRaisesRegex(ValueError, "bound identity"):
                archive(source, root / "wrong-identity", 0, wrong)

    def test_changed_or_missing_archived_file_is_rejected(self):
        for fault in ("change", "missing"):
            with self.subTest(fault=fault), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source = root / "source"
                source.mkdir()
                identity = source / "identity.json"
                identity.write_text("{}")
                (source / "gsi.log").write_text("partial suite failure\n")
                (source / "processor-probe.log").write_text("2\n")
                (source / "receipt.json").write_text(json.dumps({
                    "schema": "gambit-upstream-suite.v1", "status": "DENY",
                    "modes": ["gsi"], "wholeSuiteBudgetPerMode": 300,
                    "candidateReceiptSha256": digest(identity),
                    "results": [{"mode": "gsi", "accepted": False, "exit": -9, "timeout": True}]}))
                archive(source, root / "archive", None, identity)
                target = root / "archive/gsi.log"
                if fault == "change":
                    target.write_text("tampered\n")
                else:
                    target.unlink()
                with self.assertRaises((ValueError, FileNotFoundError)):
                    validate(root, "archive/archive.json")


if __name__ == "__main__":
    unittest.main()
