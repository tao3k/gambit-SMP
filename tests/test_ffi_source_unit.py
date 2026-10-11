from pathlib import Path
import tempfile
import unittest

from gambit_smp import check_gambit as gate
from gambit_smp import ffi_source_unit as unit

CODE = """___SCMOBJ result;
___FRAME_STORE_RA(___R0)
___W_ALL
result = ___os_condvar_select (___ARG1, ___ARG2);
___R_ALL
___SET_R0(___FRAME_FETCH_RA)
___RESULT = result;
"""
SOURCE = "(define-prim (##os-condvar-select! devices timeout)\n(##c-code #<<end-of-code\n" + CODE + "\nend-of-code\n devices timeout))\n"


class FfiSourceTests(unittest.TestCase):
    def test_embedded_c_identity_and_order_fail_closed(self):
        self.assertEqual(CODE + "\n", unit.boundary(SOURCE))
        for invalid in (SOURCE + SOURCE, SOURCE.replace("end-of-code\n", "other\n"),
                        SOURCE.replace("___W_ALL", "___R_ALL"),
                        SOURCE.replace("___W_ALL\n", "").replace("___R_ALL\n", "___R_ALL\n___W_ALL\n")):
            with self.assertRaises(ValueError):
                unit.boundary(invalid)

    def test_native_feedback_no_writeback_clobbers_even_without_gc(self):
        self.assertFalse(unit.expected_pass("no-writeback", 0))
        for count in range(3):
            self.assertTrue(unit.expected_pass("fixed", count))
            for variant in ("no-reload", "no-return-root"):
                self.assertEqual(count == 0, unit.expected_pass(variant, count))
        with self.assertRaises(ValueError):
            unit.expected_pass("unknown", 0)

    def test_checker_uses_snapshot_and_detects_both_source_and_snapshot_changes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "model.qnt"
            out = root / "out"
            out.mkdir()
            source.write_text("original")
            snapshot, model_hash = gate.snapshot_model(source, out)
            self.assertTrue(gate.model_stable(source, snapshot, model_hash))
            source.write_text("changed")
            self.assertEqual("original", snapshot.read_text())
            self.assertFalse(gate.model_stable(source, snapshot, model_hash))
            source.write_text("original")
            snapshot.write_text("changed")
            self.assertFalse(gate.model_stable(source, snapshot, model_hash))

    def test_explicitly_invalidated_attempt_cannot_be_reused(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "invalidation.json").write_text('{"status":"DENY"}')
            with self.assertRaisesRegex(ValueError, "explicitly invalidated"):
                gate.reuse_model_receipt(root / "receipt.json", {"id": "ffi_gc_frame_protocol"})


if __name__ == "__main__":
    unittest.main()
