"""Transport fixtures, not Gambit correctness or performance evidence."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from gambit_smp.framework import execute
from gambit_smp.process_observation import capture
from gambit_smp.research_kernel import completed_work
from gambit_smp.suite_primitives import SuiteCompletionProgress
from gambit_smp.gambit_build_primitives import BootstrapPhaseProgress, ConfigureProbeProgress, CoreBuildProgress, build_seed_core


class ProgressWatchdogTests(unittest.TestCase):
    def test_configure_probe_requires_complete_unique_result(self):
        progress = ConfigureProbeProgress()
        self.assertEqual(0, progress("checking for gcc... ", ""))
        self.assertEqual(0, progress("heartbeat\nchecking for gcc... \n", ""))
        self.assertEqual(1, progress("checking for gcc... yes\n", ""))
        self.assertEqual(1, progress("checking for gcc... yes\nchecking for gcc... yes\n", ""))
        self.assertEqual(2, progress("checking for gcc... yes\nchecking for mmap... no\n", ""))

    def test_configure_real_probe_progress_survives_wall_window(self):
        program = "import time\nfor i in range(4):\n print('checking feature%d... yes' % i,flush=True)\n time.sleep(.2)"
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .5, None,
                               progress=ConfigureProbeProgress())
        self.assertEqual(0, observed.exit)
        self.assertFalse(observed.timeout)
        self.assertGreater(observed.seconds, .5)

    def test_seed_core_uses_same_phase_progress_without_changing_window(self):
        calls = []
        def run(*args, **kwargs):
            calls.append((args, kwargs))
            return 0, "", False, 1
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary)
            for name in ("gsi/gsi", "gsc/gsc", "lib/libgambit.a"):
                path = source / name
                path.parent.mkdir(exist_ok=True)
                path.write_text("transport artifact, not runtime qualification")
            with patch("gambit_smp.gambit_build_primitives.available_processors", return_value=7):
                ok, result = build_seed_core(SimpleNamespace(run=run, progress_mode=True), source, 130)
        self.assertTrue(ok)
        self.assertEqual(130, calls[0][0][-1])
        self.assertIsInstance(calls[0][1]["progress"], BootstrapPhaseProgress)
        self.assertEqual("completed-native-target-inactivity", result["watchdogKind"])
        self.assertIn("--debug=b", calls[0][0][1])

    def test_core_counts_completed_native_targets_not_started_or_phony_targets(self):
        progress = CoreBuildProgress()
        self.assertEqual(0, progress("gcc -c mem.c\nMust remake target 'mem.o'.\n", ""))
        self.assertEqual(0, progress("Successfully remade target file 'phase3'.\n", ""))
        self.assertEqual(1, progress("Successfully remade target file `mem.o'.\n", ""))
        self.assertEqual(1, progress("Successfully remade target file 'mem.o'.\n"
                                     "Successfully remade target file 'mem.o'.\n", ""))
        self.assertEqual(2, progress("Successfully remade target file 'mem.o'.\n"
                                     "Successfully remade target file 'libgambit.a'.\n", ""))

    def test_bootstrap_progress_requires_ordered_phase_boundaries(self):
        progress = BootstrapPhaseProgress()
        self.assertEqual(0, progress("heartbeat\n*** making phase1\n", ""))
        self.assertEqual(1, progress("*** making phase1\n*** making phase2\n", ""))
        self.assertEqual(0, progress("*** making phase1\n*** making phase1\n*** making phase2\n", ""))
        self.assertEqual(0, progress("*** making phase1\n*** making phase4\n", ""))
        transcript = "".join(f"*** making phase{i}\n" for i in (1, 2, 3, 4, 1, 2, 3, 4))
        self.assertEqual(7, progress(transcript, ""))
        self.assertEqual(7, progress(transcript + "*** making phase1\n", ""))

    def test_bootstrap_real_progress_survives_wall_window(self):
        program = "import time\nfor i in (1,2,3,4,1,2,3,4):\n print('*** making phase%d' % i,flush=True)\n time.sleep(.2)"
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .8, None,
                               progress=BootstrapPhaseProgress())
        self.assertEqual(0, observed.exit)
        self.assertFalse(observed.timeout)
        self.assertGreater(observed.seconds, .8)

    def test_bootstrap_repeated_phase_cannot_renew_watchdog(self):
        program = "import time\nfor _ in range(100):\n print('*** making phase1',flush=True)\n time.sleep(.02)"
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .3, None,
                               progress=BootstrapPhaseProgress())
        self.assertTrue(observed.timeout)
        self.assertEqual(-9, observed.exit)

    def test_only_completed_runner_counters_advance(self):
        progress = SuiteCompletionProgress(3)
        self.assertEqual(0, progress("heartbeat\n[ 0| 0] 0% start\n", ""))
        self.assertEqual(1, progress("[ 1| 0] 33% done\n", ""))
        self.assertEqual(1, progress("[ 1| 0] 33% repeated\n[999|0] 100% fake\n", ""))
        self.assertEqual(2, progress("[ 1| 1] 66% failed but completed\n", ""))
        self.assertEqual(2, progress("[ 0| 0] 0% reset\n", ""))

    def test_actual_progress_can_exceed_wall_window(self):
        program = "import time\nfor i in range(6):\n print('[%d|0] 10%% complete' % (i+1),flush=True)\n time.sleep(.25)"
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, 1, None,
                               progress=SuiteCompletionProgress(6))
        self.assertEqual(0, observed.exit)
        self.assertFalse(observed.timeout)
        self.assertTrue(observed.group_quiescent)
        self.assertGreater(observed.seconds, 1)

    def test_repeated_output_cannot_keep_stalled_process_alive(self):
        program = "import time\nfor i in range(200):\n print('[1|0] 10% repeated',flush=True)\n time.sleep(.02)"
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .3, None,
                               progress=SuiteCompletionProgress(2))
        self.assertTrue(observed.timeout)
        self.assertEqual(-9, observed.exit)
        self.assertTrue(observed.group_quiescent)
        self.assertLess(observed.seconds, 2)

    def test_parent_executor_uses_same_progress_contract(self):
        program = "import time\nfor i in range(6):\n print('[%d|0] 10%% complete' % (i+1),flush=True)\n time.sleep(.25)"
        metadata = {}
        with tempfile.TemporaryDirectory() as temporary:
            code, output, timeout, seconds = execute([sys.executable, "-u", "-c", program],
                temporary, 1, metadata=metadata, progress_check=SuiteCompletionProgress(6))
        self.assertEqual(0, code)
        self.assertFalse(timeout)
        self.assertGreater(seconds, 1)
        self.assertIn("[6|0]", output)
        self.assertTrue(metadata["processGroupQuiescent"])

    def test_supervisor_ignores_log_growth_and_unfinished_processes(self):
        with tempfile.TemporaryDirectory() as temporary:
            out = Path(temporary)
            directory = out / "run/native"
            directory.mkdir(parents=True)
            steps = [{"id": "native"}]
            (directory / "noise.log").write_text("heartbeat" * 100)
            process = directory / "child.process.json"
            process.write_text(json.dumps({"schema": "recipe-process-observation.v1", "state": "STARTED"}))
            self.assertEqual(0, completed_work(out, steps))
            event = directory / "child.progress.json"
            event.write_text(json.dumps({"schema": "native-completed-progress.v1", "completed": 1}))
            self.assertEqual(1, completed_work(out, steps))
            event.touch()
            self.assertEqual(1, completed_work(out, steps))
            process.write_text(json.dumps({"schema": "recipe-process-observation.v1", "state": "OBSERVED",
                "exit": 70, "completionObserved": True, "parentReaped": True}))
            self.assertEqual(2, completed_work(out, steps))
