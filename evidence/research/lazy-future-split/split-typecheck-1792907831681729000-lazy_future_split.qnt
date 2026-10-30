module lazy_future_split {
// Research abstraction; native issuers and C23 refinement remain open.
type State={phase:int,eligible:int,claims:int,probes:int,childRuns:int,childDone:int,sourceRoot:int,copyRoot:int,ready:int,queueRoot:int,restoreRoot:int,contextRoot:int,resultRoot:int,placeholder:int,materialized:int,split:int,parentOwner:int,prefixRuns:int,parentRuns:int,captured:int,captureRoot:int,exited:int,descriptor:int,gcOpen:int,frozen:int,scanning:int,scanned:int,epoch:int,vSource:int,vCopy:int,vQueue:int,vRestore:int,vContext:int,vResult:int,vCapture:int,resultPublished:int}
pure val initial:State={phase:0,eligible:1,claims:0,probes:0,childRuns:1,childDone:0,sourceRoot:1,copyRoot:0,ready:0,queueRoot:0,restoreRoot:0,contextRoot:0,resultRoot:0,placeholder:0,materialized:0,split:0,parentOwner:0,prefixRuns:0,parentRuns:0,captured:0,captureRoot:0,exited:0,descriptor:1,gcOpen:1,frozen:0,scanning:0,scanned:0,epoch:1,vSource:0,vCopy:0,vQueue:0,vRestore:0,vContext:0,vResult:0,vCapture:0,resultPublished:0}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,
s.phase<=9,
s.eligible>=0,
s.eligible<=1,
s.claims>=0,
s.claims<=1,
s.probes>=0,
s.childRuns>=0,
s.childRuns<=1,
s.childDone>=0,
s.childDone<=1,
s.sourceRoot>=0,
s.sourceRoot<=1,
s.copyRoot>=0,
s.copyRoot<=1,
s.ready>=0,
s.ready<=1,
s.queueRoot>=0,
s.queueRoot<=1,
s.restoreRoot>=0,
s.restoreRoot<=1,
s.contextRoot>=0,
s.contextRoot<=1,
s.resultRoot>=0,
s.resultRoot<=1,
s.placeholder>=0,
s.placeholder<=1,
s.materialized>=0,
s.materialized<=1,
s.split>=0,
s.split<=1,
s.parentOwner>=0,
s.parentOwner<=3,
s.prefixRuns>=0,
s.prefixRuns<=1,
s.parentRuns>=0,
s.captured>=0,
s.captured<=1,
s.captureRoot>=0,
s.captureRoot<=1,
s.exited>=0,
s.exited<=1,
s.descriptor>=0,
s.descriptor<=1,
s.gcOpen>=0,
s.gcOpen<=1,
s.frozen>=0,
s.frozen<=1,
s.scanning>=0,
s.scanning<=1,
s.scanned>=0,
s.scanned<=1,
s.epoch>=0,
s.vSource>=0,
s.vSource<=1,
s.vCopy>=0,
s.vCopy<=1,
s.vQueue>=0,
s.vQueue<=1,
s.vRestore>=0,
s.vRestore<=1,
s.vContext>=0,
s.vContext<=1,
s.vResult>=0,
s.vResult<=1,
s.vCapture>=0,
s.vCapture<=1,
s.resultPublished>=0,
s.resultPublished<=1,
s.epoch>=1,
s.childRuns==1,
(s.phase<=3 or s.phase==6) implies (s.sourceRoot==1),
(s.phase>=1 and s.phase<=5) implies (s.claims==1 and s.eligible==1),
(s.phase==0) implies (s.split==0 and s.ready==0 and s.copyRoot==0 and s.queueRoot==0 and s.parentOwner==0 and s.placeholder==0),
(s.phase==1) implies (s.ready==0 and s.queueRoot==0 and s.split==0),
(s.phase==2) implies (s.copyRoot==1 and s.ready==1 and s.queueRoot==0 and s.split==0),
(s.phase==3) implies (s.copyRoot==1 and s.ready==1 and s.queueRoot==1 and s.split==0),
(s.phase==4) implies (s.copyRoot==1 and s.ready==1 and s.queueRoot==1 and s.split==1 and s.parentOwner==1),
(s.phase==5) implies (s.copyRoot==1 and s.ready==1 and s.queueRoot==0 and s.restoreRoot==1 and s.split==1 and s.parentOwner==2),
(s.phase==6) implies (s.childDone==1 and s.resultRoot==1 and s.split==0 and s.parentOwner==0),
(s.phase==7) implies (s.contextRoot==1 and s.copyRoot==0 and s.restoreRoot==0 and s.queueRoot==0 and s.split==1 and s.parentOwner==3 and s.ready==1),
(s.phase<8) implies (s.descriptor==1),
(s.phase>=8) implies (s.sourceRoot==0 and s.copyRoot==0 and s.queueRoot==0 and s.restoreRoot==0 and s.contextRoot==0 and s.resultRoot==0 and s.captureRoot==0 and s.captured==0 and s.placeholder==0 and s.exited==1),
(s.queueRoot==1) implies (s.phase==3 or s.phase==4),
(s.copyRoot==1) implies (s.placeholder==1 and s.materialized==1 and s.phase>=1 and s.phase<=5),
(s.restoreRoot==1) implies (s.phase==5),
(s.contextRoot==1) implies (s.phase==7),
(s.ready==1) implies (s.phase>=2 and s.phase<=7 and s.phase!=6),
(s.split==1) implies (s.phase>=4 and s.claims==1 and s.materialized==1),
(s.parentOwner>=1) implies (s.split==1),
(s.childDone==1 and s.phase<8) implies (s.resultRoot==1),
(s.resultPublished==1) implies (s.childDone==1 and s.split==1),
(s.parentRuns>=1) implies (s.phase>=6 and s.childDone==1 and s.prefixRuns==1),
(s.parentRuns>=1 and s.split==1) implies (s.resultPublished==1),
(s.captured==1) implies (s.captureRoot==1 and s.parentRuns>=1 and (s.phase==6 or s.phase==7) and s.exited==0),
(s.captureRoot==1) implies (s.captured==1),
(s.phase<6) implies (s.parentRuns==0 and s.prefixRuns==0 and s.captured==0 and s.exited==0),
(s.exited==1) implies (s.parentRuns>=1 and s.captured==0),
(s.materialized==1) implies (s.claims==1),
(s.frozen==1) implies (s.gcOpen==0 and s.sourceRoot==s.vSource and s.copyRoot==s.vCopy and s.queueRoot==s.vQueue and s.restoreRoot==s.vRestore and s.contextRoot==s.vContext and s.resultRoot==s.vResult and s.captureRoot==s.vCapture),
(s.scanning==1) implies (s.frozen==1 and s.scanned==0),
(s.scanned==1) implies (s.frozen==1 and s.scanning==0)}
action denyParallelProfile=all{s.phase==0 and s.claims==0,s'={...s,eligible:0}}
action claimSplit=all{s.phase==0 and s.eligible==1 and s.claims==0 and s.childDone==0 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:1,claims:s.claims+1}}
action failedProbe=all{s.descriptor==1,s'={...s,probes:s.probes+1}}
action allocateCopy=all{s.phase==1 and s.copyRoot==0 and s.gcOpen==1 and s.frozen==0,s'={...s,copyRoot:1,placeholder:1,materialized:1}}
action initializeCopy=all{s.phase==1 and s.copyRoot==1 and s.sourceRoot==1 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:2,ready:1}}
action publishReady=all{s.phase==2 and s.ready==1 and s.copyRoot==1 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:3,queueRoot:1}}
action commitSplit=all{s.phase==3 and s.ready==1 and s.copyRoot==1 and s.queueRoot==1 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:4,sourceRoot:0,split:1,parentOwner:1}}
action abortPrivate=all{(s.phase==1 or s.phase==2) and s.queueRoot==0 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:0,copyRoot:0,placeholder:0,ready:0}}
action localChildDone=all{s.phase==0 and s.childDone==0 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:6,childDone:1,resultRoot:1}}
action localAfterAbortDone=all{s.phase==0 and s.childDone==1 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:6}}
action childDoneInSplit=all{((s.phase>=1 and s.phase<=5) or s.phase==7) and s.childDone==0 and s.gcOpen==1 and s.frozen==0,s'={...s,childDone:1,resultRoot:1}}
action dequeueParent=all{s.phase==4 and s.queueRoot==1 and s.split==1 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:5,queueRoot:0,restoreRoot:1,parentOwner:2}}
action restoreParent=all{s.phase==5 and s.copyRoot==1 and s.restoreRoot==1 and s.ready==1 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:7,contextRoot:1,copyRoot:0,restoreRoot:0,parentOwner:3}}
action publishResult=all{s.split==1 and s.childDone==1 and s.resultRoot==1 and s.resultPublished==0 and s.phase<8 and s.gcOpen==1 and s.frozen==0,s'={...s,resultPublished:1}}
action runParentPrefix=all{s.phase==7 and s.parentOwner==3 and s.prefixRuns==0 and s.gcOpen==1 and s.frozen==0,s'={...s,prefixRuns:1}}
action consumeSplitResult=all{s.phase==7 and s.prefixRuns==1 and s.resultPublished==1 and s.parentRuns==0 and s.gcOpen==1 and s.frozen==0,s'={...s,parentRuns:1}}
action runLocalParent=all{s.phase==6 and s.childDone==1 and s.parentRuns==0 and s.gcOpen==1 and s.frozen==0,s'={...s,prefixRuns:1,parentRuns:1}}
action captureAfterValue=all{(s.phase==6 or s.phase==7) and s.parentRuns>=1 and s.exited==0 and s.gcOpen==1 and s.frozen==0,s'={...s,captured:1,captureRoot:1}}
action restoreAfterValue=all{(s.phase==6 or s.phase==7) and s.captured==1 and s.captureRoot==1 and s.parentRuns>=1 and s.gcOpen==1 and s.frozen==0,s'={...s,parentRuns:s.parentRuns+1}}
action dropCaptured=all{s.captured==1 and s.gcOpen==1 and s.frozen==0,s'={...s,captured:0,captureRoot:0}}
action exitParent=all{(s.phase==6 or s.phase==7) and s.parentRuns>=1 and s.captured==0 and s.gcOpen==1 and s.frozen==0,s'={...s,exited:1}}
action retireTaskRoots=all{(s.phase==6 or s.phase==7) and s.exited==1 and s.captured==0 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:8,sourceRoot:0,copyRoot:0,contextRoot:0,resultRoot:0,placeholder:0,ready:0}}
action retireDescriptor=all{s.phase==8 and s.sourceRoot==0 and s.copyRoot==0 and s.queueRoot==0 and s.restoreRoot==0 and s.contextRoot==0 and s.captureRoot==0 and s.resultRoot==0 and s.gcOpen==1 and s.frozen==0,s'={...s,phase:9,descriptor:0}}
action closeGc=all{s.gcOpen==1,s'={...s,gcOpen:0}}
action freezeRoots=all{s.gcOpen==0 and s.frozen==0,s'={...s,frozen:1,vSource:s.sourceRoot,vCopy:s.copyRoot,vQueue:s.queueRoot,vRestore:s.restoreRoot,vContext:s.contextRoot,vResult:s.resultRoot,vCapture:s.captureRoot}}
action beginScan=all{s.frozen==1 and s.scanning==0 and s.scanned==0,s'={...s,scanning:1}}
action endScan=all{s.scanning==1,s'={...s,scanning:0,scanned:1}}
action resumeGc=all{s.frozen==1 and s.scanning==0 and s.scanned==1,s'={...s,frozen:0,gcOpen:1,scanned:0,epoch:s.epoch+1}}
action step=any{denyParallelProfile,claimSplit,failedProbe,allocateCopy,initializeCopy,publishReady,commitSplit,abortPrivate,localChildDone,localAfterAbortDone,childDoneInSplit,dequeueParent,restoreParent,publishResult,runParentPrefix,consumeSplitResult,runLocalParent,captureAfterValue,restoreAfterValue,dropCaptured,exitParent,retireTaskRoots,retireDescriptor,closeGc,freezeRoots,beginScan,endScan,resumeGc,all{s'=s}}
run localNoMaterializationTest=init.then(localChildDone).then(runLocalParent).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.materialized==0 and s.descriptor==0),s'=s})
run splitTest=init.then(claimSplit).then(allocateCopy).then(initializeCopy).then(publishReady).then(commitSplit).then(dequeueParent).then(restoreParent).then(childDoneInSplit).then(publishResult).then(runParentPrefix).then(consumeSplitResult).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.materialized==1 and s.childRuns==1),s'=s})
run childDoneBeforeCopyTest=init.then(claimSplit).then(childDoneInSplit).then(allocateCopy).then(closeGc).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(initializeCopy).then(publishReady).then(commitSplit).then(publishResult).then(dequeueParent).then(restoreParent).then(runParentPrefix).then(consumeSplitResult).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.childRuns==1),s'=s})
run abortInitializedTest=init.then(claimSplit).then(allocateCopy).then(initializeCopy).then(childDoneInSplit).then(abortPrivate).then(localAfterAbortDone).then(runLocalParent).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.split==0 and s.materialized==1),s'=s})
run denyProfileTest=init.then(denyParallelProfile).then(failedProbe).then(localChildDone).then(runLocalParent).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.claims==0),s'=s})
run gcUnpublishedTest=init.then(claimSplit).then(allocateCopy).then(initializeCopy).then(closeGc).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(publishReady).then(commitSplit).then(closeGc).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(dequeueParent).then(restoreParent).then(childDoneInSplit).then(publishResult).then(runParentPrefix).then(consumeSplitResult).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.epoch==3),s'=s})
run gcDequeuedTest=init.then(claimSplit).then(allocateCopy).then(initializeCopy).then(publishReady).then(commitSplit).then(dequeueParent).then(closeGc).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(restoreParent).then(childDoneInSplit).then(publishResult).then(runParentPrefix).then(consumeSplitResult).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.childRuns==1),s'=s})
run prefixBeforeChildTest=init.then(claimSplit).then(allocateCopy).then(initializeCopy).then(publishReady).then(commitSplit).then(dequeueParent).then(restoreParent).then(runParentPrefix).then(childDoneInSplit).then(publishResult).then(consumeSplitResult).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.parentRuns==1),s'=s})
run repeatAfterValueTest=init.then(claimSplit).then(allocateCopy).then(initializeCopy).then(publishReady).then(commitSplit).then(dequeueParent).then(restoreParent).then(childDoneInSplit).then(publishResult).then(runParentPrefix).then(consumeSplitResult).then(captureAfterValue).then(restoreAfterValue).then(restoreAfterValue).then(closeGc).then(freezeRoots).then(beginScan).then(endScan).then(resumeGc).then(dropCaptured).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.parentRuns==3 and s.childRuns==1),s'=s})
run localCaptureTest=init.then(localChildDone).then(runLocalParent).then(captureAfterValue).then(restoreAfterValue).then(dropCaptured).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.materialized==0 and s.parentRuns==2),s'=s})
run abortBeforeAllocationTest=init.then(claimSplit).then(abortPrivate).then(localChildDone).then(runLocalParent).then(exitParent).then(retireTaskRoots).then(retireDescriptor).then(all{assert(safe and s.claims==1 and s.materialized==0),s'=s})
}
