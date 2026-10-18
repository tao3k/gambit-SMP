import copy
import hashlib
import io
import json
import os
import platform
from pathlib import Path
import tempfile
import sys
import subprocess
import tarfile
import time
import types
import unittest
from unittest.mock import patch

from gambit_smp import cli, recipes, research_kernel, source_capabilities


def sha(data):
    return hashlib.sha256(data).hexdigest()


class RuleWorkerBoundaryTests(unittest.TestCase):
    def test_rule_worker_reuses_only_current_full_before_after_boundary(self):
        from gambit_smp import ascent_program, evidence_capabilities
        with tempfile.TemporaryDirectory() as directory:
            engine = Path(directory).resolve()
            request = engine / "request.json"
            request.write_text(json.dumps({"engineId": "bound"}))
            manifest = {"engineId": "bound", "files": {"native/resource": "exact-sha"}}

            def evaluate(value):
                self.assertEqual("bound", value["engineId"])
                self.assertEqual((engine, manifest), ascent_program._verified_api.get())

            with patch.object(sys, "argv", ["runner", "rules", str(request)]), \
                    patch.object(research_kernel, "execution_identity", return_value=manifest) as identity, \
                    patch.object(evidence_capabilities, "native_evaluate", side_effect=evaluate) as native:
                self.assertEqual(0, research_kernel.worker(engine))
            self.assertEqual([((engine,), {}), ((engine,), {})], identity.call_args_list)
            native.assert_called_once()
            self.assertIsNone(ascent_program._verified_api.get())

    def test_rule_worker_does_not_skip_exit_checks_on_error_or_drift(self):
        from gambit_smp import ascent_program, evidence_capabilities
        with tempfile.TemporaryDirectory() as directory:
            engine = Path(directory).resolve()
            request = engine / "request.json"
            for request_id, final_id, native_error, message in (
                    ("wrong", "bound", None, "different engine seal"),
                    ("bound", "changed", None, "seal changed"),
                    ("bound", "bound", RuntimeError("query failed"), "query failed")):
                with self.subTest(request=request_id, final=final_id, error=native_error):
                    request.write_text(json.dumps({"engineId": request_id}))
                    with patch.object(sys, "argv", ["runner", "rules", str(request)]), \
                            patch.object(research_kernel, "execution_identity", side_effect=[
                                {"engineId": "bound"}, {"engineId": final_id}]) as identity, \
                            patch.object(evidence_capabilities, "native_evaluate", side_effect=native_error), \
                            self.assertRaisesRegex((ValueError, RuntimeError), message):
                        research_kernel.worker(engine)
                    self.assertEqual(2, identity.call_count)
                    self.assertIsNone(ascent_program._verified_api.get())


