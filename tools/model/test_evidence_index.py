import json
from pathlib import Path
import tempfile
import unittest

import evidence_index as index


class EvidenceTests(unittest.TestCase):
    def test_export_is_complete_portable_and_digest_bound(self):
        exported = index.export()
        self.assertEqual(25, len(exported["facts"]["pr"]))
        self.assertEqual(20, len(exported["facts"]["model"]))
        self.assertNotIn("/Users/", json.dumps(exported))
        self.assertNotIn("release_admitted", exported["facts"])
        self.assertGreater(len(exported["facts"]["frozen_negative"]), 20)

    def test_queries_expose_missing_evidence_and_recursive_dependencies(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts.update(pr=[[1, "head", "unknown"], [2, "head", "reported"]],
                     pr_model=[[2, "m"]], model=[["m", "hash", "repair"]],
                     dependency=[[1, 2], [2, 3]])
        rules = (index.ROOT / "evidence/rules.dl").read_text()
        result = index.query(facts, rules)
        self.assertEqual([(1,)], result["reports_without_models"])
        self.assertEqual([("m",)], result["models_without_native_adapters"])
        self.assertEqual([(1, 2), (1, 3), (2, 3)], result["dependency_closure"])
        facts["native_adapter"] = [["m", "fixture.scm"]]
        self.assertEqual([], index.query(facts, rules)["models_without_native_adapters"])

    def test_cyclic_dependency_is_rejected_before_engine_execution(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts["dependency"] = [[1, 2], [2, 1]]
        with self.assertRaisesRegex(ValueError, "cyclic PR dependency"):
            index.query(facts, "")

    def test_unknown_report_model_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            directory = root / "models/gambit"
            directory.mkdir(parents=True)
            (directory / "cases.json").write_text(json.dumps({"cases": []}))
            (directory / "report_catalog.json").write_text(json.dumps({"reports": [
                {"number": 1, "headRefOid": "head", "status": "unknown", "models": ["missing"]}]}))
            with self.assertRaisesRegex(ValueError, "unknown report model"):
                index.export(root)


if __name__ == "__main__":
    unittest.main()
