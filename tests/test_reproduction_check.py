from pathlib import Path
import hashlib
import json
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import reproduction_check as reproduction


class ReproductionCheckTests(unittest.TestCase):
    def test_026_source_check_keeps_five_original_file_identities(self):
        result = reproduction.check_source(reproduction.ROOT, "evidence/runtime-source-026.lock.json")
        lock = json.loads((reproduction.ROOT / "evidence/runtime-source-026.lock.json").read_text())
        self.assertEqual(set(lock["files"]), set(result["candidateFiles"]))
        self.assertEqual(5, len(result["candidateFiles"]))
        self.assertNotIn("lib/mem.h", result["candidateFiles"])
        self.assertEqual("98b39f7204d1086550d2666be67f447f0f83410e941ef7f2cb3adbea3c19391f",
                         result["candidateFiles"]["lib/setup.c"])
        self.assertFalse(result["committedInputsChecked"])
        self.assertFalse(result["configuredToolchainReproduced"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(any(".data" in Path(name).parts for name in result["inputs"]))

    def test_candidate_source_check_uses_its_own_committed_gate(self):
        with patch.object(reproduction, "verify_committed", side_effect=ValueError(
                "research input is not committed: evidence/runtime-source-026.lock.json")) as gate, \
             patch.object(reproduction, "materialize") as materializer:
            with self.assertRaisesRegex(ValueError, "not committed"):
                reproduction.check_source(reproduction.ROOT, "evidence/runtime-source-026.lock.json", True)
        self.assertIn("evidence/runtime-source-026.lock.json", gate.call_args.args[1])
        self.assertNotIn("evidence/gc-recursive-queue-wait.json", gate.call_args.args[1])
        materializer.assert_not_called()

    def test_candidate_lock_cannot_substitute_revision_or_admit_runtime(self):
        name = "evidence/runtime-source-026.lock.json"
        original = reproduction.portable
        saved = json.loads(original(reproduction.ROOT, name).read_text())
        with tempfile.TemporaryDirectory() as directory:
            lock_path = Path(directory) / "lock.json"
            for field, value in (("revision", "0" * 40), ("runtimeAdmitted", True),
                                 ("configuredToolchainReproduced", True)):
                data = {**saved, field: value}
                lock_path.write_text(json.dumps(data))
                with self.subTest(field=field), patch.object(reproduction, "portable",
                        side_effect=lambda root, item: lock_path if item == name else original(root, item)), \
                     self.assertRaisesRegex(ValueError, "pinned source capsule"):
                    reproduction.check_source(reproduction.ROOT, name)

    def test_candidate_digest_mismatch_fails_actual_materialization(self):
        name = "evidence/runtime-source-026.lock.json"
        original = reproduction.portable
        saved = json.loads(original(reproduction.ROOT, name).read_text())
        saved["files"]["lib/setup.c"]["candidateSha256"] = "0" * 64
        with tempfile.TemporaryDirectory() as directory:
            lock_path = Path(directory) / "lock.json"
            lock_path.write_text(json.dumps(saved))
            with patch.object(reproduction, "portable",
                    side_effect=lambda root, item: lock_path if item == name else original(root, item)), \
                 self.assertRaisesRegex(ValueError, "differs from candidate"):
                reproduction.check_source(reproduction.ROOT, name)

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
