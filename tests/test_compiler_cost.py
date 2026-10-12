from pathlib import Path
import tempfile
import unittest

from gambit_smp.compiler_cost import EXECUTION_WITNESS, LOAD_PROBE, stage_accepted, phase_commands


class CompilerCostTests(unittest.TestCase):
    def test_clean_options_and_public_c_compilation_api(self):
        stages = phase_commands(Path("03-number/_num.scm"), Path("work"))
        self.assertTrue(all(options[0] == "-f" for _, _, options, _ in stages))
        self.assertIn('compile-file "probe.c"', stages[1][2][2])
        self.assertFalse(stage_accepted(0, False, "Unknown or improperly placed -f option ignored", None))

    def test_execution_uses_generated_linker_and_original_assertion_state(self):
        stages = phase_commands(Path("03-number/_num.scm"), Path("work"))
        self.assertEqual(stages[2][2], ["-f", "-e", LOAD_PROBE])
        self.assertIn('(##load "probe.o1" (lambda (script path) #f) #t #t "probe" #f)', LOAD_PROBE)
        self.assertIn("'phase-module-not-executed", LOAD_PROBE)
        self.assertIn("(eq? ##failed-test? #f)", LOAD_PROBE)
        self.assertNotIn("##tested-procs", LOAD_PROBE)

    def test_execution_rejects_missing_duplicate_and_failed_witness(self):
        self.assertFalse(stage_accepted(0, False, "", None, EXECUTION_WITNESS))
        self.assertTrue(stage_accepted(0, False, EXECUTION_WITNESS + "\n", None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(0, False, (EXECUTION_WITNESS + "\n") * 2, None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(2, False, EXECUTION_WITNESS, None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(0, True, EXECUTION_WITNESS, None, EXECUTION_WITNESS))
    def test_stage_needs_exit_zero_no_timeout_and_expected_artifact(self):
        with tempfile.TemporaryDirectory() as temporary:
            artifact = Path(temporary) / "module.o1"
            self.assertFalse(stage_accepted(0, False, "", artifact))
            artifact.write_bytes(b"module")
            self.assertTrue(stage_accepted(0, False, "", artifact))
            self.assertFalse(stage_accepted(1, False, "", artifact))
            self.assertFalse(stage_accepted(0, True, "", artifact))
            self.assertFalse(stage_accepted(0, False, "FAILED assertion", artifact))
            self.assertTrue(stage_accepted(0, False, "", None))
