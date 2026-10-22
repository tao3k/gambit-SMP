"""Git/checkpoint custody, migration recovery, and stale-reference rejection."""
import json
import unittest
from pathlib import Path
from unittest.mock import patch

from tests import test_workspace as fixtures
from gambit_smp import workspace as w
from gambit_smp.source_identity import git_source, read_source, retain_sources, migrate_source_storage, sha
from gambit_smp.view_materialize import review_sources


class SourceIdentityTests(unittest.TestCase):
    # Reuse fixture setup, not the workspace test cases.
    def setUp(self):
        fixtures.WorkspaceTests.setUp(self)
        w.start(self.root,'repair',adopt=True)
        w.write(self.root/'.state/task-policy.json',{'defaultTask':'repair'})

    def test_git_identity_survives_worktree_edits_and_rejects_wrong_blob(self):
        p=self.root/'source.ss';p.write_bytes(b'committed\n')
        w.git(self.root,'add','source.ss')
        w.git(self.root,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source')
        identity=git_source(self.root,'.',w.git(self.root,'rev-parse','HEAD'),'source.ss')
        p.write_bytes(b'dirty\n')
        self.assertEqual(b'committed\n',read_source(self.root,identity))
        with self.assertRaisesRegex(ValueError,'identity mismatch'):
            read_source(self.root,dict(identity,blob='0'*40))
        with self.assertRaisesRegex(ValueError,'immutable Git commit'):
            git_source(self.root,'.','HEAD','source.ss')

    def test_checkpoint_survives_transport_expiry_but_rejects_forged_prefix(self):
        refs=retain_sources(self.root,{'first':b'dirty bytes','second':b'dirty bytes'})
        self.assertEqual(refs['first'],refs['second'])
        (self.root/refs['first']['run']/'record.json').unlink()
        self.assertEqual(b'dirty bytes',read_source(self.root,refs['first']))
        with self.assertRaisesRegex(ValueError,'prefix mismatch'):
            read_source(self.root,dict(refs['first'],identity='0'*64))

    def legacy_review(self):
        folder=self.root/'evidence/review/repair-trajectory-closure';folder.mkdir(parents=True)
        old=folder/'source.py';old.write_bytes(b'old\n')
        delta=folder/'source.patch';delta.write_text('--- a/source.py\n+++ b/source.py\n@@ -1 +1 @@\n-old\n+new\n')
        review=dict(schema='ascent.source-binding-review.v1',declaration='evidence/old.json',declarationSha256='0'*64,
                    changes=[dict(reference='source',baseline=str(old.relative_to(self.root)),patch=str(delta.relative_to(self.root)),
                                  citationIds=[],reason='historical',retainedScope='static only')])
        w.write(folder/'review.json',review)
        return folder,review

    def test_migrate_all_review_copies_preserves_exact_history_and_rejects_legacy_api(self):
        folder,old=self.legacy_review()
        with self.assertRaisesRegex(ValueError,'source binding review required'):
            review_sources(self.root,str((folder/'review.json').relative_to(self.root)))
        result=migrate_source_storage(self.root)
        self.assertEqual(1,result['reviews']);self.assertEqual(2,result['removed'])
        current=json.loads((folder/'review.json').read_text())
        self.assertEqual(old,json.loads(read_source(self.root,current['previousReview'])))
        self.assertEqual(b'old\n',read_source(self.root,current['changes'][0]['before']))
        self.assertEqual(b'new\n',read_source(self.root,current['changes'][0]['after']))
        self.assertFalse((folder/'source.py').exists());self.assertFalse((folder/'source.patch').exists())

    def test_failed_reproduction_does_not_remove_or_rewrite_inputs(self):
        folder,old=self.legacy_review();(folder/'source.patch').write_text('invalid patch')
        with self.assertRaises(ValueError):migrate_source_storage(self.root)
        self.assertEqual(old,json.loads((folder/'review.json').read_text()))
        self.assertTrue((folder/'source.py').exists())


    def test_interrupted_migration_resumes_same_plan_without_losing_history(self):
        folder,old=self.legacy_review()
        original_write=w.write
        def interrupted(path,value):
            if path==folder/'review.json':raise InterruptedError('real publication boundary')
            return original_write(path,value)
        with patch.object(w,'write',side_effect=interrupted):
            with self.assertRaises(InterruptedError):migrate_source_storage(self.root)
        manifest=self.root/'evidence/review/source-storage-migration.json'
        before=json.loads(manifest.read_text())
        self.assertEqual('pending',before['state'])
        self.assertTrue((folder/'source.py').exists())
        result=migrate_source_storage(self.root)
        after=json.loads(manifest.read_text())
        self.assertEqual('completed',after['state'])
        self.assertEqual(before['documents'],after['documents'])
        self.assertEqual(2,result['removed'])
        self.assertEqual(old,json.loads(read_source(self.root,after['previousDocuments'][str((folder/'review.json').relative_to(self.root))])))

    def test_concurrent_author_edit_blocks_pending_migration_and_cleanup(self):
        folder,old=self.legacy_review()
        original_write=w.write
        def interrupted(path,value):
            if path==folder/'review.json':raise InterruptedError()
            return original_write(path,value)
        with patch.object(w,'write',side_effect=interrupted):
            with self.assertRaises(InterruptedError):migrate_source_storage(self.root)
        edited=dict(old,reason='concurrent owner edit');w.write(folder/'review.json',edited)
        with self.assertRaisesRegex(ValueError,'raced with author'):migrate_source_storage(self.root)
        self.assertEqual(edited,json.loads((folder/'review.json').read_text()))
        self.assertTrue((folder/'source.py').exists());self.assertTrue((folder/'source.patch').exists())

    def test_actual_child_exit_after_plan_commit_resumes_authenticated_migration(self):
        import subprocess
        import sys
        import os
        folder,old=self.legacy_review()
        script='''import os,sys
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.source_identity import migrate_source_storage
root=Path(sys.argv[1]);original=w.write
def die_at_publication(path,value):
    if path==root/'evidence/review/repair-trajectory-closure/review.json':os._exit(17)
    return original(path,value)
w.write=die_at_publication
migrate_source_storage(root)
'''
        child=subprocess.run([sys.executable,'-c',script,str(self.root)],capture_output=True,text=True,timeout=20)
        self.assertEqual(17,child.returncode,child.stderr)
        manifest=self.root/'evidence/review/source-storage-migration.json'
        plan=json.loads(manifest.read_text())
        self.assertEqual('pending',plan['state'])
        self.assertEqual(old,json.loads((folder/'review.json').read_text()))
        self.assertTrue((folder/'source.py').exists())
        migrate_source_storage(self.root)
        completed=json.loads(manifest.read_text())
        self.assertEqual('completed',completed['state'])
        self.assertEqual(plan['documents'],completed['documents'])
        self.assertFalse((folder/'source.py').exists())
        self.assertEqual(old,json.loads(read_source(self.root,completed['previousDocuments'][str((folder/'review.json').relative_to(self.root))])))

    def test_distinct_sources_have_independent_small_checkpoint_records(self):
        from gambit_smp.reasoning_history import read_execution_checkpoint
        refs=retain_sources(self.root,{'small':b'small source','large':b'x'*1000000,'same':b'small source'})
        self.assertEqual(refs['small'],refs['same'])
        self.assertNotEqual(refs['small']['run'],refs['large']['run'])
        for name in ('small','large'):
            prefix=read_execution_checkpoint(self.root,self.root/refs[name]['run'])
            self.assertEqual([refs[name]['sha256']],list(prefix['records'][0]['payload']['entries']))
            self.assertIn('.cache/tasks/repair/',refs[name]['run'])
