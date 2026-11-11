"""Source snapshot publication is separate from native qualification."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.revision_submission import commit_source_checkpoint, RevisionSubmission
from gambit_smp.task_processes import run as task_run


class SourceCheckpointTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Transport test')
        self.git('config', 'user.email', 'test@example.invalid')
        (self.repo/'a.c').write_text('base a\n')
        (self.repo/'b.c').write_text('base b\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'base')
        self.base = self.git('rev-parse', 'HEAD').strip()
        self.storage = self.root/'.cache/tasks/test/checkpoints'
        self.storage.mkdir(parents=True)
        source = self.storage/'source.c'
        source.write_text('retained tested source\n')
        observation = self.root/'observation.json'
        observation.write_text('{"scope":"historical control","runtimeAdmitted":false}')
        self.spec = dict(schema='revision-source-checkpoint-request.v1',task='test',repository='repo',
            baseRevision=self.base,scope='Retain a source control observation; no new native result',
            ledger='5/12',files=[dict(path='a.c',mode='100644',
                source=str(source.relative_to(self.root)),sha256=self.sha(source))],
            observations=[dict(path='observation.json',sha256=self.sha(observation))],
            audit={k:'Transport fixture only; no runtime claim' for k in
                ['responsibility','retired','validation','benefits','costs','process','checklist','models','open']},
            message='Checkpoint retained source')
        self.request = self.storage/'request.json'

    def git(self, *args):
        result = task_run(['git','-C',str(self.repo),*args],capture_output=True,text=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr)
        return result.stdout

    @staticmethod
    def sha(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def publish(self):
        self.request.write_text(json.dumps(self.spec))
        registration=self.root/'docs/work-items.json'
        registration.parent.mkdir(exist_ok=True)
        registration.write_text(json.dumps(dict(schema='gambit-work-items.v1',items={
            'test':dict(sourceCheckpointRequests=[dict(path=str(self.request.relative_to(self.root)),
                sha256=self.sha(self.request))])})))
        return commit_source_checkpoint(self.root,self.request,self.storage)

    def test_unregistered_checkpoint_cannot_bypass_native_admission(self):
        self.request.write_text(json.dumps(self.spec))
        with self.assertRaisesRegex(ValueError,'exact registered'):
            commit_source_checkpoint(self.root,self.request,self.storage)
        self.assertEqual(self.git('rev-parse','HEAD').strip(),self.base)

    def test_snapshot_excludes_unrelated_staging_and_preserves_new_work(self):
        (self.repo/'a.c').write_text('newer Grok work\n')
        (self.repo/'b.c').write_text('unrelated staged improvement\n')
        self.git('add','a.c','b.c')
        before = self.sha(self.repo/'.git/index')
        result = self.publish()
        self.assertEqual(self.git('show','HEAD:a.c'),'retained tested source\n')
        self.assertEqual(self.git('show','HEAD:b.c'),'base b\n')
        self.assertEqual(self.sha(self.repo/'.git/index'),before)
        self.assertEqual((self.repo/'a.c').read_text(),'newer Grok work\n')
        self.assertEqual(self.git('show',':b.c'),'unrelated staged improvement\n')
        self.assertFalse(result['complete'])
        self.assertFalse(result['runtimeAdmitted'])
        self.assertEqual(result['progressDelta'],0)
        self.assertIn('not native or integration acceptance',self.git('log','-1','--format=%B'))

    def test_changed_snapshot_refuses_before_ref_update(self):
        self.spec['files'][0]['sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'source changed'):self.publish()
        self.assertEqual(self.git('rev-parse','HEAD').strip(),self.base)

    def test_changed_observation_refuses_before_ref_update(self):
        self.spec['observations'][0]['sha256']='0'*64
        with self.assertRaisesRegex(ValueError,'observation changed'):self.publish()
        self.assertEqual(self.git('rev-parse','HEAD').strip(),self.base)

    def test_stale_predecessor_refuses(self):
        self.spec['baseRevision']='0'*40
        with self.assertRaisesRegex(ValueError,'predecessor changed'):self.publish()

    def test_checkpoint_cannot_be_promoted_by_flipping_complete(self):
        result = self.publish()
        result['complete']=True
        with self.assertRaisesRegex(ValueError,'cannot supply native qualification'):
            RevisionSubmission(self.root,self.repo,self.storage,self.storage/'native',
                               self.root/'evidence',result)

    def test_target_path_escape_refuses(self):
        self.spec['files'][0]['path']='../outside.c'
        with self.assertRaisesRegex(ValueError,'canonical checkpoint target'):self.publish()

    def test_gitlink_selects_child_revision_without_staging_child_work(self):
        child=self.repo/'vendor/child'
        child.mkdir(parents=True)
        def git(*args):
            p=task_run(['git','-C',str(child),*args],capture_output=True,text=True,timeout=30)
            self.assertEqual(p.returncode,0,p.stderr)
            return p.stdout.strip()
        git('init','-q');git('config','user.name','Child');git('config','user.email','child@example.invalid')
        (child/'source.c').write_text('child committed\n');git('add','.');git('commit','-qm','child')
        revision=git('rev-parse','HEAD')
        (child/'source.c').write_text('child pending\n')
        self.spec['files']=[dict(path='vendor/child',mode='160000',revision=revision)]
        self.publish()
        self.assertIn('160000 commit '+revision,self.git('ls-tree','HEAD','vendor/child'))
        self.assertEqual((child/'source.c').read_text(),'child pending\n')

    def test_concurrent_head_is_not_overwritten(self):
        from gambit_smp import revision_submission as module
        original=module.run
        competing=[]
        def run(argv,**kwargs):
            result=original(argv,**kwargs)
            if 'commit-tree' in argv and not competing:
                revision=self.git('commit-tree',self.base+'^{tree}','-p',self.base,'-m','concurrent').strip()
                self.git('update-ref','HEAD',revision,self.base)
                competing.append(revision)
            return result
        with patch.object(module,'run',side_effect=run):
            with self.assertRaises(ValueError):self.publish()
        self.assertEqual(self.git('rev-parse','HEAD').strip(),competing[0])

    def test_concurrent_unrelated_staging_does_not_block_or_enter_checkpoint(self):
        from gambit_smp import revision_submission as module
        original=module.run
        staged=[]
        def run(argv,**kwargs):
            result=original(argv,**kwargs)
            if 'commit-tree' in argv and not staged:
                (self.repo/'b.c').write_text('concurrently staged\n')
                self.git('add','b.c');staged.append(True)
            return result
        with patch.object(module,'run',side_effect=run):result=self.publish()
        self.assertEqual(self.git('show','HEAD:b.c'),'base b\n')
        self.assertEqual(self.git('show',':b.c'),'concurrently staged\n')
        self.assertFalse(result['realIndexTouched'])
        self.assertFalse(result['realIndexBytesUnchanged'])
