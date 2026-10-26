from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Success','Error','Retry','Retained']
NEG=['OuterJump','LocalDetach','LostDebt','StopService','GcInWindow','StaleCommit','MissingJobMap','MissingCallbackMap','StaleLocal','EarlyReturn','EarlyTail','LockHeld','OldRank','ThrowFromService','DropGcDebt']
TARGETS={'GcThenCommit':('Success','s.phase==7 and s.g and s.committed and s.ack and s.host'),
 'RetainedAfterGc':('Retained','s.phase==6 and s.g and s.failed and s.active and s.serving and s.jobRoot'),
 'DebtAfterDeparture':('Success','s.phase==7 and s.gcDebt and s.gcDemand and not(s.gcAccepted) and s.ack'),
 'ErrorReturn':('Error','s.phase==8 and s.error and s.deferred and s.host and s.ack')}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def safe(s):
 return (not s['gcDemand'] or s['gcDebt'] or s['gcAccepted']) and s['host'] and s['catcher'] and not s['tlock'] and not s['plock'] and s['rankOk'] and s['jobRoot'] and s['jg']==s['g'] and (not s['cbRoot'] or s['cg']==s['g']) and (not s['usedCached'] or s['cached']==s['g']) and (not(s['window'] and s['valid']) or not s['dirty']) and (not s['committed'] or (s['valid'] and not s['dirty'] and not s['readers'])) and (s['active'] or s['committed']) and (not s['active'] or s['serving']) and (s['phase']==0 or s['pending'] or s['committed']) and (not s['returned'] or (s['committed'] and s['ack'] and not s['active'])) and (s['tail'] or s['returned']) and (not(s['error'] and s['phase']>0) or s['deferred'])
def target(s,g):
 if g=='GcThenCommit':return s['phase']==7 and s['g'] and s['committed'] and s['ack'] and s['host']
 if g=='RetainedAfterGc':return s['phase']==6 and s['g'] and s['failed'] and s['active'] and s['serving'] and s['jobRoot']
 if g=='DebtAfterDeparture':return s['phase']==7 and s['gcDebt'] and s['gcDemand'] and not s['gcAccepted'] and s['ack']
 if g=='ErrorReturn':return s['phase']==8 and s['error'] and s['deferred'] and s['host'] and s['ack']
 raise ValueError(g)
def project(code,name,observer=None):
 s=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
 return s[:-2]+'  val targetNotReached=not('+observer+')\n}\n' if observer else s
def main():
 protected=json.loads((E/'checked-park-source-protocol.json').read_text())['protectedInputs'];assert all(sha(R/n)==h for n,h in protected.items())
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/repark-cohort');out.mkdir(parents=True)
  model=R/'models/gambit/repark_cohort.qnt'
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='repark-cohort.v1',model=str(model.relative_to(R)),modelSha256=sha(model),nativeExecutions=0,nativeAdmitted=False,perCaseTimeoutSeconds=30,protectedInputs=protected,rows=[],allAccepted=False)
  cases=[(n,'positive',None) for n in POS]+[(n,'negative',None) for n in NEG]+[(n,'reachability',g) for g,(n,_) in TARGETS.items()]
  for n,kind,g in cases:
   case=out/(n+('-'+g if g else ''));case.mkdir();p=case/model.name;p.write_text(project(code,'init'+n,TARGETS[g][1] if g else None))
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if g else 'safe',negative=kind!='positive',temporal='progress' if kind=='positive' else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if kind!='positive':
    w=next((x['s'] for x in (trace or {}).get('states',[]) if target(x['s'],g)),None) if g else next((x['s'] for x in (trace or {}).get('states',[]) if not safe(x['s'])),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   row.update(initializer='init'+n,kind=kind,goal=g,evidenceDirectory=str(case.relative_to(R)));res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(n,kind,row['accepted'],row['seconds'],flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected staged FFI control')
  res['allAccepted']=len(res['rows'])==23 and all(x['accepted'] for x in res['rows']);assert res['allAccepted']
  assert all(sha(R/n)==h for n,h in protected.items());res['protectedInputsUnchanged']=True
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
