from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
NAMES=['Return','BodyError','PrefixError','BlockedChild','RunError','StaleOwner','DuplicateCompletion','RemoteLongjmp','PidOnlyRoute','ChildFreesParent','PublishNoRoot','DropBridgeEarly','DropChildBeforeMessage','AcceptStaleOwner','DuplicateFinalDrop','RestorePreGcResult','AccessAfterFinalDrop','RunMarkerBypassed','BlockedChildFreed','WrongAckOwner','DropSenderDomain','OwnerDiesWithDomain','AckBeforeReceiverRoot']
TARGETS={'Return':'s.vmFree and s.routed and s.calls==1','BodyError':'s.b==3 and s.failed and s.loanB','PrefixError':'s.b==3 and s.failed and not(s.loanB) and s.frameB','BlockedChild':'s.closing and s.b==2 and s.bridge and s.loanA and s.loanB','RunError':'s.vmFree and s.runError and not(s.markerA)','StaleOwner':'s.vmFree and s.staleRejected and s.routed','DuplicateCompletion':'s.vmFree and s.duplicateRejected and s.routed'}
def normalize(x):
 if isinstance(x,dict):
  if set(x)=={'$integerSet'}:return x['$integerSet']
  return {k:normalize(v) for k,v in x.items()}
 if isinstance(x,list):return [normalize(v) for v in x]
 return x
def safe(s):
 return (s['msg']<2 or s['routed']) and (s['msg']!=3 or s['cleanupOwner']==s['msgRootOwner']) and (not s['senderDomain'] or (s['ownerBAlive'] and s['msgPin'])) and (not s['rootM'] or s['msgRootOwner']!=1 or s['senderDomain']) and (not s['frameB'] or s['ownerBAlive']) and not s['bad'] and s['calls']<=1 and (not s['routed'] or (s['routeVm']==7 and s['routeOwner']==2 and s['routeNonce']==101 and s['routeNative']==0 and s['msg']>=2)) and s['refs']==sum(int(s[k]) for k in ['frameA','frameB','runA','bridge','msgPin','resourcePin']) and (s['a']>=8 or (s['frameA'] and s['ctlA'] and s['rootA'] and s['runA'])) and (s['b']==0 or s['b']>=6 or s['bridge']) and (not s['frameB'] or (s['ctlB'] and s['rootB'])) and (s['b']<1 or s['b']>4 or s['frameB']) and (s['msg']==0 or s['msg']>=3 or (s['rootM'] and s['msgPin'])) and (not s['loanA'] or s['frameA']) and (not s['loanB'] or s['frameB']) and (s['phase']<2 or (not s['loanA'] and not s['loanB'])) and (not s['markerA'] or s['runA']) and all(not s['root'+k] or s['v'+k]==s['gc'] for k in ['A','B','M']) and (not s['metaFree'] or (s['phase']==2 and not s['ctlA'] and not s['ctlB'] and not s['bridge'] and not s['msgPin'])) and (not s['vmFree'] or (s['closing'] and s['refs']==0))
def target(s,g):
 if g=='Return':return s['vmFree'] and s['routed'] and s['calls']==1
 if g=='BodyError':return s['b']==3 and s['failed'] and s['loanB']
 if g=='PrefixError':return s['b']==3 and s['failed'] and not s['loanB'] and s['frameB']
 if g=='BlockedChild':return s['closing'] and s['b']==2 and s['bridge'] and s['loanA'] and s['loanB']
 if g=='RunError':return s['vmFree'] and s['runError'] and not s['markerA']
 if g=='StaleOwner':return s['vmFree'] and s['staleRejected'] and s['routed']
 if g=='DuplicateCompletion':return s['vmFree'] and s['duplicateRejected'] and s['routed']
 raise ValueError(g)
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/ffi-native-owner-model');out.mkdir(parents=True)
  model=R/'models/gambit/ffi_native_owner_handoff.qnt';code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='ffi-native-owner-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  cases=[(n,None) for n in NAMES]+[(n,n) for n in TARGETS]
  for i,(suffix,goal) in enumerate(cases):
   name='init'+suffix;case=out/(name+('-goal' if goal else ''));case.mkdir();compiled=case/model.name
   projected=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
   if goal:projected=projected[:-2]+'  val targetNotReached=not('+TARGETS[goal]+')\n}\n'
   compiled.write_text(projected)
   row,log,trace=check(compiled,initializer=name,invariant='targetNotReached' if goal else 'safe',negative=bool(goal or i>=7),timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=7:
    states=[normalize(x['s']) for x in (trace or {}).get('states',[])];w=next((s for s in states if target(s,goal)),None) if goal else next((s for s in states if not safe(s)),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   row.update(initializer=name,caseName=case.name,goal=goal);res['rows'].append(row);res['allAccepted']=len(res['rows'])==len(cases) and all(x['accepted'] for x in res['rows'])
   (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(case.name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected result: '+str(case))
  print(out,flush=True)
if __name__=='__main__':main()
