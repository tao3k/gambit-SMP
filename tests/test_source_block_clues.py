"""Checked byte observations through the real Scheme/Clue/checkpoint boundary."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.evidence_views import load, reference_witnesses
from gambit_smp.framework import ROOT, digest
from gambit_smp.trajectory_exploration import repository_clues


class SourceBlockClueTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        storage = patch("gambit_smp.artifact_storage.durable_database_path",
                        return_value=self.root / "history.sqlite3")
        storage.start()
        self.addCleanup(storage.stop)
        folder = self.root / "evidence"
        folder.mkdir()
        (folder / "clues.ss").write_bytes((ROOT / "evidence/scenarios/stack-header/clues.ss").read_bytes())
        (folder / "components.json").write_text(json.dumps({"schema": "ascent.evidence-components.v1",
            "components": [{"id": "blocks", "source": "clues.ss", "exports": ["make-stack-entry-clues"],
                            "dependencies": []}]}))
        (folder / "views.json").write_text(json.dumps({"schema": "ascent.evidence-views.v1",
                                                      "views": ["evidence/blocks.view.json"]}))
        self.source = self.root / "header.h"
        self.block = b"#define WORD_BYTES 8\n"
        self.source.write_bytes(self.block + b"/* unrelated */\n")
        self.config = self.root / "config.h"
        self.config.write_bytes(b"#define TARGET_WORD_BITS 64\n")
        self.document = {"schema": "ascent.evidence-view.v1", "id": "source-block-fixture",
            "manifest": "evidence/components.json", "entry": "blocks", "constructor": "make-stack-entry-clues",
            "facts": {"observation": [["word-block", "word-byte-definition", "support", "word"]],
                      "attribute": [["word-block", "source-text", {"reference": "word", "field": "text"}]],
                      "edge": [["word-block", "unexplored-alternative", "open-reference"]],
                      "reference": {"references": True}},
            "queries": {"clue": "clue", "factor": "factor", "link": "link"},
            "references": [{"id": "config", "path": "config.h", "sha256": digest(self.config), "pointer": None},
                {"id": "word", "path": "header.h", "sha256": digest(self.source), "pointer": None,
                 "ranges": [{"start": 0, "end": len(self.block),
                             "sha256": hashlib.sha256(self.block).hexdigest()}], "context": ["config"]}]}
        self.save()

    def save(self):
        (self.root / "evidence/blocks.view.json").write_text(json.dumps(self.document))

    def read(self, **kwargs):
        return repository_clues(self.root, "word-byte-definition", **kwargs)

    def test_first_hit_is_host_attested_and_contains_the_actual_bytes(self):
        result = self.read()
        packet = json.dumps(result)
        self.assertIn("WORD_BYTES", packet)
        self.assertEqual(result["brief"]["counts"]["support"], 1)
        self.assertFalse(result["brief"]["runtimeAdmitted"])
        self.assertIn("unexplored-alternative", packet)
        _, facts, _, _ = load(self.root, "evidence/blocks.view.json")
        self.assertEqual(facts["attribute"][0][2].encode(), self.block)

    def test_resume_retains_the_block_after_a_disjoint_edit(self):
        first = self.read()
        continued = self.read(checkpoint=first["checkpoint"])
        self.assertEqual(continued["brief"]["families"], [])
        self.source.write_bytes(self.block + b"/* different unrelated bytes */\n")
        self.document["references"][1]["sha256"] = digest(self.source)
        self.save()
        refreshed = self.read(checkpoint=continued["checkpoint"])
        self.assertEqual(refreshed["brief"]["families"], [])
        self.assertFalse(refreshed["brief"]["runtimeAdmitted"])
        # A fresh read remains legal; checkpoints do not prohibit revisiting.
        self.assertEqual(self.read()["brief"]["counts"]["support"], 1)

    def test_changed_declared_context_reopens_the_observation(self):
        first = self.read()
        self.config.write_bytes(b"#define TARGET_WORD_BITS 32\n")
        self.document["references"][0]["sha256"] = digest(self.config)
        self.save()
        changed = self.read(checkpoint=first["checkpoint"])
        self.assertEqual(len(changed["brief"]["families"]), 1)
        before = reference_witnesses(self.root, self.document)["word"]["digest"]
        self.document["references"][1]["path"] = "other.h"
        (self.root / "other.h").write_bytes(self.source.read_bytes())
        self.assertNotEqual(before, reference_witnesses(self.root, self.document)["word"]["digest"])

    def test_drift_and_forged_range_never_acquire_attestation(self):
        self.document["references"][1]["ranges"][0]["sha256"] = "0" * 64
        self.save()
        with self.assertRaisesRegex(ValueError, "span byte identity mismatch"):
            self.read()
        self.document["references"][1]["ranges"][0]["sha256"] = hashlib.sha256(self.block).hexdigest()
        self.save()
        self.source.write_bytes(b"#define WORD_BYTES 4\n")
        with self.assertRaisesRegex(ValueError, "reference changed"):
            self.read()

    def test_context_cycle_and_ambiguous_ranges_are_rejected(self):
        self.document["references"][1]["context"] = ["word"]
        self.save()
        with self.assertRaisesRegex(ValueError, "acyclic"):
            self.read()
        self.document["references"][1]["context"] = []
        self.document["references"][1]["ranges"] *= 2
        self.save()
        with self.assertRaisesRegex(ValueError, "ordered disjoint"):
            self.read()

    def understanding(self):
        folder = self.root / "evidence"
        for name in ("source-understanding.ss", "source-understanding.components.json"):
            (folder / name).write_bytes((ROOT / "evidence/scenarios/stack-header" / name).read_bytes())
        self.document.update(manifest="evidence/source-understanding.components.json",
                             entry="understanding", constructor="make-source-block-clues")
        reviewed = reference_witnesses(self.root, self.document)["word"]["digest"]
        self.document["facts"]["understanding"] = [["word-review", "word-block", "word-unit-understanding",
            "The macro defines eight bytes; native target correspondence is not established.", "word", reviewed]]
        self.save()
        return reviewed

    def test_retained_understanding_is_conditional_and_reopens_when_its_basis_changes(self):
        self.understanding()
        first = repository_clues(self.root, "word-unit-understanding")
        self.assertEqual(first["brief"]["counts"]["support"], 0)
        self.assertIn("reviewed-bytes-current", json.dumps(first))
        # A compacted caller can retrieve just its summary without raw code.
        self.assertNotIn("#define WORD_BYTES", json.dumps(first))
        self.assertIn("eight bytes", json.dumps(first))
        self.config.write_bytes(b"#define TARGET_WORD_BITS 32\n")
        self.document["references"][0]["sha256"] = digest(self.config)
        self.save()
        after = repository_clues(self.root, "word-unit-understanding", checkpoint=first["checkpoint"])
        self.assertIn("changed-or-unavailable-review", json.dumps(after))
        self.assertEqual(len(after["brief"]["families"]), 1)
        self.assertFalse(after["brief"]["runtimeAdmitted"])

    def test_transitive_impact_and_unknown_radius_are_not_silently_reused(self):
        # The main block's bytes and direct context stay unchanged; an explicit
        # two-edge semantic dependency is what makes this interpretation stale.
        self.document["references"][1]["context"] = []
        reviewed = self.understanding()
        witness = self.root / "scope.md"
        witness.write_text("Fixture declaration: root calls helper; helper depends on config; config is a leaf.\n")
        self.document["references"].append(dict(id="scope", path="scope.md", sha256=digest(witness), pointer=None))
        facts = self.document["facts"]
        facts.update(impact_node=[["word-block", "word", reviewed], ["helper", "config", digest(self.config)],
                                  ["config", "config", digest(self.config)]],
            impact_dependency=[["word-block", "helper", "calls"], ["helper", "config", "configuration"]],
            impact_declaration=[["word-block", "fixture", 1], ["helper", "fixture", 1], ["config", "fixture", 0]],
            impact_witness=[[name, "fixture", "scope", digest(witness)] for name in ("word-block", "helper", "config")])
        self.document["queries"].update({name: name for name in (
            "summary_current", "impact_path", "impact_affected", "impact_boundary", "impact_unresolved", "summary_reusable")})
        self.save()
        from gambit_smp.evidence_views import evaluate
        from gambit_smp.ascent_program import engine_api
        with engine_api() as (engine, _):
            def infer():
                return evaluate(self.root, "evidence/blocks.view.json", engine)["answers"]
            current = infer()
            self.assertEqual(current["summary_reusable"], [("word-review",)])
            self.assertIn(("config", "word-block"), current["impact_path"])
            # A zero-dependency leaf is legal with its matching scoped witness.
            self.assertEqual(current["impact_boundary"], [])
            facts['impact_node'][0] = ['word-block', 'config', digest(self.config)]
            self.save()
            self.assertEqual(infer()['summary_reusable'], [])
            facts['impact_node'][0] = ['word-block', 'word', reviewed]
            self.save()
            first = repository_clues(self.root, "word-unit-understanding", engine)
            self.config.write_bytes(b"#define TARGET_WORD_BITS 32\n")
            self.document["references"][0]["sha256"] = digest(self.config)
            self.save()
            affected = infer()
            self.assertEqual(affected["summary_current"], [("word-review",)])
            self.assertEqual(affected["summary_reusable"], [])
            self.assertIn(("word-block", "config"), affected["impact_affected"])
            changed = repository_clues(self.root, "word-unit-understanding", engine, checkpoint=first["checkpoint"])
            self.assertEqual(len(changed["brief"]["families"]), 1)
            self.assertIn("impact-origin", json.dumps(changed))
            # Restore bytes, then omit a witness: absence of a change is not
            # proof that the impact radius has been enumerated completely.
            self.config.write_bytes(b"#define TARGET_WORD_BITS 64\n")
            self.document["references"][0]["sha256"] = digest(self.config)
            facts["impact_witness"] = [row for row in facts["impact_witness"] if row[0] != "helper"]
            self.save()
            unknown = infer()
            self.assertEqual(unknown["impact_affected"], [])
            self.assertEqual(unknown["summary_reusable"], [])
            self.assertIn(("word-block", "helper", "missing-current-scope-witness"), unknown["impact_unresolved"])


if __name__ == "__main__":
    unittest.main()
