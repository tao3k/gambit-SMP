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
