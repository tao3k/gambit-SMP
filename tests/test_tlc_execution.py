import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import quint_backend as backend
from gambit_smp import tlc_execution as runner


SUCCESS = ("Finished checking temporal properties in 00s\n"
           "Model checking completed. No error has been found.\n"
           "3 states generated, 2 distinct states found, 0 states left on queue.\n")


class TlcExecutionTests(unittest.TestCase):
    def run_check(self, *, compile_seconds=4, compile_exit=0, drift=False,
                  output=SUCCESS, tlc_exit=0, ir_only=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            snapshot, jar, java = root / "example.qnt", root / "tlc.jar", root / "java"
            snapshot.write_text("model identity")
            jar.write_bytes(b"checker identity")
            java.write_bytes(b"launcher identity")
            cwd = root / "check"
            cwd.mkdir()
            now, calls = [0], []

            def execute(command, directory, timeout):
                calls.append((command, timeout))
                if command[-1] == "-version":
                    now[0] += 1
                    return 0, "java version identity", False, 1
                if command[1] == "compile":
                    now[0] += compile_seconds
                    compiled = ('{"stage":"compiling","modules":[]}' if ir_only else
                        "compile log\n---- MODULE example ----\nq_init == TRUE\nq_step == TRUE\n"
                        "q_inv == TRUE\nq_temporalProps == TRUE\n====\n")
                    return compile_exit, compiled, False, compile_seconds
                now[0] += 2
                if drift:
                    jar.write_bytes(b"changed checker")
                return tlc_exit, output, False, 2

            with patch.object(runner.shutil, "which", return_value=str(java)), \
                 patch.object(runner.time, "monotonic", side_effect=lambda: now[0]), \
                 patch.object(runner, "execute", side_effect=execute):
                result = backend.check(snapshot, initializer="initFixed", invariant="safe",
                    negative=False, timeout=90, cwd=cwd, temporal="progress",
                    liveness_schedule="final", tlc_jar=jar)
            self.assertFalse((cwd / "states").exists())
            cfg = (cwd / "example.cfg").read_text() if (cwd / "example.cfg").exists() else None
            return result, calls, cfg

    def test_final_schedule_preserves_properties_and_total_deadline(self):
        (row, output, _), calls, cfg = self.run_check()
        self.assertTrue(row["accepted"])
        self.assertEqual([90, 89, 85], [remaining for _, remaining in calls])
        self.assertEqual("progress", calls[1][0][calls[1][0].index("--temporal") + 1])
        self.assertNotIn("--out", calls[1][0])
        self.assertIn("PROPERTY q_temporalProps", cfg)
        self.assertEqual("final", calls[-1][0][calls[-1][0].index("-lncheck") + 1])
        self.assertEqual(7, row["seconds"])
        self.assertEqual(2, len(row["checker"]["artifacts"]))
        self.assertTrue(row["checker"]["tlcScratchRemoved"])
        self.assertIn("[TLC-final]", output)

    def test_compile_consumes_budget_not_an_additional_ninety_seconds(self):
        (row, _, _), calls, _ = self.run_check(compile_seconds=89)
        self.assertFalse(row["accepted"])
        self.assertTrue(row["timeout"])
        self.assertEqual(2, len(calls))

    def test_failed_compile_never_starts_tlc(self):
        (row, _, _), calls, _ = self.run_check(compile_exit=2)
        self.assertFalse(row["accepted"])
        self.assertEqual("compile", row["checker"]["phase"])
        self.assertEqual(2, len(calls))

    def test_compiler_ir_cannot_be_mistaken_for_tla_source(self):
        (row, _, _), calls, _ = self.run_check(ir_only=True)
        self.assertFalse(row["accepted"])
        self.assertEqual("compile", row["checker"]["phase"])
        self.assertEqual(2, len(calls))

    def test_final_temporal_completion_is_mandatory(self):
        (row, _, _), _, _ = self.run_check(output=SUCCESS.replace(
            "Finished checking temporal properties in 00s\n", ""))
        self.assertFalse(row["accepted"])

    def test_temporal_violation_cannot_become_safety_only_acceptance(self):
        (row, _, _), _, _ = self.run_check(
            output="Error: Temporal properties were violated.\n", tlc_exit=13)
        self.assertFalse(row["accepted"])

    def test_artifact_drift_denies_success(self):
        (row, _, _), _, _ = self.run_check(drift=True)
        self.assertFalse(row["accepted"])
        self.assertFalse(row["checker"]["inputsStable"])

    def test_unknown_config_is_not_silently_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "runtime.json"
            config.write_text(json.dumps({"lncheck": "off"}))
            with self.assertRaisesRegex(ValueError, "unsupported"):
                runner.runtime_config(config)
            for value in (True, 0, "auto"):
                config.write_text(json.dumps({"workers": value}))
                with self.assertRaisesRegex(ValueError, "worker count"):
                    runner.runtime_config(config)

    def test_off_schedule_is_not_supported(self):
        with self.assertRaisesRegex(ValueError, "unsupported"):
            backend.check(None, initializer="init", invariant="safe", negative=False,
                          timeout=90, cwd=None, liveness_schedule="off")


if __name__ == "__main__":
    unittest.main()
