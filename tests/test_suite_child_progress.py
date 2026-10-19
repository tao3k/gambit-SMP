"""Child observation transport controls, not native SMP qualification."""
import tempfile
from pathlib import Path
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.suite_progress import ChildGCProgress, instrument


class ChildProgressTests(unittest.TestCase):
    def config(self):
        return {"kind": "completed-child-gc", "files": ["first.scm", "second.scm"],
                "forwarder": "models/gambit/native/child_gc_forwarder.scm",
                "runnerSha256": digest(ROOT / "vendor/gambit/tests/run-unit-tests.scm"),
                "reporterSha256": digest(ROOT / "vendor/gambit/lib/_nonstd.scm"),
                "manifest": "evidence/dsl/components.json", "entry": "checkpoint-state",
                "constructor": "make-checkpoint-state"}

    def observer(self):
        source = {"files": {"unit-tests/first.scm": "first-hash", "unit-tests/second.scm": "second-hash"},
                  "runner": "runner", "reporter": "reporter", "binary": "binary"}
        result = ChildGCProgress(ROOT, self.config(), "nonce", source, 2)
        self.addCleanup(result.close)
        return result

    def line(self, count, *, pid=123, file="first.scm", nonce="nonce"):
        return f"SMP-GC {nonce} {pid} unit-tests/{file} {count} *** GC: 1.0ms, 1M alloc, 100M heap, 10M live (10% 1+2)\n"

    def test_begin_and_partial_report_never_renew(self):
        observed = self.observer()
        text = "SMP-CHILD nonce 123 unit-tests/first.scm\n"
        self.assertEqual(observed("", text), 0)
        partial = text + self.line(1)[:-1]
        self.assertEqual(observed("", partial), 0)
        self.assertEqual(observed("", partial + "\n"), 1)
        self.assertTrue(observed.witness["advanced"])

    def test_scheme_rejects_replayed_and_regressed_frontiers(self):
        observed = self.observer()
        text = "SMP-CHILD nonce 123 unit-tests/first.scm\n" + self.line(2)
        self.assertEqual(observed("", text), 1)
        text += self.line(2) + self.line(1)
        self.assertEqual(observed("", text), 1)
        self.assertTrue(observed.witness["rejected"])
        self.assertFalse(observed.witness["advanced"])
        self.assertEqual(observed("", text + self.line(3)), 2)

    def test_other_child_or_nonce_cannot_renew(self):
        observed = self.observer()
        text = "SMP-CHILD nonce 123 unit-tests/first.scm\n"
        text += self.line(1, pid=456) + self.line(1, nonce="old") + self.line(1, file="unknown.scm")
        self.assertEqual(observed("", text), 0)
        self.assertEqual(len(observed.errors), 3)

    def test_native_negative_allocation_does_not_become_a_work_counter(self):
        observed = self.observer()
        text = "SMP-CHILD nonce 123 unit-tests/first.scm\n"
        text += self.line(1).replace("1M alloc", "-143115.4K alloc")
        self.assertEqual(observed("", text), 1)
        self.assertEqual(observed.witness["cursorAfter"][0][-1], 1)
        self.assertFalse(observed.errors)
        text += text.splitlines(True)[-1]
        self.assertEqual(observed("", text), 1)
        self.assertEqual(observed("", text + self.line(2).replace("1M alloc", "-272539.0K alloc")), 2)

    def test_new_child_has_distinct_epoch_not_a_restored_live_actor(self):
        observed = self.observer()
        text = "SMP-CHILD nonce 123 unit-tests/first.scm\n" + self.line(9)
        self.assertEqual(observed("", text), 1)
        text += "SMP-CHILD nonce 456 unit-tests/second.scm\n"
        self.assertEqual(observed("", text), 1)
        self.assertEqual(observed("", text + self.line(1, pid=456, file="second.scm")), 2)
        self.assertEqual(len({row["epoch"] for row in observed.contexts}), 2)

    def test_replayed_child_begin_is_an_error_not_a_cursor_reset(self):
        observed = self.observer()
        begin = "SMP-CHILD nonce 123 unit-tests/first.scm\n"
        text = begin + self.line(1)
        self.assertEqual(observed("", text), 1)
        self.assertEqual(observed("", text + begin + self.line(1)), 1)
        self.assertIn("replayed-child-incarnation", observed.errors)

    def test_driver_overlay_does_not_modify_original_test_inputs(self):
        import shutil
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            work, runtime = root / "tests", root / "runtime"
            (work / "unit-tests").mkdir(parents=True)
            (runtime / "lib").mkdir(parents=True)
            (runtime / "gsi").mkdir()
            shutil.copyfile(ROOT / "vendor/gambit/tests/run-unit-tests.scm", work / "run-unit-tests.scm")
            shutil.copyfile(ROOT / "vendor/gambit/lib/_nonstd.scm", runtime / "lib/_nonstd.scm")
            (runtime / "gsi/gsi").write_bytes(b"test-binary")
            original = work / "unit-tests/first.scm"
            original.write_text("(display 42)\n")
            before = digest(original)
            nonce, source = instrument(work, runtime, [Path("first.scm")], self.config(), root=ROOT)
            self.assertEqual(digest(original), before)
            self.assertEqual(source["files"]["unit-tests/first.scm"], before)
            self.assertIn(nonce, (work / "run-unit-tests.scm").read_text())
            self.assertIn('"-e" "(gc-report-set! #t)" file)', (work / "run-unit-tests.scm").read_text())
            with self.assertRaisesRegex(ValueError, "source correspondence drift"):
                instrument(work, runtime, [Path("first.scm")], self.config(), root=ROOT)


if __name__ == "__main__":
    unittest.main()
