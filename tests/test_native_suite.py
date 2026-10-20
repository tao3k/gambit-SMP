from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import unittest
from gambit_smp import native_suite
from unittest.mock import patch
from tests.support import task_fixture

from gambit_smp.native_suite import admitted_suite, selected_files, campaign_status, extra_fixture, admitted_processors, fixture_patch, partitions, runtime_view, capacity, runner_option, atomic_suite


class NativeSuiteTests(unittest.TestCase):
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
