"""Exact stress inventory transport; no runtime acceptance is implied."""
from pathlib import Path
import tempfile
import time
from types import SimpleNamespace
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.suite_primitives import selected_files
from gambit_smp.native_capabilities import run_suite_groups


class StressInventoryTests(unittest.TestCase):
    def test_explicit_inventory_preserves_default_and_helpers(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ("a.scm", "a_stress.scm", "#.scm"):
                (root / name).write_text("")
            self.assertEqual([Path("a.scm")], selected_files(root, ["."]))
            self.assertEqual([Path("a_stress.scm")], selected_files(root, ["."], inventory="stress"))
            with self.assertRaises(ValueError):
                selected_files(root, ["a_stress.scm"])
            with self.assertRaises(ValueError):
                selected_files(root, ["."], inventory="all")

    def test_all_four_unmodified_upstream_stress_files_are_selected(self):
        root = ROOT / "vendor/gambit/tests/unit-tests"
        self.assertEqual([
            Path("06-thread/tfib_stress.scm"),
            Path("06-thread/thread_interrupt2_stress.scm"),
            Path("06-thread/thread_interrupt_stress.scm"),
            Path("06-thread/thread_terminate_stress.scm"),
        ], selected_files(root, ["."], inventory="stress"))

    def test_actual_runner_receives_stress_switch_only_for_stress(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            runtime, copied = root / "runtime", root / "copied"
            runtime.mkdir()
            copied.mkdir()
            for inventory in ("unit", "stress"):
                output = root / inventory
                output.mkdir()
                argv = []
                def run(name, command, cwd, cap):
                    argv.extend(command)
                    return 0, "PASSED ALL 1 UNIT TESTS\n", False, 0.1
                ctx = SimpleNamespace(directory=output, deadline=time.monotonic() + 10, run=run)
                rows = run_suite_groups(ctx, runtime, copied,
                    {"mode": "gsi", "regime": "whole-parallel", "inventory": inventory},
                    [Path("fixture_stress.scm" if inventory == "stress" else "fixture.scm")], 1, "p2")
                self.assertEqual(inventory == "stress", "-stress" in argv)
                self.assertTrue(rows[0]["accepted"])
