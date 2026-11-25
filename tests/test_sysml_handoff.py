"""Handoff type/ownership checks do not execute a runtime protocol."""
from gambit_smp.sysml_adapters import adapter_bindings
from tests.test_sysml_adapters import AdapterFixture


class HandoffTests(AdapterFixture):
    def setUp(self):
        super().setUp()
        fields=('key','joinRule','scope','valuePolicy','unknownRule','retirement','acceptance','nonGoals')
        self.add('M','protocol','HandoffProtocol',dict(id='protocol',**{k:'required' for k in fields}))
        self.evaluations['M::protocol.adapter.id']='adapter'
        self.add('M','point','HandoffPoint',dict(id='point',caller='actual boundary',precondition='owned source',
            linearization='known commit',missing='OPEN',unknown='retain',acceptance='native independent'))
        for k,v in [('protocol','protocol'),('site','source-site'),('clause','coverage')]:
            self.evaluations['M::point.'+k+'.id']=v
        for kind,purpose in [('install','parent-ack'),('park','access-stopped'),('producer','producer-closed'),
                             ('scan','scan-status'),('observe','observe-origin'),('resume','reload-after-resume'),('retire','retire-storage')]:
            self.add('M','receipt_'+kind,'HandoffReceipt',dict(id=kind,kind=kind,identity='same origin',condition='required',
                outcomes='known / refused / unknown',permits='scoped fact',forbids='other authority',unknown='retain'))
            self.evaluations['M::receipt_'+kind+'.protocol.id']='protocol'
            self.add('M','use_'+kind,'HandoffUse',dict(role='establishes',purpose=purpose,condition='source proof required'))
            self.evaluations['M::use_'+kind+'.point.id']='point'
            self.evaluations['M::use_'+kind+'.receipt.id']=kind

    def test_whole_protocol_is_model_owned_and_never_an_automatic_source_pass(self):
        result=self.project();binding=adapter_bindings(self.root,result)[0]
        self.assertEqual(1,len(binding['protocols']))
        self.assertEqual(7,len(binding['protocols'][0]['receipts']))
        self.assertFalse(binding['protocols'][0]['semanticVerified'])
        self.assertEqual([],self.policy(result)['shAdapterClosed'])

    def test_scan_receipt_cannot_authorize_parent_ack(self):
        self.values['M::use_scan']['purpose']='parent-ack'
        with self.assertRaisesRegex(ValueError,'different handoff decision'):self.project()

    def test_origin_query_cannot_authorize_resume(self):
        self.values['M::use_observe']['purpose']='reload-after-resume'
        with self.assertRaisesRegex(ValueError,'different handoff decision'):self.project()

    def test_resume_receipt_cannot_authorize_retirement(self):
        self.values['M::use_resume']['purpose']='retire-storage'
        with self.assertRaisesRegex(ValueError,'different handoff decision'):self.project()

    def test_missing_receipt_role_refuses_whole_protocol(self):
        self.parts.remove(self.symbols['M::receipt_resume'])
        with self.assertRaisesRegex(ValueError,'distinct receipt roles'):self.project()

    def test_real_boundary_cannot_use_unrelated_native_site(self):
        self.evaluations['M::point.site.id']='site'
        with self.assertRaisesRegex(ValueError,'real owned site'):self.project()

    def test_missing_unknown_custody_is_an_incomplete_boundary(self):
        self.values['M::point']['unknown']=''
        with self.assertRaisesRegex(ValueError,'typed handoff record'):self.project()

    def test_unconnected_receipt_role_is_not_silently_dropped(self):
        self.parts.remove(self.symbols['M::use_install'])
        with self.assertRaisesRegex(ValueError,'unconnected'):self.project()

    def test_changed_ack_condition_invalidates_old_source_attestation(self):
        old=self.project();receipts=self.receipts(old)
        self.values['M::receipt_install']['condition']='a new target protection and ownership condition'
        current=self.project()
        self.assertNotEqual(adapter_bindings(self.root,old)[0]['subjectSha256'],
                            adapter_bindings(self.root,current)[0]['subjectSha256'])
        self.assertEqual([],self.policy(current,receipts)['shAdapterClosed'])

    def test_conditional_use_must_state_its_guard(self):
        self.values['M::use_install']['condition']=''
        with self.assertRaisesRegex(ValueError,'guarded condition'):self.project()
