from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors,execute
from gambit_smp.quint_backend import check
r=Path.cwd();h=lambda b:hashlib.sha256(b).hexdigest()
adm=['initLive','initTlsRefusal','initStaleRefusal','initClosingRefusal','initAcceptedWakeFault','initTlsAsOwner','initCurrentEpochInsteadOfExpected','initTouchBeforeReject','initRejectAfterCommit','initRetryAfterCommit','initDropOuterPin','initForeignOwner','initScmRefusal','initScmRooted','initUnrootedScmCommit']
disp=['initCallbackSuccess','initCallbackError','initPendingCleanup','initAuthorizedTargetEnd','initAcceptedHardFault','initDoubleUnlock','initReleaseUnderMutex','initReleaseActive','initReplayError','initReleaseExecuted','initWrongTargetEnd','initFakeAbandon','initUnrootedEnd','initMovingErrorStored','initMovingErrorNormalized','initPrimordialRetained','initFakePrimordialAbandon','initReentrantDetachedCleanup']
positives=set(adm[:5]+disp[:5]+['initMovingErrorNormalized','initPrimordialRetained','initForeignOwner','initScmRefusal','initScmRooted','initReentrantDetachedCleanup']);onlySafety={'initAcceptedWakeFault','initAcceptedHardFault','initPrimordialRetained'}
def main():
 with work_process.scope(r,'repair-9-12','audit'):
  out=workspace.task_output(r,r/'.cache/external-c-model-checks');out.mkdir(parents=True,exist_ok=True);cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')));rows=[]
  rc,holders,to,sec=execute(['/usr/sbin/lsof','-nP',str(r/'.state/tasks/repair-9-12.lock')],out,30)
  if rc!=1 or to or holders.strip():
   (out/'receipt.json').write_text(json.dumps(dict(schema='external-c-model-validation.v1',status='waiting-for-production-custody',verificationLaunched=False,allAccepted=None,rows=[],trajectories=[],lockObservation=holders,sourceRefinement=False,nativeExecuted=False,runtimeModified=False,nativeAdmitted=False),indent=2)+'\n')
   print('OUTPUT',out,'STATUS waiting-for-production-custody',flush=True)
   return
  for fname,module,names in [('external-interrupt-admission','external_interrupt_admission',adm),('interrupt-fault-disposition','interrupt_fault_disposition',disp)]:
   model=out/(module+'.qnt');model.write_bytes((r/'models/gambit'/(module+'.qnt')).read_bytes())
   for n in names:
    neg=n not in positives;case=out/n;case.mkdir();row,log,trace=check(model,initializer=n,invariant='safe',negative=neg,temporal=None if neg or n in onlySafety else 'completion',timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
    if neg:
     predicates={'initTlsAsOwner':lambda z:z['unsafeDereference'],'initCurrentEpochInsteadOfExpected':lambda z:z['wrongInstance'],'initTouchBeforeReject':lambda z:z['status']==1 and z['link']!=7,'initRejectAfterCommit':lambda z:z['accepted'] and z['status']==1,'initRetryAfterCommit':lambda z:z['enqueues']==2,'initDropOuterPin':lambda z:z['instancePin'] and not z['vmPin'],'initUnrootedScmCommit':lambda z:z['unsafeScmAccess'],'initDoubleUnlock':lambda z:z['badUnlock'],'initReleaseUnderMutex':lambda z:z['callbackUnderLock'],'initReleaseActive':lambda z:z['activeBorrow'] and z['owner']!=2,'initReplayError':lambda z:z['executions']==2,'initReleaseExecuted':lambda z:z['executions']==1 and z['releases']==1,'initWrongTargetEnd':lambda z:z['wrongTerminal'],'initFakeAbandon':lambda z:z['reply']==2 and not z['ended'],'initUnrootedEnd':lambda z:z['kind']==1 and z['activeBorrow'] and not z['root'],'initMovingErrorStored':lambda z:z['rawErrorStored'] and not z['errorImmediate'],'initFakePrimordialAbandon':lambda z:z['reply']==2 and not z['nonPrimordial']}
     w=next((z['s'] for z in reversed((trace or {}).get('states',[])) if predicates[n](z['s'])),None);row['distinguishingWitness']=w;row['accepted']=row['accepted'] and w is not None
    row.update(check=n,model=model.name,modelSha256=h(model.read_bytes()),negative=neg,safetyOnly=n in onlySafety);rows.append(row);(case/'checker.log').write_text(log);(case/'receipt.json').write_text(json.dumps(dict(row,trace=trace),indent=2)+'\n');print(n,row['accepted'],row.get('states'),flush=True)
    if not row['accepted']:print(log[-1800:],flush=True);break
   if not rows[-1]['accepted']:break
  trajRows=[]
  if len(rows)==33 and all(z['accepted'] for z in rows):
   for tn in ['external_interrupt_admission_tests','interrupt_fault_disposition_tests']:
    tests=out/(tn+'.qnt');tests.write_bytes((r/'models/gambit'/(tn+'.qnt')).read_bytes())
    for n in re.findall(r' run (\w+)=',tests.read_text()):
     rc,log,to,sec=execute(['/opt/homebrew/bin/quint','test',str(tests),'--backend','typescript','--match',n],out,30)
     row=dict(check=n,accepted=rc==0 and not to and '1 passing' in log,exit=rc,timeout=to,seconds=sec,testsSha256=h(tests.read_bytes()))
     trajRows.append(row);(out/(n+'.log')).write_text(log);print(n,row['accepted'],flush=True)
     if not row['accepted']:break
    if not trajRows[-1]['accepted']:break
  (out/'receipt.json').write_text(json.dumps(dict(schema='external-c-model-validation.v1',verificationLaunched=True,rows=rows,trajectories=trajRows,allAccepted=len(rows)==33 and all(z['accepted'] for z in rows) and len(trajRows)==11 and all(z['accepted'] for z in trajRows),budgetSecondsPerCheck=30,sourceRefinement=False,nativeExecuted=False,runtimeModified=False,nativeAdmitted=False),indent=2)+'\n');print('OUTPUT',out,flush=True)

if __name__=='__main__':main()
