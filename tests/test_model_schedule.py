import json
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from gambit_smp import model_schedule as schedule
from gambit_smp import verify_protocols as verify
from gambit_smp.framework import digest


class ModelScheduleTests(unittest.TestCase):
    def test_cpu_and_memory_budgets_are_shared_not_multiplied(self):
        for cpus in (1, 2, 8, 12, 64):
            for gib in (8, 32, 128):
                row = schedule.resources(cpus, gib * 1024 ** 3)
                self.assertLessEqual(row["parallelControls"] * row["controlTlcWorkers"], cpus)
                self.assertEqual(cpus, row["positiveTlcWorkers"])
        row = schedule.resources(12, 32 * 1024 ** 3)
        self.assertEqual((2, 6), (row["parallelControls"], row["controlTlcWorkers"]))
        self.assertEqual(1, schedule.resources(12, None)["parallelControls"])
        for requested in (0, 3, True):
            with self.assertRaisesRegex(ValueError, "exceed"):
                schedule.resources(12, 32 * 1024 ** 3, requested)

    def test_positive_checks_never_share_a_control_batch(self):
        checks = [("old", str(i), "initOld") for i in range(5)] + [
            ("protocol", "sourceSafe", "initSource"),
            ("protocol", "combinedSafe", "initCombined")]
        grouped = list(schedule.batches(checks, 2))
        self.assertEqual([2, 2, 1, 1, 1], [len(batch) for batch in grouped])
        self.assertEqual(checks, [item for batch in grouped for item in batch])

    def test_independent_workers_overlap_and_preserve_result_order(self):
        barrier = threading.Barrier(2)
        def worker(item):
            barrier.wait(timeout=2)
            return item * 2
        self.assertEqual([2, 4], schedule.run_batch([1, 2], worker))

    def test_unknown_memory_falls_back_to_serial(self):
        with patch.object(schedule.os, "sysconf", side_effect=OSError("unavailable")):
            self.assertIsNone(schedule.physical_memory())
        with patch.object(schedule.os, "sysconf", side_effect=[2, 4096]):
            self.assertEqual(8192, schedule.physical_memory())

    def campaign(self, controls_only, fail=False, compiled=False):
        from tests.support import task_fixture
        with task_fixture('model-schedule') as (root, cache):
            modules = root / "src/gambit_smp"
            modules.mkdir(parents=True)
            for name in ("verify_protocols", "check_gambit", "framework", "tlc_values", "quint_backend", "model_schedule", "tlc_execution"):
                (modules / (name + ".py")).write_text("identity")
            model = root / "models/gambit"
            model.mkdir(parents=True)
            (model / "example.qnt").write_text("test model")
            manifest = root / "manifest.json"
            manifest.write_text(json.dumps({"schema": "gambit-protocol-extensions.v1",
                "quintVersion": "0.33.0", "contextInputs": {}, "cases": [{
                    "id": "example", "mode": "characterization", "temporal": "progress",
                    "oldInvariants": ["one", "two"], "invariants": ["sourceSafe", "combinedSafe"],
                    "protocolInitializers": {"sourceSafe": "initSource", "combinedSafe": "initCombined"}}]}))
            out = cache / "campaign"
            calls = []
            def check(snapshot, **options):
                calls.append(options)
                accepted = not(fail and options["invariant"] == "one")
                result = {"accepted": accepted, "exit": 1 if options["negative"] else 0,
                          "timeout": False, "seconds": 0.1}
                if compiled:
                    artifacts = {}
                    for name in ("example.tla", "example.cfg"):
                        path = options["cwd"] / name
                        path.write_text("fixture " + options["invariant"])
                        artifacts[name] = digest(path)
                    result["checker"] = {"artifacts": artifacts}
                trace = {"states": [{"x": 0}, {"x": 1}]} if options["negative"] else None
                return result, "fixture log " + options["invariant"], trace
            argv = ["verify", "--manifest", str(manifest), "--out", str(out), "--jobs", "2"]
            if controls_only:
                argv.append("--controls-only")
            if compiled:
                jar = root / "tlc.jar"
                jar.write_bytes(b"identity")
                argv.extend(["--tlc-liveness", "final", "--tlc-jar", str(jar)])
            with patch.object(verify, "ROOT", root), \
                 patch.object(verify, "available_processors", return_value=12), \
                 patch.object(verify, "physical_memory", return_value=32 * 1024 ** 3), \
                 patch.object(verify, "_task_check_output", return_value="0.33.0"), \
                 patch.object(verify, "check_model", side_effect=check), \
                 patch("sys.argv", argv):
                code = verify.main()
            receipt = json.loads((out / "receipt.json").read_text())
            receipt["testOutputLogs"] = {row["log"]: (out / row["log"]).read_text()
                                         for row in receipt["results"]}
            receipt["testOutputTraces"] = {path.name: json.loads(path.read_text())
                                           for path in out.glob("*.trace.json")}
            return code, receipt, calls

    def test_controls_only_cannot_become_whole_model_admission(self):
        code, receipt, calls = self.campaign(True)
        self.assertEqual(0, code)
        self.assertTrue(receipt["controlChecksPassed"])
        self.assertFalse(receipt["accepted"])
        self.assertFalse(receipt["runtimeAdmitted"])
        self.assertEqual(2, len(calls))
        self.assertEqual(2, len({row["cwd"] for row in calls}))
        self.assertTrue(all(row["timeout"] == 90 for row in calls))

    def test_failed_control_stops_before_positive_dispatch(self):
        code, receipt, calls = self.campaign(False, fail=True)
        self.assertEqual(1, code)
        self.assertFalse(receipt["accepted"])
        self.assertEqual(2, len(calls))
        self.assertTrue(all(row["negative"] for row in calls))

    def test_full_campaign_runs_both_positive_partitions_with_full_cpu_budget(self):
        code, receipt, calls = self.campaign(False)
        self.assertEqual(0, code)
        self.assertTrue(receipt["accepted"])
        self.assertEqual(4, len(calls))
        self.assertEqual({"initSource", "initCombined"},
                         {row["initializer"] for row in calls if not row["negative"]})
        self.assertEqual([6, 6, 12, 12], [row["tlcWorkers"] for row in receipt["results"]])
        self.assertIn(".cache/tasks/model-schedule/campaign/tlc-config-old.json", receipt["inputs"])
        self.assertIn(".cache/tasks/model-schedule/campaign/tlc-config-protocol.json", receipt["inputs"])

    def test_compiled_artifacts_do_not_replace_per_check_log_or_trace_names(self):
        code, receipt, _ = self.campaign(False, compiled=True)
        self.assertEqual(0, code)
        names = [row["log"] for row in receipt["results"]]
        self.assertEqual(4, len(set(names)))
        for row in receipt["results"]:
            expected = "example-" + row["variant"] + "-" + row["invariant"]
            self.assertEqual(expected + ".log", row["log"])
            self.assertEqual("fixture log " + row["invariant"],
                             receipt["testOutputLogs"][row["log"]])
            if row["variant"] == "old":
                trace = receipt["testOutputTraces"][expected + ".trace.json"]
                self.assertEqual(row["invariant"], trace["invariant"])
            self.assertEqual(2, len(row["checker"]["artifacts"]))


if __name__ == "__main__":
    unittest.main()
