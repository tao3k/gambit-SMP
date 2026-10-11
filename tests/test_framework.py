import os
import argparse
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import framework


class FrameworkTests(unittest.TestCase):
    def test_generated_build_driver_binds_compiler_and_detects_drift(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "bin").mkdir()
            compiler = root / "gcc"
            compiler.touch()
            driver = root / "bin/gambuild-C"
            driver.write_text(f'C_COMPILER="{compiler}"\n')
            first = framework.gnu_build_driver(root, str(compiler))
            with patch.dict(os.environ, {"GAMBIT_DARWIN_NATIVE_OBJECTS": "1"}):
                with self.assertRaises(ValueError):
                    framework.gnu_build_driver(root, str(compiler))
            driver.write_text(f'C_COMPILER="{compiler}"\n# changed\n')
            self.assertNotEqual(first, framework.gnu_build_driver(root, str(compiler)))
            for content in ('C_COMPILER="/different/compiler"\n', '',
                            f'C_COMPILER="{compiler}"\nC_COMPILER="{compiler}"\n'):
                driver.write_text(content)
                with self.assertRaises(ValueError):
                    framework.gnu_build_driver(root, str(compiler))
    def test_parallel_jobs_share_one_deadline_and_preserve_results(self):
        rows = framework.parallel_jobs([1, 2, 3], lambda item, deadline: (item, deadline), 2, 1)
        self.assertEqual([1, 2, 3], [row[0] for row in rows])
        self.assertEqual(1, len({row[1] for row in rows}))
        for jobs, timeout in ((0, 1), (2, 0)):
            with self.assertRaises(ValueError):
                framework.parallel_jobs([], lambda item, deadline: item, jobs, timeout)
    def test_processor_selection_uses_host_and_affinity(self):
        query = "process_cpu_count" if hasattr(framework.os, "process_cpu_count") else "cpu_count"
        with patch.object(framework.os, query, return_value=10), \
                patch.object(framework.os, "sched_getaffinity", return_value={0, 1, 2}, create=True):
            self.assertEqual(framework.available_processors(), 3)
        with patch.object(framework.os, query, return_value=None), \
                patch.object(framework.os, "sched_getaffinity", side_effect=OSError, create=True):
            self.assertEqual(framework.available_processors(), 1)
    def test_native_processor_count_not_artificially_capped(self):
        self.assertEqual(framework.positive_int("12"), 12)
        for value in ("0", "-1", "invalid"):
            with self.assertRaises(argparse.ArgumentTypeError):
                framework.positive_int(value)
    def test_fixture_snapshot_isolated_and_non_overwriting(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "case.scm"
            source.write_text("fixture")
            out = root / "out"
            out.mkdir()
            target = framework.snapshot_fixture(source, out)
            self.assertEqual(target.parent, out)
            self.assertEqual(framework.digest(source), framework.digest(target))
            with self.assertRaises(FileExistsError):
                framework.snapshot_fixture(source, out)

    def test_execution_preserves_failure_and_identity(self):
        metadata = {}
        code, output, timeout, elapsed = framework.execute(
            [sys.executable, "-c", "print('failed'); raise SystemExit(7)"],
            framework.ROOT, 5, metadata=metadata)
        self.assertEqual((code, output.strip(), timeout), (7, "failed", False))
        self.assertGreaterEqual(elapsed, 0)
        self.assertGreater(metadata["pid"], 0)
        self.assertLessEqual(metadata["startedAt"], metadata["endedAt"])

    def test_invalid_budget_does_not_spawn(self):
        with patch.object(framework.subprocess, "Popen") as spawn:
            for budget in (0, -1):
                with self.assertRaises(ValueError):
                    framework.execute(["unused"], framework.ROOT, budget)
            spawn.assert_not_called()

    def test_compiler_environment_and_rejection(self):
        with patch.dict(os.environ, dict(SDKROOT="wrong", LIBRARY_PATH="wrong", CPATH="wrong")), \
                patch.object(framework, "execute", return_value=(0, "gcc (GCC) 16.2", False, 0)) as run:
            _, environment, _ = framework.gnu_compiler(Path(sys.executable))
            self.assertTrue(all(name not in environment for name in ("SDKROOT", "LIBRARY_PATH", "CPATH")))
            self.assertEqual(run.call_args.kwargs["env"], environment)
        for result in ((0, "Apple clang", False, 0), (1, "gcc", False, 0), (0, "gcc", True, 0)):
            with patch.object(framework, "execute", return_value=result), self.assertRaises(ValueError):
                framework.gnu_compiler(Path(sys.executable))
