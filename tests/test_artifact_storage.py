import ctypes
import errno
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.artifact_storage import clone_file, transfer_generation, transfer_tree


class ArtifactStorageTests(unittest.TestCase):
    def test_generation_source_symlink_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bytes").write_bytes(b"generation")
            (root / "source").symlink_to("bytes")
            with self.assertRaises(ValueError):
                transfer_generation(root / "source", root / "target")
            self.assertFalse((root / "target").exists())

    def test_generation_target_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.write_bytes(b"new")
            target.write_bytes(b"retained")
            with self.assertRaises(FileExistsError):
                transfer_generation(source, target)
            self.assertEqual(b"retained", target.read_bytes())

    def test_generation_permission_error_does_not_fall_back(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.write_bytes(b"generation")
            with patch("gambit_smp.artifact_storage.os.link", side_effect=PermissionError(errno.EACCES, "denied")), patch("gambit_smp.artifact_storage.shutil.copyfile") as copy:
                with self.assertRaises(PermissionError):
                    transfer_generation(source, target)
                copy.assert_not_called()

    def test_actual_transfer_preserves_bytes_without_shared_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            (source / "file").write_bytes(b"producer")
            (source / "link").symlink_to("file")
            target = root / "consumer"
            receipt = transfer_tree(source, target)
            self.assertEqual(b"producer", (target / "file").read_bytes())
            self.assertTrue((target / "link").is_symlink())
            self.assertNotEqual((source / "file").stat().st_ino, (target / "file").stat().st_ino)
            (target / "file").write_bytes(b"consumer")
            self.assertEqual(b"producer", (source / "file").read_bytes())
            self.assertEqual(1, sum(receipt["files"].values()))
            self.assertFalse(receipt["hardlinks"])
            self.assertEqual(len(b"producer"), receipt["logicalBytes"])

    def test_empty_runtime_view_can_receive_an_isolated_copy(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.mkdir()
            target.mkdir()
            (source / "file").write_bytes(b"data")
            transfer_tree(source, target, dirs_exist_ok=True)
            self.assertEqual(b"data", (target / "file").read_bytes())

    def test_populated_workspace_is_rejected_without_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "source", Path(directory) / "target"
            source.mkdir()
            target.mkdir()
            (source / "file").write_bytes(b"new")
            (target / "file").write_bytes(b"retained")
            with self.assertRaisesRegex(ValueError, "populated workspace"):
                transfer_tree(source, target, dirs_exist_ok=True)
            self.assertEqual(b"retained", (target / "file").read_bytes())

    def test_overlapping_trees_and_destination_links_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source"
            source.mkdir()
            link = Path(directory) / "link"
            link.symlink_to(source, target_is_directory=True)
            for target in (source, source / "child", link, source.parent):
                with self.subTest(target=target), self.assertRaises(ValueError):
                    transfer_tree(source, target, dirs_exist_ok=True)

    def test_cross_device_fallback_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / "a", Path(directory) / "b"
            source.write_bytes(b"content")

            def unavailable(*args):
                ctypes.set_errno(errno.EXDEV)
                return -1

            self.assertEqual("byte-copy", clone_file(source, target, clone=unavailable))
            self.assertEqual(b"content", target.read_bytes())

    def test_permission_failure_is_not_hidden_by_fallback(self):
        def denied(*args):
            ctypes.set_errno(errno.EACCES)
            return -1

        with patch("gambit_smp.artifact_storage.shutil.copy2") as copy:
            with self.assertRaises(PermissionError):
                clone_file("source", "target", clone=denied)
            copy.assert_not_called()
