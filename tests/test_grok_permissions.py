import tempfile
import unittest
from pathlib import Path

from gambit_smp.grok_permissions import permission_decision


class PermissionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        (self.root / "dev").mkdir()
        (self.root / "tests").mkdir()
        self.profile = {"task": "task", "read": [str(self.root / "dev") + "/**"],
                        "edit": [str(self.root / "dev") + "/**"],
                        "commands": ["trajectory", "research"]}
        self.options = [{"kind": "allow_once", "optionId": "yes"},
                        {"kind": "reject_once", "optionId": "no"}]

    def call(self, name, raw, *, session="session", declared=None, profile=None):
        meta = {"x.ai/tool": {"name": name, "input": {}},
                "x.ai/requestingSessionId": session}
        if declared is not None:
            meta["x.ai/tool"]["input"]["path"] = declared
        params = {"sessionId": "session", "toolCall": {"_meta": meta, "rawInput": raw}, "options": self.options}
        return permission_decision(params, root=self.root, session="session",
                                   profile=profile or self.profile, evidence_read=None, script_grants=set())

    def test_allowed_edit_and_forbidden_path(self):
        good = str(self.root / "dev/allowed.txt")
        bad = str(self.root / "tests/forbidden.txt")
        self.assertEqual("yes", self.call("write", {"file_path": good}, declared=good))
        self.assertEqual("no", self.call("write", {"file_path": bad}, declared=bad))
        self.assertEqual("no", self.call("write", {"file_path": good}, declared=bad))
        self.assertEqual("no", self.call("write", {"file_path": good}, session="other"))
        self.assertEqual("yes", self.call("read_file", {"target_file": good}, declared=good))
        self.assertEqual("yes", self.call("list_dir", {"target_directory": str(self.root / "dev")}, declared=str(self.root / "dev")))

    def test_escape_and_private_journal_are_rejected(self):
        (self.root / "dev/link").symlink_to(self.root / "tests", target_is_directory=True)
        self.assertEqual("no", self.call("write", {"file_path": str(self.root / "dev/link/file")}))
        self.assertEqual("no", self.call("write", {"file_path": str(self.root / "dev/../tests/file")}))
        self.assertEqual("no", self.call("read_file", {"file_path": str(self.root / "dev/grok-runs/events")}))

    def test_registered_command_and_shell_escapes(self):
        prefix = ".venv/bin/gambit-smp --task task"
        self.assertEqual("yes", self.call("run_terminal_cmd", {"command": prefix + " research --help"}))
        self.assertEqual("yes", self.call("run_terminal_command", {"command": prefix + " research --help"}))
        for suffix in ("research --help; touch x", "research $(touch x)", "research --help > x",
                       "research --help && touch x"):
            self.assertEqual("no", self.call("run_terminal_cmd", {"command": prefix + " " + suffix}))
        self.assertEqual("no", self.call("run_terminal_cmd", {"command": prefix + " workspace run x"}))
        self.assertEqual("no", self.call("run_terminal_cmd", {"command": prefix.replace("task", "other") + " research"}))

    def test_single_star_never_grants_nested_path(self):
        profile = dict(self.profile, read=[str(self.root / "dev/*")])
        self.assertEqual("no", self.call("read_file", {"file_path": str(self.root / "dev/a/secret")}, profile=profile))


if __name__ == "__main__":
    unittest.main()
