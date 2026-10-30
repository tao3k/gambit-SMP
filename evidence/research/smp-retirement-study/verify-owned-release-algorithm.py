"""Conditional QNT controls; no production compile or native execution."""
from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Good','NoWait','Retry','Unused']
NEG=['NoNeighbors','WrongWaiter','SignalUnlocked','StaleRetry','DoubleUnpin','UnusedLeak','EarlyUnpin']
GOALS={'Good':'s.done and s.woken and s.pnext==s.next and s.nprev==s.prev',
'NoWait':'s.done and not(s.signalled) and s.leaves==1',
'Retry':'s.done and s.waiter==7 and s.woken',
'Unused':'s.done and not(s.pin) and s.leaves==1'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 b=json.loads((E/'delivery-integration-handoff.json').read_text());lock=R/b['sourceLock'];assert sha(lock)==b['sourceLockSha256']
 protected=json.loads((E/'diagnostic-order-id-generated-c.json').read_text())['protectedInputs'];before={n:sha(R/n) for n in protected}
 m=R/'models/gambit/owned_release_algorithm.qnt';code=m.read_text()
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/owned-release-algorithm');out.mkdir(parents=True,exist_ok=True)
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='owned-release-algorithm.v1',model=str(m.relative_to(R)),modelSha256=sha(m),sourceLock=b['sourceLock'],sourceLockSha256=sha(lock),nativeRuns=0,sourceRefinementAdmitted=False,perCaseTimeoutSeconds=30,rows=[],allAccepted=False)
  cases=[(n,False,None,'safety') for n in POS]+[(n,True,None,'mutant') for n in NEG]+[(n,True,g,'reachability') for n,g in GOALS.items()]
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
