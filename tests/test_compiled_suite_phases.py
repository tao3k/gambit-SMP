"""Original loader/exit semantics and phase observations, not native admission."""
from pathlib import Path
from types import SimpleNamespace
import json
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp.compiler_phase_primitives import run_suite_phases, suite_phase_commands
from gambit_smp.native_capabilities import validate_suite, validate_compiler_observation
from gambit_smp import native_capabilities, recipes


class CompiledSuitePhaseTests(unittest.TestCase):
    def test_review_identity_includes_the_actual_grouping_producer(self):
        from gambit_smp.native_review import campaign
        ctx = SimpleNamespace(root=Path('/root'), directory=Path('/out/suite'),
            receipt={'steps':[{'id':'suite','budgetSeconds':90}], 'budgetSeconds':300,
                     'timeoutPolicy':{'mode':'progress'}})
        args = dict(mode='gsc', reviewRules='rules.ss', regime='whole-parallel')
        binding = dict(source='driver.scm', sha256='a'*64, fixtureSha256='b'*64)
        with patch('gambit_smp.native_review.digest', return_value='c'*64), \
             patch('gambit_smp.native_review.campaign_tree_identity', return_value={}), \
             patch('gambit_smp.framework.available_processors', return_value=12), \
             patch('gambit_smp.compiler_phase_primitives.bind_numeric_grouping') as bound:
            before = campaign(ctx, args, Path('/runtime'), Path('/identity'),
                              [Path('03-number/_num.scm')], Path('/work/unit-tests'))
            after = campaign(ctx, {**args, 'numericGrouping':binding}, Path('/runtime'),
                             Path('/identity'), [Path('03-number/_num.scm')], Path('/work/unit-tests'))
        self.assertNotEqual(before, after)
        self.assertEqual(binding, after['numericGrouping'])
        bound.assert_called_once_with(ctx, Path('/work'), binding)

    def test_commands_preserve_upstream_entry_and_loader(self):
        work = Path("work")
        plan = suite_phase_commands("numbers/control.scm", work)
        self.assertEqual(work/"unit-tests/numbers/control.c", plan[0][3])
        self.assertIn('(module-ref _test) (linker-name "_test.o1")', plan[0][2][-1])
        self.assertIn('output: "_test.o1"', plan[1][2][-1])
        self.assertNotIn("cc-options:", plan[1][2][-1])
        self.assertEqual(["-:debug-settings=-,io-settings=lu", "-f", "_test.o1"], plan[2][2])
        self.assertNotIn("##load", str(plan))
        for selection in ("../foreign.scm", "/foreign.scm", "control.c"):
            with self.assertRaises(ValueError):
                suite_phase_commands(selection, work)


    def test_grouping_requires_explicit_original_numeric_binding(self):
        from gambit_smp.compiler_phase_primitives import validate_numeric_grouping, NUMERIC_GROUP_DRIVER, NUMERIC_FIXTURE_SHA
        binding = dict(source=NUMERIC_GROUP_DRIVER, sha256="a"*64, fixtureSha256=NUMERIC_FIXTURE_SHA)
        validate_numeric_grouping(binding, [NUMERIC_GROUP_DRIVER], True)
        for value, inputs, enabled in [(binding, [], True), (binding, [NUMERIC_GROUP_DRIVER], False),
                ({**binding, "fixtureSha256": "b"*64}, [NUMERIC_GROUP_DRIVER], True),
                ({**binding, "sha256": True}, [NUMERIC_GROUP_DRIVER], True),
                ({**binding, "source": "other.scm"}, ["other.scm"], True)]:
            with self.assertRaises(ValueError):
                validate_numeric_grouping(value, inputs, enabled)

    def test_grouped_command_preserves_original_loader_and_c_driver(self):
        ordinary = suite_phase_commands("03-number/_num.scm", Path("/owned"))
        grouped = suite_phase_commands("03-number/_num.scm", Path("/owned"), Path("/source/driver.scm"))
        self.assertEqual(ordinary[1:], grouped[1:])
        self.assertIn('file-settings=lf', grouped[0][2][0])
        self.assertIn('GAMBIT_NUMERIC_GENERATED_C', grouped[0][2][-1])
        self.assertIn('/owned/unit-tests/03-number/_num.c', grouped[0][2][-1])
        with self.assertRaises(ValueError):
            suite_phase_commands("other.scm", Path("/owned"), Path("/source/driver.scm"))

    def test_actual_numeric_recipes_declare_the_verified_grouping(self):
        from gambit_smp.framework import ROOT, digest
        names = ["evidence/research/ci/bazel-profile-numeric-host.recipe.json",
                 "evidence/research/ci/bazel-profile-numeric.recipe.json",
                 "evidence/research/ci/gc-ffi-numeric.recipe.json",
                 "evidence/research/ci/three-flag-numeric-inventory.recipe.json",
                 "evidence/research/ci/bazel-profile-gc-ffi-inventory.recipe.json",
                 "evidence/research/current-source-full-bootstrap/dynamic-modulo-compiled.recipe.json"]
        for name in names:
            recipe, steps = recipes.load(ROOT, ROOT / name)
            selected = [step for step in steps if "numericGrouping" in step["arguments"]]
            self.assertEqual(1, len(selected))
            binding = selected[0]["arguments"]["numericGrouping"]
            self.assertEqual(digest(ROOT/binding["source"]), binding["sha256"])
            self.assertIn(binding["source"], recipe["inputs"])
            if selected[0]["capability"] == "gambit.compiler-observation":
                self.assertEqual(90, selected[0]["arguments"]["phaseBudgetSeconds"])
                self.assertEqual("original-gsi", selected[0]["arguments"]["loader"])

    def run_case(self, *, failed_phase=None, missing_artifact=False, timed_out=False):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            (work/"unit-tests").mkdir()
            calls = []
            def execute(name, argv, cwd, cap):
                calls.append((name, argv, cap))
                phase = len(calls)-1
                code = 2 if phase == failed_phase else 0
                timeout = timed_out and phase == failed_phase
                if phase < 2 and not missing_artifact and code == 0:
                    output = work/"unit-tests/control.c" if phase == 0 else work/"_test.o1"
                    output.write_text("actual fixture output")
                return (-9 if timeout else code), "", timeout, (64,31,1)[phase]
            rows = run_suite_phases(SimpleNamespace(run=execute), work/"runtime", work,
                                    "control.scm", "suite-0", 90)
            return rows, calls

    def test_completed_phases_receive_independent_original_windows(self):
        rows, calls = self.run_case()
        self.assertEqual(3, len(rows))
        self.assertTrue(all(row["accepted"] for row in rows))
        self.assertEqual([90,90,90], [cap for _,_,cap in calls])
        self.assertGreater(sum(row["seconds"] for row in rows), 90)
        self.assertTrue(all(row["artifactSha256"] for row in rows[:2]))
        self.assertEqual("_test.o1", calls[-1][1][-1])

    def test_original_assertion_failure_cannot_pass(self):
        rows, calls = self.run_case(failed_phase=2)
        self.assertEqual(3,len(calls))
        self.assertEqual(2,rows[-1]["exit"])
        self.assertFalse(rows[-1]["accepted"])

    def test_missing_artifact_or_timeout_stops_before_loader(self):
        rows, calls = self.run_case(missing_artifact=True)
        self.assertEqual(1,len(calls))
        self.assertFalse(rows[0]["accepted"])
        rows, calls = self.run_case(failed_phase=1,timed_out=True)
        self.assertEqual(2,len(calls))
        self.assertTrue(rows[-1]["timeout"])
        self.assertFalse(rows[-1]["accepted"])

    def test_stale_output_rejects_without_launch(self):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            (work/"_test.o1").write_text("stale")
            def unexpected(*args):
                self.fail("stale output launched a compiler")
            with self.assertRaises(ValueError):
                run_suite_phases(SimpleNamespace(run=unexpected),work/"runtime",work,"control.scm","case",90)

    def test_phase_configuration_is_exact_and_never_an_interpreted_override(self):
        args = {"runtime":{"step":"producer","output":"runtime"},
                "identity":{"step":"producer","output":"identity"},
                "mode":"gsc", "regime":"whole-parallel", "selection":["."],
                "expectedFiles":["control.scm"], "fileBudgetSeconds":{"control.scm":90},
                "compilerPhaseFiles":["control.scm"]}
        validate_suite(args,[])
        for change in ({"mode":"gsi"}, {"compilerPhaseFiles":[{}]},
                       {"compilerPhaseFiles":["control.scm","control.scm"]},
                       {"compilerPhaseFiles":["unknown.scm"]}, {"fileBudgetSeconds":{}},
                       {"regime":"atomic-coverage","batchBudgetSeconds":90}):
            with self.subTest(change=change),self.assertRaises(ValueError):
                validate_suite({**args,**change},[])
        control = {"runtime":args["runtime"],"identity":args["identity"],
                   "selection":"control.scm","scheduling":"default-control",
                   "phaseBudgetSeconds":90,"loader":"original-gsi"}
        validate_compiler_observation(control,[])
        for change in ({"loader":"custom-hook"}, {"scheduling":"no-scheduling"}):
            with self.assertRaises(ValueError):
                validate_compiler_observation({**control,**change},[])

    def test_suite_selects_only_declared_phase_file_and_retains_full_inventory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runtime = root/"runtime"
            for name in ("gsi","gsc","lib","include","bin"):
                (runtime/name).mkdir(parents=True)
            copied = root/"tests"
            (copied/"unit-tests").mkdir(parents=True)
            files = [Path("control.scm"),Path("ordinary.scm")]
            for file in files:
                (copied/"unit-tests"/file).write_text("original fixture")
            out = root/"out"
            out.mkdir()
            ctx = recipes.ExecutionContext(root,root,out,{},time.monotonic()+10,{},
                {"timeoutPolicy":{"mode":"progress"}}, {})
            phases = [{"phase":name,"exit":0,"timeout":False,"seconds":.01,
                       "accepted":True,"artifactSha256":None} for name in
                      ("scheme-to-c","c-to-dynamic-module","compiled-execution")]
            def execute(argv,cwd,cap,**kwargs):
                self.assertIn("unit-tests/ordinary.scm",argv)
                self.assertNotIn("unit-tests/control.scm",argv)
                return 0,"PASSED ALL 1 UNIT TESTS\n",False,.01
            with patch("gambit_smp.compiler_phase_primitives.run_suite_phases",return_value=phases) as selected, \
                 patch.object(recipes,"execute",side_effect=execute):
                rows = native_capabilities.run_suite_groups(ctx,runtime,copied,
                    {"mode":"gsc","regime":"whole-parallel", "compilerPhaseFiles":["control.scm"],
                     "fileBudgetSeconds":{"control.scm":.5}},files,2,"p3")
            self.assertEqual(1,selected.call_count)
            self.assertEqual(.5,selected.call_args.args[-1])
            self.assertEqual(["control.scm","ordinary.scm"],sorted(file for row in rows for file in row["files"]))
            self.assertTrue(all(row["accepted"] for row in rows))
            phased = next(row for row in rows if row["files"]==["control.scm"])
            self.assertEqual(3,len(phased["compilerPhases"]))
            self.assertEqual("original-gsi-loader-and-unit-test-exit",phased["assertionProtocol"])
            self.assertEqual(["control.scm"],json.loads((out/"suite-plan.json").read_text())["compilerPhaseFiles"])
