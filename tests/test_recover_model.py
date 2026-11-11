import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.recover_model import validated


class RecoverModelTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.case = next(row for row in json.loads((ROOT / "models/gambit/cases.json").read_text())["cases"]
                         if row["id"] == "ticket_queue_handoff")
        self.raw = self.root / ".data/original"
        self.raw.mkdir(parents=True)
        model = self.root / "models/gambit/ticket_queue_handoff.qnt"
        model.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / "models/gambit/ticket_queue_handoff.qnt", model)
        public = self.root / self.case["modelReceipt"]
        public.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / self.case["modelReceipt"], public)
        for name in ("receipt.json", "ticket_queue_handoff.qnt",
                     "ticket_queue_handoff-old.log", "ticket_queue_handoff-fixed.log"):
            shutil.copyfile(ROOT / "tests/fixtures/recover-model" / name, self.raw / name)

    def test_recovery_uses_full_logs_snapshot_and_no_quint_process(self):
        snapshot, inputs, rows = validated(self.root, self.case, self.raw)
        self.assertEqual("ticket_queue_handoff.qnt", snapshot.name)
        self.assertEqual(2, len(rows))
        self.assertIsNotNone(rows[0][2])
        self.assertIsNone(rows[1][2])
        self.assertIn(".data/original/ticket_queue_handoff-old.log", inputs)
        self.assertIn(".data/original/ticket_queue_handoff-fixed.log", inputs)

    def test_changed_snapshot_is_denied(self):
        (self.raw / "ticket_queue_handoff.qnt").write_text("changed")
        with self.assertRaisesRegex(ValueError, "snapshot differs"):
            validated(self.root, self.case, self.raw)

    def test_missing_or_incomplete_positive_log_is_denied(self):
        log = self.raw / "ticket_queue_handoff-fixed.log"
        original = log.read_text()
        log.unlink()
        with self.assertRaises(OSError):
            validated(self.root, self.case, self.raw)
        log.write_text(original.replace("0 states left on queue.", "1 states left on queue."))
        with self.assertRaisesRegex(ValueError, "raw log"):
            validated(self.root, self.case, self.raw)

    def test_negative_without_decodable_counterexample_is_denied(self):
        (self.raw / "ticket_queue_handoff-old.log").write_text("Error: Invariant q_inv is violated.\n")
        with self.assertRaisesRegex(ValueError, "raw log"):
            validated(self.root, self.case, self.raw)

    def test_original_result_identity_or_timeout_drift_is_denied(self):
        path = self.raw / "receipt.json"
        original = json.loads(path.read_text())
        for key, value in (("initializer", "wrong"), ("timeout", True), ("sourceStable", False)):
            changed = json.loads(json.dumps(original))
            changed["results"][0][key] = value
            path.write_text(json.dumps(changed))
            with self.subTest(key=key), self.assertRaises(ValueError):
                validated(self.root, self.case, self.raw)


if __name__ == "__main__":
    unittest.main()
