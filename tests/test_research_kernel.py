import copy
import hashlib
import io
import json
from pathlib import Path
import tempfile
import time
import types
import unittest
from unittest.mock import patch

from gambit_smp import cli, recipes, research_kernel, source_capabilities


def sha(data):
    return hashlib.sha256(data).hexdigest()


class ResearchGraphTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name, data in {"evidence/source.lock.json": b"{}", "patches/fix.patch": b"patch",
                           "models/fixture.c": b"int main(void) { return 0; }\n",
                           "evidence/rules.ss": b"(ascent-fragment)"}.items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        ref = lambda step, output: {"step": step, "output": output}
        step = lambda name, cap, parents, args: dict(id=name, capability=cap, dependsOn=parents,
                                                     arguments=args, budgetSeconds=5)
        self.recipe = dict(schema=research_kernel.SCHEMA, id="different-mechanism", scope="unit-only",
                           inputs=["evidence/source.lock.json", "patches/fix.patch", "models/fixture.c", "evidence/rules.ss"],
                           budgetSeconds=40, steps=[
            step("source", "gambit.materialize", [], {"sourceLock": "evidence/source.lock.json"}),
            step("workspace", "source.project", ["source"], {"source": ref("source", "source"), "files": [
                {"target": "fixture.c", "origin": {"kind": "research-asset", "path": "models/fixture.c"},
                 "sha256": sha((self.root / "models/fixture.c").read_bytes())},
                {"target": "unit.inc", "origin": {"kind": "source-artifact", "path": "lib/unit.c"},
                 "sha256": sha(b"int value = 1;\n")}] }),
            step("binding", "source.bind", ["workspace"], {"workspace": ref("workspace", "workspace")}),
            step("build", "native.workspace-build", ["workspace", "binding"], {
                "workspace": ref("workspace", "workspace"), "binding": ref("binding", "binding"),
                "translationUnit": "fixture.c", "standard": "c11", "optimization": 1, "pthread": False,
                "target": "executable"}),
            step("test", "native.test", ["build"], {"executable": ref("build", "executable"),
                "cases": [{"id": "observe", "integers": [], "stdout": ""}]}),
            step("verdict", "evidence.evaluate", ["source", "workspace", "binding", "build", "test"], {
                "rules": ["evidence/rules.ss"], "queries": {"missing": "missing_step"}, "expected": {"missing": []}})])
        self.path = self.root / "evidence/control.recipe.json"

    def load(self, recipe=None):
        self.path.write_text(json.dumps(recipe or self.recipe))
        return recipes.load(self.root, self.path)

    def test_artifact_graph_accepts_data_without_feature_registration(self):
        self.assertEqual("different-mechanism", self.load()[0]["id"])

    def test_new_lane_rejects_archived_producer_receipts_and_includes(self):
        for name in ("evidence/source-results/old/receipt.json", "models/generated.inc", "models/producer.py"):
            with self.subTest(name=name):
                value = copy.deepcopy(self.recipe)
                value["inputs"].append(name)
                path = self.root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("old")
                with self.assertRaisesRegex(ValueError, "archived producer"):
                    self.load(value)

    def test_raw_file_builder_cannot_bypass_artifact_binding(self):
        value = copy.deepcopy(self.recipe)
        value["steps"][3].update(capability="native.c-build", arguments={
            "sources": ["models/fixture.c"], "headers": [], "standard": "c11", "optimization": 1,
            "pthread": False, "target": "executable"})
        with self.assertRaisesRegex(ValueError, "historical producer"):
            self.load(value)

    def test_source_binding_cannot_be_from_another_workspace(self):
        value = copy.deepcopy(self.recipe)
        clone = copy.deepcopy(value["steps"][1])
        clone["id"] = "other-workspace"
        value["steps"].insert(2, clone)
        value["steps"][3]["arguments"]["workspace"]["step"] = "other-workspace"
        value["steps"][3]["dependsOn"] = ["other-workspace"]
        value["steps"][-1]["dependsOn"].append("other-workspace")
        with self.assertRaisesRegex(ValueError, "exact workspace"):
            self.load(value)

    def test_synthetic_only_workspace_cannot_claim_source_origin(self):
        value = copy.deepcopy(self.recipe)
        value["steps"][1]["arguments"]["files"].pop()
        with self.assertRaisesRegex(ValueError, "actual locked-source"):
            self.load(value)

    def test_native_verdict_requires_complete_graph(self):
        value = copy.deepcopy(self.recipe)
        value["steps"][-1]["dependsOn"].remove("test")
        with self.assertRaisesRegex(ValueError, "complete observation"):
            self.load(value)

    def test_editable_executor_cannot_run_v2_even_with_native_permission(self):
        self.load()
        with self.assertRaisesRegex(ValueError, "sealed executor"):
            recipes.run(self.root, self.path, self.root / "out", Path("quint"), Path("node"), allow_native=True)
        self.assertFalse((self.root / "out").exists())

    def test_old_cli_producer_is_not_an_active_experiment_entry(self):
        with patch.object(cli, "import_module") as imported, patch("sys.stderr", new_callable=io.StringIO), self.assertRaises(SystemExit):
            cli.main(["source-unit", "--case", "new-case"])
        imported.assert_not_called()

    def test_historical_reproduction_requires_explicit_selection(self):
        adapter = types.SimpleNamespace(main=lambda: 7)
        with patch.object(cli, "import_module", return_value=adapter):
            self.assertEqual(7, cli.main(["--historical-reproduction", "source-unit"]))

    def test_research_run_executes_declared_recipe_without_extra_native_switch(self):
        arguments = ["research", "--run", "declared", "--engine", "seal", "--out", "result"]
        with patch("sys.argv", arguments), \
                patch.object(recipes, "discover", return_value={"declared": self.path}), \
                patch.object(research_kernel, "run_sealed", return_value={"outcome": "PASS"}) as launched, \
                patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(0, research_kernel.main())
        self.assertIs(launched.call_args.kwargs["allow_native"], True)

    def test_research_run_still_requires_sealed_engine(self):
        with patch("sys.argv", ["research", "--run", "declared", "--out", "result"]), \
                patch.object(recipes, "discover", return_value={"declared": self.path}), \
                patch.object(research_kernel, "run_sealed") as launched, \
                patch("sys.stderr", new_callable=io.StringIO), self.assertRaises(SystemExit):
            research_kernel.main()
        launched.assert_not_called()

    def test_failed_sealed_retry_requires_cause_and_retains_independent_denial(self):
        self.load()
        inputs = {name: recipes.digest(self.root / name)
                  for name in ["evidence/control.recipe.json", *self.recipe["inputs"]]}
        prior = self.root / "failed"
        prior.mkdir()
        previous = dict(schema="sealed-research-run.v1", recipe=self.recipe["id"],
                        inputs=inputs, engineId="unit-seal", outcome="DENY", budgetSeconds=40,
                        stepBudgets={step["id"]: 5 for step in self.recipe["steps"]})
        (prior / "receipt.json").write_text(json.dumps(previous))
        original = (prior / "receipt.json").read_bytes()
        for name, total, step_budget, denial in (
                ("unchanged", 40, 5, "unchanged failed"),
                ("whole-expanded", 41, 5, "prior budget"),
                ("step-expanded", 40, 6, "prior step budget")):
            with self.subTest(name=name):
                self.recipe["budgetSeconds"] = total
                self.recipe["steps"][0]["budgetSeconds"] = step_budget
                self.load()
                with patch.object(research_kernel, "manifest_paths", return_value={"engineId": "unit-seal"}), \
                        patch.object(research_kernel, "execute") as launched:
                    result = research_kernel.run_sealed(self.root, self.path, self.root / name,
                                                        self.root / "seal", prior=prior, allow_native=True)
                launched.assert_not_called()
                self.assertFalse(result["executionLaunched"])
                self.assertIn(denial, result["denial"])
                self.assertEqual("DENY", json.loads((self.root / name / "receipt.json").read_text())["outcome"])
        self.assertEqual(original, (prior / "receipt.json").read_bytes())

    def test_projection_schema_rejects_handlers_overlap_and_path_escape(self):
        original = self.recipe["steps"][1]["arguments"]
        for mutation in (
                lambda row: row.update(handler="prepare-new-protocol"),
                lambda row: row.update(target="../outside.c"),
                lambda row: row.update(ranges=[{"start": 0, "end": 8, "sha256": "0" * 64},
                                               {"start": 7, "end": 9, "sha256": "0" * 64}])):
            value = copy.deepcopy(original)
            mutation(value["files"][1])
            with self.assertRaises(ValueError):
                source_capabilities.validate_project(value, self.recipe["inputs"])