class ResearchGraphTests(unittest.TestCase):
    def test_manifest_identity_cache_is_exact_bytes_not_a_file_validation_cache(self):
        research_kernel.manifest_content_identity.cache_clear()
        raw = b'{"engineId":"declared","files":{"a":"sha"}}'
        expected = research_kernel.content_id({"files": {"a": "sha"}})
        self.assertEqual(expected, research_kernel.manifest_content_identity(raw))
        self.assertEqual(expected, research_kernel.manifest_content_identity(raw))
        self.assertEqual(1, research_kernel.manifest_content_identity.cache_info().hits)
        changed = b'{"engineId":"declared","files":{"a":"changed"}}'
        self.assertNotEqual(expected, research_kernel.manifest_content_identity(changed))
        parsed = json.loads(raw)
        parsed["files"]["a"] = "caller mutation"
        self.assertEqual(expected, research_kernel.manifest_content_identity(raw))

    def test_sealed_parent_preserves_identity_for_recipe_child(self):
        from gambit_smp import host_environment
        self.load()
        manifest = {"engineId": "unit-seal", "hostTools": {"python": {"path": sys.executable}}}
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(host_environment, "observe", return_value=None), \
                patch.object(research_kernel, "retain_run_record", return_value={"path": "unit-only"}), \
                patch.object(research_kernel, "execute", return_value=(2, "no child result", False, .01)) as launched, \
                patch.dict(os.environ, {"USER": "fixture-user"}):
            result = research_kernel.run_sealed(self.root, self.path, self.root / "identity", self.root / "seal")
        launched.assert_called_once()
        self.assertEqual("fixture-user", launched.call_args.kwargs["env"]["USER"])
        self.assertEqual("DENY", result["outcome"])

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
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
        arguments = ["research", "--run", "declared", "--engine", "seal", "--out", ".cache/result"]
        with patch("sys.argv", arguments), \
                patch.object(recipes, "discover", return_value={"declared": self.path}), \
                patch.object(research_kernel, "run_sealed", return_value={"outcome": "PASS"}) as launched, \
                patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(0, research_kernel.main())
        self.assertIs(launched.call_args.kwargs["allow_native"], True)

    def test_explicit_recipe_validates_its_closure_without_global_discovery(self):
        self.load()
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        arguments = ["research", "--run", "evidence/control.recipe.json", "--engine", "seal", "--out", ".cache/result"]
        with patch("sys.argv", arguments), patch.object(research_kernel, "ROOT", self.root), \
                patch.object(recipes, "discover", side_effect=AssertionError("unrelated graph")), \
                patch.object(research_kernel, "run_sealed", return_value={"outcome": "PASS"}) as launched, \
                patch("sys.stdout", new_callable=io.StringIO):
            self.assertEqual(0, research_kernel.main())
        self.assertEqual(self.path.resolve(), launched.call_args.args[1])

    def test_research_run_still_requires_sealed_engine(self):
        with patch("sys.argv", ["research", "--run", "declared", "--out", ".cache/result"]), \
                patch.object(recipes, "discover", return_value={"declared": self.path}), \
                patch.object(research_kernel, "run_sealed") as launched, \
                patch("sys.stderr", new_callable=io.StringIO), self.assertRaises(SystemExit):
            research_kernel.main()
        launched.assert_not_called()

    def test_engine_read_exposes_validated_tool_bindings_without_execution(self):
        engine = self.root / "engine"
        engine.mkdir()
        (engine / "engine.json").write_text("{}")
        manifest = {"engineId": "bound-engine", "hostTools": {
            "quint": {"path": "/host/quint", "sha256": "bound-tool"},
            "quint-file:/host/dependency": {"path": "/host/dependency", "sha256": "dependency"}},
            "capabilities": ["quint.verify"], "files": {"private-inventory": "not-rendered"}}
        with patch.object(research_kernel, "manifest_paths", return_value=manifest) as checked, \
                patch.object(research_kernel, "run_sealed") as launched, \
                patch("sys.argv", ["research", "--read", str(engine)]), \
                patch("sys.stdout", new_callable=io.StringIO) as output:
            self.assertEqual(0, research_kernel.main())
        checked.assert_called_once_with(engine.resolve())
        launched.assert_not_called()
        result = json.loads(output.getvalue())
        self.assertEqual(result["hostTools"], {"quint": manifest["hostTools"]["quint"]})
        self.assertEqual(result["hostToolDependencyCount"], 1)
        self.assertEqual(result["capabilities"], ["quint.verify"])
        self.assertNotIn("files", result)
        self.assertFalse(result["executionLaunched"])
        self.assertFalse(result["runtimeAdmitted"])

    def test_engine_read_does_not_hide_drift_or_ambiguous_artifact_identity(self):
        engine = self.root / "engine"
        engine.mkdir()
        (engine / "engine.json").write_text("{}")
        with patch.object(research_kernel, "manifest_paths", side_effect=ValueError("tool drift")), \
                self.assertRaisesRegex(ValueError, "tool drift"):
            research_kernel.inspect(engine)
        (engine / "receipt.json").write_text("{}")
        with self.assertRaisesRegex(ValueError, "unambiguous seal"):
            research_kernel.inspect(engine)

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

    def test_stage_retry_retains_interrupted_cost_without_reducing_fresh_timers(self):
        from gambit_smp import host_environment
        self.load()
        prior = self.root / "interrupted"
        prior.mkdir()
        previous = dict(schema="sealed-research-run.v1", recipe=self.recipe["id"],
                        inputs={}, engineId="old-seal", outcome="DENY", budgetSeconds=40,
                        wholeSeconds=39, timeout=True, parentReaped=True, processGroupQuiescent=True,
                        stepBudgets={step["id"]: 5 for step in self.recipe["steps"]})
        previous_path = prior / "receipt.json"
        previous_path.write_text(json.dumps(previous))
        original = previous_path.read_bytes()
        self.recipe.pop("budgetSeconds")
        self.recipe["timeoutPolicy"] = {"mode": "per-stage", "overheadSeconds": 20}
        self.load()
        manifest = {"engineId": "new-seal", "hostTools": {"python": {"path": sys.executable}}}
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(host_environment, "observe", return_value=None), \
                patch.object(research_kernel, "retain_run_record", return_value={"path": "unit-only"}), \
                patch.object(research_kernel, "execute", return_value=(2, "fixture only", False, .01)) as launched:
            result = research_kernel.run_sealed(self.root, self.path, self.root / "fresh-stages",
                                                self.root / "seal", prior=prior)
        self.assertGreater(launched.call_args.args[2], 49)
        self.assertEqual(50, result["supervisorWatchdogSeconds"])
        self.assertTrue(result["prior"]["interruptedPriorExpenditure"]["accountingOnly"])
        self.assertIsNone(json.loads((self.root / "fresh-stages/request.json").read_text())["prior"])
        self.assertEqual(original, previous_path.read_bytes())
        self.assertNotIn("performanceBudgetExceeded", result)

    def test_whole_timeout_missing_child_is_accounting_only_with_real_change(self):
        from gambit_smp import host_environment
        self.load()
        prior = self.root / "whole-interrupted"
        prior.mkdir()
        previous = dict(schema="sealed-research-run.v1", recipe=self.recipe["id"],
                        inputs={}, engineId="old-seal", outcome="DENY", budgetSeconds=40,
                        wholeSeconds=39, timeout=True, parentReaped=True, processGroupQuiescent=True,
                        stepBudgets={step["id"]: 5 for step in self.recipe["steps"]})
        (prior / "receipt.json").write_text(json.dumps(previous))
        original = (prior / "receipt.json").read_bytes()
        manifest = {"engineId": "new-seal", "hostTools": {"python": {"path": sys.executable}}}
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(host_environment, "observe", return_value=None), \
                patch.object(research_kernel, "retain_run_record", return_value={"path": "unit-only"}), \
                patch.object(research_kernel, "execute", return_value=(2, "unit only", False, .01)) as launched:
            result = research_kernel.run_sealed(self.root, self.path, self.root / "whole-new",
                                                self.root / "seal", prior=prior)
        self.assertLessEqual(launched.call_args.args[2], 40)
        self.assertTrue(result["prior"]["interruptedPriorExpenditure"]["accountingOnly"])
        self.assertIsNone(json.loads((self.root / "whole-new/request.json").read_text())["prior"])
        self.assertEqual(original, (prior / "receipt.json").read_bytes())
        self.assertNotEqual(result["outcome"], "PASS")

    def test_timeout_policy_migration_requires_unchanged_graph_and_inputs(self):
        from gambit_smp import host_environment
        self.load()
        old_name = "evidence/legacy.recipe.json"
        old_path = self.root / old_name
        old_path.write_bytes(self.path.read_bytes())
        prior = self.root / "old-timeout"
        prior.mkdir()
        request_path = prior / "request.json"
        request_path.write_text(json.dumps({"recipe": old_name}))
        previous = dict(schema="sealed-research-run.v1", recipe=self.recipe["id"],
                        inputs={name: recipes.digest(self.root / name)
                                for name in [old_name, *self.recipe["inputs"]]},
                        engineId="old-seal", outcome="DENY", budgetSeconds=40, wholeSeconds=40,
                        timeout=True, parentReaped=True, processGroupQuiescent=True,
                        artifacts={"request.json": recipes.digest(request_path)},
                        stepBudgets={step["id"]: 5 for step in self.recipe["steps"]})
        (prior / "receipt.json").write_text(json.dumps(previous))
        self.recipe["id"] = "stage-policy-migration"
        self.recipe.pop("budgetSeconds")
        self.recipe["timeoutPolicy"] = {"mode": "per-stage", "overheadSeconds": 20}
        manifest = {"engineId": "new-seal", "hostTools": {"python": {"path": sys.executable}}}
        for changed in (False, True):
            with self.subTest(changed=changed):
                self.recipe["steps"][0]["budgetSeconds"] = 6 if changed else 5
                self.load()
                with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                        patch.object(host_environment, "observe", return_value=None), \
                        patch.object(research_kernel, "retain_run_record", return_value={"path": "unit-only"}), \
                        patch.object(research_kernel, "execute", return_value=(2, "fixture", False, .01)) as launched:
                    result = research_kernel.run_sealed(self.root, self.path, self.root / str(changed),
                                                        self.root / "seal", prior=prior)
                if changed:
                    launched.assert_not_called()
                    self.assertIn("exact graph", result["denial"])
                else:
                    launched.assert_called_once()
                    self.assertTrue(result["prior"]["timeoutPolicyMigration"]["sameGraph"])

    def test_host_prelaunch_denial_repair_retains_outer_without_inventing_child(self):
        from gambit_smp import host_environment as host
        self.load()
        old = {"schema": host.SCHEMA, "operation": "ipv4-loopback-bind", "epoch": "boot",
               "available": False, "errno": 1}
        current = {**old, "available": True, "errno": None}
        manifest = {"engineId": "unit-seal", "hostTools": {"python": {"path": sys.executable}}}
        prior = self.root / "host-refused"
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(host, "observe", return_value=old), patch.object(research_kernel, "execute") as launched:
            result = research_kernel.run_sealed(self.root, self.path, prior, self.root / "seal")
        launched.assert_not_called()
        self.assertEqual(host.ERROR, result["denial"])
        original = (prior / "receipt.json").read_bytes()
        target = self.root / "host-repaired"
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(host, "observe", return_value=current), \
                patch.object(research_kernel, "retain_run_record", return_value={"path": "unit-only"}), \
                patch.object(research_kernel, "execute", return_value=(2, "no child result", False, .01)) as launched:
            result = research_kernel.run_sealed(self.root, self.path, target, self.root / "seal", prior=prior)
        launched.assert_called_once()
        self.assertTrue(result["prior"]["environmentRepaired"])
        self.assertEqual(sha(original), result["prior"]["receiptSha256"])
        self.assertIsNone(json.loads((target / "request.json").read_text())["prior"])
        self.assertEqual("DENY", result["outcome"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual(original, (prior / "receipt.json").read_bytes())
        self.recipe["budgetSeconds"] += 1
        self.load()
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(host, "observe", return_value=current), patch.object(research_kernel, "execute") as launched:
            result = research_kernel.run_sealed(self.root, self.path, self.root / "expanded-host-retry",
                                                self.root / "seal", prior=prior)
        launched.assert_not_called()
        self.assertIn("prior budget", result["denial"])

    def test_progress_prelaunch_environment_repair_needs_no_invented_process(self):
        from gambit_smp import host_environment as host
        self.recipe.pop("budgetSeconds")
        self.recipe["timeoutPolicy"] = {"mode": "progress", "overheadSeconds": 30}
        self.load()
        old = {"schema": host.SCHEMA, "operation": "ipv4-loopback-bind", "epoch": None,
               "available": False, "errno": 1}
        current = {**old, "epoch": "observed-boot", "available": True, "errno": None}
        manifest = {"engineId": "unit-seal", "hostTools": {"python": {"path": sys.executable}}}
        prior = self.root / "progress-host-refused"
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(host, "observe", return_value=old), patch.object(research_kernel, "execute") as launched:
            result = research_kernel.run_sealed(self.root, self.path, prior, self.root / "seal")
        launched.assert_not_called()
        original = (prior / "receipt.json").read_bytes()
        self.assertFalse(result["executionLaunched"])
        self.assertNotIn("processGroupQuiescent", result)
        for available in (False, True):
            with self.subTest(loopback_available=available), \
                    patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                    patch.object(host, "observe", return_value=current if available else old), \
                    patch.object(research_kernel, "retain_run_record", return_value={"path": "unit-only"}), \
                    patch.object(research_kernel, "execute", return_value=(2, "no child result", False, .01)) as launched:
                target = self.root / ("progress-repaired" if available else "progress-still-denied")
                result = research_kernel.run_sealed(self.root, self.path, target, self.root / "seal", prior=prior)
                self.assertEqual(available, launched.called)
                if available:
                    self.assertTrue(result["prior"]["environmentRepaired"])
                    self.assertEqual(sha(original), result["prior"]["receiptSha256"])
                    self.assertIsNone(json.loads((target / "request.json").read_text())["prior"])
                self.assertEqual("DENY", result["outcome"])
                self.assertFalse(result["runtimeAdmitted"])
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

    def test_interrupted_launch_retains_header_without_terminal_pass_or_head(self):
        from gambit_smp.reasoning_history import read_journal
        self.load()
        manifest = {"engineId": "unit-seal", "hostTools": {"python": {"path": sys.executable}}}
        out = self.root / "interrupted"
        with patch.object(research_kernel, "manifest_paths", return_value=manifest), \
                patch.object(research_kernel, "clock_epoch", return_value=None), \
                patch.object(research_kernel, "execute", side_effect=KeyboardInterrupt), \
                self.assertRaises(KeyboardInterrupt):
            research_kernel.run_sealed(self.root, self.path, out, self.root / "seal", allow_native=True)
        header = recipes.read_json(out / "run-header.json")
        request = recipes.read_json(out / "request.json")
        self.assertIsNone(header["clockEpoch"])
        self.assertFalse(header["executionCompleted"])
        self.assertNotIn("outcome", header)
        self.assertAlmostEqual(40, header["deadlineMonotonic"] - header["startedMonotonic"], places=9)
        self.assertEqual(header["request"], {key: value for key, value in request.items() if key != "journal"})
        self.assertFalse((out / "receipt.json").exists())
        retained = read_journal(self.root, request["journal"]["scope"])
        self.assertIsNone(retained["head"])
        self.assertEqual(1, len(retained["observations"]))
        body = retained["observations"][request["journal"]["observation"]]
        self.assertEqual({}, body["boundInputs"])
        self.assertEqual(header, json.loads(body["queries"]["run_record"][0]))

    def test_run_record_is_immutable_and_never_publishes_analysis(self):
        from gambit_smp.reasoning_history import read_journal
        path = self.root / "record.json"
        saved = research_kernel.retain_run_record(self.root, path, "unit-lineage", {"state": "STARTED"}, {})
        with self.assertRaises(FileExistsError):
            research_kernel.retain_run_record(self.root, path, "unit-lineage", {"state": "PASS"}, {})
        retained = read_journal(self.root, "unit-lineage")
        self.assertEqual(1, len(retained["observations"]))
        self.assertEqual({}, retained["results"])
        self.assertIsNone(retained["head"])
        self.assertEqual(saved["sha256"], recipes.digest(path))

    def test_unknown_boot_identity_is_not_fabricated(self):
        with patch.object(sys, "platform", "unknown-os"):
            self.assertIsNone(research_kernel.clock_epoch())

    def test_actual_process_exit_keeps_committed_transport_not_pass(self):
        from gambit_smp.reasoning_history import read_journal
        program = (
            "import os,sys; from pathlib import Path; "
            "from gambit_smp.research_kernel import retain_run_record; "
            "root=Path(sys.argv[1]); "
            "retain_run_record(root,root/'process-header.json','crashed-run',"
            "{'state':'STARTED','executionCompleted':False},{}); os._exit(7)"
        )
        environment = {**os.environ, "PYTHONPATH": str(Path(research_kernel.__file__).parent.parent)}
        result = subprocess.run([sys.executable, "-B", "-c", program, str(self.root)],
                                env=environment, capture_output=True, timeout=10)
        self.assertEqual(7, result.returncode, result.stderr.decode())
        retained = read_journal(self.root, "crashed-run")
        self.assertEqual(1, len(retained["observations"]))
        self.assertIsNone(retained["head"])
        self.assertEqual({}, retained["results"])
        self.assertFalse(recipes.read_json(self.root / "process-header.json")["executionCompleted"])


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
    def test_private_source_transfers_do_not_alias_or_chmod_originals(self):
        original = self.source.read_bytes()
        permissions = self.source.stat().st_mode & 0o777
        manifest = self.seal()
        target = self.root / "engine/provider-source/example.ss"
        self.assertFalse(manifest["privateFileTransfers"]["hardlinks"])
        self.assertGreater(sum(manifest["privateFileTransfers"][name] for name in ("copy-on-write", "byte-copy")), 0)
        self.assertNotEqual(self.source.stat().st_ino, target.stat().st_ino)
        self.assertEqual(permissions, self.source.stat().st_mode & 0o777)
        self.source.write_bytes(b"changed original source")
        self.assertEqual(original, target.read_bytes())

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True, capture_output=True)
        self.binding = self.root / "python/ascent"
        self.binding.mkdir(parents=True)
        (self.binding / "__init__.py").write_text("unit fixture, not an executable provider")
        (self.binding / "_core.abi3.so").write_bytes(b"unit fixture extension")
        self.extension_sha = sha(b"unit fixture extension")
        self.api = self.binding
        self.source_root = self.binding / "_sources"
        self.source_root.mkdir()
        self.source = self.source_root / "example.ss"
        self.source.write_bytes(b"exact provider source")
        resource = self.api / "syntax/gerbil-ascent/example.ssi"
        resource.parent.mkdir(parents=True)
        resource.write_bytes(b"unit fixture compiled module identity")
        self.receipt = self.root / "build-inputs.json"
        self.receipt.write_text(json.dumps({"schema": "ascent.rust-build.v1", "rayon": True,
            "sourceRoot": str(self.source_root),
            "sourceInputs": {"example.ss": sha(self.source.read_bytes())},
            "runtimeInputs": {str(resource): sha(resource.read_bytes())}}))

    def test_no_sdk_environment_is_required_or_recorded(self):
        with patch.dict(os.environ, {}, clear=True):
            manifest = self.seal()
            self.assertNotIn("runtimeEnvironment", manifest)
            self.assertEqual(dict(os.environ), {})

    def test_external_runtime_cannot_be_repaired_by_environment(self):
        external = self.root / "build-machine/module.ssi"
        external.parent.mkdir()
        external.write_bytes(b"external compiled module")
        receipt = json.loads(self.receipt.read_text())
        receipt["runtimeInputs"] = {str(external): sha(external.read_bytes())}
        self.receipt.write_text(json.dumps(receipt))
        with self.assertRaisesRegex(ValueError, "fix Library packaging"):
            self.seal()
        self.assertFalse((self.root / "engine").exists())

    def test_wheel_seal_preserves_package_layout_without_external_resources(self):
        receipt = json.loads(self.receipt.read_text())
        original = next(iter(receipt["runtimeInputs"]))
        resource = Path(original)
        relative = resource.relative_to(self.binding).as_posix()
        receipt["packageInputs"] = {
            relative: receipt["runtimeInputs"][original],
            "_sources/example.ss": receipt["sourceInputs"]["example.ss"]}
        receipt["runtimePackagePaths"] = {original: relative}
        self.receipt.write_text(json.dumps(receipt))
        manifest = self.seal()
        self.assertEqual(manifest["externalRuntimeInputs"], {})
        self.assertEqual(manifest["providerSources"]["schema"], "ascent.rust-wheel-archive.v1")
        resource.unlink()
        self.source.unlink()
        current = research_kernel.manifest_paths(self.root / "engine")
        self.assertEqual(current["engineId"], manifest["engineId"])
        self.assertEqual((self.root / "engine/python/ascent/_sources/example.ss").read_bytes(),
                         b"exact provider source")
        self.assertEqual((self.root / "engine/python/ascent" / relative).read_bytes(),
                         b"unit fixture compiled module identity")

    def test_wheel_runtime_mapping_uses_the_installed_inventory_keys(self):
        receipt = json.loads(self.receipt.read_text())
        installed = next(iter(receipt["runtimeInputs"]))
        relative = Path(installed).relative_to(self.binding).as_posix()
        receipt["packageInputs"] = {relative: receipt["runtimeInputs"][installed]}
        receipt["runtimePackagePaths"] = {"/old-build/module.ssi": relative}
        self.receipt.write_text(json.dumps(receipt))
        with self.assertRaisesRegex(ValueError, "inventory keys disagree"):
            self.seal()

    def test_one_installed_file_preserves_source_and_runtime_roles(self):
        original = self.source.read_bytes()
        self.source_root = self.binding / "_sources"
        self.source_root.mkdir(exist_ok=True)
        self.source = self.source_root / "example.ss"
        self.source.write_bytes(original)
        sha256 = sha(original)
        self.receipt.write_text(json.dumps({"schema": "ascent.rust-build.v1", "rayon": True,
            "sourceRoot": str(self.source_root), "sourceInputs": {"example.ss": sha256},
            "runtimeInputs": {str(self.source): sha256},
            "packageInputs": {"_sources/example.ss": sha256},
            "runtimePackagePaths": {str(self.source): "_sources/example.ss"}}))
        manifest = self.seal()
        for name in ("provider-source/example.ss", "python/ascent/_sources/example.ss"):
            self.assertEqual(manifest["files"][name], sha256)
            self.assertEqual((self.root / "engine" / name).read_bytes(), original)
        self.assertEqual(research_kernel.manifest_paths(self.root / "engine")["engineId"],
                         manifest["engineId"])

    def test_wheel_runtime_mapping_cannot_substitute_another_packaged_file(self):
        receipt = json.loads(self.receipt.read_text())
        installed = next(iter(receipt["runtimeInputs"]))
        receipt["packageInputs"] = {"_sources/example.ss": receipt["sourceInputs"]["example.ss"]}
        receipt["runtimePackagePaths"] = {installed: "_sources/example.ss"}
        self.receipt.write_text(json.dumps(receipt))
        with self.assertRaisesRegex(ValueError, "resource binding mismatch"):
            self.seal()

    def test_source_archive_survives_original_source_removal(self):
        from gambit_smp.ascent_program import build_sources
        original_receipt = self.receipt.read_bytes()
        manifest = self.seal()
        self.source.unlink()
        entries = build_sources(json.loads(original_receipt), sealed_engine=self.root / "engine")
        self.assertEqual(Path(entries["example.ss"]["path"]).read_bytes(), b"exact provider source")
        self.assertEqual(self.receipt.read_bytes(), original_receipt)
        self.assertIn("provider-source/example.ss", manifest["files"])

    def test_changed_build_source_is_rejected(self):
        self.source.write_bytes(b"different source")
        with self.assertRaisesRegex(ValueError, "source mismatch"):
            self.seal()

    def test_source_alias_is_rejected(self):
        target = self.root / "outside.ss"
        self.source.rename(target)
        self.source.symlink_to(target)
        with self.assertRaisesRegex(ValueError, "source alias"):
            self.seal()

    def test_linked_source_must_be_an_exact_build_input(self):
        from gambit_smp.ascent_program import build_sources
        manifest = self.seal()
        path = self.root / 'engine/ascent-build.json'
        receipt = json.loads(path.read_text())
        receipt['sourceInputs']['example.ss'] = '0' * 64
        path.chmod(0o644)
        path.write_text(json.dumps(receipt))
        manifest['files']['ascent-build.json'] = sha(path.read_bytes())
        manifest['engineId'] = research_kernel.content_id({k: v for k, v in manifest.items() if k != 'engineId'})
        identity = self.root / 'engine/engine.json'
        identity.chmod(0o644)
        identity.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "source/runtime inventory drift"):
            build_sources(json.loads(self.receipt.read_text()), sealed_engine=self.root / 'engine')

    def seal(self, *, probe_error=None, missing_provider=False, **kwargs):
        from gambit_smp import ascent_runtime
        import base64
        import importlib.metadata
        original_import = ascent_runtime.importlib.import_module
        def installed(name):
            if name not in ('ascent', 'ascent._core'):
                return original_import(name)
            if missing_provider:
                raise ModuleNotFoundError('no installed ASCENT provider; no fallback')
            return types.SimpleNamespace(__file__=str(self.binding / (
                '__init__.py' if name == 'ascent' else '_core.abi3.so')))
        extension = importlib.metadata.PackagePath('ascent/_core.abi3.so')
        extension.hash = importlib.metadata.FileHash('sha256=' + base64.urlsafe_b64encode(
            bytes.fromhex(self.extension_sha)).decode().rstrip('='))
        distribution = types.SimpleNamespace(files=[extension],
            locate_file=lambda path: self.root / 'python' / path)
        with patch('ascent.build.runtime_identity', side_effect=lambda: json.loads(self.receipt.read_text())), \
                patch.object(ascent_runtime.importlib, 'import_module', side_effect=installed), \
                patch.object(ascent_runtime.importlib.metadata, 'distribution', return_value=distribution), \
                patch("gambit_smp.provider_contract.inspect_provider", side_effect=probe_error,
                      return_value={"status": "unit-fixture"}):
            return research_kernel.seal(self.root / "engine", gcc=Path(__file__), ascent_api=self.api, **kwargs)

    def test_reseal_can_reuse_exact_checked_provider_sources(self):
        self.seal()
        archive = self.root / "retained"
        (self.root / "engine").rename(archive)
        self.source.write_bytes(b"new workspace version")
        receipt = self.receipt.read_bytes()
        self.seal(provider_sources=archive)
        self.assertEqual((self.root / "engine/provider-source/example.ss").read_bytes(),
                         b"exact provider source")
        self.assertEqual(self.receipt.read_bytes(), receipt)
        self.assertEqual(self.source.read_bytes(), b"new workspace version")

    def test_reseal_rejects_archive_tampering(self):
        self.seal()
        archive = self.root / "retained"
        (self.root / "engine").rename(archive)
        (archive / "provider-source/example.ss").chmod(0o644)
        (archive / "provider-source/example.ss").write_bytes(b"tampered")
        self.source.write_bytes(b"new workspace version")
        with self.assertRaises(ValueError):
            self.seal(provider_sources=archive)

    def test_seal_is_immutable_and_binds_inventory(self):
        manifest = self.seal()
        self.assertEqual(manifest["engineId"], research_kernel.manifest_paths(self.root / "engine")["engineId"])
        actual = research_kernel.sealed_inventory(self.root / "engine")
        self.assertEqual(manifest["files"], {name: sha for name, sha in actual.items() if name != "engine.json"})
        with self.assertRaisesRegex(ValueError, "fresh directory"):
            self.seal()

    def generation(self):
        resource = self.api / "syntax/example/module~1.o1"
        resource.parent.mkdir(parents=True)
        resource.write_bytes(b"compiled generation fixture")
        resource.chmod(0o644)
        receipt = json.loads(self.receipt.read_text())
        receipt["runtimeInputs"][str(resource)] = sha(resource.read_bytes())
        self.receipt.write_text(json.dumps(receipt))
        return resource

    def generation_target(self, source):
        mapping = json.loads((self.root / 'engine/ascent-runtime.json').read_text())
        return self.root / 'engine' / mapping[str(source)]

    def test_shared_generation_does_not_chmod_source_and_rejects_alias_mutation(self):
        source = self.generation()
        manifest = self.seal()
        target = self.generation_target(source)
        self.assertEqual(source.stat().st_ino, target.stat().st_ino)
        self.assertEqual(0o644, source.stat().st_mode & 0o777)
        self.assertEqual("linked-generation", manifest["resourceOwnership"]["generations"][
            target.relative_to(self.root / 'engine').as_posix()]["mode"])
        source.write_bytes(b"aliased mutation")
        with self.assertRaisesRegex(ValueError, "implementation drift"):
            research_kernel.manifest_paths(self.root / "engine")

    def test_unlink_and_replace_source_name_preserves_published_generation(self):
        source = self.generation()
        self.seal()
        original = source.read_bytes()
        source.unlink()
        source.write_bytes(b"new generation at former source name")
        target = self.generation_target(source)
        self.assertEqual(original, target.read_bytes())
        with self.assertRaisesRegex(ValueError, 'runtime resource drift'):
            research_kernel.manifest_paths(self.root / "engine")

    def test_cross_device_copy_has_independent_permissions_and_bytes(self):
        import errno
        source = self.generation()
        with patch("gambit_smp.artifact_storage.os.link", side_effect=OSError(errno.EXDEV, "cross device")):
            manifest = self.seal()
        target = self.generation_target(source)
        self.assertNotEqual(source.stat().st_ino, target.stat().st_ino)
        self.assertEqual(0o644, source.stat().st_mode & 0o777)
        self.assertEqual(0o444, target.stat().st_mode & 0o777)
        self.assertEqual("copied", manifest["resourceOwnership"]["generations"][
            target.relative_to(self.root / 'engine').as_posix()]["mode"])
        source.write_bytes(b"independent source mutation")
        with self.assertRaisesRegex(ValueError, 'runtime resource drift'):
            research_kernel.manifest_paths(self.root / "engine")

    def test_portable_seal_survives_archive_transfer_without_inode_authority(self):
        source = self.generation()
        manifest = self.seal(portable=True)
        target = self.generation_target(source)
        self.assertNotEqual(source.stat().st_ino, target.stat().st_ino)
        self.assertEqual("copied", manifest["resourceOwnership"]["generations"][
            target.relative_to(self.root / "engine").as_posix()]["mode"])
        archive = self.root / "engine.tar"
        with tarfile.open(archive, "w") as tree:
            tree.add(self.root / "engine", arcname="engine")
        with tempfile.TemporaryDirectory() as temporary:
            with tarfile.open(archive) as tree:
                tree.extractall(temporary, filter="data")
            restored = research_kernel.manifest_paths(Path(temporary) / "engine")
            self.assertEqual(manifest["engineId"], restored["engineId"])
            self.assertEqual(manifest["files"], restored["files"])

    def test_unknown_link_io_error_is_not_silently_copied(self):
        import errno
        self.generation()
        with patch("gambit_smp.artifact_storage.os.link", side_effect=OSError(errno.EIO, "IO failure")):
            with self.assertRaises(OSError):
                self.seal()

    def test_generation_ownership_inventory_cannot_be_omitted(self):
        self.generation()
        manifest = self.seal()
        manifest["resourceOwnership"]["generations"] = {}
        identity = {k: v for k, v in manifest.items() if k != "engineId"}
        manifest["engineId"] = research_kernel.content_id(identity)
        path = self.root / "engine/engine.json"
        path.chmod(0o644)
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "ownership inventory drift"):
            research_kernel.manifest_paths(self.root / "engine")

    def test_historical_v1_manifest_is_not_an_executable_current_seal(self):
        manifest = self.seal()
        manifest["schema"] = "research-engine-seal.v1"
        del manifest["resourceOwnership"]
        identity = {k: v for k, v in manifest.items() if k != "engineId"}
        manifest["engineId"] = research_kernel.content_id(identity)
        path = self.root / "engine/engine.json"
        path.chmod(0o644)
        path.write_text(json.dumps(manifest))
        before = path.read_bytes()
        with self.assertRaisesRegex(ValueError, "sealed research engine required"):
            research_kernel.manifest_paths(self.root / "engine")
        self.assertEqual(before, path.read_bytes())

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

    def test_inventory_open_rejects_a_file_replaced_by_a_link_after_scan(self):
        self.seal()
        engine = self.root / "engine"
        engine.chmod(0o755)
        target = engine / "runner.py"
        external = self.root / "same-bytes.py"
        external.write_bytes(target.read_bytes())
        original_open = research_kernel.os.open
        def raced_open(path, flags, **kwargs):
            if path == "runner.py" and "dir_fd" in kwargs:
                target.unlink()
                target.symlink_to(external)
            return original_open(path, flags, **kwargs)
        with patch.object(research_kernel.os, "open", side_effect=raced_open):
            with self.assertRaises(OSError):
                research_kernel.sealed_inventory(engine)

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
        (self.binding / '_core.abi3.so').write_bytes(b"drift")
        with self.assertRaisesRegex(ValueError, "RECORD"):
            self.seal()

    def test_legacy_extension_receipt_is_not_a_compatible_abi(self):
        receipt = json.loads(self.receipt.read_text())
        receipt['schema'] = 'ascent.cffi-api-build.v1'
        self.receipt.write_text(json.dumps(receipt))
        with self.assertRaisesRegex(ValueError, 'Rust ASCENT'):
            self.seal()

    def test_seal_rejects_directory_links_even_with_identical_inventory(self):
        self.seal()
        engine = self.root / "engine"
        engine.chmod(0o755)
        external = self.root / "empty-directory"
        external.mkdir()
        (engine / "unlisted-directory").symlink_to(external, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "implementation drift"):
            research_kernel.manifest_paths(engine)

    def test_provider_mismatch_is_rejected_before_seal_directory_creation(self):
        with self.assertRaisesRegex(ValueError, "provider mismatch"):
            self.seal(probe_error=ValueError('provider mismatch'))
        self.assertFalse((self.root / "engine").exists())

    def test_missing_native_rule_provider_fails_closed(self):
        with self.assertRaisesRegex(ModuleNotFoundError, "no fallback"):
            self.seal(missing_provider=True)

    def test_static_import_closure_cannot_reach_a_historical_producer(self):
        package = self.root / "package"
        package.mkdir()
        for name in ("__init__", "research_kernel", "recipes", "native_capabilities", "source_capabilities",
                     "evidence_capabilities", "process_observation", "ascent_program", "validation_domains"):
            (package / (name + ".py")).write_text("")
        (package / "recipes.py").write_text("from gambit_smp.source_unit import prepare\n")
        with self.assertRaisesRegex(ValueError, "historical producer reachable"):
            research_kernel.implementation_paths(package)

    def test_dependency_projection_uses_source_bytes_not_file_metadata(self):
        import os
        package = self.root / 'package'
        package.mkdir()
        for name in ('__init__', 'research_kernel', 'recipes', 'native_capabilities',
                     'source_capabilities', 'evidence_capabilities', 'process_observation',
                     'ascent_program', 'validation_domains'):
            (package / (name + '.py')).write_text('')
        source = package / 'recipes.py'
        source.write_text('from gambit_smp import framework\n')
        (package / 'framework.py').write_text('')
        before = source.stat()
        first = research_kernel.implementation_paths(package)
        self.assertIn(package / 'framework.py', first)
        self.assertEqual(first, research_kernel.implementation_paths(package))
        source.write_text('from gambit_smp import source_unit\n')
        os.utime(source, ns=(before.st_atime_ns, before.st_mtime_ns))
        with self.assertRaisesRegex(ValueError, 'historical producer reachable'):
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
            subprocess.run(["git", "init", "-q", str(root)], check=True, capture_output=True)
            context = recipes.ExecutionContext(root, root, root, {}, time.monotonic() + 5, {}, {"engine": {}}, {})
            text = context.require("identity", [sys.executable, "-c",
                "import sys; print('identity'); print('warning', file=sys.stderr)"], root, 5)
            self.assertEqual("identity\n", text)
            self.assertEqual("warning\n", (root / "identity.stderr").read_text())
            self.assertEqual(sha(b"warning\n"), context.commands[0]["stderrSha256"])


if __name__ == "__main__":
    unittest.main()
