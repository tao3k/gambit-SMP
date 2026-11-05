from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Success','Retry','Retained']
NEG=['EarlyGo','ActivateBeforeGo','MemberReturn','FreeOldAtAck','OldTailAccess','FreeRcAtGo','AckWithoutRoot','FreeWithBorrow','FreeWithReader','LoseMap','DetachedReload','DoubleRelease','FailedDrop','PostReleaseRead','SharedMailbox']
TARGETS={'NewGcOldPinned':('Success','s.go and s.activated==successors and s.tails!=Set() and s.oldLive and s.newGc and s.g'),
 'ReleasedWithDestination':('Success','not(s.rc) and s.dst and s.restoreAck and s.releases==1 and s.borrowers==Set()'),
 'RetainedGc':('Retained','s.retained and s.serviced and s.g and s.rc'),
 'RetryCommitted':('Retry','s.failed and s.go and s.acks==old')}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def norm(s):
 return {k:set(v['$integerSet']) if isinstance(v,dict) and '$integerSet' in v else v for k,v in s.items()}
def safe(s):
 s=norm(s)
 old={0,1,2}
 return (not(s['go'] and s['tails']) or s['distinctChannels']) and (not s['go'] or (s['installed'] and set(s['acks'])==old)) and (s['go'] or not s['activated']) and (s['oldLive'] or not s['tails']) and not s['oldAccess'] and not s['returnedEarly'] and not s['detachedPs'] and (not s['departed'] or (s['go'] and 2 not in s['tails'])) and (not s['restoreAck'] or (s['dst'] and s['rejoined'])) and (s['rc'] or s['dst']) and (not s['rc'] or s['rg']==s['g']) and (not s['dst'] or s['dg']==s['g']) and s['releases']<=1 and (s['rc'] or (s['restoreAck'] and not s['readers'] and not s['borrowers'])) and (not s['retained'] or (s['rc'] and not s['go']))
def target(s,g):
 s=norm(s)
 if g=='NewGcOldPinned':return s['go'] and set(s['activated'])=={0,1} and bool(s['tails']) and s['oldLive'] and s['newGc'] and s['g']
 if g=='ReleasedWithDestination':return not s['rc'] and s['dst'] and s['restoreAck'] and s['releases']==1 and not s['borrowers']
 if g=='RetainedGc':return s['retained'] and s['serviced'] and s['g'] and s['rc']
 if g=='RetryCommitted':return s['failed'] and s['go'] and set(s['acks'])=={0,1,2}
 raise ValueError(g)
def project(code,name,observer=None):
 s=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
 return s[:-2]+'  val targetNotReached=not('+observer+')\n}\n' if observer else s
def main():
 protected=json.loads((E/'checked-park-source-protocol.json').read_text())['protectedInputs'];assert all(sha(R/n)==h for n,h in protected.items())
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/cohort-ack-rc');out.mkdir(parents=True)
  model=R/'models/gambit/cohort_ack_rc.qnt'
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='cohort-ack-rc.v1',model=str(model.relative_to(R)),modelSha256=sha(model),nativeExecutions=0,nativeAdmitted=False,perCaseTimeoutSeconds=30,protectedInputs=protected,rows=[],allAccepted=False)
  cases=[(n,'positive',None) for n in POS]+[(n,'negative',None) for n in NEG]+[(n,'reachability',g) for g,(n,_) in TARGETS.items()]
  for n,kind,g in cases:
   case=out/(n+('-'+g if g else ''));case.mkdir();p=case/model.name;p.write_text(project(code,'init'+n,TARGETS[g][1] if g else None))
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if g else 'safe',negative=kind!='positive',temporal=None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if kind!='positive':
    w=next((x['s'] for x in (trace or {}).get('states',[]) if target(x['s'],g)),None) if g else next((x['s'] for x in (trace or {}).get('states',[]) if not safe(x['s'])),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   row.update(initializer='init'+n,kind=kind,goal=g,evidenceDirectory=str(case.relative_to(R)));res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(n,kind,row['accepted'],row['seconds'],flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected staged FFI control')
  res['allAccepted']=len(res['rows'])==22 and all(x['accepted'] for x in res['rows']);assert res['allAccepted']
  assert all(sha(R/n)==h for n,h in protected.items());res['protectedInputsUnchanged']=True
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
