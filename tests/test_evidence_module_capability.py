import copy
import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import evidence_capabilities as capability


class EvidenceModuleContractTests(unittest.TestCase):
    def entry(self):
        return {"schema": "ascent.evidence-module-entry.v1", "module": ":example/evidence",
                "constructor": "make-evidence", "arguments": [], "sourceSha256": "0" * 64}

    def test_module_entry_and_exact_recorded_partition(self):
        args = {"module": "evidence/module.json", "queries": {"ok": "complete", "value": "native_value"},
                "expected": {"ok": [[True]]}, "recordedQueries": ["value"]}
        capability.validate(args, ["evidence/module.json"])
        self.assertEqual(capability.module_entry(self.entry()), self.entry())
        for change in ({"recordedQueries": []}, {"recordedQueries": ["ok", "value"]},
                       {"recordedQueries": ["value", "value"]}, {"rules": ["evidence/rules.ss"]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                capability.validate(dict(args, **change), ["evidence/module.json"])

    def test_no_scripts_handlers_or_missing_module_identity(self):
        for change in ({"schema": "other"}, {"sourceSha256": "g" * 64}, {"arguments": "eval"},
                       {"module": "script.py"}, {"handler": "eval"}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                capability.module_entry(dict(self.entry(), **change))
        with self.assertRaises(ValueError):
            capability.validate({"module": "producer.py", "queries": {"x": "x"}, "expected": {"x": []}},
                                ["producer.py"])

    def test_compiled_module_source_must_match_real_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "module.ss"
            source.write_text("(export constructor)\n")
            entry = dict(self.entry(), sourceSha256=hashlib.sha256(source.read_bytes()).hexdigest())
            build = {"producerBuild": {"linkedSchemeSources": {"example/evidence": {
                "path": str(source), "sha256": entry["sourceSha256"]}}}}
            self.assertEqual(capability.module_source(entry, build), source)
            wrong = copy.deepcopy(build)
            wrong["producerBuild"]["linkedSchemeSources"]["example/evidence"]["sha256"] = "0" * 64
            with self.assertRaisesRegex(ValueError, "compiled producer"):
                capability.module_source(entry, wrong)
            source.write_text("changed\n")
            with self.assertRaisesRegex(ValueError, "source changed"):
                capability.module_source(entry, build)

    def test_native_graph_is_recorded_without_scalar_admission(self):
        args = {"module": "evidence/module.json", "queries": {"ok": "ok", "graph": "graph"},
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
