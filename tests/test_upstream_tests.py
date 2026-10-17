"""Make process/scope contracts, not Gambit native acceptance."""
import json
import os
from pathlib import Path
import shutil
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp.framework import ROOT, digest
from gambit_smp import native_capabilities, recipes
from gambit_smp.native_review import make_operation_scope, selected_scope
from gambit_smp.process_observation import capture
from gambit_smp.upstream_tests import execute, validate, scope_contract, POLICIES, CONTRACT


class Context:
    def __init__(self, root, budget=3):
        self.root, self.directory = root, root / "output"
        self.directory.mkdir()
        self.tools, self.env = {"make": Path("/usr/bin/make")}, dict(os.environ)
        self.commands = []
        self.receipt = {"engine": {"path": "synthetic-contract-only"}, "budgetSeconds": budget,
                        "steps": [{"id": "output", "budgetSeconds": budget}]}
        self.deadline = time.monotonic() + budget
    def artifact(self, ref, kind):
        return self.root / ("identity.json" if kind == "runtime-identity" else "runtime")
    def bind(self, paths):
        pass
    def remaining(self):
        return max(0.001, self.deadline - time.monotonic())
    def publish(self, name, kind, path):
        return {name: {"type": kind, "path": str(path)}}
    def run(self, name, argv, cwd, cap):
        result = capture([str(arg) for arg in argv], cwd, min(cap, self.remaining()), self.env)
        self.commands.append({"stage": name, "argv": list(map(str, argv)),
            "exit": result.exit, "timeout": result.timeout,
            "parentReaped": True, "processGroupQuiescent": result.group_quiescent})
        return result.exit, result.stdout + result.stderr, result.timeout, result.seconds


