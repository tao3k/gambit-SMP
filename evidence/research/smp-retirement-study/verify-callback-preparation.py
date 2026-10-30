from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
NAMES=['Normal','NestedEscape','UnknownRetained','PartialRetry','RootAfterDetach','NestedOverwrite','ReplayConsumed','EscapedContinuation','DropOnUnknown','GcStaleRoot','DropBeforeGrace','RepeatP0','CallbackInDestroy','CallbackUnderLock']
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/callback-preparation');out.mkdir(parents=True,exist_ok=True)
  model=R/'models/gambit/callback_preparation.qnt';code=model.read_text()
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='callback-preparation.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  for i,suffix in enumerate(NAMES):
   name='init'+suffix;case=out/name;case.mkdir();compiled=case/model.name
   compiled.write_text(re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m.group(0) if m.group(1)==name else '',code,flags=re.M))
   row,log,trace=check(compiled,initializer=name,invariant='safe',negative=i>=4,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=4:
    def violated(s):
     return s['calls1']>1 or s['calls2']>1 or s['staleExecuted'] or s['p0']>1 or s['vm']>1 or (s['phase']==3 and s['p0']!=1) or (s['j1'] in [1,2] and not(s['root1'] and s['carrier'] and s['owner'])) or (s['j2'] not in [0,3] and not(s['root2'] and s['carrier'] and s['owner'])) or (s['root1'] and s['v1']!=s['gc']) or (s['root2'] and s['v2']!=s['gc']) or (s['reader']==1 and not s['carrier']) or ((s['j1']==2 or s['j2']==2) and (s['phase']!=0 or s['locked'])) or (s['unknown'] and not s['owner']) or (s['phase']>=1 and (s['j1']!=3 or s['j2']!=3))
    witness=next((x['s'] for x in (trace or {}).get('states',[]) if violated(x['s'])),None)
    row['witness']=witness;row['accepted']=bool(row['accepted'] and witness)
   row['initializer']=name;result['rows'].append(row)
   result['allAccepted']=len(result['rows'])==len(NAMES) and all(x['accepted'] for x in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected result')
  print(out,flush=True)
if __name__=='__main__':main()
