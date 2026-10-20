"""Real generation and historical queue custody; no native repair admission."""
from contextlib import closing
from datetime import date
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import unittest
from unittest.mock import patch

from tests import test_workspace as fixtures
from gambit_smp import workspace as w, task_dependencies as deps, task_retention
from gambit_smp import view_materialize as views, validation_retention as queues, git_custody


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


class BindingClosureTests(unittest.TestCase):
    setUp=fixtures.WorkspaceTests.setUp
    old=fixtures.WorkspaceTests.old

    def declaration(self,external=False):
        folder=self.root/'evidence';folder.mkdir()
        (folder/'rules.ss').write_text('(define-evidence (make) (sources input) (outputs input) (relation input (value)))')
        (folder/'components.json').write_text(json.dumps(dict(schema='ascent.evidence-components.v1',components=[dict(id='entry',source='rules.ss',exports=['make'],dependencies=[])])))
        target=folder/'sample.view.json';target.write_text('{"historical":"exact original bytes"}\n')
        original=target.read_bytes()
        source=folder/'observed.ss';source.write_text('base source\n')
        locator=dict(path='evidence/observed.ss',sha256=sha(source))
        if external:
            repo=self.root/'external';repo.mkdir();w.git(repo,'init','-q')
            source=repo/'file.ss';source.write_text('base source\n')
            w.git(repo,'add','file.ss');w.git(repo,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source')
            revision=w.git(repo,'rev-parse','HEAD');source.write_text('actual dirty source\n')
            delta=views.git(repo,'diff','--binary','--no-ext-diff','--no-renames',revision,'--','file.ss')
            locator=dict(repository='external',revision=revision,path='file.ss',sha256=sha(source),patchSha256=hashlib.sha256(delta).hexdigest())
        spec=dict(schema='ascent.evidence-view-source.v1',output='evidence/sample.view.json',view=dict(schema='ascent.evidence-view.v1',id='generated',manifest='evidence/components.json',entry='entry',constructor='make',facts={'input':[[7]]},queries={'checked':'input'}),references=[dict(id='source',source=locator,pointer=None)])
        declaration=folder/'sample.view.source.json';w.write(declaration,spec)
        return target,source,original

    def test_real_dirty_git_import_reproduces_source_and_runs_queries(self):
        target,source,original=self.declaration(external=True)
        result=views.materialize(self.root,'evidence/sample.view.source.json',expected_view_sha=sha(target))
        self.assertTrue(result['engineEvaluated']);self.assertEqual({'checked':1},result['queryRows'])
        self.assertEqual(source.read_bytes(),(self.root/result['imports'][0]['snapshot']).read_bytes())
        old=self.root/'.state/evidence-views/archive'/hashlib.sha256(original).hexdigest()
        self.assertEqual(original,old.read_bytes());self.assertFalse(result['runtimeAdmitted'])
        second=views.materialize(self.root,'evidence/sample.view.source.json',expected_view_sha=sha(target))
        self.assertFalse(second['changed']);self.assertEqual(result['queryAnswersSha256'],second['queryAnswersSha256'])
        self.assertTrue(views.check_binding(self.root,'evidence/sample.view.json'))
        declaration=self.root/'evidence/sample.view.source.json'
        spec=json.loads(declaration.read_text());spec['view']['facts']['input']=[[99]];w.write(declaration,spec)
        with self.assertRaisesRegex(ValueError,'binding stale'):
            views.check_binding(self.root,'evidence/sample.view.json')

    def test_stale_declared_source_fails_without_changing_existing_view(self):
        target,source,original=self.declaration();expected=sha(target);source.write_text('unreviewed change')
        with self.assertRaisesRegex(ValueError,'reviewed source changed'):
            views.materialize(self.root,'evidence/sample.view.source.json',expected_view_sha=expected)
        self.assertEqual(original,target.read_bytes())

    def test_publication_does_not_overwrite_a_concurrent_view(self):
        target,source,original=self.declaration()
        from gambit_smp.evidence_views import evaluate
        def concurrent(*args):
            result=evaluate(*args);target.write_text('{"concurrent":"retained"}');return result
        with patch('gambit_smp.evidence_views.evaluate',side_effect=concurrent):
            with self.assertRaisesRegex(ValueError,'concurrent Evidence publication'):
                views.materialize(self.root,'evidence/sample.view.source.json',expected_view_sha=sha(target))
        self.assertEqual('{"concurrent":"retained"}',target.read_text())
        self.assertEqual([],list(target.parent.glob('.sample.view.json.*')))

    def test_changed_git_patch_is_not_blessed_by_regeneration(self):
        target,source,original=self.declaration(external=True);expected=sha(target);source.write_text('later dirty source')
        with self.assertRaisesRegex(ValueError,'working source or patch changed'):
            views.materialize(self.root,'evidence/sample.view.source.json',expected_view_sha=expected)
        self.assertEqual(original,target.read_bytes())

    def test_nested_domain_queue_expires_with_unclaimed_jobs_preserved(self):
        w.start(self.root,'repair',adopt=True)
        outer=self.root/'.cache/old';domain=outer/'full/graph/validation/domains/0';lane=domain/'0';lane.mkdir(parents=True)
        queue=domain/'queue.sqlite';ids=['tests.Sample.test_one','tests.Sample.test_two']
        with closing(sqlite3.connect(queue)) as db:
            db.execute('CREATE TABLE jobs(ordinal INTEGER UNIQUE,id TEXT PRIMARY KEY,lane INTEGER)');db.executemany('INSERT INTO jobs VALUES(?,?,NULL)',enumerate(ids));db.commit()
        request=dict(schema='sealed-validation-request.v1',engineId='engine',root=str(self.root),queue=str(queue),testIds=ids,lane=0)
        w.write(lane/'request.json',request)
        child=subprocess.Popen([sys.executable,'-c',"print('real failed test producer');raise SystemExit(7)"],stdout=subprocess.PIPE,start_new_session=True)
        log=child.communicate()[0];self.assertEqual(7,child.returncode);(lane/'process.log').write_bytes(log)
        artifacts={name:sha(domain/name) for name in ['queue.sqlite','0/request.json','0/process.log']}
        row=dict(schema='sealed-validation-domain.v1',engineId='engine',expectedTestIds=ids,artifacts=artifacts,lanes=[dict(pid=child.pid,endedAt=w.now().isoformat(),exit=7)])
        w.write(domain/'receipt.json',row)
        for p in [*outer.rglob('*'),outer]:self.old(p)
        deps.adopt(self.root,'repair',['.cache/old']);task_retention.classify(self.root,'repair',recovery=[])
        self.assertEqual('expired-validation-queues.v2',queues.proof(outer)['schema'])
        from gambit_smp.storage_custody import audit
        with w.lease(self.root,'repair'):
            prepared=audit(self.root,'repair',archive_queues=True,opened=[])
            self.assertIn('lease held',prepared['taskCustody'])
            self.assertEqual(2,prepared['decisions'][0]['queueArchives'][0]['pendingTestJobs'])
            self.assertTrue(queue.exists())
        with closing(sqlite3.connect(queue)) as writer:
            writer.execute('BEGIN IMMEDIATE')
            with self.assertRaises(sqlite3.OperationalError):task_retention.collect(self.root,'repair',today=date(2099,1,1),opened=[])
            writer.rollback()
        self.assertEqual(['.cache/old'],task_retention.collect(self.root,'repair',today=date(2099,1,1),opened=[]))
        record=json.loads(deps.registry(self.root,'repair').read_text())['expired'][0]
        archive=self.root/record['cleanup']['queueArchives'][0]['path']
        with closing(sqlite3.connect(archive)) as db:self.assertEqual([(0,ids[0],None),(1,ids[1],None)],db.execute('SELECT * FROM jobs ORDER BY ordinal').fetchall())

    def test_dirty_nested_git_has_owned_release_conditions_and_never_expires_by_age(self):
        w.start(self.root,'repair',adopt=True);outer=self.root/'.cache/release';source=outer/'source';source.mkdir(parents=True)
        w.git(source,'init','-q');(source/'gerbil.pkg').write_text('(package: owned-project)');w.git(source,'add','gerbil.pkg');w.git(source,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','source');(source/'uncommitted.ss').write_text('keep')
        for p in [*outer.rglob('*'),outer]:self.old(p)
        deps.adopt(self.root,'repair',['.cache/release']);task_retention.classify(self.root,'repair',recovery=[])
        self.assertEqual([],task_retention.collect(self.root,'repair',today=date(2099,1,1),opened=[]))
        record=json.loads(deps.registry(self.root,'repair').read_text())['paths'][0]['gitCustody']
        self.assertEqual('owned-project',record['ownerProject']);self.assertTrue(record['repositories'][0]['dirty']);self.assertFalse(record['ageAloneReleases'])
        self.assertEqual('keep',(source/'uncommitted.ss').read_text())

    def test_group_number_reuse_uses_real_birth_time_without_signalling_new_owner(self):
        child=subprocess.Popen([sys.executable,'-c','import time;time.sleep(20)'],start_new_session=True)
        try:
            value=queues.producer_group(child.pid,'2000-01-01T00:00:00+00:00')
            self.assertEqual('reused-after-producer-exit',value['result'])
            self.assertIsNone(child.poll())
            self.assertIsNone(queues.producer_group(child.pid,'2099-01-01T00:00:00+00:00'))
        finally:child.terminate();child.wait(timeout=5)

    def test_source_review_reproduces_exact_delta_before_updating_declaration(self):
        import difflib
        target,source,original=self.declaration()
        declaration=self.root/'evidence/sample.view.source.json'
        baseline=self.root/'evidence/baseline.ss';baseline.write_bytes(source.read_bytes())
        source.write_text('reviewed expanded source\n')
        delta=''.join(difflib.unified_diff(baseline.read_text().splitlines(True),source.read_text().splitlines(True),fromfile='a/evidence/observed.ss',tofile='b/evidence/observed.ss'))
        (self.root/'evidence/source.patch').write_text(delta)
        review=dict(schema='ascent.source-binding-review.v1',declaration='evidence/sample.view.source.json',declarationSha256=sha(declaration),changes=[dict(reference='source',baseline='evidence/baseline.ss',patch='evidence/source.patch',citationIds=[],reason='Reviewed source-only extension',retainedScope='Static fixture, no runtime admission')])
        w.write(self.root/'evidence/review.json',review)
        receipt=views.review_sources(self.root,'evidence/review.json')
        self.assertEqual(sha(source),receipt['changes'][0]['newSha256'])
        self.assertEqual(original,target.read_bytes())
        with self.assertRaisesRegex(ValueError,'declaration changed'):views.review_sources(self.root,'evidence/review.json')
        result=views.materialize(self.root,'evidence/sample.view.source.json',expected_view_sha=sha(target))
        self.assertEqual({'checked':1},result['queryRows'])

    def semantic_update(self,remove_old=False):
        target,source,_=self.declaration()
        declaration=self.root/'evidence/sample.view.source.json';spec=json.loads(declaration.read_text())
        spec['view']['facts'].update(claim=[['old','proposal','retained']],value_review=[['Q','open']])
        w.write(declaration,spec)
        current=json.loads(json.dumps(spec['view']))
        current['references']=[dict(id='source',path='evidence/observed.ss',sha256=sha(source),pointer=None)]
        current['facts']['claim']=([] if remove_old else spec['view']['facts']['claim'])+[['new','proposal','new bounded question']]
        current['facts']['value_review']=[['Q','conditional']]
        w.write(target,current)
        review=dict(declarationUpdateOnly=True,runtimeAdmitted=False,executionAuthorized=False,
            inputs={str(target):sha(target)},newClaimIds=['new'],newClaims=1,newReferences=[],
            factCounts={key:len(value) for key,value in current['facts'].items()},
            valueReviewChanges=[dict(previous=['Q','open'],current=['Q','conditional'],reason='Reviewed bounded question')])
        w.write(self.root/'evidence/semantic.json',review)
        return declaration,target

    def test_semantic_import_preserves_concurrent_reviewed_new_claims(self):
        declaration,target=self.semantic_update();original_view=target.read_bytes()
        result=views.adopt_reviewed_view(self.root,'evidence/sample.view.source.json','evidence/semantic.json')
        self.assertEqual(1,result['newClaims']);self.assertFalse(result['runtimeAdmitted'])
        updated=json.loads(declaration.read_text())
        self.assertEqual(2,len(updated['view']['facts']['claim']));self.assertEqual(original_view,target.read_bytes())

    def test_semantic_import_rejects_silent_old_fact_removal(self):
        declaration,target=self.semantic_update(remove_old=True);original=declaration.read_bytes()
        with self.assertRaisesRegex(ValueError,'silently removed'):
            views.adopt_reviewed_view(self.root,'evidence/sample.view.source.json','evidence/semantic.json')
        self.assertEqual(original,declaration.read_bytes())

    def test_git_flow_collects_clean_integrated_source_and_keeps_unique_commit(self):
        from gambit_smp.storage_custody import audit
        canonical=self.root/'canonical';canonical.mkdir();w.git(canonical,'init','-q')
        (canonical/'gerbil.pkg').write_text('(package: owned-project)');w.git(canonical,'add','gerbil.pkg')
        w.git(canonical,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','integrated')
        for unique in (False,True):
            task='unique' if unique else 'integrated';w.start(self.root,task,adopt=True)
            outer=self.root/'.cache'/task;outer.mkdir();source=outer/'source'
            w.git(self.root,'clone','-q',str(canonical),str(source))
            if unique:
                (source/'unique.ss').write_text('unmerged source');w.git(source,'add','unique.ss')
                w.git(source,'-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','unique')
            for p in [*outer.rglob('*'),outer]:self.old(p)
            deps.adopt(self.root,task,['.cache/'+task]);task_retention.classify(self.root,task,recovery=[])
            receipt=audit(self.root,task,opened=[],paths=['.cache/'+task],integration=canonical)
            self.assertEqual('registered under owning task lease',receipt['ownershipRegistration'])
            removed=task_retention.collect(self.root,task,today=date(2099,1,1),opened=[])
            self.assertEqual([] if unique else ['.cache/'+task],removed)
            self.assertEqual(unique,source.exists())
            w.finish(self.root,task)
        self.assertTrue((canonical/'gerbil.pkg').exists())
