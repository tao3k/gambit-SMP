from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
NAMES=['Deferred','Resurrection','InlineNative','NoContextRefusal','CheckedBridge','UnknownRefusal','UnknownSweepStop','ExplicitReleaseRace','StrongCapture','MappedInSweep','FreeQueuedWrapper','CallWithoutContext','RepeatAfterResurrection','RestoreReleasedPointer','DropPendingRoot','RefuseAfterAccess','AcceptUnknown','LateWillConsumption','RaceDoubleInvoke','EraseExternalRoot']
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/sweep-finalizer-context');out.mkdir(parents=True,exist_ok=True)
  model=R/'models/gambit/sweep_finalizer_context.qnt';code=model.read_text()
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='sweep-finalizer-context.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  for i,suffix in enumerate(NAMES):
   name='init'+suffix;case=out/name;case.mkdir();compiled=case/model.name
   compiled.write_text(re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m.group(0) if m.group(1)==name else '',code,flags=re.M))
   row,log,trace=check(compiled,initializer=name,invariant='safe',negative=i>=8,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=8:
    def violated(s):
     return s['calls']>1 or s['captures'] or s['calledWithoutContext'] or (s['released'] and s['ptr']) or (s['refused'] and s['vmTouched']) or (s['jobRoot'] and s['freed']) or (s['eligible'] and not(s['released'] or s['jobRoot'])) or (s['kind']==1 and s['calledInGC']) or (s['kind']==1 and s['calls']>0 and not(s['actionCleared'] or s['explicitReleased'])) or (s['kind']==2 and s['accepted'] and s['mode']!=6) or (s['resurrected'] and (not s['released'] or s['ptr'])) or (s['mode']==7 and s['phase']>=6 and not s['appRoot'])
    witness=next((x['s'] for x in (trace or {}).get('states',[]) if violated(x['s'])),None)
    row['witness']=witness;row['accepted']=bool(row['accepted'] and witness)
   row['initializer']=name;result['rows'].append(row)
   result['allAccepted']=len(result['rows'])==len(NAMES) and all(x['accepted'] for x in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected result')
  print(out,flush=True)
if __name__=='__main__':main()
