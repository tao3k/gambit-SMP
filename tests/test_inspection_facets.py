import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.framework import digest
from gambit_smp import recipes, research_kernel


class InspectionFacetTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.source = self.root / "source.lock.json"
        self.patch = self.root / "candidate.patch"
        self.source.write_text("source identity")
        self.patch.write_text("exact patch bytes")
        self.out = self.root / "run"
        self.out.mkdir()
        (self.out / "tools.json").write_text("{}")
        (self.out / "compile.log").write_text("compiler exit 0")
        self.tree = self.out / "source"
        self.tree.mkdir()
        (self.tree / "object.o").write_bytes(b"compiled object")
        receipt = {"schema": "evidence-recipe-run.v1", "recipe": "source-check",
                   "outcome": "PASS", "inputs": {str(p): digest(p) for p in (self.source, self.patch)},
                   "toolInputs": {"path": "tools.json", "sha256": digest(self.out / "tools.json")},
                   "steps": [{"id": "compile", "observedInputs": {},
                              "artifacts": {"compile.log": digest(self.out / "compile.log")},
                              "outputs": {"source": {"type": "configured-tree", "path": "source",
                                                     "identity": recipes.tree_identity(self.tree)}}}]}
        (self.out / "receipt.json").write_text(json.dumps(receipt))

    def test_cleanup_preserves_recorded_pass_but_denies_producer_reuse(self):
        shutil.rmtree(self.tree)
        state = recipes.inspect_run(self.out)
        self.assertEqual("PASS", state["recordedOutcome"])
        self.assertEqual("CURRENT", state["evidenceBindingStatus"])
        self.assertEqual("MISSING", state["artifactAvailability"]["status"])
        self.assertEqual("STALE", state["identityStatus"])
        self.assertFalse(state["executionAuthorized"])
        self.assertFalse(state["runtimeAdmitted"])

    def test_source_and_patch_changes_invalidate_evidence_binding(self):
        for path in (self.source, self.patch):
            original = path.read_bytes()
            path.write_bytes(original + b"changed")
            state = recipes.inspect_run(self.out)
            self.assertEqual("STALE", state["evidenceBindingStatus"])
            self.assertEqual("AVAILABLE", state["artifactAvailability"]["status"])
            self.assertEqual("STALE", state["identityStatus"])
            path.write_bytes(original)

    def test_output_drift_is_distinct_from_missing_cache(self):
        (self.tree / "object.o").write_bytes(b"different object")
        state = recipes.inspect_run(self.out)
        self.assertEqual("CURRENT", state["evidenceBindingStatus"])
        self.assertEqual("MODIFIED", state["artifactAvailability"]["status"])
        self.assertEqual("STALE", state["identityStatus"])

    def test_log_tampering_does_not_become_cache_eviction(self):
        (self.out / "compile.log").write_text("forged log")
        state = recipes.inspect_run(self.out)
        self.assertEqual("STALE", state["evidenceBindingStatus"])
        self.assertEqual("AVAILABLE", state["artifactAvailability"]["status"])

    def test_unchanged_evidence_and_outputs_remain_current(self):
        state = recipes.inspect_run(self.out)
        self.assertEqual("CURRENT", state["identityStatus"])
        self.assertEqual("CURRENT", state["evidenceBindingStatus"])
        self.assertEqual("AVAILABLE", state["artifactAvailability"]["status"])

    def sealed_observation(self):
        outer = self.root / "sealed"
        outer.mkdir()
        shutil.move(str(self.out), str(outer / "run"))
        self.out = outer / "run"
        self.tree = self.out / "source"
        receipt = {"schema": "sealed-research-run.v1", "recipe": "source-check",
                   "engineId": "fixed-engine", "engine": str(self.root / "engine"),
                   "root": str(self.root), "outcome": "PASS", "executionLaunched": True,
                   "inputs": {p.name: digest(p) for p in (self.source, self.patch)},
                   "artifacts": {}, "childReceiptSha256": digest(self.out / "receipt.json")}
        (outer / "receipt.json").write_text(json.dumps(receipt))
        return outer

    def test_sealed_readback_preserves_facets_without_admitting_evicted_output(self):
        outer = self.sealed_observation()
        shutil.rmtree(self.tree)
        with patch.object(research_kernel, "manifest_paths", return_value={"engineId": "fixed-engine"}):
            state = research_kernel.inspect(outer)
        self.assertEqual("PASS", state["recordedOutcome"])
        self.assertEqual("CURRENT", state["evidenceBindingStatus"])
        self.assertEqual("MISSING", state["artifactAvailability"]["status"])
        self.assertEqual("STALE", state["identityStatus"])
        self.assertFalse(state["runtimeAdmitted"])
        self.assertFalse(state["sourceRefinementAdmitted"])

    def test_sealed_patch_drift_is_not_hidden_by_cache_loss(self):
        outer = self.sealed_observation()
        shutil.rmtree(self.tree)
        self.patch.write_text("different patch")
        with patch.object(research_kernel, "manifest_paths", return_value={"engineId": "fixed-engine"}):
            state = research_kernel.inspect(outer)
        self.assertEqual("STALE", state["evidenceBindingStatus"])
        self.assertEqual("MISSING", state["artifactAvailability"]["status"])
        self.assertEqual("STALE", state["identityStatus"])


if __name__ == "__main__":
    unittest.main()
