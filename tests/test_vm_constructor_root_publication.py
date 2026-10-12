import json
import unittest

from gambit_smp.framework import ROOT
from gambit_smp import protocol_evidence as evidence
from gambit_smp.verify_protocols import load_manifest


class RootPublicationTests(unittest.TestCase):
    def test_controls_and_finite_protocol_check_are_source_bound(self):
        name = "evidence/fixtures/pstate-log-owned-rollback/root-publication-contract.json"
        manifest = load_manifest(ROOT / name)
        receipt = "evidence/model-results/fixtures/pstate-log-owned-rollback/root-publication-contract/receipt.json"
        rows = evidence.checked_rows(ROOT, manifest, ROOT / receipt)[0][1]
        self.assertEqual(5, len(rows))
        controls = {row["initializer"] for row in rows if row["variant"] == "old"}
        self.assertEqual({"initEarly", "initDeferred", "initUnchecked", "initSplit"}, controls)
        positive = next(row for row in rows if row["variant"] == "protocol")
        self.assertEqual(0, positive["exit"])
        self.assertEqual(32, positive["states"]["distinct"])
        self.assertEqual(0, positive["states"]["queued"])
        self.assertIn("vm_constructor_root_publication_source", manifest["cases"][0]["openObligations"])

    def test_count_only_deferral_has_a_real_missing_root_counterexample(self):
        directory = ROOT / "evidence/model-results/fixtures/pstate-log-owned-rollback/root-publication-contract"
        trace = json.loads((directory /
            "vm_constructor_root_publication-old-rootCoverageSafe.trace.json").read_text())
        state = trace["states"][-1]["publication"]
        self.assertEqual("running", state["phase"])
        self.assertTrue(state["ready"])
        self.assertEqual(1, state["count"])
        globals_ = set(state["globals"]["$integerSet"])
        roots = set(state["roots"]["$integerSet"])
        self.assertTrue(globals_ - roots)
