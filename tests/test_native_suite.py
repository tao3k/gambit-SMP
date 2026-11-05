from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import unittest
from gambit_smp import native_suite
from unittest.mock import call, patch
from tests.support import task_fixture

from gambit_smp.native_suite import admitted_suite, selected_files, campaign_status, extra_fixture, admitted_processors, fixture_patch, partitions, runtime_view, capacity, runner_option, atomic_suite


class ThreadRequestFixtureTests(unittest.TestCase):
    def sources(self):
        root = Path(__file__).resolve().parents[1]
        original = (root / "models/gambit/native/pr1047/thread_interrupt_ended.scm").read_bytes()
        bootstrap = json.loads((root / "evidence/research/retained/modern-c/frozen-568e0276-smp/shared-procedure-dispatch-bootstrap.json").read_text())
        header = subprocess.check_output(
            ["git", "-C", str(root / "vendor/gambit"), "show", bootstrap["baseRevision"] + ":lib/_thread#.scm"])
        return root, original, header

    def test_current_constructor_retains_original_assertions_and_native_bytes(self):
        from gambit_smp.suite_primitives import thread_request_fixture
        root, original, header = self.sources()
        proof = json.loads((root / "evidence/research/retained/modern-c/pr-gsi/request-constructor-refinement.json").read_text())
        derived = thread_request_fixture(original, header)
        self.assertEqual(hashlib.sha256(derived).hexdigest(), proof["projectedSha256"])
        self.assertIn(b"(macro-make-thread-request target", derived)
        self.assertEqual(original[original.index(b"      ;; Use trylock"):],
                         derived[derived.index(b"      ;; Use trylock"):])
        self.assertEqual(original.count(b"(test-"), derived.count(b"(test-"))

    def test_ambiguous_old_call_or_changed_constructor_refuses_projection(self):
        from gambit_smp.suite_primitives import thread_request_fixture
        _, original, header = self.sources()
        for source, contract in [
            (original + original, header),
            (original.replace(b"##thread-intr-propagate!", b"other"), header),
            (original, header.replace(b"macro-make-thread-request", b"other")),
        ]:
            with self.subTest(source=hashlib.sha256(source).hexdigest()):
                with self.assertRaises(ValueError):
                    thread_request_fixture(source, contract)


