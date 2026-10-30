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
        kinds = {kind} if isinstance(kind, str) else set(kind)
        identity = bool(kinds & {'runtime-identity', 'bootstrap-input-identity'})
        if identity:
            if ref['output'] != 'identity':
                raise ValueError('identity reference required by test artifact contract')
        return self.root / ("identity.json" if identity else "runtime")
    def bind(self, paths):
        pass
    def remaining(self):
        return max(0.001, self.deadline - time.monotonic())
    def publish(self, name, kind, path):
        return {name: {"type": kind, "path": str(path)}}
    def run(self, name, argv, cwd, cap, **options):
        result = capture([str(arg) for arg in argv], cwd, min(cap, self.remaining()), self.env, **options)
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

    def test_import_preflight_uses_the_existing_scope_dsl_without_make_or_fixture_copy(self):
        from gambit_smp.upstream_tests import preflight_import
        self.makefile('test1:\n\t@true\ntest5:\n\t@true\n')
        ctx = Context(self.root)
        ctx.planned_steps = [dict(id='runtime', capability='gambit.runtime-import',
            arguments=dict(source=dict(step='output', output='source'))),
            dict(id='official', capability='gambit.upstream-tests', arguments=self.args)]
        result = preflight_import(ctx, self.root/'runtime')
        self.assertEqual(['official'], [row['step'] for row in result])
        self.assertEqual(['test1', 'test5'], result[0]['operations'])
        self.assertFalse(result[0]['fixtureInventoryChecked'])
        self.assertFalse(result[0]['runtimeAdmitted'])
        self.assertEqual([], ctx.commands)
        self.assertFalse((ctx.directory/'source').exists())
        self.contract_mock.side_effect = ValueError('configured/source target headers differ')
        with self.assertRaisesRegex(ValueError, 'configured/source target headers'):
            preflight_import(ctx, self.root/'runtime')
        self.assertEqual([], ctx.commands)

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

    def test_official_make_runs_hash_bound_additional_fixture(self):
        source = self.root / "models/process_spawn.scm"
        source.parent.mkdir()
        source.write_text("(display \"fixture\")\n")
        fixture = {"12-os/process_spawn.scm": {"source": "models/process_spawn.scm",
                    "sha256": digest(source)}}
        args = {**self.args, "additionalFixtures": fixture}
        inputs = [args["failures"], args["reviewRules"], *POLICIES, "models/process_spawn.scm"]
        validate(args, inputs)
        self.makefile("test1:\n\t@test -f unit-tests/12-os/process_spawn.scm\n"
                      "test5:\n\t@test -f unit-tests/12-os/process_spawn.scm\n")
        ctx = Context(self.root)
        execute(args, ctx)
        self.assertEqual(source.read_bytes(),
                         (self.root / "runtime/tests/unit-tests/12-os/process_spawn.scm").read_bytes())
        self.assertEqual("PASS", self.observations(ctx)["outcome"])
        with self.assertRaisesRegex(ValueError, "cannot replace upstream"):
            native_capabilities.additional_fixtures(args, ctx, self.root / "runtime/tests/unit-tests")
        source.write_text("drift\n")
        with self.assertRaisesRegex(ValueError, "drift"):
            native_capabilities.additional_fixtures(args, ctx, self.root / "other-unit-tests")
        with self.assertRaises(ValueError):
            validate({**args, "additionalFixtures": {"../escape.scm": next(iter(fixture.values()))}}, inputs)

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
        # Make may observe its killed recipe and return 2 before the group
        # kill reaches Make itself. Preserve that actual exit, not a synthetic
        # -9; timeout and the real teardown observation are separate facts.
        self.assertNotEqual(0, row["exit"])
        self.assertEqual(ctx.commands[-1]["exit"], row["exit"])
        # Timeout delivery does not guarantee descendants have already exited.
        # Retain the actual probe and refuse acceptance in every case.
        self.assertEqual("DENY", row["outcome"])
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

    def test_real_make_target_processor_override_does_not_reach_sibling(self):
        self.contract['unitModes'] = {}
        self.makefile('test1:\n\t@printf "%s" "$$GAMBOPT" > first.env\ntest5:\n\t@printf "%s" "$${GAMBOPT-unset}" > sibling.env\n')
        gsi = self.root/'runtime/gsi/gsi'; gsi.parent.mkdir()
        gsi.write_text('#!/bin/sh\nvalue=${GAMBOPT:-p1}\nprintf "%s" "${value#p}"\n')
        gsi.chmod(0o755)
        ctx = Context(self.root)
        ctx.env.pop('GAMBOPT',None)
        execute({**self.args,'targetProcessors':{'test1':1}},ctx)
        self.assertEqual('p1',(self.root/'runtime/tests/first.env').read_text())
        self.assertEqual('unset',(self.root/'runtime/tests/sibling.env').read_text())
        self.assertNotIn('GAMBOPT',ctx.env)
        row = json.loads((ctx.directory/'upstream-observations.json').read_text())
        self.assertEqual({'test1':1},row['processorConfiguration']['targets'])

    def test_make_adopts_and_measures_the_same_producer_environment_population(self):
        self.makefile('test1:\n\t@printf "%s" "$$GAMBOPT" > first.env\ntest5:\n\t@printf "%s" "$$GAMBOPT" > sibling.env\n')
        gsi = self.root/'runtime/gsi/gsi'; gsi.parent.mkdir()
        gsi.write_text('#!/bin/sh\nvalue=${GAMBOPT:-p6}\nprintf "%s" "${value#p}"\n')
        gsi.chmod(0o755)
        observation = self.root/'environment.json'
        observation.write_text(json.dumps({'processors':1}))
        ctx = Context(self.root)
        original = ctx.artifact
        ctx.artifact = lambda ref,kind: observation if kind == 'current-producer-observation' else original(ref,kind)
        execute({**self.args,'environmentProbe':{'step':'environment','output':'observation'}},ctx)
        self.assertEqual('p1',(self.root/'runtime/tests/first.env').read_text())
        self.assertEqual('p1',(self.root/'runtime/tests/sibling.env').read_text())
        row=json.loads((ctx.directory/'upstream-observations.json').read_text())
        self.assertEqual([{'target':'default','processors':1}],row['processorConfiguration']['observed'])

    def test_processor_override_cannot_narrow_unit_suite_or_dependency_closure(self):
        from gambit_smp.upstream_tests import validate_target_processors
        with self.assertRaisesRegex(ValueError,'non-unit'):
            validate_target_processors({'targetProcessors':{'test1':1}},self.contract,['test1'])
        self.contract['unitModes'] = {}
        self.contract['targets']['test1']['dependencies'] = ['test5']
        with self.assertRaisesRegex(ValueError,'non-unit'):
            validate_target_processors({'targetProcessors':{'test1':1}},self.contract,['test1','test5'])

    def test_timeout_refuses_all_three_teardown_deliveries(self):
        from gambit_smp.process_observation import Observation
        self.makefile("test1:\n\t@true\ntest5:\n\t@true\n")
        for quiescent in (True, False, None):
            with self.subTest(quiescent=quiescent):
                ctx = Context(self.root)
                observation = Observation("", "", -9, True, .1, 123,
                                          "start", "end", quiescent)
                with patch.dict(globals(), capture=lambda *a, **k: observation):
                    with self.assertRaisesRegex(ValueError, "exit/timeout/teardown"):
                        execute(self.args, ctx)
                row = self.observations(ctx)
                self.assertIs(row["timeout"], True)
                self.assertEqual(-9, row["exit"])
                self.assertIs(row["processGroupQuiescent"], quiescent)
                self.assertEqual("DENY", row["outcome"])
                shutil.rmtree(ctx.directory)

    def test_source_headers_and_scope_policy_are_actually_bound(self):
        self.contract_mock.stop()
        for name in POLICIES:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, path)
        template = self.root / "runtime/tests/makefile.in"
        # Use the exact source named by the contract, not a moving vendor tree.
        pin = json.loads((ROOT/CONTRACT).read_text())['template']['sha256']
        lock = json.loads((ROOT / '.github/gambit/source.lock.json').read_text())
        original = capture([
            'git', '-C', str(ROOT / lock['submodule']), 'show',
            lock['revision'] + ':tests/makefile.in'], ROOT, 10, dict(os.environ))
        self.assertEqual(0, original.exit)
        self.assertFalse(original.timeout)
        self.assertTrue(original.group_quiescent)
        template.write_bytes(original.stdout.encode())
        self.assertEqual(pin, digest(template))
        self.makefile(template.read_text())
        ctx = Context(self.root)
        manifest = {"files": {sealed: digest(self.root / name) for name, sealed in POLICIES.items()}}
        with patch("gambit_smp.research_kernel.manifest_paths", return_value=manifest):
            with self.assertRaisesRegex(ValueError, 'headers'):
                scope_contract(ctx, self.root / 'runtime')
            declaration = 'evidence/research/incremental-builds/qualified-upstream-tests.json'
            contract, _ = scope_contract(ctx, self.root / "runtime", declaration=declaration)
            self.assertEqual(["test7"], contract["targets"]["test9"]["dependencies"])
            self.makefile(template.read_text().replace("test9: test7", "test9:"))
            with self.assertRaisesRegex(ValueError, "headers"):
                scope_contract(ctx, self.root / "runtime", declaration=declaration)
            self.makefile(template.read_text())
            data = json.loads((self.root / CONTRACT).read_text())
            data["targets"]["test11"]["unitSelections"] = []
            (self.root / CONTRACT).write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, "sealed"):
                scope_contract(ctx, self.root / "runtime", declaration=declaration)

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
        tiny_args = {key: value for key, value in args.items()
                     if key not in {"fileBudgetSeconds", "additionalFixtures"}}
        with patch.object(ctx, "artifact", return_value=source):
            self.assertEqual(["06-thread/thread_start.scm"],
                             native_capabilities.expected_suite_inventory(tiny_args, ctx))
            group = {"thread-completion": {"files": ["06-thread/missing.scm"], "budgetSeconds": 120}}
            with self.assertRaisesRegex(ValueError, "group budget escaped"):
                native_capabilities.expected_suite_inventory({**tiny_args, "groupBudgetSeconds": group}, ctx)
            with self.assertRaisesRegex(ValueError, "file budget escaped"):
                native_capabilities.expected_suite_inventory(
                    {**tiny_args, "fileBudgetSeconds": {"06-thread/missing.scm": 10}}, ctx)
            with self.assertRaisesRegex(ValueError, "extend the selected inventory"):
                native_capabilities.expected_suite_inventory(
                    {**tiny_args, "additionalFixtures": {"06-thread/thread_start.scm": {}}}, ctx)
        with self.assertRaisesRegex(ValueError, "per-file controls"):
            native_capabilities.validate_suite({**args, "compilerPhaseFiles": []}, recipe["inputs"])

    def test_source_bound_inventory_accepts_exact_completed_or_imported_producer(self):
        source_ref = {"step": "candidate", "output": "source"}
        source = {"id": "candidate", "capability": "gambit.materialize",
                  "dependsOn": [], "arguments": {}}
        producer = {"id": "producer", "capability": "gambit.completed-runtime",
                    "dependsOn": ["candidate"], "arguments": {"source": source_ref}}
        suite = {"id": "suite", "capability": "gambit.suite",
                 "dependsOn": ["candidate", "producer"], "arguments": {
                     "runtime": {"step": "producer", "output": "runtime"},
                     "identity": {"step": "producer", "output": "identity"},
                     "expectedSource": source_ref}}
        by_id = {row["id"]: row for row in (source, producer, suite)}
        for capability in ("gambit.completed-runtime", "gambit.runtime-import"):
            with self.subTest(capability=capability):
                producer["capability"] = capability
                native_capabilities.graph(suite, by_id, recipes.CAPABILITIES)
                producer["arguments"]["source"] = {"step": "other", "output": "source"}
                with self.assertRaisesRegex(ValueError, "exact materialized candidate"):
                    native_capabilities.graph(suite, by_id, recipes.CAPABILITIES)
                producer["arguments"]["source"] = source_ref
        suite["dependsOn"].remove("candidate")
        with self.assertRaisesRegex(ValueError, "exact materialized candidate"):
            native_capabilities.graph(suite, by_id, recipes.CAPABILITIES)

    def test_source_successor_only_rebinds_the_reviewed_line_and_current_bytes(self):
        line = "     ? ___FIXNEGP_NOTFALSEP(var,x) \\"
        paths = {
            "base": self.root / "evidence/base.json",
            "lock": self.root / "evidence/lock.json",
            "old": self.root / "patches/old.patch",
            "new": self.root / "patches/new.patch",
            "source": self.root / "candidate/include/gambit.h.in",
        }
        for path in paths.values():
            path.parent.mkdir(parents=True, exist_ok=True)
        paths["old"].write_text("+" + line + "\n")
        paths["new"].write_text("+" + line + "\n")
        paths["source"].write_text("header\n" + line + "\n")
        intent = {"schema": "current-producer-review-intent.v1", "failures": [
            {"id": "known", "changes": [{"id": "repair", "kind": "source", "path": "include/gambit.h.in",
                                            "before": "a" * 64, "after": "b" * 64}], "budget": {"pointer": "unchanged"}}]}
        paths["base"].write_text(json.dumps(intent))
        paths["lock"].write_text(json.dumps({"files": {"include/gambit.h.in": {
            "candidateSha256": digest(paths["source"])}}, "patch": "patches/new.patch",
            "patchSha256": digest(paths["new"])}))
        successor = {"schema": "current-source-successor-review.v1",
            "baseIntent": {"path": "evidence/base.json", "sha256": digest(paths["base"])},
            "sourceLock": {"path": "evidence/lock.json", "sha256": digest(paths["lock"])},
            "priorPatch": {"path": "patches/old.patch", "sha256": digest(paths["old"])},
            "failureId": "known", "changeId": "repair", "file": "include/gambit.h.in",
            "priorAfter": "b" * 64, "currentAfter": digest(paths["source"]), "retainedLine": line}
        ctx = Context(self.root)
        ctx.receipt["plannedSteps"] = [{"id": "candidate", "capability": "gambit.materialize",
                                         "arguments": {"sourceLock": "evidence/lock.json"}}]
        args = {"expectedSource": {"step": "candidate", "output": "source"}}
        with patch.object(ctx, "artifact", return_value=self.root / "candidate"):
            revised = native_capabilities.bind_source_successor(intent, successor, ctx, args, "evidence/base.json")
            self.assertEqual("b" * 64, intent["failures"][0]["changes"][0]["after"])
            self.assertEqual(digest(paths["source"]), revised["failures"][0]["changes"][0]["after"])
            self.assertEqual(intent["failures"][0]["budget"], revised["failures"][0]["budget"])
            with self.assertRaisesRegex(ValueError, "unrelated causal claims"):
                native_capabilities.bind_source_successor(intent, {**successor, "priorAfter": "c" * 64},
                                                          ctx, args, "evidence/base.json")
            paths["source"].write_text("changed header\n")
            with self.assertRaisesRegex(ValueError, "materialized candidate"):
                native_capabilities.bind_source_successor(intent, successor, ctx, args, "evidence/base.json")

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

    def test_bound_upstream_review_includes_the_official_additional_fixture(self):
        intent_name = "evidence/research/current-source-full-bootstrap/interpreted-intent.json"
        intent_path = self.root / intent_name
        intent_path.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / intent_name, intent_path)
        source = self.root / "models/process_spawn.scm"
        source.parent.mkdir()
        source.write_text("(display \"fixture\")\n")
        (self.root / "runtime/tests/unit-tests/12-os").mkdir(parents=True)
        self.makefile("test1:\n\t@true\ntest5:\n\t@true\n")
        target_args = {**self.args, "additionalFixtures": {
            "12-os/process_spawn.scm": {"source": "models/process_spawn.scm", "sha256": digest(source)}}}
        ctx = Context(self.root)
        ctx.receipt["plannedSteps"] = [{"id": "official", "capability": "gambit.upstream-tests",
                                         "arguments": target_args, "budgetSeconds": 250}]
        args = {"runtime": self.args["runtime"], "identity": self.args["identity"],
                "intent": intent_name, "target": "official", "mode": "gsi",
                "failureIds": ["018-thread-interrupt"]}
        scope = {"scope": [["test1"], ["test5"]], "selection": [["12-os"]],
                 "mode": [["gsi"]], "cycle": []}
        with patch("gambit_smp.evidence_capabilities.evaluate_observations", return_value=scope), \
             patch("gambit_smp.upstream_tests.scope_contract",
                   side_effect=lambda ctx, runtime: (self.contract, runtime / "tests/makefile")), \
             patch("gambit_smp.native_review.campaign", return_value={"mode": "gsi"}):
            native_capabilities.bind_review(args, ctx)
        call = self.preflight.call_args
        self.assertEqual([Path("12-os/process_spawn.scm")], call.args[4])
        self.assertEqual(source.read_bytes(),
                         (call.args[5] / "12-os/process_spawn.scm").read_bytes())
        self.assertFalse((self.root / "runtime/tests/unit-tests/12-os/process_spawn.scm").exists())
        self.assertEqual(call.args[2], self.root / "runtime")
        self.assertFalse((ctx.directory / "source").exists())
        official_runtime = self.root / "official-runtime"
        shutil.copytree(self.root / "runtime", official_runtime)
        native_capabilities.additional_fixtures(target_args, ctx, official_runtime / "tests/unit-tests")
        from gambit_smp.native_review import campaign_tree_identity
        self.assertEqual(campaign_tree_identity(call.args[2], call.args[5]),
                         recipes.tree_identity(official_runtime))
        (call.args[5] / "12-os/process_spawn.scm").write_text("drift")
        self.assertNotEqual(campaign_tree_identity(call.args[2], call.args[5]),
                            recipes.tree_identity(official_runtime))


