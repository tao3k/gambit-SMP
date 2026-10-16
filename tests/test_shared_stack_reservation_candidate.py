"""Source/recipe boundary controls, not native qualification."""
import hashlib
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "evidence/research/current-source-full-bootstrap"


class SharedStackReservationCandidateTests(unittest.TestCase):
    def test_same_source_revision_and_only_mem_delta(self):
        parent = json.loads((ROOT / "evidence/fixtures/darwin-shared-successor-snapshot/source.lock.json").read_text())
        candidate = json.loads((ROOT / "evidence/fixtures/darwin-shared-stack-reservation/source.lock.json").read_text())
        self.assertEqual(parent["revision"], candidate["revision"])
        self.assertEqual(set(parent["files"]), set(candidate["files"]))
        changed = set()
        for name, row in candidate["files"].items():
            self.assertEqual(parent["files"][name]["baseSha256"], row["baseSha256"])
            if parent["files"][name]["candidateSha256"] != row["candidateSha256"]:
                changed.add(name)
        self.assertEqual({"lib/mem.c"}, changed)
        self.assertEqual(hashlib.sha256((ROOT / candidate["patch"]).read_bytes()).hexdigest(),
                         candidate["patchSha256"])
        self.assertFalse(candidate["runtimeAdmitted"])
        self.assertFalse(candidate["releaseAdmitted"])

    def test_model_controls_cover_both_losses_and_unchanged_path(self):
        recipe = json.loads((BASE / "shared-section-undo-bounds.recipe.json").read_text())
        checks = {step["id"]: step["arguments"] for step in recipe["steps"]
                  if step["capability"] == "quint.verify"}
        self.assertTrue(checks["original-undo-partition"]["negative"])
        self.assertTrue(checks["original-gc-pending-frame"]["negative"])
        self.assertFalse(checks["restored-shared-boundary"]["negative"])
        self.assertFalse(checks["unchanged-separate-section"]["negative"])

    def test_original_profile_and_stage_windows_are_retained(self):
        recipe = json.loads((BASE / "darwin-shared-stack-reservation-bootstrap.recipe.json").read_text())
        steps = {step["id"]: step for step in recipe["steps"]}
        self.assertEqual("evidence/fixtures/gerbil-bazel-build-profile/profile.json",
                         steps["configure"]["arguments"]["buildProfile"])
        self.assertEqual("progress", recipe["timeoutPolicy"]["mode"])
        self.assertEqual({"source": 30, "configure": 60, "seed": 130,
                          "review": 15, "bootstrap": 270, "verdict": 10},
                         {name: step["budgetSeconds"] for name, step in steps.items()})

    def test_reviewed_claim_changes_bind_the_actual_intent(self):
        intent = json.loads((BASE / "darwin-shared-stack-reservation-reviewed-intent.json").read_text())
        for failure in intent["failures"]:
            changes = {row["id"] for row in failure["changes"]}
            for claim in failure["claims"]:
                path = ROOT / claim["evidence"]["path"]
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),
                                 claim["evidence"]["sha256"])
                row = json.loads(path.read_text())
                for component in claim["pointer"].strip("/").split("/"):
                    row = row[int(component)] if isinstance(row, list) else row[component]
                self.assertLessEqual(set(row["changes"]), changes)
