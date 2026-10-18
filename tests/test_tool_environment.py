"""Environment transport controls; no inference, installation or shell eval."""
import copy
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import tool_environment as tool
from gambit_smp.process_observation import Observation


class ToolEnvironmentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.manager = self.root / "opam manager"
        self.manager.write_bytes(b"manager fixture")
        self.manager.chmod(0o700)
        self.binary = self.root / "bin" / "caller-tool"
        self.binary.parent.mkdir()
        self.binary.write_bytes(b"tool fixture")
        self.binary.chmod(0o700)
        self.request = {"schema": "opam-tool-discovery.v1", "switch": "caller switch",
                        "tool": "caller-tool", "versionArguments": ["--version"], "variables": []}

    def response(self, stdout, code=0, timeout=False):
        return Observation(stdout, "", code, timeout, .01, 123, "start", "end", True)

    def test_switch_is_explicit_and_no_parent_environment_or_shell_is_modified(self):
        before = dict(os.environ)
        env = {"PATH": "/usr/bin:/bin", "OPAMSWITCH": "wrong"}
        replies = [self.response("2.6"), self.response(str(self.binary.parent)), self.response("1.0")]
        with patch.object(tool, "capture", side_effect=replies) as run:
            row = tool.observe(self.request, cwd=self.root, environment=env, opam=self.manager)
        self.assertTrue(row["complete"])
        self.assertTrue(row["identityStable"])
        self.assertEqual(row["launchPrefix"], [str(self.manager), "exec", "--switch=caller switch", "--set-switch", "--", str(self.binary)])
        self.assertEqual(env["OPAMSWITCH"], "wrong")
        self.assertEqual(dict(os.environ), before)
        self.assertTrue(all(isinstance(call.args[0], list) for call in run.call_args_list))
        self.assertFalse(row["modelExecuted"])
        self.assertFalse(row["executionAuthorized"])

    def test_missing_manager_or_failed_probe_is_recorded_not_fallback(self):
        with patch.object(tool.shutil, "which", return_value=None):
            row = tool.observe(self.request, cwd=self.root)
        self.assertFalse(row["complete"])
        self.assertEqual(row["probes"], [])
        with patch.object(tool, "capture", return_value=self.response("", code=99)) as run:
            row = tool.observe(self.request, cwd=self.root, opam=self.manager)
        self.assertFalse(row["complete"])
        self.assertEqual(row["probes"][0]["exit"], 99)
        self.assertEqual(run.call_count, 1)

    def test_timeout_and_drift_do_not_publish_success(self):
        replies = [self.response("2.6"), self.response(str(self.binary.parent)), self.response("", timeout=True)]
        with patch.object(tool, "capture", side_effect=replies):
            self.assertFalse(tool.observe(self.request, cwd=self.root, opam=self.manager)["complete"])
        def probe(argv, *args):
            if "exec" in argv:
                self.binary.write_bytes(b"changed")
                return self.response("1.0")
            return self.response(str(self.binary.parent) if "var" in argv else "2.6")
        with patch.object(tool, "capture", side_effect=probe):
            row = tool.observe(self.request, cwd=self.root, opam=self.manager)
        self.assertFalse(row["complete"])
        self.assertFalse(row["identityStable"])

    def test_read_only_variables_and_executable_names_do_not_accept_shell_commands(self):
        for changes in ({"tool": "herd7; touch file"}, {"tool": "/bin/sh"},
                        {"switch": "bad\0switch"}, {"variables": ["PATH=/tmp"]},
                        {"variables": ["bin", "bin"]}, {"variables": [[]]},
                        {"versionArguments": []}, {"versionArguments": ["-c", "touch file"]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                tool.declaration(dict(copy.deepcopy(self.request), **changes))
        self.assertEqual(tool.declaration(self.request), self.request)


if __name__ == "__main__":
    unittest.main()
