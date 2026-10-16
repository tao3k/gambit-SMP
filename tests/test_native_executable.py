"""Standalone transport checks; mock executions are not runtime qualification."""
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp import native_capabilities as native


class NativeExecutableTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.directory = self.root / "step"
        self.directory.mkdir()
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        self.identity = self.root / "identity.json"
        self.identity.write_text("{}")
        self.source = self.root / "fixture.scm"
        self.source.write_text('(display "PASS\\n")')
        self.args = {"runtime": {"step": "producer", "output": "runtime"},
                     "identity": {"step": "producer", "output": "identity"},
                     "program": "fixture.scm", "stdout": "PASS\n"}
        self.ctx = SimpleNamespace(root=self.root, directory=self.directory, env={}, commands=[],
            artifact=lambda ref, kind: self.runtime if ref["output"] == "runtime" else self.identity,
            bind=lambda paths: list(paths), remaining=lambda: 10)
        self.log, self.stderr, self.change = "PASS\n", 0, None
        def require(stage, argv, cwd, cap, **kwargs):
            self.ctx.commands.append({"stderrBytes": self.stderr, "seconds": 1})
            if stage == "compile-executable":
                (self.directory / "fixture").write_text("mock executable")
                return ""
            if self.change:
                self.change()
            return self.log
        self.ctx.require = require

    def execute(self, capacity=5):
        with patch.object(native, "compiler", return_value=Path("/usr/bin/gcc")), \
                patch.object(native, "gnu_build_driver", return_value={"verified": True}), \
                patch.object(native, "available_processors", return_value=capacity), \
                patch("gambit_smp.suite_primitives.check_runtime"):
            return native.executable_test(self.args, self.ctx)

    def test_exact_source_runtime_and_capacity_without_admission(self):
        native.validate_executable_test(self.args, ["fixture.scm"])
        result = self.execute()
        self.assertEqual(5, result["hostCpuCapacity"])
        self.assertEqual("5", self.ctx.env["GAMBIT_SMP_AVAILABLE_CPUS"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(result["nativeGcPassed"])
        self.assertEqual("fixture-managed", result["processorTopology"])
        self.assertEqual(1, result["executionProcessors"])
        self.assertTrue(self.ctx.env["GAMBOPT"].startswith("p1,"))

    def test_host_managed_topology_is_derived_from_available_capacity(self):
        self.args["processorTopology"] = "host-managed"
        native.validate_executable_test(self.args, ["fixture.scm"])
        for cpu in (1, 5, 12):
            with self.subTest(cpu=cpu):
                result = self.execute(capacity=cpu)
                self.assertEqual(max(1, cpu - 1), result["executionProcessors"])
                self.assertTrue(self.ctx.env["GAMBOPT"].startswith(
                    f"p{result['executionProcessors']},"))
                self.assertEqual(str(cpu), self.ctx.env["GAMBIT_SMP_AVAILABLE_CPUS"])
                self.assertEqual(str(result["executionProcessors"]),
                                 self.ctx.env["GAMBIT_SMP_EXPECTED_PROCESSORS"])

    def test_unknown_topology_cannot_silently_use_one_processor(self):
        self.args["processorTopology"] = "unknown"
        with self.assertRaisesRegex(ValueError, "processor topology"):
            native.validate_executable_test(self.args, ["fixture.scm"])

    def test_completed_units_bind_exact_results_without_runtime_admission(self):
        self.ctx.progress_mode = True
        self.args["completedUnits"] = {"marker": "ROOT-DONE", "count": 2, "result": "987"}
        self.log = "ROOT-DONE 1/2 987\nROOT-DONE 2/2 987\nPASS\n"
        native.validate_executable_test(self.args, ["fixture.scm"])
        with patch.object(self.ctx, "require", wraps=self.ctx.require) as require:
            result = self.execute()
        self.assertEqual(2, result["completedUnitCount"])
        self.assertIn("progress", require.call_args.kwargs)
        self.assertFalse(result["runtimeAdmitted"])

    def test_completed_units_cannot_be_used_as_wall_timer_or_partial_pass(self):
        self.args["completedUnits"] = {"marker": "ROOT-DONE", "count": 2, "result": "987"}
        with self.assertRaisesRegex(ValueError, "inactivity"):
            self.execute()
        self.ctx.progress_mode = True
        with self.assertRaisesRegex(ValueError, "incomplete"):
            self.execute()

    def test_execution_cap_remains_nested_in_the_whole_step(self):
        for requested, expected in ((3, 3), (30, 10)):
            self.args["executionBudgetSeconds"] = requested
            native.validate_executable_test(self.args, ["fixture.scm"])
            with patch.object(self.ctx, "require", wraps=self.ctx.require) as require:
                self.execute()
            self.assertEqual(expected, require.call_args.args[3])

    def test_invalid_execution_budgets_are_rejected(self):
        for cap in (True, 0, -1, float("inf"), float("nan"), "30"):
            self.args["executionBudgetSeconds"] = cap
            with self.subTest(cap=cap), self.assertRaises(ValueError):
                native.validate_executable_test(self.args, ["fixture.scm"])

    def test_declared_parameters_reach_fixture_without_overriding_capacity(self):
        shared_environment = self.ctx.env
        self.args["parameters"] = {"GAMBIT_SMP_DEPTH": 131072}
        native.validate_executable_test(self.args, ["fixture.scm"])
        self.execute(capacity=5)
        self.assertEqual("131072", self.ctx.env["GAMBIT_SMP_DEPTH"])
        self.assertEqual("5", self.ctx.env["GAMBIT_SMP_AVAILABLE_CPUS"])
        self.assertNotIn("GAMBIT_SMP_DEPTH", shared_environment)

    def test_parameters_cannot_replace_tools_capacity_or_identity(self):
        for name, value in (("PATH", 1), ("GAMBOPT", 1), ("LD_PRELOAD", 1),
                            ("GAMBIT_SMP_ROOT", 1), ("GAMBIT_SMP_AVAILABLE_CPUS", 12),
                            ("GAMBIT_SMP_EXPECTED_PROCESSORS", 12),
                            ("GAMBIT_SMP_DEPTH", True), ("GAMBIT_SMP_DEPTH", 0),
                            ("GAMBIT_SMP_DEPTH", "131072"), ("GAMBIT_SMP_DEPTH", 2147483648)):
            self.args["parameters"] = {name: value}
            with self.subTest(name=name, value=value), self.assertRaises(ValueError):
                native.validate_executable_test(self.args, ["fixture.scm"])

    def test_declared_stderr_must_match_every_byte(self):
        transcript = "TRACE:gc-request\nTRACE:gc-request\n"
        self.args["stderr"] = transcript
        native.validate_executable_test(self.args, ["fixture.scm"])
        self.stderr = len(transcript.encode())
        path = self.directory / "run-executable.stderr"
        path.write_text(transcript)
        self.execute()
        path.write_text(transcript.replace("gc-request", "xx-request"))
        with self.assertRaises(ValueError):
            self.execute()
        path.write_text(transcript + "warning\n")
        self.stderr = path.stat().st_size
        with self.assertRaises(ValueError):
            self.execute()

    def test_nontext_stderr_contract_is_rejected(self):
        self.args["stderr"] = True
        with self.assertRaises(ValueError):
            native.validate_executable_test(self.args, ["fixture.scm"])

    def test_output_stderr_and_binary_drift_fail_closed(self):
        for kind in ("output", "stderr", "binary", "source", "copied-source"):
            with self.subTest(kind=kind):
                self.log, self.stderr, self.change = "PASS\n", 0, None
                if kind == "output":
                    self.log = "PARTIAL\n"
                elif kind == "stderr":
                    self.stderr = 1
                elif kind == "binary":
                    self.change = lambda: (self.directory / "fixture").write_text("changed")
                elif kind == "source":
                    self.change = lambda: self.source.write_text("changed source")
                else:
                    self.change = lambda: (self.directory / "fixture.scm").write_text("changed copy")
                with self.assertRaises(ValueError):
                    self.execute()

    def test_undeclared_program_is_rejected(self):
        with self.assertRaises(ValueError):
            native.validate_executable_test(self.args, [])

    def test_optional_latency_uses_observed_cpu_and_execution_time(self):
        options = {"path": "latencies.jsonl", "minimumSamples": 1000,
                   "percentiles": [55, 99]}
        self.args["latency"] = options
        native.validate_executable_test(self.args, ["fixture.scm"])
        with patch("gambit_smp.latency_observation.summarize", return_value={"samples": 1000}) as observe:
            result = self.execute(capacity=12)
        observe.assert_called_once_with(self.directory, options, 12, 1)
        self.assertEqual({"samples": 1000}, result["latencyObservation"])
        self.assertFalse(result["runtimeAdmitted"])

    def test_transcript_review_does_not_replace_native_latency_duration(self):
        self.args["stdoutTranscript"] = {"contract": "contract.json", "rules": "rules.ss"}
        self.args["latency"] = {"path": "latencies.jsonl", "minimumSamples": 1000,
                                "percentiles": [55, 99]}
        native.validate_executable_test(self.args, ["fixture.scm", "contract.json", "rules.ss"])
        def reviewed(*args):
            self.ctx.commands.append({"stderrBytes": 0, "seconds": 99})
            return {"answers": {"bad": [], "missing": []}}
        with patch("gambit_smp.native_transcript.review", side_effect=reviewed), \
                patch("gambit_smp.latency_observation.summarize", return_value={}) as observe:
            self.execute(capacity=12)
        observe.assert_called_once_with(self.directory, self.args["latency"], 12, 1)

    def test_complete_grid_requires_both_modes_and_independent_vms(self):
        from gambit_smp.framework import ROOT
        from gambit_smp.recipes import read_json
        grid = read_json(ROOT / "evidence/research/smp-threaded-vm-native-grid/native.recipe.json")
        steps = {step["id"]: step for step in grid["steps"]}
        target = steps["independent-vms"]
        self.assertTrue({"native-gsi", "native-gsc", "entry-safe-binding",
                         "entry-bypass-control", "entry-trajectories"} <= set(target["dependsOn"]))
        self.assertIn("independent-vms", steps["verdict"]["dependsOn"])
        self.assertEqual(steps["native-gsi"]["arguments"]["identity"], target["arguments"]["identity"])
        self.assertEqual(steps["native-gsc"]["arguments"]["runtime"], target["arguments"]["runtime"])
        self.assertNotIn("processors", target["arguments"])
