from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check,counterexample
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 patch=R/'patches/fixtures/delivery-service-roots-cumulative.patch';ph='a303931266e5773a9b089d7dec9ad094c112ac9fb776945288e41b4adaa1e625';assert sha(patch)==ph
 b=json.loads((E/'prepared-signal-native-commit.json').read_text());protected={n:sha(R/n) for n in b['protectedInputs']}
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/active-request-drain');out.mkdir(parents=True)
  frozen=out/'producer-input.patch';frozen.write_bytes(patch.read_bytes());assert sha(frozen)==ph
  landed=E/'delivery-service-roots-landed.json';(out/'landed-input.json').write_bytes(landed.read_bytes());assert json.loads(landed.read_text())['patchSha256']==ph
  model=R/'models/gambit/active_request_drain.qnt';model.write_bytes(Path('/tmp/active-request-drain.qnt').read_bytes());(E/'verify-active-request-drain.py').write_bytes(Path('/tmp/verify-active-request-drain.py').read_bytes())
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='active-request-drain.v1',patch=str(patch.relative_to(R)),patchSha256=ph,sourcePatchSnapshot=str(frozen.relative_to(R)),landedSnapshot=str((out/'landed-input.json').relative_to(R)),model=str(model.relative_to(R)),modelSha256=sha(model),perCaseTimeoutSeconds=30,nativeRuns=0,runtimeAdmitted=False,rows=[],allAccepted=False)
  cases=[(n,'positive') for n in ['Good','Terminated','Retained','CommittedThenTerminated']]+[(n,'negative') for n in ['Replay','WrongUnlink','StaleNext','WrongTail','TermDouble','DropRoot','DropRetained','PhaseOnlyCapability','EarlyUnlink','LatePayload']]+[('HeadOnly','temporal-negative')]+[(n,'reachability') for n in ['Good','Terminated','Retained','CommittedThenTerminated']]
  for n,kind in cases:
   d=out/(n+'-'+kind);d.mkdir();p=d/model.name;t=re.sub(r'^ action init(\w+)=.*\n',lambda m:m[0] if m[1]==n else '',code,flags=re.M)
   if kind=='reachability':t=t.rsplit('}',1)[0]+' val targetNotReached=not(s.done and s.migrated and s.capChecked)\n}\n'
   p.write_text(t)
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if kind=='reachability' else 'safe',negative=kind in ('negative','reachability'),temporal='progress' if kind in ('positive','temporal-negative') else None,timeout=30,cwd=d,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (d/'check.log').write_text(log)
   if kind=='temporal-negative':
    loop=re.search(r'Back to state \d+|State \d+: Stuttering',log)
    try:trace=counterexample(re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M))
    except ValueError:trace=None
    states=[z['s'] for z in (trace or {}).get('states',[])];row['cycleMarker']=loop.group(0) if loop else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and any(s['stage']==2 and s['capChecked'] and not s['done'] for s in states) and row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
   if kind in ('negative','reachability'):row['accepted']=bool(row['accepted'] and trace and len(trace.get('states',[]))>1)
   if trace:(d/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   row.update(initializer='init'+n,kind=kind,evidenceDirectory=str(d.relative_to(R)));res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(n,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:break
  res['allAccepted']=len(res['rows'])==19 and all(r['accepted'] for r in res['rows']);res['protectedInputsUnchanged']=protected=={n:sha(R/n) for n in protected};assert res['protectedInputsUnchanged'] and sha(frozen)==ph
  res['livePatchObservedAtEnd']=sha(patch)
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