class ActualFileBudgetTransportTests(unittest.TestCase):
    def observe(self, body, cap):
        import sys
        from gambit_smp.upstream_tests import FileBudgetGuard
        guard = FileBudgetGuard({'13-modules/prim_port.scm': cap})
        with tempfile.TemporaryDirectory() as directory:
            result = capture([sys.executable, '-c', body], Path(directory), 2,
                             dict(os.environ), boundary=guard)
        return result, guard

    def test_actual_hanging_file_is_killed_before_whole_deadline(self):
        result, guard = self.observe(
            'import time; print("[  0|  0] 0% ... 0.0s 13-modules/prim_port.scm",flush=True); time.sleep(10)', .15)
        self.assertTrue(result.timeout)
        self.assertLess(result.seconds, 1)
        self.assertIsNotNone(result.exit)
        self.assertTrue(result.group_quiescent)
        self.assertEqual('TIMEOUT', guard.rows[0]['outcome'])

    def test_actual_completed_interval_and_missing_protocol_are_distinct(self):
        result, guard = self.observe(
            'import time; print("[  0|  0] 0% ... 0.0s 13-modules/prim_port.scm",flush=True); time.sleep(.1); print("[  1|  0] 100% ... 0.1s",flush=True)', .5)
        self.assertFalse(result.timeout); self.assertEqual(0, result.exit)
        guard.complete()
        result, missing = self.observe('print("no file frame")', .15)
        self.assertEqual(0, result.exit)
        with self.assertRaisesRegex(ValueError, 'every required real file interval'):missing.complete()
