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
    def test_native_run_returns_receipt_without_evaluating_the_evidence_catalog(self):
        from gambit_smp.task_entry import present_observation
        value={'recipe':'native-request','outcome':'DENY','runtimeAdmitted':False}
        seen=[]
        adapter=SimpleNamespace(main=lambda: seen.append(present_observation(value)) or 2)
        with patch.object(cli,'import_module',return_value=adapter), \
                patch('gambit_smp.trajectory_exploration.repository_clues') as query:
            self.assertEqual(2,cli.main(['research','--run','selected.recipe.json']))
        query.assert_not_called()
        self.assertIs(seen[0],value)

    def test_read_presentation_is_dispatcher_owned_and_does_not_leak_to_workers(self):
        from gambit_smp.task_entry import present_observation
        value = {'recipe': 'declared-recipe', 'outcome': 'DENY'}
        packet = {'brief': {'families': []}, 'checkpoint': 'source-bound-token'}
        seen = []
        adapter = SimpleNamespace(main=lambda: seen.append(present_observation(value)) or 0,
                                  execution_policy=lambda argv: 'read')
        with patch.object(cli, 'import_module', return_value=adapter), \
                patch('gambit_smp.trajectory_exploration.repository_clues', return_value=packet) as query, \
                patch('gambit_smp.workspace.execution_scope') as native:
            self.assertEqual(0, cli.main(['research', '--read', 'retained-run']))
        native.assert_not_called()
        self.assertEqual(query.call_args.kwargs['bindings'], [['recipe', 'declared-recipe']])
        self.assertEqual(seen[0]['evidence'], packet)
        self.assertEqual(seen[0]['outcome'], 'DENY')
        self.assertIs(present_observation(value), value)
        self.assertNotIn('evidence', value)

    def setUp(self):
        # Dispatcher mocks run in their own real campaign, never production state.
        from gambit_smp import workspace
        temporary=tempfile.TemporaryDirectory();self.addCleanup(temporary.cleanup)
        root=Path(temporary.name).resolve()
        workspace.git(root,'init','-q')
        workspace.git(root,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','--allow-empty','-qm','test')
        workspace.start(root,'cli-test',adopt=True)
        for manager in [patch('gambit_smp.framework.project_root',return_value=root),
                        patch('gambit_smp.task_dependencies.default_task',return_value='cli-test')]:
            manager.start();self.addCleanup(manager.stop)

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

    def test_declared_reads_do_not_collect_or_take_execution_custody(self):
        adapter = SimpleNamespace(main=lambda: 0, execution_policy=lambda argv: "read")
        with patch.object(cli, "import_module", return_value=adapter), \
                patch("gambit_smp.workspace.execution_scope") as scope, \
                patch("gambit_smp.workspace.collect") as collect, \
                patch("gambit_smp.task_dependencies.default_task", return_value=None):
            self.assertEqual(0, cli.main(["trajectory", "clues", "((questions (\"unknown\")))"]))
        scope.assert_not_called()
        collect.assert_not_called()

    def test_trajectory_effects_are_parser_owned_and_fail_closed(self):
        from gambit_smp.trajectory_exploration import execution_policy
        self.assertEqual("read", execution_policy(["clues", "() "]))
        self.assertEqual("read", execution_policy(["catalog"]))
        self.assertEqual("journal", execution_policy(["submit", "--request", "hypothesis.json"]))
        self.assertEqual("journal", execution_policy(["submit", "hypothesis.ss"]))
        self.assertEqual("task", execution_policy(["record", "--request", "observation.json"]))
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            execution_policy(["clues", "()", "--execute"])
        from gambit_smp.research_kernel import execution_policy as research_policy
        self.assertEqual("read", research_policy(["--read", "retained-run", "--step", "core"]))
        self.assertEqual("task", research_policy(["--run", "recipe"]))
        self.assertEqual("task", research_policy(["--read", "retained-run", "--out", "outputs"]))

    def test_hypothesis_journal_does_not_take_execution_custody(self):
        adapter = SimpleNamespace(main=lambda: 0, execution_policy=lambda argv: "journal")
        with patch.object(cli, "import_module", return_value=adapter), \
                patch("gambit_smp.workspace.execution_scope") as scope, \
                patch("gambit_smp.workspace.collect") as collect:
            self.assertEqual(0, cli.main(["trajectory", "submit", "hypothesis.ss"]))
        scope.assert_not_called()
        collect.assert_not_called()

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
