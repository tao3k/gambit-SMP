module future_frame_commit {
// Research abstraction; native issuers and C23 refinement remain open.
type State={decision:int,claims:int,done:int,resultRoot:int,sourceRoot:int,destRoot:int,childRoot:int,copyReady:int,copyRev:int,viewRev:int,viewGen:int,viewLease:int,patchReady:int,patchRev:int,patchGen:int,patchLease:int,gate:int,admitted:int,generation:int,grantGen:int,lease:int,revision:int,sourceHeap:int,localGrants:int,remoteGrants:int,copyOps:int,validations:int,probes:int}
pure val initial:State={decision:0,claims:0,done:0,resultRoot:0,sourceRoot:1,destRoot:0,childRoot:1,copyReady:0,copyRev:0,viewRev:0,viewGen:0,viewLease:0,patchReady:0,patchRev:0,patchGen:0,patchLease:0,gate:0,admitted:1,generation:1,grantGen:0,lease:0,revision:0,sourceHeap:0,localGrants:0,remoteGrants:0,copyOps:0,validations:0,probes:0}
var s:State
action init=s'=initial
val safe=all{s.decision>=0,
s.decision<=3,
s.claims>=0,
s.claims<=1,
s.done>=0,
s.done<=1,
s.resultRoot>=0,
s.resultRoot<=1,
s.sourceRoot>=0,
s.sourceRoot<=1,
s.destRoot>=0,
s.destRoot<=1,
s.childRoot>=0,
s.childRoot<=1,
s.copyReady>=0,
s.copyReady<=1,
s.copyRev>=0,
s.viewRev>=0,
s.viewGen>=0,
s.viewLease>=0,
s.patchReady>=0,
s.patchReady<=1,
s.patchRev>=0,
s.patchGen>=0,
s.patchLease>=0,
s.gate>=0,
s.gate<=2,
s.admitted>=0,
s.admitted<=1,
s.generation>=0,
s.grantGen>=0,
s.lease>=0,
s.revision>=0,
s.sourceHeap>=0,
s.sourceHeap<=1,
s.localGrants>=0,
s.localGrants<=1,
s.remoteGrants>=0,
s.remoteGrants<=1,
s.copyOps>=0,
s.validations>=0,
s.probes>=0,
s.copyOps<=1,
(s.copyOps==1) implies (s.copyReady==1 or s.decision==3),
s.generation>=1,
s.viewRev<=s.revision,
s.copyRev<=s.revision,
s.patchRev<=s.revision,
s.viewGen<=s.generation,
s.patchGen<=s.generation,
s.grantGen<=s.generation,
s.viewLease<=s.lease,
s.patchLease<=s.lease,
s.childRoot==1,
s.sourceRoot+s.destRoot>=1,
s.localGrants+s.remoteGrants<=1,
(s.done==1) implies (s.resultRoot==1),
(s.resultRoot==1) implies (s.done==1),
(s.decision==0) implies (s.claims==0 and s.sourceRoot==1 and s.destRoot==0 and s.copyReady==0 and s.localGrants==0 and s.remoteGrants==0),
(s.decision==1) implies (s.claims==1 and s.sourceRoot==1 and s.localGrants==0 and s.remoteGrants==0),
(s.decision==2) implies (s.claims==1 and s.sourceRoot==0 and s.destRoot==1 and s.copyReady==1 and s.localGrants==0),
(s.decision==3) implies (s.sourceRoot==1 and s.destRoot==0 and s.copyReady==0 and s.remoteGrants==0),
(s.copyReady==1) implies (s.destRoot==1 and (s.decision==1 or s.decision==2) and s.copyRev==s.revision),
(s.destRoot==1) implies (s.claims==1 and (s.decision==1 or s.decision==2)),
(s.localGrants==1) implies (s.decision==3 and s.done==1 and s.resultRoot==1),
(s.remoteGrants==1) implies (s.decision==2 and s.done==1 and s.resultRoot==1),
(s.gate>=1) implies (s.grantGen==s.generation),
(s.gate==1) implies (s.lease>=1),
(s.patchReady==1) implies (s.copyReady==1 and s.destRoot==1),
(s.copyOps==0) implies (s.copyReady==0 and s.patchReady==0)}
action reserveSplit=all{s.decision==0 and s.done==0 and s.admitted==1,s'={...s,decision:1,claims:s.claims+1}}
action childDone=all{s.done==0 and s.gate!=2,s'={...s,done:1,resultRoot:1}}
action closeLocal=all{s.decision==0 and s.done==1 and s.gate==0,s'={...s,decision:3}}
action allocateRootedCopy=all{s.decision==1 and s.destRoot==0 and s.gate==0 and s.admitted==1,s'={...s,destRoot:1}}
action enterRuntime=all{s.gate==0 and s.admitted==1 and s.decision>=1,s'={...s,gate:1,lease:s.lease+1,grantGen:s.generation}}
action resolveCanonical=all{s.gate==1 and s.grantGen==s.generation,s'={...s,viewRev:s.revision,viewGen:s.generation,viewLease:s.lease}}
action initializeCopy=all{s.decision==1 and s.destRoot==1 and s.copyReady==0 and s.sourceRoot==1 and s.gate==1 and s.grantGen==s.generation and s.viewGen==s.generation and s.viewLease==s.lease and s.viewRev==s.revision,s'={...s,copyReady:1,copyRev:s.revision,copyOps:s.copyOps+1,patchReady:0}}
action validateCopy=all{s.decision==1 and s.destRoot==1 and s.copyReady==1 and s.copyRev==s.revision and s.gate==1 and s.grantGen==s.generation and s.viewGen==s.generation and s.viewLease==s.lease and s.viewRev==s.revision,s'={...s,validations:s.validations+1,patchReady:0}}
action prepareReturn=all{s.decision==1 and s.destRoot==1 and s.copyReady==1 and s.copyRev==s.revision and s.gate==1 and s.grantGen==s.generation and s.viewGen==s.generation and s.viewLease==s.lease and s.viewRev==s.revision,s'={...s,patchReady:1,patchRev:s.revision,patchGen:s.generation,patchLease:s.lease}}
action commitSplit=all{s.decision==1 and s.copyReady==1 and s.destRoot==1 and s.copyRev==s.revision and s.patchReady==1 and s.patchRev==s.revision and s.patchGen==s.generation and s.patchLease==s.lease and s.gate==1 and s.grantGen==s.generation and s.viewGen==s.generation and s.viewLease==s.lease and s.viewRev==s.revision,s'={...s,decision:2,sourceRoot:0}}
action abortSplit=all{s.decision==1 and s.gate==1 and s.grantGen==s.generation and s.viewGen==s.generation and s.viewLease==s.lease and s.viewRev==s.revision,s'={...s,decision:3,destRoot:0,copyReady:0,copyRev:0,patchReady:0}}
action grantLocal=all{s.decision==3 and s.done==1 and s.localGrants==0 and s.gate==1 and s.grantGen==s.generation and s.viewGen==s.generation and s.viewLease==s.lease and s.viewRev==s.revision,s'={...s,localGrants:s.localGrants+1}}
action grantRemote=all{s.decision==2 and s.done==1 and s.remoteGrants==0 and s.copyReady==1 and s.copyRev==s.revision and s.gate==1 and s.grantGen==s.generation and s.viewGen==s.generation and s.viewLease==s.lease and s.viewRev==s.revision,s'={...s,remoteGrants:s.remoteGrants+1}}
action leaveRuntime=all{s.gate==1,s'={...s,gate:0}}
action enterGc=all{s.gate==0 and s.admitted==1,s'={...s,gate:2,grantGen:s.generation}}
action forwardNoCopy=all{s.gate==2 and s.copyReady==0,s'={...s,revision:s.revision+1,sourceHeap:1}}
action forwardWithCopy=all{s.gate==2 and s.copyReady==1 and s.destRoot==1,s'={...s,revision:s.revision+1,copyRev:s.revision+1,sourceHeap:1}}
action leaveGc=all{s.gate==2,s'={...s,gate:0}}
action closeDomain=all{s.admitted==1,s'={...s,admitted:0}}
action resetDomain=all{s.admitted==0 and s.gate==0,s'={...s,generation:s.generation+1,admitted:1}}
action failedProbe=all{s.decision!=0,s'={...s,probes:s.probes+1}}
action step=any{reserveSplit,childDone,closeLocal,allocateRootedCopy,enterRuntime,resolveCanonical,initializeCopy,validateCopy,prepareReturn,commitSplit,abortSplit,grantLocal,grantRemote,leaveRuntime,enterGc,forwardNoCopy,forwardWithCopy,leaveGc,closeDomain,resetDomain,failedProbe,all{s'=s}}
run localWinsTest=init.then(childDone).then(closeLocal).then(enterRuntime).then(resolveCanonical).then(grantLocal).then(leaveRuntime).then(all{assert(safe and s.localGrants==1 and s.claims==0),s'=s})
run splitWinsTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(validateCopy).then(prepareReturn).then(commitSplit).then(leaveRuntime).then(childDone).then(enterRuntime).then(resolveCanonical).then(grantRemote).then(leaveRuntime).then(all{assert(safe and s.remoteGrants==1 and s.localGrants==0),s'=s})
run childDoneDuringPrepareTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(childDone).then(validateCopy).then(prepareReturn).then(commitSplit).then(grantRemote).then(leaveRuntime).then(all{assert(safe and s.done==1 and s.localGrants==0),s'=s})
run gcBeforeClaimTest=init.then(enterGc).then(forwardNoCopy).then(leaveGc).then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(validateCopy).then(prepareReturn).then(commitSplit).then(leaveRuntime).then(childDone).then(enterRuntime).then(resolveCanonical).then(grantRemote).then(leaveRuntime).then(all{assert(safe and s.sourceHeap==1),s'=s})
run gcBetweenCopyCommitTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(leaveRuntime).then(enterGc).then(forwardWithCopy).then(leaveGc).then(enterRuntime).then(resolveCanonical).then(validateCopy).then(prepareReturn).then(commitSplit).then(leaveRuntime).then(childDone).then(enterRuntime).then(resolveCanonical).then(grantRemote).then(leaveRuntime).then(all{assert(safe and s.copyOps==1 and s.revision==1),s'=s})
run gcAfterPreparedPlanTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(validateCopy).then(prepareReturn).then(leaveRuntime).then(enterGc).then(forwardWithCopy).then(leaveGc).then(enterRuntime).then(resolveCanonical).then(validateCopy).then(prepareReturn).then(commitSplit).then(leaveRuntime).then(childDone).then(enterRuntime).then(resolveCanonical).then(grantRemote).then(leaveRuntime).then(all{assert(safe and s.copyOps==1 and s.validations==2),s'=s})
run abortAfterChildTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(childDone).then(abortSplit).then(grantLocal).then(leaveRuntime).then(all{assert(safe and s.remoteGrants==0 and s.destRoot==0),s'=s})
run gcBeforeLocalTest=init.then(childDone).then(closeLocal).then(enterGc).then(forwardNoCopy).then(leaveGc).then(enterRuntime).then(resolveCanonical).then(grantLocal).then(leaveRuntime).then(all{assert(safe and s.localGrants==1 and s.revision==1),s'=s})
run resetStaleViewTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(validateCopy).then(prepareReturn).then(leaveRuntime).then(closeDomain).then(resetDomain).then(enterRuntime).then(resolveCanonical).then(validateCopy).then(prepareReturn).then(commitSplit).then(leaveRuntime).then(childDone).then(enterRuntime).then(resolveCanonical).then(grantRemote).then(leaveRuntime).then(all{assert(safe and s.generation==2 and s.copyOps==1),s'=s})
run closeAcceptedGrantTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(validateCopy).then(prepareReturn).then(closeDomain).then(childDone).then(commitSplit).then(grantRemote).then(leaveRuntime).then(resetDomain).then(all{assert(safe and s.remoteGrants==1 and s.generation==2),s'=s})
run gcAfterSplitBeforeDispatchTest=init.then(reserveSplit).then(allocateRootedCopy).then(enterRuntime).then(resolveCanonical).then(initializeCopy).then(validateCopy).then(prepareReturn).then(commitSplit).then(leaveRuntime).then(enterGc).then(forwardWithCopy).then(leaveGc).then(childDone).then(enterRuntime).then(resolveCanonical).then(grantRemote).then(leaveRuntime).then(all{assert(safe and s.copyOps==1 and s.remoteGrants==1),s'=s})
}
