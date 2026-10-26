from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import execute,available_processors
from gambit_smp.quint_backend import check
r=Path.cwd();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
names=['initSlice','initAtomicSignal','initSpareChannel','initAuthorizedDisposition','initFaultOnlySlice','initSignalBeforePlainSelect','initEarlyDeviceTimeout','initDispatchWithProcessorLock','initStaleAcknowledgment','initCloseBeforeWriter','initClearFaultBeforeObservation','initUnrootedFaultObserver','initFakeCompletion','initSpareAlsoBroken']
def main():
 with work_process.scope(r,'repair-9-12','audit'):
  out=workspace.task_output(r,r/'.cache/independent-wake-checks');out.mkdir(parents=True,exist_ok=True)
  rc,holders,to,_=execute(['/usr/sbin/lsof','-nP',str(r/'.state/tasks/repair-9-12.lock')],out,30)
  result=dict(schema='independent-wake-validation.v1',verificationLaunched=False,allAccepted=None,rows=[],trajectories=[],lockObservation=holders,sourceRefinement=False,runtimeModified=False,nativeExecuted=False)
  if rc!=1 or to or holders.strip():result['status']='waiting-for-production-custody'
  else:
   result['verificationLaunched']=True;model=out/'independent_wake_return.qnt';model.write_bytes((r/'models/gambit/independent_wake_return.qnt').read_bytes())
   cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
   for i,n in enumerate(names):
    case=out/n;case.mkdir()
    row,log,trace=check(model,initializer=n,invariant='safe',negative=i>=4,temporal='observation' if i<4 else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
    if i>=4:
     def stranded(s):return s['parked'] and s['fault'] and not s['armed'] and not s['signal'] and not(s['carrier']==3 and s['bug']!=11)
     predicates={4:stranded,5:stranded,6:lambda s:s['timerReady'] and not s['realDeadline'],7:lambda s:s['reported'] and s['pLock'],8:lambda s:s['acked'] and s['ackInstance']!=s['instance'],9:lambda s:not s['fdOpen'] and s['writer'],10:lambda s:s['bad'] and not s['fault'],11:lambda s:s['observed'] and not s['root'],12:lambda s:s['completed'] and not s['terminalAuthorized'],13:stranded}
     witness=next((z['s'] for z in reversed((trace or {}).get('states',[])) if predicates[i](z['s'])),None)
     row['distinguishingWitness']=witness;row['accepted']=row['accepted'] and witness is not None
    row.update(check=n,modelSha256=h(model),negative=i>=4);result['rows'].append(row)
    (case/'checker.log').write_text(log);(case/'receipt.json').write_text(json.dumps(dict(row,trace=trace),indent=2)+'\n');print(n,row['accepted'],flush=True)
    if not row['accepted']:break
   if len(result['rows'])==14 and all(x['accepted'] for x in result['rows']):
    tests=out/'independent_wake_return_tests.qnt';tests.write_bytes((r/'models/gambit/independent_wake_return_tests.qnt').read_bytes())
    for name in re.findall(r' run (\w+)=',tests.read_text()):
     rc,log,to,sec=execute(['/opt/homebrew/bin/quint','test',str(tests),'--backend','typescript','--match',name],out,30)
     row=dict(check=name,accepted=rc==0 and not to and '1 passing' in log,exit=rc,timeout=to,seconds=sec,testsSha256=h(tests));result['trajectories'].append(row);(out/(name+'.log')).write_text(log)
     if not row['accepted']:break
   result['allAccepted']=len(result['rows'])==14 and all(x['accepted'] for x in result['rows']) and len(result['trajectories'])==5 and all(x['accepted'] for x in result['trajectories']);result['status']='checked'
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print('OUTPUT',out,'STATUS',result['status'],flush=True)
if __name__=='__main__':main()
