"""Source arguments remain conditional and consume existing adapter clauses."""
from gambit_smp.sysml_adapters import adapter_bindings
from tests.test_sysml_adapters import AdapterFixture


class SourceCaseTests(AdapterFixture):
    def setUp(self):
        super().setUp()
        self.add_case('first')
        self.add_case('second')
        self.link('handoff','second','first')

    def add_case(self, name):
        fields=dict(id=name,precondition='source lifetime and stop are known',argument='reviewed guard path',
            conclusion='conditional local conclusion',missing='all-caller proof remains open',
            acceptance='current native acceptance stays separate',formalBoundary='reuse existing owner',
            counterexample='source argument, not an executed native failure')
        self.add('M',name,'SourceCase',fields)
        self.evaluations['M::'+name+'.clause.id']='coverage'
        self.evaluations['M::'+name+'.entrySite.id']='source-site'
        self.evaluations['M::'+name+'.exitSite.id']='source-site'

    def link(self,name,dependent,prerequisite):
        self.add('M',name,'CaseDependency',dict(condition='complete source handoff premise'))
        self.evaluations['M::'+name+'.dependent.id']=dependent
        self.evaluations['M::'+name+'.prerequisite.id']=prerequisite

    def test_cases_use_existing_clause_without_creating_another_obligation(self):
        result=self.project();binding=adapter_bindings(self.root,result)[0]
        self.assertEqual(6,len(binding['clauses']))
        self.assertEqual(2,len(binding['sourceCases']))
        self.assertFalse(binding['semanticVerified'])
        self.assertEqual([],self.policy(result)['shAdapterClosed'])

    def test_missing_existing_clause_is_refused(self):
        self.evaluations['M::first.clause.id']='another-proof-owner'
        with self.assertRaisesRegex(ValueError,'existing adapter clause'):self.project()

    def test_case_endpoints_cannot_claim_an_unrelated_native_site(self):
        self.evaluations['M::first.exitSite.id']='site'
        with self.assertRaisesRegex(ValueError,'endpoints'):self.project()

    def test_source_premise_cycle_is_refused(self):
        self.link('back','first','second')
        with self.assertRaisesRegex(ValueError,'cyclic source'):self.project()

    def test_dangling_handoff_is_refused(self):
        self.evaluations['M::handoff.prerequisite.id']='missing'
        with self.assertRaisesRegex(ValueError,'premise endpoints'):self.project()

    def test_missing_conditional_premise_is_not_a_complete_source_argument(self):
        self.values['M::first']['precondition']=''
        with self.assertRaisesRegex(ValueError,'guarded source'):self.project()

    def test_changed_source_argument_invalidates_old_attestation(self):
        result=self.project();receipts=self.receipts(result)
        self.values['M::first']['argument']='a different root transfer is required'
        current=self.project()
        self.assertNotEqual(adapter_bindings(self.root,result)[0]['subjectSha256'],
                            adapter_bindings(self.root,current)[0]['subjectSha256'])
        self.assertEqual([],self.policy(current,receipts)['shAdapterClosed'])

    def test_handoff_condition_is_bound_to_the_full_subject(self):
        before=adapter_bindings(self.root,self.project())[0]['subjectSha256']
        self.values['M::handoff']['condition']='new physical stop or retained custody premise'
        after=adapter_bindings(self.root,self.project())[0]['subjectSha256']
        self.assertNotEqual(before,after)

    def test_checked_local_clause_does_not_hide_an_open_handoff_premise(self):
        self.evaluations['M::second.clause.id']='exclusion'
        result=self.project();receipts=[row for row in self.receipts(result) if row[0]!='coverage']
        answer=self.policy(result,receipts,names=('shSourceCaseOpen','shAdapterClosed'))
        self.assertIn(['second','handoff-premise-open'],answer['shSourceCaseOpen'])
        self.assertNotIn(['second','source-clause-open'],answer['shSourceCaseOpen'])
        self.assertEqual([],answer['shAdapterClosed'])
