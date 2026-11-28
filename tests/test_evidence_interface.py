"""Real DSL/answer publication, exact bytes and bound-fact tamper controls."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.ascent_program import engine_api
from gambit_smp.evidence_views import evaluate
from gambit_smp.evidence_interface import write, read
from gambit_smp.framework import ROOT, digest

VIEW = "evidence/scenarios/concurrent-gc/reasoning-methods.view.json"


class EvidenceInterfaceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with engine_api() as (engine, _):
            cls.view = evaluate(ROOT, VIEW, engine)
        cls.inputs = {str(Path(p).relative_to(ROOT)): sha for p, sha in cls.view["inputs"].items()}

    def publish(self, directory):
        out = Path(directory)
        artifacts = write(ROOT, out, [self.view], self.inputs)
        review = {"evidenceViews": [self.view], "agentGraph": {"checkout": {"root": str(ROOT)}}}
        artifacts.update({name: {} for name in ("review.json", "graph.json", "context.md", "graph.mmd")})
        return out, artifacts, review

    def test_real_rules_facts_answers_and_dependencies_are_not_rewritten(self):
        with tempfile.TemporaryDirectory() as directory:
            out, artifacts, review = self.publish(directory)
            interface = read(out, artifacts, review)
            entry = interface["views"][0]
            manifest = json.loads((ROOT / "evidence/dsl/reasoning-methods.components.json").read_bytes())
            self.assertEqual([c["declaration"] for c in entry["components"]], manifest["components"])
            source = entry["components"][0]["source"]
            self.assertEqual((out / source["path"]).read_bytes(), (ROOT / "evidence/dsl/reasoning-methods.ss").read_bytes())
            self.assertEqual(json.loads((out / entry["facts"]["path"]).read_bytes()), self.view["facts"])
            answers = json.loads((out / entry["answers"]["path"]).read_bytes())
            self.assertEqual(len(answers["options"]), 4)
            self.assertEqual(len(answers["missing"]), 9)
            self.assertEqual(answers["supported"], [])
            self.assertEqual(interface["selection"], "open-world-unordered")
            self.assertFalse(interface["executionAuthorized"])

    def test_rehashed_fact_and_answer_substitution_cannot_change_evaluated_semantics(self):
        for field in ("facts", "answers"):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as directory:
                out, artifacts, review = self.publish(directory)
                path = out / "evidence.json"
                interface = json.loads(path.read_bytes())
                descriptor = interface["views"][0][field]
                changed = out / descriptor["path"]
                changed.write_text('{}\n')
                descriptor["sha256"] = digest(changed)
                artifacts[descriptor["path"]] = descriptor
                path.write_text(json.dumps(interface))
                artifacts["evidence.json"]["sha256"] = digest(path)
                with self.assertRaisesRegex(ValueError, "differs|differ"):
                    read(out, artifacts, review)

    def test_missing_view_or_dependency_inventory_is_not_complete(self):
        with tempfile.TemporaryDirectory() as directory:
            out, artifacts, review = self.publish(directory)
            path = out / "evidence.json"
            original = json.loads(path.read_bytes())
            for replacement in (dict(original, views=[]), dict(original, views=[dict(original["views"][0], components=[])])):
                path.write_text(json.dumps(replacement))
                artifacts["evidence.json"]["sha256"] = digest(path)
                with self.assertRaisesRegex(ValueError, "inventory|differs"):
                    read(out, artifacts, review)

    def test_raw_rule_drift_cannot_be_consumed_as_the_original_program(self):
        with tempfile.TemporaryDirectory() as directory:
            out, artifacts, review = self.publish(directory)
            index = json.loads((out / "evidence.json").read_bytes())
            rule = out / index["views"][0]["components"][0]["source"]["path"]
            rule.write_text('(define-evidence (changed))\n')
            with self.assertRaisesRegex(ValueError, "artifact identity differs"):
                read(out, artifacts, review)

    def test_unbound_source_and_duplicate_views_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory, self.assertRaisesRegex(ValueError, "not bound"):
            write(ROOT, Path(directory), [self.view], {})
        with tempfile.TemporaryDirectory() as directory, self.assertRaisesRegex(ValueError, "duplicate"):
            write(ROOT, Path(directory), [self.view, self.view], self.inputs)
        changed = copy.deepcopy(self.view)
        changed["inputs"][str(ROOT / VIEW)] = "changed"
        with tempfile.TemporaryDirectory() as directory, self.assertRaisesRegex(ValueError, "differs"):
            write(ROOT, Path(directory), [changed], self.inputs)


if __name__ == "__main__":
    unittest.main()
