from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import execute,available_processors
from gambit_smp.quint_backend import check

root=Path.cwd()
names=['initCallbackError','initOrdinaryEnd','initVmLanding','initJobsFailureLanding','initHardWakeRetained','initClearRemainingDebt','initReplayExecuted','initPrimordialFakeAbandon','initLostJobSuffix','initEarlyFdClose','initEarlyMarkerKill','initFailedCleanupFrees','initDropActiveRoot']
def main():
 with work_process.scope(root,'repair-9-12','audit'):
  out=workspace.task_output(root,root/'.cache/accepted-terminal-checks');out.mkdir(parents=True,exist_ok=True)
  rc,holders,to,_=execute(['/usr/sbin/lsof','-nP',str(root/'.state/tasks/repair-9-12.lock')],out,30)
  receipt=dict(schema='accepted-terminal-checks.v1',verificationLaunched=False,allAccepted=None,rows=[],lockObservation=holders,nativeExecuted=False,runtimeModified=False,sourceRefinement=False)
  if rc!=1 or to or holders.strip():
   receipt['status']='waiting-for-production-custody'
  else:
   receipt['verificationLaunched']=True
   model=out/'accepted_interrupt_terminal.qnt';model.write_bytes((root/'models/gambit/accepted_interrupt_terminal.qnt').read_bytes())
   cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
   for i,n in enumerate(names):
    case=out/n;case.mkdir()
    row,log,trace=check(model,initializer=n,invariant='safe',negative=i>=5,temporal='completion' if i<4 else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
    row.update(check=n,modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),safetyOnly=i==4)
    if i>=5:
     predicates={5:lambda s:s['queue']>0 and not s['debt'],6:lambda s:s['executed']>2,7:lambda s:s['reply']==2 and s['mode']!=1,8:lambda s:s['bad'] and not s['suffix'],9:lambda s:not s['fdOpen'] and s['borrow'],10:lambda s:not s['markerLive'] and not s['nonreturnable'],11:lambda s:s['rawExit'] and s['queue']>0,12:lambda s:s['borrow'] and not s['root']}
     witness=next((z['s'] for z in reversed((trace or {}).get('states',[])) if predicates[i](z['s'])),None)
     row['distinguishingWitness']=witness;row['accepted']=row['accepted'] and witness is not None
    (case/'checker.log').write_text(log);(case/'receipt.json').write_text(json.dumps(dict(row,trace=trace),indent=2)+'\n')
    receipt['rows'].append(row);print(n,row['accepted'],flush=True)
    if not row['accepted']:break
   receipt['allAccepted']=len(receipt['rows'])==13 and all(r['accepted'] for r in receipt['rows'])
   receipt['status']='checked'
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print('OUTPUT',out,'STATUS',receipt['status'],flush=True)
if __name__=='__main__':main()
