from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
NAMES=['Normal','Escape','Retained','QueueGap','HandlerRelease','OuterEarly','MissingWriteback','LockedCallback','PostReleaseAccess','DuplicateP0','EscapeDrop','DestructorCallback']
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/async-destruction-composition');out.mkdir(parents=True,exist_ok=True)
  model=R/'models/gambit/async_destruction_composition.qnt';code=model.read_text()
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='async-destruction-composition.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  for i,suffix in enumerate(NAMES):
   name='init'+suffix;case=out/name;case.mkdir();compiled=case/model.name
   compiled.write_text(re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m.group(0) if m.group(1)==name else '',code,flags=re.M))
   row,log,trace=check(compiled,initializer=name,invariant='safe',negative=i>=3,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=3:
    def violated(s):
     owners=sum(int(s[k]) for k in ['producer','outer','queued','handler','reply'])
     return s['units']!=owners or s['units']<0 or (s['tail'] and not s['outer']) or ((s['queued'] or s['handler'] or s['reply']) and s['rootVersion']!=s['gc']) or (s['handler'] and (s['locked'] or s['destroying'])) or (s['destroying'] and s['units']!=0) or (s['freed'] and s['units']!=0) or s['postFreeAccess'] or s['pstateDestructs']>1 or s['vmDestructs']>1
    witness=next((x['s'] for x in (trace or {}).get('states',[]) if violated(x['s'])),None)
    row['witness']=witness;row['accepted']=bool(row['accepted'] and witness)
   row['initializer']=name;result['rows'].append(row)
   result['allAccepted']=len(result['rows'])==len(NAMES) and all(x['accepted'] for x in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected result')
  print(out,flush=True)
if __name__=='__main__':main()
