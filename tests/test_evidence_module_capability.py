import copy
import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import evidence_capabilities as capability


class EvidenceModuleContractTests(unittest.TestCase):
    def entry(self):
        return {"schema": "ascent.evidence-dsl-entry.v1", "trusted": True,
                "constructor": "make-evidence", "arguments": [],
                "sources": [{"path": "module.ss", "sha256": "0" * 64}]}

    def test_module_entry_and_exact_recorded_partition(self):
        args = {"dsl": "evidence/module.json", "queries": {"ok": "complete", "value": "native_value"},
                "expected": {"ok": [[True]]}, "recordedQueries": ["value"]}
        capability.validate(args, ["evidence/module.json"])
        self.assertEqual(capability.dsl_entry(self.entry()), self.entry())
        for change in ({"recordedQueries": []}, {"recordedQueries": ["ok", "value"]},
                       {"recordedQueries": ["value", "value"]}, {"rules": ["evidence/rules.ss"]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                capability.validate(dict(args, **change), ["evidence/module.json"])

    def test_no_scripts_handlers_or_missing_module_identity(self):
        for change in ({"schema": "other"}, {"sources": [{"path": "module.ss", "sha256": "g" * 64}]},
                       {"arguments": "eval"}, {"module": "script.py"}, {"handler": "eval"}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                capability.dsl_entry(dict(self.entry(), **change))
        with self.assertRaises(ValueError):
            capability.validate({"module": "producer.py", "queries": {"x": "x"}, "expected": {"x": []}},
                                ["producer.py"])

    def test_declarative_source_must_match_real_bytes_and_complete_inventory(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "module.ss"
            source.write_text("(define-evidence (make-evidence) (sources input) (outputs input) (relation input (x)))\n")
            entry = dict(self.entry(), sources=[{"path": "module.ss", "sha256": hashlib.sha256(source.read_bytes()).hexdigest()}])
            self.assertEqual(capability.dsl_sources(entry, Path(directory)), [source.resolve()])
            wrong = copy.deepcopy(entry)
            wrong['sources'][0]['sha256'] = '0' * 64
            with self.assertRaisesRegex(ValueError, "source changed"):
                capability.dsl_sources(wrong, Path(directory))
            with self.assertRaises(ValueError):
                capability.dsl_entry(dict(entry, sources=entry['sources'] * 2))
            source.write_text("changed\n")
            with self.assertRaisesRegex(ValueError, "source changed"):
                capability.dsl_sources(entry, Path(directory))

    def test_native_graph_is_recorded_without_scalar_admission(self):
        args = {"dsl": "evidence/module.json", "queries": {"ok": "ok", "graph": "graph"},
                "expected": {"ok": [[True]]}, "recordedQueries": ["graph"]}
        context = type("Context", (), {"receipt": {"steps": []}})()
        native = {"ok": [[True]], "graph": {"value": {"format": "native-value-graph.v1"}}}
        with patch.object(capability, "evaluate_observations", return_value=native):
            result = capability.evaluate(args, context)
        self.assertEqual(result["answers"]["graph"], native["graph"])
        self.assertEqual(result["recordedOnlyQueries"], ["graph"])
        self.assertFalse(result["runtimeAdmitted"])
        with patch.object(capability, "evaluate_observations", return_value={"ok": {}, "graph": {}}):
            with self.assertRaisesRegex(ValueError, "exact inventory"):
                capability.evaluate(args, context)

    def test_component_entry_binds_separate_manifest_and_exact_assets(self):
        import json
        root = Path(__file__).resolve().parents[1]
        entry = json.loads((root / 'tests/fixtures/components/entry.json').read_text())
        self.assertEqual(capability.dsl_entry(entry), entry)
        paths = capability.dsl_sources(entry, root)
        self.assertEqual(len(paths), len(entry['sources']) + 1)
        for change in ({'trusted': False}, {'entry': ''}, {'sources': entry['sources'] * 2},
                       {'manifest': {'path': '../escape.json', 'sha256': '0' * 64}}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                capability.dsl_entry(dict(entry, **change))


if __name__ == "__main__":
    unittest.main()
