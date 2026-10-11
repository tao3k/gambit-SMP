from pathlib import Path
import hashlib
import json
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import reproduction_check as reproduction


class ReproductionCheckTests(unittest.TestCase):
    def test_current_inputs_are_cache_independent(self):
        result = reproduction.check(reproduction.ROOT, "evidence/gc-recursive-queue-wait.json")
        self.assertEqual(7, result["papers"])
        self.assertFalse(result["committedInputsChecked"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(any(".data" in Path(name).parts for name in result["inputs"]))
        self.assertIn("models/gambit/gc_recursive_queue_wait.qnt", result["inputs"])

    def test_inventory_exposes_cache_dependencies_without_rewriting(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "evidence").mkdir()
            legacy = root / "evidence/legacy.json"
            data = json.dumps({"contextInputs": {".data/paper.txt": "old"}})
            legacy.write_text(data)
            result = reproduction.inventory(root)
            self.assertEqual(1, result["blocked"])
            self.assertEqual(0, result["portable"])
            self.assertEqual(data, legacy.read_text())
            self.assertFalse(result["runtimeAdmitted"])

    def test_manifest_requires_model_and_matching_context(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "evidence").mkdir()
            note = root / "note.md"
            note.write_text("note")
            manifest = root / "evidence/model.json"
            manifest.write_text(json.dumps({"cases": [{"id": "example"}],
                "contextInputs": {"note.md": hashlib.sha256(note.read_bytes()).hexdigest()}}))
            self.assertEqual(1, reproduction.inventory(root)["blocked"])
            model = root / "models/gambit/example.qnt"
            model.parent.mkdir(parents=True)
            model.write_text("module example {}")
            self.assertEqual(1, reproduction.inventory(root)["portable"])
            note.write_text("changed")
            self.assertEqual(1, reproduction.inventory(root)["blocked"])

    def test_strict_inventory_rejects_uncommitted_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "evidence").mkdir()
            (root / "evidence/model.json").write_text(json.dumps({"contextInputs": {}}))
            with patch.object(reproduction, "check", side_effect=ValueError(
                    "research input is not committed: docs/note.md")) as checker:
                result = reproduction.inventory(root, require_committed=True)
            checker.assert_called_once_with(root, "evidence/model.json", require_committed=True)
            self.assertEqual(1, result["blocked"])
            self.assertTrue(result["committedInputsChecked"])
            self.assertFalse(result["manifests"][0]["committedInputsVerified"])
            self.assertIn("not committed", result["manifests"][0]["issues"][0])

    def test_strict_inventory_verifies_each_portable_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "evidence").mkdir()
            for name in ("a", "b"):
                (root / f"evidence/{name}.json").write_text(json.dumps({"contextInputs": {}}))
            with patch.object(reproduction, "check", return_value={}) as checker:
                result = reproduction.inventory(root, require_committed=True)
            self.assertEqual(2, checker.call_count)
            self.assertEqual(2, result["portable"])
            self.assertTrue(all(row["committedInputsVerified"] for row in result["manifests"]))
            self.assertFalse(result["networkReproductionChecked"])

    def test_cache_absolute_and_parent_paths_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".data").mkdir()
            cached = root / ".data/paper.md"
            cached.write_text("cached")
            for name in (str(cached), ".data/paper.md", "docs/../.data/paper.md"):
                with self.subTest(name=name), self.assertRaisesRegex(ValueError, "non-portable"):
                    reproduction.portable(root, name)

    def test_external_symlink_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / "repo"
            root.mkdir()
            outside = root.parent / "note.md"
            outside.write_text("outside")
            (root / "note.md").symlink_to(outside)
            with self.assertRaisesRegex(ValueError, "non-portable"):
                reproduction.portable(root, "note.md")

    def test_relative_symlink_into_cache_is_not_a_portable_input(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".data").mkdir()
            (root / ".data/mem.c").write_text("cached source")
            (root / "vendor").mkdir()
            (root / "vendor/mem.c").symlink_to("../.data/mem.c")
            (root / "source").symlink_to(".data", target_is_directory=True)
            for name in ("vendor/mem.c", "source/mem.c"):
                with self.subTest(name=name), self.assertRaisesRegex(ValueError, "non-portable"):
                    reproduction.portable(root, name)
            (root / "evidence").mkdir()
            manifest = root / "evidence/model.json"
            original = json.dumps({"contextInputs": {"vendor/mem.c": "old"}})
            manifest.write_text(original)
            self.assertEqual(1, reproduction.inventory(root)["blocked"])
            self.assertEqual(original, manifest.read_text())

    def test_relative_source_symlink_outside_cache_is_portable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "vendor").mkdir()
            source = root / "vendor/mem.c"
            source.write_text("pinned source")
            (root / "mem.c").symlink_to("vendor/mem.c")
            self.assertEqual(source.resolve(), reproduction.portable(root, "mem.c"))

    def test_model_context_cannot_silently_change(self):
        original = reproduction.hashlib.sha256
        with patch.object(reproduction.hashlib, "sha256") as sha:
            sha.side_effect = lambda data: original(data + b"changed")
            with self.assertRaisesRegex(ValueError, "source differs|overlay differs|capsule binding"):
                reproduction.check(reproduction.ROOT, "evidence/gc-recursive-queue-wait.json")

    def test_uncommitted_gitlink_is_not_clean_checkout_evidence(self):
        original = reproduction.git
        def git(root, *args):
            return "" if args[0] == "ls-tree" else original(root, *args)
        with patch.object(reproduction, "git", side_effect=git):
            with self.assertRaisesRegex(ValueError, "gitlink is not committed"):
                reproduction.check(reproduction.ROOT,
                                   "evidence/gc-recursive-queue-wait.json", True)


if __name__ == "__main__":
    unittest.main()
