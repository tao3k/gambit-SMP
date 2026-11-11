import unittest
import shlex
import subprocess
import sys
from unittest.mock import Mock, patch
from tempfile import TemporaryDirectory
from pathlib import Path

from gambit_smp.gambit_build_primitives import (build_capacity, core_command,
                                              build_seed_core, rebuild_source_core)


class BuildCapacityTests(unittest.TestCase):
    def test_host_budget_is_shared_not_multiplied(self):
        for cpus in (1, 2, 3, 8, 12, 24, 64):
            with self.subTest(cpus=cpus):
                plan = build_capacity(cpus)
                self.assertEqual(cpus, plan["makeJobs"])
                self.assertLessEqual(plan["makeJobs"] * plan["compilerProcessors"], cpus)
                self.assertEqual(["make", "-j" + str(cpus), "GAMBOPT=p1", "core"], core_command(plan))

    def test_invalid_host_budget_is_rejected(self):
        for cpus in (0, -1, True, None, 1.5):
            with self.subTest(cpus=cpus), self.assertRaises(ValueError):
                build_capacity(cpus)

    def test_make_exports_runtime_budget_to_recipe_children(self):
        child = shlex.quote(sys.executable)
        script = shlex.quote("import os; print(os.environ['GAMBOPT'])")
        result = subprocess.run(["make", "-f", "-", "GAMBOPT=p1"],
                                input="all:\n\t@" + child + " -c " + script + "\n",
                                text=True, capture_output=True, timeout=10)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("p1", result.stdout.strip())

    def test_seed_executes_and_records_host_selected_plan(self):
        with TemporaryDirectory() as temporary:
            source = Path(temporary)
            stages = Mock()
            stages.run.return_value = (0, "", False, 0.1)
            with patch("gambit_smp.gambit_build_primitives.available_processors", return_value=7):
                ok, observation = build_seed_core(stages, source, 120)
            self.assertFalse(ok)  # Successful exit without artifacts is not admission.
            from gambit_smp.gambit_build_primitives import CoreBuildProgress
            stages.run.assert_called_once()
            self.assertEqual(stages.run.call_args.args,
                ("seed-core", ["make", "--debug=b", "-j7", "GAMBOPT=p1", "core"], source, 120))
            self.assertEqual(set(stages.run.call_args.kwargs), {"progress"})
            self.assertIsInstance(stages.run.call_args.kwargs["progress"], CoreBuildProgress)
            self.assertEqual(7, observation["capacity"]["availableProcessors"])
            self.assertEqual("host-auto-shared-budget", observation["processorSelection"])

    def test_source_core_progress_is_not_a_total_wall_clock_budget(self):
        from types import SimpleNamespace
        from gambit_smp.gambit_build_primitives import CoreBuildProgress
        for progress_mode in (True, False):
            with self.subTest(progress=progress_mode), TemporaryDirectory() as temporary:
                source = Path(temporary)
                for name in ("lib/_unit.scm", "lib/_unit.c", "gsc/gsc",
                             "gsi/gsi", "lib/libgambit.a"):
                    path = source / name
                    path.parent.mkdir(exist_ok=True)
                    path.write_text("fixture")
                calls = []

                def run(name, argv, cwd, cap, **kwargs):
                    calls.append((name, argv, cap, kwargs))
                    if name == "bootclean":
                        (source / "lib/_unit.c").unlink()
                    elif name == "source-core":
                        (source / "lib/_unit.c").write_text("regenerated")
                    return 0, "", False, 0.1

                stages = SimpleNamespace(progress_mode=progress_mode, run=run)
                with patch("gambit_smp.gambit_build_primitives.available_processors", return_value=7), \
                     patch("gambit_smp.gambit_build_primitives.time.monotonic", side_effect=[0, 1000]):
                    ok, observation = rebuild_source_core(stages, source, 10)
                self.assertEqual(ok, progress_mode)
                self.assertEqual(len(calls), 2 if progress_mode else 1)
                if progress_mode:
                    self.assertEqual(calls[-1][1], ["make", "--debug=b", "-j7", "GAMBOPT=p1", "core"])
                    self.assertIsInstance(calls[-1][3]["progress"], CoreBuildProgress)
                    self.assertEqual(observation["watchdogKind"], "completed-native-target-inactivity")
                    self.assertFalse(observation["fullTwoPassBootstrapEstablished"])


if __name__ == "__main__":
    unittest.main()
