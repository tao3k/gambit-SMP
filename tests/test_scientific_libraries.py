"""Whole-cohort source qualification; mocked process tests are not native evidence."""
import ast
import copy
import hashlib
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp.framework import ROOT
from gambit_smp.recipes import CAPABILITIES, ExecutionContext
from gambit_smp.research_flow import (EvidenceUnavailable, ast_identity,
    check_scientific_migration, scientific_catalog_source, scientific_pool,
    scientific_predecessor, scientific_tree, study_execution)
from gambit_smp.scientific_catalog import ENTRIES, LIBRARIES

FIXTURE=ROOT/'tests/fixtures/sysml-api/scientific-cohort-migration.json'

class ScientificLibraryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.fixture=json.loads(FIXTURE.read_text())

    def test_complete_cohort_and_independent_inverse(self):
        result=check_scientific_migration(ROOT,self.fixture)
        self.assertEqual((133,221,0,0),(result['entries'],result['libraries'],result['standaloneRunners'],result['dynamicHelpers']))
        self.assertFalse(result['wholeStudyAdmitted']);self.assertFalse(result['runtimeAdmitted'])
        for change in ('missing','duplicate','identity','algorithm'):
            bad=copy.deepcopy(self.fixture)
            if change=='missing':bad['files'].pop()
            if change=='duplicate':bad['files'][1]=bad['files'][0]
            if change=='identity':bad['files'][0]['afterSha256']='changed'
            if change=='algorithm':bad['files'][0]['beforeAstSha256']['source']='changed'
            with self.subTest(change=change),self.assertRaises(ValueError):check_scientific_migration(ROOT,bad)

    def test_every_private_library_is_constructible_without_cache_or_rebinding(self):
        class Owner:
            def __init__(self,root):self.root=root
            def library(self,key):return LIBRARIES[key](self)
            def library_source(self,key):
                if key not in LIBRARIES:raise ValueError('unknown library')
                return 'src/gambit_smp/scientific_'+key+'.py'
        first=Owner(Path('/missing-checkout-a'));second=Owner(Path('/missing-checkout-b'))
        for name,library in LIBRARIES.items():
            with self.subTest(library=name):
                a=library(first);b=library(second)
                self.assertIsNot(a,b);self.assertIs(a.context,first);self.assertIs(b.context,second)
                if hasattr(a,'ROOT'):self.assertEqual(first.root,a.ROOT);self.assertEqual(second.root,b.ROOT)
                if name in ENTRIES:self.assertTrue(callable(a.analyze))
        with self.assertRaises(EvidenceUnavailable):ExecutionContext.library(SimpleNamespace(remaining=lambda:1),'../unknown')
        self.assertFalse(hasattr(ExecutionContext, "clues"))

    def test_native_catalog_view_is_closed_and_deterministic(self):
        values=dict(libraryIds=';'.join(LIBRARIES),entryIds=';'.join(ENTRIES),libraryCount=221,entryCount=133)
        self.assertEqual((ROOT/'src/gambit_smp/scientific_catalog.py').read_text(),scientific_catalog_source(values))
        for field,value in [('libraryIds',values['libraryIds']+';../escape'),('entryIds','unknown'),('libraryCount',True),('entryCount',132)]:
            bad={**values,field:value}
            with self.subTest(field=field),self.assertRaises(ValueError):scientific_catalog_source(bad)

    def test_static_catalog_is_data_and_cannot_inflate_writer_membership(self):
        from gambit_smp.research_flow import inventory
        with TemporaryDirectory() as temporary:
            root=Path(temporary).resolve();package=root/'src/gambit_smp';package.mkdir(parents=True)
            (package/'scientific_catalog.py').write_text('LIBRARIES = {}\n')
            (package/'scientific_unregistered.py').write_text('x = 1\n')
            with patch('gambit_smp.evidence_views.registry',return_value=([],{})):
                result=inventory(root)
            catalog=next(r for r in result['files'] if r['path'].endswith('scientific_catalog.py'))
            self.assertEqual('framework',catalog['role'])
            self.assertTrue(any('outside the native catalog' in row['reason'] for row in result['violations']))

    def test_memoized_subtrees_equal_standard_ast_dump(self):
        for name in ('typed_binding_witness','formal_study','runtime_ownership_study'):
            tree=scientific_tree((ROOT/('src/gambit_smp/scientific_'+name+'.py')).read_text())
            self.assertEqual({ast_identity(n) for n in ast.walk(tree)},set(scientific_pool(tree)))

    def test_independent_algorithm_projection_refuses_control_and_number_drift(self):
        from gambit_smp.research_flow import scientific_algorithm_correspondence
        row=next(r for r in self.fixture['files'] if r['id']=='typed_binding_witness')
        old=scientific_predecessor(ROOT,row);current=ast.parse((ROOT/row['library']).read_text())
        self.assertEqual(3,scientific_algorithm_correspondence(old,current)[0])
        for mutation in ('threshold','numeric-type','branch','missing-method'):
            changed=copy.deepcopy(current);klass=next(n for n in changed.body if isinstance(n,ast.ClassDef))
            if mutation=='missing-method':klass.body=[n for n in klass.body if not(isinstance(n,ast.FunctionDef) and n.name=='check')]
            else:
                method=next(n for n in klass.body if isinstance(n,ast.FunctionDef) and n.name=='check')
                if mutation=='branch':method.body.append(ast.If(ast.Constant(True),[ast.Pass()],[]))
                else:
                    number=next(n for n in ast.walk(method) if isinstance(n,ast.Constant) and type(n.value) is int)
                    number.value=number.value+1 if mutation=='threshold' else float(number.value)
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):scientific_algorithm_correspondence(old,changed)

    def test_real_json_algorithm_and_refusals_match_predecessor(self):
        row=next(r for r in self.fixture['files'] if r['id']=='typed_binding_witness')
        predecessor=scientific_predecessor(ROOT,row)
        # This reviewed module contains only JSON algorithms and the Refusal
        # type: execute neither a retired runner nor native command transport.
        self.assertTrue(all(isinstance(n,(ast.Import,ast.ClassDef,ast.FunctionDef,ast.Expr)) for n in predecessor.body))
        original={};exec(compile(predecessor,'<reviewed-json-algorithm>','exec'),original)
        current=LIBRARIES['typed_binding_witness'](SimpleNamespace(root=ROOT))
        cases=['{}','[]','{"x":[true,0,"汉字"]}','{"x":1,"x":2}','NaN','Infinity','-Infinity','{"x":','null','18446744073709551616']
        for text in cases:
            outcomes=[]
            for operation in (original['read_json'],current.read_json):
                try:outcomes.append(('value',operation(text)))
                except ValueError as error:outcomes.append(('refusal',str(error)))
            self.assertEqual(outcomes[0],outcomes[1],text)

    def context(self,root):
        out=root/'.cache/tasks/unit/run';directory=out/'study';directory.mkdir(parents=True)
        return ExecutionContext(root,out,directory,{},time.monotonic()+10,{},
            {'engine':{'path':'unit-mock'}},{'node':'/sealed/node','quint':'/sealed/quint','lean':'/sealed/lean','git':'/sealed/git'})

    def test_shared_command_ownership_budget_repetition_and_negative_controls(self):
        from gambit_smp.process_observation import Observation
        policy=dict(cap=60,stream='stdout',failure='assertion',failParameter=True,expectedParameter=False)
        with TemporaryDirectory() as temporary:
            root=Path(temporary).resolve();(root/'m.qnt').write_text('module m { pure val ok = true }')
            context=self.context(root);deadline=context.deadline
            def result(code=0):return Observation('same output','same diagnostic',code,False,.01,1,'unit','unit',True,())
            with study_execution(context,projection={'step':'model','output':'projection'}):
                with patch('gambit_smp.process_observation.capture',return_value=result()) as native:
                    for _ in range(2):self.assertEqual('same output',context.command('same',['quint','typecheck','m.qnt'],policy=policy))
                    self.assertEqual(2,len(context.commands));self.assertNotEqual(context.commands[0]['log'],context.commands[1]['log'])
                    self.assertLessEqual(native.call_args.args[2],10);self.assertEqual(deadline,context.deadline)
                    self.assertEqual(['typecheck','m.qnt'],native.call_args.args[0][2:])
                with patch('gambit_smp.process_observation.capture',return_value=result(3)):
                    self.assertEqual('same output',context.command('negative',['quint','typecheck','m.qnt'],True,policy=policy))
                    self.assertEqual(3,context.commands[-1]['expectedExit'])
                    with self.assertRaises(AssertionError):context.command('wrong',['quint','typecheck','m.qnt'],policy=policy)
                with patch('gambit_smp.process_observation.capture',return_value=result(-9)):
                    with self.assertRaises(AssertionError):context.command('signal',['quint','typecheck','m.qnt'],True,policy=policy)
                with self.assertRaises(EvidenceUnavailable):context.command('missing',['lean','missing.lean'],policy=policy)
                with self.assertRaises(EvidenceUnavailable):context.command('impostor',['/other/provider/quint','typecheck','m.qnt'],policy=policy)
                with patch('gambit_smp.process_observation.capture',return_value=Observation(b'\xff\x00\r\n',b'\xfe',0,False,.01,1,'unit','unit',True,())):
                    self.assertEqual(b'\xff\x00\r\n',context.output(['git','show','HEAD:x'],name='bytes'))
                    self.assertEqual(b'\xff\x00\r\n',(context.directory/'work/bytes.stdout').read_bytes())
                with self.assertRaises(ValueError):context.command('../outside',['quint','typecheck','m.qnt'],policy=policy)
                with self.assertRaises(ValueError):context.command('flag',['quint','typecheck','m.qnt','--unknown','x'],policy=policy)
                with self.assertRaises(ValueError):context.command('budget',['quint','typecheck','m.qnt'],policy={**policy,'cap':61})
                with self.assertRaises(ValueError):context.command('bool',['quint','typecheck','m.qnt'],policy={**policy,'failParameter':1})
                context.deadline=time.monotonic()-1
                with self.assertRaises(TimeoutError):context.command('late',['quint','typecheck','m.qnt'],policy=policy)
            with self.assertRaises(EvidenceUnavailable):context.command('retired',['quint','typecheck','m.qnt'],policy=policy)

    def test_native_artifact_build_capture_and_drift_refusal(self):
        import os,shutil
        from gambit_smp.native_capabilities import c_build
        compiler=os.environ.get('GAMBIT_SMP_TEST_GCC') or shutil.which('gcc-16') or shutil.which('gcc')
        if not compiler:self.skipTest('GNU GCC provider unavailable; native admission not established')
        with TemporaryDirectory() as temporary:
            root=Path(temporary).resolve();context=self.context(root)
            context.env={**os.environ,'PATH':'/usr/bin:/bin'};context.tools={'gcc':compiler}
            context.receipt['executionConfig']={'allowNative':True}
            context.receipt['steps']=[dict(id='build',capability='native.c-build',dependsOn=[],outcome='PASS')]
            (root/'bytes.c').write_text('#include <stdio.h>\nint main(void) { unsigned char b[]={255,0,13,10,128}; return fwrite(b,1,sizeof b,stdout)==sizeof b?0:1; }\n')
            built=c_build(dict(sources=['bytes.c'],headers=[],standard='c23',optimization=0,pthread=False,target='executable'),context)
            context.receipt['steps'][0]['outputs']=built['outputs']
            consumer=context.out/'consumer';consumer.mkdir()
            active=ExecutionContext(root,context.out,consumer,context.env,time.monotonic()+10,{},context.receipt,{})
            active.receipt['steps'].append(dict(id='consumer',capability='research.audit',dependsOn=['build']))
            reference=dict(step='build',output='executable')
            with study_execution(active,projection=dict(step='unused',output='projection')):
                self.assertEqual(b'\xff\x00\r\n\x80',active.output([reference],name='native-bytes'))
                self.assertEqual(reference,active.commands[-1]['executableInput'])
                count=len(active.commands)
                from gambit_smp.storage_policy import StoragePolicyError
                with self.assertRaises(StoragePolicyError):active.output([str(context.directory/'program')],name='raw-path')
                active.receipt['steps'][-1]['dependsOn']=[]
                with self.assertRaises(EvidenceUnavailable):active.output([reference],name='undeclared')
                active.receipt['steps'][-1]['dependsOn']=['build']
                active.receipt['steps'][0]['outputs']['executable']['sha256']='0'*64
                with self.assertRaises(ValueError):active.output([reference],name='changed')
                self.assertEqual(count,len(active.commands))

    def test_shared_typed_input_group_has_no_legacy_fallback(self):
        consumers=[r for r in self.fixture['files'] if 'typedInputMigration' in r]
        self.assertEqual(9,len(consumers));self.assertEqual(18,sum(r['typedInputMigration']['sites'] for r in consumers))
        for row in consumers:
            self.assertNotIn(row['typedInputMigration']['retiredLiteral'],(ROOT/row['library']).read_text())
        from gambit_smp.recipes import load
        recipe,steps=load(ROOT,ROOT/'tests/recipes/framework-contracts/current-research-recovery.recipe.json')
        self.assertEqual(120,recipe['budgetSeconds'])
        witness=next(r for r in steps if r['id']=='witness')
        validate=CAPABILITIES['research.audit'].graph
        by_id={r['id']:r for r in steps}
        validate(witness,by_id,CAPABILITIES)
        for change in ('untyped','undeclared','wrong-output'):
            bad=copy.deepcopy(by_id);current=bad['witness']
            if change=='untyped':bad['typed']['arguments']['typed']=False
            if change=='undeclared':current['dependsOn'].remove('typed')
            if change=='wrong-output':current['arguments']['typedIr']['output']='observation'
            with self.subTest(change=change),self.assertRaises(ValueError):validate(current,bad,CAPABILITIES)
        validate=CAPABILITIES['quint.observe'].validate
        for argv in ([],['test','m.qnt'],['typecheck','m.qnt','--out','foreign.json']):
            with self.assertRaises(ValueError):validate(dict(argv=argv,typed=True),['m.qnt'])

    def test_recovery_cannot_drop_or_reinterpret_a_historical_obligation(self):
        from gambit_smp.research_flow import evidence_recovery
        plan=json.loads((ROOT/'tests/fixtures/sysml-api/evidence-recovery.json').read_text())
        self.assertEqual(235,len(plan['rows']));self.assertEqual(158,len({r['path'] for r in plan['rows']}))
        for mutation in ('drop','duplicate','rebind'):
            with TemporaryDirectory() as temporary:
                root=Path(temporary).resolve();changed=copy.deepcopy(plan)
                if mutation=='drop':changed['rows'].pop()
                if mutation=='duplicate':changed['rows'][1]=changed['rows'][0]
                if mutation=='rebind':changed['rows'][0]['referenceSpec']['sha256']='0'*64
                path=root/'plan.json';path.write_text(json.dumps(changed))
                first=plan['rows'][0];view=root/first['view'];view.parent.mkdir(parents=True);view.write_bytes((ROOT/first['view']).read_bytes())
                projection=root/'projection.json';projection.write_text(json.dumps(dict(values={'ScientificStudies::recovery':dict(plan='plan.json',referenceCount=235)})))
                doc=json.loads(view.read_text());manifest=root/doc['manifest'];manifest.parent.mkdir(parents=True,exist_ok=True);manifest.write_bytes((ROOT/doc['manifest']).read_bytes())
                ctx=SimpleNamespace(root=root,artifact=lambda *_:projection,bind=lambda _:None,remaining=lambda:10,
                    receipt={'declaredInputs':['plan.json',first['view'],doc['manifest']], 'engine':{'path':str(root/'engine')}})
                message='historical obligation' if mutation=='rebind' else 'complete independent235'
                with patch('gambit_smp.ascent_program.load_component_catalog',return_value=dict(sourceInputs={},nativeComponents={'manifest':{'components':[]}})):
                    with self.subTest(mutation=mutation),self.assertRaisesRegex(ValueError,message):evidence_recovery(dict(projection={}),ctx)

    def test_whole_historical_storage_migration_keeps_content_and_duty(self):
        from gambit_smp.research_flow import recovery_reference
        rows=json.loads((ROOT/'tests/fixtures/sysml-api/evidence-recovery.json').read_text())['rows']
        documents={}
        for row in rows:
            doc=documents.setdefault(row['view'],json.loads((ROOT/row['view']).read_text()))
            reference=next(item for item in doc['references'] if item['id']==row['reference'])
            identity=recovery_reference(row,reference)
            self.assertEqual(row['sha256'],identity['sha256'])
            self.assertNotIn('identity',row['referenceSpec'])
            self.assertFalse(row['currentAdmission']);self.assertFalse(row['historicalObligationRetired'])
        self.assertEqual(49,sum(r['producer']['status']=='git-source' for r in rows))
        self.assertEqual(140,sum(r['producer']['status']=='unresolved' for r in rows))
        first=rows[0];reference=next(item for item in documents[first['view']]['references'] if item['id']==first['reference'])
        for mutation in ('content','path','repository','revision','blob','execution','fallback','old-edge'):
            row=copy.deepcopy(first);ref=copy.deepcopy(reference)
            if mutation=='content':row['storageResolution']['identity']['sha256']='0'*64
            if mutation=='path':row['storageResolution']['identity']['path']='foreign.c'
            if mutation=='repository':row['storageResolution']['identity']['repository']='..'
            if mutation=='revision':row['storageResolution']['identity']['revision']='HEAD'
            if mutation=='blob':row['storageResolution']['identity']['blob']='alias'
            if mutation=='execution':row['storageResolution']['executionProvenance']=True
            if mutation=='fallback':row['storageResolution']['cacheFallback']=True
            if mutation=='old-edge':ref=copy.deepcopy(row['referenceSpec'])
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):recovery_reference(row,ref)

    def test_observation_duties_preserve_full_cohort_and_distinct_kinds(self):
        from collections import Counter
        from gambit_smp.research_flow import observation_mechanism
        from gambit_smp.recipes import load
        ledger=json.loads((ROOT/'tests/fixtures/sysml-api/evidence-recovery.json').read_text())
        plan=ledger['observationProducerPlan']
        rows=[r for r in ledger['rows'] if r['id'] in plan['cohortIds']]
        self.assertEqual((50,28),(len(rows),len(plan['records'])))
        self.assertEqual({'native-result':47,'formal-result':3},dict(Counter(r['group'] for r in rows)))
        self.assertEqual({'native-execution':24,'object-codegen':9,'image-mapping':7,
                          'conditional-model':5,'source-reapply':2,'bounded-model':2,'lean-proof':1},
                         dict(Counter(plan['records'][r['path']]['mechanism'] for r in rows)))
        self.assertEqual('conditional-model',observation_mechanism('native-result.json',dict(schema='gambit-smp.conditional-frame-composition.v1')))
        with self.assertRaises(ValueError):observation_mechanism('native.json',dict(schema='unknown',status='PASS'))
        validate_lean=CAPABILITIES['lean.check'].validate
        for modules in [[{'name':'../escape','source':'m.lean'}],
                        [{'name':'A','source':'m.lean'},{'name':'a','source':'m.lean'}],
                        [{'name':'A','identity':{'kind':'task-checkpoint'}}]]:
            with self.assertRaises(ValueError):validate_lean(dict(argv=['m.lean'],modules=modules),['m.lean'])
        self.assertEqual(5,sum(argv[0]=='run' for argv in plan['formalCommands']))
        for argv in plan['formalCommands'][2:]:
            self.assertEqual(['--max-samples','100','--max-steps','10','--seed','42'],argv[-6:])
        _,steps=load(ROOT,ROOT/'tests/recipes/framework-contracts/observation-producer-study.recipe.json')
        by_id={step['id']:step for step in steps};audit=by_id['audit']
        graph=CAPABILITIES['research.audit'].graph;graph(audit,by_id,CAPABILITIES)
        for mutation in ('undeclared','wrong-output','wrong-kind'):
            bad=copy.deepcopy(by_id)
            if mutation=='undeclared':bad['audit']['dependsOn'].remove('q1')
            if mutation=='wrong-output':bad['audit']['arguments']['observations']['q1']['output']='typed'
            if mutation=='wrong-kind':bad['q1']['capability']='native.c-build'
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):graph(bad['audit'],bad,CAPABILITIES)

    def test_scientific_scope_only_accepts_its_owned_birth_archive(self):
        with TemporaryDirectory() as temporary:
            root=Path(temporary).resolve();context=self.context(root)
            peer=context.out.parent/'process-starts'
            with patch('gambit_smp.task_processes.recorder',return_value=SimpleNamespace(root=root,spawn_root=peer)):
                with study_execution(context,projection=dict(step='model',output='projection')) as state:
                    self.assertIn(str(peer.relative_to(root))+'/',context.receipt['scientific'][context.directory.name]['serviceDirectories'])
            for index in range(2):
                other=self.context(root/('other'+str(index)))
                target=other.root/('src' if index==0 else '.cache/tasks/foreign/outputs/process-starts')
                with patch('gambit_smp.task_processes.recorder',return_value=SimpleNamespace(root=other.root,spawn_root=target)):
                    with self.assertRaises(EvidenceUnavailable):
                        with study_execution(other,projection=dict(step='model',output='projection')):pass

    def test_command_journal_grant_cannot_write_source_or_other_request(self):
        import os
        from gambit_smp.storage_policy import study_writes,StoragePolicyError
        from gambit_smp.research_flow import _approved_command
        with TemporaryDirectory() as temporary:
            root=Path(temporary).resolve();journal=root/'.cache/tasks/unit/outputs/request'
            work=journal/'run/witness';work.mkdir(parents=True)
            protected=journal/'run-header.json';protected.write_text('immutable')
            external=root/'source.txt';external.write_text('source')
            name='process-'+('a'*32)+'-planned.json';target=journal/name;pending=journal/(name+'.pending-'+('b'*32))
            with study_writes(root,work,[],journal=journal):
                with self.assertRaises(StoragePolicyError):pending.write_text('no command')
                token=_approved_command.set(('qualified-lean',))
                try:
                    pending.write_text('owned process record');os.link(pending,target);pending.unlink()
                    self.assertEqual('owned process record',target.read_text())
                    with self.assertRaises(StoragePolicyError):protected.write_text('overwrite')
                    with self.assertRaises(StoragePolicyError):os.link(external,journal/('process-'+('c'*32)+'-started.json'))
                    with self.assertRaises(StoragePolicyError):(root/'.cache/tasks/unit/outputs'/name).write_text('foreign request')
                finally:_approved_command.reset(token)
            self.assertEqual('immutable',protected.read_text())

    def test_formal_roles_are_distinct_registered_capabilities(self):
        self.assertIn('quint.observe',CAPABILITIES);self.assertIn('lean.check',CAPABILITIES)
        self.assertIsNot(CAPABILITIES['quint.observe'].executor,CAPABILITIES['quint.verify'].executor)
        self.assertIsNot(CAPABILITIES['lean.check'].executor,CAPABILITIES['quint.observe'].executor)
        validate=CAPABILITIES['research.audit'].validate
        with self.assertRaises(ValueError):validate({'projection':{'step':'m','output':'projection'},'study':'unknown'},[])
        with self.assertRaises(ValueError):validate({'projection':{'step':'m','output':'projection'},'study':next(iter(ENTRIES))},[])

    def test_source_archive_reuse_preserves_identity_and_refuses_drift(self):
        from gambit_smp.evidence_capabilities import EvaluationOwner
        with TemporaryDirectory() as temporary:
            root=Path(temporary).resolve();source=root/'source.ss';source.write_text('original')
            directory=root/'owner';directory.mkdir()
            owner=EvaluationOwner(root/'engine',directory,time.monotonic()+10)
            before=hashlib.sha256(source.read_bytes()).hexdigest()
            a=owner.archive_source(source,before);b=owner.archive_source(source,before)
            self.assertEqual(a,b);self.assertEqual(str(source),b['originalPath'])
            self.assertEqual((1,1),(len(owner.source_archives),owner.source_archive_reuses))
            source.write_text('changed')
            with self.assertRaises(ValueError):owner.archive_source(source,before)
            after=hashlib.sha256(source.read_bytes()).hexdigest();c=owner.archive_source(source,after)
            self.assertNotEqual(a['archivePath'],c['archivePath'])
            self.assertEqual('original',Path(a['archivePath']).read_text())
            snapshot=Path(c['archivePath']);snapshot.chmod(0o644);snapshot.write_text('tampered')
            with self.assertRaises(ValueError):owner.archive_source(source,after)
            self.assertEqual('tampered',snapshot.read_text())
            owner.closed=True
            with self.assertRaises(ValueError):owner.archive_source(source,after)

if __name__=='__main__':unittest.main()
