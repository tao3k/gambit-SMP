import contextlib
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp import cli
from gambit_smp.framework import ROOT, project_root


class CommandTests(unittest.TestCase):
    def test_dispatch_preserves_arguments_and_exit_status(self):
        original = sys.argv

        def run():
            self.assertEqual(sys.argv, ["gambit-smp verify", "--out", "some path", "--jobs", "2"])
            return 7

        with patch.object(cli, "import_module", return_value=SimpleNamespace(main=run)) as imported:
            self.assertEqual(7, cli.main(["verify", "--out", "some path", "--jobs", "2"]))
        imported.assert_called_once_with("gambit_smp.verify_protocols")
        self.assertIs(sys.argv, original)

    def test_failure_is_not_swallowed(self):
        original = sys.argv
        with patch.object(cli, "import_module", return_value=SimpleNamespace(main=lambda: sys.exit(3))):
            with self.assertRaises(SystemExit) as error:
                cli.main(["suite"])
        self.assertEqual(3, error.exception.code)
        self.assertIs(sys.argv, original)

    def test_unknown_command_and_invalid_root_do_not_import_an_adapter(self):
        with tempfile.TemporaryDirectory() as temporary:
            for args in (["unknown"], ["--root", temporary, "check"]):
                with self.subTest(args=args), contextlib.redirect_stderr(io.StringIO()):
                    with patch.object(cli, "import_module") as imported:
                        with self.assertRaises(SystemExit) as error:
                            cli.main(args)
                        self.assertEqual(2, error.exception.code)
                        imported.assert_not_called()

    def test_help_for_every_registered_adapter(self):
        for name in cli.COMMANDS:
            with self.subTest(command=name), contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaises(SystemExit) as error:
                    cli.main([name, "--help"])
                self.assertEqual(0, error.exception.code)

    def test_installed_module_works_outside_checkout(self):
        with tempfile.TemporaryDirectory() as temporary:
            env = dict(os.environ)
            env.pop("PYTHONPATH", None)
            env.pop("GAMBIT_SMP_ROOT", None)
            result = subprocess.run([sys.executable, "-m", "gambit_smp", "--root", str(ROOT),
                                     "evidence", "--help"], cwd=temporary, env=env,
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("--check", result.stdout)

    def test_explicit_root_cannot_fall_back_to_a_different_checkout(self):
        with tempfile.TemporaryDirectory() as temporary:
            with patch.dict(os.environ, {"GAMBIT_SMP_ROOT": temporary}):
                with self.assertRaisesRegex(ValueError, "checkout not found"):
                    project_root()

    def test_no_legacy_python_entrypoints_remain(self):
        self.assertFalse((ROOT / "tools").exists())


if __name__ == "__main__":
    unittest.main()
