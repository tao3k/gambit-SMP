import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify
from gambit_smp.framework import ROOT, digest


class GCRecursiveQueueWaitTests(unittest.TestCase):
    def test_matrix_preserves_nine_independent_controls_and_both_policies(self):
        case = verify.load_manifest(ROOT / "evidence/gc-recursive-queue-wait.json")["cases"][0]
        self.assertEqual([
            ("old", "payloadSafe", "initEarlyPublish"),
            ("old", "ownershipSafe", "initDuplicateClaim"),
            ("old", "producerLifetimeSafe", "initEarlyIdle"),
            ("old", "restoreSafe", "initNoRestore"),
            ("old", "localExportSafe", "initLocalReexport"),
            ("old", "queueTopologySafe", "initWrongQueue"),
            ("old", "fieldPartitionSafe", "initScanHead"),
            ("old", "localDrainSafe", "initSkipLocalDrain"),
            ("old", "eagerOwnerSafe", "initEarlyOwnerRelease"),
            ("protocol", "sourceSafe", "initSource"),
            ("protocol", "combinedSafe", "initCombined")], verify.model_checks(case))
        for obligation in ("gc_processor_local_queue_topology", "gc_local_unexported_scan_composition",
                           "gc_copy_queue_memory_order", "gc_recursive_wait_phase_composition"):
            self.assertIn(obligation, case["openObligations"])

    def test_unchecked_nested_copy_frontier_stays_an_open_contract(self):
        case = verify.load_manifest(ROOT / "evidence/gc-recursive-queue-wait.json")["cases"][0]
        self.assertIn("gc_recursive_copy_stack_frontier", case["openObligations"])
        self.assertIn("four processor-owned queues", case["scope"])
        self.assertIn("ordered nested copy stacks", case["scope"])

    def test_recursive_eager_heads_cover_helpers_not_only_original_roots(self):
        manifest = verify.load_manifest(ROOT / "evidence/gc-recursive-queue-wait.json")
        case = manifest["cases"][0]
        self.assertIn("Every object has a copier-owned eager head", case["scope"])
        model = (ROOT / "models/gambit/gc_recursive_queue_wait.qnt").read_text()
        self.assertIn("st.headDone == objects", model)
        self.assertIn("val closureSafe = closureSafeOf(s)", model)
        self.assertIn("action markTail", model)
        self.assertNotIn("nondet p = producers.oneOf()", model)
        self.assertIn("settled and (s.headDone.contains(o) or s.fault", model)
        self.assertIn("s.work.get(o) == 3 and s.headDone.contains(o)", model)

    def test_sequential_probe_has_no_atomic_global_empty_premise(self):
        model = (ROOT / "models/gambit/gc_recursive_queue_wait.qnt").read_text()
        probe = model.split("action startProbe", 1)[1].split("action lockTermination", 1)[0]
        self.assertNotIn("queued == Set()", probe)
        self.assertIn("action probeEmptyQueue", probe)
        self.assertIn("not(queuePending(probeOrder.nth(index)))", probe)
        scope = verify.load_manifest(ROOT / "evidence/gc-recursive-queue-wait.json")["cases"][0]
        self.assertIn("gc_recursive_wait_steal_loop_source_refinement", scope["openObligations"])
        order = []
        for i in range((4 - 1) * 1000 - 1, -1, -1):
            q = (i + i % (4 - 1) + 1) % 4
            if q not in order:
                order.append(q)
        self.assertEqual([2, 0, 3, 1], order)

    def test_current_inputs_are_versioned_not_legacy_paper_cache(self):
        manifest = verify.load_manifest(ROOT / "evidence/gc-recursive-queue-wait.json")
        for name, sha in manifest["contextInputs"].items():
            self.assertFalse(name.startswith(".data/"))
            self.assertFalse(name.endswith(".txt"))
            self.assertEqual(sha, digest(ROOT / name))

    def test_datalog_keeps_model_pending(self):
        facts, _ = evidence.bundle_facts(ROOT, "evidence/gc-recursive-queue-wait.json",
                                       "evidence/model-results/gc-recursive-queue-wait/receipt.json")
        self.assertEqual("gc_recursive_queue_wait", facts["protocol_model"][0][0])
        self.assertEqual([], facts["protocol_checked"])
        self.assertIn(("gc_recursive_queue_wait", "gc_processor_local_queue_topology"),
                      facts["protocol_obligation"])

    def test_archived_denial_and_timing_cannot_be_admitted(self):
        manifest = verify.load_manifest(ROOT / "evidence/gc-recursive-queue-wait.json")
        for name in ("gc-recursive-queue-wait-deny", "gc-recursive-queue-controls-parallel",
                     "gc-recursive-queue-wait-processor-local-deny",
                     "gc-recursive-queue-wait-eager-fields-deny", "gc-recursive-queue-wait-final-deny"):
            directory = ROOT / "evidence/model-results" / name
            saved = json.loads((directory / "receipt.json").read_text())
            self.assertFalse(saved["accepted"])
            self.assertFalse(saved["runtimeAdmitted"])
            archive = json.loads((directory / "archive.json").read_text())
            for path, row in archive["files"].items():
                self.assertEqual(row["portableSha256"], digest(directory / path))
            with self.assertRaisesRegex(ValueError, "not admitted"):
                evidence.checked_rows(ROOT, manifest, directory / "receipt.json")

    def test_archive_rejects_admitted_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            (source / "receipt.json").write_text(json.dumps({"accepted": True,
                                                           "native": {"status": "not-run"}}))
            with self.assertRaisesRegex(ValueError, "non-admitted"):
                evidence.archive_attempt(source, source / "out")


if __name__ == "__main__":
    unittest.main()
