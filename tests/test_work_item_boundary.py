"""Work-item scope admission; these tests never qualify a compiler or package."""
import copy
import json
import tempfile
import time
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from gambit_smp import work_items as w
from gambit_smp.recipes import ExecutionContext


class WorkItemBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root/'docs').mkdir()
        self.contract = {'model': 'boundary.sysml', 'part': 'Owner::boundary'}
        (self.root/'docs/work-items.json').write_text(json.dumps({
            'schema': 'gambit-work-items.v1', 'items': {
                'darwin': {'scope': 'darwin-only', 'executionBoundary': self.contract,
                           'processes': {'audit': 'maintenance'}},
                'modern-c': {'scope': 'runtime', 'processes': {'audit': 'maintenance'}}}}))
        self.steps = [
            dict(id='model', component='boundary', capability='sysml.project', dependsOn=[],
                 arguments={'models': ['boundary.sysml'], 'part': 'Owner::boundary'}),
            dict(id='scope', component='boundary', capability='research.audit', dependsOn=['model'],
                 arguments={'projection': {'step': 'model', 'output': 'projection'}, 'boundary': True}),
            dict(id='build', component='pipeline', capability='gerbil.build', dependsOn=['scope'], arguments={})]
        self.recipe = {'inputs': ['docs/work-items.json', 'boundary.sysml', 'evidence/dsl/work-item-boundary.ss',
                                  'tests/recipes/framework-contracts/work-item-boundary-entry.json']}
        self.policy = dict(taskId='darwin', scopeId='darwin-only', ownedComponents='pipeline',
                           externalOwners='gc=modern-c;smp=modern-c',
                           allowedCapabilities='gerbil.build;source.contract',
                           readOnlyCapabilities='source.contract', mutableSourcePaths='gsc/*.scm',
                           baselineRevision='a'*40, modelOwners='dev/architecture/toolchain/models/=pipeline;dev/refactoring/modern-c/=gc')

    def test_inline_python_and_shell_refused_before_spawn(self):
        from gambit_smp import workspace
        for argv in [['python3', '-c', 'raise SystemExit(0)'], ['/bin/sh', '-c', 'true'],
                     ['/usr/bin/env', 'python3', '-c', 'pass']]:
            with self.subTest(argv=argv), patch('gambit_smp.spawn_protocol.launch') as launch:
                with self.assertRaisesRegex(ValueError, 'declarative research CLI'):
                    workspace.execute(self.root, 'darwin', argv)
                launch.assert_not_called()

    def test_other_work_item_does_not_inherit_darwin_restrictions(self):
        w.admit_command(self.root, 'modern-c', ['python3', '-c', 'pass'])

    def test_legacy_adapter_and_automatic_task_switch_refused(self):
        for command in ['suite','bootstrap','gc-wait-schedule','recipes','debug']:
            with self.subTest(command=command), self.assertRaisesRegex(ValueError,'legacy adapters'):
                w.admit_adapter(self.root,'darwin',command)
        w.admit_adapter(self.root,'darwin','research')
        with patch.dict('os.environ',{'GAMBIT_SMP_TASK_ID':'darwin'}):
            with self.assertRaisesRegex(ValueError,'inherited work-item owner'):
                w.admit_adapter(self.root,'modern-c','research')
            ctx=self.context();ctx.env['GAMBIT_SMP_TASK_ID']='modern-c'
            with self.assertRaisesRegex(ValueError,'inherited work-item owner'):
                w.require_boundary_context(ctx)

    def test_scope_gate_dominates_all_actions(self):
        result = w.check_recipe_boundary(self.root, self.recipe, self.steps, task='darwin')
        self.assertEqual('scope', result['gate'])
        self.steps[2]['dependsOn'] = ['model']
        with self.assertRaisesRegex(ValueError, 'dominate'):
            w.check_recipe_boundary(self.root, self.recipe, self.steps, task='darwin')

    def test_missing_gate_component_and_wrong_model_refused(self):
        variants = []
        steps = copy.deepcopy(self.steps); steps[1]['arguments'].pop('boundary'); variants.append(steps)
        steps = copy.deepcopy(self.steps); steps[2].pop('component'); variants.append(steps)
        steps = copy.deepcopy(self.steps); steps[0]['arguments']['part']='Other::scope'; variants.append(steps)
        for steps in variants:
            with self.subTest(steps=steps), self.assertRaises(ValueError):
                w.check_recipe_boundary(self.root, self.recipe, steps, task='darwin')

    def test_ad_hoc_execution_context_cannot_spawn(self):
        out = self.root/'out'; out.mkdir()
        ctx = ExecutionContext(self.root, out, out, {'GAMBIT_SMP_TASK_ID':'darwin'},
                               time.monotonic()+10, {}, {}, {})
        self.addCleanup(ctx.workspace_leases.close)
        with patch('gambit_smp.spawn_protocol.launch') as launch:
            with self.assertRaisesRegex(ValueError, 'unstructured ExecutionContext'):
                ctx.run('gc-experiment', ['true'], self.root, 5)
            launch.assert_not_called()
        self.assertFalse(list(out.iterdir()))

    def context(self):
        projection = self.root/'projection.json'
        projection.write_text(json.dumps({'values':self.policy}))
        gate = self.root/'gate.json'
        gate.write_text(json.dumps({'task':'darwin','scopeAdmitted':True,'policy':self.policy}))
        out = self.root/'result'; out.mkdir(exist_ok=True)
        return SimpleNamespace(root=self.root, directory=out,
            env={'GAMBIT_SMP_TASK_ID':'darwin'},
            receipt={'workItemBoundary':{'task':'darwin','gate':'scope','projection':'model',
                'registrationSha256':__import__('hashlib').sha256((self.root/'docs/work-items.json').read_bytes()).hexdigest()}},
            planned_steps=self.steps, outcomes={'scope':'PASS'}, tools={'git':'/usr/bin/git'},
            artifact=lambda ref, kind: projection if ref['step']=='model' else gate,
            publish=lambda name,kind,path:{name:{'type':kind,'path':str(path)}})

    def test_missing_or_foreign_scope_receipt_refused(self):
        ctx=self.context(); ctx.outcomes={}
        with self.assertRaisesRegex(ValueError, 'missing or denied'):w.require_boundary_context(ctx)
        ctx.outcomes={'scope':'PASS'}; ctx.receipt['workItemBoundary']['task']='modern-c'
        with self.assertRaisesRegex(ValueError, 'another task'):w.require_boundary_context(ctx)

    def test_registration_cannot_change_after_gate(self):
        ctx=self.context()
        plan=self.root/'docs/work-items.json'; value=json.loads(plan.read_text())
        value['items']['darwin']['scope']='changed';plan.write_text(json.dumps(value))
        with self.assertRaisesRegex(ValueError,'registration changed'):
            w.require_boundary_context(ctx)

    def test_sealed_environment_can_use_inherited_task_owner(self):
        ctx=self.context();ctx.env={}
        with patch.dict('os.environ',{'GAMBIT_SMP_TASK_ID':'darwin'}):
            self.assertEqual(self.policy,w.require_boundary_context(ctx))

    def test_native_source_delta_rejects_gc_and_thread_changes(self):
        ctx=self.context()
        for paths in ['lib/mem.c\0', 'lib/_thread.scm\0', 'include/gambit.h.in\0']:
            ctx.require=lambda stage,*args: paths if stage=='scope-source-delta' else ''
            with self.subTest(paths=paths), self.assertRaisesRegex(ValueError,'unowned source'):
                w.admit_source_delta(ctx,self.root)
        ctx.require=lambda stage,*args:'gsc/_t-c-1.scm\0' if stage=='scope-source-delta' else ''
        w.admit_source_delta(ctx,self.root)
        ctx.require=lambda stage,*args:'lib/new-gc.c\0' if stage=='scope-source-untracked' else ''
        with self.assertRaisesRegex(ValueError,'unowned source'):w.admit_source_delta(ctx,self.root)

    def test_exact_dependency_receipt_cannot_admit_an_extra_runtime_edit(self):
        import hashlib
        path=self.root/'lib/mem.c';path.parent.mkdir();path.write_text('specific source repair\n')
        expected=hashlib.sha256(path.read_bytes()).hexdigest()
        self.policy['sourceDeltaReceipts']='lib/mem.c='+'b'*40+':'+expected
        ctx=self.context();ctx.bind=lambda paths:None
        ctx.require=lambda stage,*args: ('lib/mem.c\0' if stage=='scope-source-delta' else
            'b'*40 if stage.startswith('scope-source-blob-') else '')
        w.admit_source_delta(ctx,self.root)
        path.write_text('specific source repair\nunrelated GC rewrite\n')
        with self.assertRaisesRegex(ValueError,'exact repair'):
            w.admit_source_delta(ctx,self.root)
        path.write_text('specific source repair\n')
        ctx.require=lambda stage,*args: ('lib/mem.c\0' if stage=='scope-source-delta' else
            'c'*40 if stage.startswith('scope-source-blob-') else '')
        with self.assertRaisesRegex(ValueError,'exact repair'):
            w.admit_source_delta(ctx,self.root)

    def test_ascent_denial_is_not_relabelled_pass(self):
        ctx=self.context()
        # Transport check only: real DSL evaluation is an independent integration check.
        with patch('gambit_smp.evidence_capabilities.evaluate_observations',
                   return_value={'Denied':[['build']], 'Permitted':[]}):
            with self.assertRaisesRegex(ValueError,'ASCENT denied'):
                w.evaluate_boundary({'projection':{'step':'model','output':'projection'}},ctx)
        self.assertFalse((ctx.directory/'observation.json').exists())

    def test_missing_ascent_provider_is_not_a_permission(self):
        ctx=self.context()
        with patch('gambit_smp.evidence_capabilities.evaluate_observations',
                   side_effect=FileNotFoundError('sealed provider absent')):
            with self.assertRaises(FileNotFoundError):
                w.evaluate_boundary({'projection':{'step':'model','output':'projection'}},ctx)
        self.assertFalse((ctx.directory/'observation.json').exists())

    def test_exact_complete_decision_publishes_scope_only(self):
        ctx=self.context()
        with patch('gambit_smp.evidence_capabilities.evaluate_observations',
                   return_value={'Denied':[], 'Permitted':[['build']]}):
            w.evaluate_boundary({'projection':{'step':'model','output':'projection'}},ctx)
        result=json.loads((ctx.directory/'observation.json').read_text())
        self.assertTrue(result['scopeAdmitted']); self.assertFalse(result['runtimeAdmitted'])
        self.assertIn(['darwin','gc'],result['facts']['scope_blocked_by'])

    def test_actual_source_mapping_rejects_a_mislabelled_gc_proof(self):
        from gambit_smp.ascent_program import load_evidence_catalog, query
        root=Path(__file__).resolve().parents[1]
        catalog=load_evidence_catalog(root/'evidence/dsl/work-item-boundary.ss',
            constructor='make-work-item-boundary',trusted=True)
        ctx=self.context();ctx.planned_steps[-1].update(capability='lean.check',
            arguments={'argv':['dev/refactoring/modern-c/models/lean/CollectorCapacity.lean']})
        def native_transport(context,rules,facts,queries,label,**kwargs):
            return json.loads(json.dumps(query(facts,catalog,queries)))
        with patch('gambit_smp.evidence_capabilities.evaluate_observations',side_effect=native_transport):
            with self.assertRaisesRegex(ValueError,'ASCENT denied'):
                w.evaluate_boundary({'projection':{'step':'model','output':'projection'}},ctx)


