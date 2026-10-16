"""Diagnostic transport only; debug objects do not qualify native execution."""
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import native_capabilities as native


class ObjectDebugTests(unittest.TestCase):
    def test_debug_selection_is_boolean_not_arbitrary_flags(self):
        base = {"source": {"step": "producer", "output": "runtime"}}
        for value in (True, False):
            native.validate_object({**base, "debugSymbols": value}, [])
        for value in (1, "-g", [], None):
            with self.assertRaises(ValueError):
                native.validate_object({**base, "debugSymbols": value}, [])

    def test_only_debug_metadata_is_added_to_configured_command(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "lib").mkdir()
            (root / "lib/_thread.c").write_text("int x;")
            for enabled in (False, True):
                commands = []
                ctx = SimpleNamespace(directory=root, tools={"make": "make"},
                    remaining=lambda: 10, require=lambda *args: commands.append(args) or "plan",
                    publish=lambda *args: {})
                argv = ["gcc", "-O1", "-c", "_thread.c"]
                with patch.object(native, "clone", return_value=root), \
                        patch.object(native, "compiler", return_value=Path("gcc")), \
                        patch("gambit_smp.gambit_build_primitives.command", return_value=argv):
                    result = native.object_build({"source": {}, "translationUnit": "lib/_thread.c",
                                                  "debugSymbols": enabled}, ctx)
                self.assertEqual(["gcc", "-O1", "-c", "_thread.c"] + (["-g"] if enabled else []), argv)
                self.assertEqual(enabled, result["debugSymbols"])
                self.assertEqual("configured-library-object-not-linked", result["claim"])
