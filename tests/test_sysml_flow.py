"""SDK flow schema controls; no runtime/native acceptance is inferred."""
import copy
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

from gambit_smp.sysml_flow import api_flow, drive_flow, flow_facts, validate_flow, formal_plan


class FlowFixture(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.documents = [('m.sysml', 'model source'), ('policy.sysml', 'policy source')]
        for name, text in self.documents:
            (self.root/name).write_text(text)
        self.metadata = dict(projectionKind='flow-contract', designId='design',
            verificationPolicy='Policy', readinessQuestion='native',
            nativeAdmitted=False, progressDelta=0)
        self.values = {'M': self.metadata}
        self.symbols, self.evaluations = {}, {}
        self.parts = []
        self.roles = []
        self.make('M', self.metadata, parts=self.parts)
        self.make('Policy', {}, parts=self.roles)
        for name, domains in [('quint','control'),('lean','data'),('source','refinement'),('native','native')]:
            self.add('Policy', name, 'Responsibility', dict(id=name, domains=domains), self.roles)
        self.add('M', 'ctx', 'Component', dict(id='ctx', label='execution'))
        self.add('M', 'gc', 'Component', dict(id='gc', label='collector'))
        self.add('M', 'cut', 'Question', self.question('CUT', 'quint', 'control'))
        self.add('M', 'native', 'Question', self.question('EXEC', 'native', 'native'))
        self.add('M', 'inherited', 'ImportedNeed', dict(id='EXT', authority='Other::source',
            artifact='external.sysml', premise='source proof remains open', boundary='OPEN'))
        self.edge('dep', 'Dependency', dependent='EXEC', prerequisite='CUT')
        self.edge('extdep', 'ExternalDependency', dependent='EXEC', prerequisite='EXT')
        self.edge('publish', 'Flow', contract='root publication', producer='ctx', consumer='gc')
        self.edge('resume', 'Flow', contract='root reload', producer='gc', consumer='ctx')
        self.add('M','org','View',dict(kind='org',path='dev/design.org',anchor='flow'))
        self.add('M','d2','View',dict(kind='d2',path='dev/design.d2',anchor=''))
        self.edge('usecut', 'Use', component='ctx', question='CUT')
        self.edge('usenative', 'Use', component='gc', question='EXEC')
        for name in ('CUT.qnt','EXEC.qnt','external.sysml'):
            (self.root/name).write_text('subject '+name)
        self.model = SimpleNamespace(hash='native-model-hash', diagnostics=[],
            find=lambda name:self.symbols.get(name),
            instantiate=lambda name:self.values[name],
            eval=lambda name:self.evaluations[name] if name in self.evaluations else self.values[name.rsplit('.',1)[0]][name.rsplit('.',1)[1]], raise_for_errors=Mock())
        self.connection = SimpleNamespace(parse_sources=Mock(return_value=self.model))

    def question(self, identity, owner, domain):
        return dict(id=identity, semanticKey=domain+'/'+identity, owner=owner,
            domain=domain, artifact=identity+'.qnt', symbols=identity+':scope',
            question='scoped question', boundary='OPEN')

    def make(self, name, values, parts=None, kind='package', resolved=''):
        self.values[name] = values
        attributes = [SimpleNamespace(name=n, kind='attributeUsage') for n in values]
        symbol = SimpleNamespace(id=name, name=name.split('::')[-1], kind=kind,
            type_facts=SimpleNamespace(resolved_id=resolved),
            attributes=lambda:attributes, children=lambda:attributes + ([] if parts is None else parts))
        self.symbols[name] = symbol
        return symbol

    def add(self, parent, name, kind, values, parts=None):
        symbol = self.make(parent+'::'+name, values, kind='partUsage', resolved=parent+'::'+kind)
        (self.parts if parts is None else parts).append(symbol)
        return symbol

    def edge(self, name, kind, **fields):
        attributes={k:v for k,v in fields.items() if k=='contract'}
        symbol=self.add('M', name, kind, attributes)
        self.evaluations.update({symbol.id+'.'+k+'.id':v for k,v in fields.items()if k!='contract'})

    def project(self):
        return api_flow(self.connection, self.documents, 'M')


class SdkFlowTests(FlowFixture):
    def move_to_module(self, namespace='OwnedModule'):
        original = list(self.parts)
        self.parts.clear()
        self.make(namespace, {}, parts=original)
        module = self.add('M', 'ownedModule', 'ModelModule', dict(namespace=namespace))
        return module

    def test_native_package_module_preserves_all_flow_records(self):
        before = self.project()['flow']
        self.move_to_module()
        self.assertEqual(before, self.project()['flow'])

    def test_module_members_are_discovered_without_a_python_catalog(self):
        self.move_to_module()
        self.assertEqual({'ctx', 'gc'},
                         {row['id'] for row in self.project()['flow']['components']})

    def test_missing_module_is_not_an_empty_success(self):
        self.add('M', 'missingModule', 'ModelModule', dict(namespace='Missing'))
        with self.assertRaisesRegex(ValueError, 'resolved native package'):
            self.project()

    def test_module_assembly_cycle_is_refused(self):
        self.add('M', 'cycle', 'ModelModule', dict(namespace='M'))
        with self.assertRaisesRegex(ValueError, 'cyclic flow module'):
            self.project()

    def test_duplicate_module_assembly_is_refused(self):
        self.move_to_module()
        self.add('M', 'duplicateModule', 'ModelModule', dict(namespace='OwnedModule'))
        with self.assertRaisesRegex(ValueError, 'duplicate flow module'):
            self.project()

    def test_module_does_not_hide_an_unknown_record_role(self):
        self.add('M', 'unknown', 'UnknownKind', dict(id='unknown'))
        self.move_to_module()
        with self.assertRaisesRegex(ValueError, 'unhandled flow schema'):
            self.project()

    def test_module_keeps_exclusive_verification_ownership(self):
        self.move_to_module()
        self.values['M::cut']['owner'] = 'lean'
        with self.assertRaisesRegex(ValueError, 'owner/domain'):
            self.project()

    def support_factor(self):
        symbol = self.add('M', 'support', 'SupportFactor', dict(id='SUP',
            owner='quint', domain='control', authority='Existing::history',
            artifact='CUT.qnt', dependencies='external.sysml', scope='CUT:scope',
            boundary='finite support only'))
        self.evaluations[symbol.id+'.component.id'] = 'gc'
        self.evaluations[symbol.id+'.requiredFor.id'] = 'EXEC'
        return symbol

    def test_support_factor_is_discovered_without_issuing_a_receipt(self):
        self.support_factor()
        projection = self.project()
        facts = flow_facts(self.root, projection)
        self.assertEqual('EXEC', facts['shSupport'][0][1])
        self.assertEqual([], facts['shSupportReceipt'])

    def test_support_factor_binds_declared_dependency_bytes(self):
        self.support_factor()
        projection = self.project()
        before = flow_facts(self.root, projection)['shSupport'][0][3]
        (self.root/'external.sysml').write_text('changed premise')
        after = flow_facts(self.root, projection)['shSupport'][0][3]
        self.assertNotEqual(before, after)

    def test_support_factor_cannot_relabel_source_as_data(self):
        symbol = self.support_factor()
        self.values[symbol.id]['owner'] = 'lean'
        with self.assertRaisesRegex(ValueError, 'owner/domain'):
            self.project()

    def test_existing_sdk_path_discovers_members_not_python_lists(self):
        result=self.project()
        self.connection.parse_sources.assert_called_once_with(self.documents,strict=True,strict_conformance=True)
        self.assertEqual(2,len(result['flow']['components']))
        self.assertNotIn('components',result['values'])
        self.assertFalse(result['runtimeAdmitted'])

    def test_new_component_is_discovered_without_an_inventory_change(self):
        self.add('M','vm','Component',dict(id='vm',label='VM'))
        self.edge('usevm','Use',component='vm',question='EXEC')
        self.assertEqual({'ctx','gc','vm'},{x['id']for x in self.project()['flow']['components']})

    def test_runtime_flow_feedback_is_not_a_proof_dependency_cycle(self):
        self.assertEqual(2,len(self.project()['flow']['flows']))

    def test_dangling_reference_is_refused(self):
        self.evaluations['M::publish.consumer.id']='missing'
        with self.assertRaisesRegex(ValueError,'dangling runtime'):self.project()

    def test_proof_dependency_cycle_is_refused(self):
        self.edge('back','Dependency',dependent='CUT',prerequisite='EXEC')
        with self.assertRaisesRegex(ValueError,'cyclic'):self.project()

    def test_renaming_does_not_hide_duplicate_semantic_ownership(self):
        question=self.question('ALIAS','quint','control');question['semanticKey']='control/CUT'
        self.add('M','alias','Question',question)
        with self.assertRaisesRegex(ValueError,'semantic question'):self.project()

    def test_owner_domain_comes_from_model_policy(self):
        self.values['M::cut']['owner']='lean'
        with self.assertRaisesRegex(ValueError,'owner/domain'):self.project()

    def test_unresolved_member_type_is_not_guessed(self):
        self.symbols['M::cut'].type_facts.resolved_id=''
        with self.assertRaisesRegex(ValueError,'resolved local'):self.project()

    def test_unknown_schema_member_is_not_silently_dropped(self):
        self.add('M','hidden','UnknownKind',dict(id='hidden'))
        with self.assertRaisesRegex(ValueError,'unhandled'):self.project()

    def test_unused_component_cannot_hide_an_unbound_scope(self):
        self.add('M','hidden','Component',dict(id='hidden'))
        with self.assertRaisesRegex(ValueError,'explicit typed use'):self.project()

    def test_duplicate_use_is_refused(self):
        self.edge('duplicate','Use',component='ctx',question='CUT')
        with self.assertRaisesRegex(ValueError,'duplicate component'):self.project()

    def test_model_cannot_grant_native_progress(self):
        for field,value in [('nativeAdmitted',True),('progressDelta',1),('progressDelta',False)]:
            with self.subTest(field=field,value=value):
                old=self.metadata[field];self.metadata[field]=value
                with self.assertRaisesRegex(ValueError,'cannot grant'):self.project()
                self.metadata[field]=old

    def test_readiness_must_reference_native_question(self):
        self.metadata['readinessQuestion']='cut'
        with self.assertRaisesRegex(ValueError,'native question'):self.project()

    def test_diagnostics_refuse_projection(self):
        self.model.diagnostics=['unresolved']
        with self.assertRaisesRegex(ValueError,'diagnostic-free'):self.project()


class FlowEvidenceTests(FlowFixture):
    def test_artifact_presence_supplies_no_observations(self):
        facts=flow_facts(self.root,self.project())
        self.assertEqual([],facts['verificationObservation'])
        self.assertEqual([],facts['shExternalReceipt'])
        self.assertEqual([['design']],facts['shDesign'])

    def test_stale_model_source_is_refused(self):
        result=self.project();(self.root/'m.sysml').write_text('changed')
        with self.assertRaisesRegex(ValueError,'source identity'):flow_facts(self.root,result)

    def test_mutated_projection_is_not_a_cached_authority(self):
        result=self.project();result['flow']['components'][0]['label']='changed'
        with self.assertRaisesRegex(ValueError,'changed after'):flow_facts(self.root,result)

    def test_missing_inherited_subject_is_unavailable(self):
        result=self.project();(self.root/'external.sysml').unlink()
        with self.assertRaisesRegex(ValueError,'actual repository subject'):flow_facts(self.root,result)


class FlowPlanTests(FlowFixture):
    def test_only_declared_formal_owners_become_conditional_checks(self):
        plan=formal_plan(self.root,self.project())
        self.assertEqual([('CUT','quint')],[(x['id'],x['checker'])for x in plan['checks']])
        self.assertEqual(['EXEC'],plan['open'])
        self.assertFalse(plan['executionAuthorized'])
        self.assertEqual(['dev/design.org','dev/design.d2'],[x['path']for x in plan['views']])

    def test_model_owned_output_escape_is_refused(self):
        self.values['M::org']['path']='../outside.org'
        with self.assertRaisesRegex(ValueError,'view output'):self.project()

    def test_missing_org_consumer_is_refused(self):
        self.parts.remove(self.symbols['M::org'])
        with self.assertRaisesRegex(ValueError,'Org and D2'):self.project()

    def test_wrong_checker_subject_is_not_dispatched(self):
        self.values['M::cut']['artifact']='external.sysml'
        with self.assertRaisesRegex(ValueError,'subject mismatch'):formal_plan(self.root,self.project())


class OrganizationFixture(FlowFixture):
    def setUp(self):
        super().setUp()
        boundary=dict(label='foundation',authority='existing-owner',unit='whole boundary',
                      entry='source bound',exit='qualified consumers',excluded='scheduler',
                      netBenefit='avoided work versus added work')
        self.add('M','work','Workstream',dict(boundary,id='work'))
        self.add('M','later','Workstream',dict(boundary,id='later'))
        for name,q in [('assignCut','CUT'),('assignExec','EXEC')]:
            self.edge(name,'Assignment',question=q,workstream='work')
        self.edge('workdep','WorkDependency',dependent='later',prerequisite='work')
        self.add('M','axis','ProgressAxis',dict(id='axis',authority='old-epoch',reported='reported only',
            meaning='independent family count',credit='no transfer'))
        site=dict(id='site',artifact='external.sysml',anchor='subject',role='consumer',
                  observed='location only',required='actual adapter',gap='not semantic verification')
        symbol=self.add('M','site','SourceSite',site)
        self.evaluations[symbol.id+'.question.id']='EXEC'


class OrganizationTests(OrganizationFixture):
    def test_typed_organization_is_discovered(self):
        flow=self.project()['flow']
        self.assertEqual(2,len(flow['workstreams']))
        self.assertEqual(2,len(flow['assignments']))
        self.assertEqual('old-epoch',flow['progressAxes'][0]['authority'])

    def test_question_cannot_have_two_primary_owners(self):
        self.edge('again','Assignment',question='EXEC',workstream='later')
        with self.assertRaisesRegex(ValueError,'primary workstream'):self.project()

    def test_delivery_dependency_cycle_is_rejected(self):
        self.edge('back','WorkDependency',dependent='work',prerequisite='later')
        with self.assertRaisesRegex(ValueError,'cyclic workstream'):self.project()

    def test_source_native_question_cannot_lose_its_source(self):
        self.parts.remove(self.symbols['M::site'])
        with self.assertRaisesRegex(ValueError,'actual source locations'):self.project()

    def test_locations_never_supply_semantic_pass(self):
        from gambit_smp.sysml_organization import source_bindings
        result=self.project();sites=source_bindings(self.root,result['flow'])
        self.assertEqual([1],sites[0]['lines'])
        self.assertFalse(sites[0]['semanticVerified'])
        facts=flow_facts(self.root,result)
        self.assertEqual([],facts['verificationObservation'])
        self.assertEqual('located',facts['shSourceSite'][0][-1])

    def test_changed_and_missing_source_remains_an_explicit_gap(self):
        from gambit_smp.sysml_organization import source_bindings
        result=self.project();before=source_bindings(self.root,result['flow'])[0]
        (self.root/'external.sysml').write_text('no longer the same bytes')
        after=source_bindings(self.root,result['flow'])[0]
        self.assertNotEqual(before['sha256'],after['sha256'])
        self.assertEqual('missing',after['status'])
        self.assertFalse(after['semanticVerified'])

    def test_all_conditional_definitions_are_retained(self):
        from gambit_smp.sysml_organization import source_bindings
        (self.root/'external.sysml').write_text('subject first\nsubject fallback\n')
        sites=source_bindings(self.root,self.project()['flow'])
        self.assertEqual([1,2],sites[0]['lines'])

    def test_symlink_cannot_escape_source_scope(self):
        from gambit_smp.sysml_organization import source_bindings
        (self.root/'external.sysml').unlink()
        (self.root/'external.sysml').symlink_to(self.root/'m.sysml')
        with self.assertRaisesRegex(ValueError,'symlinks'):
            source_bindings(self.root,self.project()['flow'])
