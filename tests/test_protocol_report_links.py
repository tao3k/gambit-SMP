import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.ascent_program import load_catalog
from gambit_smp import evidence_index as index
from gambit_smp import protocol_evidence as evidence
from gambit_smp.framework import digest


class ProtocolReportLinkTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "evidence").mkdir()
        self.snapshot = self.root / "evidence/snapshot.json"
        self.head, self.model_sha = "b" * 40, "a" * 64
        self.snapshot.write_text(json.dumps({"number": 1035, "head": self.head}))
        self.manifest = {"contextInputs": {"cache/pr.json": digest(self.snapshot)},
                         "cases": [{"id": "slice"}]}
        (self.root / "evidence/manifest.json").write_text(json.dumps(self.manifest))
        self.link = {"model": "slice", "modelSha256": self.model_sha, "report": 1035,
                     "head": self.head, "snapshot": "evidence/snapshot.json",
                     "snapshotSha256": digest(self.snapshot), "contextInput": "cache/pr.json"}
        self.links = {"schema": "gambit-protocol-report-links.v1", "links": [self.link]}
        self.patcher = patch.object(evidence, "BUNDLES", (("evidence/manifest.json", "unused"),))
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def run_links(self):
        (self.root / "evidence/protocol-report-links.json").write_text(json.dumps(self.links))
        return evidence.report_links(self.root, {"slice": self.model_sha})

    def test_exact_model_snapshot_and_context_are_bound(self):
        rows, inputs = self.run_links()
        self.assertEqual([("slice", 1035, self.head, digest(self.snapshot))], rows)
        self.assertIn("evidence/protocol-report-links.json", inputs)
        self.assertEqual(digest(self.snapshot), inputs["evidence/snapshot.json"])

    def test_missing_or_unknown_model_does_not_bypass_identity(self):
        self.link["model"] = "unregistered"
        with self.assertRaisesRegex(ValueError, "unknown"):
            self.run_links()

    def test_changed_model_requires_a_new_review(self):
        self.link["modelSha256"] = "c" * 64
        with self.assertRaisesRegex(ValueError, "changed model"):
            self.run_links()

    def test_changed_report_head_cannot_reuse_the_link(self):
        self.link["head"] = "c" * 40
        with self.assertRaisesRegex(ValueError, "head differs"):
            self.run_links()

    def test_snapshot_bytes_and_model_context_cannot_be_substituted(self):
        self.link["snapshotSha256"] = "c" * 64
        with self.assertRaisesRegex(ValueError, "snapshot changed"):
            self.run_links()
        self.link["snapshotSha256"] = digest(self.snapshot)
        self.link["contextInput"] = "cache/unbound.json"
        with self.assertRaisesRegex(ValueError, "does not bind"):
            self.run_links()

    def test_duplicate_and_traversing_links_are_rejected(self):
        self.links["links"].append(dict(self.link))
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.run_links()
        self.links["links"].pop()
        self.link["snapshot"] = "../snapshot.json"
        with self.assertRaises(ValueError):
            self.run_links()

    def test_coverage_link_is_not_a_model_check_or_native_admission(self):
        self.patcher.stop()
        facts = {name: [] for name in index.export()["facts"]}
        facts["pr"] = [(1035, self.head, "open")]
        facts["report_kind"] = [(1035, "runtime-repair")]
        facts["protocol_model"] = [("slice", self.model_sha)]
        facts["protocol_report"] = [("slice", 1035, self.head, "snapshot")]
        rules = load_catalog(index.ROOT / "evidence/catalog.ss")
        result = index.query(facts, rules)
        self.assertEqual([], result["reports_without_models"])
        self.assertEqual([(1035, "slice")], result["protocol_reports_without_checks"])
        self.assertEqual([("slice",)], result["protocol_extensions_without_checks"])
        self.assertNotIn("runtime_admitted", result)


if __name__ == "__main__":
    unittest.main()
