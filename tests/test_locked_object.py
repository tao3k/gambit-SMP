import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.locked_object import BuildStages, build_seed_core, configure_source, regenerate_module, rebuild_source_core, preserve_failure


class BuildStageTests(unittest.TestCase):
    def test_source_context_rejection_preserves_failure_not_a_pass(self):
        record = {"contextStable": True, "runtimeAdmitted": False}
        with preserve_failure(record):
            raise ValueError("locked source inputs changed during audit")
        self.assertFalse(record["contextStable"])
        self.assertEqual("ValueError", record["failure"]["type"])
        self.assertFalse(record["runtimeAdmitted"])

    def test_effective_command_budget_logs_and_exit_are_bound(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            source = out / "source"
            runner = BuildStages(source, out, {"PATH": "/usr/bin"})
            raw = str(source) + " compile failed\n"
            with patch("gambit_smp.locked_object.execute", return_value=(7, raw, False, 0.5)) as execute:
                result = runner.run("compile", ["gcc", str(source / "mem.c")], source, 12)
            self.assertEqual(result[0], 7)
            execute.assert_called_once_with(["gcc", str(source / "mem.c")], source, 12, env=runner.env)
            row = runner.results[0]
            self.assertEqual(row["budgetSeconds"], 12)
            self.assertEqual(row["argv"], ["gcc", "${SOURCE}/mem.c"])
            self.assertEqual(row["rawLogSha256"], hashlib.sha256(raw.encode()).hexdigest())
            self.assertEqual((out / "compile.portable.log").read_text(), "${SOURCE} compile failed\n")

    def test_failed_configuration_does_not_advance_to_native_stage(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            with patch("gambit_smp.locked_object.execute", return_value=(1, "failed\n", False, 0.1)) as execute:
                stages, ok = configure_source(out, out, "gcc", {}, "autoconf")
            self.assertFalse(ok)
            self.assertEqual(len(stages.results), 1)
            self.assertEqual(execute.call_count, 1)

    def test_rts_and_generated_c_optimizations_are_separate_explicit_flags(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            with patch("gambit_smp.locked_object.execute", return_value=(0, "", False, 0.1)) as execute:
                _, ok = configure_source(out, out, "gcc", {}, "autoconf", c_opt="-O0", rts_opt="-O1")
            self.assertTrue(ok)
            argv = execute.call_args_list[1].args[0]
            self.assertIn("--enable-c-opt=-O0", argv)
            self.assertIn("--enable-c-opt-rts=-O1", argv)

    def test_seed_exit_zero_without_binaries_or_with_recursive_error_is_denied(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            runner = BuildStages(out, out, {})
            with patch("gambit_smp.locked_object.execute", return_value=(0, "", False, 0.1)):
                ok, result = build_seed_core(runner, out, 120)
            self.assertFalse(ok)
            self.assertFalse(result["scmRegenerationEstablished"])
            for name in ("gsi/gsi", "gsc/gsc", "lib/libgambit.a"):
                path = out / name
                path.parent.mkdir(exist_ok=True)
                path.write_bytes(b"test artifact")
            with patch("gambit_smp.locked_object.execute", return_value=(0, "make: *** Error 2\n", False, 0.1)):
                ok, result = build_seed_core(runner, out, 120)
            self.assertFalse(ok)
            self.assertTrue(result["recursiveBuildErrors"])

    def test_regeneration_requires_actual_generated_output_and_does_not_use_dummy(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source"
            for name in ("lib/_thread.scm", "gsc/gsc"):
                path = source / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"fixture")
            out = Path(directory)
            runner = BuildStages(source, out, {})
            recipe = '../gsc-boot -:~~lib=../lib -f -c -prelude "header" _thread.scm\n'
            with patch("gambit_smp.locked_object.execute", side_effect=[(0, recipe, False, 0.1), (0, "", False, 0.1)]) as execute:
                ok, result = regenerate_module(runner, source, "lib/_thread.scm", 30)
            self.assertFalse(ok)
            self.assertEqual(execute.call_args.args[0][0], str(source / "gsc/gsc"))
            self.assertIn("-o", execute.call_args.args[0])
            self.assertFalse(result["runtimeAdmitted"])

    def test_interpreted_regeneration_binds_loaded_sources_and_explicit_processors(self):
        self.check_interpreted_regeneration(False)

    def test_interpreted_regeneration_rejects_loaded_source_drift(self):
        self.check_interpreted_regeneration(True)

    def test_interpreted_regeneration_refuses_an_unbound_gsi_override(self):
        from gambit_smp.gambit_build_primitives import regenerate_module as regenerate_source_module
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            for name in ('lib/_thread.scm', 'gsc/igsc.scm'):
                path = source/name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('fixture')
            runner = BuildStages(source, source, {'GAMBIT_BOOT_GSI': '/unbound/gsi'})
            with self.assertRaisesRegex(ValueError, 'bound in-tree GSI'):
                regenerate_source_module(runner, source, 'lib/_thread.scm', 30,
                                         interpreted=True, processors=1)

    def check_interpreted_regeneration(self, drift):
        from gambit_smp.gambit_build_primitives import regenerate_module as regenerate_source_module
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            source = out/'source'
            for name in ('lib/_thread.scm', 'gsc/igsc.scm',
                         'gsc/_prims.scm', 'gsi/main.scm', 'gsi/gsi'):
                path = source/name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('fixture')

            class Runner:
                stdout = ''
                def __init__(self):
                    self.out = out
                    self.argv = None
                def run(self, stage, argv, cwd, budget):
                    if stage == 'regeneration-recipe':
                        self.stdout = '../gsc-boot -:~~lib=../lib -f -c -prelude "header" _thread.scm\n'
                    else:
                        self.argv = argv
                        (out/'_thread.c').write_text('actual generated fixture')
                        if drift:
                            (source/'gsc/_prims.scm').write_text('changed')
                    return 0, '', False, 0.1

            runner = Runner()
            ok, result = regenerate_source_module(runner, source, 'lib/_thread.scm', 30,
                                                  interpreted=True, processors=1)
            self.assertEqual(ok, not drift)
            self.assertEqual(runner.argv[0], str(source/'gsc/igsc.scm'))
            self.assertTrue(runner.argv[1].startswith('-:p1,'))
            self.assertIn('gsc/_prims.scm', result['inputs'])
            self.assertIn('gsi/main.scm', result['inputs'])
            self.assertTrue(result['interpretedSourceCompiler'])
            self.assertFalse(result['runtimeAdmitted'])

    def test_source_core_rejects_bootclean_that_leaves_generated_c(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source"
            for name in ("lib/_thread.scm", "lib/_thread.c", "gsc/gsc"):
                path = source / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"fixture")
            (source / "gsi").mkdir()
            runner = BuildStages(source, Path(directory), {})
            with patch("gambit_smp.locked_object.execute", return_value=(0, "", False, 0.1)) as execute:
                ok, result = rebuild_source_core(runner, source, 120)
            self.assertFalse(ok)
            self.assertEqual(["lib/_thread.c"], result["generatedCStillPresent"])
            self.assertEqual(1, execute.call_count)


if __name__ == "__main__":
    unittest.main()
