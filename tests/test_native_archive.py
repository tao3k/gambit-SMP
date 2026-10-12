import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.native_archive import archive, source_unit_checked, validate


NAME = "evidence/source-results/gc-notification-source-schedules-031/archive.json"


class NativeArchiveTests(unittest.TestCase):
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
