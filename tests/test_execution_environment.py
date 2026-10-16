"""Host identity transport is generic and never fabricated for a fixture."""
import unittest

from gambit_smp.host_environment import execution_environment


class ExecutionEnvironmentTests(unittest.TestCase):
    def test_real_inherited_identity_is_preserved_but_shell_controls_are_not(self):
        result = execution_environment("workspace", {"USER": "fixture-user", "USERNAME": "fixture-name",
            "HOME": "fixture-home", "PATH": "untrusted", "LD_PRELOAD": "inject", "PYTHONPATH": "inject"})
        self.assertEqual("fixture-user", result["USER"])
        self.assertEqual("fixture-name", result["USERNAME"])
        self.assertEqual("fixture-home", result["HOME"])
        self.assertEqual("/usr/bin:/bin", result["PATH"])
        self.assertNotIn("LD_PRELOAD", result)
        self.assertNotIn("PYTHONPATH", result)

    def test_missing_identity_is_not_invented(self):
        result = execution_environment("workspace", {})
        self.assertNotIn("USER", result)
        self.assertNotIn("USERNAME", result)

    def test_invalid_identity_is_not_passed_to_process(self):
        for value in ("", "bad\0identity", None, 4):
            with self.subTest(value=value):
                self.assertNotIn("USER", execution_environment("workspace", {"USER": value}))
