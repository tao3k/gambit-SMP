module stable_copy_publication {
 import stable_copy_parameters.* from "./stable_copy_parameters"
 // Two abstract payload fields expose torn-copy and capture/publication races.
 type State={phase:int,immutable:bool,sourceGen:int,sourceA:int,sourceB:int,writing:bool,
  locked:bool,sourcePin:bool,destPin:bool,lease:bool,capturedGen:int,capturedA:int,capturedB:int,
  copyA:int,copyB:int,copyReceipt:bool,validated:bool,tainted:bool,admit:bool,retired:bool,
  published:bool,resultGen:int,savedContinuation:bool,workspace:int}
 pure val initial:State={phase:0,immutable:false,sourceGen:0,sourceA:0,sourceB:0,writing:false,
  locked:false,sourcePin:false,destPin:false,lease:false,capturedGen:-1,capturedA:-1,capturedB:-1,
  copyA:-1,copyB:-1,copyReceipt:false,validated:false,tainted:false,admit:true,retired:false,
  published:false,resultGen:-1,savedContinuation:false,workspace:0}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,workspace:WorkspaceCount-1}
 action useImmutable=all {s.phase==0,s'={...s,immutable:true}}
 action beginWrite=all {not(s.locked),not(s.writing),s.sourceGen==0,
  s'={...s,writing:true,sourceA:1}}
 action finishWrite=all {s.writing,s'={...s,writing:false,sourceB:1,sourceGen:1}}
 action acquire=all {s.phase==0,s.admit,not(s.writing),not(s.tainted),
  s'={...s,phase:1,locked:not(s.immutable),sourcePin:true,destPin:true,lease:true,
   capturedGen:s.sourceGen,capturedA:s.sourceA,capturedB:s.sourceB}}
 action copyHead=all {s.phase==1,s.sourcePin,
  s'={...s,phase:2,copyA:if(s.immutable) s.capturedA else s.sourceA}}
 action copyTail=all {s.phase==2,s.sourcePin,
  s'={...s,phase:3,copyB:if(s.immutable) s.capturedB else s.sourceB,copyReceipt:true}}
 action releaseSource=all {s.phase>=3,s.copyReceipt,s'={...s,locked:false,sourcePin:false}}
 action validateCopy=all {s.phase==3,s.copyReceipt,not(s.tainted),s.destPin,
  s.copyA==s.capturedA,s.copyB==s.capturedB,s'={...s,phase:4,validated:true}}
 action publishResult=all {s.phase==4,s.validated,not(s.tainted),s.lease,s.destPin,
  s'={...s,phase:5,published:true,resultGen:s.capturedGen}}
 action retire=all {not(s.retired),s'={...s,admit:false,retired:true}}
 action taint=all {not(s.published),s'={...s,admit:false,retired:true,tainted:true}}
 action saveContinuation=all {s.lease,s.phase<5,s'={...s,savedContinuation:true}}
 action retireContinuation=all {s.savedContinuation,s'={...s,savedContinuation:false}}
 action abortAttempt=all {s.phase>0,s.phase<5,s'={...s,phase:6,locked:false,copyReceipt:false,validated:false}}
 action drain=all {(s.phase==5 or s.phase==6),not(s.savedContinuation),
  s'={...s,sourcePin:false,destPin:false,lease:false,locked:false}}
 def safe=(s.locked implies s.sourcePin and s.lease and not(s.writing)) and
  (s.phase==1 or s.phase==2 implies s.sourcePin and s.destPin and s.lease) and
  (s.savedContinuation implies s.sourcePin or s.destPin) and
  (s.copyReceipt implies s.copyA==s.capturedA and s.copyB==s.capturedB) and
  (s.published implies s.validated and not(s.tainted) and s.resultGen==s.capturedGen and
    s.copyA==s.capturedA and s.copyB==s.capturedB and s.copyA==s.copyB)
 action step=any {useImmutable,beginWrite,finishWrite,acquire,copyHead,copyTail,releaseSource,validateCopy,publishResult,
  retire,taint,saveContinuation,retireContinuation,abortAttempt,drain,s'=s}
 action rawAliasWrite=s'={...s,sourceA:1,sourceB:1,sourceGen:1}
 action dropReadGuard=s'={...s,locked:false,sourcePin:false}
 action forceReceipt=s'={...s,copyReceipt:true}
 action forcePublish=s'={...s,published:true,resultGen:s.sourceGen}
 action rekey=s'={...s,resultGen:s.sourceGen}
 action loseRoots=s'={...s,sourcePin:false,destPin:false}
 action staleResume=s'={...s,published:true,resultGen:s.capturedGen}
 run exclusiveCopyTest=init.then(acquire).then(copyHead).then(copyTail).then(validateCopy).then(publishResult).expect(safe)
 run immutableConcurrentTest=init.then(useImmutable).then(acquire).then(copyHead).then(beginWrite).then(finishWrite).then(copyTail).then(validateCopy).then(publishResult).expect(safe and s.resultGen==0 and s.sourceGen==1)
 run releaseBeforePublishTest=init.then(acquire).then(copyHead).then(copyTail).then(releaseSource).then(beginWrite).then(finishWrite).then(validateCopy).then(publishResult).expect(safe and s.resultGen==0)
 run afterWriteTest=init.then(beginWrite).then(finishWrite).then(acquire).then(copyHead).then(copyTail).then(validateCopy).then(publishResult).expect(safe and s.resultGen==1)
 run retireDrainsTest=init.then(acquire).then(retire).then(copyHead).then(copyTail).then(validateCopy).then(publishResult).then(drain).expect(safe and not(s.lease))
 run taintAbortTest=init.then(acquire).then(taint).then(abortAttempt).then(drain).expect(safe and not(s.published))
 run continuationCustodyTest=init.then(acquire).then(saveContinuation).then(abortAttempt).expect(safe and s.sourcePin and s.destPin)
 run continuationRetireTest=init.then(acquire).then(saveContinuation).then(abortAttempt).then(retireContinuation).then(drain).expect(safe and not(s.lease))
 run otherContextTest=initOther.then(acquire).then(copyHead).then(copyTail).then(validateCopy).then(publishResult).expect(safe and s.workspace==1)
 run privateValidationTest=init.then(acquire).then(copyHead).then(copyTail).then(releaseSource).then(validateCopy).expect(safe and not(s.sourcePin) and s.destPin)
 run tornAliasControlTest=init.then(acquire).then(copyHead).then(rawAliasWrite).then(copyTail).expect(not(safe))
 run guardGapControlTest=init.then(acquire).then(dropReadGuard).expect(not(safe))
 run partialReceiptControlTest=init.then(acquire).then(copyHead).then(forceReceipt).expect(not(safe))
 run taintedPublishControlTest=init.then(acquire).then(copyHead).then(copyTail).then(validateCopy).then(taint).then(forcePublish).expect(not(safe))
 run rekeyControlTest=init.then(acquire).then(copyHead).then(copyTail).then(releaseSource).then(beginWrite).then(finishWrite).then(validateCopy).then(publishResult).then(rekey).expect(not(safe))
 run earlyRootsControlTest=init.then(acquire).then(saveContinuation).then(abortAttempt).then(loseRoots).expect(not(safe))
 run staleContinuationControlTest=init.then(acquire).then(saveContinuation).then(abortAttempt).then(staleResume).expect(not(safe))
 run prevalidationPublishControlTest=init.then(acquire).then(copyHead).then(copyTail).then(forcePublish).expect(not(safe))
}
