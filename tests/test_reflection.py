import copy
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.framework import digest
from gambit_smp.reflection import validate


class ReflectionTests(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "context.md").write_text("bounded observation")
        self.record = {"schema": "gambit-evidence-reflection.v1",
            "references": [{"id": "local", "kind": "observation", "path": "context.md",
                            "locator": "component", "scope": "not full GC"}],
            "requirements": [{"id": "payload", "status": "partial", "gap": "stubbed",
                              "conditions": ["Trace real payload"], "references": ["local"]}]}

    def test_reference_bytes_are_bound_but_not_admitted(self):
        self.assertEqual({"context.md": digest(self.root / "context.md")}, validate(self.root, self.record))
        before = validate(self.root, self.record)
        (self.root / "context.md").write_text("changed observation")
        self.assertNotEqual(before, validate(self.root, self.record))

    def test_incomplete_or_closed_requirements_are_rejected(self):
        for changes in ({"status": "closed"}, {"conditions": []},
                        {"references": ["unknown"]}, {"references": ["local", "local"]}):
            record = copy.deepcopy(self.record)
            record["requirements"][0].update(changes)
            with self.assertRaises(ValueError):
                validate(self.root, record)

    def test_disposable_or_external_references_are_rejected(self):
        for path in (".data/context.md", "/context.md", "../context.md"):
            self.record["references"][0]["path"] = path
            with self.assertRaises(ValueError):
                validate(self.root, self.record)

    def test_nested_artifacts_are_bound_and_tampering_fails_closed(self):
        (self.root / "snapshot.qnt").write_text("model snapshot")
        self.record["references"][0]["artifacts"] = [
            {"path": "snapshot.qnt", "sha256": digest(self.root / "snapshot.qnt")}]
        self.assertIn("snapshot.qnt", validate(self.root, self.record))
        (self.root / "snapshot.qnt").write_text("changed")
        with self.assertRaisesRegex(ValueError, "stale reflection artifact"):
            validate(self.root, self.record)

    def test_cache_aliases_cannot_supply_reference_or_nested_artifact(self):
        cache = self.root / ".data"
        cache.mkdir()
        target = cache / "receipt.json"
        target.write_text("replaceable receipt")
        (self.root / "receipt.json").symlink_to(target)
        record = copy.deepcopy(self.record)
        record["references"][0]["path"] = "receipt.json"
        with self.assertRaisesRegex(ValueError, "cache alias"):
            validate(self.root, record)
        self.record["references"][0]["artifacts"] = [
            {"path": "receipt.json", "sha256": digest(target)}]
        with self.assertRaisesRegex(ValueError, "cache alias"):
            validate(self.root, self.record)

    def test_durable_in_repository_symlink_remains_valid(self):
        (self.root / "reference.md").symlink_to(self.root / "context.md")
        self.record["references"][0]["path"] = "reference.md"
        self.assertEqual({"reference.md": digest(self.root / "context.md")},
                         validate(self.root, self.record))

    def test_repository_gc_reflection_has_eight_unclosed_requirements(self):
        root = Path(__file__).resolve().parents[1]
        audit = json.loads((root / "evidence/research-audit.json").read_text())
        record = next(issue["reflection"] for issue in audit["issues"]
                      if issue["id"] == "notification-component-source-refinement")
        self.assertEqual(8, len(record["requirements"]))
        expected = {reference["path"] for reference in record["references"]}
        expected.update(artifact["path"] for reference in record["references"]
                        for artifact in reference.get("artifacts", []))
        from gambit_smp.output_observations import TRANSCRIPT_SUFFIXES, REGISTRY
        expected = {name for name in expected if Path(name).suffix not in TRANSCRIPT_SUFFIXES} | {REGISTRY}
        self.assertEqual(expected, set(validate(root, record)))

    def test_preserved_full_step_timeout_cannot_qualify_as_a_model_pass(self):
        from gambit_smp.output_observations import recorded, check_model
        from tests.support import published_digest
        root = Path(__file__).resolve().parents[1]
        directory = root / "evidence/model-results/gc-source-wait-full-step-safety"
        record = json.loads((directory / "receipt.json").read_text())
        for name, expected in record["artifacts"].items():
            self.assertEqual(expected, published_digest(root, directory / name))
        output = recorded(root, directory / "check.portable.log")
        with self.assertRaises(ValueError):
            check_model(output, dict(variant='protocol', exit=record['exit'], timeout=record['timeout']))
        self.assertFalse(record["accepted"])
        self.assertFalse(record["wholeStateSpaceChecked"])
        self.assertGreater(record["lastReportedStates"]["queued"], 0)
