import unittest
import shlex
import subprocess
import sys
from unittest.mock import Mock, patch
from tempfile import TemporaryDirectory
from pathlib import Path

from gambit_smp.gambit_build_primitives import build_capacity, core_command, build_seed_core


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
            stages.run.assert_called_once_with("seed-core", ["make", "-j7", "GAMBOPT=p1", "core"], source, 120)
            self.assertEqual(7, observation["capacity"]["availableProcessors"])
            self.assertEqual("host-auto-shared-budget", observation["processorSelection"])


if __name__ == "__main__":
    unittest.main()
