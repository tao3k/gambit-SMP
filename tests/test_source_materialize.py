import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import source_materialize as source
from gambit_smp.framework import digest


class SourceMaterializeTests(unittest.TestCase):
    def fixture(self, root):
        (root / ".data").mkdir()
        checkout = root / "vendor/gambit"
        checkout.mkdir(parents=True)
        candidate = root / ".data/candidate"
        base = {}
        for name in source.FILES:
            base[name] = b"base\n"
            target = candidate / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(b"candidate\n")
        archive = io.BytesIO()
        with tarfile.open(fileobj=archive, mode="w") as tree:
            for name, data in base.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                tree.addfile(info, io.BytesIO(data))
        def git(command, **kwargs):
            if "show" in command:
                return base[command[-1].split(":", 1)[1]]
            if "archive" in command:
                return archive.getvalue()
            raise AssertionError(command)
        return checkout, candidate, git

    def run_fixture(self, mode):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            checkout, candidate, git = self.fixture(root)
            lock_path, patch_path = root / "lock.json", root / "snapshot.patch"
            with patch.object(source, "ROOT", root), \
                 patch.object(source, "revision", return_value="a" * 40), \
                 patch.object(source.subprocess, "check_output", side_effect=git):
                lock = source.export(checkout, candidate, lock_path, patch_path)
                if mode == "patch-drift":
                    patch_path.write_text("changed")
                    with self.assertRaisesRegex(ValueError, "overlay drift"):
                        source.materialize(lock_path, root / "restored")
                    self.assertFalse((root / "restored").exists())
                    return
                if mode == "wrong-candidate":
                    lock["files"]["lib/mem.c"]["candidateSha256"] = "0" * 64
                    lock_path.write_text(json.dumps(lock))
                    with self.assertRaisesRegex(ValueError, "differs from candidate"):
                        source.materialize(lock_path, root / "restored")
                    self.assertFalse((root / "restored").exists())
                    return
                receipt = source.materialize(lock_path, root / "restored")
                self.assertFalse(receipt["configuredToolchainReproduced"])
                self.assertFalse(receipt["runtimeAdmitted"])
                for name in source.FILES:
                    self.assertEqual(digest(candidate / name), digest(root / "restored" / name))
                with self.assertRaisesRegex(ValueError, "fresh output"):
                    source.materialize(lock_path, root / "restored")
                with self.assertRaisesRegex(ValueError, "overwrite"):
                    source.export(checkout, candidate, lock_path, patch_path)

    def test_fresh_source_reproduces_exact_slice_not_runtime(self):
        self.run_fixture("pass")

    def test_patch_drift_fails_before_publishing_output(self):
        self.run_fixture("patch-drift")

    def test_candidate_digest_mismatch_does_not_publish(self):
        self.run_fixture("wrong-candidate")

    def test_checked_in_snapshot_has_no_personal_paths(self):
        lock = json.loads(source.LOCK.read_text())
        self.assertEqual("7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882", lock["revision"])
        overlay = source.ROOT / lock["patch"]
        self.assertEqual(lock["patchSha256"], digest(overlay))
        self.assertNotIn("/Users/", overlay.read_text())
        self.assertNotIn(".data/", overlay.read_text())


if __name__ == "__main__":
    unittest.main()
