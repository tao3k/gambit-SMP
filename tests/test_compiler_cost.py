from pathlib import Path
import tempfile
import unittest

from gambit_smp.compiler_cost import stage_accepted, phase_commands


class CompilerCostTests(unittest.TestCase):
    def test_clean_options_and_public_c_compilation_api(self):
        stages = phase_commands(Path("03-number/_num.scm"), Path("work"))
        self.assertTrue(all(options[0] == "-f" for _, _, options, _ in stages))
        self.assertIn('compile-file "probe.c"', stages[1][2][2])
        self.assertFalse(stage_accepted(0, False, "Unknown or improperly placed -f option ignored", None))
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
