"""Transport fixtures, not Gambit correctness or performance evidence."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from gambit_smp.framework import execute
from gambit_smp.process_observation import capture, EvidenceProgress
from gambit_smp.research_kernel import completed_work
from gambit_smp.suite_primitives import SuiteCompletionProgress
from gambit_smp.gambit_build_primitives import BootstrapPhaseProgress, ConfigureProbeProgress, CoreBuildProgress, build_seed_core


def resume_retained_progress(request):
    """Fresh-owner fixture: journal survives, but producer liveness is not inherited."""
    from gambit_smp.reasoning_history import read_execution_checkpoint
    state = read_execution_checkpoint(Path(request["root"]), Path(request["run"]))
    records = [row for row in state["records"] if row["payload"].get("event") == "progress"]
    cursor = records[-1]["payload"]["witness"]["cursorAfter"]
    fixture = ProgressWatchdogTests()
    try:
        progress = fixture.evidence_progress()
        progress.cursor = {tuple(row[:-1]): row for row in cursor}
        progress.facts["progress_active"] = []
        count = progress(json.dumps({"counter": cursor[0][-1] + 1, "completed": True}), "")
        return {"prefixIdentity": state["prefixIdentity"], "renewals": count,
                "cursor": cursor, "advanced": progress.witness["advanced"],
                "rejected": progress.witness["rejected"]}
    finally:
        fixture.doCleanups()


class ProgressWatchdogTests(unittest.TestCase):
    def evidence_progress(self, cursor=0):
        from ascent import Engine
        from gambit_smp.ascent_program import load_component_catalog
        from gambit_smp.framework import ROOT
        engine = Engine()
        catalog = load_component_catalog(ROOT / "evidence/dsl/components.json",
            entry="checkpoint-state", constructor="make-checkpoint-state", trusted=True)
        declaration = catalog["nativeComponents"]
        with engine.components(declaration["manifest"], declaration["sources"],
                               declaration["entry"], trusted=True) as module:
            with module.call(declaration["constructor"]) as value:
                session = value.open_session()
        self.addCleanup(session.close)
        identity = ("test-phase", "owned-worker", "attempt", "completed-unit", "fixture-sha")
        facts = {"progress_contract": [identity], "progress_active": [identity[:3]],
                 "progress_cursor": [(*identity, cursor)]}
        def collect(stdout, stderr):
            observations = {"progress_sample": [], "progress_attested": [], "progress_completed": []}
            for line in stdout.splitlines():
                try:
                    row = json.loads(line)
                except json.JSONDecodeError:
                    continue
                event = str(row["counter"])
                observations["progress_sample"].append((event, *identity, row["counter"]))
                observations["progress_attested"].append((event,))
                if row.get("completed") is True:
                    observations["progress_completed"].append((event,))
            return observations
        return EvidenceProgress(session, facts, collect)

    def test_scheme_admitted_work_renews_original_inactivity_window_and_is_recorded(self):
        program = ("import time,json\nfor i in range(1,5):\n"
                   " sum(range(10000))\n print(json.dumps({'counter':i,'completed':True}),flush=True)\n time.sleep(.4)")
        records = []
        progress = self.evidence_progress()
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .7, None,
                progress=progress, recorder=lambda event, token, fields: records.append((event, token, fields)))
        self.assertEqual(observed.exit, 0)
        self.assertFalse(observed.timeout)
        self.assertGreater(observed.seconds, .7)
        renewals = [row for row in records if row[0] == "progress"]
        self.assertTrue(renewals)
        self.assertTrue(all(row[2]["witness"]["advanced"] for row in renewals))
        self.assertEqual(len({row[1] for row in records}), 1)
        self.assertTrue(observed.group_quiescent)

    def test_replayed_completed_messages_cannot_keep_a_stalled_child_alive(self):
        program = ("import time,json\nfor _ in range(100):\n"
                   " print(json.dumps({'counter':1,'completed':True}),flush=True)\n time.sleep(.03)")
        progress = self.evidence_progress()
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .7, None,
                               progress=progress)
        self.assertTrue(observed.timeout)
        self.assertEqual(progress.renewals, 1)
        self.assertTrue(observed.group_quiescent)

    def test_heartbeat_counter_increase_does_not_renew_without_completed_work(self):
        program = ("import time,json\nfor i in range(100):\n"
                   " print(json.dumps({'counter':i,'completed':False}),flush=True)\n time.sleep(.03)")
        progress = self.evidence_progress()
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .7, None,
                               progress=progress)
        self.assertTrue(observed.timeout)
        self.assertEqual(progress.renewals, 0)
        self.assertTrue(observed.group_quiescent)

    def test_restored_cursor_is_a_baseline_not_a_watchdog_renewal(self):
        progress = self.evidence_progress()
        text = json.dumps({"counter": 3, "completed": True})
        self.assertEqual(progress(text, ""), 1)
        restored = self.evidence_progress(cursor=3)
        self.assertEqual(restored(text, ""), 0)
        self.assertEqual(restored(json.dumps({"counter": 4, "completed": True}), ""), 1)

    def test_collector_cannot_replace_current_actor_or_declared_work_contract(self):
        progress = self.evidence_progress()
        progress.observer = lambda *_: {"progress_active": [("other", "actor", "epoch")]}
        with self.assertRaisesRegex(ValueError, "cannot replace"):
            progress("", "")

    def test_inference_and_recording_time_cannot_invent_later_progress(self):
        import subprocess
        from gambit_smp.process_observation import communicate_progress
        clock = [0.0]
        class Process:
            args = ["clock-fixture"]
            def communicate(self, timeout):
                if clock[0] == 0:
                    clock[0] = .1
                    raise subprocess.TimeoutExpired(self.args, timeout, output="completed")
                return "completed", ""
        def verify(*_):
            clock[0] = 1.0
            return 1
        with patch("gambit_smp.process_observation.time.monotonic", side_effect=lambda: clock[0]):
            with self.assertRaises(subprocess.TimeoutExpired):
                communicate_progress(Process(), .5, verify)

    def test_omitted_batch_witness_cannot_inherit_previous_attestation(self):
        progress = self.evidence_progress()
        self.assertEqual(progress(json.dumps({"counter": 1, "completed": True}), ""), 1)
        identity = ("test-phase", "owned-worker", "attempt", "completed-unit", "fixture-sha")
        progress.observer = lambda *_: {"progress_sample": [("1", *identity, 2)]}
        self.assertEqual(progress("", ""), 1)
        self.assertEqual(progress.witness["advanced"], [])
        self.assertIn(["1", "unattested"], progress.witness["rejected"])

    def test_progress_witnesses_use_existing_immutable_execution_journal(self):
        from tests.test_research_resumption import ResearchResumptionTests
        from gambit_smp.research_kernel import retain_run_record, process_recorder
        from gambit_smp.reasoning_history import read_execution_checkpoint
        fixture = ResearchResumptionTests()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        run = fixture.root / ".cache/progress-witness"
        run.mkdir()
        journal = retain_run_record(fixture.root, run / "run-header.json", "progress-witness-fixture",
            {"schema": "research-run-header.v1", "runId": "fixture-run", "inputs": {}}, {})
        record = process_recorder(fixture.root, run, journal)
        program = ("import time,json\nfor i in range(1,4):\n"
                   " print(json.dumps({'counter':i,'completed':True}),flush=True)\n time.sleep(.4)")
        observed = capture([sys.executable, "-u", "-c", program], run, .7, None,
                           progress=self.evidence_progress(), recorder=record)
        self.assertEqual(observed.exit, 0)
        records = read_execution_checkpoint(fixture.root, run)["records"]
        progress = [row for row in records if row["payload"].get("event") == "progress"]
        self.assertGreaterEqual(len(progress), 2)
        self.assertEqual(len(progress), len({row["path"] for row in progress}))
        self.assertEqual(progress[-1]["payload"]["witness"]["cursorAfter"][0][-1], 3)
        # Transport recovery retains the prefix; it has not synthesized a terminal verdict.
        self.assertFalse(any(row["payload"].get("schema") == "research-terminal-observation.v1"
                             for row in records))
        prefix = read_execution_checkpoint(fixture.root, run)["prefixIdentity"]
        for path in run.iterdir():
            if path.is_dir():__import__('shutil').rmtree(path)
            else:path.unlink()
        run.rmdir()
        from gambit_smp.task_processes import run as task_run
        code = ("import json,sys; from tests.test_progress_watchdog import resume_retained_progress; "
                "print(json.dumps(resume_retained_progress(json.load(sys.stdin))))")
        child = task_run([sys.executable, "-c", code],
            input=json.dumps({"root": str(fixture.root), "run": str(run)}),
            text=True, capture_output=True, timeout=30)
        self.assertEqual(child.returncode, 0, child.stderr)
        restored = json.loads(child.stdout)
        self.assertEqual(restored["prefixIdentity"], prefix)
        self.assertEqual(restored["cursor"][0][-1], 3)
        self.assertEqual(restored["renewals"], 0)
        self.assertEqual(restored["advanced"], [])

    def test_completed_progress_does_not_replace_a_failed_process_exit(self):
        program = "import json,sys; print(json.dumps({'counter':1,'completed':True}),flush=True); sys.exit(7)"
        with tempfile.TemporaryDirectory() as temporary:
            observed = capture([sys.executable, "-u", "-c", program], temporary, .7, None,
                               progress=self.evidence_progress())
        self.assertEqual(observed.exit, 7)
        self.assertFalse(observed.timeout)
        self.assertTrue(observed.group_quiescent)

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

    def test_phase_observations_do_not_invent_timing_for_buffered_announcements(self):
        ticks = iter((10.0, 12.0, 25.0))
        progress = BootstrapPhaseProgress(clock=lambda: next(ticks))
        self.assertEqual(0, progress("*** making phase1\n", ""))
        self.assertEqual(2, progress("*** making phase1\n*** making phase2\n*** making phase3\n", ""))
        self.assertEqual([2.0, 15.0, 15.0],
                         [row["firstObservedSeconds"] for row in progress.boundaries])
        self.assertEqual([1, 2, 3], [row["phase"] for row in progress.boundaries])
        # Re-reading the same prefix must neither create receipts nor renew work.
        self.assertEqual(2, progress("*** making phase1\n*** making phase2\n*** making phase3\n", ""))

    def test_phase_observer_retains_prefix_before_caller_finalization(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "phase-observations.json"
            progress = BootstrapPhaseProgress(observation_path=path)
            first = "*** making phase1\n"
            progress(first, "diagnostic\n")
            self.assertFalse(json.loads(path.read_text())["completionObserved"])
            self.assertEqual(first, (path.parent / "from-scratch.partial.stdout").read_text())
            # A repeated poll cannot duplicate bytes; no success/finalizer is called.
            progress(first, "diagnostic\n")
            self.assertEqual(first, (path.parent / "from-scratch.partial.stdout").read_text())
            progress(first + "*** making phase2\n", "diagnostic\n")
            self.assertEqual(2, len(json.loads(path.read_text())["boundaries"]))

    def test_phase_prefix_survives_killed_observer_without_success_receipt(self):
        program = ("from pathlib import Path\nimport os,signal,sys\n"
                   "from gambit_smp.gambit_build_primitives import BootstrapPhaseProgress\n"
                   "p=BootstrapPhaseProgress(observation_path=Path(sys.argv[1]))\n"
                   "p('*** making phase1\\n', '')\n"
                   "print('PREFIX-SAVED',flush=True)\nos.kill(os.getpid(),signal.SIGKILL)\n")
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "phase-observations.json"
            observed = capture([sys.executable, "-c", program, str(path)],
                               directory, 2, None)
            self.assertFalse(observed.timeout)
            self.assertEqual(-9, observed.exit)
            self.assertIn("PREFIX-SAVED", observed.stdout)
            self.assertFalse(json.loads(path.read_text())["completionObserved"])
            self.assertEqual("*** making phase1\n",
                             (path.parent / "from-scratch.partial.stdout").read_text())

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
        self.assertEqual(dict(kind='upstream-suite-counter', reportedGood=1, reportedFailed=1,
                              completed=2, expected=3), progress.witness)
        self.assertEqual(2, progress("[ 0| 0] 0% reset\n", ""))
        self.assertEqual(1, progress.witness['reportedFailed'])

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
