"""Historical publication is byte provenance, not another admission route."""
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import digest
from gambit_smp.native_archive import publish_observation, validate_publication


class ObservationPublicationTests(unittest.TestCase):
    def fixture(self, root):
        source = root / "raw"
        source.mkdir()
        (source / "failure.log").write_text("/Users/another-person/work/failed.c: failure\n")
        (source / "scratch.bin").write_bytes(b"\x00\xff")
        receipt = {"status": "DENY", "accepted": False, "exit": 75,
                   "timeout": False, "seconds": 8.5, "runtimeAdmitted": False,
                   "cwd": "/Users/another-person/work", "logSha256": digest(source / "failure.log")}
        (source / "receipt.json").write_text(json.dumps(receipt))
        spec = dict(schema="gambit-observation-publication-source.v1",
                    scope="Historical failed observation, not a new test",
                    files={name: digest(source / name) for name in ("receipt.json", "failure.log")},
                    omitted={"scratch.bin": dict(sha256=digest(source / "scratch.bin"), reason="binary scratch retained privately")},
                    bindings=[dict(document="receipt.json", pointer="/logSha256", artifact="failure.log")])
        declaration = root / "declaration.json"
        declaration.write_text(json.dumps(spec))
        return source, declaration, spec, receipt

    def test_redaction_preserves_raw_bytes_verdicts_and_digest_namespace(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            source, declaration, spec, receipt = self.fixture(root)
            raw = {p.name: p.read_bytes() for p in source.iterdir()}
            saved = publish_observation(source, root / "public", declaration)
            self.assertEqual(raw, {p.name: p.read_bytes() for p in source.iterdir()})
            published = json.loads((root / "public/receipt.json").read_text())
            self.assertEqual(published, dict(receipt, cwd="<HOME>/work"))
            self.assertNotEqual(saved["files"]["failure.log"], receipt["logSha256"])
            self.assertEqual(saved["originalFiles"], spec["files"])
            self.assertFalse(saved["runtimeAdmitted"])
            self.assertIsNone(saved["observedParentExit"])
            self.assertFalse((root / "public/scratch.bin").exists())
            self.assertEqual(saved, validate_publication(root / "public"))

    def test_wrong_raw_hash_missing_or_extra_source_is_rejected_before_writing(self):
        for alteration in ("hash", "missing", "extra"):
            with self.subTest(alteration=alteration), tempfile.TemporaryDirectory() as d:
                root = Path(d)
                source, declaration, spec, _ = self.fixture(root)
                if alteration == "hash":
                    spec["files"]["failure.log"] = "0" * 64
                    declaration.write_text(json.dumps(spec))
                elif alteration == "missing":
                    (source / "failure.log").unlink()
                else:
                    (source / "unregistered.log").write_text("unaccounted")
                with self.assertRaisesRegex(ValueError, "inventory changed"):
                    publish_observation(source, root / "public", declaration)
                self.assertFalse((root / "public").exists())

    def test_forged_raw_binding_is_rejected_not_rehashed(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            source, declaration, spec, receipt = self.fixture(root)
            receipt["logSha256"] = "0" * 64
            (source / "receipt.json").write_text(json.dumps(receipt))
            spec["files"]["receipt.json"] = digest(source / "receipt.json")
            declaration.write_text(json.dumps(spec))
            with self.assertRaisesRegex(ValueError, "binding differs"):
                publish_observation(source, root / "public", declaration)
            self.assertFalse((root / "public").exists())

    def test_public_mutation_missing_extra_or_admission_is_rejected(self):
        for alteration in ("changed", "missing", "extra", "admission"):
            with self.subTest(alteration=alteration), tempfile.TemporaryDirectory() as d:
                root = Path(d)
                source, declaration, _, _ = self.fixture(root)
                saved = publish_observation(source, root / "public", declaration)
                if alteration == "changed":
                    (root / "public/failure.log").write_text("PASS")
                elif alteration == "missing":
                    (root / "public/failure.log").unlink()
                elif alteration == "extra":
                    (root / "public/unregistered.log").write_text("extra")
                else:
                    saved["runtimeAdmitted"] = True
                    (root / "public/archive.json").write_text(json.dumps(saved))
                with self.assertRaises(ValueError):
                    validate_publication(root / "public")

    def test_alias_and_overlapping_output_are_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            source, declaration, _, _ = self.fixture(root)
            with self.assertRaisesRegex(ValueError, "separate"):
                publish_observation(source, source / "public", declaration)
            (source / "alias").symlink_to(declaration)
            with self.assertRaisesRegex(ValueError, "aliases"):
                publish_observation(source, root / "public", declaration)

    def test_export_cannot_write_runtime_observations_into_git_sources(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            source, declaration, _, _ = self.fixture(root)
            with patch("gambit_smp.framework.ROOT", root.resolve()), patch(
                    "gambit_smp.task_dependencies.default_task", return_value=None), patch(
                    "gambit_smp.artifact_storage.repository_root", return_value=root.resolve()):
                with self.assertRaisesRegex(ValueError, "not Git source"):
                    publish_observation(source, root / "evidence/results", declaration)
            self.assertFalse((root / "evidence").exists())

    def test_source_custody_is_rechecked_after_transform(self):
        from unittest.mock import patch
        from gambit_smp.native_archive import observation_text
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            source, declaration, _, _ = self.fixture(root)
            def changed(text):
                (source / "failure.log").write_text("changed during transformation")
                return observation_text(text)
            with patch("gambit_smp.native_archive.observation_text", side_effect=changed):
                with self.assertRaisesRegex(ValueError, "changed during redaction"):
                    publish_observation(source, root / "public", declaration)
            self.assertFalse((root / "public").exists())
