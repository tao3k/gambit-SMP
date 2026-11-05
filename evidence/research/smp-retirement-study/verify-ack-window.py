from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.task_processes import check_output
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check,counterexample
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['AllFinish','BusyB','ParkedB','NativeSync','LateAck','Rejoin']
SAFETY=['EarlyWindow','ConcurrentGc','RemoteParkedDetach','SkipFreeze','LoseLateDebt','DoubleDetach','DropParkedRoot']
LIVE=['StrictGc','SerialB','GlobalBorrow','ActiveBlocked','Unfair']
GOALS={'ReaderTail':('AllFinish','s.phase==2 and s.readB and s.readC'),
 'ParkedRetained':('ParkedB','s.serviceSeen and s.doneC and s.parkedB and s.rootB and s.domainB')}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def safe(s):
 return s['activeB']!=s['parkedB'] and (not s['parkedB'] or (s['frozenB'] and s['materialB'] and s['scanOwnerB']==2)) and (not s['activeB'] or s['scanOwnerB']==1) and (not s['window'] or (s['phase'] in (4,5) and not s['readB'] and not s['readC'])) and (not s['readB'] or s['rootB']) and (not s['readC'] or s['rootC']) and (not s['debtB'] or (s['rootB'] and s['domainB'])) and (not s['debtC'] or (s['rootC'] and s['domainC'])) and (not s['rootB'] or s['domainB']) and (not s['rootC'] or s['domainC']) and (s['rootB'] or s['cleanupB']==1) and (s['rootC'] or s['cleanupC']==2) and s['detachC']<=1 and (not s['extraRoot'] or s['extraDebt']) and (not s['latePublished'] or s['extraRoot'] or s['extraDone']) and (not s['vmFree'] or (not s['domainB'] and not s['domainC'] and not s['extraRoot']))
def goal(s):
 m=s['mode']
 if m in (1,2):return s['doneC'] and s['rootB'] and s['domainB'] and s['debtB']
 if m==4:return s['doneB'] and s['doneC'] and s['nativeSeen']
 if m==5:return s['doneC'] and s['extraDone']
 return s['doneB'] and s['doneC']
def target(s,g):
 if g=='ReaderTail':return s['phase']==2 and s['readB'] and s['readC']
 if g=='ParkedRetained':return s['serviceSeen'] and s['doneC'] and s['parkedB'] and s['rootB'] and s['domainB']
 raise ValueError(g)
def project(code,name,observer=None):
 s=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
 return s[:-2]+'  val targetNotReached=not('+observer+')\n}\n' if observer else s
def main():
 before=json.loads((E/'run-ack-source-protocol.json').read_text())['protectedInputs'];assert all(sha(R/n)==h for n,h in before.items())
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/ack-service-window');out.mkdir(parents=True)
  model=R/'models/gambit/ack_service_window.qnt'
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  supplement=check_output(['git','-C',str(R/'vendor/gambit'),'show','7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882:lib/setup.h'],timeout=10)
  assert 'lib/setup.h' not in json.loads((R/'evidence/research/processor-interrupt-collective-wait/foreign-release-claim.lock.json').read_text())['files']
  (out/'setup.h').write_bytes(supplement)
  res=dict(schema='ack-service-window.v1',model=str(model.relative_to(R)),modelSha256=sha(model),perCaseTimeoutSeconds=30,nativeAdmitted=False,nativeExecutions=0,supplement=dict(path=str((out/'setup.h').relative_to(R)),sha256=sha(out/'setup.h'),revision='7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882',patchTouchesFile=False),protectedInputs=before,rows=[],allAccepted=False)
  cases=[(n,'positive',None) for n in POS]+[(n,'safety-negative',None) for n in SAFETY]+[(n,'temporal-negative',None) for n in LIVE]+[(n,'reachability',g) for g,(n,_) in GOALS.items()]
  for n,kind,g in cases:
   case=out/(n+('-'+g if g else ''));case.mkdir();p=case/model.name;p.write_text(project(code,'init'+n,GOALS[g][1] if g else None))
   temporal=('noSchedulerAssumption' if n=='Unfair' else 'progress') if kind in ('positive','temporal-negative') else None
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if g else 'safe',negative=kind in ('safety-negative','reachability'),temporal=temporal,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if kind=='temporal-negative':
    row['backendAccepted']=row['accepted'];cleaned=re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M)
    try:trace=counterexample(cleaned)
    except ValueError:trace=None
    loop=re.search(r'Back to state (\d+)|State (\d+): Stuttering',log);states=[x['s'] for x in (trace or {}).get('states',[])]
    row['cycleMarker']=loop.group(0) if loop else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and states and all(safe(x) and not goal(x) for x in states) and row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
   elif kind in ('safety-negative','reachability'):
    w=next((x['s'] for x in (trace or {}).get('states',[]) if target(x['s'],g) if g),None) if g else next((x['s'] for x in (trace or {}).get('states',[]) if not safe(x['s'])),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   row.update(initializer='init'+n,kind=kind,goal=g,evidenceDirectory=str(case.relative_to(R)));res['rows'].append(row)
   (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(n,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected ACK service result')
  res['allAccepted']=len(res['rows'])==20 and all(x['accepted'] for x in res['rows']);assert res['allAccepted']
  assert all(sha(R/n)==h for n,h in before.items());res['protectedInputsUnchanged']=True
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
