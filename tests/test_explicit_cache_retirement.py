import json
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.storage_retention import retire


class ExplicitCacheRetirementTests(unittest.TestCase):
    def setUp(self):
        self.temporary=tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root=Path(self.temporary.name).resolve()
        self.keep=self.root/'.cache/tasks/darwin/baseline'
        self.keep.mkdir(parents=True)
        self.old=self.root/'.cache/obsolete';self.old.mkdir()

    def git(self,path,*args):
        return subprocess.run(['git','-C',str(path),*args],check=True,capture_output=True).stdout

    def test_retains_current_work_and_rejects_overlapping_or_source_targets(self):
        for target in ['.cache/tasks/darwin','.cache/tasks/darwin/baseline','.cache/tasks/DARWIN/BASELINE','src','.cache/tasks']:
            with self.assertRaises(ValueError):retire(self.root,[target],keep=[self.keep.relative_to(self.root)],opened=[])
        with self.assertRaises(ValueError):retire(self.root,[self.old.relative_to(self.root)],keep=[],opened=[])

    def test_live_and_registered_sources_are_not_disposed(self):
        result=retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[self.old/'writer'])
        self.assertFalse(result['removed']);self.assertTrue(self.old.exists())
        with patch('gambit_smp.task_dependencies.protected',return_value=True):
            result=retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        self.assertFalse(result['removed']);self.assertTrue(self.old.exists())

    def test_preserves_git_history_patches_and_untracked_source_before_removal(self):
        self.git(self.old,'init','-q')
        (self.old/'source.ss').write_text('original\n')
        self.git(self.old,'add','source.ss')
        self.git(self.old,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source')
        head=self.git(self.old,'rev-parse','HEAD').strip()
        (self.old/'source.ss').write_text('changed\n')
        (self.old/'new.ss').write_text('new source\n')
        result=retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        self.assertEqual(['.cache/obsolete'],result['removed']);self.assertFalse(self.old.exists())
        receipt=next((self.root/'.state/storage/explicit-retirement').glob('*.json'))
        recovery=json.loads(receipt.read_text())['recovery'][0]
        restored=self.root/'restored';restored.mkdir()
        with tarfile.open(self.root/recovery['sourceSnapshot']['path']) as archive:
            archive.extractall(restored,filter='data')
        clone=restored/'source'
        self.assertEqual(head,self.git(clone,'rev-parse','HEAD').strip())
        self.assertEqual('changed\n',(clone/'source.ss').read_text())
        with tarfile.open(self.root/recovery['untracked']['path']) as archive:
            self.assertEqual(b'new source\n',archive.extractfile('new.ss').read())

    def test_offline_state_is_preserved_without_completing_requests(self):
        (self.old/'queue.sqlite').write_bytes(b'unknown offline queue bytes')
        retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        receipt=next((self.root/'.state/storage/explicit-retirement').glob('*.json'))
        row=json.loads(receipt.read_text())['recovery'][0]
        self.assertFalse(row['requestsCompleted'])
        with tarfile.open(self.root/row['offlineState']['path']) as archive:
            self.assertEqual(b'unknown offline queue bytes',archive.extractfile('queue.sqlite').read())

    def test_linked_worktree_is_archived_and_unregistered_without_deleting_common_repository(self):
        self.git(self.keep,'init','-q')
        (self.keep/'source').write_text('source')
        self.git(self.keep,'add','source')
        self.git(self.keep,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source')
        self.old.rmdir()
        self.git(self.keep,'worktree','add','--detach',str(self.old),'HEAD')
        retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        self.assertFalse(self.old.exists())
        self.assertTrue((self.keep/'.git').exists())
        self.assertNotIn(str(self.old).encode(),self.git(self.keep,'worktree','list','--porcelain'))

    def test_source_change_during_preservation_refuses_removal(self):
        def changed(root,path,**kwargs):
            (path/'late').write_text('late source');return []
        with patch('gambit_smp.git_custody.preserve',side_effect=changed):
            result=retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        self.assertEqual([],result['removed'])
        self.assertEqual('metadata changed during preservation',result['deferred'][0]['reason'])
        record=next((self.root/'.state/storage/retirement-drift').glob('*.json'))
        self.assertIn('late',[r['path'] for r in json.loads(record.read_text())['changes']])
        self.assertTrue(self.old.exists())

    def test_moved_old_copy_does_not_unregister_another_git_path(self):
        self.git(self.keep,'init','-q')
        (self.keep/'source').write_text('source')
        self.git(self.keep,'add','source')
        self.git(self.keep,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source')
        self.old.rmdir();self.git(self.keep,'worktree','add','--detach',str(self.old),'HEAD')
        moved=self.old.with_name('moved');self.old.rename(moved)
        before=self.git(self.keep,'worktree','list','--porcelain')
        retire(self.root,[moved.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        self.assertFalse(moved.exists())
        self.assertEqual(before,self.git(self.keep,'worktree','list','--porcelain'))

    def test_source_disposal_preserves_device_drift_without_admitting_reuse(self):
        from gambit_smp.task_dependencies import release
        from gambit_smp.git_custody import preserve
        from gambit_smp.workspace import write
        self.git(self.old,'init','-q');(self.old/'source.ss').write_text('source')
        self.git(self.old,'add','source.ss')
        self.git(self.old,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source')
        st=self.old.stat();identity=[st.st_dev-1,st.st_ino]
        row=dict(path='.cache/obsolete',identity=identity,custody='in-place-pin')
        other=dict(path='.cache/unreviewed',identity=[0,0],custody='in-place-pin')
        file=self.root/'.state/task-dependencies/old.json';write(file,dict(paths=[row,other]))
        proof=dict(path=row['path'],registeredIdentity=identity,observedIdentity=[st.st_dev,st.st_ino],metadataStable=True,
                   recovery=preserve(self.root,self.old,pack_history=False))
        with patch('gambit_smp.workspace.active_paths',return_value=[]):
            with self.assertRaises(ValueError):release(self.root,'old',[row['path']])
            with self.assertRaises(ValueError):release(self.root,'old',[row['path'],other['path']],source_disposal=[proof])
            archive=proof['recovery'][0]['sourceSnapshot'];original=archive['sha256'];archive['sha256']='0'*64
            with self.assertRaisesRegex(ValueError,'archive changed'):release(self.root,'old',[row['path']],source_disposal=[proof])
            archive['sha256']=original
            value=release(self.root,'old',[row['path']],source_disposal=[proof])
        self.assertEqual([other],value['paths'])
        self.assertEqual(identity,value['released'][0]['identity'])
        self.assertFalse(value['released'][0]['reuseAdmitted'])

    def test_source_disposal_refuses_unstable_or_changed_inode(self):
        from gambit_smp.task_dependencies import release
        from gambit_smp.workspace import write
        st=self.old.stat();row=dict(path='.cache/obsolete',identity=[st.st_dev-1,st.st_ino])
        write(self.root/'.state/task-dependencies/old.json',dict(paths=[row]))
        proof=dict(path=row['path'],registeredIdentity=row['identity'],observedIdentity=[st.st_dev,st.st_ino],metadataStable=False,recovery=[])
        with patch('gambit_smp.workspace.active_paths',return_value=[]):
            with self.assertRaises(ValueError):release(self.root,'old',[row['path']],source_disposal=[proof])
        self.assertEqual([row],json.loads((self.root/'.state/task-dependencies/old.json').read_text())['paths'])

    def test_interrupted_deletion_resumes_only_the_unchanged_remainder(self):
        from gambit_smp.storage_retention import remove_tree
        (self.old/'a').write_text('a');(self.old/'b').write_text('b')
        def interrupted(path):
            (path/'a').unlink();raise InterruptedError('stop after first unlink')
        with patch('gambit_smp.storage_retention.remove_tree',side_effect=interrupted):
            with self.assertRaises(InterruptedError):retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        result=retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        self.assertEqual(['.cache/obsolete'],result['removed']);self.assertFalse(self.old.exists())

    def test_new_entries_after_interruption_refuse_resume(self):
        (self.old/'a').write_text('a')
        with patch('gambit_smp.storage_retention.remove_tree',side_effect=InterruptedError('stop')):
            with self.assertRaises(InterruptedError):retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        (self.old/'new').write_text('new owner source')
        with self.assertRaisesRegex(ValueError,'new entry'):
            retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        self.assertTrue(self.old.exists())

    def test_expired_output_device_observation_is_not_native_requalification(self):
        from datetime import date
        import os
        from gambit_smp.task_retention import collect
        from gambit_smp.workspace import write
        file=self.old/'run.json';file.write_text('{"outcome":"historical failure"}')
        os.utime(file,(1,1));os.utime(self.old,(1,1))
        st=self.old.stat();identity=[st.st_dev-1,st.st_ino]
        row=dict(path='.cache/obsolete',identity=identity,custody='retained-output')
        registry=self.root/'.state/task-dependencies/old.json';write(registry,dict(paths=[row]))
        result=collect(self.root,'old',today=date(2026,11,2),opened=[])
        self.assertEqual(['.cache/obsolete'],result)
        saved=json.loads(registry.read_text())['expired'][0]
        self.assertEqual(identity,saved['identity'])
        self.assertFalse(saved['cleanup']['identityObservation']['reuseAdmitted'])

    def test_expired_output_replaced_inode_remains_blocked(self):
        from datetime import date
        from gambit_smp.task_retention import collect
        from gambit_smp.workspace import write
        row=dict(path='.cache/obsolete',identity=[self.old.stat().st_dev,0],custody='retained-output')
        write(self.root/'.state/task-dependencies/old.json',dict(paths=[row]))
        with self.assertRaisesRegex(ValueError,'identity changed'):
            collect(self.root,'old',today=date(2026,11,2),opened=[])
        self.assertTrue(self.old.exists())

    def test_late_reader_prevents_disposal_after_source_preservation(self):
        with patch('gambit_smp.storage_retention.active_paths',side_effect=[[],[self.old/'reader']]):
            result=retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)])
        self.assertEqual([],result['removed'])
        self.assertEqual('late live reference',result['deferred'][0]['reason'])
        self.assertTrue(self.old.exists())

    def test_broken_historical_graph_is_snapshot_not_a_complete_history_claim(self):
        self.git(self.old,'init','-q')
        (self.old/'source.ss').write_text('source retained\n')
        self.git(self.old,'add','source.ss')
        self.git(self.old,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source')
        from gambit_smp.task_processes import run
        def broken(argv,**kwargs):
            if 'bundle' in argv and 'create' in argv:
                return subprocess.CompletedProcess(argv,128,b'',b'missing historical parent')
            return run(argv,**kwargs)
        with patch('gambit_smp.git_custody.run',side_effect=broken):
            from gambit_smp.git_custody import preserve
            first=preserve(self.root,self.old)[0]
            self.assertIn('missing historical parent',first['historyFailure'])
            retire(self.root,[self.old.relative_to(self.root)],keep=[self.keep.relative_to(self.root)],opened=[])
        receipt=next((self.root/'.state/storage/explicit-retirement').glob('*.json'))
        row=json.loads(receipt.read_text())['recovery'][0]
        self.assertFalse(row['historyComplete'])
        self.assertNotIn('bundle',row)
        with tarfile.open(self.root/row['sourceSnapshot']['path']) as archive:
            self.assertEqual(b'source retained\n',archive.extractfile('source/source.ss').read())

