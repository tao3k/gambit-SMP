import json
from pathlib import Path
import shutil
import tempfile
import unittest

from gambit_smp import progress_evidence as evidence
from gambit_smp.framework import digest
from gambit_smp.output_observations import REGISTRY


class ProgressEvidenceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        fixture = json.loads((evidence.ROOT / "tests/fixtures/model-progress-sync-resource-users.json").read_text())
        name = fixture["prefix"]
        self.destination = self.root / name
        self.destination.mkdir(parents=True, exist_ok=True)
        for filename, content in fixture["files"].items():
            (self.destination / filename).write_text(content)
        registry_path = self.root / REGISTRY
        registry_path.parent.mkdir(parents=True, exist_ok=True)
        published_schema = json.loads((evidence.ROOT / REGISTRY).read_text())["schema"]
        registry_path.write_text(json.dumps({
            "schema": published_schema,
            "records": {},
            "observations": fixture["observations"],
        }))
        self.receipt = self.destination / "receipt.json"
        saved = json.loads(self.receipt.read_text())
        saved["inputs"] = {key.replace("tools/model/", "src/gambit_smp/"): sha
                           for key, sha in saved["inputs"].items()}
        for relative in saved["inputs"]:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(evidence.ROOT / relative, target)
        # This is an isolated validator unit fixture, not republished evidence.
        # Historical receipts must still reject changed tool/context identities.
        self.original_inputs = dict(saved["inputs"])
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
        self.mutate(lambda saved: saved["inputs"].update(self.original_inputs))
        saved = json.loads(self.receipt.read_text())
        changed = any(not (self.root / name).is_file() or digest(self.root / name) != sha
                      for name, sha in saved["inputs"].items())
        if changed:
            with self.assertRaisesRegex(ValueError, "context differs"):
                evidence.checked(self.root, self.case, self.receipt)
        else:
            self.assertFalse(evidence.checked(self.root, self.case, self.receipt)["runtimeAdmitted"])

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
            from gambit_smp.output_observations import recorded
            output = recorded(self.root, self.destination / row["log"], row["logSha256"])
            output["tlc"]["temporalComplete"] = False
            saved["outputs"] = {row["log"]: output}
        self.mutate(change)
        with self.assertRaisesRegex(ValueError, "temporal check"):
            evidence.checked(self.root, self.case, self.receipt)
