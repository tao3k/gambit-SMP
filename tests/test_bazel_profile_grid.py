"""Default-profile consumers must preserve complete coverage and source identity."""
import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "evidence/research/smp-threaded-vm-native-grid"


class BazelProfileGridTests(unittest.TestCase):
    def test_default_profile_topology_preserves_models_fixture_and_budgets(self):
        base = ROOT / "evidence/research/vm-registry-reader-lease"
        old = json.loads((base / "host-topology-grid.recipe.json").read_text())
        current = json.loads((base / "bazel-profile-host-topology-grid.recipe.json").read_text())
        producer = "evidence/research/vm-registry-reader-lease/bazel-profile-completed-producer.json"
        historical = "evidence/research/vm-registry-reader-lease/resize-grace-complete-historical-producer.json"
        self.assertIn(producer, current["inputs"])
        current["inputs"] = [historical if name == producer else name for name in current["inputs"]]
        step = next(step for step in current["steps"] if step["id"] == "producer")
        self.assertEqual(producer, step["arguments"]["producer"])
        step["arguments"]["producer"] = historical
        current["id"], current["scope"] = old["id"], old["scope"]
        self.assertEqual(old, current)

    def test_complete_inventory_and_original_budgets_are_preserved(self):
        current = json.loads((BASE / "bazel-profile-interpreted.recipe.json").read_text())
        compiled = json.loads((BASE / "current-compiled-configuration.recipe.json").read_text())
        steps = {step["id"]: step for step in current["steps"]}
        original = next(step for step in compiled["steps"] if step["id"] == "native-gsc")
        suite = steps["native-gsi"]
        self.assertEqual(300, current["budgetSeconds"])
        self.assertEqual(300, suite["budgetSeconds"])
        self.assertEqual(379, len(suite["arguments"]["expectedFiles"]))
        for key in ("expectedFiles", "additionalFixtures"):
            self.assertEqual(original["arguments"][key], suite["arguments"][key])
        self.assertEqual({"13-modules/prim_port.scm": 20,
                          "06-thread/thread_interrupt_ended.scm": 20,
                          "10-tables/serialization_gc.scm": 60},
                         suite["arguments"]["fileBudgetSeconds"])
        self.assertTrue(steps["producer"]["arguments"]["producer"].endswith(
            "/bazel-profile-completed-producer.json"))
        self.assertIn("review-gsi", suite["dependsOn"])
        self.assertEqual("gsi", suite["arguments"]["mode"])

    def test_successor_changes_only_stale_setup_binding_and_claim_references(self):
        old = json.loads((BASE / "gsi-complete-reviewed-intent.json").read_text())
        current = json.loads((BASE / "bazel-profile-gsi-intent.json").read_text())
        lock = json.loads((ROOT / "evidence/fixtures/vm-registry-reader-lease/"
                           "resize-grace-source.lock.json").read_text())
        additions = current["failures"][len(old["failures"]):]
        self.assertEqual({"020-ended-interrupt-lock", "022-pr1038-serialization-gc"},
                         {entry["id"] for entry in additions})
        for entry in additions:
            change = entry["changes"][0]
            self.assertEqual(lock["files"][change["path"]]["candidateSha256"],
                             change["after"])
            baseline = ROOT / entry["baselineIdentity"]["path"]
            self.assertEqual(hashlib.sha256(baseline.read_bytes()).hexdigest(),
                             entry["baselineIdentity"]["sha256"])
            for claim in entry["claims"]:
                self.assertEqual(hashlib.sha256((ROOT / claim["evidence"]["path"]).read_bytes()).hexdigest(),
                                 claim["evidence"]["sha256"])
        current["failures"] = current["failures"][:len(old["failures"])]
        for previous, entry in zip(old["failures"], current["failures"], strict=True):
            for change in entry["changes"]:
                if change["path"] == "lib/setup.c":
                    self.assertEqual(lock["files"]["lib/setup.c"]["candidateSha256"],
                                     change["after"])
                    change["after"] = previous["changes"][0]["after"]
            for original, claim in zip(previous["claims"], entry["claims"], strict=True):
                if claim["evidence"]["path"].endswith("bazel-profile-interpreted-causal-evidence.json"):
                    path = ROOT / claim["evidence"]["path"]
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),
                                     claim["evidence"]["sha256"])
                    claim["evidence"] = original["evidence"]
        self.assertEqual(old, current)
