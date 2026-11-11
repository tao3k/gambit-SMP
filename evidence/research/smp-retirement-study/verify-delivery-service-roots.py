from pathlib import Path
import json,hashlib,re,sys
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check,counterexample
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 source=json.loads((E/'prepared-signal-native-commit.json').read_text())
 for n,v in source['currentFiles'].items():assert sha(R/v['path'])==v['sha256'],n
 assert sha(R/source['sourceLock'])==source['sourceLockSha256']
 protected={n:sha(R/n) for n in source['protectedInputs']}
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/delivery-service-roots');out.mkdir(parents=True)
  model=R/'models/gambit/delivery_service_roots.qnt';model.write_bytes(Path('/tmp/delivery-service-roots.qnt').read_bytes())
  verifier=E/'verify-delivery-service-roots.py';verifier.write_bytes(Path('/tmp/verify-delivery-service-roots.py').read_bytes())
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='delivery-service-roots.v1',model=str(model.relative_to(R)),modelSha256=sha(model),sourceLock=source['sourceLock'],sourceLockSha256=source['sourceLockSha256'],perCaseTimeoutSeconds=30,nativeRuns=0,runtimeAdmitted=False,rows=[],allAccepted=False)
  cases=[(n,'positive') for n in ['Bare','Device','WakeSuccess']]+[(n,'negative') for n in ['ClearOnNotify','HiddenGc','MissingMap','StaleLocal','NoDestinationRoot','DispatchLocked','FalseTimeout','EarlyDomainRemove','EscapeLocked']]+[('NoBound','temporal-negative')]+[(n,'reachability') for n in ['Bare','Device']]
  if '--reach-only' in sys.argv:
   prior=R/'.cache/tasks/repair-9-12/processes/audit/runs/5609f7d75cc04427a7a132bb84c69958/outputs/delivery-service-roots/receipt.json'
   retained=json.loads(prior.read_text());assert retained['allAccepted'] and retained['modelSha256']==sha(model)
   result['retainedChecks']={'path':str(prior.relative_to(R)),'sha256':sha(prior)};result['rows']=retained['rows']
   cases=[c for c in cases if c[1]=='reachability']
  for n,kind in cases:
   d=out/(n+'-'+kind);d.mkdir();p=d/model.name;projected=re.sub(r'^  action init(\w+)=.*\n',lambda m:m[0] if m[1]==n else '',code,flags=re.M)
   if kind=='reachability':projected=projected.rsplit('}',1)[0]+'  val targetNotReached=not(s.done and s.wakeFails and s.retried and s.finishGc)\n}\n'
   p.write_text(projected)
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if kind=='reachability' else 'safe',negative=kind in ('negative','reachability'),temporal='progress' if kind in ('positive','temporal-negative') else None,timeout=30,cwd=d,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (d/'check.log').write_text(log)
   if kind=='temporal-negative':
    loop=re.search(r'Back to state \d+|State \d+: Stuttering',log)
    try:trace=counterexample(re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M))
    except ValueError:trace=None
    states=[v['s'] for v in (trace or {}).get('states',[])]
    row['cycleMarker']=loop.group(0) if loop else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and states and any(s['phase']==4 and s['wakeFails'] and not s['finite'] and not s['done'] for s in states) and row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
   if kind in ('negative','reachability'):row['accepted']=bool(row['accepted'] and trace and len(trace.get('states',[]))>1)
   if trace:(d/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   row.update(initializer='init'+n,kind=kind,evidenceDirectory=str(d.relative_to(R)));result['rows'].append(row)
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(n,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:break
  result['allAccepted']=len(result['rows'])==15 and all(x['accepted'] for x in result['rows'])
  result['protectedInputsUnchanged']=protected=={n:sha(R/n) for n in protected}
  for n,v in source['currentFiles'].items():assert sha(R/v['path'])==v['sha256'],n
  assert result['protectedInputsUnchanged']
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
