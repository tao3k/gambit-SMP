from pathlib import Path
import json
import os
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

    def test_task_and_process_attempts_cannot_hide_complete_source_copies(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = self.tree(root / '.cache/fixtures/original/source')
            for relative in ('.cache/tasks/repair/fixtures/inventory-3/source',
                             '.cache/tasks/repair/runs/another/source',
                             '.cache/tasks/repair/processes/audit/runs/another/source'):
                target = root / relative
                with self.assertRaisesRegex(ValueError, 'maintained build product'):
                    transfer_tree(source, target)
                self.assertFalse(target.exists())

    def test_maintained_product_and_explicit_transient_delta_do_not_need_another_fixture(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            product = root / '.cache/tasks/repair/build/gambit-core' / ('a' * 64) / 'source'
            with source_capacity(product):
                self.tree(product)
            delta = root / '.cache/tasks/repair/runs/one/candidate/source'
            with source_capacity(delta, staging=True):
                self.tree(delta)
            with self.assertRaisesRegex(ValueError, 'maintained build product'):
                with source_capacity(delta):
                    self.fail('transient delta became an unmanaged reusable source')

    def test_nested_task_namespace_cannot_masquerade_as_another_managed_product(self):
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary).resolve()
            forged = project/'.cache/tasks/repair/agents/owner/.cache/tasks/another/build/core'/('a'*64)/'source'
            with patch.dict(os.environ, {'GAMBIT_SMP_TASK_ROOT': str(project)}):
                with self.assertRaisesRegex(ValueError, 'nested task stores'):
                    with source_capacity(forged):
                        self.fail('a nested task namespace escaped product ownership')

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

    def test_task_duplicate_cleanup_checks_archive_bytes_and_keeps_failure_records(self):
        from tests.test_runtime_artifact import fixture, pack
        from gambit_smp.fixture_storage import discard_bindings
        from gambit_smp.framework import digest
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            original, value = fixture(project)
            archive = project / 'runtime.tar'; pack(archive, original, value)
            root = project / '.cache/tasks/repair/fixtures'
            duplicate = root / 'inventory-1/run/runtime/generation/runtime'
            # This deliberately creates the pre-migration historical layout.
            import shutil
            shutil.copytree(original, duplicate, symlinks=True)
            (duplicate/'failure.json').write_text('{"outcome":"DENY"}')
            declaration = dict(schema='artifact-backed-source-discard.v1', archive=str(archive),
                sha256=digest(archive), trees={str(duplicate.relative_to(root)):'runtime'})
            discard = discard_bindings(root, declaration, [duplicate])
            self.assertIn(str((duplicate/'program').relative_to(root)), discard)
            with patch('gambit_smp.fixture_storage.subprocess.run',
                       return_value=SimpleNamespace(returncode=0, stdout='n/unrelated\n')):
                result = prune(root, [], project/'retained', targets=[duplicate], discard=discard, apply=True)
            self.assertFalse(duplicate.exists())
            self.assertTrue((original/'program').is_file())
            self.assertEqual(1, len(result['removed']))
            retained = project/'retained/evidence'/duplicate.relative_to(root)
            self.assertEqual({'outcome':'DENY'}, json.loads((retained/'failure.json').read_text()))
            self.assertFalse((retained/'program').exists())
            declaration['sha256'] = '0' * 64
            with self.assertRaisesRegex(ValueError, 'archive changed'):
                discard_bindings(root, declaration, [])

    def test_maintenance_cleanup_cannot_gain_general_parent_task_write_authority(self):
        from gambit_smp.storage_policy import enforce, retiring_fixture, StoragePolicyError
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary).resolve()
            root = project/'.cache/tasks/repair/fixtures'
            target = self.tree(root/'old/source')
            (target/'nested').mkdir()
            (target/'nested/failure.log').write_text('retain descriptor-relative failure log')
            product = self.tree(project/'.cache/tasks/repair/build/gambit-core'/('a'*64)/'source')
            archive = project/'.cache/tasks/repair/processes/audit/runs/one/cleanup'
            archive.parent.mkdir(parents=True)
            with patch.dict(os.environ, {'GAMBIT_SMP_TASK_PROCESS':'audit'}), enforce(project, 'repair'):
                with self.assertRaises(StoragePolicyError):
                    (target/'lib/setup.c').unlink()
                with self.assertRaises(StoragePolicyError):
                    with retiring_fixture(product):
                        self.fail('build product was admitted for cleanup')
                with patch('gambit_smp.fixture_storage.subprocess.run',
                           return_value=SimpleNamespace(returncode=0, stdout='n/unrelated\n')):
                    record = prune(root, [], archive, targets=[target], apply=True)
                self.assertEqual(1, len(record['removed']))
                self.assertTrue((archive/'evidence/old/source/nested/failure.log').is_file())
                self.assertTrue((product/'lib/setup.c').exists())
                with self.assertRaises(StoragePolicyError):
                    (product/'lib/setup.c').unlink()
                descriptor = os.open(product/'lib', os.O_RDONLY)
                try:
                    with self.assertRaises(StoragePolicyError):
                        os.unlink('setup.c', dir_fd=descriptor)
                finally:
                    os.close(descriptor)
