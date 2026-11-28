"""Refine six retained model/evidence gaps; never execute native 9–12."""
from dataclasses import asdict
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import unittest
from gambit_smp.framework import ROOT,digest,execute
from gambit_smp.artifact_storage import runtime_output
from gambit_smp.ascent_program import engine_api,evaluate,load_component_catalog
from gambit_smp.process_observation import capture
from gambit_smp.quint_backend import check,counterexample,summarize
from tests.test_retirement_repair_campaign import prepared_compiler,compiled_control

class MechanismGranularityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.out=runtime_output(ROOT,'.cache/mechanism-granularity-tests')
        cls.out.mkdir(parents=True,exist_ok=False)
        cls.files=[ROOT/'models/gambit'/n for n in ('retirement_repair_campaign.qnt','structure_fault_observation.qnt','native_compiler_probe_correspondence.qnt','retirement_exit_handoff.qnt','callback_return_owned_result.qnt','resize_saved_stack_retirement_isolated.qnt','sync_slot_retained_resources.qnt')]
        cls.files += [ROOT/'models/library/gc/WorkObligations.qnt',ROOT/'models/gambit/lean/RetirementRepairCampaign.lean',ROOT/'models/gambit/lean/lean-toolchain',ROOT/'evidence/dsl/modeling-guidance.ss',ROOT/'tests/test_retirement_repair_campaign.py',Path(__file__)]
        cls.inputs={str(p.relative_to(ROOT)):digest(p) for p in cls.files}
        # A test projection imports the production pure transition, not a
        # second implementation. Idle campaign/protocol state is not copied.
        maintained=(ROOT/'models/gambit/retirement_repair_campaign.qnt').read_text()
        start=maintained.index('module retirement_recovery_model {')
        end=maintained.index('module retirement_recovery_tests {',start)
        component=maintained[start:end]
        cls.projection=cls.out/'mechanism_projection.qnt'
        cls.projection.write_text(component+'module mechanism_projection {\n import retirement_recovery_model.*\n'+'''
 var r: RecoveryState
 var policy: int
 action init = { nondet p = Set(0,1,2,3,4).oneOf()
   all { r' = recoveryInitial, policy' = p } }
 action step = { nondet key = recoveryKeys.oneOf()
   nondet kind = recoveryKinds.oneOf()
   nondet errno = Set(11,35).oneOf()
   all { r' = recoveryPolicy(r,recoveryEvent(key,kind,errno),policy), policy' = policy } }
 action advance = { nondet key = recoveryKeys.oneOf()
   nondet kind = recoveryKinds.oneOf()
   nondet errno = Set(11,35).oneOf()
   val advanced = recoveryPolicy(r,recoveryEvent(key,kind,errno),policy)
   all { recoveryRank(advanced) < recoveryRank(r), r' = advanced, policy' = policy } }
 val mechanismSafe = policy != 0 or recoverySafe(r)
 val mixedIdentitySafe = policy != 1 or recoverySafe(r)
 val bodyReturnSafe = policy != 2 or recoverySafe(r)
 val earlyClearSafe = policy != 3 or recoverySafe(r)
 val earlyReclaimSafe = policy != 4 or recoverySafe(r)
 val noMechanismCompletion = policy != 0 or r.phase != 6
 val noTerminalRetention = policy != 0 or r.phase != 7
 temporal progress = (policy == 0).implies(weakFair(advance,Set((r,policy)))
   .implies(eventually(r.phase == 6 or r.phase == 7)))
}\n''')
        cls.inputs[str(cls.projection.relative_to(ROOT))]=digest(cls.projection)
        cls.config=cls.out/'tlc.json';cls.config.write_text(json.dumps({'workers':1,'maxHeap':'-Xmx1G','stackSize':'-Xss8m'}))
        cls.catalog=load_component_catalog(ROOT/'evidence/dsl/modeling-guidance.components.json',entry='modeling-guidance',constructor='make-modeling-guidance',trusted=True)
        cls.context=engine_api();cls.engine,_=cls.context.__enter__()
        cls.rows=[]
    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None,None,None)
        after={str(p.relative_to(ROOT)):digest(p) for p in cls.files+[cls.projection]}
        (cls.out/'summary.json').write_text(json.dumps(dict(inputs=cls.inputs,sourceWindowUnchanged=after==cls.inputs,checks=cls.rows,nativeAdmitted=False),indent=2)+'\n')
        assert after==cls.inputs,'model/control sources changed during checks'

    def tlc(self,initializer,invariant,negative=False,temporal=None):
        folder=self.out/(initializer+'-'+invariant);folder.mkdir()
        if not negative:
            with prepared_compiler(folder/'compiler',ROOT/'.cache/tools/apalache-0.62.1/lib/apalache.jar'):
                row,log,trace=check(self.projection,initializer='init',invariant=invariant,negative=False,timeout=30,cwd=folder,config=self.config,executable=shutil.which('quint'),step='step',temporal=temporal,liveness_schedule='final',tlc_jar=ROOT/'.cache/tools/apalache-0.62.1/lib/apalache.jar')
                (folder/'checker.log').write_text(log)
                (folder/'receipt.json').write_text(json.dumps(dict(row,trace=trace,inputs=self.inputs,nativeAdmitted=False),indent=2))
            if row['accepted']:
                self.compiled=folder/'mechanism_projection.tla'
                self.compiled_sha=digest(self.compiled)
                self.jar_sha=digest(ROOT/'.cache/tools/apalache-0.62.1/lib/apalache.jar')
        else:
            row,log,trace=compiled_control(self.compiled,folder,invariant,
                ROOT/'.cache/tools/apalache-0.62.1/lib/apalache.jar',expected_sha=self.compiled_sha,
                jar_sha=self.jar_sha,model_sha=digest(self.projection),workers=1)

        (folder/'checker.log').write_text(log);(folder/'receipt.json').write_text(json.dumps(dict(row,trace=trace,inputs=self.inputs,nativeAdmitted=False),indent=2))
        self.rows.append(dict(kind='TLC',initializer='init',invariant=invariant,**row))
        self.assertTrue(row['accepted'],log[-3500:]);self.assertFalse(row['timeout']);return trace

    def test_exhaustive_recovery_order_and_real_countertraces(self):
        self.tlc('conditional-progress','mechanismSafe',temporal='progress')
        for init,inv in [('initMixedIdentity','mixedIdentitySafe'),('initBodyIsReturn','bodyReturnSafe'),('initEarlyClear','earlyClearSafe'),('initEarlyReclaim','earlyReclaimSafe')]:
            with self.subTest(control=init):
                trace=self.tlc(init,inv,True);r=trace['states'][-1]['r']
                if init=='initMixedIdentity':self.assertNotEqual(r['joinKey'],r['errorKey'])
                elif init=='initBodyIsReturn':self.assertTrue(r['consumers']['$integerSet'])
                elif init=='initEarlyClear':self.assertEqual(r['phase'],2);self.assertFalse(r['pending'])
                else:self.assertEqual(r['phase'],6);self.assertTrue(r['consumers']['$integerSet'])
        for inv,phase in [('noMechanismCompletion',6),('noTerminalRetention',7)]:
            trace=self.tlc('initMechanism',inv,True)
            r=trace['states'][-1]['r'];self.assertEqual(r['phase'],phase)
            self.assertEqual(r['pending'],phase==7)

    def test_quint_mechanism_runs(self):
        for name in ('retirement_repair_campaign','structure_fault_observation','native_compiler_probe_correspondence'):
            row=capture([shutil.which('quint'),'test',str(ROOT/'models/gambit'/f'{name}.qnt'),*(['--main','retirement_recovery_tests'] if name=='retirement_repair_campaign' else []),'--match','mechanism.*Test','--max-samples','1'],self.out,30,dict(os.environ))
            (self.out/(name+'-runs.json')).write_text(json.dumps(asdict(row),indent=2));self.assertEqual(row.exit,0,row.stdout+row.stderr);self.assertTrue(row.group_quiescent);self.assertFalse(row.timeout)

    def test_lean_arbitrary_trace_and_negative_contracts(self):
        directory=ROOT/'models/gambit/lean'
        row=capture([shutil.which('lean'),'-j1','-DmaxHeartbeats=200000','-DmaxRecDepth=512','RetirementRepairCampaign.lean'],directory,20,dict(os.environ,ELAN_TOOLCHAIN=(directory/'lean-toolchain').read_text().strip()))
        (self.out/'lean.json').write_text(json.dumps(asdict(row),indent=2));self.assertEqual(row.exit,0,row.stdout+row.stderr);self.assertFalse(row.timeout);self.assertTrue(row.group_quiescent);self.assertNotIn('sorryAx',row.stdout+row.stderr)
        for line in row.stdout.splitlines():
            if 'depends on axioms: [' in line:
                names=line.split('depends on axioms: [',1)[1].rstrip(']').split(',')
                self.assertLessEqual({n.strip() for n in names},{'propext','Quot.sound'})
        for theorem in ('recovery_trace_preserves','recovery_other_worker_ignored','recovery_old_generation_ignored','recovery_other_owner_ignored','unfinished_consumer_blocks_reclaim','clear_before_transfer_ignored','terminal_error_retains','same_identity_recovery_reachable','body_only_cannot_reclaim','failed_read_is_not_zero_witness','compile_zero_without_dump_is_not_phase','equal_numbers_do_not_identify_units'):
            self.assertIn(theorem,row.stdout)

    def facts(self):
        kinds=['close','join-error-pending','join-ok','body-end','handler-return','last-read','observe-quiet','transfer','clear-pending','reclaim']
        key=['run','source','config','vm','worker','generation','owner']
        return dict(source=[['control','model-control.json','h']],mechanism_binding=[['control','h']],mechanism_target=[['r','recovery','control']],recovery_target=[['r',*key]],recovery_key=[[str(i),*key] for i in range(10)],recovery_event=[[str(i),kind,i,11 if i==1 else 0,'control'] for i,kind in enumerate(kinds)],recovery_consumer_event=[['3','handler'],['4','handler'],['5','private']],join_errno_population=[['r',11],['r',35]],required_consumer=[['r','handler','handler-return','control'],['r','private','last-read','control']])
    def infer(self,facts):
        names=['recovery_valid','consumer_missing','mechanism_gap','capture_valid','captured_bad_descriptor','capture_causes','pass_observed','cost_units','incomparable_units','applicable','unclosed']
        complete={n:[] for n in ('mechanism_binding','mechanism_withdrawn','mechanism_target','recovery_target','recovery_key','recovery_event','recovery_consumer_event','join_errno_population','required_consumer','capture_fact','compatible_hypothesis','compiler_sample','compiler_artifact','cost_observation')}
        complete.update(facts)
        return evaluate(self.engine,complete,self.catalog,{n:n for n in names})[0]

    def test_scheme_same_worker_generation_owner_and_errno_population(self):
        facts=self.facts();self.assertEqual(self.infer(facts)['recovery_valid'],[('r','1','2','9')])
        for column in range(1,8):
            altered=copy.deepcopy(facts);altered['recovery_key'][2][column]='foreign'
            self.assertEqual(self.infer(altered)['recovery_valid'],[],column)
        for relation,row_index,column in [('recovery_target',0,5),('recovery_key',2,5),('recovery_event',2,2),('recovery_consumer_event',2,1)]:
            altered=copy.deepcopy(facts);extra=list(altered[relation][row_index]);extra[column]=99 if isinstance(extra[column],int) else 'foreign';altered[relation].append(extra)
            self.assertEqual(self.infer(altered)['recovery_valid'],[],relation)
        alternate=copy.deepcopy(facts);alternate['recovery_event'][1][3]=35
        self.assertTrue(self.infer(alternate)['recovery_valid'])
        invalid=copy.deepcopy(facts);invalid['recovery_event'][1][3]=22;invalid['join_errno_population'].append(['r',22])
        self.assertEqual(self.infer(invalid)['recovery_valid'],[])
        self.assertEqual(self.infer(dict(facts,recovery_event=[r for r in facts['recovery_event'] if r[1]!='join-error-pending']))['recovery_valid'],[])

    def test_scheme_last_consumer_and_reclaim_order_withdrawal(self):
        facts=self.facts()
        for kind in ['close','body-end','handler-return','last-read','observe-quiet','transfer','clear-pending','reclaim']:
            altered=dict(facts,recovery_event=[r for r in facts['recovery_event'] if r[1]!=kind])
            self.assertEqual(self.infer(altered)['recovery_valid'],[],kind)
        for a,b in [(4,3),(7,6),(8,7),(9,8)]:
            altered=copy.deepcopy(facts);altered['recovery_event'][a][2],altered['recovery_event'][b][2]=altered['recovery_event'][b][2],altered['recovery_event'][a][2]
            self.assertEqual(self.infer(altered)['recovery_valid'],[],(a,b))
        another=copy.deepcopy(facts);another['required_consumer'].append(['r','private-second','last-read','control'])
        self.assertEqual(self.infer(another)['recovery_valid'],[])
        collision=copy.deepcopy(facts);collision['required_consumer'].append(['r','handler','last-read','control'])
        self.assertEqual(self.infer(collision)['recovery_valid'],[])
        for kind in ['terminal-error','consumer-enter','reopen']:
            altered=copy.deepcopy(facts);altered['recovery_event'].append(['hazard',kind,7,0,'control']);altered['recovery_key'].append(['hazard',*facts['recovery_key'][0][1:]])
            self.assertEqual(self.infer(altered)['recovery_valid'],[])
        self.assertEqual(self.infer(dict(facts,mechanism_withdrawn=[['control']]))['recovery_valid'],[])
        self.assertEqual(self.infer(dict(facts,source=[['control','model-control.json','changed']]))['recovery_valid'],[])
        self.assertEqual(self.infer(facts)['recovery_valid'],[('r','1','2','9')])

    def test_scheme_capture_is_separate_from_cause_and_pass_is_not_exit(self):
        f=self.facts();f['capture_fact']=[['bad','image','image','owner','owner',1,1,'qualified','read','ok',0,'control']]
        collision=copy.deepcopy(f);collision['capture_fact'].append(['bad','image','image','other','owner',1,1,'qualified','read','ok',0,'control'])
        self.assertEqual(self.infer(collision)['capture_valid'],[])
        f['compatible_hypothesis']=[['bad',str(i),'control'] for i in range(1,5)]
        before=self.infer(f);self.assertEqual(before['captured_bad_descriptor'],[('bad',0)]);self.assertEqual(len(before['capture_causes']),4)
        for column,value in [(2,'wrong-image'),(4,'other-owner'),(6,2),(7,'failed'),(8,'published'),(9,'unreadable')]:
            altered=copy.deepcopy(f);altered['capture_fact'][0][column]=value;self.assertEqual(self.infer(altered)['capture_valid'],[],column)
        f['compiler_sample']=[['gcc',0,False,1,'alias','src','tool',False,'control']]
        f['compiler_artifact']=[['gcc','alias','src','tool','control']]
        self.assertEqual(self.infer(f)['pass_observed'],[('gcc','alias')])
        collision=copy.deepcopy(f);collision['compiler_sample'].append(['gcc',0,False,0,'alias','src','tool',False,'control'])
        self.assertEqual(self.infer(collision)['pass_observed'],[])
        for column,value in [(1,3),(2,True),(3,0),(5,'wrong-src'),(6,'wrong-tool'),(7,True)]:
            altered=copy.deepcopy(f);altered['compiler_sample'][0][column]=value;self.assertEqual(self.infer(altered)['pass_observed'],[],column)
        self.assertEqual(self.infer(dict(f,compiler_artifact=[]))['pass_observed'],[])
        f['cost_observation']=[['gcc','universe-element',4,'control'],['gcc','merged-class',2,'control'],['gcc','projected-slot',2,'control']]
        self.assertEqual(len(self.infer(f)['incomparable_units']),6);self.assertEqual(self.infer(f)['applicable'],[])

    def test_independent_reachability_oracle(self):
        # Reference: per-node queue traversal. It does not call the candidate's
        # saturation or unit projection, and is not production admission logic.
        fixtures=[({1,2,3},[(1,2),(2,3)]),({1,2,3},[(1,2),(2,1),(2,3)]),({1,2,3},[(1,2),(1,2)]),({1,2,3,4},[(1,2),(3,4)]),({1},[]),({("value",1),("location",1),("value",2)},[( ("value",1),("location",1)),(("location",1),("value",2))])]
        assertions=[]
        def literal(value):
            if isinstance(value,tuple):return '('+','.join(literal(x) for x in value)+')'
            return json.dumps(value)
        for nodes,edges in fixtures:
            expected=set()
            for start in nodes:
                seen={start};queue=[start]
                while queue:
                    head=queue.pop(0)
                    for left,right in edges:
                        if left==head and right not in seen:seen.add(right);queue.append(right)
                expected.update((start,end) for end in seen)
            ns='Set('+','.join(literal(x) for x in sorted(nodes))+')'
            es='Set('+','.join(f'({literal(a)},{literal(b)})' for a,b in sorted(set(edges)))+')'
            oracle='Set('+','.join(f'({literal(a)},{literal(b)})' for a,b in sorted(expected))+')'
            assertions.append(f'assert(aliasClosure({ns},{es}) == {oracle})')
        source=self.out/'oracle.qnt'
        imported=(ROOT/'models/gambit/native_compiler_probe_correspondence').as_posix()
        shutil.copyfile(ROOT/'models/gambit/native_compiler_probe_correspondence.qnt',self.out/'native_compiler_probe_correspondence.qnt')
        imported='./native_compiler_probe_correspondence'
        source.write_text('module oracle {\n import native_compiler_probe_correspondence.* from "'+imported+'"\n run oracleTest = init.then(all { '+', '.join(assertions)+", s' = s })\n}\n")
        row=capture([shutil.which('quint'),'test',str(source),'--max-samples','1'],self.out,30,dict(os.environ))
        (self.out/'oracle.json').write_text(json.dumps(asdict(row),indent=2));self.assertEqual(row.exit,0,row.stdout+row.stderr);self.assertTrue(row.group_quiescent)
