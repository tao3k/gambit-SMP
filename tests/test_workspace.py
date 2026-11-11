import hashlib
from contextlib import closing
from contextlib import contextmanager
import json
import os
from datetime import date
from pathlib import Path
import subprocess
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import workspace as w
from gambit_smp import storage_retention as retention
from gambit_smp.artifact_storage import runtime_output


class WorkspaceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        w.git(self.root, "init", "-q")
        w.git(self.root, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
              "commit", "--allow-empty", "-qm", "initial")

    def old(self, path):
        os.utime(path, (1, 1), follow_symlinks=False)

    def test_task_reuse_and_provider_independent_routing(self):
        first = w.start(self.root, "repair-9-12", adopt=True)
        self.assertEqual(first, w.start(self.root, "repair-9-12", adopt=True))
        for provider in ("codex", "grok"):
            with w.execution_scope(self.root, "repair-9-12", provider=provider):
                self.assertEqual(self.root / ".cache/tasks/repair-9-12/runs" / os.environ['GAMBIT_SMP_TASK_RUN'] / 'outputs/checks',
                                 runtime_output(self.root, ".cache/checks"))
                with self.assertRaises(ValueError):
                    runtime_output(self.root, ".cache/tasks/other/checks")
                with self.assertRaises(ValueError):
                    runtime_output(self.root, ".cache/../src")

    def test_build_entry_reconciles_its_owner_without_global_retention(self):
        w.start(self.root,'modern-c',adopt=True)
        with patch.object(w,'collect') as collect, \
                patch.object(w,'transition_check',wraps=w.transition_check) as check:
            with w.execution_scope(self.root,'modern-c'):
                pass
        collect.assert_not_called()
        self.assertTrue(any(call.kwargs.get('takeover') is True for call in check.call_args_list))

    def test_run_passes_task_context_and_keeps_exit_status(self):
        w.start(self.root, "repair", adopt=True)
        command = [sys.executable, "-c", "import os; assert os.environ['GAMBIT_SMP_TASK_ID']=='repair'; raise SystemExit(7)"]
        self.assertEqual(7, w.execute(self.root, "repair", command, provider="codex"))
        value = json.loads(w.paths(self.root, "repair")[0].read_text())
        self.assertEqual("unverified", value["descendants"])
        self.assertEqual("open", value["state"])

    def test_exclusive_lease_and_open_task_never_expires(self):
        w.start(self.root, "repair", adopt=True)
        with w.lease(self.root, "repair"):
            with self.assertRaises(BlockingIOError):
                w.finish(self.root, "repair")
        self.assertFalse(w.reclaim(self.root, "repair", today=date(2099, 1, 1), opened=[])["removed"])

    def test_two_calendar_day_cutoff_and_open_reference(self):
        w.start(self.root, "repair", adopt=True)
        w.finish(self.root, "repair")
        record, cache, _ = w.paths(self.root, "repair")
        value = json.loads(record.read_text())
        value["lastActivity"] = "2026-10-19T00:00:00+08:00"
        w.write(record, value)
        self.assertFalse(w.reclaim(self.root, "repair", today=date(2026, 10, 20), opened=[])["removed"])
        value["lastActivity"] = "2026-10-18T23:59:59+08:00"
        w.write(record, value)
        self.assertFalse(w.reclaim(self.root, "repair", today=date(2026, 10, 20), opened=[cache / "log"])["removed"])
        self.assertTrue(w.reclaim(self.root, "repair", today=date(2026, 10, 20), opened=[])["removed"])
        self.assertTrue(record.exists())

    def test_storage_alias_rejected_before_mkdir(self):
        (self.root / ".cache").symlink_to(self.root.parent)
        with self.assertRaisesRegex(ValueError, "aliases"):
            w.start(self.root, "repair", adopt=True)

    def test_new_task_never_silently_reuses_a_shared_dirty_checkout(self):
        (self.root / "uncommitted").write_text("keep")
        with self.assertRaisesRegex(ValueError, "explicit --adopt"):
            w.start(self.root, "new")
        self.assertFalse(w.paths(self.root, "new")[0].exists())

    def test_unreadable_task_subtree_cannot_hide_operational_state_from_gc(self):
        w.start(self.root, "expired", adopt=True)
        w.finish(self.root, "expired")
        record, cache, _ = w.paths(self.root, "expired")
        value = json.loads(record.read_text())
        value["lastActivity"] = "2000-01-01T00:00:00+08:00"
        w.write(record, value)
        hidden = cache / "hidden"
        hidden.mkdir()
        (hidden / "requests.sqlite").write_text("must survive")
        hidden.chmod(0)
        try:
            with self.assertRaises(PermissionError):
                w.reclaim(self.root, "expired", opened=[])
        finally:
            hidden.chmod(0o700)
        self.assertTrue((hidden / "requests.sqlite").exists())

    def test_worktree_is_owned_by_git_not_cache_expiry(self):
        value = w.start(self.root, "repair", ref="HEAD")
        tree = Path(value["checkout"])
        self.assertEqual(self.root / ".data/worktrees/repair", tree)
        (tree / "unsaved").write_text("keep me")
        w.finish(self.root, "repair")
        with self.assertRaisesRegex(ValueError, "dirty"):
            w.remove_worktree(self.root, "repair", base="HEAD")
        (tree / "unsaved").unlink()
        with patch.object(w, "active_paths", return_value=[tree]):
            with self.assertRaisesRegex(ValueError, "occupied"):
                w.remove_worktree(self.root, "repair", base="HEAD")
        with patch.object(w, "active_paths", return_value=[]):
            w.remove_worktree(self.root, "repair", base="HEAD")
        self.assertFalse(tree.exists())

    def test_legacy_cleanup_preserves_recent_children_git_and_databases(self):
        for name in ("old", "recent-child", "checkout", "pending"):
            p = self.root / ".data" / name
            p.mkdir(parents=True)
            self.old(p)
        (self.root / ".data/recent-child/log").write_text("recent")
        (self.root / ".data/checkout/.git").mkdir()
        (self.root / ".data/pending/state.sqlite").write_text("state")
        for p in (self.root / ".data").rglob("*"):
            if "recent-child" not in p.parts:
                self.old(p)
        value = retention.plan(self.root, today=date(2026, 10, 20), opened=[])
        self.assertEqual([".data/old"], [row["path"] for row in value["targets"]])

    def test_legacy_manifest_change_refuses_deletion(self):
        p = self.root / ".cache/old"
        p.mkdir(parents=True)
        self.old(p)
        value = retention.plan(self.root, today=date(2026, 10, 20), opened=[])
        manifest = self.root / "plan.json"
        w.write(manifest, value)
        digest = hashlib.sha256(manifest.read_bytes()).hexdigest()
        (p / "new").write_text("keep")
        with patch.object(retention, "active_paths", return_value=[]):
            with self.assertRaisesRegex(ValueError, "changed"):
                retention.apply(self.root, manifest, digest)
        self.assertTrue(p.exists())

    def test_pending_action_rows_survive_durable_migration_and_cache_removal(self):
        from gambit_smp.research_actions import _database, _outcomes
        import shutil
        path = self.root / ".cache/research-actions/requests.sqlite"
        path.parent.mkdir(parents=True)
        with closing(sqlite3.connect(path)) as db:
            db.execute("CREATE TABLE requests (id TEXT PRIMARY KEY, body TEXT, result TEXT)")
            db.execute("INSERT INTO requests VALUES ('pending', '{}', NULL)")
            db.execute("INSERT INTO requests VALUES ('done', '{}', '{}')")
            db.commit()
        # Even a process retaining an old writable SQLite connection cannot
        # reserve another execution in the retired cache store.
        with closing(sqlite3.connect(path)) as legacy:
            legacy.execute("INSERT INTO requests VALUES ('relaunch', '{}', NULL)")
            legacy.rollback()
            with closing(_database(self.root)) as db:
                self.assertEqual(1, db.execute("SELECT count(*) FROM requests WHERE result IS NULL").fetchone()[0])
            with self.assertRaisesRegex(sqlite3.IntegrityError, "requests moved"):
                legacy.execute("INSERT INTO requests VALUES ('relaunch', '{}', NULL)")
        shutil.rmtree(self.root / ".cache")
        with closing(_database(self.root)) as db:
            self.assertEqual([("done",), ("pending",)], db.execute("SELECT id FROM requests ORDER BY id").fetchall())
        self.assertEqual([("{}", "{}")], _outcomes(self.root))

    def test_unmerged_commit_prevents_worktree_removal(self):
        value = w.start(self.root, "repair", ref="HEAD")
        tree = Path(value["checkout"])
        w.git(tree, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
              "commit", "--allow-empty", "-qm", "unmerged")
        w.finish(self.root, "repair")
        with self.assertRaises(subprocess.CalledProcessError):
            w.remove_worktree(self.root, "repair", base="HEAD")
        self.assertTrue(tree.exists())

    def test_retired_cache_cannot_fake_recovery_after_durable_store_loss(self):
        from gambit_smp.research_actions import _database
        legacy = self.root / ".cache/research-actions/requests.sqlite"
        legacy.parent.mkdir(parents=True)
        with closing(sqlite3.connect(legacy)) as db:
            db.execute("CREATE TABLE requests (id TEXT PRIMARY KEY, body TEXT, result TEXT)")
            db.execute("INSERT INTO requests VALUES ('old', '{}', NULL)")
            db.commit()
        with closing(_database(self.root)) as db:
            db.execute("INSERT INTO requests VALUES ('new-pending', '{}', NULL)")
            db.commit()
        target = self.root / ".state/research-actions/requests.sqlite"
        target.unlink()
        with self.assertRaisesRegex(ValueError, "not recovery authority"):
            _database(self.root)
        self.assertFalse(target.exists())

    def test_case_variant_process_reference_is_conservatively_retained(self):
        path = self.root / ".cache/SomeTask"
        self.assertTrue(w.referenced(path, [Path(str(path).upper()) / "log"]))
        self.assertFalse(w.referenced(path, [self.root / ".cache/SomeTaskElse/log"]))

    def test_startup_collects_closed_expired_tasks_and_keeps_custody_record(self):
        w.start(self.root, "old", adopt=True)
        w.finish(self.root, "old")
        record, cache, _ = w.paths(self.root, "old")
        value = json.loads(record.read_text())
        value["lastActivity"] = "2000-01-01T00:00:00+08:00"
        w.write(record, value)
        with patch.object(w, "active_paths", return_value=[]):
            w.start(self.root, "new", adopt=True)
        self.assertFalse(cache.exists())
        self.assertTrue(record.exists())

    def test_legacy_cleanup_archives_failed_receipt_without_rewriting_bytes(self):
        path = self.root / ".data/old"
        path.mkdir(parents=True)
        receipt = path / "receipt.json"
        raw = b'{"passed": false, "exit": 137}\n'
        receipt.write_bytes(raw)
        self.old(receipt)
        self.old(path)
        value = retention.plan(self.root, today=date(2026, 10, 20), opened=[])
        manifest = self.root / "plan.json"
        w.write(manifest, value)
        sha = hashlib.sha256(manifest.read_bytes()).hexdigest()
        with patch.object(retention, "active_paths", return_value=[]):
            result = retention.apply(self.root, manifest, sha)
        archived = result["removed"][0]["archivedRecords"][0]
        self.assertFalse(path.exists())
        self.assertEqual(raw, (self.root / archived["archive"]).read_bytes())

    def test_python_generated_artifacts_do_not_become_fallback_source_identity(self):
        from gambit_smp.research_actions import _catalog_fallback_paths, _inputs
        paths = ["models/experiment.py", "models/__pycache__/experiment.pyc",
                 "models/standalone.pyc", "models/.cache/generated.json", "docs/contract.md"]
        for name in paths:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("original")
        selected = list(_catalog_fallback_paths(self.root))
        self.assertEqual({self.root / "models/experiment.py", self.root / "docs/contract.md"}, set(selected))
        before = _inputs(self.root, selected)
        (self.root / "models/__pycache__/experiment.pyc").write_text("regenerated")
        self.assertEqual(before, _inputs(self.root, list(_catalog_fallback_paths(self.root))))
        (self.root / "models/experiment.py").write_text("changed source")
        self.assertNotEqual(before, _inputs(self.root, list(_catalog_fallback_paths(self.root))))

    def test_cleanup_resumes_after_partial_delete_and_handles_readonly_packages(self):
        path = self.root / ".cache/old"
        package = path / "package"
        package.mkdir(parents=True)
        for name in ("a", "b"):
            (package / name).write_text("old")
            self.old(package / name)
        self.old(package)
        self.old(path)
        package.chmod(0o500)
        value = retention.plan(self.root, today=date(2026, 10, 20), opened=[])
        manifest = self.root / "plan.json"
        w.write(manifest, value)
        sha = hashlib.sha256(manifest.read_bytes()).hexdigest()
        def interrupted(target):
            package.chmod(0o700)
            (package / "a").unlink()
            raise PermissionError("interrupted deletion")
        with patch.object(retention, "active_paths", return_value=[]), patch.object(
                retention, "remove_tree", side_effect=interrupted):
            with self.assertRaises(PermissionError):
                retention.apply(self.root, manifest, sha)
        package.chmod(0o500)
        with patch.object(retention, "active_paths", return_value=[]):
            result = retention.apply(self.root, manifest, sha, resume=True)
        self.assertTrue(result["complete"])
        self.assertFalse(path.exists())

    def test_cleanup_reloads_completion_after_acquiring_lease(self):
        path = self.root / ".cache/old"
        path.mkdir(parents=True)
        self.old(path)
        value = retention.plan(self.root, today=date(2026, 10, 20), opened=[])
        manifest = self.root / "plan.json"
        w.write(manifest, value)
        sha = hashlib.sha256(manifest.read_bytes()).hexdigest()
        journal = self.root / ".state/storage/legacy-cleanup-applied.json"
        w.write(journal, dict(schema=1, planSha256=sha, removed=[], complete=False))
        @contextmanager
        def finishes_first(*args):
            path.rmdir()
            w.write(journal, dict(schema=1, planSha256=sha, removed=value["targets"], complete=True))
            yield
        with patch.object(retention, "lease", side_effect=finishes_first), patch.object(
                retention, "active_paths", return_value=[]):
            with self.assertRaisesRegex(ValueError, "receipt exists"):
                retention.apply(self.root, manifest, sha, resume=True)
        self.assertTrue(json.loads(journal.read_text())["complete"])


if __name__ == "__main__":
    unittest.main()
