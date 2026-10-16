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
                                     for name in self.args["targets"]}}
        for target, replacement in (("gambit_smp.native_capabilities.clone", self.root / "runtime"),
                                    ("gambit_smp.native_capabilities.compiler", Path("/usr/bin/cc")),
                                    ("gambit_smp.suite_primitives.check_runtime", None),
                                    ("gambit_smp.native_review.preflight", {"decision": "NOT_REQUIRED"}),
                                    ("gambit_smp.evidence_capabilities.evaluate_observations",
                                     {"scope": [["test1"], ["test5"]], "selection": [], "cycle": []})):
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
            validate({**self.args, "reviews": {"gsi": {"step": "old-review", "output": "review"}}}, inputs)

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
