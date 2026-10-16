import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import digest
from gambit_smp import historical_inputs as history


class HistoricalInputTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name).resolve()
        self.original = "evidence/research/rules.ss"
        self.archived = "evidence/source-results/fixtures/example/rules.ss"
        for name, content in ((self.original, "new rule"), (self.archived, "original rule")):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        self.receipt = self.root / "receipt.json"
        self.receipt.write_text(json.dumps({"inputs": {self.original: digest(self.root / self.archived)}}))
        self.record = {"schema": history.SCHEMA, "receiptSha256": digest(self.receipt),
                       "inputs": [{"original": self.original, "sha256": digest(self.root / self.archived),
                                   "archive": self.archived}]}
        self.manifest = "evidence/source-results/fixtures/example/inputs.json"
        self.save()

    def save(self):
        (self.root / self.manifest).write_text(json.dumps(self.record))

    def test_exact_archived_source_is_not_current_source(self):
        mapping, paths = history.bindings(self.root, self.receipt, self.manifest)
        expected = {str(self.root / self.original): digest(self.root / self.archived)}
        self.assertTrue(history.match(expected, mapping))
        self.assertFalse(history.match(expected, {}))
        self.assertEqual(2, len(paths))

    def test_original_receipt_and_archive_bytes_cannot_drift(self):
        self.receipt.write_text("changed")
        with self.assertRaisesRegex(ValueError, "exact historical"):
            history.bindings(self.root, self.receipt, self.manifest)
        self.record["receiptSha256"] = digest(self.receipt)
        self.save()
        with self.assertRaises(ValueError):
            history.bindings(self.root, self.receipt, self.manifest)

    def test_duplicate_and_unbound_input_rejected(self):
        self.record["inputs"].append(dict(self.record["inputs"][0]))
        self.save()
        with self.assertRaisesRegex(ValueError, "unique original"):
            history.bindings(self.root, self.receipt, self.manifest)
        self.record["inputs"] = [dict(self.record["inputs"][0], sha256="0" * 64)]
        self.save()
        with self.assertRaisesRegex(ValueError, "unique original"):
            history.bindings(self.root, self.receipt, self.manifest)

    def test_archive_drift_outside_versioned_evidence_and_symlink_rejected(self):
        row = self.record["inputs"][0]
        for target in (self.original, "../outside", "/private/tmp/old"):
            row["archive"] = target
            self.save()
            with self.assertRaises(ValueError):
                history.bindings(self.root, self.receipt, self.manifest)
        row["archive"] = self.archived
        self.save()
        path = self.root / self.archived
        path.write_text("drift")
        with self.assertRaisesRegex(ValueError, "exact versioned"):
            history.bindings(self.root, self.receipt, self.manifest)
        path.unlink()
        target = path.with_name("original.ss")
        target.write_text("original rule")
        path.symlink_to(target.name)
        with self.assertRaisesRegex(ValueError, "exact versioned"):
            history.bindings(self.root, self.receipt, self.manifest)

    def test_runtime_output_is_not_a_source_input_archive(self):
        path = self.root / ".data/runtime/gsi"
        path.parent.mkdir(parents=True)
        path.write_text("binary")
        self.record["inputs"][0]["original"] = ".data/runtime/gsi"
        self.save()
        with self.assertRaises(ValueError):
            history.bindings(self.root, self.receipt, self.manifest)

    def test_declared_design_document_keeps_exact_historical_bytes(self):
        name = "docs/design.md"
        document = self.root/name
        document.parent.mkdir()
        document.write_text("new explanation")
        old_sha = digest(self.root/self.archived)
        self.receipt.write_text(json.dumps({"inputs":{name:old_sha}}))
        self.record["receiptSha256"] = digest(self.receipt)
        self.record["inputs"][0]["original"] = name
        self.save()
        mapping,_ = history.bindings(self.root,self.receipt,self.manifest)
        self.assertTrue(history.match({str(document):old_sha},mapping))
        self.assertFalse(history.match({str(document):old_sha},{}))
        (self.root/self.archived).write_text("different old explanation")
        with self.assertRaisesRegex(ValueError,"exact versioned"):
            history.bindings(self.root,self.receipt,self.manifest)

    def test_retained_workspace_uses_the_same_exact_historical_input_binding(self):
        from gambit_smp.artifact_storage import seal_workspace_state, checked_workspace_state
        from gambit_smp.recipes import tree_identity
        source = self.root / "workspace"
        source.mkdir()
        (source/"runtime").write_text("exact current product")
        original = self.root / self.original
        original.write_text("original rule")
        inventory = tree_identity(source)
        reference = seal_workspace_state(self.root, source, self.root/"evidence/state.json",
                                         {self.original:digest(original)})
        original.write_text("new rule")
        mapping, _ = history.bindings(self.root,self.receipt,self.manifest)
        with self.assertRaisesRegex(ValueError,"input drift"):
            checked_workspace_state(self.root,reference,inventory)
        result = checked_workspace_state(self.root,reference,inventory,input_bindings=mapping)
        self.assertTrue(result["recordedStateBound"])
        self.assertFalse(result["currentBytesEstablished"])
        self.assertFalse(result["runtimeAdmitted"])
        (source/"runtime").write_text("changed product")
        with self.assertRaisesRegex(ValueError,"does not match producer"):
            checked_workspace_state(self.root,reference,tree_identity(source),input_bindings=mapping)
        (self.root/self.archived).write_text("changed archive")
        with self.assertRaisesRegex(ValueError,"input drift"):
            checked_workspace_state(self.root,reference,inventory,input_bindings=mapping)


if __name__ == "__main__":
    unittest.main()
