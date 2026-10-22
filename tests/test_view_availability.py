"""Real Scheme provenance projections; no stale domain facts or execution grants."""
import json
from pathlib import Path
import tempfile
import subprocess
import unittest

from gambit_smp.ascent_program import engine_api
from gambit_smp.evidence_views import load, evaluate, ReferenceUnavailable
from gambit_smp.framework import ROOT, digest
from gambit_smp.trajectory_exploration import repository_clues, catalog, _repository_snapshot, _current


class ViewAvailabilityTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = root = Path(temporary.name).resolve()
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        folder = root / "evidence"
        folder.mkdir()
        dsl = folder / "dsl"
        dsl.mkdir()
        for name in ("storage.ss", "history.ss", "view-availability.ss"):
            (dsl / name).write_text((ROOT / "evidence/dsl" / name).read_text())
        storage = json.loads((ROOT / "evidence/dsl/components.json").read_text())
        storage["components"] = [c for c in storage["components"] if c["id"] == "state-storage"]
        (dsl / "components.json").write_text(json.dumps(storage))
        (folder / "clues.ss").write_text((ROOT / "evidence/scenarios/stack-header/clues.ss").read_text())
        (folder / "components.json").write_text(json.dumps({
            "schema": "ascent.evidence-components.v1", "components": [{
                "id": "clues", "source": "clues.ss", "exports": ["make-stack-entry-clues"],
                "dependencies": []}]}))
        for name in ("healthy", "changing"):
            receipt = folder / (name + ".md")
            receipt.write_text(name)
            (folder / (name + ".view.json")).write_text(json.dumps({
                "schema": "ascent.evidence-view.v1", "id": name,
                "manifest": "evidence/components.json", "entry": "clues",
                "constructor": "make-stack-entry-clues",
                "facts": {"observation": [[name, name + "-claim", "support", "receipt"]],
                          "reference": {"references": True}},
                "queries": {n: n for n in ("clue", "factor", "link")},
                "references": [{"id": "receipt", "path": "evidence/" + name + ".md",
                                "sha256": digest(receipt), "pointer": None}]}))
        (folder / "views.json").write_text(json.dumps({
            "schema": "ascent.evidence-views.v1",
            "availability": {"source": "evidence/dsl/view-availability.ss",
                             "constructor": "make-view-availability"},
            "views": ["evidence/healthy.view.json", "evidence/changing.view.json"]}))

    def test_changed_reference_is_queryable_but_cannot_supply_domain_support(self):
        receipt = self.root / "evidence/changing.md"
        receipt.write_text("different")
        with self.assertRaises(ReferenceUnavailable):
            load(self.root, "evidence/changing.view.json")
        with engine_api() as (engine, _):
            healthy = repository_clues(self.root, "healthy-claim", engine)
            self.assertEqual(healthy["brief"]["counts"]["support"], 1)
            coverage = healthy["brief"]["evidenceCoverage"]
            self.assertFalse(coverage["complete"])
            self.assertEqual(coverage["unavailableViews"], 1)
            ref = _repository_snapshot(self.root)["unavailableViews"][0]["references"][0]
            self.assertEqual(ref["observed"], digest(receipt))
            self.assertEqual(ref["reason"], "changed")
            diagnostic = repository_clues(self.root, "evidence-view-current:changing", engine)
            observation = diagnostic["brief"]["families"][0]["observations"][0]
            self.assertEqual(observation["polarity"], "counter")
            self.assertEqual(observation["factors"]["evidence-state"], ["provenance-unavailable"])
            stale = repository_clues(self.root, "changing-claim", engine)
            self.assertEqual(stale["brief"]["counts"]["support"], 0)
            with self.assertRaises(ReferenceUnavailable):
                evaluate(self.root, "evidence/changing.view.json", engine)

    def test_missing_reference_reappearance_invalidates_snapshot_then_restores_view(self):
        receipt = self.root / "evidence/changing.md"
        receipt.unlink()
        snapshot = _repository_snapshot(self.root)
        _current(snapshot)
        with engine_api() as (engine, _):
            missing = repository_clues(self.root, "evidence-view-current:changing", engine)
            observation = missing["brief"]["families"][0]["observations"][0]
            self.assertEqual(observation["factors"]["unavailable-reason"], ["missing"])
            receipt.write_text("changing")
            with self.assertRaisesRegex(ValueError, "source appeared"):
                _current(snapshot)
            restored = repository_clues(self.root, "changing-claim", engine,
                                       checkpoint=missing["checkpoint"])
            self.assertTrue(restored["brief"]["evidenceCoverage"]["complete"])
            self.assertEqual(restored["brief"]["counts"]["support"], 1)
            self.assertNotEqual(restored["brief"]["sourceIdentity"], missing["brief"]["sourceIdentity"])

    def test_invalid_code_and_path_contracts_are_not_softened_as_unavailability(self):
        (self.root / "evidence/changing.md").write_text("different")
        source = self.root / "evidence/clues.ss"
        source.write_text("(malformed Scheme")
        with self.assertRaises(ValueError) as error:
            _repository_snapshot(self.root)
        self.assertNotIsInstance(error.exception, ReferenceUnavailable)
        source.write_text((ROOT / "evidence/scenarios/stack-header/clues.ss").read_text())
        path = self.root / "evidence/changing.view.json"
        view = json.loads(path.read_text())
        view["references"][0]["path"] = "../outside.md"
        path.write_text(json.dumps(view))
        with self.assertRaisesRegex(ValueError, "relative evidence path"):
            _repository_snapshot(self.root)

    def test_missing_reference_alias_cannot_be_retargeted_inside_a_snapshot(self):
        receipt = self.root / "evidence/changing.md"
        receipt.unlink()
        receipt.symlink_to("absent.md")
        snapshot = _repository_snapshot(self.root)
        _current(snapshot)
        receipt.unlink()
        receipt.symlink_to("healthy.md")
        with self.assertRaisesRegex(ValueError, "reference changed during read"):
            _current(snapshot)

    def test_unavailable_only_registry_has_explicit_counter_not_empty_success(self):
        (self.root / "evidence/healthy.md").unlink()
        (self.root / "evidence/changing.md").unlink()
        with engine_api() as (engine, _):
            packet = repository_clues(self.root, ["evidence-view-current:healthy",
                "evidence-view-current:changing"], engine=engine)
        self.assertEqual(packet["brief"]["evidenceCoverage"]["availableViews"], 0)
        self.assertEqual(len(packet["brief"]["families"]), 2)
        self.assertTrue(all(o["polarity"] == "counter" for f in packet["brief"]["families"]
                            for o in f["observations"]))
        inventory = catalog(self.root)
        self.assertTrue(inventory["clueExchangeAvailable"])
        self.assertIn("unavailable-reason", inventory["factorNames"])
        self.assertFalse(inventory["evidenceCoverage"]["complete"])


if __name__ == "__main__":
    unittest.main()
