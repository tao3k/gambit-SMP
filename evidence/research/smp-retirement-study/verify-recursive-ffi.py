from pathlib import Path
import hashlib,json,re,sys
from gambit_smp.tlc_values import value
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
NAMES=['Nested','PrefixFailure','InnerBoundary','OuterBoundary','TrampolineRetry','RetainedCleanup','ResultFailure','ReturnedPointer','MatchedDropsOuter','PrefixBypassesDrain','RetryDrainsOuter','JumpSkipsJournal','FreeMetadataAtLoanZero','ReadAfterLastReference','KillAllMarkers','RestoreStaleRoots','WrongOwnerUnwind','DuplicateUnwind','DropPinBeforeTail','RetryUncertainCleanup','ResultBypassesDrain','SkipCallbackParent','DropRunAnchor','ReturnLoanDiesAtMarker','ReturnOwnerFrameGone']
TARGETS={'Nested':'s.vmFree and s.entered.contains(5) and s.calls==1','PrefixFailure':'s.vmFree and s.prefixFailed and s.entered.contains(5)','InnerBoundary':'s.reached and s.target==2 and s.stack==[1,2] and s.loans.contains(1) and s.markers.contains(2)','OuterBoundary':'s.vmFree and s.reached and s.target==0 and s.entered.contains(5)','TrampolineRetry':'s.retried and s.stack==[1,2,3,4,5] and s.loans==Set(1,3,5)','RetainedCleanup':'s.fault and s.closed and s.stack==[1,2,3,4,5] and s.loans==Set(1,3,5)','ResultFailure':'s.vmFree and s.resultFailed and s.entered.contains(5)','ReturnedPointer':'s.vmFree and s.returnMoved and s.entered.contains(5)'}
def normalize(x):
 if isinstance(x,dict):
  if set(x)=={'$integerSet'}:return x['$integerSet']
  return {k:normalize(v) for k,v in x.items()}
 if isinstance(x,list):return [normalize(v) for v in x]
 return x
def decode(log):
 # Research-local extension: recursive stack is a homogeneous variable-length List[int].
 # Existing backend shape inference compares tuple lengths and rejects this valid trace.
 ints=set('mode bug p1 p2 p3 p4 p5 vmRefs op calls target gc rootVersion returnOwner'.split())
 bools=set('anchor resourcePin metaBase metaFree closed vmFree freed unwinding reached prefixFailed resultFailed retried fault returnMoved returnRefused bad'.split())
 sets=set('entered popped loans using roots records pins markers'.split())
 states=[]
 for block in re.findall(r'^State \d+:[^\n]*\n((?:[^\n]+\n)+)',log,re.M):
  if not block.startswith('s = '):raise ValueError('unexpected trace variables')
  item=normalize(value(block[4:]));assert set(item)==ints|bools|sets|{'stack'}
  assert all(type(item[k]) is int for k in ints) and all(type(item[k]) is bool for k in bools)
  assert type(item['stack']) is list and len(item['stack'])<=5 and all(type(x) is int for x in item['stack'])
  assert all(type(item[k]) is list and len(set(item[k]))==len(item[k]) and all(type(x) is int for x in item[k]) for k in sets)
  states.append({'s':item})
 if len(states)<2:raise ValueError('missing trace')
 return {'schema':'recursive-ffi-counterexample.v1','states':states}
def safe(s):
 live=set(s['stack']);cf={1,3,5};sf={2,4};loans=set(s['loans'])
 return not s['bad'] and s['calls']<=1 and s['stack']==[1,2,3,4,5][:len(s['stack'])] and live<=set(s['roots']) and live<=set(s['pins']) and live&cf<=set(s['records']) and set(s['using'])<=loans and loans-{6}<=live&cf and (6 not in loans or (s['returnOwner'] in live and 6 in s['records'] and (not s['returnMoved'] or s['returnOwner']==3))) and all(s['p'+str(i)]<5 or i not in loans for i in cf) and all(s['p'+str(i)]>=5 or i in s['markers'] for i in live&sf) and s['vmRefs']==len(s['pins'])+int(s['anchor'])+int(s['resourcePin']) and (not live or s['anchor']) and (s['op']<2 or not loans) and (not s['freed'] or not loans) and (not s['metaFree'] or (not s['metaBase'] and not s['records'])) and (not s['vmFree'] or (s['closed'] and s['vmRefs']==0)) and (not live or s['rootVersion']==s['gc'])
def target(s,g):
 if g=='Nested':return s['vmFree'] and 5 in s['entered'] and s['calls']==1
 if g=='PrefixFailure':return s['vmFree'] and s['prefixFailed'] and 5 in s['entered']
 if g=='InnerBoundary':return s['reached'] and s['target']==2 and s['stack']==[1,2] and 1 in s['loans'] and 2 in s['markers']
 if g=='OuterBoundary':return s['vmFree'] and s['reached'] and s['target']==0 and 5 in s['entered']
 if g=='TrampolineRetry':return s['retried'] and s['stack']==[1,2,3,4,5] and set(s['loans'])=={1,3,5}
 if g=='RetainedCleanup':return s['fault'] and s['closed'] and s['stack']==[1,2,3,4,5] and set(s['loans'])=={1,3,5}
 if g=='ReturnedPointer':return s['vmFree'] and s['returnMoved'] and 5 in s['entered']
 if g=='ResultFailure':return s['vmFree'] and s['resultFailed'] and 5 in s['entered']
 raise ValueError(g)
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/recursive-ffi-composition');out.mkdir(parents=True)
  model=R/'models/gambit/recursive_ffi_loan_composition.qnt';code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='recursive-ffi-composition.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),verifierSha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  prior=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else None
  previous=json.loads((prior/'receipt.json').read_text()) if prior else None
  if previous:assert previous['modelSha256']==res['modelSha256'];res['retainedPredecessor']=str(prior.relative_to(R))
  cases=[(n,None) for n in NAMES]+[(n,n) for n in TARGETS]
  for i,(suffix,goal) in enumerate(cases):
   name='init'+suffix;case=out/(name+('-goal' if goal else ''));case.mkdir();compiled=case/model.name
   projected=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
   if goal:projected=projected[:-2]+'  val targetNotReached=not('+TARGETS[goal]+')\n}\n'
   compiled.write_text(projected)
   previousRows={r['caseName']:r for r in previous['rows']} if previous else {}
   if case.name in previousRows:
    row=dict(previousRows[case.name]);pcase=prior/case.name;assert (pcase/model.name).read_bytes()==compiled.read_bytes()
    assert hashlib.sha256(compiled.read_bytes()).hexdigest()==row['checker']['modelSha256']
    log=(pcase/'check.log').read_text();trace=None;row['reusedEvidenceDirectory']=str(pcase.relative_to(R))
   else:
    row,log,trace=check(compiled,initializer=name,invariant='targetNotReached' if goal else 'safe',negative=bool(goal or i>=8),timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   if i>=8:
    assert row['exit']==12 and not row['timeout'] and 'Error: Invariant q_inv is violated.' in log
    trace=decode(log);row['traceDecoder']='research-local homogeneous List[int], strict fields; no backend source change'
    row['accepted']=True
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=8:
    states=[normalize(x['s']) for x in (trace or {}).get('states',[])];w=next((s for s in states if target(s,goal)),None) if goal else next((s for s in states if not safe(s)),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   row.update(initializer=name,caseName=case.name,goal=goal);res['rows'].append(row);res['allAccepted']=len(res['rows'])==len(cases) and all(x['accepted'] for x in res['rows'])
   (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(case.name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected result: '+str(case))
  print(out,flush=True)
if __name__=='__main__':main()
