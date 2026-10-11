import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp import progress_evidence as evidence
from gambit_smp.framework import digest


class ProgressEvidenceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        name = "evidence/model-results/model-progress/sync_resource_users"
        source = evidence.ROOT / name
        self.destination = self.root / name
        shutil.copytree(source, self.destination)
        self.receipt = self.destination / "receipt.json"
        saved = json.loads(self.receipt.read_text())
        saved["inputs"] = {name.replace("tools/model/", "src/gambit_smp/"): sha
                           for name, sha in saved["inputs"].items()}
        for relative in saved["inputs"]:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(evidence.ROOT / relative, target)
        # This is an isolated validator unit fixture, not republished evidence.
        # Live historical receipts must still reject changed tool identities.
        saved["inputs"] = {relative: digest(self.root / relative) for relative in saved["inputs"]}
        self.receipt.write_text(json.dumps(saved))
        self.case = json.loads((self.root / evidence.MANIFEST).read_text())["cases"][0]

    def mutate(self, change):
        saved = json.loads(self.receipt.read_text())
        change(saved)
        self.receipt.write_text(json.dumps(saved))

    def test_unit_fixture_progress_is_not_runtime_admission(self):
        saved = evidence.checked(self.root, self.case, self.receipt)
        self.assertFalse(saved["runtimeAdmitted"])
        facts, _ = evidence.facts(self.root)
        self.assertEqual([("sync_resource_users", digest(self.receipt))], facts["model_progress_checked"])

    def test_live_receipt_still_rejects_changed_context(self):
        receipt = evidence.ROOT / self.receipt.relative_to(self.root)
        saved = json.loads(receipt.read_text())
        changed = any(not (evidence.ROOT / name).is_file() or digest(evidence.ROOT / name) != sha
                      for name, sha in saved["inputs"].items())
        if changed:
            with self.assertRaisesRegex(ValueError, "context differs"):
                evidence.checked(evidence.ROOT, self.case, receipt)
        else:
            self.assertFalse(evidence.checked(evidence.ROOT, self.case, receipt)["runtimeAdmitted"])

    def test_missing_control_is_rejected(self):
        self.mutate(lambda saved: saved["results"].pop(0))
        with self.assertRaises(ValueError):
            evidence.checked(self.root, self.case, self.receipt)
        facts, _ = evidence.facts(self.root)
        self.assertEqual([], facts["model_progress_checked"])

    def test_nonboolean_acceptance_is_not_admitted(self):
        self.mutate(lambda saved: saved.update(accepted=1))
        with self.assertRaisesRegex(ValueError, "not admitted"):
            evidence.checked(self.root, self.case, self.receipt)

    def test_changed_base_model_leaves_progress_obligation_open(self):
        source = self.root / "models/gambit/sync_resource_users.qnt"
        source.write_text(source.read_text() + "// changed source\n")
        with self.assertRaisesRegex(ValueError, "context differs"):
            evidence.checked(self.root, self.case, self.receipt)
        facts, _ = evidence.facts(self.root)
        self.assertEqual(1, len(facts["model_progress_obligation"]))
        self.assertEqual([], facts["model_progress_checked"])

    def test_rehashed_snapshot_cannot_change_the_original_protocol(self):
        def change(saved):
            row = saved["results"][1]
            snapshot = self.destination / row["snapshot"]
            snapshot.write_text(snapshot.read_text().replace("sender: 1", "sender: 4"))
            row["snapshotSha256"] = digest(snapshot)
        self.mutate(change)
        with self.assertRaisesRegex(ValueError, "snapshot or log identity"):
            evidence.checked(self.root, self.case, self.receipt)

    def test_safety_only_log_cannot_be_rehashed_into_temporal_admission(self):
        def change(saved):
            row = saved["results"][1]
            log = self.destination / row["log"]
            log.write_text(log.read_text().replace("Finished checking temporal properties", "Safety checks only"))
            row["logSha256"] = digest(log)
        self.mutate(change)
        with self.assertRaisesRegex(ValueError, "temporal check"):
            evidence.checked(self.root, self.case, self.receipt)
