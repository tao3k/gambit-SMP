import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import native_capabilities as native, recipes


class NativeRecipeTests(unittest.TestCase):
    def test_typed_macros_reach_both_dependency_and_compilation_commands(self):
        self.recipe["steps"][0]["arguments"]["defines"] = ["TEST_BRANCH", "TEST_COUNT=3"]
        self.save()
        result = self.run_recipe("macros")
        self.assertEqual("PASS", result["outcome"])
        builds = [argv for argv, _ in self.calls if "-M" in argv or "-MD" in argv]
        self.assertEqual(2, len(builds))
        self.assertTrue(all("-DTEST_BRANCH" in argv and "-DTEST_COUNT=3" in argv for argv in builds))

    def test_expected_failure_is_explicit_and_preserves_real_nonzero_exit(self):
        case = self.recipe["steps"][1]["arguments"]["cases"][0]
        case.update(expectedExit=1, negativeControl=True, stdout="EXPECTED-FAILURE\n")
        self.save()
        def negative(argv, cwd, timeout, **kwargs):
            if len(argv) == 1 and str(argv[0]).endswith("program"):
                return 1, "EXPECTED-FAILURE\n", False, 0.01
            return self.execute(argv, cwd, timeout, **kwargs)
        result = self.run_recipe("negative", execute=negative)
        self.assertEqual("PASS", result["outcome"])
        row = result["steps"][1]
        self.assertEqual(["zero"], row["expectedFailureControls"])
        self.assertEqual(1, row["commands"][0]["exit"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual("DENY", self.run_recipe("wrong-exit")["outcome"])

    def test_macro_flags_and_implicit_or_signal_failures_are_rejected(self):
        original = copy.deepcopy(self.recipe)
        for defines in (["-include/private/input"], ["TEST=abc"], [{}]):
            self.recipe = copy.deepcopy(original)
            self.recipe["steps"][0]["arguments"]["defines"] = defines
            self.save()
            with self.assertRaisesRegex(ValueError, "defines"):
                recipes.load(self.root, self.path)
        for expected, negative in ((1, False), (-11, True), (127, True), (0, True)):
            self.recipe = copy.deepcopy(original)
            self.recipe["steps"][1]["arguments"]["cases"][0].update(
                expectedExit=expected, negativeControl=negative)
            self.save()
            with self.assertRaisesRegex(ValueError, "negative control"):
                recipes.load(self.root, self.path)

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "evidence").mkdir()
        (self.root / "source.c").write_text("int main(void) { return 0; }\n")
        self.path = self.root / "evidence/native.recipe.json"
        self.recipe = {"schema": recipes.SCHEMA, "id": "native-control", "scope": "executor unit controls only",
                       "inputs": ["source.c"], "budgetSeconds": 30, "steps": [
            {"id": "build", "capability": "native.c-build", "dependsOn": [], "budgetSeconds": 10,
             "arguments": {"sources": ["source.c"], "headers": [], "standard": "c11", "optimization": 0,
                           "pthread": False, "target": "executable"}},
            {"id": "test", "capability": "native.test", "dependsOn": ["build"], "budgetSeconds": 10,
             "arguments": {"executable": {"step": "build", "output": "executable"},
                           "cases": [{"id": "zero", "integers": [], "stdout": ""}]}}]}
        self.save()
        self.gcc = self.root / "gcc"
        self.gcc.write_text("unit compiler")
        self.backend = self.root / "cc1"
        self.backend.write_text("unit backend")
        self.calls = []

    def save(self):
        self.path.write_text(json.dumps(self.recipe))

    def execute(self, argv, cwd, timeout, **kwargs):
        self.calls.append((argv, timeout))
        kwargs.get("metadata", {}).update(pid=123, startedAt="unit-start", endedAt="unit-end")
        if "--version" in argv:
            return 0, "gcc unit fixture", False, 0.01
        if "-print-prog-name=cc1" in argv:
            return 0, str(self.backend), False, 0.01
        if "-M" in argv or "-MD" in argv:
            Path(argv[argv.index("-MF") + 1]).write_text("program: " + str(Path(cwd) / "source.c") + "\n")
        if "-o" in argv:
            Path(argv[argv.index("-o") + 1]).write_text("unit compiled artifact")
        return 0, "", False, 0.01

    def run_recipe(self, name, execute=None, prior=None, allow=True):
        with patch.object(native, "host_tools", return_value=({"gcc": self.gcc}, {"PATH": "/unavailable"})), \
                patch.object(recipes, "execute", side_effect=execute or self.execute), \
                patch.object(recipes, "tool_files", side_effect=AssertionError("native must not load Quint")):
            return recipes.run(self.root, self.path, self.root / name, Path("no-quint"), Path("no-node"), prior,
                               gcc=self.gcc, allow_native=allow)

    def test_native_discovery_and_execution_need_no_quint_or_feature_registration(self):
        alternate = copy.deepcopy(self.recipe)
        alternate["id"] = "independent-native"
        (self.root / "evidence/second.recipe.json").write_text(json.dumps(alternate))
        self.assertEqual(2, len(recipes.discover(self.root)))
        result = self.run_recipe("run")
        self.assertEqual("PASS", result["outcome"])
        self.assertEqual(["zero"], result["steps"][1]["passedCases"])
        self.assertEqual("CURRENT", recipes.inspect_run(self.root / "run")["identityStatus"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(result["executionAuthorized"])
        self.assertTrue(all(row[1] <= 10 for row in self.calls))
        self.assertTrue(all("pid" in row for step in result["steps"] for row in step["commands"]))

    def test_host_authorization_is_required_before_native_processes(self):
        result = self.run_recipe("unauthorized", allow=False)
        self.assertEqual("DENY", result["outcome"])
        self.assertEqual([], self.calls)

    def test_bound_workspace_rejects_unused_source_and_external_header_before_build(self):
        import time
        copied = self.root / "workspace"
        copied.mkdir()
        copied = copied.resolve()
        source = copied / "source.c"
        source.write_text("int main(void) { return 0; }\n")
        (copied / "locked.inc").write_text("int locked = 1;\n")
        outside = self.root / "archived.h"
        outside.write_text("old producer output")
        originals = {name: recipes.digest(copied / name) for name in ("source.c", "locked.inc")}
        for label, external, message in (("unused", False, "required locked-source"),
                                         ("external", True, "external non-system")):
            directory = self.root / label
            directory.mkdir()
            context = recipes.ExecutionContext(self.root, self.root, directory, {}, time.monotonic() + 5,
                                                {}, {"engine": {}}, {})
            commands = []
            def dependencies(name, argv, cwd, timeout):
                commands.append(name)
                path = Path(argv[argv.index("-MF") + 1])
                path.write_text("program: " + str(source) + (" " + str(outside) if external else "") + "\n")
                return ""
            with patch.object(native, "compiler", return_value=self.gcc), \
                    patch.object(context, "require", side_effect=dependencies):
                with self.assertRaisesRegex(ValueError, message):
                    native.compile_workspace(self.recipe["steps"][0]["arguments"], context, copied,
                                             source, originals, required_origins=["locked.inc"])
            self.assertNotIn("c-build", commands)
            self.assertFalse((directory / "program").exists())

    def test_mistyped_missing_and_undeclared_artifact_edges_are_rejected(self):
        original = copy.deepcopy(self.recipe)
        for change in (lambda: self.recipe["steps"][1].update(dependsOn=[]),
                       lambda: self.recipe["steps"][1]["arguments"]["executable"].update(output="object"),
                       lambda: self.recipe["steps"][0]["arguments"].update(target="object"),
                       lambda: self.recipe["steps"][1]["arguments"]["executable"].update(step="missing")):
            self.recipe = copy.deepcopy(original)
            change()
            self.save()
            with self.assertRaises(ValueError):
                recipes.load(self.root, self.path)

    def test_raw_flags_scripts_and_untyped_case_operands_are_rejected(self):
        original = copy.deepcopy(self.recipe)
        for arguments in ({"flags": ["-include", "hidden.h"]}, {"optimization": True}, {"target": "shared-library"}):
            self.recipe = copy.deepcopy(original)
            self.recipe["steps"][0]["arguments"].update(arguments)
            self.save()
            with self.assertRaises(ValueError):
                recipes.load(self.root, self.path)
        self.recipe = copy.deepcopy(original)
        self.recipe["steps"][1]["arguments"]["cases"][0]["integers"] = ["; arbitrary-command"]
        self.save()
        with self.assertRaises(ValueError):
            recipes.load(self.root, self.path)

    def test_failed_parent_and_timeout_block_test_and_keep_process_log(self):
        for label, code, timed_out in (("failed", 7, False), ("timeout", -9, True)):
            def failure(argv, cwd, timeout, **kwargs):
                if "-MD" in argv:
                    return code, "first typed build failure\n", timed_out, 0.1
                return self.execute(argv, cwd, timeout, **kwargs)
            result = self.run_recipe(label, failure)
            self.assertEqual("DENY", result["outcome"])
            self.assertEqual("BLOCKED", result["steps"][1]["outcome"])
            self.assertEqual(code, result["steps"][0]["commands"][-1]["exit"])
            self.assertEqual("first typed build failure\n", (self.root / label / "build/c-build.log").read_text())
            self.assertEqual("TIMEOUT" if timed_out else "DENY", result["steps"][0]["outcome"])

    def test_stdout_inventory_is_required_even_with_zero_exit(self):
        self.recipe["steps"][1]["arguments"]["cases"][0]["stdout"] = "missing completion\n"
        self.save()
        self.assertEqual("DENY", self.run_recipe("missing-stdout")["steps"][1]["outcome"])

    def test_backend_source_and_binary_drift_invalidate_read(self):
        self.assertEqual("PASS", self.run_recipe("bound")["outcome"])
        for path in (self.backend, self.root / "source.c", self.root / "bound/build/program"):
            original = path.read_bytes()
            path.write_bytes(original + b"changed")
            self.assertEqual("STALE", recipes.inspect_run(self.root / "bound")["identityStatus"])
            path.write_bytes(original)
        binary = self.root / "bound/build/program"
        binary.chmod(0o755)
        self.assertEqual("STALE", recipes.inspect_run(self.root / "bound")["identityStatus"])

    def test_unchanged_failure_cannot_be_hidden_by_new_directory_or_larger_budget(self):
        def failed(argv, cwd, timeout, **kwargs):
            return 1, "failed", False, 0.01
        self.run_recipe("old-failure", failed)
        result = self.run_recipe("renamed", prior=self.root / "old-failure")
        self.assertIn("unchanged failed", result["error"])
        self.recipe["steps"][0]["budgetSeconds"] = 11
        self.save()
        result = self.run_recipe("expanded", prior=self.root / "old-failure")
        self.assertIn("expanding a budget", result["error"])

    def test_tree_inventory_modes_and_internal_links_are_bound(self):
        tree = self.root / "tree"
        tree.mkdir()
        file = tree / "source"
        file.write_text("source")
        original = recipes.tree_identity(tree)
        (tree / "new").write_text("addition")
        self.assertNotEqual(original, recipes.tree_identity(tree))
        (tree / "new").unlink()
        file.chmod(0o755)
        self.assertNotEqual(original, recipes.tree_identity(tree))
        (tree / "outside").symlink_to(self.gcc)
        with self.assertRaisesRegex(ValueError, "external symlink"):
            recipes.tree_identity(tree)

    def test_mutating_native_step_clones_the_producer(self):
        tree = self.root / "producer"
        tree.mkdir()
        (tree / "source.c").write_text("original")
        directory = self.root / "step"
        directory.mkdir()
        class Context:
            def artifact(inner, ref, kind):
                return tree
            def remaining(inner):
                return 10
        context = Context()
        context.directory = directory
        clone = native.clone(context, {"step": "producer", "output": "source"}, "source-tree")
        (clone / "source.c").write_text("changed")
        self.assertEqual("original", (tree / "source.c").read_text())

    def test_producer_artifact_drift_during_a_dependent_prevents_pass(self):
        def changed(argv, cwd, timeout, **kwargs):
            result = self.execute(argv, cwd, timeout, **kwargs)
            if Path(argv[0]).name == "program":
                Path(argv[0]).write_text("changed during execution")
            return result
        self.assertEqual("STALE", self.run_recipe("binary-drift", changed)["outcome"])

    def test_undeclared_local_dependency_is_rejected_before_compilation(self):
        def undeclared(argv, cwd, timeout, **kwargs):
            result = self.execute(argv, cwd, timeout, **kwargs)
            if "-M" in argv:
                hidden = Path(cwd) / "hidden.h"
                hidden.write_text("hidden")
                deps = Path(argv[argv.index("-MF") + 1])
                deps.write_text(deps.read_text().strip() + " " + str(hidden) + "\n")
            return result
        result = self.run_recipe("undeclared", undeclared)
        self.assertIn("undeclared", result["steps"][0]["reason"])
        self.assertFalse(any("-MD" in call[0] for call in self.calls))

    def test_shared_deadline_caps_each_producer_subcommand(self):
        directory = self.root / "bounded"
        directory.mkdir()
        import time
        ctx = recipes.ExecutionContext(self.root, self.root, directory, {}, time.monotonic() + 0.1, {}, {}, {})
        with patch.object(recipes, "execute", return_value=(0, "", False, 0.01)) as call:
            ctx.run("subcommand", ["unit-command"], self.root, 600)
            self.assertLessEqual(call.call_args.args[2], 0.1)
        ctx.deadline = 0
        with patch.object(recipes, "execute") as call:
            with self.assertRaises(TimeoutError):
                ctx.run("blocked", ["unit-command"], self.root, 10)
            call.assert_not_called()

    def test_gambit_graph_retains_seed_source_and_suite_identity_boundaries(self):
        steps = [
            {"id": "materialize", "capability": "gambit.materialize", "dependsOn": [], "arguments": {"sourceLock": "source.lock.json"}},
            {"id": "configure", "capability": "gambit.configure", "dependsOn": ["materialize"], "arguments": {"source": {"step": "materialize", "output": "source"}, "cOptimization": 0, "rtsOptimization": 0}},
            {"id": "seed", "capability": "gambit.seed-core", "dependsOn": ["configure"], "arguments": {"source": {"step": "configure", "output": "source"}}},
            {"id": "source-core", "capability": "gambit.source-core", "dependsOn": ["seed"], "arguments": {"runtime": {"step": "seed", "output": "runtime"}}},
            {"id": "suite", "capability": "gambit.suite", "dependsOn": ["source-core"], "arguments": {"runtime": {"step": "source-core", "output": "runtime"}, "identity": {"step": "source-core", "output": "identity"}, "mode": "gsi", "regime": "whole-sequential", "selection": ["control.scm"], "expectedFiles": ["control.scm"]}}]
        (self.root / "source.lock.json").write_text("{}")
        self.recipe["inputs"] = ["source.lock.json"]
        self.recipe["steps"] = [{**step, "budgetSeconds": 10} for step in steps]
        self.save()
        self.assertEqual(5, len(recipes.load(self.root, self.path)[1]))
        self.recipe["steps"][3]["arguments"]["runtime"]["step"] = "configure"
        self.save()
        with self.assertRaisesRegex(ValueError, "dependency|type mismatch"):
            recipes.load(self.root, self.path)
        self.recipe["steps"][3]["arguments"]["runtime"]["step"] = "seed"
        self.recipe["steps"][4]["arguments"]["identity"]["step"] = "seed"
        self.recipe["steps"][4]["dependsOn"].append("seed")
        self.save()
        with self.assertRaisesRegex(ValueError, "same producer"):
            recipes.load(self.root, self.path)

    def test_suite_regimes_require_explicit_atomic_budget_and_bounded_capacity(self):
        arguments = {"runtime": {"step": "seed", "output": "runtime"},
                     "identity": {"step": "seed", "output": "identity"}, "mode": "gsc",
                     "regime": "atomic-coverage", "selection": ["control.scm"], "expectedFiles": ["control.scm"]}
        with self.assertRaises(ValueError):
            native.validate_suite(arguments, [])
        arguments["batchBudgetSeconds"] = 10
        native.validate_suite(arguments, [])
        for change in ({"regime": "whole-sequential"}, {"processors": True}, {"jobs": 0}):
            with self.assertRaises(ValueError):
                native.validate_suite({**arguments, **change}, [])

    def test_suite_shards_keep_exact_inventory_and_atomic_claim_separate(self):
        runtime = self.root / "runtime"
        for name in ("gsi", "gsc", "lib", "include", "bin"):
            (runtime / name).mkdir(parents=True)
        copied = self.root / "tests"
        (copied / "unit-tests").mkdir(parents=True)
        (copied / "run-unit-tests.scm").write_text("unit runner")
        files = [Path("one.scm"), Path("two.scm"), Path("three.scm")]
        for file in files:
            (copied / "unit-tests" / file).write_text("unit fixture")
        for regime in ("whole-parallel", "atomic-coverage"):
            directory = self.root / regime
            directory.mkdir()
            import time
            ctx = recipes.ExecutionContext(self.root, self.root, directory, {}, time.monotonic() + 10, {}, {}, {})
            def executed(argv, cwd, timeout, **kwargs):
                count = sum(str(argument).startswith("unit-tests/") for argument in argv)
                return 0, f"PASSED ALL {count} UNIT TESTS\n", False, 0.01
            with patch.object(recipes, "execute", side_effect=executed):
                rows = native.run_suite_groups(ctx, runtime, copied,
                    {"regime": regime, "mode": "gsc", "batchBudgetSeconds": 1}, files, 2, "p2")
            self.assertTrue(all(row["accepted"] for row in rows))
            self.assertEqual(sorted(str(file) for file in files), sorted(file for row in rows for file in row["files"]))
            self.assertEqual(3 if regime == "atomic-coverage" else 2, len(rows))
            self.assertTrue(all(row["effectiveBudgetSeconds"] <= (1 if regime == "atomic-coverage" else 10)
                                for row in ctx.commands))

    def test_suite_retry_review_blocks_runtime_probe_and_test(self):
        runtime = self.root / "candidate"
        for name in ("gsi", "gsc", "lib", "include", "bin"):
            (runtime / name).mkdir(parents=True)
        (runtime / "tests/unit-tests").mkdir(parents=True)
        (runtime / "tests/run-unit-tests.scm").write_text("unit runner")
        (runtime / "tests/unit-tests/control.scm").write_text("fixture")
        ident = self.root / "identity.json"
        ident.write_text("{}")
        directory = self.root / "suite-preflight"
        directory.mkdir()
        class Context:
            def artifact(inner, reference, kind):
                return runtime if reference["output"] == "runtime" else ident
            def remaining(inner):
                return 10
            def bind(inner, paths):
                list(paths)
            def run(inner, *args):
                raise AssertionError("runtime must not execute after preflight denial")
        ctx = Context()
        ctx.root, ctx.directory = self.root, directory
        ctx.receipt = {"engine": {}}
        arguments = {"runtime": {"output": "runtime"}, "identity": {"output": "identity"},
                     "mode": "gsi", "regime": "whole-sequential", "selection": ["control.scm"],
                     "expectedFiles": ["control.scm"]}
        for decision in ("DENY", "REVIEW_REQUIRED"):
            with patch("gambit_smp.suite_primitives.check_runtime"), patch.object(native, "compiler", return_value=str(self.gcc)), \
                    patch.object(native, "gnu_build_driver", return_value={}), \
                    patch("gambit_smp.native_review.preflight", return_value={"decision": decision, "inputs": {}}):
                with self.assertRaisesRegex(ValueError, decision):
                    native.suite(arguments, ctx)
            import shutil
            shutil.rmtree(directory / "runtime")

    def test_bootstrap_known_failure_gate_precedes_clone_and_from_scratch(self):
        runtime, identity = self.root / "seed", self.root / "seed-identity.json"
        runtime.mkdir()
        identity.write_text("{}")
        for decision in ("DENY", "REVIEW_REQUIRED"):
            directory = self.root / ("bootstrap-" + decision)
            directory.mkdir()
            class Context:
                def artifact(inner, ref, kind):
                    return identity if ref["output"] == "identity" else runtime
            ctx = Context()
            ctx.receipt, ctx.directory = {"engine": {}}, directory
            args = {"runtime": {"step": "seed", "output": "runtime"},
                    "identity": {"step": "seed", "output": "identity"},
                    "failures": "evidence/native-failures.json", "reviewRules": "evidence/rules.ss"}
            with patch("gambit_smp.native_review.preflight", return_value={"decision": decision}), \
                    patch.object(native, "clone") as clone, patch.object(native, "compiler") as compiler:
                with self.assertRaisesRegex(ValueError, decision):
                    native.bootstrap(args, ctx)
            clone.assert_not_called()
            compiler.assert_not_called()

    def test_locked_materialization_records_all_git_commands_under_one_deadline(self):
        import tarfile
        lock = self.root / "source.lock.json"
        overlay = self.root / "candidate.patch"
        overlay.write_text("unit overlay")
        base = self.root / "base"
        (base / "lib").mkdir(parents=True)
        (base / "lib/mem.c").write_text("base")
        candidate = self.root / "candidate.c"
        candidate.write_text("candidate")
        commit = "1" * 40
        (self.root / "vendor/gambit").mkdir(parents=True)
        gitdir = self.root / "git-metadata"
        gitdir.mkdir()
        (gitdir / "HEAD").write_text(commit)
        lock.write_text(json.dumps({"schema": "gambit-runtime-source-lock.v1", "revision": commit,
            "runtimeAdmitted": False, "releaseAdmitted": False, "submodule": "vendor/gambit",
            "repository": "https://git.cons.io/mighty-gerbils/gambit.git", "patch": "candidate.patch",
            "patchSha256": recipes.digest(overlay), "files": {"lib/mem.c": {
                "baseSha256": recipes.digest(base / "lib/mem.c"), "candidateSha256": recipes.digest(candidate)}}}))
        self.recipe["inputs"] = ["source.lock.json", "candidate.patch"]
        self.recipe["steps"] = [{"id": "materialize", "capability": "gambit.materialize", "dependsOn": [],
                                 "arguments": {"sourceLock": "source.lock.json"}, "budgetSeconds": 10}]
        self.save()
        def git_execute(argv, cwd, timeout, **kwargs):
            if "rev-parse" in argv:
                return 0, str(gitdir) if "--absolute-git-dir" in argv else commit, False, 0.01
            if "archive" in argv:
                output = next(arg.split("=", 1)[1] for arg in argv if arg.startswith("--output="))
                with tarfile.open(output, "w") as archive:
                    archive.add(base / "lib", arcname="lib")
            if "--numstat" in argv:
                return 0, "1\t1\tlib/mem.c\0", False, 0.01
            if "apply" in argv and "--check" not in argv:
                (Path(cwd) / "lib/mem.c").write_text("candidate")
            return 0, "", False, 0.01
        with patch.object(native, "host_tools", return_value=({"git": self.gcc}, {})), \
                patch.object(recipes, "execute", side_effect=git_execute):
            result = recipes.run(self.root, self.path, self.root / "materialized", Path("no-quint"), Path("no-node"),
                                 gcc=self.gcc, allow_native=True)
        self.assertEqual("PASS", result["outcome"])
        self.assertEqual(7, len(result["steps"][0]["commands"]))
        self.assertEqual("CURRENT", recipes.inspect_run(self.root / "materialized")["identityStatus"])
        (gitdir / "HEAD").write_text("changed")
        self.assertEqual("STALE", recipes.inspect_run(self.root / "materialized")["identityStatus"])

    def test_seed_and_regeneration_failures_retain_partial_observations(self):
        import time
        source = self.root / "partial-source"
        source.mkdir()
        for name, function, helper, arguments in (
                ("seed", native.seed, "build_seed_core", {"source": {}}),
                ("module", native.regenerate, "regenerate_module", {"runtime": {}, "module": "lib/_thread.scm"}),
                ("source-core", native.source_core, "rebuild_source_core", {"runtime": {}})):
            directory = self.root / ("partial-" + name)
            directory.mkdir()
            ctx = recipes.ExecutionContext(self.root, self.root, directory, {}, time.monotonic() + 10, {}, {}, {})
            with patch.object(ctx, "artifact", return_value=source), patch.object(native, "compiler"), \
                    patch("gambit_smp.gambit_build_primitives." + helper, return_value=(False, {"partial": name})):
                with self.assertRaises(ValueError):
                    function(arguments, ctx)
            self.assertEqual({"partial": name}, json.loads((directory / "observation.json").read_text()))


if __name__ == "__main__":
    unittest.main()
