"""Composed GC evidence remains separate from native source qualification."""
import json
import unittest

from gambit_smp.ascent_program import engine_api, evaluate
from gambit_smp.evidence_views import load, registry
from gambit_smp.framework import ROOT, digest

VIEW = "evidence/scenarios/concurrent-gc/btq-copy-epochs.view.json"


class CopyEpochEvidenceTests(unittest.TestCase):
    def test_movable_queue_result_checks_color_and_container_not_boolean_only(self):
        result = json.loads((ROOT / "evidence/source-results/compiled-stress-failure/queue-relocation-model.json").read_text())
        for key in ("source", "import", "recipe", "sourceLock", "nativeFailure"):
            self.assertEqual(result[key + "Sha256"], digest(ROOT / result[key]))
        self.assertTrue(all(row["accepted"] for row in result["checks"]))
        self.assertEqual(0, result["checks"][0]["queued"])
        controls = {row["initializer"] for row in result["checks"] if row["negative"]}
        self.assertEqual(7, len(controls))
        self.assertTrue({"initMissingColor", "initMissingContainer"} <= controls)
        self.assertEqual("current queue reference", result["representation"]["black"])
        self.assertEqual("false", result["representation"]["red"])
        for key in ("runtimeAdmitted", "sourceRefinementAdmitted", "performanceAdmitted", "unchangedNativeRetryAdmitted"):
            self.assertFalse(result[key])

    def test_incident_classification_matches_captured_words_not_a_guessed_object(self):
        result = json.loads((ROOT / "evidence/fixtures/darwin-ffi-return-premise/btq-value-classification.json").read_text())
        for key in ("source", "recipe", "sourceLock", "incident"):
            self.assertEqual(result[key + "Sha256"], digest(ROOT / result[key]))
        crash = json.loads((ROOT / result["incident"]).read_text())
        registers = next(row["registers"]["x"] for row in crash["threads"] if row["faulting"])
        self.assertEqual(int(result["siblingWordHex"], 16), registers[0])
        self.assertEqual(int(result["childWordHex"], 16), registers[2])
        self.assertEqual(registers[2] & 7, result["childTag"])
        recipe = json.loads((ROOT / result["recipe"]).read_text())
        project = next(row for row in recipe["steps"] if row["id"] == "project")
        fixture = next(row for row in project["arguments"]["files"] if row["target"] == "values.c")
        self.assertEqual(result["sourceSha256"], fixture["sha256"])
        for key in ("causeEstablished", "runtimeAdmitted", "sourceRefinementAdmitted",
                    "pidBoundToNativeReceipt", "unchangedNativeRetryAdmitted"):
            self.assertFalse(result[key])

    def test_model_result_binds_reproducible_inputs_and_all_controls(self):
        result = json.loads((ROOT / "evidence/source-results/compiled-stress-failure/copy-epochs-model.json").read_text())
        for key in ("source", "import", "recipe", "sourceLock", "nativeFailure"):
            self.assertEqual(result[key + "Sha256"], digest(ROOT / result[key]))
        self.assertTrue(all(row["accepted"] for row in result["checks"]))
        self.assertEqual(5, sum(row["negative"] for row in result["checks"]))
        self.assertEqual(0, result["checks"][0]["queued"])
        for field in ("runtimeAdmitted", "sourceRefinementAdmitted", "performanceAdmitted", "unchangedNativeRetryAdmitted"):
            self.assertFalse(result[field])

    def test_source_gaps_and_native_failure_survive_model_withdrawal(self):
        self.assertIn(VIEW, registry(ROOT)[0])
        document, facts, catalog, inputs = load(ROOT, VIEW)
        self.assertFalse(any("/.data/" in path[len(str(ROOT)):] for path in inputs))
        with engine_api() as (engine, _):
            before = evaluate(engine, facts, catalog, document["queries"])[0]
            model_sources = {row[2] for row in facts["model"]}
            withdrawn = dict(facts, source=[row for row in facts["source"] if row[0] not in model_sources])
            after = evaluate(engine, withdrawn, catalog, document["queries"])[0]
        self.assertTrue(before["models"])
        self.assertEqual([], after["models"])
        self.assertEqual(before["open"], after["open"])
        self.assertEqual(before["source_gaps"], after["source_gaps"])
        self.assertIn("NATIVE_DENY", {row[1] for row in after["observed"]})

    def test_cell_encoding_is_injective_for_the_declared_projection(self):
        addresses = [base + actor * 1024 + slot * 256 + 1
                     for base in (0, 32768) for actor in (0, 1) for slot in (1, 2)]
        offsets = (0, 4, 5, 6, 7, 17)
        encoded = {address * 32 + offset for address in addresses for offset in offsets}
        self.assertEqual(len(addresses) * len(offsets), len(encoded))
        self.assertTrue(encoded.isdisjoint({0, 1}))
