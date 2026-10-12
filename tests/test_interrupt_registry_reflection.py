import copy
import json
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.reflection import validate
from gambit_smp.registry_history import validate as validate_history


class InterruptRegistryReflectionTests(unittest.TestCase):
    def test_historical_registry_identity_is_not_replaced_by_current_hash(self):
        parent = ROOT / "evidence/source-results/fixtures/abandoned-result-state/registry-parent.json"
        self.assertEqual(digest(parent), "eac411bf5c033abd4f4554dc4e6c81eeda6d4082581479e637255526446a35d2")
        predecessor = ROOT / "evidence/source-results/fixtures/thread-completion-contract/registry-before-interrupt-lifetime.json"
        predecessor_sha = "4582a11c426cd420e982e13df285cfa2ab1c202541c122e88e3904bd3f7d3254"
        self.assertEqual(digest(predecessor), predecessor_sha)
        history_path = "evidence/fixtures/thread-completion-contract/registry-history.json"
        history = json.loads((ROOT / history_path).read_text())
        bound_history = validate_history(ROOT, history_path)
        self.assertEqual([row["path"] for row in history["snapshots"]],
                         [str(parent.relative_to(ROOT)), str(predecessor.relative_to(ROOT))])
        self.assertEqual(len(history["snapshots"][1]["additions"]), 3)
        self.assertEqual(history["current"]["path"], "evidence/protocol-bundles.json")
        self.assertEqual(bound_history[str(parent.relative_to(ROOT))], digest(parent))
        self.assertEqual(bound_history[str(predecessor.relative_to(ROOT))], predecessor_sha)
        additions = history["current"]["requiredAdditions"]
        for name in ("sealed-runtime-review-handoff", "interrupt-delivery-gc-roots",
                     "interrupt-callback-gc-exit", "interrupt-requester-cancel"):
            self.assertIn([f"evidence/research/{name}/registry-contract.json",
                           f"evidence/model-results/research/{name}/receipt.json"], additions)
        audit = json.loads((ROOT / "evidence/research-audit.json").read_text())
        for issue in audit["issues"]:
            if "reflection" in issue:
                validate(ROOT, issue["reflection"])
        issue = next(row for row in audit["issues"] if row["id"] == "interrupt-result-composition-current-source")
        original = ROOT / "evidence/fixtures/abandoned-result-state/registered-protocol-reflection.json"
        self.assertEqual(digest(original), "9ed7bf26b09ff80c02156e0556ff96dbc018ada7993fa26b2b6ffa68f89769ef")
        reflection = ROOT / issue["evidence"][0]["path"]
        self.assertEqual(reflection, ROOT / "evidence/fixtures/thread-completion-contract/historical-registry-reflection.json")
        self.assertEqual(issue["reflection"], json.loads(reflection.read_text()))
        self.assertEqual(issue["evidence"][0]["sha256"], digest(reflection))
        self.assertIn({"path": str(original.relative_to(ROOT)), "sha256": digest(original)}, issue["evidence"])
        historical = copy.deepcopy(json.loads(original.read_text()))
        reference = historical["references"][0]
        self.assertEqual(reference["path"], "evidence/protocol-bundles.json")
        self.assertEqual(reference["artifacts"][0], {"path": reference["path"], "sha256": predecessor_sha})
        reference["path"] = str(predecessor.relative_to(ROOT))
        reference["artifacts"][0]["path"] = reference["path"]
        reference["scope"] = "Historical registration snapshot, not the later lifetime registry or full graph acceptance"
        self.assertEqual(issue["reflection"], historical)
        self.assertEqual({row["status"] for row in issue["reflection"]["requirements"]}, {"open", "partial"})
        bound = validate(ROOT, issue["reflection"])
        self.assertEqual(bound[str(predecessor.relative_to(ROOT))], predecessor_sha)
        self.assertNotIn("evidence/protocol-bundles.json", bound)