class UpstreamTestContracts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "runtime/tests").mkdir(parents=True)
        (self.root / "identity.json").write_text("{}")
        self.args = {"runtime": {"step": "runtime", "output": "runtime"},
            "identity": {"step": "runtime", "output": "identity"}, "targets": ["test1", "test5"],
            "failures": "evidence/native-failures.json", "reviewRules": "evidence/rules.ss"}
        self.contract = {"targets": {name: {"executable": True, "dependencies": [], "unitSelections": []}
                                     for name in self.args["targets"]},
                         "unitModes": {"test1": ["gsi"], "test5": ["gsc"]}}
        for target, replacement in (("gambit_smp.native_capabilities.clone", self.root / "runtime"),
                                    ("gambit_smp.native_capabilities.compiler", Path("/usr/bin/cc")),
                                    ("gambit_smp.suite_primitives.check_runtime", None),
                                    ("gambit_smp.native_review.preflight", {"decision": "NOT_REQUIRED"}),
                                    ("gambit_smp.evidence_capabilities.evaluate_observations",
                                     {"scope": [["test1"], ["test5"]], "selection": [],
                                      "mode": [["gsi"], ["gsc"]], "cycle": []})):
            manager = patch(target, return_value=replacement)
            self.addCleanup(manager.stop)
            handle = manager.start()
            if target.endswith("preflight"):
                self.preflight = handle
        manager = patch("gambit_smp.upstream_tests.scope_contract",
                        return_value=(self.contract, self.root / "runtime/tests/makefile"))
        self.addCleanup(manager.stop)
        self.contract_mock = manager.start()

    def makefile(self, body):
        (self.root / "runtime/tests/makefile").write_text(body)

    def observations(self, ctx):
        return json.loads((ctx.directory / "upstream-observations.json").read_text())

    def test_literal_operands_and_complete_policy_inventory_required(self):
        inputs = [self.args["failures"], self.args["reviewRules"], *POLICIES]
        validate(self.args, inputs)
        for targets in (["-j8"], ["test1", "test1"], ["../escape"], []):
            with self.subTest(targets=targets), self.assertRaises(ValueError):
                validate({**self.args, "targets": targets}, inputs)
        with self.assertRaises(ValueError):
            validate({**self.args, "failures": "empty.json"}, [*inputs, "empty.json"])
        with self.assertRaises(ValueError):
            validate(self.args, [self.args["failures"], self.args["reviewRules"]])
        with self.assertRaises(ValueError):
            validate({**self.args, "reviews": {"gsi": {"step": "old-review", "output": "wrong"},
                                                "gsc": {"step": "another-review"}}}, inputs)
        validate({**self.args, "reviews": {"gsi": {"step": "review-gsi", "output": "review"}}}, inputs)

    def test_multiple_targets_use_one_real_make_and_one_scoped_review_per_mode(self):
        self.makefile("test1:\n\t@echo interpreter-transport-control\ntest5:\n\t@echo compiler-transport-control\n")
        ctx = Context(self.root)
        result = execute(self.args, ctx)
        self.assertEqual(["test1", "test5"], result["targets"])
        self.assertEqual(1, len(ctx.commands))
        self.assertEqual(["/usr/bin/make", "test1", "test5"], ctx.commands[0]["argv"])
        self.assertEqual(["retry-review-gsi", "retry-review-gsc"],
                         [call.kwargs["label"] for call in self.preflight.call_args_list])
        for call in self.preflight.call_args_list:
            self.assertEqual("upstream-make", call.args[1]["regime"])
            self.assertEqual(["test1", "test5"], call.args[1]["operations"])
        self.assertEqual(3, self.observations(ctx)["wholeUpstreamTestBudget"])

    def test_review_documents_are_not_mixed_between_modes(self):
        self.makefile("test1:\n\t@echo one\ntest5:\n\t@echo five\n")
        ctx = Context(self.root)
        execute({**self.args, "reviews": {"gsi": "evidence/gsi.json", "gsc": "evidence/gsc.json"}}, ctx)
        self.assertEqual(["evidence/gsi.json", "evidence/gsc.json"],
                         [call.args[1]["retryReview"] for call in self.preflight.call_args_list])

    def test_bound_reviews_are_kept_per_mode(self):
        self.makefile("test1:\n\t@echo one\ntest5:\n\t@echo five\n")
        ctx = Context(self.root)
        reviews = {mode: {"step": "review-" + mode, "output": "review"}
                   for mode in ("gsi", "gsc")}
        execute({**self.args, "reviews": reviews}, ctx)
        self.assertEqual([reviews["gsi"], reviews["gsc"]],
                         [call.args[1]["retryReview"] for call in self.preflight.call_args_list])

    def test_bound_review_graph_rejects_cross_mode_or_missing_dependency(self):
        source = {"id": "runtime", "capability": "gambit.runtime-import", "arguments": {},
                  "dependsOn": []}
        runtime = {"step": "runtime", "output": "runtime"}
        identity = {"step": "runtime", "output": "identity"}
        reviews = {}
        steps = [source]
        for mode in ("gsi", "gsc"):
            name = "review-" + mode
            steps.append({"id": name, "capability": "gambit.review", "dependsOn": ["runtime"],
                          "arguments": {"runtime": runtime, "identity": identity,
                                        "target": "official", "mode": mode}})
            reviews[mode] = {"step": name, "output": "review"}
        official = {"id": "official", "capability": "gambit.upstream-tests",
                    "dependsOn": ["runtime", "review-gsi", "review-gsc"],
                    "arguments": {"runtime": runtime, "identity": identity, "reviews": reviews}}
        steps.append(official)
        by_id = {step["id"]: step for step in steps}
        for step in steps[1:]:
            native_capabilities.graph(step, by_id, recipes.CAPABILITIES)
        official["arguments"]["reviews"] = {"gsi": reviews["gsc"], "gsc": reviews["gsi"]}
        with self.assertRaises(ValueError):
            native_capabilities.graph(official, by_id, recipes.CAPABILITIES)
        official["arguments"]["reviews"] = reviews
        official["dependsOn"].remove("review-gsi")
        with self.assertRaises(ValueError):
            native_capabilities.graph(official, by_id, recipes.CAPABILITIES)

    def test_denied_review_is_not_a_started_or_successful_test(self):
        self.makefile("test1:\n\t@echo forbidden\ntest5:\n\t@echo forbidden\n")
        self.preflight.return_value = {"decision": "REVIEW_REQUIRED"}
        ctx = Context(self.root)
        with self.assertRaisesRegex(ValueError, "REVIEW_REQUIRED"):
            execute(self.args, ctx)
        self.assertEqual([], ctx.commands)
        self.assertIs(self.observations(ctx)["executionStarted"], False)
        self.assertEqual("DENY", self.observations(ctx)["outcome"])

    def test_actual_nonzero_exit_is_not_an_invented_per_target_completion(self):
        self.makefile("test1:\n\t@exit 7\ntest5:\n\t@echo not-reached\n")
        ctx = Context(self.root)
        with self.assertRaisesRegex(ValueError, "exit/timeout/teardown"):
            execute(self.args, ctx)
        result = self.observations(ctx)
        self.assertEqual(2, result["exit"])
        self.assertIs(result["timeout"], False)
        self.assertEqual(["test1", "test5"], result["requested"])
        self.assertEqual("DENY", result["outcome"])

    def test_timeout_keeps_actual_teardown_observation(self):
        self.makefile("test1:\n\t@sleep 3\ntest5:\n\t@echo not-reached\n")
        ctx = Context(self.root, budget=0.1)
        with self.assertRaises(ValueError):
            execute(self.args, ctx)
        row = self.observations(ctx)
        self.assertIs(row["timeout"], True)
        self.assertEqual(-9, row["exit"])
        self.assertEqual(ctx.commands[-1]["processGroupQuiescent"], row["processGroupQuiescent"])

    def test_undeclared_target_and_shadowing_file_never_launch_make(self):
        self.makefile("test1:\n\t@echo one\ntest5:\n\t@echo five\n")
        ctx = Context(self.root)
        with self.assertRaisesRegex(ValueError, "not declared executable"):
            execute({**self.args, "targets": ["all"]}, ctx)
        (self.root / "runtime/tests/test1").write_text("could hide a non-phony test")
        with self.assertRaisesRegex(ValueError, "shadowed"):
            execute(self.args, ctx)
        self.assertEqual([], ctx.commands)

    def test_launch_exception_never_fabricates_a_started_child_or_exit(self):
        self.makefile("test1:\n\t@echo one\ntest5:\n\t@echo five\n")
        ctx = Context(self.root)
        with patch.object(ctx, "run", side_effect=OSError("launch observation unavailable")):
            with self.assertRaises(OSError):
                execute(self.args, ctx)
        row = self.observations(ctx)
        self.assertIsNone(row["executionStarted"])
        self.assertNotIn("exit", row)

    def test_source_headers_and_scope_policy_are_actually_bound(self):
        self.contract_mock.stop()
        for name in POLICIES:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, path)
        template = self.root / "runtime/tests/makefile.in"
        shutil.copyfile(ROOT / "vendor/gambit/tests/makefile.in", template)
        self.makefile(template.read_text())
        ctx = Context(self.root)
        manifest = {"files": {sealed: digest(self.root / name) for name, sealed in POLICIES.items()}}
        with patch("gambit_smp.research_kernel.manifest_paths", return_value=manifest):
            contract, _ = scope_contract(ctx, self.root / "runtime")
            self.assertEqual(["test7"], contract["targets"]["test9"]["dependencies"])
            self.makefile(template.read_text().replace("test9: test7", "test9:"))
            with self.assertRaisesRegex(ValueError, "headers"):
                scope_contract(ctx, self.root / "runtime")
            self.makefile(template.read_text())
            data = json.loads((self.root / CONTRACT).read_text())
            data["targets"]["test11"]["unitSelections"] = []
            (self.root / CONTRACT).write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, "sealed"):
                scope_contract(ctx, self.root / "runtime")

    def test_official_check_unit_mode_has_source_witness(self):
        source = (ROOT / "vendor/gambit/tests/makefile.in").read_text()
        contract = json.loads((ROOT / CONTRACT).read_text())
        self.assertEqual({"test11": ["gsi"]}, contract["unitModes"])
        self.assertIn("test11:\n\t@echo \"------------ TEST 11 (run unit tests)\"\n\t$(MAKE) ut\n", source)
        unit_recipe = source.split("ut ut-C:\n", 1)[1].split("\nut-js:", 1)[0]
        self.assertIn("-f ./run-unit-tests.scm", unit_recipe)
        self.assertNotIn("-gsc", unit_recipe)

    def test_root_core_failure_is_not_tests_makefile_core(self):
        official = {"regime": "upstream-make", "makefileScope": "tests/makefile",
                    "operations": ["check", "core"], "requestedOperations": ["check"]}
        scope = make_operation_scope(official)
        self.assertIn("tests/makefile:core", scope)
        self.assertFalse(selected_scope("Makefile:core", scope, []))
        self.assertIn("Makefile:core", make_operation_scope({"operation": "core"}))
        with self.assertRaisesRegex(ValueError, "source-bound"):
            make_operation_scope({**official, "makefileScope": "Makefile"})

    def test_reused_causal_intent_rejects_missing_or_duplicate_declared_ids(self):
        intent = json.loads((ROOT / "evidence/research/current-source-full-bootstrap/interpreted-intent.json").read_text())
        selected = native_capabilities.select_review_intent(intent, ["018-thread-interrupt"])
        self.assertEqual(["018-thread-interrupt"], [row["id"] for row in selected["failures"]])
        self.assertEqual(len(intent["failures"]), 10)
        with self.assertRaisesRegex(ValueError, "failure scope"):
            native_capabilities.select_review_intent(intent, ["not-recorded"])
        with self.assertRaisesRegex(ValueError, "failure scope"):
            native_capabilities.select_review_intent({**intent, "failures": [*intent["failures"], intent["failures"][0]]},
                                                     ["018-thread-interrupt"])

    def test_source_bound_suite_inventory_is_exact_and_has_no_per_file_waiver(self):
        recipe = json.loads((ROOT / "evidence/research/ci/threads.recipe.json").read_text())
        args = next(step["arguments"] for step in recipe["steps"] if step["id"] == "gsi")
        native_capabilities.validate_suite(args, recipe["inputs"])
        source = self.root / "candidate"
        unit = source / "tests/unit-tests/06-thread"
        unit.mkdir(parents=True)
        (unit / "thread_start.scm").write_text("(display 1)\n")
        (unit / "thread_stress.scm").write_text("(display 2)\n")
        ctx = Context(self.root)
        tiny_args = {key: value for key, value in args.items() if key != "fileBudgetSeconds"}
        with patch.object(ctx, "artifact", return_value=source):
            self.assertEqual(["06-thread/thread_start.scm"],
                             native_capabilities.expected_suite_inventory(tiny_args, ctx))
            group = {"thread-completion": {"files": ["06-thread/missing.scm"], "budgetSeconds": 120}}
            with self.assertRaisesRegex(ValueError, "group budget escaped"):
                native_capabilities.expected_suite_inventory({**tiny_args, "groupBudgetSeconds": group}, ctx)
            with self.assertRaisesRegex(ValueError, "file budget escaped"):
                native_capabilities.expected_suite_inventory(
                    {**tiny_args, "fileBudgetSeconds": {"06-thread/missing.scm": 10}}, ctx)
        with self.assertRaisesRegex(ValueError, "per-file controls"):
            native_capabilities.validate_suite({**args, "additionalFixtures": {}}, recipe["inputs"])

    def test_bound_upstream_review_uses_exact_declared_failure_slice(self):
        intent_name = "evidence/research/current-source-full-bootstrap/interpreted-intent.json"
        intent_path = self.root / intent_name
        intent_path.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / intent_name, intent_path)
        self.makefile("test1:\n\t@echo one\ntest5:\n\t@echo five\n")
        target_args = {**self.args, "reviews": {"gsi": {"step": "review", "output": "review"}}}
        ctx = Context(self.root)
        ctx.receipt["plannedSteps"] = [{"id": "official", "capability": "gambit.upstream-tests",
                                         "arguments": target_args, "budgetSeconds": 250}]
        args = {"runtime": self.args["runtime"], "identity": self.args["identity"],
                "intent": intent_name, "target": "official", "mode": "gsi",
                "failureIds": ["018-thread-interrupt"]}
        with patch("gambit_smp.native_review.campaign", return_value={"mode": "gsi"}):
            native_capabilities.bind_review(args, ctx)
        document = self.preflight.call_args.kwargs["document"]
        self.assertEqual(["018-thread-interrupt"], [row["id"] for row in document["failures"]])
        self.assertEqual("tests/makefile", self.preflight.call_args.args[1]["makefileScope"])
