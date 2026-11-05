from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check,counterexample
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 b=json.loads((E/'prepared-signal-native-commit.json').read_text());protected={n:sha(R/n) for n in b['protectedInputs']}
 for n,v in b['currentFiles'].items():assert sha(R/v['path'])==v['sha256'],n
 assert sha(R/b['sourceLock'])==b['sourceLockSha256']
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/device-relock-sync');out.mkdir(parents=True)
  model=R/'models/gambit/device_relock_sync.qnt';model.write_bytes(Path('/tmp/device-relock-sync.qnt').read_bytes());(E/'verify-device-relock-sync.py').write_bytes(Path('/tmp/verify-device-relock-sync.py').read_bytes())
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='device-relock-sync.v1',model=str(model.relative_to(R)),modelSha256=sha(model),sourceLock=b['sourceLock'],sourceLockSha256=b['sourceLockSha256'],perCaseTimeoutSeconds=30,nativeRuns=0,runtimeAdmitted=False,rows=[],allAccepted=False)
  cases=[(n,'positive') for n in ['Good','Closed']]+[(n,'negative') for n in ['SyncHeld','LosePrefix','MissingMap','StalePointer','StaleEpoch','EarlyFree','RetryClear','OldCompletion','LockLeak']]+[('Current','temporal-negative')]+[(n,'reachability') for n in ['Good','Closed']]
  for n,kind in cases:
   d=out/(n+'-'+kind);d.mkdir();p=d/model.name;t=re.sub(r'^ action init(\w+)=.*\n',lambda m:m[0] if m[1]==n else '',code,flags=re.M)
   if kind=='reachability':t=t.rsplit('}',1)[0]+' val targetNotReached=not(s.finished and s.gc==2 and s.delivered2 and s.ack==1 and s.epoch==2)\n}\n'
   p.write_text(t)
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if kind=='reachability' else 'safe',negative=kind in ('negative','reachability'),temporal='progress' if kind in ('positive','temporal-negative') else None,timeout=30,cwd=d,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (d/'check.log').write_text(log)
   if kind=='temporal-negative':
    loop=re.search(r'Back to state \d+|State \d+: Stuttering',log)
    try:trace=counterexample(re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M))
    except ValueError:trace=None
    states=[v['s'] for v in (trace or {}).get('states',[])];row['cycleMarker']=loop.group(0) if loop else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and any(s['phase']==3 and s['holder'] and s['pending'] and not s['finished'] for s in states) and row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
   if kind in ('negative','reachability'):row['accepted']=bool(row['accepted'] and trace and len(trace.get('states',[]))>1)
   if trace:(d/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   row.update(initializer='init'+n,kind=kind,evidenceDirectory=str(d.relative_to(R)));result['rows'].append(row);(out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(n,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:break
  result['allAccepted']=len(result['rows'])==14 and all(r['accepted'] for r in result['rows']);result['protectedInputsUnchanged']=protected=={n:sha(R/n) for n in protected}
  assert result['protectedInputsUnchanged']
  for n,v in b['currentFiles'].items():assert sha(R/v['path'])==v['sha256'],n
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
