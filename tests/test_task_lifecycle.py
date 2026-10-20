"""Real child processes and old launch paths exercise shared lifecycle custody."""
import hashlib
import json
import os
from pathlib import Path
import sqlite3
from contextlib import closing
import subprocess
import sys
import unittest
from unittest.mock import patch

from tests import test_workspace as fixtures
from gambit_smp import workspace as w
from gambit_smp import task_dependencies as legacy
from gambit_smp import task_migration as migration
from gambit_smp import storage_retention as retention
from gambit_smp.artifact_storage import runtime_output


class LifecycleTests(unittest.TestCase):
    setUp = fixtures.WorkspaceTests.setUp
    old = fixtures.WorkspaceTests.old
    # Reuse only the Git fixture, not the parent test cases.
    def test_nested_actual_child_reuses_inherited_lock(self):
        w.start(self.root, 'repair', adopt=True)
        code = "from gambit_smp.workspace import execution_scope; from pathlib import Path; import os;\nwith execution_scope(Path(os.environ['GAMBIT_SMP_TASK_ROOT']), 'repair'): print('nested')"
        self.assertEqual(0, w.execute(self.root, 'repair', [sys.executable, '-c', code]))
        self.assertEqual(1, len(list((self.root / '.state/task-runs/repair').glob('*.json'))))

    def test_environment_flag_cannot_forge_lease(self):
        w.start(self.root, 'repair', adopt=True)
        lock = w.paths(self.root, 'repair')[0].with_suffix('.lock')
        fd = os.open(lock, os.O_RDWR)
        try:
            with patch.dict(os.environ, GAMBIT_SMP_TASK_LOCK_FD=str(fd)):
                with self.assertRaisesRegex(ValueError, 'not held'):
                    with w.execution_scope(self.root, 'repair'): pass
        finally:
            os.close(fd)

    def test_old_script_uses_task_output_and_preserves_input_location(self):
        w.start(self.root, 'repair', adopt=True)
        cached = self.root / '.cache/checkpoint'
        cached.mkdir(parents=True)
        (cached / 'header').write_text('actual-header')
        inode = cached.stat().st_ino
        legacy.adopt(self.root, 'repair', ['.cache/checkpoint'], default=True)
        script = self.root / '.cache/old.py'
        script.write_text("from pathlib import Path\nROOT=Path(" + repr(str(self.root)) + ")\np=ROOT/'.cache/new-output';p.mkdir(parents=True);(p/'result').write_text((ROOT/'.cache/checkpoint/header').read_text())\n")
        original = script.read_bytes()
        row = migration.migrate(self.root, 'repair', '.cache/old.py', enabled=True, opened=[])
        self.assertEqual(hashlib.sha256(original).hexdigest(), row['originalSha256'])
        self.assertFalse(script.exists())
        self.assertEqual(0, w.run_script(self.root, 'repair', row['key']))
        self.assertFalse((self.root / '.cache/new-output').exists())
        outputs = list((self.root / '.cache/tasks/repair/runs').glob('*/outputs/new-output/result'))
        self.assertEqual(1, len(outputs))
        self.assertEqual('actual-header', outputs[0].read_text())
        self.assertEqual(inode, cached.stat().st_ino)
        self.assertEqual(self.root / '.cache/tasks/repair/outputs/next', runtime_output(self.root, '.cache/next'))
        # Changed campaign source cannot reuse the original seal.
        Path(row['path']).write_text('raise SystemExit(0)')
        with self.assertRaisesRegex(ValueError,'source changed'):w.run_script(self.root,'repair',row['key'])

    def test_disabled_grok_script_remains_disabled_and_occupied_script_unchanged(self):
        w.start(self.root, 'repair', adopt=True)
        script = self.root / '.cache/old.py'; script.parent.mkdir(exist_ok=True)
        script.write_text('raise RuntimeError("must never execute")')
        raw = script.read_bytes()
        with self.assertRaisesRegex(ValueError, 'occupied'):
            migration.migrate(self.root, 'repair', '.cache/old.py', opened=[script])
        self.assertEqual(raw, script.read_bytes())
        entry=migration.migrate(self.root, 'repair', '.cache/old.py', opened=[])
        self.assertFalse(script.exists())
        with self.assertRaisesRegex(ValueError,'disabled'):w.run_script(self.root,'repair',entry['key'])

    def test_pending_real_sqlite_blocks_finish_and_resume_without_replay(self):
        w.start(self.root, 'repair', adopt=True)
        db = self.root / '.state/research-actions/requests.sqlite'; db.parent.mkdir()
        with closing(sqlite3.connect(db)) as con:
            con.execute('CREATE TABLE requests(id TEXT, result TEXT)')
            con.execute("INSERT INTO requests VALUES('unresolved', NULL)")
            con.commit()
        with patch.object(w, 'active_paths', return_value=[]):
            for operation in (w.finish, w.resume):
                with self.assertRaisesRegex(ValueError, 'pending requests'):
                    operation(self.root, 'repair')
        with closing(sqlite3.connect(db)) as con:
            self.assertEqual([('unresolved', None)], con.execute('SELECT * FROM requests').fetchall())
        self.assertEqual('open', json.loads(w.paths(self.root, 'repair')[0].read_text())['state'])

    def test_uncertain_attempt_requires_reconciliation_not_automatic_retry(self):
        w.start(self.root, 'repair', adopt=True)
        with self.assertRaises(FileNotFoundError):
            w.execute(self.root, 'repair', ['/nonexistent-task-executable'])
        with self.assertRaisesRegex(ValueError, 'explicit workspace resume'):
            w.execute(self.root, 'repair', [sys.executable, '-c', 'pass'])
        with patch.object(w, 'active_paths', return_value=[]): w.resume(self.root, 'repair')
        self.assertEqual(0, w.execute(self.root, 'repair', [sys.executable, '-c', 'pass']))
        runs = [json.loads(p.read_text()) for p in (self.root / '.state/task-runs/repair').glob('*.json')]
        self.assertEqual({'interrupted', 'returned'}, {row['state'] for row in runs})

    def test_cleanup_manifest_cannot_delete_subsequently_adopted_dependency(self):
        w.start(self.root, 'repair', adopt=True)
        cache = self.root / '.cache/old';cache.mkdir();self.old(cache)
        plan = retention.plan(self.root, opened=[])
        manifest = self.root / 'plan.json';w.write(manifest, plan)
        legacy.adopt(self.root, 'repair', ['.cache/old'])
        with patch.object(retention, 'active_paths', return_value=[]):
            with self.assertRaisesRegex(ValueError, 'protected'):
                retention.apply(self.root, manifest, hashlib.sha256(manifest.read_bytes()).hexdigest())
        self.assertTrue(cache.exists())
        self.assertEqual([], retention.plan(self.root, opened=[])['targets'])

    def test_dependency_replacement_is_not_real_recovery(self):
        w.start(self.root, 'repair', adopt=True)
        cache=self.root/'.cache/checkpoint';cache.mkdir()
        legacy.adopt(self.root, 'repair', ['.cache/checkpoint'])
        cache.rename(cache.with_name('original'));cache.mkdir()
        with self.assertRaisesRegex(ValueError, 'identity changed'):
            with patch.object(w, 'active_paths', return_value=[]): w.resume(self.root, 'repair')

    def test_open_campaign_expires_only_old_unpinned_completed_runs(self):
        w.start(self.root, 'repair', adopt=True)
        with w.execution_scope(self.root, 'repair') as (_, _, record):
            path = runtime_output(self.root, '.cache/result')
            path.mkdir(parents=True)
            (path / 'receipt.json').write_text('{"outcome":"DENY"}')
        row=json.loads(record.read_text()); row['endedAt']='2000-01-01T00:00:00+08:00';w.write(record,row)
        for item in [*Path(row['output']).rglob('*'), Path(row['output'])]:self.old(item)
        legacy.adopt(self.root,'repair',[str(path.relative_to(self.root))])
        self.assertEqual([], w.collect_runs(self.root,'repair',opened=[]))
        legacy.registry(self.root,'repair').unlink()  # Test-only explicit pin release.
        self.assertEqual([row['run']], w.collect_runs(self.root,'repair',opened=[]))
        self.assertFalse(path.exists())
        self.assertEqual('open',json.loads(w.paths(self.root,'repair')[0].read_text())['state'])
        self.assertEqual('returned',json.loads(record.read_text())['state'])
        self.assertTrue(json.loads(record.read_text())['cleanup']['archivedRecords'])

    def test_real_live_group_prevents_completion_even_without_open_files(self):
        w.start(self.root,'repair',adopt=True)
        child=subprocess.Popen([sys.executable,'-c','import time;time.sleep(30)'],start_new_session=True)
        try:
            run=self.root/'.state/task-runs/repair/observed.json'
            w.write(run,dict(state='interrupted',pgid=child.pid))
            with patch.object(w,'active_paths',return_value=[]):
                with self.assertRaisesRegex(ValueError,'process group still present'):w.finish(self.root,'repair')
        finally:
            child.terminate();child.wait()
        with patch.object(w,'active_paths',return_value=[]):w.resume(self.root,'repair')
        self.assertEqual('interrupted',json.loads(run.read_text())['state'])

    def test_dynamic_legacy_write_fails_closed_and_pin_release_preserves_history(self):
        w.start(self.root,'repair',adopt=True)
        cache=self.root/'.cache/input';cache.mkdir()
        legacy.adopt(self.root,'repair',['.cache/input'])
        script=self.root/'.cache/dynamic.py'
        script.write_text("from pathlib import Path\nROOT=Path("+repr(str(self.root))+")\n(ROOT / '.cache' / 'rogue').mkdir()\n")
        entry=migration.migrate(self.root,'repair','.cache/dynamic.py',enabled=True,opened=[])
        direct=subprocess.run([sys.executable,entry['path']],capture_output=True,text=True)
        self.assertNotEqual(0,direct.returncode)
        self.assertIn('real task execution custody',direct.stderr)
        self.assertNotEqual(0,w.run_script(self.root,'repair',entry['key']))
        self.assertFalse((self.root/'.cache/rogue').exists())
        with patch.object(w,'active_paths',return_value=[cache]):
            with self.assertRaisesRegex(ValueError,'occupied'):legacy.release(self.root,'repair',['.cache/input'])
        with patch.object(w,'active_paths',return_value=[]):
            value=legacy.release(self.root,'repair',['.cache/input'])
        self.assertEqual([],value['paths']);self.assertEqual('.cache/input',value['released'][0]['path'])
        self.assertTrue(cache.exists())

    def test_quarantine_and_timeout_are_not_completion(self):
        w.start(self.root,'repair',adopt=True)
        with self.assertRaises(subprocess.TimeoutExpired):
            w.execute(self.root,'repair',[sys.executable,'-c','import time;time.sleep(20)'],wall_seconds=.1)
        rows=[json.loads(p.read_text()) for p in (self.root/'.state/task-runs/repair').glob('*.json')]
        self.assertTrue(rows[0]['parentReaped']);self.assertTrue(rows[0]['timedOut'])
        self.assertEqual('interrupted',rows[0]['state'])
        quarantine=self.root/'.cache/workspace-leases/source.quarantine.json';quarantine.parent.mkdir()
        quarantine.write_text('{"processGroupQuiescent":false}')
        with patch.object(w,'active_paths',return_value=[]):
            with self.assertRaisesRegex(ValueError,'quarantine'):w.resume(self.root,'repair')
        self.assertTrue(quarantine.exists())

    def test_default_cli_and_nested_explicit_task_use_one_attempt(self):
        from gambit_smp import cli
        from types import SimpleNamespace
        w.start(self.root,'repair',adopt=True)
        legacy.adopt(self.root,'repair',[],default=True)
        calls=[]
        def adapter():
            calls.append(os.environ['GAMBIT_SMP_TASK_RUN'])
            if len(calls)==1:
                return cli.main(['--task','repair','verify'])
            self.assertIsNotNone(w.inherited_lease(self.root,'repair'))
            return 7
        with patch('gambit_smp.framework.project_root',return_value=self.root), patch.object(cli,'import_module',return_value=SimpleNamespace(main=adapter)):
            self.assertEqual(7,cli.main(['verify']))
        self.assertEqual(calls[0],calls[1])
        self.assertEqual(1,len(list((self.root/'.state/task-runs/repair').glob('*.json'))))

    def test_wrong_framework_checkout_is_not_a_configured_worktree(self):
        w.start(self.root,'repair',adopt=True)
        module=self.root/'src/gambit_smp/workspace.py';module.parent.mkdir(parents=True)
        module.write_text('# another checkout')
        with self.assertRaisesRegex(ValueError,'another checkout'):
            with w.execution_scope(self.root,'repair'):pass

    def test_interrupted_source_migration_resumes_from_exact_bytes(self):
        w.start(self.root,'repair',adopt=True)
        script=self.root/'.cache/old.py';script.parent.mkdir(exist_ok=True)
        script.write_text('print("migrated")')
        original_unlink=Path.unlink
        def interrupted(path,*args,**kwargs):
            if path==script:raise OSError('simulated interruption before old-entry removal')
            return original_unlink(path,*args,**kwargs)
        with patch.object(Path,'unlink',interrupted):
            with self.assertRaisesRegex(OSError,'simulated interruption'):
                migration.migrate(self.root,'repair','.cache/old.py',enabled=True,opened=[])
        key=hashlib.sha256(b'.cache/old.py').hexdigest()
        entry=json.loads(migration.script_record(self.root,'repair',key).read_text())
        self.assertEqual('prepared',entry['state']);self.assertTrue(script.exists())
        with self.assertRaisesRegex(ValueError,'incomplete'):w.run_script(self.root,'repair',key)
        completed=migration.migrate(self.root,'repair','.cache/old.py',opened=[],resume=True)
        self.assertEqual(entry['sha256'],completed['sha256']);self.assertFalse(script.exists())
        self.assertEqual(0,w.run_script(self.root,'repair',key))

    def test_batch_source_retirement_uses_one_real_task_boundary(self):
        w.start(self.root,'repair',adopt=True)
        names=['.cache/one.py','.cache/two.py']
        for name in names:
            path=self.root/name;path.parent.mkdir(exist_ok=True);path.write_text('print("source")')
        items=[dict(original=name,enabled=False) for name in names]
        with w.lease(self.root,'repair'):
            with self.assertRaises(BlockingIOError):migration.migrate_many(self.root,'repair',items)
        self.assertTrue(all((self.root/name).exists() for name in names))
        rows=migration.migrate_many(self.root,'repair',items)
        self.assertEqual(2,len(rows));self.assertFalse(any((self.root/name).exists() for name in names))
        for row in rows:
            code=Path(row['path']).read_text()
            self.assertIn('_task_require_execution(',code)
            self.assertNotIn('legacy_tasks',code)
        self.assertEqual(rows,migration.migrate_many(self.root,'repair',items))
