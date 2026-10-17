"""CI framework wiring and process controls, never native acceptance."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

from gambit_smp import native_capabilities, recipes
from gambit_smp.framework import ROOT, digest, apply_untracked_patch, available_processors
from gambit_smp.process_observation import capture
from gambit_smp.source_capabilities import validate_source_lock
from gambit_smp.suite_primitives import capacity, selected_files

DIRECTORY = ROOT / "evidence/research/ci"


class GambitCIContracts(unittest.TestCase):
    def recipe(self, name):
        return recipes.load(ROOT, DIRECTORY / (name + ".recipe.json"))

    def test_three_flags_together(self):
        with tempfile.TemporaryDirectory() as name:
            source = Path(name)
            (source / "include").mkdir()
            (source / "include/gambit.h").write_text("generated header control")
            (source / "lib").mkdir()
            (source / "lib/makefile").write_text("define-cond-expand-feature|enable-smp|")
            ctx = Mock(directory=source, tools={"aclocal": "aclocal", "autoconf": "autoconf", "sh": "sh"})
            ctx.progress_mode = False
            ctx.remaining.return_value = 10
            ctx.require.side_effect = lambda name, *args: "#define ___MULTIPLE_VMS\n#define ___MULTIPLE_THREADED_VMS\n" if name == "configuration-macros" else ""
            with patch.object(native_capabilities, "clone", return_value=source), \
                 patch.object(native_capabilities, "compiler", return_value=Path("gcc")), \
                 patch("gambit_smp.completed_producer.prevent_duplicate_configuration"):
                native_capabilities.configure({"source": {"step": "source", "output": "source"},
                    "cOptimization": 3, "rtsOptimization": 3}, ctx)
            calls = {call.args[0]: call for call in ctx.require.call_args_list}
            self.assertIn("aclocal", calls)
            flags = set(calls["configure"].args[1])
            self.assertTrue({"--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"} <= flags)

    def test_requested_flags_without_effective_macros_do_not_publish_configuration(self):
        with tempfile.TemporaryDirectory() as name:
            source = Path(name)
            (source / "include").mkdir()
            (source / "include/gambit.h").write_text("missing effective macro")
            (source / "lib").mkdir()
            (source / "lib/makefile").write_text("define-cond-expand-feature|enable-smp|")
            ctx = Mock(tools={"aclocal": "aclocal", "autoconf": "autoconf", "sh": "sh"})
            ctx.progress_mode = False
            ctx.remaining.return_value = 10
            ctx.require.return_value = "#define ___MULTIPLE_VMS\n"
            with patch.object(native_capabilities, "clone", return_value=source), \
                 patch.object(native_capabilities, "compiler", return_value=Path("gcc")), \
                 patch("gambit_smp.completed_producer.prevent_duplicate_configuration"):
                with self.assertRaisesRegex(ValueError, "effective configuration"):
                    native_capabilities.configure({"source": {"step": "source", "output": "source"},
                        "cOptimization": 3, "rtsOptimization": 3}, ctx)
            ctx.publish.assert_not_called()

    def test_complete_candidate_change_is_source_bound_not_just_unblocked(self):
        candidate = recipes.read_json(DIRECTORY / "candidate.json")
        source = recipes.read_json(ROOT / candidate["sourceLock"])
        validate_source_lock(source)
        self.assertGreater(len(source["files"]), 1)
        self.assertFalse(candidate["runtimeAdmitted"])
        self.assertEqual(38897367565, candidate["baselineFailureRun"])
        for assessment in candidate["sourceAssessment"]:
            for name in assessment["changedInputs"]:
                row = source["files"][name]
                self.assertNotEqual(row["baseSha256"], row["candidateSha256"])
            for name in assessment["premises"]:
                self.assertTrue(recipes.source_path(ROOT, name).is_file())

    def test_checked_patch_reproduces_exact_context_fix_without_vendor_mutation(self):
        lock = recipes.read_json(ROOT / ".github/gambit/source.lock.json")
        validate_source_lock(lock)
        self.assertEqual({"lib/setup.c"}, set(lock["files"]))
        source = ROOT / "vendor/gambit/lib/setup.c"
        before = digest(source)
        self.assertEqual(before, lock["files"]["lib/setup.c"]["baseSha256"])
        overlay = ROOT / lock["patch"]
        self.assertEqual(digest(overlay), lock["patchSha256"])
        with tempfile.TemporaryDirectory() as name:
            copied = Path(name)
            (copied / "lib").mkdir()
            shutil.copy2(source, copied / "lib/setup.c")
            apply_untracked_patch(copied, overlay.read_bytes(), {"lib/setup.c"})
            self.assertEqual(lock["files"]["lib/setup.c"]["candidateSha256"], digest(copied / "lib/setup.c"))
            self.assertIn("make_global (___MAKE_GLOBAL_PSV", (copied / "lib/setup.c").read_text())
        self.assertEqual(before, digest(source))

    def test_complete_stress_inventory_has_independent_jobs(self):
        upstream = sorted(path.relative_to(ROOT / "vendor/gambit/tests/unit-tests").as_posix()
                          for path in (ROOT / "vendor/gambit/tests/unit-tests").rglob("*_stress.scm"))
        declared = []
        for path in DIRECTORY.glob("*-stress.recipe.json"):
            _, steps = recipes.load(ROOT, path)
            modes = [step for step in steps if step["capability"] == "gambit.suite"]
            self.assertEqual(["gsi", "gsc"], [step["arguments"]["mode"] for step in modes])
            self.assertEqual(modes[0]["arguments"]["expectedFiles"], modes[1]["arguments"]["expectedFiles"])
            declared.extend(modes[0]["arguments"]["expectedFiles"])
        self.assertEqual(upstream, sorted(declared))

    def test_identity_rejects_revision_missing_extra_and_changed_paths(self):
        # The production archive transport owns these checks; no CI-local verifier.
        from tests.test_runtime_artifact import fixture, pack
        from gambit_smp.runtime_artifact import unpack
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            runtime, value = fixture(root)
            (runtime / "program").write_text("drift")
            pack(root / "drift.tar", runtime, value)
            with self.assertRaises(ValueError):
                unpack(root / "drift.tar", root / "out")

    def test_process_failure_and_timeout_retain_original_observations(self):
        for code, seconds, expected in (("raise SystemExit(7)", 3, False),
                                        ("import time; time.sleep(3)", 0.1, True)):
            result = capture([sys.executable, "-c", code], ROOT, seconds, dict(os.environ))
            self.assertEqual(expected, result.timeout)
            self.assertEqual(-9 if expected else 7, result.exit)
            self.assertTrue(result.group_quiescent)

    def test_runtime_options_reach_actual_child_and_receipt(self):
        result = capture([sys.executable, "-c", "import os; print(os.environ['GAMBOPT'])"],
                         ROOT, 3, dict(os.environ, GAMBOPT="p2"))
        self.assertEqual("p2\n", result.stdout)
        self.assertEqual(0, result.exit)

    def test_modes_use_existing_suite_executor_and_independent_original_deadlines(self):
        recipe, steps = self.recipe("threads")
        modes = [step for step in steps if step["capability"] == "gambit.suite"]
        self.assertEqual({"mode": "per-stage", "overheadSeconds": 30}, recipe["timeoutPolicy"])
        self.assertEqual(sum(step["budgetSeconds"] for step in steps) + 30, recipe["budgetSeconds"])
        self.assertEqual([300, 300], [step["budgetSeconds"] for step in modes])
        self.assertEqual(["gsi", "gsc"], [step["arguments"]["mode"] for step in modes])
        for step in modes:
            self.assertIs(recipes.CAPABILITIES[step["capability"]].executor, native_capabilities.suite)
            args = step["arguments"]
            self.assertNotIn("processors", args)
            self.assertNotIn("jobs", args)
            self.assertEqual({"step": "candidate", "output": "source"}, args["expectedSource"])
            selected = selected_files(ROOT / "vendor/gambit/tests/unit-tests", args["selection"])
            self.assertIn("06-thread/thread_start.scm", map(str, selected))
            self.assertGreater(len(selected), 25)
            population, jobs = capacity(available_processors(), len(selected), True)
            self.assertLessEqual(jobs * (population + 1), max(2, available_processors()))

    def test_suite_inventory_must_bind_the_runtime_source(self):
        _, steps = self.recipe("threads")
        by_id = {step["id"]: step for step in steps}
        suite = by_id["gsi"]
        review = by_id["review-gsi"]
        native_capabilities.graph(suite, by_id, recipes.CAPABILITIES)
        native_capabilities.graph(review, by_id, recipes.CAPABILITIES)
        forged = {**suite, "arguments": {**suite["arguments"],
                  "expectedSource": {"step": "other", "output": "source"}}}
        with self.assertRaisesRegex(ValueError, "runtime's exact materialized candidate"):
            native_capabilities.graph(forged, by_id, recipes.CAPABILITIES)
        detached = {**review, "dependsOn": ["runtime", "environment-probe"]}
        with self.assertRaisesRegex(ValueError, "source-bound inventory producer"):
            native_capabilities.graph(detached, by_id, recipes.CAPABILITIES)

    def test_full_suite_review_declares_every_overlapping_historical_route(self):
        from gambit_smp.native_review import failure_modes, selected_scope

        _, steps = self.recipe("threads")
        by_id = {step["id"]: step for step in steps}
        failures = recipes.read_json(ROOT / "evidence/native-failures.json")["failures"]
        for mode in ("gsi", "gsc"):
            args = by_id[mode]["arguments"]
            ctx = Mock()
            ctx.artifact.return_value = ROOT / "vendor/gambit"
            files = [Path(name) for name in native_capabilities.expected_suite_inventory(args, ctx)]
            self.assertEqual(len(selected_files(ROOT / "vendor/gambit/tests/unit-tests", ["."])) + 5,
                             len(files))
            selected = {str(path) for path in files}
            overlapping = set()
            for failure in failures:
                if not selected_scope(failure["file"], selected, files):
                    continue
                modes = failure_modes(recipes.read_json(ROOT / failure["receipt"]))
                if not modes or mode in modes:
                    overlapping.add(failure["id"])
            review = by_id["review-" + mode]["arguments"]
            self.assertEqual(overlapping, set(review["failureIds"]))
            intent = recipes.read_json(ROOT / review["intent"])
            self.assertLessEqual(overlapping, {row["id"] for row in intent["failures"]})

    def test_every_module_is_required_and_uses_one_artifact(self):
        workflow = (ROOT / ".github/workflows/gambit.yml").read_text()
        self.assertIn("fail-fast: false", workflow)
        self.assertNotIn("continue-on-error", workflow)
        self.assertIn('test "$PATCHES" = success', workflow)
        self.assertIn('test "$MODULES" = success', workflow)
        self.assertEqual(2, workflow.count("gambit-runtime-${{ github.run_id }}-${{ github.run_attempt }}"))
        self.assertEqual(2, workflow.count("gambit-engine-${{ github.run_id }}-${{ github.run_attempt }}"))
        self.assertIn("--portable-seal", workflow)
        self.assertFalse((ROOT / ".github/gambit/runner.py").exists())
        self.assertNotIn(".github/gambit/runner.py", workflow)
        self.assertIn("research --export-runtime", workflow)
        self.assertIn("research --run", workflow)
        modules = re.search(r"module: \[(.*)\]", workflow).group(1).split(", ")
        for name in modules:
            self.recipe(name)

    def test_official_targets_are_not_replaced_with_local_fixture(self):
        for name, targets in (("upstream-check", ["check"]), ("gc-ffi", ["test7", "test8", "test9"]),
                              ("compile-execute", ["test5", "test6"])):
            _, steps = self.recipe(name)
            step = next(step for step in steps if step["capability"] == "gambit.upstream-tests")
            self.assertEqual(targets, step["arguments"]["targets"])
            if name == "upstream-check":
                fixtures = step["arguments"]["additionalFixtures"]
                self.assertEqual({"12-os/process_spawn.scm"}, set(fixtures))
                fixture = fixtures["12-os/process_spawn.scm"]
                self.assertEqual(digest(ROOT / fixture["source"]), fixture["sha256"])
                selected = selected_files(ROOT / "vendor/gambit/tests/unit-tests", ["."])
                self.assertNotIn(Path("12-os/process_spawn.scm"), selected)
            self.assertEqual("evidence/native-failures.json", step["arguments"]["failures"])

    def test_policy_and_dependency_changes_trigger_native_workflow(self):
        workflow = (ROOT / ".github/workflows/gambit.yml").read_text()
        filters = re.findall(r"paths: \[(.*?)\]", workflow)
        self.assertEqual(2, len(filters))
        for paths in filters:
            for path in ("evidence/dsl/**", "evidence/native-failures.json",
                         "evidence/fixtures/**/source.lock.json", "pyproject.toml", "uv.lock"):
                self.assertIn("'" + path + "'", paths)

    def test_known_failure_observations_are_committed_with_complete_archives(self):
        from gambit_smp.native_archive import validate

        failures = json.loads((ROOT / "evidence/native-failures.json").read_text())
        observations = {row["observation"] for row in failures["failures"] if "observation" in row}
        for name in observations:
            with self.subTest(observation=name):
                observed = json.loads((ROOT / name).read_text())
                archive = observed["archive"]["path"]
                self.assertEqual(observed["archive"]["sha256"], digest(ROOT / archive))
                inputs = validate(ROOT, archive)
                for path in (name, *inputs):
                    tracked = subprocess.run(["git", "ls-files", "--error-unmatch", "--", path],
                                             cwd=ROOT, capture_output=True)
                    self.assertEqual(0, tracked.returncode, "historical evidence must be committed: " + path)

    def test_tfib_stress_uses_inactivity_watchdog_not_whole_wall_budget(self):
        raw = json.loads((DIRECTORY / "tfib-stress.recipe.json").read_text())
        self.assertNotIn("budgetSeconds", raw)
        self.assertEqual("progress", raw["timeoutPolicy"]["mode"])
        caps = {step["id"]: step["budgetSeconds"] for step in raw["steps"]}
        self.assertEqual(1800, caps["gsi"])
        self.assertEqual(1800, caps["gsc"])


if __name__ == "__main__":
    unittest.main()