class SourceArtifactTests(unittest.TestCase):
    def setUp(self):
        ResearchGraphTests.setUp(self)
        source = self.root / "out/source/tree"
        source.mkdir(parents=True)
        (source / "lib").mkdir()
        (source / "lib/unit.c").write_bytes(b"int value = 1;\n")
        self.out = self.root / "out"
        self.receipt = {"steps": [{"id": "source", "outcome": "PASS", "outputs": {
            "source": {"type": "source-tree", "path": "source/tree", "identity": recipes.tree_identity(source)}}}]}

    def context(self, name):
        directory = self.out / name
        directory.mkdir()
        return recipes.ExecutionContext(self.root, self.out, directory, {}, time.monotonic() + 5,
                                        {}, self.receipt, {})

    def project(self, args=None):
        context = self.context("workspace")
        result = source_capabilities.project(args or self.recipe["steps"][1]["arguments"], context)
        self.receipt["steps"].append({"id": "workspace", "outcome": "PASS", **result})
        return context.directory / "workspace"

    def test_projection_and_binding_preserve_byte_origin_not_semantic_admission(self):
        workspace = self.project()
        self.assertEqual(b"int value = 1;\n", (workspace / "unit.inc").read_bytes())
        context = self.context("binding")
        result = source_capabilities.bind({"workspace": {"step": "workspace", "output": "workspace"}}, context)
        binding = json.loads((context.directory / "binding.json").read_text())
        self.assertFalse(binding["sourceRefinementAdmitted"])
        self.assertEqual("byte-origin-only", result["claim"])

    def test_projection_rejects_wrong_full_source_hash(self):
        value = copy.deepcopy(self.recipe["steps"][1]["arguments"])
        value["files"][1]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "reviewed byte"):
            self.project(value)

    def test_range_projection_uses_numeric_identity_not_feature_tokens(self):
        value = copy.deepcopy(self.recipe["steps"][1]["arguments"])
        value["files"][1]["ranges"] = [{"start": 4, "end": 9, "sha256": sha(b"value")}]
        source_capabilities.validate_project(value, self.recipe["inputs"])
        self.assertEqual(b"value", (self.project(value) / "unit.inc").read_bytes())

    def test_projection_rejects_out_of_bounds_and_changed_spans(self):
        for span in ({"start": 0, "end": 999, "sha256": sha(b"value")},
                     {"start": 4, "end": 9, "sha256": "0" * 64}):
            with self.subTest(span=span):
                value = copy.deepcopy(self.recipe["steps"][1]["arguments"])
                value["files"][1]["ranges"] = [span]
                directory = self.out / "workspace"
                if directory.exists():
                    import shutil
                    shutil.rmtree(directory)
                with self.assertRaises(ValueError):
                    self.project(value)

    def test_binding_detects_workspace_drift_before_any_compiler(self):
        workspace = self.project()
        (workspace / "unit.inc").write_text("changed")
        with self.assertRaisesRegex(ValueError, "artifact dependency drift"):
            source_capabilities.bind({"workspace": {"step": "workspace", "output": "workspace"}}, self.context("binding"))


class EngineSealTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.binding = self.root / "provider"
        self.binding.mkdir()
        (self.binding / "__init__.py").write_text("unit fixture, not a native engine")
        self.api = self.root / "api"
        self.api.mkdir()
        (self.api / "_ascent_cffi.so").write_bytes(b"unit fixture extension")
        import sys
        library = self.api / ("libascent.dylib" if sys.platform == "darwin" else "libascent.so")
        library.write_bytes(b"unit fixture library")
        (self.api / "receipt.json").write_text(json.dumps({"schema": "ascent.cffi-api-build.v1",
            "extensionSha256": sha(b"unit fixture extension"), "librarySha256": sha(b"unit fixture library")}))

    def seal(self):
        spec = types.SimpleNamespace(submodule_search_locations=[str(self.binding)])
        with patch.object(research_kernel.importlib.util, "find_spec", return_value=spec), \
                patch("gambit_smp.provider_contract.inspect_provider", return_value={"status": "unit-fixture"}):
            return research_kernel.seal(self.root / "engine", gcc=Path(__file__), ascent_api=self.api)

    def test_seal_is_immutable_and_binds_inventory(self):
        manifest = self.seal()
        self.assertEqual(manifest["engineId"], research_kernel.manifest_paths(self.root / "engine")["engineId"])
        with self.assertRaisesRegex(ValueError, "fresh directory"):
            self.seal()

    def test_seal_rejects_extra_code_and_byte_drift(self):
        self.seal()
        engine = self.root / "engine"
        engine.chmod(0o755)
        (engine / "new-handler.py").write_text("handler")
        with self.assertRaisesRegex(ValueError, "inventory drift"):
            research_kernel.manifest_paths(engine)
        (engine / "new-handler.py").unlink()
        target = engine / "runner.py"
        target.chmod(0o644)
        target.write_text("changed")
        with self.assertRaisesRegex(ValueError, "implementation drift"):
            research_kernel.manifest_paths(engine)

    def test_editable_code_cannot_present_a_seal_as_its_own_execution_identity(self):
        self.seal()
        with self.assertRaisesRegex(ValueError, "editable checkout"):
            research_kernel.execution_identity(self.root / "engine")

    def test_same_bytes_cannot_escape_the_seal_through_a_symlink(self):
        self.seal()
        engine = self.root / "engine"
        engine.chmod(0o755)
        target = engine / "runner.py"
        external = self.root / "same-bytes.py"
        external.write_bytes(target.read_bytes())
        target.unlink()
        target.symlink_to(external)
        with self.assertRaisesRegex(ValueError, "implementation drift"):
            research_kernel.manifest_paths(engine)

    def test_wrong_engine_api_receipt_cannot_be_sealed(self):
        (self.api / "_ascent_cffi.so").write_bytes(b"drift")
        with self.assertRaisesRegex(ValueError, "receipt-bound"):
            self.seal()

    def test_provider_mismatch_is_rejected_before_seal_directory_creation(self):
        spec = types.SimpleNamespace(submodule_search_locations=[str(self.binding)])
        with patch.object(research_kernel.importlib.util, "find_spec", return_value=spec), \
                patch("gambit_smp.provider_contract.inspect_provider", side_effect=ValueError("native provider mismatch")):
            with self.assertRaisesRegex(ValueError, "provider mismatch"):
                research_kernel.seal(self.root / "engine", gcc=Path(__file__), ascent_api=self.api)
        self.assertFalse((self.root / "engine").exists())

    def test_missing_native_rule_provider_fails_closed(self):
        with patch.object(research_kernel.importlib.util, "find_spec", return_value=None):
            with self.assertRaisesRegex(ValueError, "no fallback"):
                research_kernel.seal(self.root / "engine", gcc=Path(__file__), ascent_api=self.api)

    def test_static_import_closure_cannot_reach_a_historical_producer(self):
        package = self.root / "package"
        package.mkdir()
        for name in ("__init__", "research_kernel", "recipes", "native_capabilities", "source_capabilities",
                     "evidence_capabilities", "process_observation", "ascent_program", "validation_domains"):
            (package / (name + ".py")).write_text("")
        (package / "recipes.py").write_text("from gambit_smp.source_unit import prepare\n")
        with self.assertRaisesRegex(ValueError, "historical producer reachable"):
            research_kernel.implementation_paths(package)