class NativeBoundaryDslTests(unittest.TestCase):
    def test_actual_ascent_dependency_does_not_confer_ownership(self):
        from gambit_smp.ascent_program import load_evidence_catalog, query
        root=Path(__file__).resolve().parents[1]
        catalog=load_evidence_catalog(root/'evidence/dsl/work-item-boundary.ss',
            constructor='make-work-item-boundary',trusted=True)
        facts={'scope_owner':[['pipeline','darwin'],['gc','modern-c'],['smp','modern-c']],
               'scope_allow':[['darwin','gerbil.build'],['darwin','native.test'],['darwin','lean.check']],
               'scope_read':[['darwin','source.contract']],
               'scope_blocked_by':[['darwin','gc'],['darwin','smp']],
               'scope_subject':[['build','pipeline'],['read-gc','gc'],['gc-native','gc'],['gc-proof','gc'],['smp-native','smp'],['unknown','unknown'],['undeclared-cap','pipeline'],['mislabelled-proof','gc']],
               'scope_action':[['build','darwin','pipeline','gerbil.build'],
                   ['read-gc','darwin','gc','source.contract'],
                   ['gc-native','darwin','gc','native.test'],
                   ['gc-proof','darwin','gc','lean.check'],
                   ['smp-native','darwin','smp','native.test'],
                   ['unknown','darwin','unknown','gerbil.build'],
                   ['undeclared-cap','darwin','pipeline','arbitrary.command'],
                   ['mislabelled-proof','darwin','pipeline','lean.check']]}
        actual=query(facts,catalog,{'Permitted':'scope_permitted','Denied':'scope_denied',
                                    'Dependency':'scope_dependency'})
        self.assertEqual([('build',),('read-gc',)],sorted(actual['Permitted']))
        self.assertEqual([('gc-native',),('gc-proof',),('mislabelled-proof',),('smp-native',),('undeclared-cap',),('unknown',)],
                         sorted(actual['Denied']))
        self.assertEqual([('darwin','modern-c','gc'),('darwin','modern-c','smp')],sorted(actual['Dependency']))


if __name__=='__main__':unittest.main()
