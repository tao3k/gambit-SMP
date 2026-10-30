"""Conditional QNT controls; no production compile or native execution."""
from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Entry','NoOwner','ClosedHost','Commit','Busy','Throw','Fault','Reset','StaleGuard']
NEG=['MissingRegister','AsyncBypass','RawHost','LegacyDrop','EarlyPopRelease','LostPopRoot','GcInCommit','EscapeInCommit','RetryUnlink','LocalReturn','WrongError','MissingReopen','StaleAck','ResetWithDebt']
GOALS={'Commit':'s.done and s.owner==2 and s.woken and not(s.locks) and s.count==0',
 'Busy':'s.done and s.ret0 and s.ret1 and s.result0==1 and s.result1==1 and not(s.sfun)',
 'Throw':'s.done and s.ret0 and s.ret1 and s.result0==2 and not(s.sfun)',
 'Fault':'s.done and s.retained and s.count==1 and s.registered and s.unlinks==1',
 'Reset':'s.done and s.reset and s.count==0',
 'StaleGuard':'s.done and s.retained and not(s.ret0) and not(s.ret1) and s.sfun',
 'NoOwner':'s.done and not(s.accepted) and not(s.touched) and s.callerOwns',
 'ClosedHost':'s.done and not(s.accepted) and s.callerOwns'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 b=json.loads((E/'delivery-function-alignment.json').read_text());lock=R/b['sourceLock'];assert sha(lock)==b['sourceLockSha256']
 protected=json.loads((E/'diagnostic-order-id-generated-c.json').read_text())['protectedInputs'];before={n:sha(R/n) for n in protected}
 m=R/'models/gambit/delivery_commit_entry_return.qnt';code=m.read_text()
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/delivery-commit-entry-return');out.mkdir(parents=True,exist_ok=True)
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='delivery-commit-entry-return.v1',model=str(m.relative_to(R)),modelSha256=sha(m),sourceLock=b['sourceLock'],sourceLockSha256=sha(lock),nativeRuns=0,sourceRefinementAdmitted=False,perCaseTimeoutSeconds=30,rows=[],allAccepted=False)
  cases=[(n,False,None,'safety') for n in POS]+[(n,True,None,'mutant') for n in NEG]+[(n,True,g,'reachability') for n,g in GOALS.items()]
  cases += [('Entry',True,'s.done and s.accepted and s.kind=='+str(k),'entry-kind-reachability-'+str(k)) for k in range(9)]
  for name,negative,goal,kind in cases:
   d=out/(name+'-'+kind);d.mkdir()
   projected=re.sub(r'^  action init(\w+)=.*\n',lambda v:v[0] if v[1]==name else '',code,flags=re.M)
   if goal:projected=projected.rsplit('}',1)[0]+'  val targetNotReached=not('+goal+')\n}\n'
   snap=d/m.name;snap.write_text(projected)
   row,log,trace=check(snap,initializer='init'+name,invariant='targetNotReached' if goal else 'safe',negative=negative,timeout=30,cwd=d,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (d/'check.log').write_text(log)
   if trace:(d/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if negative:row['accepted']=bool(row['accepted'] and trace and len(trace.get('states',[]))>1)
   row.update(initializer='init'+name,kind=kind,goal=goal,evidenceDirectory=str(d.relative_to(R)))
   if negative:row['witness']=(trace or {}).get('states',[{}])[-1].get('s')
   result['rows'].append(row);(out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('unexpected result retained at '+str(d))
  result['allAccepted']=all(r['accepted'] for r in result['rows']);result['protectedInputsUnchanged']=before=={n:sha(R/n) for n in protected};assert result['protectedInputsUnchanged'];assert sha(lock)==b['sourceLockSha256']
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
