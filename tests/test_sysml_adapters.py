"""Source-adapter completeness and scoped ASCENT policy, not native acceptance."""
import copy
from pathlib import Path
import unittest

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.sysml_adapters import adapter_bindings
from gambit_smp.sysml_flow import flow_facts
from tests.test_sysml_flow import OrganizationFixture


class AdapterFixture(OrganizationFixture):
    def setUp(self):
        super().setUp()
        question=self.question('SOURCE','source','refinement')
        question['artifact']='external.sysml'
        self.add('M','source','Question',question)
        self.edge('assignSource','Assignment',question='SOURCE',workstream='work')
        self.edge('useSource','Use',component='ctx',question='SOURCE')
        symbol=self.add('M','sourceSite','SourceSite',dict(id='source-site',artifact='external.sysml',
            anchor='subject',role='writer',observed='location',required='source contract',gap='OPEN'))
        self.evaluations[symbol.id+'.question.id']='SOURCE'
        fields=('inputs','precondition','authorization','linearization','postcondition','recovery',
                'retirement','stateModel','dataModel','acceptance','rejection','benefit')
        adapter=self.add('M','adapter','AdapterContract',dict(id='adapter',**{field:'required'for field in fields}))
        self.evaluations[adapter.id+'.question.id']='SOURCE'
        for kind in ('coverage','exclusion','publication','reentry','failure','validation'):
            clause=self.add('M',kind,'AdapterClause',dict(id=kind,kind=kind,rule='rule',missing='OPEN',acceptance='actual scoped evidence'))
            self.evaluations[clause.id+'.adapter.id']='adapter'
            self.evaluations[clause.id+'.site.id']='source-site'

    def policy(self, result, receipts=(), names=('shAdapterClauseChecked','shAdapterClauseOpen','shAdapterClosed','shNativeReady')):
        facts=flow_facts(self.root,result);facts['shAdapterReceipt']=list(receipts)
        root=Path(__file__).resolve().parents[1]
        catalog=load_catalog(root/'dev/modeling/ascent/obligation-ownership.rules.scm',
                             root/'dev/modeling/ascent/shared-heap-smp.rules.scm')
        catalog['sourceTexts']=['(ascent-fragment\n'+source+'\n)' for source in catalog['sourceTexts']]
        return {key:[list(row)for row in rows]for key,rows in query(facts,catalog,{name:name for name in names}).items()}

    def receipts(self, result, method='source-refinement'):
        binding=adapter_bindings(self.root,result)[0]
        return [[row['id'],binding['subjectSha256'],method,'pass']for row in binding['clauses']]


class AdapterTests(AdapterFixture):
    def test_discovery_preserves_whole_contract_without_automatic_closure(self):
        result=self.project();binding=adapter_bindings(self.root,result)[0]
        self.assertEqual(6,len(binding['clauses']))
        self.assertFalse(binding['semanticVerified'])
        answer=self.policy(result)
        self.assertEqual(6,len(answer['shAdapterClauseOpen']))
        self.assertEqual([],answer['shAdapterClosed'])

    def test_partial_clause_set_is_not_a_whole_adapter(self):
        self.parts.remove(self.symbols['M::failure'])
        with self.assertRaisesRegex(ValueError,'whole adapter needs'):self.project()

    def test_source_contract_cannot_be_assigned_to_native_owner(self):
        self.evaluations['M::adapter.question.id']='EXEC'
        with self.assertRaisesRegex(ValueError,'source-owned'):self.project()

    def test_clause_cannot_borrow_an_unrelated_site(self):
        self.evaluations['M::coverage.site.id']='site'
        with self.assertRaisesRegex(ValueError,'own actual source'):self.project()

    def test_secondary_source_changes_the_complete_attestation_subject(self):
        second=self.add('M','secondary','SourceSite',dict(id='secondary',artifact='secondary.c',anchor='store',
            role='raw-writer',observed='location',required='same contract',gap='OPEN'))
        self.evaluations[second.id+'.question.id']='SOURCE'
        (self.root/'secondary.c').write_text('store old;')
        result=self.project();before=adapter_bindings(self.root,result)[0]['subjectSha256']
        (self.root/'secondary.c').write_text('store new;')
        after=adapter_bindings(self.root,result)[0]['subjectSha256']
        self.assertNotEqual(before,after)

    def test_synthetic_source_attestations_do_not_grant_native_acceptance(self):
        result=self.project();answer=self.policy(result,self.receipts(result))
        self.assertEqual([['adapter']],answer['shAdapterClosed'])
        self.assertEqual([],answer['shNativeReady'])

    def test_stale_or_wrong_kind_receipts_cannot_close_adapter(self):
        result=self.project();old=self.receipts(result)
        (self.root/'external.sysml').write_text('subject changed')
        self.assertEqual([],self.policy(result,old)['shAdapterClosed'])
        self.assertEqual([],self.policy(result,self.receipts(result,'lean'))['shAdapterClosed'])

    def test_one_missing_clause_receipt_retains_whole_adapter(self):
        result=self.project();answer=self.policy(result,self.receipts(result)[:-1])
        self.assertEqual([],answer['shAdapterClosed'])
        self.assertEqual(1,len(answer['shAdapterClauseOpen']))

    def test_even_fresh_assumed_receipts_cannot_admit_missing_source_anchor(self):
        (self.root/'external.sysml').write_text('anchor removed')
        result=self.project();answer=self.policy(result,self.receipts(result))
        self.assertEqual([],answer['shAdapterClosed'])
