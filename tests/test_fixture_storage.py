from pathlib import Path
import fcntl
import hashlib
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

from gambit_smp.fixture_storage import prune, source_capacity, source_trees
from gambit_smp.artifact_storage import transfer_tree


class FixtureStorageTests(unittest.TestCase):
    def test_explicit_targets_preserve_unknown_bytes_and_all_log_names(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data"
            kept = self.tree(root / "working")
            target = self.tree(root / "reproduction")
            (target / "compile.stderr").write_bytes(b"original failure\n")
            (target / "unknown-artifact").write_bytes(b"not classified as cache")
            name = "reproduction/lib/setup.c"
            discard = {name: hashlib.sha256((root / name).read_bytes()).hexdigest()}
            archive = root.parent / "archive"
            with patch("gambit_smp.fixture_storage.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="n/unrelated\n")):
                result = prune(root, [kept], archive, targets=[target], discard=discard, apply=True)
            self.assertTrue(kept.is_dir())
            self.assertFalse(target.exists())
            self.assertTrue(result["evidencePreserved"])
            self.assertEqual((archive / "evidence/reproduction/compile.stderr").read_bytes(), b"original failure\n")
            self.assertTrue((archive / "evidence/reproduction/unknown-artifact").is_file())
            self.assertFalse((archive / ("evidence/" + name)).exists())
            self.assertEqual(result["inventories"]["reproduction"][name]["sha256"], discard[name])

    def test_wrong_discard_digest_does_not_remove_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data/fixtures"
            target = self.tree(root / "old")
            with patch("gambit_smp.fixture_storage.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="n/unrelated\n")):
                with self.assertRaisesRegex(ValueError, "discard source identity"):
                    prune(root, [], root.parent / "archive", targets=[target],
                          discard={"old/lib/setup.c": "0" * 64}, apply=True)
            self.assertTrue(target.is_dir())

    def test_held_workspace_lease_and_evidence_discard_are_denied(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data/fixtures"
            target = self.tree(root / "old").resolve()
            locks = root.parent / "workspace-leases"
            locks.mkdir()
            key = hashlib.sha256(str(target).encode()).hexdigest()
            with (locks / (key + ".lock")).open("a") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                with patch("gambit_smp.fixture_storage.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="n/unrelated\n")):
                    with self.assertRaisesRegex(ValueError, "leased workspace"):
                        prune(root, [], root.parent / "archive", targets=[target], apply=True)
            with self.assertRaisesRegex(ValueError, "non-evidence discard"):
                prune(root, [], root.parent / "other", targets=[target], discard={"old/failure.json": "0" * 64})

    def tree(self, path):
        (path / "lib").mkdir(parents=True)
        (path / "include").mkdir()
        (path / "lib/setup.c").write_text("source")
        return path

    def test_third_source_is_denied(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data/fixtures"
            first = self.tree(root / "baseline")
            self.tree(root / "candidate")
            with self.assertRaisesRegex(ValueError, "limit is 2"):
                with source_capacity(root / "extra"):
                    self.fail("capacity guard did not reject")
            with source_capacity(first):
                self.assertEqual(2, len(source_trees(root)))

    def test_same_fixture_can_advance_through_multiple_source_stages(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".cache/fixtures"
            self.tree(root / "current/run/candidate/source")
            self.tree(root / "current/run/configure/source")
            with source_capacity(root / "current/run/seed/source"):
                self.tree(root / "current/run/seed/source")
            self.tree(root / "baseline/source")
            with self.assertRaisesRegex(ValueError, "limit is 2"):
                with source_capacity(root / "unrelated/source"):
                    self.fail("third independent fixture was admitted")

    def test_prune_preserves_failure_evidence_and_kept_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data/fixtures"
            kept = self.tree(root / "baseline")
            removed = self.tree(root / "old")
            (removed / "failure.json").write_text('{"status":"DENY"}')
            archive = root.parent / "archive"
            with patch("gambit_smp.fixture_storage.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="n/unrelated\n")):
                record = prune(root, [kept], archive, apply=True)
            self.assertEqual(["old"], record["removed"])
            self.assertTrue(kept.is_dir())
            self.assertFalse(removed.exists())
            self.assertEqual('{"status":"DENY"}', (archive / "evidence/old/failure.json").read_text())

    def test_transfer_cannot_bypass_capacity(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data/fixtures"
            source = self.tree(root / "baseline")
            self.tree(root / "candidate")
            with self.assertRaisesRegex(ValueError, "limit is 2"):
                transfer_tree(source, root / "extra")
            self.assertFalse((root / "extra").exists())

    def test_git_checkout_is_protected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data/fixtures"
            kept = self.tree(root / "baseline")
            checkout = self.tree(root / "checkout")
            (checkout / ".git").mkdir()
            with patch("gambit_smp.fixture_storage.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="n/unrelated\n")):
                record = prune(root, [kept], root.parent / "archive", apply=True)
            self.assertEqual(["checkout"], record["gitProtected"])
            self.assertTrue(checkout.is_dir())

    def test_active_tree_is_not_deleted(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / ".data/fixtures"
            kept = self.tree(root / "baseline")
            active = self.tree(root / "active")
            with patch("gambit_smp.fixture_storage.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout=f"n{active.resolve()}/lib/setup.c\n")):
                record = prune(root, [kept], root.parent / "archive", apply=True)
            self.assertEqual(["active"], record["activeProtected"])
            self.assertEqual([], record["removed"])
            self.assertTrue(active.is_dir())
