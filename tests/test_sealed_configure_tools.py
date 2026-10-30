import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.native_capabilities import configure_tool_bindings, host_tools
from gambit_smp.recipes import prior_tool_observation


class SealedConfigureToolsTests(unittest.TestCase):
    def test_known_preflight_absence_preserves_unknown_tools_without_native_credit(self):
        receipt = {"schema": "evidence-recipe-run.v1", "outcome": "DENY", "steps": [],
                   "error": "required native tool missing: aclocal"}
        self.assertIsNone(prior_tool_observation(Path("/unused"), receipt))
        for change in ({"steps": [{"id": "seed", "outcome": "FAIL"}]},
                       {"outcome": "PASS"}, {"error": "unclassified native failure"}):
            with self.assertRaisesRegex(ValueError, "missing prior tool observation"):
                prior_tool_observation(Path("/unused"), {**receipt, **change})

    def test_selected_executable_is_recovered_without_caller_path(self):
        with tempfile.TemporaryDirectory() as directory:
            tool = Path(directory) / "autoconf"
            tool.write_bytes(b"#!/bin/sh\nexit 0\n")
            tool.chmod(0o755)
            row = {"path": str(tool), "sha256": hashlib.sha256(tool.read_bytes()).hexdigest()}
            self.assertEqual(configure_tool_bindings({"autoconf": row}), {"autoconf": tool.resolve()})
            self.assertEqual(configure_tool_bindings({}), {})

    def test_configure_can_resolve_sealed_tools_when_sanitized_path_cannot(self):
        with tempfile.TemporaryDirectory() as directory:
            bindings = {}
            for name in ("aclocal", "autoconf"):
                tool = Path(directory) / name
                tool.write_bytes(b"#!/bin/sh\nexit 0\n")
                tool.chmod(0o755)
                bindings[name] = {"path": str(tool), "sha256": hashlib.sha256(tool.read_bytes()).hexdigest()}
            find = lambda name, **kwargs: None if name in bindings else "/usr/bin/true"
            with patch("gambit_smp.native_capabilities.sys.platform", "linux"), \
                    patch("gambit_smp.native_capabilities.shutil.which", side_effect=find):
                with self.assertRaisesRegex(ValueError, "required native tool missing"):
                    host_tools(Path("/usr/bin/true"), [{"capability": "gambit.configure"}], {"PATH": "/usr/bin:/bin"})
                tools, environment = host_tools(Path("/usr/bin/true"), [{"capability": "gambit.configure"}],
                    {"PATH": "/usr/bin:/bin"}, configure_bindings=bindings)
            self.assertEqual(tools["autoconf"], Path(bindings["autoconf"]["path"]).resolve())
            self.assertIn(str(Path(directory).resolve()), environment["PATH"].split(":"))

    def test_changed_or_non_executable_tool_cannot_inherit_a_seal(self):
        with tempfile.TemporaryDirectory() as directory:
            tool = Path(directory) / "aclocal"
            tool.write_bytes(b"original")
            tool.chmod(0o755)
            row = {"path": str(tool), "sha256": hashlib.sha256(tool.read_bytes()).hexdigest()}
            tool.write_bytes(b"replacement")
            with self.assertRaisesRegex(ValueError, "sealed configure tool drift"):
                configure_tool_bindings({"aclocal": row})
            row["sha256"] = hashlib.sha256(tool.read_bytes()).hexdigest()
            tool.chmod(0o644)
            with self.assertRaisesRegex(ValueError, "sealed configure tool drift"):
                configure_tool_bindings({"aclocal": row})
