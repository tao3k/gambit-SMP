"""Conditional frame model context must not discharge native source obligations."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load, registry
from gambit_smp.framework import ROOT, digest

VIEW = "evidence/scenarios/concurrent-gc/ffi-select-frame.view.json"


class SelectFrameEvidenceTests(unittest.TestCase):
    def test_return_probe_non_hit_does_not_promote_failed_diagnostic(self):
        path = ROOT / "evidence/fixtures/darwin-ffi-return-premise/native-observation.json"
        record = json.loads(path.read_text())
        self.assertEqual(digest(ROOT / record["sourceLock"]), record["sourceLockSha256"])
        self.assertEqual(digest(ROOT / record["incident"]), record["incidentSha256"])
        self.assertEqual((0, 0), (record["entryAbsentHits"], record["returnAbsentHits"]))
        self.assertEqual((3, 1, 0), (record["stress"]["passed"], record["stress"]["failed"], record["stress"]["timeouts"]))
        self.assertEqual("DENY", record["stress"]["outcome"])
        self.assertTrue(record["diagnosticOnly"])
        self.assertFalse(record["fullStressAdmitted"])
        self.assertFalse(record["unchangedRetryAdmitted"])

    def test_abi_classification_matches_actual_fault_registers(self):
        record = json.loads((ROOT / "evidence/fixtures/darwin-ticket-ownership-acquire/incident-value-classification.json").read_text())
        for field in ("incident", "recipe", "fixture"):
            self.assertEqual(digest(ROOT / record[field]), record[field + "Sha256"])
        incident = json.loads((ROOT / record["incident"]).read_text())
        registers = next(row["registers"]["x"] for row in incident["threads"] if row["faulting"])
        self.assertEqual(record["returnAddress"]["captured"], registers[23] - (1 << 64))
        self.assertEqual(int(record["cResult"]["capturedHex"], 16), registers[21])
        self.assertFalse(record["crashCausalityEstablished"])

    def test_registered_view_binds_versioned_inputs_not_cache_authority(self):
        self.assertIn(VIEW, registry(ROOT)[0])
        _, facts, _, inputs = load(ROOT, VIEW)
        self.assertEqual(3, len(facts["obligation"]))
        self.assertFalse(any("/.data/" in name[len(str(ROOT)):] for name in inputs))

    def test_model_and_native_failure_coexist_with_all_requirements_open(self):
        document, facts, catalog, _ = load(ROOT, VIEW)
        with engine_api() as (engine, _):
            answer, _ = evaluate(engine, facts, catalog, document["queries"])
        self.assertEqual(3, len(answer["open"]))
        self.assertEqual(3, len(answer["models"]))
        self.assertEqual(4, len(answer["source_gaps"]))
        self.assertIn("NATIVE_DENY", {row[1] for row in answer["observed"]})

    def test_model_withdrawal_preserves_native_failure_and_source_requirements(self):
        document, facts, catalog, _ = load(ROOT, VIEW)
        changed = dict(facts, source=[row for row in facts["source"] if row[0] != "composition"])
        with engine_api() as (engine, _):
            answer, _ = evaluate(engine, changed, catalog, document["queries"])
        self.assertEqual([], answer["models"])
        self.assertEqual(3, len(answer["open"]))
        self.assertIn("NATIVE_DENY", {row[1] for row in answer["observed"]})

    def test_exact_model_import_recipe_and_unproved_conditions(self):
        record = json.loads((ROOT / "evidence/fixtures/darwin-ticket-ownership-acquire/ffi-select-relock-model.json").read_text())
        for field in ("source", "import", "recipe"):
            self.assertEqual(digest(ROOT / record[field]), record[field + "Sha256"])
        self.assertEqual(0, record["checks"][0]["queued"])
        self.assertTrue(all(row["accepted"] for row in record["checks"]))
        self.assertEqual(3, sum(row["negative"] for row in record["checks"]))
        self.assertTrue(record["unprovedConditions"])
        self.assertFalse(record["sourceRefinementAdmitted"])
        self.assertFalse(record["runtimeAdmitted"])
