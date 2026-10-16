"""Transport contracts, not evidence of compiler speed or native correctness."""
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import native_capabilities as native
from gambit_smp.compiler_phase_primitives import EXECUTION_WITNESS


class CompilerObservationTests(unittest.TestCase):
    def test_rejects_unbounded_or_injected_diagnostics(self):
        args = {"runtime":{"step":"producer","output":"runtime"},
                "identity":{"step":"producer","output":"identity"},
                "selection":"03-number/_num.scm", "scheduling":"no-modulo",
                "phaseBudgetSeconds":90}
        native.validate_compiler_observation(args, [])
        native.validate_compiler_observation({**args,"scheduling":"default-control"}, [])
        for key, value in (("scheduling","default"), ("scheduling","-O0"),
                           ("selection","../foreign.scm"), ("phaseBudgetSeconds",91),
                           ("phaseBudgetSeconds",True), ("phaseBudgetSeconds",float("nan"))):
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                native.validate_compiler_observation({**args,key:value}, [])

    def test_three_phases_preserve_budget_and_require_actual_execution_witness(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            runtime = root / "runtime"
            unit = runtime / "tests/unit-tests/03-number"
            unit.mkdir(parents=True)
            (unit / "_num.scm").write_text("original unit fixture")
            identity = root / "identity.json"
            identity.write_text("{}")
            directory = root / "step"
            directory.mkdir()
            work = directory / "runtime"
            work.mkdir()
            args = {"runtime":{"step":"producer","output":"runtime"},
                    "identity":{"step":"producer","output":"identity"},
                    "selection":"03-number/_num.scm", "scheduling":"no-scheduling",
                    "phaseBudgetSeconds":90}
            shared = {}
            ctx = SimpleNamespace(directory=directory,env=shared,commands=[],remaining=lambda:200,
                  artifact=lambda ref,kind: runtime if ref["output"]=="runtime" else identity,
                  bind=lambda paths:list(paths))
            calls = []
            witness = [EXECUTION_WITNESS + "\n"]
            def require(name,argv,cwd,cap):
                calls.append((name,argv,cap))
                ctx.commands.append({"exit":0,"timeout":False,"seconds":.01})
                if name=="scheme-to-c": (work/"probe.c").write_text("generated C")
                if name=="c-to-dynamic-module": (work/"probe.o1").write_text("compiled module")
                return witness[0] if name=="compiled-execution" else ""
            ctx.require = require
            with patch.object(native,"compiler",return_value=Path("gcc")), \
                 patch.object(native,"gnu_build_driver",return_value={"sha256":"unit"}), \
                 patch.object(native,"available_processors",return_value=6), \
                 patch("gambit_smp.suite_primitives.check_runtime"), \
                 patch("gambit_smp.suite_primitives.runtime_view",return_value=work), \
                 patch("gambit_smp.artifact_storage.transfer_tree"):
                result = native.compiler_observation(args,ctx)
                self.assertEqual(3,len(result["phases"]))
                self.assertTrue(all(0<cap<=90 for _,_,cap in calls))
                self.assertIn("-fno-schedule-insns2",calls[1][1][-1])
                self.assertFalse(result["performanceAdmitted"])
                self.assertTrue(ctx.env["GAMBOPT"].startswith("p6,"))
                self.assertEqual({},shared)
                calls.clear()
                for output in ("probe.c", "probe.o1"):
                    (work/output).unlink()
                ctx.receipt = {"timeoutPolicy": {"mode": "per-stage", "overheadSeconds": 30}}
                with patch.object(native.time, "monotonic", return_value=1000):
                    staged = native.compiler_observation(args,ctx)
                self.assertEqual([90,90,90],[cap for _,_,cap in calls])
                self.assertEqual("independent-watchdogs",staged["phaseTiming"])
                calls.clear()
                for output in ("probe.c", "probe.o1"):
                    (work/output).unlink()
                controlled = native.compiler_observation({**args,"scheduling":"default-control"},ctx)
                self.assertEqual([],controlled["ccOptions"])
                self.assertIn('cc-options: ""',calls[1][1][-1])
                self.assertNotIn("-fno-",calls[1][1][-1])
                self.assertFalse(controlled["runtimeAdmitted"])
                self.assertFalse(controlled["performanceAdmitted"])
                self.assertTrue(controlled["claim"].startswith("default-command-phase-control"))
                witness[0]=""
                for output in ("probe.c", "probe.o1"):
                    (work/output).unlink()
                with self.assertRaisesRegex(ValueError,"execution witness"):
                    native.compiler_observation(args,ctx)