class ProcessObservationTests(unittest.TestCase):
    def test_threaded_batch_runs_independent_processes_and_preserves_exits(self):
        import sys
        from gambit_smp.process_observation import capture_batch
        with tempfile.TemporaryDirectory() as folder:
            code = ("import pathlib,sys,time; p=pathlib.Path(sys.argv[1]); "
                    "(p/sys.argv[2]).touch(); deadline=time.monotonic()+2; "
                    "exec('while len(list(p.iterdir()))<2 and time.monotonic()<deadline:\\n time.sleep(.005)'); "
                    "assert len(list(p.iterdir()))==2; print(sys.argv[2]); "
                    "print('warning',file=sys.stderr); raise SystemExit(int(sys.argv[3]))")
            jobs = [{"argv": [sys.executable, "-c", code, folder, str(i), str(7 * i)],
                     "cwd": folder, "environment": {}, "budget": 3} for i in range(2)]
            result = capture_batch(jobs, workers=2, budget=3)
        observed = [row["observation"] for row in result["runs"]]
        self.assertEqual([0, 7], [row["exit"] for row in observed])
        self.assertEqual(["0\n", "1\n"], [row["stdout"] for row in observed])
        self.assertTrue(all(row["stderr"] == "warning\n" for row in observed))
        self.assertTrue(all(row["group_quiescent"] and not row["timeout"] for row in observed))
        self.assertEqual(2, len({row["pid"] for row in observed}))

    def test_threaded_batch_queue_does_not_reset_whole_deadline(self):
        import sys
        from gambit_smp.process_observation import capture_batch
        job = {"argv": [sys.executable, "-c", "import time; time.sleep(2)"],
               "cwd": Path.cwd(), "environment": {}, "budget": 1}
        result = capture_batch([job, job], workers=1, budget=.05)
        first, second = result["runs"]
        self.assertTrue(first["observation"]["timeout"])
        self.assertLessEqual(first["processBudgetSeconds"], .05)
        self.assertFalse(second["started"])
        self.assertTrue(second["deadlineExpired"])
        self.assertIsNone(second["observation"])
        self.assertLess(result["seconds"], 1)

    def test_stdout_identity_is_not_contaminated_by_stderr_warning(self):
        import sys
        from gambit_smp.process_observation import capture
        observed = capture([sys.executable, "-c", "import sys; print('identity'); print('warning', file=sys.stderr)"],
                           Path.cwd(), 5, {})
        self.assertEqual("identity\n", observed.stdout)
        self.assertEqual("warning\n", observed.stderr)
        self.assertEqual(0, observed.exit)
        self.assertFalse(observed.timeout)

    def test_final_nonzero_exit_is_not_swallowed(self):
        import sys
        from gambit_smp.process_observation import capture
        observed = capture([sys.executable, "-c", "raise SystemExit(7)"], Path.cwd(), 5, {})
        self.assertEqual(7, observed.exit)

    def test_process_group_timeout_is_a_failure_with_final_exit(self):
        import sys
        from gambit_smp.process_observation import capture
        observed = capture([sys.executable, "-c", "import time; time.sleep(2)"], Path.cwd(), 0.05, {})
        self.assertTrue(observed.timeout)
        self.assertLess(observed.exit, 0)
        self.assertLess(observed.seconds, 1)

    def test_bounded_context_retains_both_streams_but_require_returns_stdout(self):
        import sys
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            context = recipes.ExecutionContext(root, root, root, {}, time.monotonic() + 5, {}, {"engine": {}}, {})
            text = context.require("identity", [sys.executable, "-c",
                "import sys; print('identity'); print('warning', file=sys.stderr)"], root, 5)
            self.assertEqual("identity\n", text)
            self.assertEqual("warning\n", (root / "identity.stderr").read_text())
            self.assertEqual(sha(b"warning\n"), context.commands[0]["stderrSha256"])


if __name__ == "__main__":
    unittest.main()