class NativeSuiteTests(unittest.TestCase):
    def test_recipe_and_run_receipts_share_one_owned_pool(self):
        from gambit_smp.suite_primitives import suite_workers
        with task_fixture('suite-receipt-owners') as (root, cache):
            observed = set()
            for tail in ('runs/one', 'fixtures/ci-threads/run/gsi',
                         'fixtures/ci-threads/run/gsc'):
                with suite_workers(root, cache / tail, 1) as slots:
                    observed.add(slots.get())
            self.assertEqual({cache / 'build/suite-tests/worker-0'}, observed)
            foreign = root / '.cache/tasks/other/runs/one'
            with self.assertRaisesRegex(ValueError, 'another task'):
                with suite_workers(root, foreign, 1):
                    self.fail('foreign task acquired this pool')
            self.assertFalse((root / '.cache/tasks/other/build').exists())

    def test_fixed_task_slots_reuse_bytes_and_cwd_across_runs(self):
        from gambit_smp.suite_primitives import digest, suite_workers, prepare_suite_worker
        with task_fixture('suite-slots') as (root, cache):
            runtime = root / 'runtime'
            for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
                (runtime / name).mkdir(parents=True)
            copied = root / 'inputs'
            copied.mkdir()
            (copied / 'case.scm').write_text('(exit 0)')
            directories = set()
            for run in ('first', 'second', 'third'):
                with suite_workers(root, cache / 'runs' / run, 2) as slots:
                    for index in range(12):
                        slot = slots.get()
                        with patch("gambit_smp.suite_primitives.digest", wraps=digest) as observed:
                            work, storage = prepare_suite_worker(runtime, copied, slot)
                        self.assertEqual(1, sum(call.args == (work / 'case.scm',)
                                                for call in observed.call_args_list))
                        self.assertEqual(2, sum(call.args == (copied / 'case.scm',)
                                                for call in observed.call_args_list))
                        directories.add(work)
                        if run == 'first' and index < 2:
                            (work / 'retained.o1').write_text('completed bytes')
                        else:
                            self.assertTrue(storage['workspaceReused'])
                            self.assertEqual(0, storage['filesCopied'])
                            self.assertEqual('completed bytes', (work / 'retained.o1').read_text())
                        self.assertFalse(storage['compiledResultReused'])
                        slots.put(slot)
            self.assertEqual(2, len(directories))
            self.assertFalse((cache / 'runs').exists())

    def test_suite_slot_delta_resets_only_test_data_not_bootstrap(self):
        from gambit_smp.suite_primitives import suite_workers, prepare_suite_worker
        with task_fixture('suite-delta') as (root, cache):
            runtime = root / 'runtime'
            for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
                (runtime / name).mkdir(parents=True)
            seed = runtime / 'gsi/gsi'
            seed.write_bytes(b'compiled seed')
            copied = root / 'inputs'; copied.mkdir()
            source = copied / 'case.scm'; source.write_text('old')
            with suite_workers(root, cache / 'runs/first', 1) as slots:
                slot = slots.get()
                work, _ = prepare_suite_worker(runtime, copied, slot)
                (work / 'stale.o1').write_text('old output')
                source.write_text('new')
                same, storage = prepare_suite_worker(runtime, copied, slot)
                self.assertEqual(work, same)
                self.assertFalse(storage['workspaceReused'])
                self.assertFalse((work / 'stale.o1').exists())
                self.assertEqual('new', (work / 'case.scm').read_text())
                self.assertEqual(b'compiled seed', seed.read_bytes())
                seed.write_bytes(b'new compiled seed')
                (work / 'stale.o1').write_text('old runtime output')
                _, storage = prepare_suite_worker(runtime, copied, slot)
                self.assertFalse(storage['workspaceReused'])
                self.assertFalse((work / 'stale.o1').exists())

    def test_suite_slot_keeps_verified_inputs_when_execution_context_changes(self):
        from gambit_smp.suite_primitives import suite_workers, prepare_suite_worker
        with task_fixture('suite-context') as (root, cache):
            runtime = root / 'runtime'
            for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
                (runtime / name).mkdir(parents=True)
            copied = root / 'inputs'
            (copied / 'nested').mkdir(parents=True)
            (copied / 'empty').mkdir()
            (copied / 'nested/case.scm').write_text('(exit 0)')
            with suite_workers(root, cache / 'runs/first', 1) as slots:
                slot = slots.get()
                work, _ = prepare_suite_worker(runtime, copied, slot, context={'run': 'first'})
                fixture = work / 'nested/case.scm'
                before = fixture.stat().st_ino
                (work / 'nested/stale.o1').write_text('compiled in a previous context')
                (work / 'generated').mkdir()
                (work / 'generated/stale.c').write_text('derived')
                same, storage = prepare_suite_worker(runtime, copied, slot, context={'run': 'second'})
                self.assertEqual(same, work)
                self.assertEqual(fixture.stat().st_ino, before)
                self.assertTrue((work / 'empty').is_dir())
                self.assertFalse((work / 'generated').exists())
                self.assertFalse((work / 'nested/stale.o1').exists())
                self.assertTrue(storage['workspaceReused'])
                self.assertEqual(storage['filesCopied'], 0)
                self.assertTrue(storage['runnerOutputsInvalidated'])
                self.assertFalse(storage['compiledResultReused'])

    def test_suite_campaign_shares_and_rechecks_the_donor_snapshot(self):
        from gambit_smp.suite_primitives import digest, suite_worker_inputs, suite_workers
        with task_fixture('suite-shared-inputs') as (root, cache):
            runtime = root / 'runtime'
            for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
                (runtime / name).mkdir(parents=True)
            executable = runtime / 'gsc/gsc'
            executable.write_bytes(b'compiled GSC')
            copied = root / 'inputs'
            copied.mkdir()
            source = copied / 'case.scm'
            source.write_text('(exit 0)')
            with suite_workers(root, cache / 'runs' / 'first', 2) as slots:
                workers = [slots.get(), slots.get()]
                with patch("gambit_smp.suite_primitives.digest", wraps=digest) as observed:
                    with suite_worker_inputs(runtime, copied, {}) as prepare:
                        for slot in workers:
                            work, _ = prepare(slot)
                            self.assertEqual(source.read_bytes(), (work / 'case.scm').read_bytes())
                self.assertEqual(observed.call_args_list.count(call(source)), 2)
                self.assertEqual(observed.call_args_list.count(call(executable)), 2)
                with self.assertRaisesRegex(ValueError, 'inputs changed during the campaign'):
                    with suite_worker_inputs(runtime, copied, {}) as prepare:
                        work, _ = prepare(workers[0])
                        source.write_text('(exit 1)')
                        self.assertEqual((work / 'case.scm').read_text(), '(exit 0)')

    def test_occupied_suite_pool_refuses_without_allocating_another_copy(self):
        from gambit_smp.suite_primitives import suite_workers
        with task_fixture('suite-lock') as (root, cache):
            with suite_workers(root, cache / 'runs/first', 1):
                with self.assertRaisesRegex(ValueError, 'already leased'):
                    with suite_workers(root, cache / 'runs/second', 1):
                        self.fail('a competing run acquired the same workspace')
            self.assertEqual(['suite-tests'], [p.name for p in (cache / 'build').iterdir()])

    def test_suite_slot_rejects_aliases_and_unknown_content(self):
        from gambit_smp.suite_primitives import suite_workers, prepare_suite_worker
        with task_fixture('suite-alias') as (root, cache):
            runtime = root / 'runtime'; runtime.mkdir()
            copied = root / 'inputs'; copied.mkdir()
            outside = root / 'outside'; outside.write_text('retain')
            (copied / 'escape').symlink_to(outside)
            with suite_workers(root, cache / 'runs/first', 1) as slots:
                slot = slots.get()
                with self.assertRaisesRegex(ValueError, 'aliases'):
                    prepare_suite_worker(runtime, copied, slot)
                (copied / 'escape').unlink()
                slot.mkdir()
                (slot / 'foreign').write_text('retain')
                with self.assertRaisesRegex(ValueError, 'unowned'):
                    prepare_suite_worker(runtime, copied, slot)
                self.assertEqual('retain', (slot / 'foreign').read_text())

    def test_unknown_child_retains_slot_instead_of_forking_or_resetting(self):
        from gambit_smp.suite_primitives import (suite_workers, prepare_suite_worker,
                                                retain_unquiesced_suite_worker)
        with task_fixture('suite-unknown') as (root, cache):
            runtime = root / 'runtime'
            for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
                (runtime / name).mkdir(parents=True)
            copied = root / 'inputs'; copied.mkdir()
            (copied / 'case.scm').write_text('input')
            with suite_workers(root, cache / 'runs/first', 1) as slots:
                slot = slots.get()
                work, _ = prepare_suite_worker(runtime, copied, slot)
                (work / 'retained.o1').write_text('possibly in flight')
                with self.assertRaisesRegex(ValueError, 'quiescence unresolved'):
                    retain_unquiesced_suite_worker(slot, [{'processGroupQuiescent': None,
                                                            'parentReaped': True}])
                with self.assertRaisesRegex(ValueError, 'unresolved child'):
                    prepare_suite_worker(runtime, copied, slot)
                self.assertEqual('possibly in flight', (work / 'retained.o1').read_text())

    def test_expired_compiled_group_is_unstarted_not_a_forged_child_timeout(self):
        import time
        from gambit_smp.native_capabilities import run_suite_groups
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            copied = root / 'fixtures'
            (copied / 'unit-tests').mkdir(parents=True)
            (copied / 'unit-tests/case.scm').write_text('(exit 0)\n')
            class Context:
                directory = root / 'observations'
                deadline = time.monotonic() - 1
                progress_mode = False
                def run(self, *args, **kwargs):
                    raise AssertionError('an expired group must not launch a process')
            Context.directory.mkdir()
            rows = run_suite_groups(Context(), root / 'runtime', copied,
                                    dict(mode='gsc', regime='whole-parallel'),
                                    [Path('case.scm')], 1, 'p1')
            self.assertEqual(1, len(rows))
            self.assertFalse(rows[0]['started'])
            self.assertFalse(rows[0]['accepted'])
            self.assertFalse(rows[0]['timeout'])
            self.assertIsNone(rows[0]['exit'])
            self.assertTrue(rows[0]['deadlineExhausted'])
            self.assertEqual(['case.scm'], rows[0]['files'])
            self.assertIsNone(rows[0]['storageTransfer'])
            self.assertFalse((Context.directory / 'shards').exists())

    def test_retry_preflight_denies_before_any_runtime_probe_or_suite_launch(self):
        with task_fixture('suite-preflight') as (root, cache):
            runtime = root / "source"
            unit = runtime / "tests/unit-tests"
            unit.mkdir(parents=True)
            (unit / "case.scm").write_text("original test")
            (runtime / "tests/run-unit-tests.scm").write_text("original runner")
            candidate = root / "candidate.json"
            candidate.write_text("{}")
            out = cache / "attempt"
            argv = ["gambit_smp.native_suite.py", "--runtime", str(runtime),
                    "--toolchain-receipt", str(candidate), "--gcc", "/selected/gcc",
                    "--out", str(out), "--timeout", "30", "--mode", "gsc", "case.scm"]
            with patch("sys.argv", argv), patch("gambit_smp.native_suite.check"), \
                    patch("gambit_smp.native_suite.gnu_compiler", return_value=(Path("/selected/gcc"), {}, "gcc")), \
                    patch("gambit_smp.native_suite.gnu_build_driver", return_value={}), \
                    patch("gambit_smp.retry_gate.preflight", return_value={"decision": "DENY"}), \
                    patch("gambit_smp.native_suite.execute") as execute, \
                    patch("gambit_smp.native_suite.parallel_suite") as suite:
                self.assertEqual(2, native_suite.main())
            execute.assert_not_called()
            suite.assert_not_called()
            receipt = json.loads((out / "receipt.json").read_text())
            self.assertFalse(receipt["runtimeExecuted"])
            self.assertEqual("DENY", receipt["status"])
            self.assertFalse((out / "processor-probe.log").exists())

    def test_atomic_coverage_never_admits_whole_mode_timing(self):
        self.assertEqual("COVERAGE-PASS", campaign_status([{"accepted": True}], ["gsc"], True))
        self.assertEqual("DENY", campaign_status([{"accepted": False}], ["gsc"], True))
        self.assertEqual("RUNNING", campaign_status([], ["gsc"], True))

    def test_atomic_batches_cover_files_once_with_unchanged_batch_budget(self):
        files = [Path(f"test-{index}.scm") for index in range(9)]
        checkpoints = []
        def run(*args):
            self.assertEqual(10, args[6])
            return 0, "original marker\n", False, 0.1, [{"accepted": True}]
        with patch("gambit_smp.native_suite.parallel_suite", side_effect=run) as mocked:
            code, _, timeout, _, rows = atomic_suite(
                Path("runtime"), Path("copied"), Path("out"), "gsc", files,
                2, 10, {}, "p3", {}, {}, {}, lambda: True,
                lambda rows: checkpoints.append(len(rows)))
        self.assertEqual(0, code)
        self.assertFalse(timeout)
        self.assertEqual(5, mocked.call_count)
        self.assertEqual([1, 2, 3, 4, 5], checkpoints)
        self.assertTrue(all(len(row["files"]) <= 2 for row in rows))
        self.assertEqual(sorted(str(p) for p in files), sorted(p for row in rows for p in row["files"]))

    def test_atomic_failure_stops_remaining_batches_and_retains_failure(self):
        files = [Path(f"test-{index}.scm") for index in range(9)]
        with patch("gambit_smp.native_suite.parallel_suite", return_value=(-9, "deadline\n", True, 10.01, [{"accepted": False}])) as run:
            code, output, timeout, _, rows = atomic_suite(
                Path("runtime"), Path("copied"), Path("out"), "gsc", files,
                2, 10, {}, "p3", {}, {}, {}, lambda: True, lambda rows: None)
        self.assertEqual(1, run.call_count)
        self.assertEqual(-9, code)
        self.assertTrue(timeout)
        self.assertEqual("deadline\n", output)
        self.assertFalse(rows[0]["accepted"])

    def test_atomic_input_drift_prevents_launch(self):
        with patch("gambit_smp.native_suite.parallel_suite") as run:
            code, _, _, _, rows = atomic_suite(
                Path("runtime"), Path("copied"), Path("out"), "gsc", [Path("test.scm")],
                2, 10, {}, "p3", {}, {}, {}, lambda: False, lambda rows: None)
        run.assert_not_called()
        self.assertEqual(-1, code)
        self.assertFalse(rows[0]["accepted"])

    def test_model_bound_extra_fixture_patch_preserves_original_and_all_work(self):
        root = Path(__file__).resolve().parents[1]
        source = root / "models/gambit/native/pr1037/pipe_concurrent.scm"
        content = source.read_bytes()
        patch = root / "patches/candidates/test-pipe-read-deadline.patch"
        relative = "09-io/pipe_concurrent.scm"
        with tempfile.TemporaryDirectory() as temporary:
            mirror = Path(temporary)
            unit = mirror / "tests/unit-tests"
            unit.mkdir(parents=True)
            original_sha = extra_fixture(source, relative, unit)
            changed = fixture_patch(patch.read_bytes(), mirror,
                {"unit-tests/" + relative: original_sha}, {"tests/unit-tests/" + relative})
            derived = (unit / relative).read_text()
            self.assertEqual(content, source.read_bytes())
            self.assertNotEqual(original_sha, changed["unit-tests/" + relative])
            self.assertEqual(content.decode().count("10000"), derived.count("10000"))
            for line in content.decode().splitlines():
                if "test-equal" in line or "thread-join!" in line or "##thread-pin!" in line:
                    self.assertIn(line, derived.splitlines())
            self.assertEqual(1, derived.count("(input-port-timeout-set! port 10)"))
            self.assertIn("(value (read-with-timeout server))", derived)
            self.assertIn("(value (read-with-timeout client))", derived)

    def test_pipe_fixture_is_exact_pr1037_blob_without_weakened_timeouts(self):
        root = Path(__file__).resolve().parents[1]
        snapshot = json.loads((root / "evidence/upstream/smp-20261010/pr-1037-snapshot.json").read_text())
        row = next(row for row in snapshot["files"] if row["file"].endswith("pipe_concurrent.scm"))
        content = (root / "models/gambit/native/pr1037/pipe_concurrent.scm").read_bytes()
        self.assertEqual(row["blobSha"], hashlib.sha1(b"blob " + str(len(content)).encode() + b"\0" + content).hexdigest())
    def test_thread_start_join_patch_retains_original_assertions_and_work(self):
        root = Path(__file__).resolve().parents[1]
        lines = (root / "patches/candidates/test-thread-start-join.patch").read_text().splitlines()
        self.assertEqual(["+(thread-join! t2)"], [line for line in lines if line.startswith("+") and not line.startswith("+++")])
        self.assertEqual([], [line for line in lines if line.startswith("-") and not line.startswith("---")])
    def test_ended_interrupt_fixture_is_exact_pr1047_blob(self):
        root = Path(__file__).resolve().parents[1]
        snapshot = json.loads((root / "evidence/upstream/smp-20261010/pr-1047-snapshot.json").read_text())
        row = next(row for row in snapshot["files"] if row["file"].endswith("thread_interrupt_ended.scm"))
        content = (root / "models/gambit/native/pr1047/thread_interrupt_ended.scm").read_bytes()
        self.assertEqual(row["blobSha"], hashlib.sha1(b"blob " + str(len(content)).encode() + b"\0" + content).hexdigest())
    def test_parallel_capacity_shares_host_budget_without_fixed_population(self):
        for cpu in (1, 2, 4, 10, 12, 64):
            processors, jobs = capacity(cpu, 375, True)
            self.assertLessEqual((processors + 1) * jobs, max(2, cpu))
            self.assertGreater(processors, 0)
        self.assertEqual((3, 3), capacity(12, 375, True))
        self.assertEqual((11, 1), capacity(12, 375, True, processors=11))
        self.assertEqual((1, 6), capacity(12, 375, True, jobs=6))
        self.assertEqual((11, 1), capacity(12, 375, False))
        for cpu in (1, 2, 4, 10, 12, 64):
            processors, jobs = capacity(cpu, 375, False)
            self.assertEqual(1, jobs)
            self.assertLessEqual(processors + 1, max(2, cpu))
        with self.assertRaises(ValueError):
            capacity(12, 375, False, processors=12)
        with self.assertRaises(ValueError):
            capacity(12, 375, True, processors=12, jobs=12)
        with self.assertRaises(ValueError):
            capacity(12, 375, True, processors=12)
    def test_driver_population_does_not_change_child_environment_options(self):
        option = "m123,p7,~~lib=/selected/lib,~~bin=/selected/bin"
        self.assertEqual("m123,p1,~~lib=/selected/lib,~~bin=/selected/bin", runner_option(option))
        self.assertIn("p7", option)
    def test_each_runtime_view_preserves_upstream_relative_binary_layout(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            runtime = root / "source"
            for name in ("gsi", "gsc", "lib", "include", "bin"):
                (runtime / name).mkdir(parents=True)
            (runtime / "gsc/gsc").write_text("selected compiler")
            tests = runtime_view(runtime, root / "shards" / "0")
            self.assertEqual((runtime / "gsc/gsc").resolve(), (tests / "../gsc/gsc").resolve())
            self.assertEqual("selected compiler", (tests / "../gsc/gsc").read_text())
    def test_shards_cover_each_file_once_without_empty_workers(self):
        files = [Path(str(index) + ".scm") for index in range(7)]
        for jobs in (1, 3, 12):
            groups = partitions(files, jobs)
            self.assertTrue(all(groups))
            self.assertEqual(sorted(files), sorted(path for group in groups for path in group))
        for files, jobs in ((files, 0), ([files[0], files[0]], 2)):
            with self.assertRaises(ValueError):
                partitions(files, jobs)
    def test_completion_patch_is_exact_tested_fixture_and_original_source(self):
        root = Path(__file__).resolve().parents[1]
        relative = Path("tests/unit-tests/06-thread/thread_interrupt.scm")
        receipt = json.loads((root / "evidence/model-results/native-thread-completion-019.json").read_text())
        fixture = root / "models/gambit/native/pr988/thread_interrupt_completion.scm"
        patch = root / "patches/candidates/test-thread-interrupt-completion.patch"
        self.assertEqual(receipt["extraFixtures"]["diagnostic/thread_interrupt_completion.scm"]["sha256"],
                         hashlib.sha256(fixture.read_bytes()).hexdigest())
        with tempfile.TemporaryDirectory() as temporary:
            parent = Path(temporary)
            subprocess.run(["git", "init", "--quiet", str(parent)], check=True, capture_output=True)
            directory = parent / ".data" / "isolated"
            directory.mkdir(parents=True)
            target = directory / relative
            target.parent.mkdir(parents=True)
            target.write_bytes(fixture.read_bytes())
            subprocess.run(["git", "--git-dir=/dev/null", "apply", "--reverse", str(patch)], cwd=directory,
                           check=True, capture_output=True)
            self.assertEqual(receipt["sourceFiles"]["unit-tests/06-thread/thread_interrupt.scm"],
                             hashlib.sha256(target.read_bytes()).hexdigest())
            hashes = fixture_patch(patch.read_bytes(), directory, receipt["sourceFiles"], {relative.as_posix()})
            self.assertEqual({"unit-tests/06-thread/thread_interrupt.scm": hashlib.sha256(fixture.read_bytes()).hexdigest()}, hashes)
            self.assertEqual(fixture.read_bytes(), target.read_bytes())

    def test_fixture_patch_rejects_unbound_paths_and_empty_patch(self):
        root = Path(__file__).resolve().parents[1]
        patch = (root / "patches/candidates/test-thread-interrupt-completion.patch").read_bytes()
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            with self.assertRaises(ValueError):
                fixture_patch(patch, directory, {}, set())
            with self.assertRaises(ValueError):
                fixture_patch(b"", directory, {}, set())

    def test_serialization_fixture_is_exact_reported_pr1038_git_blob(self):
        root = Path(__file__).resolve().parents[1]
        snapshot = json.loads((root / "evidence/upstream/smp-20261010/pr-1038-snapshot.json").read_text())
        row = next(row for row in snapshot["files"] if row["file"] == "tests/unit-tests/10-tables/serialization.scm")
        content = (root / "models/gambit/native/pr1038/serialization.scm").read_bytes()
        git_blob = b"blob " + str(len(content)).encode() + b"\0" + content
        self.assertEqual(row["blobSha"], hashlib.sha1(git_blob).hexdigest())

    def test_environment_probe_requires_actual_requested_vm_population(self):
        self.assertTrue(admitted_processors(0, "PROCESSORS:7\n", False, 7))
        self.assertFalse(admitted_processors(0, "PROCESSORS:1\n", False, 7))
        self.assertFalse(admitted_processors(1, "PROCESSORS:7\n", False, 7))
        self.assertFalse(admitted_processors(0, "PROCESSORS:7\n", True, 7))

    def test_extra_fixture_cannot_replace_source_or_escape_snapshot(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "extra.scm"
            source.touch()
            unit = root / "unit"
            unit.mkdir()
            extra_fixture(source, "tables/new.scm", unit)
            for destination in ("tables/new.scm", "../escape.scm", str(root / "absolute.scm")):
                with self.assertRaises(ValueError):
                    extra_fixture(source, destination, unit)

    def test_partial_mode_success_never_admits_whole_campaign(self):
        modes = ("gsi", "gsc")
        self.assertEqual("RUNNING", campaign_status([], modes))
        self.assertEqual("RUNNING", campaign_status([{"accepted": True}], modes))
        self.assertEqual("DENY", campaign_status([{"accepted": False}], modes))
        self.assertEqual("PASS", campaign_status([{"accepted": True}] * 2, modes))

    def test_admission_requires_exit_count_and_no_failures(self):
        self.assertTrue(admitted_suite(0, "PASSED ALL 9 UNIT TESTS\n", False, 9))
        for code, output, timeout in ((1, "PASSED ALL 9 UNIT TESTS", False),
                (0, "PASSED ALL 8 UNIT TESTS", False), (0, "PASSED ALL 9 UNIT TESTS", True),
                (0, "*** FAILED x\nPASSED ALL 9 UNIT TESTS", False)):
            self.assertFalse(admitted_suite(code, output, timeout, 9))

    def test_selection_rejects_escape_and_excludes_helpers_and_stress(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ("#.scm", "a.scm", "b_stress.scm"):
                (root / name).touch()
            self.assertEqual([Path("a.scm")], selected_files(root, [".", "a.scm"]))
            for selection in ("..", "missing.scm", str(root)):
                with self.assertRaises(ValueError):
                    selected_files(root, [selection])


class CompletedUnitCounterTests(unittest.TestCase):
    def test_started_filename_is_not_a_completed_test(self):
        from gambit_smp.suite_primitives import completed_unit_cases
        out = "[ 0| 0] 0% .... 0s a.scm\n[ 1| 0] 50% .... 1s b.scm\n"
        self.assertEqual(completed_unit_cases(['a.scm', 'b.scm'], out),
                         [dict(file='a.scm', status='PASS'), dict(file='b.scm', status='UNRESOLVED')])

    def test_failed_counter_and_final_completion_preserve_outcomes(self):
        from gambit_smp.suite_primitives import completed_unit_cases
        out = "[ 0| 0] 0% .... 0s a.scm\n[ 0| 1] 50% .... 1s b.scm\n[ 1| 1] 100% .... 2s\n"
        self.assertEqual([r['status'] for r in completed_unit_cases(['a.scm', 'b.scm'], out)], ['FAIL', 'PASS'])

    def test_gaps_reset_wrong_order_and_duplicate_inventory_fail_closed(self):
        from gambit_smp.suite_primitives import completed_unit_cases
        for out in ['[ 1| 0] 50% .... 1s b.scm\n',
                    '[ 0| 0] 0% .... 0s b.scm\n',
                    '[ 0| 0] 0% .... 0s a.scm\n[ 2| 0] 100% .... 1s\n']:
            with self.subTest(out=out), self.assertRaises(ValueError):
                completed_unit_cases(['a.scm', 'b.scm'], out)
        with self.assertRaises(ValueError):
            completed_unit_cases(['a.scm', 'a.scm'], '')

    def test_exit_text_without_counters_grants_no_coverage(self):
        from gambit_smp.suite_primitives import completed_unit_cases
        self.assertEqual(completed_unit_cases(['a.scm'], 'PASSED ALL 1 UNIT TESTS'),
                         [dict(file='a.scm', status='UNRESOLVED')])

    def test_timeout_stdout_is_not_silently_replaced_by_joined_stderr(self):
        from gambit_smp.suite_primitives import completed_unit_cases
        stdout = "[ 0| 0] 0% .... 0s a.scm"
        self.assertEqual(completed_unit_cases(['a.scm'], stdout)[0]['status'], 'UNRESOLVED')
        with self.assertRaises(ValueError):
            completed_unit_cases(['a.scm'], stdout + 'In file included from other.c:1:')
