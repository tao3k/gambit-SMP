"""C verifier observations retain scope, failures and branch identity."""
import json
from pathlib import Path
import unittest

from gambit_smp.cbmc_capabilities import project, report, validate, solver_arguments, reachability
from gambit_smp.evidence_capabilities import facts
from gambit_smp.recipes import load
from gambit_smp.research_kernel import validate_graph

ROOT = Path(__file__).resolve().parents[1]


class CbmcContractTests(unittest.TestCase):
    def output(self, statuses, final='success'):
        return json.dumps([{'result': [dict(property='p'+str(i), status=s,
                           **({'trace':[{'stepType':'failure'}]} if s=='FAILURE' else {}))
                           for i,s in enumerate(statuses)]}, {'cProverStatus':final}])

    def test_success_requires_nonempty_complete_matching_property_report(self):
        self.assertEqual(report(self.output(['SUCCESS']),0,False)['verdict'],'VERIFIED')
        for raw,code in [(self.output([]),0),(self.output(['UNKNOWN']),0),
                         (self.output(['FAILURE']),0),(self.output(['SUCCESS']),10),
                         ('[]',0),('not-json',0)]:
            with self.subTest(raw=raw,code=code):
                self.assertEqual(report(raw,code,False)['verdict'],'INCONCLUSIVE')

    def test_counterexample_and_timeout_never_become_proof_success(self):
        self.assertEqual(report(self.output(['FAILURE'],'failure'),10,False)['verdict'],'COUNTEREXAMPLE')
        self.assertEqual(report(self.output(['SUCCESS']),0,True)['verdict'],'INCONCLUSIVE')

    def test_duplicate_properties_are_not_a_complete_inventory(self):
        raw=json.dumps([{'result':[dict(property='p',status='SUCCESS')]*2},
                        {'cProverStatus':'success'}])
        self.assertEqual(report(raw,0,False)['verdict'],'INCONCLUSIVE')

    def test_reachability_is_not_a_source_repair_and_requires_other_checks(self):
        witness=dict(property='goal',description='witness.first-failure',status='FAILURE',
                     trace=[{'stepType':'failure'}])
        normal=dict(property='bounds',status='SUCCESS')
        d=reachability(dict(verdict='COUNTEREXAMPLE',properties=[witness,normal]),
                       ['witness.first-failure'])
        self.assertEqual(d['verdict'],'REACHABILITY')
        self.assertEqual(d['witnesses'][0]['status'],'REACHED')
        for status in ('FAILURE','UNKNOWN'):
            d=reachability(dict(verdict='INCONCLUSIVE',properties=[witness,{**normal,'status':status}]),
                           ['witness.first-failure'])
            self.assertEqual(d['witnesses'][0]['status'],'UNQUALIFIED_TRACE')

    def test_unknown_properties_preserve_failure_diagnostics_without_proof(self):
        actual=report(self.output(['SUCCESS','FAILURE','UNKNOWN'],'failure'),10,False)
        self.assertEqual(actual['verdict'],'INCONCLUSIVE')
        self.assertEqual(actual['failedProperties'],['p1'])
        self.assertEqual(actual['unresolvedProperties'],['p2'])
        self.assertEqual(actual['properties'][1]['trace'],[{'stepType':'failure'}])

    def test_unwinding_limit_and_missing_trace_are_not_source_counterexamples(self):
        raw=json.dumps([{'result':[dict(property='f.unwind.0',status='FAILURE')]},
                        {'cProverStatus':'failure'}])
        self.assertEqual(report(raw,10,False)['verdict'],'INCONCLUSIVE')

    def test_missing_callee_cannot_be_promoted_to_a_source_repair(self):
        raw=json.dumps([{'result':[dict(property='f.no-body.helper',status='FAILURE'),
                                  dict(property='f.assertion.1',status='FAILURE')]},
                        {'cProverStatus':'failure'}])
        actual=report(raw,10,False)
        self.assertEqual(actual['verdict'],'INCONCLUSIVE')
        self.assertEqual(actual['reason'],'missing C callee implementation')
        raw=raw.replace('f.unwind.0','f.assertion.0')
        self.assertEqual(report(raw,10,False)['verdict'],'INCONCLUSIVE')

    def test_projection_preserves_source_bytes_and_refuses_ambiguous_cuts(self):
        cut=dict(begin='int f',end='int g')
        text='/* source */\nint f(void) { return 3; }\nint g(void);'
        selected,first,last=project(text,cut)
        self.assertEqual(selected,text[first:last])
        self.assertEqual(selected,'int f(void) { return 3; }\n')
        for bad in [text+'int f',text.replace('int g','gone'),text[::-1]]:
            with self.subTest(bad=bad),self.assertRaises(ValueError):project(bad,cut)

    def test_harness_cannot_claim_a_different_contract_or_branch(self):
        recipe,_=load(ROOT,ROOT/'evidence/fixtures/dev-cbmc-copy-plan/check.recipe.json')
        a=recipe['steps'][0]['arguments']
        validate(a,recipe['inputs'])
        with self.assertRaisesRegex(ValueError,'belong'):
            validate({**a,'branch':'other-branch'},recipe['inputs'])

    def test_solver_and_path_choices_are_explicit_without_disabling_checks(self):
        recipe,_=load(ROOT,ROOT/'evidence/fixtures/dev-cbmc-copy-plan/check.recipe.json')
        a=recipe['steps'][0]['arguments']
        validate({**a,'paths':'lifo','solver':'z3','requires':['geometry-proof']},recipe['inputs'])
        for changed in [dict(paths='discard-paths'),dict(solver='arbitrary-command'),
                        dict(options=['--no-pointer-check'])]:
            with self.subTest(changed=changed),self.assertRaises(ValueError):
                validate({**a,**changed},recipe['inputs'])

    def test_cbmc_owns_smt_arguments_not_a_shell_command(self):
        path='/checked path/z3'
        self.assertEqual(solver_arguments('z3',path),['--z3','--external-smt2-solver',path])
        self.assertEqual(solver_arguments('sat'),[])
        with self.assertRaises(ValueError):solver_arguments('z3')

    def test_aggregate_and_independent_branches_use_same_inputs_and_obligations(self):
        recipe,steps=load(ROOT,ROOT/'evidence/fixtures/dev-cbmc-copy-plan/check.recipe.json')
        validate_graph(recipe,steps)
        identities=[]
        for step in steps[:-1]:
            p=ROOT/step['arguments']['harness']
            single,ss=load(ROOT,p.with_name('check.recipe.json'))
            validate_graph(single,ss)
            self.assertEqual(next(s for s in ss if s['id']==step['id']),step)
            for cut in step['arguments']['projections']:
                data=(ROOT/cut['source']).read_bytes().decode('utf-8')
                selected,first,last=project(data,cut)
                self.assertEqual(selected.encode(),data[first:last].encode())
            identities.append((step['arguments']['contract'],step['arguments']['branch']))
        self.assertEqual(len(identities),len(set(identities)))
        self.assertEqual(len(identities),8)

    def test_transaction_requires_the_real_geometry_producer_without_budget_growth(self):
        from gambit_smp.recipes import CAPABILITIES
        path=ROOT/'tests/contracts/allocation-grant/section-growth/partial-failure/check.recipe.json'
        recipe,steps=load(ROOT,path)
        by={s['id']:s for s in steps}
        self.assertEqual(recipe['budgetSeconds'],90)
        self.assertEqual(sum(s['budgetSeconds'] for s in steps if s['capability']=='c.cbmc'),60)
        self.assertEqual(by['resize']['arguments']['requires'],['geometry'])
        CAPABILITIES['c.cbmc'].graph(by['resize'],by,CAPABILITIES)
        with self.assertRaisesRegex(ValueError,'producer dependency'):
            CAPABILITIES['c.cbmc'].graph({**by['resize'],'dependsOn':[]},by,CAPABILITIES)

    def test_transaction_still_contains_actual_vendor_algorithm_and_full_extent(self):
        storage=(ROOT/'tests/contracts/allocation-grant/support/section-storage.h').read_text()
        self.assertIn('sizeof(contract_section_storage)==SECTION_BYTES',storage)
        harness=(ROOT/'tests/contracts/allocation-grant/support/growth-fixture.h').read_text()
        self.assertIn('#include "resize.inc"',harness)
        self.assertIn('__CPROVER_allocate(sizeof(contract_section_storage),0)',harness)
        self.assertNotIn('void adjust_msections',harness)

    def test_outcome_witnesses_keep_safety_checks_and_original_combined_budget(self):
        recipe,steps=load(ROOT,ROOT/'evidence/fixtures/dev-cbmc-copy-plan/reachability.recipe.json')
        validate_graph(recipe,steps)
        self.assertEqual(sum(s['budgetSeconds'] for s in steps if s['capability']=='c.cbmc'),60)
        self.assertEqual(len(steps),6)
        for step in steps[1:-1]:
            args=step['arguments']
            self.assertEqual(args['requires'],['geometry'])
            self.assertEqual(len(args['witnesses']),1)
            self.assertIn(args['witnesses'][0],args['assertions'])
            text=(ROOT/args['harness']).read_text()
            self.assertIn('#include "tests/contracts/allocation-grant/support/growth-fixture.h"',text)
            self.assertNotIn('adjust_msections(',text)
            self.assertNotIn('__CPROVER_assume',text)

    def test_ascent_distinguishes_observation_pass_from_solver_verdict(self):
        data=dict(contract='allocation-grant/copy-capacity',branch='byte-budget',
                  verdict='COUNTEREXAMPLE',scope='bounded',properties=[
                  dict(property='p',status='FAILURE',description='budget',
                       sourceLocation=dict(file='copy-planning.inc',line='323'))],
                  inputDigests={'source':'abc'},assumptions=['LP64'])
        rows=facts({'steps':[dict(id='capacity',capability='c.cbmc',dependsOn=[],
                    arguments={},outcome='PASS',cVerification=data)]})
        self.assertEqual(rows['c_verdict'],[['capacity','allocation-grant/copy-capacity',
                         'byte-budget','COUNTEREXAMPLE','bounded']])
        self.assertEqual(rows['c_property'][0][2],'FAILURE')


if __name__=='__main__':unittest.main()
