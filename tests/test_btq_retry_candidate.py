"""Source/recipe integrity checks, not executed SMP qualification."""
import json
from pathlib import Path
import unittest

from gambit_smp.framework import ROOT, digest


class BtqRetryCandidateTests(unittest.TestCase):
    def read(self, relative):
        return json.loads((ROOT / relative).read_text())

    def test_one_changed_source_and_inherited_closure(self):
        old = self.read("evidence/fixtures/vm-reporter-preservation/source.lock.json")
        new = self.read("evidence/fixtures/btq-retry-sync-participation/source.lock.json")
        self.assertEqual(21, len(new["files"]))
        self.assertEqual(old["revision"], new["revision"])
        self.assertEqual(old["files"].keys(), new["files"].keys())
        changed = [name for name in old["files"] if old["files"][name] != new["files"][name]]
        self.assertEqual(["lib/_thread.scm"], changed)
        self.assertEqual(old["files"][changed[0]]["baseSha256"], new["files"][changed[0]]["baseSha256"])
        self.assertEqual(new["patchSha256"], digest(ROOT / new["patch"]))

    def test_full_native_inventory_and_budget_are_unchanged(self):
        folder = "evidence/research/smp-threaded-vm-native-grid/"
        old = self.read(folder + "reporter-preservation-interpreted.recipe.json")
        new = self.read(folder + "btq-retry-interpreted.recipe.json")
        step = lambda recipe: next(row for row in recipe["steps"] if row["id"] == "native-gsi")
        self.assertEqual(step(old), step(new))
        self.assertEqual(old["budgetSeconds"], new["budgetSeconds"])

    def test_new_review_keeps_failure_and_original_baseline(self):
        folder = "evidence/research/smp-threaded-vm-native-grid/"
        old = self.read(folder + "global-cleanup-gsi-intent.json")
        new = self.read(folder + "btq-retry-gsi-intent.json")
        lock = self.read("evidence/fixtures/btq-retry-sync-participation/source.lock.json")
        self.assertEqual(len(old["failures"]), len(new["failures"]))
        for before, after in zip(old["failures"], new["failures"]):
            if before["id"] != "020-ended-interrupt-lock":
                self.assertEqual(before, after)
                continue
            for key in ("id", "receiptSha256", "baselineIdentity", "failurePointer", "log", "budget"):
                self.assertEqual(before[key], after[key])
            self.assertEqual(before["changes"][0]["before"], after["changes"][0]["before"])
            self.assertEqual(lock["files"]["lib/_thread.scm"]["candidateSha256"], after["changes"][0]["after"])
            for claim in after["claims"]:
                self.assertNotEqual(before["claims"][0]["evidence"]["path"], claim["evidence"]["path"])
                self.assertEqual(claim["evidence"]["sha256"], digest(ROOT / claim["evidence"]["path"]))
