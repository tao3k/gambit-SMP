import unittest
import shlex
import subprocess
import sys
from unittest.mock import Mock, patch
from tempfile import TemporaryDirectory
from pathlib import Path

from gambit_smp.gambit_build_primitives import (build_capacity, compiler_rss_limit,
                                              core_command, build_seed_core,
                                              host_compiler_reservation, rebuild_source_core)


class MemoryCapacityTests(unittest.TestCase):
    def test_unknown_job_exclusively_reserves_available_budget(self):
        plan=build_capacity(12,memory_bytes=3072,parent_reserve_bytes=128,job_reserve_bytes=2944)
        self.assertEqual(1,plan['makeJobs'])
        self.assertEqual(1,plan['compilerProcessors'])
        self.assertEqual(12,plan['availableProcessors'])
        self.assertFalse(plan['reservationIsMeasuredUpperBound'])
        self.assertEqual(['make','-j1','GAMBOPT=p1','core'],core_command(plan))

    def test_eight_gibibyte_runner_admits_eight_parallel_compiler_jobs(self):
        with patch.dict("os.environ", {}, clear=False):
            with patch("os.sysconf", side_effect=lambda name: 4096 if name == "SC_PAGE_SIZE" else 2 * 1024 ** 2):
                reservation = host_compiler_reservation()
        plan = build_capacity(12, **reservation)
        self.assertEqual(8, plan["makeJobs"])
        self.assertEqual(1, plan["compilerProcessors"])
        self.assertEqual(8 * 1024 ** 3, plan["memoryBytes"])
        self.assertEqual(8 * 1024 ** 3, compiler_rss_limit(reservation))
        self.assertEqual(["make", "-j8", "GAMBOPT=p1", "core"], core_command(plan))

    def test_thirty_two_gibibyte_host_runs_eight_jobs_within_eight_gibibyte_envelope(self):
        with patch.dict("os.environ", {}, clear=False):
            with patch("os.sysconf", side_effect=lambda name: 4096 if name == "SC_PAGE_SIZE" else 8 * 1024 ** 2):
                reservation = host_compiler_reservation()
        plan = build_capacity(12, **reservation)
        self.assertEqual(8, plan["makeJobs"])
        self.assertEqual(1, plan["compilerProcessors"])
        self.assertEqual(8 * 1024 ** 3, reservation["memory_bytes"])
        self.assertEqual(8 * 1024 ** 3, compiler_rss_limit(reservation))
        self.assertEqual(["make", "-j8", "GAMBOPT=p1", "core"], core_command(plan))

    def test_low_ram_host_throttles_parallelism_adaptively(self):
        with patch.dict("os.environ", {}, clear=False):
            with patch("os.sysconf", side_effect=lambda name: 4096 if name == "SC_PAGE_SIZE" else 512 * 1024):
                reservation = host_compiler_reservation()
        plan = build_capacity(12, **reservation)
        self.assertEqual(1, plan["makeJobs"])
        self.assertEqual(2 * 1024 ** 3, reservation["memory_bytes"])

    def test_memory_credits_and_cpu_both_limit_concurrency(self):
        self.assertEqual(2,build_capacity(12,memory_bytes=1000,parent_reserve_bytes=200,
                                        job_reserve_bytes=400)['makeJobs'])
        self.assertEqual(2,build_capacity(2,memory_bytes=1000,parent_reserve_bytes=200,
                                        job_reserve_bytes=100)['makeJobs'])

    def test_make_lineage_adaptive_memory_estimator_scales_with_c_source_size(self):
        from gambit_smp.make_lineage import estimate_recipe_memory_bytes
        with TemporaryDirectory() as tmp:
            small = Path(tmp) / "small.c"
            small.write_bytes(b"x" * (32 * 1024))
            giant = Path(tmp) / "giant.c"
            giant.write_bytes(b"x" * (4 * 1024 * 1024))
            small_est = estimate_recipe_memory_bytes("object", [small])
            giant_est = estimate_recipe_memory_bytes("object", [giant])
            self.assertEqual(160 * 1024 * 1024, small_est)
            self.assertGreaterEqual(giant_est, 1600 * 1024 * 1024)
            self.assertLessEqual(giant_est, 2200 * 1024 * 1024)
            self.assertEqual(768 * 1024 * 1024, estimate_recipe_memory_bytes("emit", [small]))

    def test_make_lineage_memory_gate_executes_command_under_slot(self):
        from gambit_smp import make_lineage
        with TemporaryDirectory() as tmp:
            gate_dir = Path(tmp) / "gate"
            out_file = Path(tmp) / "ran.txt"
            rc = make_lineage.main([
                "--memory-gate", str(gate_dir), "object", "foo.o", "foo.c", "--",
                sys.executable, "-c", f"from pathlib import Path; Path({str(out_file)!r}).write_text('ok')",
            ])
            self.assertEqual(0, rc)
            self.assertEqual("ok", out_file.read_text())
            self.assertEqual(0, make_lineage.main(["--memory-gate", str(gate_dir), "promote", "a", "b"]))

    def test_incomplete_invalid_or_oversized_reservation_refuses(self):
        for args in [dict(memory_bytes=1),dict(memory_bytes=True,parent_reserve_bytes=0,job_reserve_bytes=1),
                     dict(memory_bytes=10,parent_reserve_bytes=10,job_reserve_bytes=1),
                     dict(memory_bytes=10,parent_reserve_bytes=1,job_reserve_bytes=10),
                     dict(memory_bytes=10,parent_reserve_bytes=-1,job_reserve_bytes=1)]:
            with self.subTest(args=args),self.assertRaises(ValueError):build_capacity(12,**args)


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
            stages.memory_reservation = {}
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
