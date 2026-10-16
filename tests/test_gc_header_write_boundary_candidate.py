"""Diagnostic scope controls; these do not qualify a native source repair."""
import hashlib
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class GCHeaderWriteBoundaryCandidateTests(unittest.TestCase):
    def test_parent_layout_and_source_identity_are_preserved(self):
        parent = json.loads((ROOT / "evidence/fixtures/darwin-shared-stack-reservation/source.lock.json").read_text())
        child = json.loads((ROOT / "evidence/fixtures/darwin-gc-header-write-boundary/source.lock.json").read_text())
        self.assertEqual(parent["revision"], child["revision"])
        self.assertEqual(set(parent["files"]), set(child["files"]))
        changed = {name for name in parent["files"]
                   if parent["files"][name] != child["files"][name]}
        self.assertEqual({"lib/mem.c"}, changed)
        self.assertEqual(hashlib.sha256((ROOT / child["patch"]).read_bytes()).hexdigest(),
                         child["patchSha256"])
        contract = json.loads((ROOT / "evidence/fixtures/darwin-gc-header-write-boundary/review-contract.json").read_text())
        self.assertFalse(contract["runtimeAdmitted"])
        self.assertFalse(contract["releaseAdmitted"])

    def test_current_position_mismatch_and_writer_controls_are_kept(self):
        recipe = json.loads((ROOT / "evidence/research/current-source-full-bootstrap/shared-header-write-boundary.recipe.json").read_text())
        checks = {step["id"]: step["arguments"] for step in recipe["steps"]
                  if step["capability"] == "quint.verify"}
        self.assertFalse(checks["guarded-writes"]["negative"])
        for name in ("unguarded-writes", "native-header", "in-range-position"):
            self.assertTrue(checks[name]["negative"])

    def test_stress_inventory_and_original_watchdog_are_unchanged(self):
        base = ROOT / "evidence/research/current-source-full-bootstrap"
        old = json.loads((base / "darwin-shared-stack-reservation-stress-compiled.recipe.json").read_text())
        new = json.loads((base / "darwin-gc-header-write-boundary-stress-compiled.recipe.json").read_text())
        old_step = next(step for step in old["steps"] if step["id"] == "stress-gsc")
        new_step = next(step for step in new["steps"] if step["id"] == "stress-gsc")
        self.assertEqual(old_step, new_step)
        self.assertEqual(old["timeoutPolicy"], new["timeoutPolicy"])
