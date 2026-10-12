from contextlib import contextmanager
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.ascent_program import assemble, evaluate, load_catalog, engine_api
from gambit_smp.framework import ROOT


class RuleSourceTests(unittest.TestCase):
    def test_native_catalogs_load_without_compiler_or_legacy_parser(self):
        with patch.dict(os.environ, {"PATH": "/unavailable", "GERBIL_PATH": "/unavailable"}), \
                patch("subprocess.Popen", side_effect=AssertionError("consumer ran a process")):
            catalog = load_catalog(ROOT / "evidence/catalog.ss", ROOT / "evidence/research-rules.ss")
        self.assertEqual(2, len(catalog["sourceTexts"]))
        self.assertEqual(2, len(catalog["sourceInputs"]))

    def test_missing_native_capability_fails_without_fallback(self):
        class OldEngine:
            def request(self, request):
                return {"operations": []}

        with self.assertRaisesRegex(ValueError, "lacks the upstream native DSL"):
            evaluate(OldEngine(), {}, load_catalog(ROOT / "evidence/catalog.ss"), {"answer": "has_model"})

    def test_rule_source_drift_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory, engine_api() as (engine, identities):
            source = Path(directory) / "catalog.ss"
            source.write_text("(ascent-fragment (relation input ((x symbol?))))")

            catalog = load_catalog(source)
            source.write_text(source.read_text() + "\n; replaced")
            with self.assertRaisesRegex(ValueError, "source generation changed"):
                evaluate(engine, {"input": []}, catalog, {"answer": "input"})

    def test_legacy_text_and_bool_as_integer_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "rule text is unsupported"):
            assemble({}, "output(X) <= input(X)", {"output": "output"})
        with engine_api() as (engine, _):
            catalog = engine.read_rules("(ascent-fragment (relation input ((x exact-integer?))))")
        with self.assertRaisesRegex(ValueError, "violates native relation type"):
            assemble({"input": [[True]]}, catalog, {"input": "input"})


if __name__ == "__main__":
    unittest.main()
