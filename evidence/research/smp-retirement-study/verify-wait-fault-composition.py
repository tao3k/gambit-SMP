from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import execute,available_processors
from gambit_smp.quint_backend import check
r=Path.cwd();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
names=['initDevices', 'initIdle', 'initJobsFail', 'initWorkerFault', 'initOpaqueRetain', 'initJoinFailureRetain', 'initNativeCloseFailureRetain', 'initNoPrearmedReturn', 'initEarlyDeviceTimer', 'initOverwriteDeadline', 'initPStillLocked', 'initUnregisteredCarrier', 'initDuplicateCoordinator', 'initWrongProcessor', 'initRecordUnrooted', 'initGcStaleFrame', 'initShrinkBeforeGc', 'initDropPrivateWork', 'initLoseExitSuffix', 'initLoseCaughtError', 'initStaleWaitAck', 'initKillReturnableMarker', 'initFreeWithWriter', 'initOpaqueFakeExit', 'initStaleCaughtError', 'initNoPrivateHandoffWitness', 'initFreeDeviceGroupEarly']
def main():
 with work_process.scope(r,'repair-9-12','audit'):
  out=workspace.task_output(r,r/'.cache/wait-fault-composition-checks');out.mkdir(parents=True,exist_ok=True)
  rc,holders,to,_=execute(['/usr/sbin/lsof','-nP',str(r/'.state/tasks/repair-9-12.lock')],out,30)
  result=dict(schema='wait-fault-composition-validation.v1',verificationLaunched=False,allAccepted=None,rows=[],trajectories=[],lockObservation=holders,sourceRefinement=False,runtimeModified=False,nativeExecuted=False)
  result['modelOnlyDuringProductionAuthorized']=True
  result['productionCustodyUnchanged']=True
  if to or rc not in (0,1):result['status']='lock-observation-unavailable'
  else:
   result['verificationLaunched']=True;model=out/'wait_fault_exit_composition.qnt';model.write_bytes((r/'models/gambit/wait_fault_exit_composition.qnt').read_bytes())
   cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
   for i,n in enumerate(names):
    case=out/n;case.mkdir()
    row,log,trace=check(model,initializer=n,invariant='safe',negative=i>=7,temporal='completion' if i<4 else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
    if i>=7:
     predicates={
      1:lambda s:s['phase']==2 and s['fault'] and not s['armed'],
      2:lambda s:s['timerReady'] and s['internalExpired'],
      3:lambda s:s['deviceDeadline']!=s['originalDeadline'],
      4:lambda s:s['claims']>0 and s['pLock'],
      5:lambda s:(s['controlQueued'] or s['mapped']) and not s['registered'],
      6:lambda s:s['claims']>1,
      7:lambda s:s['mapped'] and not s['p0'],
      8:lambda s:s['phase']>=7 and s['requests']>0 and not s['vmRoot'],
      9:lambda s:s['mapped'] and s['frameEpoch']!=s['gc'],
      10:lambda s:s['phase']==9 and s['oldCohort']!=2,
      11:lambda s:s['phase']==9 and not s['privateWork'],
      12:lambda s:s['phase']>=10 and not s['suffixRoot'],
      13:lambda s:s['jobsFailed'] and not s['errorRoot'],
      14:lambda s:s['claims']>0 and s['ackInstance']!=s['waitInstance'],
      15:lambda s:s['markers']==3 and s['phase']<13,
      16:lambda s:s['freed'] and s['writer'],
      17:lambda s:s['bad'] and s['rawOpaque'],
      18:lambda s:s['jobsFailed'] and s['errorEpoch']!=s['gc'],
      19:lambda s:s['oldCohort']==1 and not s['handoffWitness'],
      20:lambda s:s['pendingDevices']>0 and not s['deviceGroupOwned']}
     witness=next((z['s'] for z in reversed((trace or {}).get('states',[])) if predicates[z['s']['bug']](z['s'])),None)
     row['distinguishingWitness']=witness;row['accepted']=row['accepted'] and witness is not None
    row.update(check=n,modelSha256=h(model),negative=i>=7);result['rows'].append(row)
    (case/'checker.log').write_text(log);(case/'receipt.json').write_text(json.dumps(dict(row,trace=trace),indent=2)+'\n');print(n,row['accepted'],flush=True)
    if not row['accepted']:break
   if len(result['rows'])==27 and all(x['accepted'] for x in result['rows']):
    tests=out/'wait_fault_exit_composition_tests.qnt';tests.write_bytes((r/'models/gambit/wait_fault_exit_composition_tests.qnt').read_bytes())
    for name in re.findall(r' run (\w+)=',tests.read_text()):
     rc,log,to,sec=execute(['/opt/homebrew/bin/quint','test',str(tests),'--backend','typescript','--match',name],out,30)
     row=dict(check=name,accepted=rc==0 and not to and '1 passing' in log,exit=rc,timeout=to,seconds=sec,testsSha256=h(tests));result['trajectories'].append(row);(out/(name+'.log')).write_text(log)
     if not row['accepted']:break
   result['allAccepted']=len(result['rows'])==27 and all(x['accepted'] for x in result['rows']) and len(result['trajectories'])==8 and all(x['accepted'] for x in result['trajectories']);result['status']='checked'
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print('OUTPUT',out,'STATUS',result['status'],flush=True)
if __name__=='__main__':main()
