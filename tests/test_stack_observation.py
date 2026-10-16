"""Owned-child diagnostic transport; not an SMP correctness assertion."""
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from gambit_smp.process_observation import capture
from gambit_smp.native_capabilities import host_tools, validate_executable_test


class StackObservationTests(unittest.TestCase):
    def test_requested_sampler_reaches_native_tool_context(self):
        steps = [{"capability": "gambit.executable-test",
                  "arguments": {"stackSampleAfterSeconds": 20}}]
        with patch("gambit_smp.native_capabilities.sys.platform", "darwin"), \
             patch("gambit_smp.native_capabilities.shutil.which", return_value="/usr/bin/true"), \
             patch.object(Path, "is_file", return_value=True), \
             patch.object(Path, "resolve", lambda path, **kwargs: path):
            tools, _ = host_tools(Path("/usr/bin/true"), steps, {})
            self.assertEqual(Path("/usr/bin/sample"), tools["darwinSample"])
            tools, _ = host_tools(Path("/usr/bin/true"), [], {})
            self.assertNotIn("darwinSample", tools)

    def test_non_darwin_sampling_contract_is_not_silently_ignored(self):
        steps = [{"capability": "gambit.executable-test",
                  "arguments": {"stackSampleAfterSeconds": 20}}]
        with patch("gambit_smp.native_capabilities.sys.platform", "linux"), \
             patch.object(Path, "resolve", lambda path, **kwargs: path):
            with self.assertRaisesRegex(ValueError, "tool unavailable"):
                host_tools(Path("/usr/bin/true"), steps, {})

    def test_completed_child_is_not_sampled(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch("gambit_smp.stack_observation.sample") as observe:
                result = capture([sys.executable, "-c", "print('done')"], directory, 2,
                                 os.environ.copy(), diagnostic={"afterSeconds": 1})
        self.assertEqual("done\n", result.stdout)
        self.assertEqual(0, result.exit)
        self.assertFalse(result.timeout)
        self.assertTrue(result.group_quiescent)
        observe.assert_not_called()

    def test_sampling_observes_owned_child_without_widening_deadline(self):
        observed = []
        def record(process, cwd, budget, env, diagnostic):
            self.assertIsNone(process.poll())
            self.assertLessEqual(budget, .1)
            observed.append(process.pid)
        with tempfile.TemporaryDirectory() as directory:
            with patch("gambit_smp.stack_observation.sample", side_effect=record):
                result = capture([sys.executable, "-c", "import time; time.sleep(10)"],
                    directory, .1, os.environ.copy(), diagnostic={"afterSeconds": .02})
        self.assertEqual([result.pid], observed)
        self.assertTrue(result.timeout)
        self.assertTrue(result.group_quiescent)
        self.assertLess(result.seconds, 1)

    def test_diagnostic_error_kills_and_reaps_original_child(self):
        pids = []
        def fail(process, *args):
            pids.append(process.pid)
            raise ValueError("diagnostic tool drift")
        with tempfile.TemporaryDirectory() as directory:
            with patch("gambit_smp.stack_observation.sample", side_effect=fail):
                with self.assertRaisesRegex(ValueError, "tool drift"):
                    capture([sys.executable, "-c", "import time; time.sleep(10)"],
                        directory, 1, os.environ.copy(), diagnostic={"afterSeconds": .02})
        self.assertEqual(1, len(pids))
        with self.assertRaises(ProcessLookupError):
            os.kill(pids[0], 0)

    def test_invalid_delays_are_not_recipe_options(self):
        args = {"runtime": {"step": "producer", "output": "runtime"},
                "identity": {"step": "producer", "output": "identity"},
                "program": "fixture.scm", "stdout": "PASS\n"}
        for delay in (True, 0, -1, 61, float("nan")):
            with self.assertRaises(ValueError):
                validate_executable_test({**args, "stackSampleAfterSeconds": delay}, ["fixture.scm"])
