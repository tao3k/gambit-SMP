from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
TARGETS={
 'Deferred':'s.phase==7 and s.gc==2 and s.freed and s.calls==1 and s.released and not(s.ptr) and s.actionCleared',
 'Resurrection':'s.phase==7 and s.gc==2 and s.resurrected and s.appRoot and not(s.freed) and s.calls==1 and s.released and not(s.ptr)',
 'ExplicitReleaseRace':'s.phase==7 and s.gc==2 and s.explicitReleased and s.explicitDone and s.appRoot and s.actionCleared and s.calls==1 and s.released and not(s.ptr)',
 'RaceWillWins':'s.phase==7 and s.gc==2 and s.explicitDone and not(s.explicitReleased) and s.appRoot and s.calls==1 and s.actionCleared and s.released and not(s.ptr)',
 'CheckedBridge':'s.phase==7 and s.context and s.vmTouched and s.validToken and s.calls==1 and s.released',
 'NoContextRefusal':'s.phase==8 and s.refused and not(s.vmTouched) and not(s.accepted) and s.calls==0',
 'UnknownSweepStop':'s.phase==9 and s.fatal and s.calls==0 and not(s.freed) and s.ptr'}
def target(s,n):
 if n=='Deferred':return s['phase']==7 and s['gc']==2 and s['freed'] and s['calls']==1 and s['released'] and not s['ptr'] and s['actionCleared']
 if n=='Resurrection':return s['phase']==7 and s['gc']==2 and s['resurrected'] and s['appRoot'] and not s['freed'] and s['calls']==1 and s['released'] and not s['ptr']
 if n=='ExplicitReleaseRace':return s['phase']==7 and s['gc']==2 and s['explicitReleased'] and s['explicitDone'] and s['appRoot'] and s['actionCleared'] and s['calls']==1 and s['released'] and not s['ptr']
 if n=='RaceWillWins':return s['phase']==7 and s['gc']==2 and s['explicitDone'] and not s['explicitReleased'] and s['appRoot'] and s['calls']==1 and s['actionCleared'] and s['released'] and not s['ptr']
 if n=='CheckedBridge':return s['phase']==7 and s['context'] and s['vmTouched'] and s['validToken'] and s['calls']==1 and s['released']
 if n=='NoContextRefusal':return s['phase']==8 and s['refused'] and not s['vmTouched'] and not s['accepted'] and s['calls']==0
 if n=='UnknownSweepStop':return s['phase']==9 and s['fatal'] and s['calls']==0 and not s['freed'] and s['ptr']
 return False
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/sweep-finalizer-reachability');out.mkdir(parents=True,exist_ok=True)
  model=R/'models/gambit/sweep_finalizer_context.qnt';code=model.read_text()
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='sweep-finalizer-reachability.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  for suffix,expr in TARGETS.items():
   label='init'+suffix;name='initExplicitReleaseRace' if suffix=='RaceWillWins' else label;case=out/label;case.mkdir();compiled=case/model.name
   projected=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m.group(0) if m.group(1)==name else '',code,flags=re.M)
   observer='  val targetNotReached=not('+expr+')\n';assert projected.endswith('}\n');compiled.write_text(projected[:-2]+observer+'}\n')
   row,log,trace=check(compiled,initializer=name,invariant='targetNotReached',negative=True,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   w=next((x['s'] for x in (trace or {}).get('states',[]) if target(x['s'],suffix)),None)
   row.update(initializer=name,caseName=label,targetLabel=suffix,witness=w,expected='existential-target-reachability-not-liveness',accepted=bool(row['accepted'] and w),projection='unreferenced initializer erasure plus pure target observation; no action edits',observer=observer)
   result['rows'].append(row);result['allAccepted']=len(result['rows'])==len(TARGETS) and all(x['accepted'] for x in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row['seconds'],flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected reachability result')
  print(out,flush=True)
if __name__=='__main__':main()
