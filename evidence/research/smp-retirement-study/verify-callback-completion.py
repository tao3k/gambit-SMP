from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/callback-preparation-completion');out.mkdir(parents=True,exist_ok=True)
  model=R/'models/gambit/callback_preparation.qnt';code=model.read_text()
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='callback-preparation-reachability.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  observer='  val targetNotReached=not(s.phase==3 and s.gc==2 and s.reader==2)\n'
  for suffix in ['Normal','PartialRetry']:
   name='init'+suffix;case=out/name;case.mkdir();compiled=case/model.name
   projected=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m.group(0) if m.group(1)==name else '',code,flags=re.M)
   assert projected.endswith('}\n');compiled.write_text(projected[:-2]+observer+'}\n')
   row,log,trace=check(compiled,initializer=name,invariant='targetNotReached',negative=True,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   w=next((x['s'] for x in (trace or {}).get('states',[]) if x['s']['phase']==3 and x['s']['gc']==2 and x['s']['reader']==2 and x['s']['calls1']==1 and x['s']['calls2']==1 and x['s']['p0']==1 and x['s']['vm']==1 and not x['s']['owner'] and not x['s']['carrier'] and (suffix!='PartialRetry' or x['s']['retried'])),None)
   row.update(initializer=name,witness=w,expected='reachable-completion-after-two-GCs-and-reader-grace',accepted=bool(row['accepted'] and w),projection='unreferenced initializer erasure plus pure target observation; no action edits',observer=observer)
   result['rows'].append(row);result['allAccepted']=len(result['rows'])==2 and all(x['accepted'] for x in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row['seconds'],flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected reachability result')
  print(out,flush=True)
if __name__=='__main__':main()
