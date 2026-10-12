import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp import protocol_evidence as evidence


class VMOwnedFixtureTests(unittest.TestCase):
    def test_private_memory_model_has_checked_split_prefix_and_private_success(self):
        base = "evidence/fixtures/vm-constructor-owned-rollback/"
        manifest = json.loads((ROOT / (base + "private-memory-contract.json")).read_text())
        name = "evidence/model-results/fixtures/vm-constructor-owned-rollback/private-memory-contract/receipt.json"
        rows = evidence.checked_rows(ROOT, manifest, ROOT / name)[0][1]
        self.assertEqual(7, len(rows))
        positive = next(row for row in rows if row["variant"] == "fixed")
        self.assertEqual(0, positive["exit"])
        self.assertEqual(978, positive["states"]["distinct"])
        self.assertEqual(0, positive["states"]["queued"])
        lock = json.loads((ROOT / (base + "source.lock.json")).read_text())
        self.assertEqual(lock["patchSha256"], digest(ROOT / lock["patch"]))
        self.assertEqual(13, len(lock["files"]))

    def test_native_observation_is_a_summary_not_runtime_admission(self):
        path = ROOT / "evidence/source-results/fixtures/vm-constructor-owned-rollback/observation.json"
        saved = json.loads(path.read_text())
        for flag in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"):
            self.assertIs(saved[flag], False)
        for name, sha in saved["inputs"].items():
            self.assertEqual(sha, digest(ROOT / name))
        self.assertEqual("DENY", saved["runs"]["objects"]["outcome"])
        self.assertEqual("PASS", saved["runs"]["host-objects"]["outcome"])
        self.assertEqual("PASS", saved["runs"]["caller"]["outcome"])
        self.assertEqual("PASS", saved["runs"]["spin-backends"]["outcome"])
        mutex = next(row for row in saved["runs"]["spin-backends"]["steps"]
                     if row["id"] == "memory-mutex")
        self.assertEqual("PASS", mutex["outcome"])
        self.assertTrue(all(command["exit"] == 0 for command in mutex["commands"]))
        negative = next(row for row in saved["runs"]["caller"]["steps"]
                        if row["id"] == "negative-threaded-test")
        self.assertEqual(1, negative["commands"][0]["exit"])
        self.assertEqual("PASS", negative["outcome"])

    def test_actual_memory_bodies_have_complete_failure_and_backend_matrix(self):
        path = ROOT / "evidence/source-results/fixtures/vm-constructor-owned-rollback/observation.json"
        saved = json.loads(path.read_text())
        run = saved["runs"]["memory-callee"]
        self.assertEqual("PASS", run["outcome"])
        expected = {"candidate-mutex-test", "candidate-ticket-test", "candidate-void-test",
                    "candidate-single-thread-test", "candidate-single-vm-test", "negative-mutex-test"}
        rows = [row for row in run["steps"] if row["id"].endswith("-test")]
        self.assertEqual(expected, {row["id"] for row in rows})
        for row in rows:
            self.assertEqual("PASS", row["outcome"])
            self.assertEqual(1, len(row["commands"]))
            self.assertIs(row["commands"][0]["timeout"], False)
            self.assertEqual(int(row["id"] == "negative-mutex-test"), row["commands"][0]["exit"])
