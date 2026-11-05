from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Return','PrepareFail','CommitFail','PostCommitFault','UnsafeAbi','P0Refusal','Callback','RollbackFail','RejoinFail']
NEG=['SaveIsMaterial','SplitMembership','WrongWorkers','DropFrozenRoot','KillRunMarker','OldFpRestore','ParkP0','DirectCallback','StaleTicket','DoubleRestore','RollbackDrop','RemoteOwner','OmitStillScan','OmitRcScan','KeepPrivateWork','DoubleScan','CallbackCompletesParent']
TARGETS={'RetainedRejoin':('RejoinFail','s.phase==12 and not(s.activeB) and s.rejoinRequested and s.carrier and s.cProgress'),
 'Frozen':('Return','s.phase==5 and not(s.activeB) and s.material and s.carrier'),
 'CurrentAbort':('PrepareFail','s.phase==8 and s.gcBit and s.restoreSource==1'),
 'CallbackRejoin':('Callback','s.phase==7 and s.callback and s.activeB and s.freshStack and s.restores==0 and not(s.jobDone)'),
 'RetainedFailure':('RollbackFail','s.phase==12 and s.activeB and s.carrier and s.cProgress')}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def base_safe(s):
 return s['nativeCtx'] and s['marker'] and (s['liveRoot'] or (s['carrier'] and s['registered'] and s['domain'])) and (not s['carrier'] or (s['registered'] and s['valueBit']==s['gcBit'])) and ((s['workers']==2 and s['scanOwner']==1) if s['activeB'] else (s['workers']==1 and s['scanOwner']==2 and s['material'] and s['frozen'] and s['carrier'] and s['domain'] and not s['isP0'])) and (not s['bodyRan'] or (s['approved'] and (s['activeB'] or (s['material'] and s['frozen'])))) and s['restores']<=1 and s['restoreSource']!=2 and (s['restores']==0 or not s['callback'] or (s['callbackDone'] and s['jobDone'])) and (s['restores']==0 or s['activeB']) and (s['epoch'] not in (2,4) or (s['activeB'] and s['freshStack'] and s['owner']==1 and s['ticket']==s['acceptedTicket'])) and (not s['retained'] or (s['carrier'] and s['registered'] and s['domain'])) and (not s['refused'] or (not s['bodyRan'] and s['epoch']==0))
def safe(s):
 return base_safe(s) and s['scanCopies']==1 and (s['activeB'] or (s['privateWork']==0 and s['stillBit']==s['gcBit'] and s['rcBit']==s['gcBit']))
def target(s,g):
 if g=='RetainedRejoin':return s['phase']==12 and not s['activeB'] and s['rejoinRequested'] and s['carrier'] and s['cProgress']
 if g=='Frozen':return s['phase']==5 and not s['activeB'] and s['material'] and s['carrier']
 if g=='CurrentAbort':return s['phase']==8 and s['gcBit'] and s['restoreSource']==1
 if g=='CallbackRejoin':return s['phase']==7 and s['callback'] and s['activeB'] and s['freshStack'] and s['restores']==0 and not s['jobDone']
 if g=='RetainedFailure':return s['phase']==12 and s['activeB'] and s['carrier'] and s['cProgress']
 raise ValueError(g)
def project(code,name,observer=None):
 s=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
 return s[:-2]+'  val targetNotReached=not('+observer+')\n}\n' if observer else s
def main():
 protected=json.loads((E/'ack-collective-service.json').read_text())['protectedInputs'];assert all(sha(R/n)==h for n,h in protected.items())
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/checked-park-model');out.mkdir(parents=True)
  model=R/'models/gambit/checked_park.qnt'
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='checked-park-model.v4',typedPredecessor='.cache/tasks/repair-9-12/processes/audit/runs/75e942bf7fa24589bca3bbf6e0b6a74d/outputs/checked-park-model/receipt.json',predecessor='.cache/tasks/repair-9-12/processes/audit/runs/a4b8b048c3584ea3bec6f74920581346/outputs/checked-park-model/receipt.json',model=str(model.relative_to(R)),modelSha256=sha(model),nativeAdmitted=False,nativeExecutions=0,perCaseTimeoutSeconds=30,protectedInputs=protected,rows=[],allAccepted=False)
  cases=[(n,'positive',None) for n in POS]+[(n,'negative',None) for n in NEG]+[(n,'reachability',g) for g,(n,_) in TARGETS.items()]
  for n,kind,g in cases:
   case=out/(n+('-'+g if g else ''));case.mkdir();p=case/model.name;p.write_text(project(code,'init'+n,TARGETS[g][1] if g else None))
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if g else 'safe',negative=kind!='positive',temporal='progress' if kind=='positive' else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if kind!='positive':
    w=next((x['s'] for x in (trace or {}).get('states',[]) if target(x['s'],g)),None) if g else next((x['s'] for x in (trace or {}).get('states',[]) if not safe(x['s'])),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   row.update(initializer='init'+n,kind=kind,goal=g,evidenceDirectory=str(case.relative_to(R)));res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(n,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected checked park control')
  res['allAccepted']=len(res['rows'])==31 and all(x['accepted'] for x in res['rows']);assert res['allAccepted']
  assert all(sha(R/n)==h for n,h in protected.items());res['protectedInputsUnchanged']=True
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
