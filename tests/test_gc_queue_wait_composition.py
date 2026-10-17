from copy import deepcopy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import evidence_index as index
from gambit_smp import check_gambit as checker
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify


class GCQueueWaitCompositionTests(unittest.TestCase):
    def setUp(self):
        self.case = verify.load_manifest(
            index.ROOT / "evidence/gc-queue-wait-composition.json"
        )["cases"][0]

    def test_controls_separate_notification_count_and_producer_lifetime(self):
        self.assertEqual([
            ("old", "notificationSafe", "initOld"),
            ("old", "restoreSafe", "initNoRestore"),
            ("old", "producerLifetimeSafe", "initEarlyIdle"),
            ("protocol", "sourceSafe", "initSource"),
            ("protocol", "combinedSafe", "initCombined"),
        ], verify.model_checks(self.case))
        self.assertEqual("characterization", self.case["mode"])
        self.assertEqual("progress", self.case["temporal"])

    def test_partition_mapping_rejects_unknown_or_invalid_initializers(self):
        for mapping in ({"missingSafe": "initSource"},
                        {"sourceSafe": ""}, {"sourceSafe": 42}, []):
            broken = deepcopy(self.case)
            broken["protocolInitializers"] = mapping
            with self.assertRaisesRegex(ValueError, "initializer mapping"):
                verify.model_checks(broken)

    def test_receipt_requires_both_partitions_and_exact_initializers(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "receipt.json"
            rows = [{"case": self.case["id"], "variant": variant,
                     "invariant": invariant, "initializer": initializer,
                     "accepted": True, "evidence": "finite-state-TLC",
                     "modelSha256": "digest"}
                    for variant, invariant, initializer in verify.model_checks(self.case)]
            with patch.object(checker, "digest", return_value="digest"):
                path.write_text(json.dumps({"results": rows}))
                self.assertEqual(5, len(checker.reuse_model_receipt(path, self.case)))
                for bad in (rows[:-1], rows[:-1] + [rows[-2]],
                            rows[:-1] + [{**rows[-1], "initializer": "initSource"}],
                            rows[:-1] + [{**rows[-1], "accepted": False}]):
                    path.write_text(json.dumps({"results": bad}))
                    with self.assertRaisesRegex(ValueError, "missing admission"):
                        checker.reuse_model_receipt(path, self.case)

    def test_open_source_memory_resize_and_unbounded_contracts_are_retained(self):
        self.assertEqual({"gc_wait_notification", "gc_wait_count_restore",
                          "gc_notification_lock_order", "eager_tail_scan_partition",
                          "eager_chain_work_closure"}, set(self.case["composes"]))
        for obligation in ("gc_notification_source_repair",
                           "gc_arbitrary_queue_graph_composition",
                           "gc_copy_queue_memory_order",
                           "gc_queue_wait_resize_composition",
                           "gc_queue_wait_source_refinement",
                           "gc_unbounded_spurious_wake_fairness"):
            self.assertIn(obligation, self.case["openObligations"])
        self.assertIn("not deadlock", self.case["scope"])
        self.assertIn("native acceptance", self.case["scope"])

    def test_pending_composition_is_exported_without_inventing_a_receipt(self):
        facts, inputs = evidence.bundle_facts(
            index.ROOT, "evidence/gc-queue-wait-composition.json",
            "evidence/model-results/gc-queue-wait-composition/absent-receipt.json",
        )
        self.assertEqual([self.case["id"]], [row[0] for row in facts["protocol_model"]])
        self.assertEqual([], facts["protocol_checked"])
        self.assertIn((self.case["id"], "gc_queue_wait_source_refinement"),
                      facts["protocol_obligation"])
        self.assertIn("models/gambit/gc_queue_wait_composition.qnt", inputs)

    def test_published_partition_receipt_closes_only_bounded_model_gate(self):
        facts, _ = evidence.bundle_facts(
            index.ROOT, "evidence/gc-queue-wait-composition.json",
            "evidence/model-results/gc-queue-wait-composition/receipt.json",
        )
        manifest = verify.load_manifest(index.ROOT / "evidence/gc-queue-wait-composition.json")
        missing = [name for name in manifest["contextInputs"] if not (index.ROOT / name).is_file()]
        self.assertEqual([] if missing else [self.case["id"]],
                         [row[0] for row in facts["protocol_checked"]])
        self.assertIn((self.case["id"], "gc_queue_wait_source_refinement"),
                      facts["protocol_obligation"])
        self.assertNotIn("native_observation", facts)

    def test_partial_or_denied_campaign_does_not_close_model_gate(self):
        manifest = verify.load_manifest(index.ROOT / "evidence/gc-queue-wait-composition.json")
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "receipt.json"
            record = {"accepted": False, "contextStable": True,
                      "runtimeAdmitted": False, "native": {"status": "not-run"},
                      "quintVersion": manifest["quintVersion"], "results": []}
            path.write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, "model-only evidence"):
                evidence.checked_rows(index.ROOT, manifest, path)
            incomplete = deepcopy(record)
            incomplete.update(accepted=True, inputs=manifest["contextInputs"])
            path.write_text(json.dumps(incomplete))
            actual_digest = evidence.digest
            def context_digest(source):
                try:
                    name = str(source.relative_to(index.ROOT))
                except ValueError:
                    return actual_digest(source)
                if name in manifest["contextInputs"] and not source.is_file():
                    return manifest["contextInputs"][name]
                return actual_digest(source)
            with patch.object(evidence, "digest", side_effect=context_digest), \
                    patch.object(evidence, "reuse_model_receipt", return_value=[]):
                with self.assertRaisesRegex(ValueError, "missing protocol checks"):
                    evidence.checked_rows(index.ROOT, manifest, path)


if __name__ == "__main__":
    unittest.main()
