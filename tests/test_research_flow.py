"""Fresh executions and missing bytes cannot borrow an earlier PASS."""
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import types
import unittest
import os

from gambit_smp.research_flow import (EvidenceUnavailable, SourceViewDrift,
                                     check_command, study_execution, study_workspace, write_text)
from gambit_smp.storage_policy import StoragePolicyError, validate


class ResearchFlowTests(unittest.TestCase):
    def test_typed_artifact_reader_refuses_stale_partial_foreign_and_reordered_delivery(self):
        import copy,hashlib
        from gambit_smp.research_flow import projected_fields
        from types import SimpleNamespace
        digest=lambda value:hashlib.sha256(value).hexdigest()
        with TemporaryDirectory() as directory:
            root=Path(directory);owner=self.owner(root)
            (root/'m.sysml').write_text('package Pkg {}')
            inputs={'m.sysml':digest((root/'m.sysml').read_bytes())}
            plan=dict(schema='sysml-field-selection',queries=[dict(path=['case:row','0','key'],expression='Pkg::row0.key',kind='string')],
                      listGroups=['case:row'],modelInputs=inputs,expected={'case:row':[{'key':'value'}]})
            (root/'plan.json').write_text(json.dumps(plan))
            original=dict(schema='sysml-source-contract-projection',values=plan['expected'],orderedValues=['value'],
                runtimeAdmitted=False,modelInputs=inputs,diagnostics=[],equivalence=dict(matched=True,kind='ordered-fields-and-layout'),
                selectionSha256=digest(json.dumps(plan,sort_keys=True,separators=(',',':')).encode()))
            target=owner.directory/'projection.json'
            step=dict(id='model',capability='sysml.project',outcome='PASS',arguments=dict(selection='plan.json'),outputs={})
            owner.receipt['steps']=[step]
            owner.artifact=lambda ref,kind:target
            owner.bind=lambda paths:None
            def publish(value):
                target.write_text(json.dumps(value));step['outputs']={'projection':{'sha256':digest(target.read_bytes())}}
            publish(original);keys=[('row','0','key','Pkg::row0.key')]
            with study_execution(owner,projection={'step':'model','output':'projection'}):
                self.assertEqual(({'row':[{'key':'value'}]},inputs),projected_fields(root,None,'case',keys))
                delivery=projected_fields(root,None,'shared-helper',['Pkg::row0.key','Pkg::row0.key'],ordered=True,models=['m.sysml'])
                self.assertEqual(['value','value'],delivery['orderedValues'])
                self.assertEqual('sysml-ordered-field-delivery',delivery['schema']);self.assertNotIn('output',delivery)
                for expressions,models in [(['Pkg::missing.key'],[]),([],[]),(['Pkg::row0.key'],['missing.sysml']),(['Pkg::row0.key'],['../foreign.sysml'])]:
                    with self.assertRaises(EvidenceUnavailable):projected_fields(root,None,'case',expressions,ordered=True,models=models)
                for field,value in [('schema','wrong'),('runtimeAdmitted',True),('selectionSha256','stale'),('modelInputs',{}),('diagnostics',['warning']),('equivalence',{'matched':True}),('orderedValues',[]),('orderedValues',[True]),('values',{})]:
                    bad=copy.deepcopy(original);bad[field]=value;publish(bad)
                    with self.subTest(field=field,value=value),self.assertRaises(EvidenceUnavailable):projected_fields(root,None,'case',keys)
                publish(original);owner.root=root/'foreign'
                with self.assertRaises(EvidenceUnavailable):projected_fields(root,None,'case',keys)
                owner.root=root
                with self.assertRaises(EvidenceUnavailable):projected_fields(root,None,'case',[])
                step['outcome']='FAILED'
                with self.assertRaises(EvidenceUnavailable):projected_fields(root,None,'case',keys)
                step['outcome']='PASS';target.write_text('{}')
                with self.assertRaises(EvidenceUnavailable):projected_fields(root,None,'case',keys)
                publish(original)
                with self.assertRaises(StoragePolicyError):(root/'m.sysml').write_text('changed')
                with self.assertRaises(EvidenceUnavailable):projected_fields(root,owner.directory,'case',keys)
            (root/'m.sysml').write_text('changed')
            next_owner=self.owner(root);next_owner.receipt['steps']=[step];next_owner.artifact=lambda ref,kind:target;next_owner.bind=lambda paths:None
            with study_execution(next_owner,projection={'step':'model','output':'projection'}):
                with self.assertRaises(EvidenceUnavailable):projected_fields(root,None,'case',keys)

    def test_entire_stdout_cohort_preserves_ordered_scalar_transport_and_source(self):
        import ast,copy,hashlib
        from gambit_smp.framework import ROOT
        from gambit_smp.research_flow import check_stdout_migration,restore_stdout_source
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/stdout-cohort-migration.json').read_text())
        self.assertEqual(101,check_stdout_migration(ROOT,fixture)['guardedDecodersRetired'])
        samples=[False,0,True,1,'','quote " newline\n汉字',2**63-1]
        decoders=0;requests=0
        for record in fixture['files']:
            from gambit_smp.research_flow import ast_identity,scientific_records
            proof=scientific_records(ROOT)[record['path']]
            self.assertEqual(record['afterSha256'],proof['beforeSha256'])
            after=self.predecessor(record['path']);before=self.predecessor(record['path'],'stdout-before')
            self.assertEqual(record['beforeAstSha256'],ast_identity(before))
            self.assertEqual(record['afterAstSha256'],ast_identity(after))
            for node in ast.walk(before):
                if not isinstance(node,ast.ListComp) or not any(isinstance(n,ast.Constant) and n.value=='  = ' for n in ast.walk(node)):continue
                decoders+=1
                payload={'output':['ignored status']+['  = '+json.dumps(v) for v in samples]}
                namespace={'json':json,'raw':payload,'native':payload,'result':payload}
                values=eval(compile(ast.Expression(node),'<independent-retired-decoder>','eval'),namespace)
                self.assertEqual(json.dumps(samples),json.dumps(values))
            requests+=sum(isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id=='_study_fields' for n in ast.walk(after))
            from gambit_smp.research_flow import execution_debt
            self.assertNotIn('model-stdout',execution_debt(after)['factors'])
            # Every scientific run/test invocation and resource parameter remains
            # outside the reviewed source edits (whole-file inverses fence them).
        self.assertEqual((102,98),(decoders,requests))
        for field in ('beforeSha256','afterSha256','directRequests'):
            bad=copy.deepcopy(fixture)
            bad['files'][0][field]=0 if field=='directRequests' else 'wrong'
            with self.subTest(field=field),self.assertRaises(ValueError):check_stdout_migration(ROOT,bad)
        for change in ('missing','duplicate'):
            bad=copy.deepcopy(fixture)
            if change=='missing':bad['files'].pop()
            else:bad['files'][1]=bad['files'][0]
            with self.subTest(change=change),self.assertRaises(ValueError):check_stdout_migration(ROOT,bad)


    def test_current_field_plan_keeps_independent_oracle_and_refuses_rebase(self):
        import copy
        from gambit_smp.framework import ROOT
        from gambit_smp.research_flow import check_field_evolution
        review=json.loads((ROOT/'tests/fixtures/sysml-api/three-study-evolution.json').read_text())
        result=check_field_evolution(ROOT,review)
        self.assertEqual(809,result['fields'])
        self.assertTrue(result['independentExpectedUnchanged'])
        for mutation in ('before','after','diff','added','oracle'):
            changed=copy.deepcopy(review)
            if mutation=='before':changed['changed'][0]['before']+='drift'
            if mutation=='after':changed['changed'][0]['afterSha256']='0'*64
            if mutation=='diff':changed['changed'][0]['reviewedDiff']=''
            if mutation=='added':changed['addedModels']=[]
            if mutation=='oracle':changed['expectedSha256']='0'*64
            with self.subTest(mutation=mutation),self.assertRaises(ValueError):check_field_evolution(ROOT,changed)

    def test_selected_consumers_preserve_old_layout_scope_and_saved_data(self):
        import ast,copy
        from gambit_smp.framework import ROOT
        from gambit_smp.contract_capabilities import typed_equal
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/workspace-context-migration.json').read_text())
        plan=json.loads((ROOT/'tests/fixtures/sysml-api/three-study-selection.json').read_text())
        count=0
        for record in fixture['files']:
            if 'fieldSelectionMigration' not in record:continue
            count+=1;component=Path(record['path']).stem.removesuffix('-study')
            rows=[r for r in plan['queries'] if r['path'][0].startswith(component+':')]
            expected={k[len(component)+1:]:v for k,v in plan['expected'].items() if k.startswith(component+':')}
            keys=[(r['path'][0][len(component)+1:],*r['path'][1:],r['expression']) for r in rows]
            source=self.predecessor(record['path'])
            groups=next(n for n in source.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='GROUPS' for t in n.targets))
            pkg=next(n for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='PKG' for t in n.targets))
            namespace={'ROOT':ROOT,'json':json,'GROUPS':ast.literal_eval(groups.value),'PKG':ast.literal_eval(pkg.value),
                       '_study_workspace':lambda _:Path('/owned/work'),'sha':lambda p:plan['modelInputs'][str(p.relative_to(ROOT))]}
            results=[]
            for project in (ast.parse(record['fieldSelectionMigration']['projectBefore']).body[0],
                            next(n for n in source.body if isinstance(n,ast.FunctionDef) and n.name=='project')):
                saved={};calls=[]
                def save(path,value):saved[str(path)]=copy.deepcopy(value)
                def run(label,argv):
                    calls.append(argv)
                    if argv[0]=='rg':return '\n'.join(plan['modelInputs'])
                    self.assertEqual([r['expression'] for r in rows],argv[6:-1:2])
                    values=[]
                    for r in rows:
                        g,i,f=r['path'];container=plan['expected'][g]
                        values.append((container[int(i)] if isinstance(container,list) else container[i])[f])
                    return json.dumps(dict(exit=0,errors=[],output=['  = '+json.dumps(v) for v in values]))
                def fields(root,projection_run,name,selected):
                    self.assertEqual((ROOT,'explicit-run',component,keys),(root,projection_run,name,selected))
                    return copy.deepcopy(expected),dict(plan['modelInputs'])
                ns={**namespace,'save':save,'run':run,'_study_fields':fields}
                exec(compile(ast.Module(body=[copy.deepcopy(project)],type_ignores=[]),'<reviewed-projector>','exec'),ns)
                value=ns['project'](*(['explicit-run'] if project.args.args else []))
                results.append((value,saved))
                if project.args.args:self.assertEqual([],calls)
            self.assertTrue(typed_equal(results[0],results[1]),component)
        self.assertEqual(3,count)

    def test_field_handoff_proof_refuses_changed_projector_or_scientific_controls(self):
        import ast,copy
        from gambit_smp.framework import ROOT
        from gambit_smp.research_flow import restore_field_selection
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/workspace-context-migration.json').read_text())
        record=next(r for r in fixture['files'] if 'fieldSelectionMigration' in r)
        source=self.predecessor(record['path'])
        for name in ('project','main'):
            changed=copy.deepcopy(source)
            target=next(n for n in changed.body if isinstance(n,ast.FunctionDef) and n.name==name)
            target.body.append(ast.Pass())
            with self.subTest(name=name),self.assertRaises(ValueError):restore_field_selection(changed,record)

    def test_real_shared_helper_preserves_outputs_limits_and_failure_mapping(self):
        import ast,copy,hashlib
        from types import SimpleNamespace
        from gambit_smp.framework import ROOT
        source=self.predecessor('dev/modeling/tools/advantage-architecture-study.py')
        run=next(n for n in source.body if isinstance(n,ast.FunctionDef) and n.name=='run')
        class Inverse(ast.NodeTransformer):
            def visit_Call(self,node):
                if isinstance(node.func,ast.Name) and node.func.id=='_study_workspace':
                    return ast.copy_location(ast.Name(node.args[0].value,ast.Load()),node)
                return self.generic_visit(node)
        with TemporaryDirectory() as directory:
            root,owned,metadata=self.make_source(directory)
            for exit_code in (0,9):
                with study_execution(self.owner(root),projection={'step':'model','output':'projection'}) as context:
                    outcomes=[]
                    for node in (Inverse().visit(copy.deepcopy(run)),copy.deepcopy(run)):
                        calls=[]
                        def invoke(argv,**options):
                            calls.append((argv,options))
                            return SimpleNamespace(returncode=exit_code,stdout='same output',stderr='same diagnostic')
                        namespace=dict(subprocess=SimpleNamespace(run=invoke),ROOT=root,CACHE=context['work'],
                            _study_workspace=study_workspace,_study_write_text=write_text,json=json,hashlib=hashlib,
                            save=lambda path,value:write_text(path,json.dumps(value,indent=2,ensure_ascii=False)+'\n'))
                        exec(compile(ast.fix_missing_locations(ast.Module(body=[node],type_ignores=[])),'<owned-helper>','exec'),namespace)
                        try:value=namespace['run']('case',['quint','test','unchanged.qnt'])
                        except RuntimeError:value='RuntimeError'
                        files={p.name:p.read_bytes() for p in context['work'].iterdir()}
                        outcomes.append((value,files,calls))
                    self.assertEqual(outcomes[0],outcomes[1])
                    self.assertEqual(60,outcomes[1][2][0][1]['timeout'])

    def test_copied_callback_context_cannot_revive_retired_workspace(self):
        from contextvars import copy_context,Context
        with TemporaryDirectory() as directory:
            root,source,namespace=self.make_source(directory)
            with study_execution(self.owner(root),projection={'step':'model','output':'projection'}):
                callback=copy_context()
                target=study_workspace('CACHE')/'late.json'
                self.assertEqual(target.parent,callback.run(study_workspace,'CACHE'))
                with self.assertRaises(StoragePolicyError):Context().run(study_workspace,'CACHE')
            for function,args in ((study_workspace,('CACHE',)),(write_text,(target,'late'))):
                with self.assertRaises(StoragePolicyError):callback.run(function,*args)
            self.assertFalse(target.exists())

    def test_inventory_refuses_reintroduced_helper_global_assignment(self):
        from unittest.mock import patch
        from gambit_smp.research_flow import inventory
        with TemporaryDirectory() as directory:
            root=Path(directory);source=root/'dev/modeling/tools/new.py';source.parent.mkdir(parents=True)
            source.write_text('helper.CACHE = other\n')
            with patch('gambit_smp.evidence_views.registry',return_value=([],{})):
                report=inventory(root)
            self.assertTrue(any(row['reason']=='global workspace rebinding is retired' for row in report['violations']))

    def test_workspace_cohort_checker_rejects_algorithm_or_role_drift(self):
        import copy
        from gambit_smp.framework import ROOT
        from gambit_smp.research_flow import check_workspace_migration
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/workspace-context-migration.json').read_text())
        result=check_workspace_migration(ROOT,fixture)
        self.assertEqual((123,4223,168),(result['files'],result['workspaceReads'],result['helperRebindingsRemoved']))
        for change in ('missing','digest','count','duplicate'):
            bad=copy.deepcopy(fixture)
            if change=='missing':bad['files'].pop()
            if change=='digest':bad['files'][0]['normalizedAstSha256']='wrong'
            if change=='count':bad['files'][0]['readCount']+=1
            if change=='duplicate':bad['files'][1]=bad['files'][0]
            with self.subTest(change=change),self.assertRaises(ValueError):check_workspace_migration(ROOT,bad)

    def test_workspace_roles_require_live_owner_and_exception_resets_it(self):
        with self.assertRaises(StoragePolicyError):study_workspace('CACHE')
        with self.assertRaises(ValueError):study_workspace('arbitrary')
        with TemporaryDirectory() as directory:
            root,source,namespace=self.make_source(directory)
            unchanged=dict(namespace)
            with self.assertRaisesRegex(RuntimeError,'deliberate'):
                with study_execution(self.owner(root),projection={'step':'model','output':'projection'}) as context:
                    self.assertEqual(context['work'],study_workspace('CACHE'))
                    self.assertEqual(context['results'],study_workspace('OUT'))
                    self.assertEqual(study_workspace('OUT'),study_workspace('EVIDENCE'))
                    with self.assertRaisesRegex(ValueError,'nested'):
                        with study_execution(context['context'],projection={'step':'model','output':'projection'}):pass
                    raise RuntimeError('deliberate')
            self.assertEqual(unchanged,namespace)
            with self.assertRaises(StoragePolicyError):study_workspace('CACHE')
            record=self.execution_record(context)
            self.assertEqual('failed',record['state'])
            self.assertFalse(record['runtimeAdmitted'])

    def test_whole_workspace_cohort_preserves_pre_migration_ast_and_limits(self):
        import ast,hashlib,copy
        from gambit_smp.framework import ROOT
        fixture=json.loads((ROOT/'tests/fixtures/sysml-api/workspace-context-migration.json').read_text())
        self.assertEqual(123,len(fixture['files']))
        for row in fixture['files']:
            transports=json.loads((ROOT/'tests/fixtures/sysml-api/stdout-cohort-migration.json').read_text())
            phase='stdout-before' if any(r['path']==row['path'] for r in transports['files']) else 'source'
            tree=self.predecessor(row['path'],phase)
            from gambit_smp.research_flow import restore_field_selection
            tree=restore_field_selection(tree,row)
            tree.body=[n for n in tree.body if not isinstance(n,ast.Pass) and not (isinstance(n,ast.ImportFrom)
                and n.module=='gambit_smp.research_flow' and any(a.asname=='_study_workspace' for a in n.names))]
            class Inverse(ast.NodeTransformer):
                def visit_Call(self,node):
                    if isinstance(node.func,ast.Name) and node.func.id=='_study_workspace':
                        self.assert_role(node)
                        return ast.copy_location(ast.Name(node.args[0].value,ast.Load()),node)
                    return self.generic_visit(node)
                def assert_role(self,node):
                    if len(node.args)!=1 or not isinstance(node.args[0],ast.Constant) or node.args[0].value not in row['symbols']:
                        raise ValueError('unexpected workspace substitution')
            original=Inverse().visit(tree)
            identity=hashlib.sha256(ast.dump(original,include_attributes=False).encode()).hexdigest()
            self.assertEqual(row['normalizedAstSha256'],identity,row['path'])
            constants=[n.value for n in ast.walk(original) if isinstance(n,ast.Constant) and type(n.value) in (int,float,bool)]
            self.assertEqual(row['controlLiteralsSha256'],hashlib.sha256(json.dumps(constants,separators=(',',':')).encode()).hexdigest(),row['path'])

    def test_retired_decoder_paths_cannot_return_by_same_count_substitution(self):
        import hashlib
        from gambit_smp.research_flow import check_stdout_inventory
        config=dict(remainingStdoutDecoderCount=1,remainingStdoutInventorySha256=hashlib.sha256(b'old.py\n').hexdigest())
        file=dict(path='old.py',role='guarded-study',executionDebt={'factors':{'model-stdout':[4]}})
        self.assertEqual(1,check_stdout_inventory(config,[file])['entries'])
        with self.assertRaises(ValueError):check_stdout_inventory(config,[dict(file,path='replacement.py')])

    def test_projection_input_never_searches_cache_or_accepts_a_foreign_run(self):
        from gambit_smp.research_flow import projected_fields
        with TemporaryDirectory() as directory:
            root=Path(directory)
            for path in (root/'missing',root/'.cache/tasks/missing'):
                with self.assertRaises(EvidenceUnavailable):projected_fields(root,path,'component',[])

    def test_no_new_runner_gate_checks_exact_names_not_only_count(self):
        import hashlib
        from gambit_smp.research_flow import check_retirement_inventory
        config=dict(remainingStudyCount=1,remainingStudyInventorySha256=hashlib.sha256(b'dev/modeling/tools/old.py\n').hexdigest())
        original=[dict(path='dev/modeling/tools/old.py',role='guarded-study')]
        self.assertEqual(1,check_retirement_inventory(config,original)['entries'])
        for files in ([],[dict(path='dev/modeling/tools/new.py',role='guarded-study')],
                      original+[dict(path='dev/modeling/tools/new.py',role='guarded-study')]):
            with self.assertRaisesRegex(ValueError,'SysML migration review'):
                check_retirement_inventory(config,files)

    def test_execution_debt_reports_real_syntax_without_claiming_alias_closure(self):
        import ast
        from gambit_smp.research_flow import execution_debt
        result=execution_debt(ast.parse("CACHE=root/'old'\nh.CACHE=CACHE\nsubprocess.run(['quint'])\nx.startswith('  = ')\nspec_from_file_location('h','dev/modeling/tools/helper.py')\nx='legacy-evidence/old'\n"))
        self.assertEqual([1,2],result['factors']['mutable-workspace'])
        self.assertEqual([3],result['factors']['native-process'])
        self.assertEqual([3],result['factors']['formal-command'])
        self.assertEqual([4],result['factors']['model-stdout'])
        self.assertEqual(['dev/modeling/tools/helper.py'],result['literalDependencies'])
        self.assertIn('unresolved',result['closure'])

    def test_cold_check_uses_shared_exported_module_and_structured_result(self):
        from unittest.mock import patch
        from types import SimpleNamespace
        from gambit_smp.research_flow import clean_smoke
        with TemporaryDirectory() as name:
            root=Path(name).resolve();destination=root/'export'
            def launch(argv, **options):
                self.assertNotIn('-c',argv)
                self.assertEqual('--cold-check',argv[-2])
                self.assertTrue(Path(argv[-3]).is_relative_to(destination))
                Path(argv[-1]).write_text(json.dumps(dict(schema='research-cold-check',root=str(destination))))
                return SimpleNamespace(returncode=0,stdout='untrusted non-JSON log',stderr='')
            with patch('gambit_smp.research_flow.materialize',return_value={'copiedCache':False}), \
                 patch('gambit_smp.research_flow.run_process',side_effect=launch):
                result=clean_smoke(root,destination)
                self.assertEqual(str(destination),result['smoke']['root'])
                self.assertFalse(result['nativeBuildRun'])
                with self.assertRaisesRegex(ValueError,'fresh cold result'):
                    clean_smoke(root,destination)

    def test_helper_cannot_publish_without_a_study_owner(self):
        with TemporaryDirectory() as directory:
            target = Path(directory)/'result.json'
            with self.assertRaisesRegex(StoragePolicyError, 'owned study_execution'):
                write_text(target, '{}')
            self.assertFalse(target.exists())

    def predecessor(self,name,phase='source'):
        from gambit_smp.framework import ROOT
        from gambit_smp.research_flow import scientific_records,scientific_predecessor
        return scientific_predecessor(ROOT,scientific_records(ROOT)[name],phase)

    def owner(self,root):
        from types import SimpleNamespace
        self._owner_count=getattr(self,'_owner_count',0)+1
        directory=root/'.cache/tasks/fixture/run'/str(self._owner_count)
        directory.mkdir(parents=True)
        return SimpleNamespace(root=root,directory=directory,receipt={})

    def execution_record(self,state):
        owner=state['context']
        return owner.receipt['scientific'][owner.directory.name]

    def make_source(self, directory):
        root = Path(directory).resolve()
        script = root/'dev/modeling/tools/fixture-study.py'
        script.parent.mkdir(parents=True)
        script.write_text('# source\n')
        old = root/'.cache/tasks/fixture'
        old.mkdir(parents=True)
        return root, script, dict(ROOT=root, CACHE=old, OUT=old/'old-results', TASK='fixture')

    def test_fresh_run_uses_owner_workspace_without_rebinding_any_runner(self):
        with TemporaryDirectory() as directory:
            root, source, namespace = self.make_source(directory)
            old = namespace['CACHE']
            (old/'checks.json').write_text('{"accepted":true}')
            helper = types.ModuleType('helper'); helper.CACHE = old
            namespace['helper'] = helper
            with study_execution(self.owner(root),projection={'step':'model','output':'projection'}) as first:
                self.assertEqual(old, namespace['CACHE'])
                self.assertEqual(old, helper.CACHE)
                self.assertNotEqual(old,study_workspace('CACHE'))
                self.assertFalse((study_workspace('CACHE')/'checks.json').exists())
                write_text(study_workspace('OUT')/'result.json', '{}')
            with study_execution(self.owner(root),projection={'step':'model','output':'projection'}) as second:
                self.assertNotEqual(first['run'], second['run'])
                self.assertFalse((study_workspace('OUT')/'result.json').exists())
            self.assertEqual(old, helper.CACHE)
            receipt = self.execution_record(first)
            self.assertEqual('completed', receipt['state'])
            self.assertFalse(receipt['evidenceAccepted'])
            self.assertFalse(receipt['runtimeAdmitted'])

    def test_missing_dependency_is_unavailable_with_failure_status(self):
        with TemporaryDirectory() as directory:
            root, source, namespace = self.make_source(directory)
            with self.assertRaises(EvidenceUnavailable):
                with study_execution(self.owner(root),projection={'step':'model','output':'projection'}) as execution:
                    (study_workspace('CACHE')/'parent-proof.json').read_text()
            receipt = self.execution_record(execution)
            self.assertEqual('unavailable', receipt['state'])
            self.assertFalse(receipt['evidenceAccepted'])

    def test_source_updates_are_previews_and_require_equal_existing_bytes(self):
        with TemporaryDirectory() as directory:
            root, source, namespace = self.make_source(directory)
            view = root/'dev/modeling/example.org'
            view.write_text('unchanged\n')
            with study_execution(self.owner(root),projection={'step':'model','output':'projection'}) as execution:
                write_text(view, 'unchanged\n')
                self.assertEqual('unchanged\n', view.read_text())
                with self.assertRaises(SourceViewDrift):
                    write_text(view, 'different\n')
                self.assertEqual('unchanged\n', view.read_text())
                self.assertEqual('different\n', (execution['run']/'previews/dev/modeling/example.org').read_text())

    def test_scope_rejects_raw_source_other_run_and_unknown_native_targets(self):
        with TemporaryDirectory() as directory:
            root, source, namespace = self.make_source(directory)
            with study_execution(self.owner(root),projection={'step':'model','output':'projection'}) as execution:
                for path in [source, root/'.cache/tasks/other/result.json',
                             root/'.cache/research/legacy-evidence/old.json']:
                    with self.subTest(path=path), self.assertRaises(StoragePolicyError):
                        path.write_text('bad')
                with self.assertRaises(StoragePolicyError):
                    source.unlink()
                with self.assertRaises(StoragePolicyError):
                    source.rename(study_workspace('CACHE')/'moved-source.py')
                with self.assertRaises(StoragePolicyError):
                    os.link(source, study_workspace('CACHE')/'aliased-source.py')
                with self.assertRaises(StoragePolicyError):
                    check_command(execution, ['d2', 'input.d2', 'dev/output.svg'])
                with self.assertRaises(StoragePolicyError):
                    check_command(execution, ['gsc', 'input.scm'])
                with self.assertRaises(StoragePolicyError):
                    check_command(execution, ['git', 'checkout', '--', 'dev/file.org'])
                with self.assertRaises(StoragePolicyError):
                    check_command(execution, ['rg', '--pre=sh', 'pattern'])
                check_command(execution, ['git', '--no-optional-locks', '-C', root, 'rev-parse', 'HEAD'])
                check_command(execution, ['quint', 'typecheck', 'model.qnt', '--out', study_workspace('CACHE')/'ir.json'])

    def test_legacy_archive_write_is_rejected_outside_study_too(self):
        with TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            with self.assertRaises(StoragePolicyError):
                validate(root, root/'.cache/research/legacy-evidence/old.json')


if __name__ == '__main__':
    unittest.main()
