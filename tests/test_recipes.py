import copy
import json
import os
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp import recipes


class FingerprintPlanTests(unittest.TestCase):
    def test_same_size_same_timestamp_change_is_not_cached(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / "source"
            file.write_bytes(b"before")
            plan = recipes.FingerprintPlan(recipes.fingerprints([file, file]))
            self.assertTrue(plan.matches())
            timestamp = file.stat()
            file.write_bytes(b"after!")
            os.utime(file, ns=(timestamp.st_atime_ns, timestamp.st_mtime_ns))
            self.assertFalse(plan.matches())
            file.write_bytes(b"before")
            self.assertTrue(plan.matches())
            file.unlink()
            with self.assertRaises(FileNotFoundError):
                plan.matches()

    def test_mismatch_reads_all_paths_and_snapshots_expected_identity(self):
        expected = {"a": "old", "b": "same"}
        plan = recipes.FingerprintPlan(expected)
        expected["a"] = "new"
        with patch.object(recipes, "digest", side_effect=["new", "same"]) as digest:
            self.assertFalse(plan.matches())
            self.assertEqual([((Path("a"),), {}), ((Path("b"),), {})], digest.call_args_list)


class ProcessCheckpointTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.ctx = recipes.ExecutionContext(self.root, self.root, self.root, {},
            time.monotonic() + 5, {}, {}, {})

    def test_observation_survives_without_final_recipe_receipt(self):
        with patch.object(recipes, "execute", return_value=(70, "compiler failure", False, 0.1)):
            self.ctx.run("compile", ["gcc"], self.root, 2)
        record = recipes.read_json(self.root / "compile.process.json")
        self.assertEqual("OBSERVED", record["state"])
        self.assertEqual(70, record["exit"])
        self.assertFalse(record["timeout"])
        self.assertFalse(record["runtimeAdmitted"])
        self.assertEqual(recipes.digest(self.root / "compile.log"), record["logSha256"])
        self.assertFalse((self.root / "receipt.json").exists())

    def test_interruption_does_not_fabricate_completion_or_allow_overwrite(self):
        with patch.object(recipes, "execute", side_effect=KeyboardInterrupt), self.assertRaises(KeyboardInterrupt):
            self.ctx.run("compile", ["gcc"], self.root, 2)
        record = recipes.read_json(self.root / "compile.process.json")
        self.assertEqual("STARTED", record["state"])
        self.assertFalse(record["completionObserved"])
        self.assertNotIn("exit", record)
        self.assertEqual([], self.ctx.commands)
        with patch.object(recipes, "execute") as launched, self.assertRaises(ValueError):
            self.ctx.run("compile", ["gcc"], self.root, 2)
        launched.assert_not_called()

    def test_timeout_observation_remains_timeout(self):
        with patch.object(recipes, "execute", return_value=(-9, "", True, 2)):
            self.ctx.run("compile", ["gcc"], self.root, 2)
        record = recipes.read_json(self.root / "compile.process.json")
        self.assertTrue(record["timeout"])
        self.assertEqual(-9, record["exit"])
        self.assertLessEqual(record["effectiveBudgetSeconds"], 2)


class QuintImportedInventoryTests(unittest.TestCase):
    def test_qualified_names_remain_strict_identifiers(self):
        args = {"source": "model.qnt", "parsed": "parse", "main": "main", "seed": "0x1",
                "maxSamples": 1, "expectedTests": ["A::B::baseTest"]}
        recipes.validate_test(args, ["model.qnt"])
        for name in ("A::::baseTest", "::baseTest", "A::baseTest;exit", "A/baseTest"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                recipes.validate_test(dict(args, expectedTests=[name]), ["model.qnt"])

    def fixture(self, declaration):
        return {"modules": [
            {"name": "base", "declarations": [{"qualifier": "run", "name": "baseTest"}]},
            {"name": "main", "declarations": [declaration, {"qualifier": "run", "name": "ownTest"}]}]}

    def test_alias_wildcard_named_and_instance_imports(self):
        for declaration, expected in (
                ({"kind": "import", "protoName": "base", "qualifiedName": "B"}, ["B::baseTest", "ownTest"]),
                ({"kind": "import", "protoName": "base", "defName": "*"}, ["baseTest", "ownTest"]),
                ({"kind": "import", "protoName": "base", "defName": "baseTest"}, ["baseTest", "ownTest"]),
                ({"kind": "import", "protoName": "base", "defName": "nonTest"}, ["ownTest"]),
                ({"kind": "instance", "protoName": "base", "qualifiedName": "B"}, ["B::baseTest", "ownTest"])):
            with self.subTest(declaration=declaration):
                self.assertEqual(expected, recipes.quint_test_inventory(self.fixture(declaration), "main"))

    def test_missing_and_cyclic_imports_fail_closed(self):
        for name in ("absent", "main"):
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, "cyclic or missing"):
                recipes.quint_test_inventory(self.fixture({"kind": "import", "protoName": name}), "main")

    def test_nested_aliases_preserve_names(self):
        ir = self.fixture({"kind": "import", "protoName": "middle", "qualifiedName": "M"})
        ir["modules"].append({"name": "middle", "declarations": [
            {"kind": "import", "protoName": "base", "qualifiedName": "B"}]})
        self.assertEqual(["M::B::baseTest", "ownTest"], recipes.quint_test_inventory(ir, "main"))


class RecipeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "models").mkdir()
        (self.root / "models/control.qnt").write_text("module control { run controlTest = true }")
        (self.root / "evidence").mkdir()
        self.path = self.root / "evidence/control.recipe.json"
        self.recipe = {"schema": recipes.SCHEMA, "id": "control", "scope": "local unit controls only",
                       "budgetSeconds": 30, "inputs": ["models/control.qnt"], "steps": [
            {"id": "parse", "capability": "quint.parse", "dependsOn": [],
             "arguments": {"source": "models/control.qnt"}, "budgetSeconds": 10},
            {"id": "test", "capability": "quint.test", "dependsOn": ["parse"],
             "arguments": {"source": "models/control.qnt", "parsed": "parse", "main": "control",
                           "seed": "0x1", "maxSamples": 1, "expectedTests": ["controlTest"]}, "budgetSeconds": 10}]}
        self.save()
        self.node = self.root / "node"
        self.quint = self.root / "quint"
        self.node.write_text("unit-test runtime")
        self.quint.write_text("unit-test tool")

    def save(self):
        self.path.write_text(json.dumps(self.recipe))

    def simulated_execute(self, argv, root, timeout, **kwargs):
        kwargs.get('metadata', {}).update(parentReaped=True, processGroupQuiescent=True)
        output = Path(argv[argv.index("--out") + 1])
        if "parse" in argv:
            result = {"stage": "parsing", "errors": [], "modules": [{"name": "control", "declarations": [
                {"name": "controlTest", "qualifier": "run"}]}]}
            sources = Path(argv[argv.index("--source-map") + 1])
            sources.write_text(json.dumps({"sourceIndex": {"0": str(self.root / "models/control.qnt")}}))
        else:
            result = {"stage": "testing", "errors": [], "passed": ["controlTest"], "failed": [], "ignored": []}
        output.write_text(json.dumps(result))
        return 0, "unit-test executor only\n", False, 0.1

    def test_quint_commands_publish_the_shared_completion_observation(self):
        receipt = self.run_simulated('quint-observations')
        self.assertEqual('PASS', receipt['outcome'])
        for name in ('parse', 'test'):
            row = recipes.read_json(self.root / 'quint-observations' / name / 'raw.process.json')
            self.assertEqual('OBSERVED', row['state'])
            self.assertTrue(row['completionObserved'])
            self.assertTrue(row['parentReaped'])
            self.assertTrue(row['processGroupQuiescent'])
            self.assertFalse(row['runtimeAdmitted'])
        self.assertTrue(all(len(step['commands']) == 1 for step in receipt['steps']))

    def run_simulated(self, name, side_effect=None, prior=None):
        with patch.object(recipes, "tool_files", return_value=[self.node, self.quint]), \
                patch.object(recipes, "execute", side_effect=side_effect or self.simulated_execute):
            return recipes.run(self.root, self.path, self.root / name, self.quint, self.node, prior)

    def test_discovery_accepts_new_recipes_without_python_registration(self):
        alternate = copy.deepcopy(self.recipe)
        alternate["id"] = "independent-control"
        (self.root / "evidence/another.recipe.json").write_text(json.dumps(alternate))
        self.assertEqual({"control", "independent-control"}, set(recipes.discover(self.root)))

    def test_stage_watchdogs_start_fresh_after_previous_stage_work(self):
        self.recipe.pop("budgetSeconds")
        self.recipe["timeoutPolicy"] = {"mode": "per-stage", "overheadSeconds": 2}
        self.save()
        now, caps = [100.0], []

        def execute(argv, root, timeout, **kwargs):
            caps.append(timeout)
            now[0] += 7
            return self.simulated_execute(argv, root, timeout, **kwargs)

        with patch.object(recipes.time, "monotonic", side_effect=lambda: now[0]):
            receipt = self.run_simulated("stage-timers", execute)
        self.assertEqual([10, 10], caps)
        self.assertEqual("PASS", receipt["outcome"])
        self.assertEqual(14, receipt["wholeSeconds"])
        self.assertEqual(22, receipt["budgetSeconds"])
        self.assertEqual("per-stage", receipt["timeoutPolicy"]["mode"])

    def test_stage_policy_rejects_mixed_quota_and_invalid_watchdogs(self):
        original = copy.deepcopy(self.recipe)
        for change in ({"budgetSeconds": 30}, {"continuationRequest": "evidence/request.json"},
                       {"continuationLedger": "evidence/ledger.json"},
                       {"timeoutPolicy": {"mode": "per-stage", "overheadSeconds": 0}},
                       {"timeoutPolicy": {"mode": "unknown", "overheadSeconds": 2}}):
            with self.subTest(change=change):
                self.recipe = copy.deepcopy(original)
                self.recipe.pop("budgetSeconds")
                self.recipe["timeoutPolicy"] = {"mode": "per-stage", "overheadSeconds": 2}
                self.recipe.update(change)
                self.save()
                with self.assertRaises(ValueError):
                    recipes.load(self.root, self.path)

    def test_authorization_preflight_preserves_absent_tool_observation(self):
        prior = {"outcome": "DENY", "steps": [], "error": recipes.AUTHORIZATION_ERROR}
        self.assertIsNone(recipes.prior_tool_observation(self.root, prior))
        self.assertTrue(recipes.authorization_repair(prior, True, self.node))
        self.assertFalse(recipes.authorization_repair(prior, False, self.node))
        self.assertFalse(recipes.authorization_repair(prior, True, None))
        self.assertFalse(recipes.authorization_repair(prior, 1, self.node))
        for mutation in ({"steps": [{"outcome": "DENY"}]}, {"error": "compiler failed"},
                         {"outcome": "PASS"}, {"outcome": "STALE"}):
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                recipes.prior_tool_observation(self.root, {**prior, **mutation})
        self.assertNotIn("toolInputs", prior)

    def test_prior_tool_manifest_tampering_is_denied(self):
        path = self.root / "tools.json"
        path.write_text("{}")
        prior = {"toolInputs": {"path": "tools.json", "sha256": recipes.digest(path)}}
        self.assertEqual({}, recipes.prior_tool_observation(self.root, prior))
        path.write_text('{"forged":"observation"}')
        with self.assertRaisesRegex(ValueError, "changed"):
            recipes.prior_tool_observation(self.root, prior)

    def test_duplicate_json_and_discovered_ids_are_rejected(self):
        self.path.write_text('{"schema":"x","schema":"y"}')
        with self.assertRaisesRegex(ValueError, "duplicate JSON"):
            recipes.discover(self.root)
        self.save()
        (self.root / "evidence/duplicate.recipe.json").write_text(self.path.read_text())
        with self.assertRaisesRegex(ValueError, "duplicate discovered"):
            recipes.discover(self.root)

    def test_scripts_unknown_capabilities_and_extra_fields_are_rejected(self):
        for field in ("argv", "shell", "python", "module"):
            self.recipe["steps"][0][field] = "arbitrary executable"
            self.save()
            with self.subTest(field=field), self.assertRaises(ValueError):
                recipes.load(self.root, self.path)
            del self.recipe["steps"][0][field]
        self.recipe["steps"][0]["capability"] = "research-feature-specific-runner"
        self.save()
        with self.assertRaisesRegex(ValueError, "unknown capability"):
            recipes.load(self.root, self.path)

    def test_graph_cycles_unknown_edges_and_mismatched_parse_are_rejected(self):
        original = copy.deepcopy(self.recipe)
        for change in (lambda: self.recipe["steps"][0].update(dependsOn=["test"]),
                       lambda: self.recipe["steps"][1].update(dependsOn=["unknown"]),
                       lambda: self.recipe["steps"][1]["arguments"].update(parsed="unknown")):
            self.recipe = copy.deepcopy(original)
            change()
            self.save()
            with self.assertRaises(ValueError):
                recipes.load(self.root, self.path)

    def test_cache_alias_and_traversal_inputs_are_rejected(self):
        (self.root / ".data").mkdir()
        (self.root / ".data/control.qnt").write_text("cached")
        (self.root / "models/alias.qnt").symlink_to(self.root / ".data/control.qnt")
        for name in ("models/alias.qnt", ".data/control.qnt", "../escaped.qnt"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                recipes.source_path(self.root, name)

    def test_boolean_nonfinite_and_expanded_budgets_are_rejected(self):
        for value in (True, 0, -1, float("inf"), 601):
            with self.subTest(value=value), self.assertRaises(ValueError):
                recipes.budget(value)

    def test_structured_inventory_and_parent_exit_are_both_required(self):
        for label, effect in (("exit", lambda argv, root, timeout, **kwargs: (7, "failed", False, 0.1)),
                              ("timeout", lambda argv, root, timeout, **kwargs: (0, "timeout", True, 0.1))):
            receipt = self.run_simulated(label, effect)
            self.assertEqual("DENY", receipt["outcome"])
            self.assertEqual("BLOCKED", receipt["steps"][1]["outcome"])
        def incomplete(argv, root, timeout, **kwargs):
            response = self.simulated_execute(argv, root, timeout, **kwargs)
            if "test" in argv:
                output = Path(argv[argv.index("--out") + 1])
                result = json.loads(output.read_text())
                result["passed"] = []
                output.write_text(json.dumps(result))
            return response
        receipt = self.run_simulated("missing-inventory", incomplete)
        self.assertEqual("DENY", receipt["outcome"])

    def test_undeclared_import_denies_dependents(self):
        def imported(argv, root, timeout, **kwargs):
            response = self.simulated_execute(argv, root, timeout, **kwargs)
            if "parse" in argv:
                sources = Path(argv[argv.index("--source-map") + 1])
                (self.root / "models/other.qnt").write_text("other")
                sources.write_text(json.dumps({"sourceIndex": {"0": str(self.root / "models/other.qnt")}}))
            return response
        receipt = self.run_simulated("undeclared-import", imported)
        self.assertEqual("DENY", receipt["steps"][0]["outcome"])
        self.assertEqual("BLOCKED", receipt["steps"][1]["outcome"])

    def test_rechecked_observation_is_stale_after_source_tool_or_artifact_drift(self):
        self.assertEqual("PASS", self.run_simulated("bound")["outcome"])
        out = self.root / "bound"
        self.assertEqual("CURRENT", recipes.inspect_run(out)["identityStatus"])
        for path in (self.root / "models/control.qnt", self.node, out / "test/raw.log"):
            original = path.read_bytes()
            path.write_bytes(original + b"changed")
            self.assertEqual("STALE", recipes.inspect_run(out)["identityStatus"])
            path.write_bytes(original)
        with self.assertRaises(FileExistsError):
            self.run_simulated("bound")

    def test_drift_during_execution_prevents_a_pass(self):
        def changed(argv, root, timeout, **kwargs):
            response = self.simulated_execute(argv, root, timeout, **kwargs)
            (self.root / "models/control.qnt").write_text("changed")
            return response
        self.assertEqual("STALE", self.run_simulated("drift", changed)["outcome"])

    def test_prior_unchanged_failure_and_budget_expansion_are_denied(self):
        self.run_simulated("failed", lambda argv, root, timeout, **kwargs: (1, "failed", False, 0.1))
        receipt = self.run_simulated("unchanged", prior=self.root / "failed")
        self.assertEqual("DENY", receipt["outcome"])
        self.assertIn("unchanged failed", receipt["error"])
        self.recipe["budgetSeconds"] = 31
        self.save()
        receipt = self.run_simulated("expanded", prior=self.root / "failed")
        self.assertIn("expanding a budget", receipt["error"])


if __name__ == "__main__":
    unittest.main()
