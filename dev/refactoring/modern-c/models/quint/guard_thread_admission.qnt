module guard_thread_admission {
// Finite protocol: preissued source ownership is a premise; mask 2 / root 2 / TLS 2 mean unknown.
type State={phase:int,mask:int,guard:int,sourceRoot:int,targetRoot:int,ack:int,tls:int,supervisor:int,childGuard:int,childRoot:int,childSource:int,childAck:int,application:int,closed:int}
pure val initial:State={phase:0,mask:0,guard:0,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}
var s:State
action init=s'=initial
val safe=any{all{s.phase==0,s.mask==0,s.guard==0,s.sourceRoot==1,s.targetRoot==0,s.ack==0,s.tls==0,s.supervisor==0,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==1,s.mask==0,s.guard==0,s.sourceRoot==1,s.targetRoot==0,s.ack==0,s.tls==0,s.supervisor==0,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==2,s.mask==0,s.guard==0,s.sourceRoot==1,s.targetRoot==0,s.ack==0,s.tls==0,s.supervisor==0,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==3,s.mask==1,s.guard==0,s.sourceRoot==1,s.targetRoot==0,s.ack==0,s.tls==0,s.supervisor==0,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==4,s.mask==1,s.guard==1,s.sourceRoot==1,s.targetRoot==0,s.ack==0,s.tls==0,s.supervisor==0,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==5,s.mask==1,s.guard==1,s.sourceRoot==1,s.targetRoot==1,s.ack==0,s.tls==0,s.supervisor==1,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==6,s.mask==1,s.guard==1,s.sourceRoot==1,s.targetRoot==1,s.ack==1,s.tls==0,s.supervisor==1,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==7,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==0,s.supervisor==1,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==8,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==1,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==9,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==1,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==10,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==1,s.childGuard==1,s.childRoot==0,s.childSource==1,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==11,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==1,s.childGuard==1,s.childRoot==1,s.childSource==0,s.childAck==1,s.application==1,s.closed==0},
all{s.phase==12,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==1,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==13,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==14,s.mask==0,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==15,s.mask==2,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==16,s.mask==2,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==17,s.mask==0,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==1},
all{s.phase==18,s.mask==0,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==0,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==1},
all{s.phase==19,s.mask==0,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==0,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==1},
all{s.phase==20,s.mask==0,s.guard==0,s.sourceRoot==0,s.targetRoot==0,s.ack==1,s.tls==0,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==1,s.closed==1},
all{s.phase==21,s.mask==2,s.guard==0,s.sourceRoot==1,s.targetRoot==0,s.ack==0,s.tls==0,s.supervisor==0,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==22,s.mask==0,s.guard==0,s.sourceRoot==1,s.targetRoot==0,s.ack==0,s.tls==0,s.supervisor==0,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==23,s.mask==1,s.guard==1,s.sourceRoot==1,s.targetRoot==2,s.ack==0,s.tls==0,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==24,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==2,s.supervisor==2,s.childGuard==0,s.childRoot==0,s.childSource==0,s.childAck==0,s.application==0,s.closed==0},
all{s.phase==25,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==2,s.childGuard==1,s.childRoot==2,s.childSource==1,s.childAck==0,s.application==1,s.closed==0},
all{s.phase==26,s.mask==2,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==2,s.childGuard==1,s.childRoot==1,s.childSource==0,s.childAck==1,s.application==1,s.closed==0},
all{s.phase==27,s.mask==1,s.guard==1,s.sourceRoot==0,s.targetRoot==1,s.ack==1,s.tls==1,s.supervisor==1,s.childGuard==1,s.childRoot==1,s.childSource==1,s.childAck==0,s.application==1,s.closed==0}}
action arrive=all{s.phase==0,s'={...s,phase:1,mask:0,guard:0,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action cancelBeforeRegistration=all{s.phase==1,s'={...s,phase:2,mask:0,guard:0,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action maskConfirmed=all{s.phase==1,s'={...s,phase:3,mask:1,guard:0,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action maskOutcomeUnknown=all{s.phase==1,s'={...s,phase:21,mask:2,guard:0,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action reserveGuard=all{s.phase==3,s'={...s,phase:4,mask:1,guard:1,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action capacityReject=all{s.phase==3,s'={...s,phase:22,mask:0,guard:0,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action publishRegistry=all{s.phase==4,s'={...s,phase:5,mask:1,guard:1,sourceRoot:1,targetRoot:1,ack:0,tls:0,supervisor:1,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action publicationUnknown=all{s.phase==4,s'={...s,phase:23,mask:1,guard:1,sourceRoot:1,targetRoot:2,ack:0,tls:0,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action queryCommitted=all{s.phase==23,s'={...s,phase:5,mask:1,guard:1,sourceRoot:1,targetRoot:1,ack:0,tls:0,supervisor:1,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action queryAbsent=all{s.phase==23,s'={...s,phase:4,mask:1,guard:1,sourceRoot:1,targetRoot:0,ack:0,tls:0,supervisor:0,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action roundAcknowledged=all{s.phase==5,s'={...s,phase:6,mask:1,guard:1,sourceRoot:1,targetRoot:1,ack:1,tls:0,supervisor:1,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action releaseSourceRoot=all{s.phase==6,s'={...s,phase:7,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:0,supervisor:1,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action bindContext=all{s.phase==7,s'={...s,phase:8,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:1,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action bindingUnknown=all{s.phase==7,s'={...s,phase:24,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:2,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:0,closed:0}}
action enterApplication=all{s.phase==8,s'={...s,phase:9,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:1,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:0}}
action beginNested=all{s.phase==9,s'={...s,phase:10,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:1,childGuard:1,childRoot:0,childSource:1,childAck:0,application:1,closed:0}}
action nestedPublish=all{s.phase==10,s'={...s,phase:27,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:1,childGuard:1,childRoot:1,childSource:1,childAck:0,application:1,closed:0}}
action nestedRoundAcknowledged=all{s.phase==27,s'={...s,phase:11,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:1,childGuard:1,childRoot:1,childSource:0,childAck:1,application:1,closed:0}}
action nestedPublicationUnknown=all{s.phase==10,s'={...s,phase:25,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:1,childRoot:2,childSource:1,childAck:0,application:1,closed:0}}
action queryNestedCommitted=all{s.phase==25,s'={...s,phase:27,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:1,childGuard:1,childRoot:1,childSource:1,childAck:0,application:1,closed:0}}
action returnNested=all{s.phase==11,s'={...s,phase:12,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:1,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:0}}
action nestedExitUnknown=all{s.phase==11,s'={...s,phase:26,mask:2,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:1,childRoot:1,childSource:0,childAck:1,application:1,closed:0}}
action armOuterExit=all{s.phase==9,s'={...s,phase:13,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:0}}
action armAfterNested=all{s.phase==12,s'={...s,phase:13,mask:1,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:0}}
action restoreReturns=all{s.phase==13,s'={...s,phase:14,mask:0,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:0}}
action restoreDoesNotReturn=all{s.phase==13,s'={...s,phase:15,mask:2,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:0}}
action restoreUnknown=all{s.phase==13,s'={...s,phase:16,mask:2,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:0}}
action closeAdmission=all{s.phase==14,s'={...s,phase:17,mask:0,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:1,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:1}}
action tlsDetachKnown=all{s.phase==17,s'={...s,phase:18,mask:0,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:0,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:1}}
action scanGraceKnown=all{s.phase==18,s'={...s,phase:19,mask:0,guard:1,sourceRoot:0,targetRoot:1,ack:1,tls:0,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:1}}
action retireActiveGuard=all{s.phase==19,s'={...s,phase:20,mask:0,guard:0,sourceRoot:0,targetRoot:0,ack:1,tls:0,supervisor:2,childGuard:0,childRoot:0,childSource:0,childAck:0,application:1,closed:1}}
action step=any{arrive,cancelBeforeRegistration,maskConfirmed,maskOutcomeUnknown,reserveGuard,capacityReject,publishRegistry,publicationUnknown,queryCommitted,queryAbsent,roundAcknowledged,releaseSourceRoot,bindContext,bindingUnknown,enterApplication,beginNested,nestedPublish,nestedRoundAcknowledged,nestedPublicationUnknown,queryNestedCommitted,returnNested,nestedExitUnknown,armOuterExit,armAfterNested,restoreReturns,restoreDoesNotReturn,restoreUnknown,closeAdmission,tlsDetachKnown,scanGraceKnown,retireActiveGuard,all{s'=s}}
run preRegistrationCancelTest=init.then(arrive).then(cancelBeforeRegistration).then(all{assert(s.phase==2),assert(safe),s'=s})
run unknownMaskTest=init.then(arrive).then(maskOutcomeUnknown).then(all{assert(s.phase==21),assert(safe),s'=s})
run poolExhaustedTest=init.then(arrive).then(maskConfirmed).then(capacityReject).then(all{assert(s.phase==22),assert(safe),s'=s})
run rootOverlapTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(all{assert(s.phase==6),assert(safe),s'=s})
run publishRetryTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publicationUnknown).then(queryAbsent).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindContext).then(enterApplication).then(all{assert(s.phase==9),assert(safe),s'=s})
run bindingUncertainTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindingUnknown).then(all{assert(s.phase==24),assert(safe),s'=s})
run normalTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindContext).then(enterApplication).then(armOuterExit).then(restoreReturns).then(closeAdmission).then(tlsDetachKnown).then(scanGraceKnown).then(retireActiveGuard).then(all{assert(s.phase==20),assert(safe),s'=s})
run restoreAbandonedTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindContext).then(enterApplication).then(armOuterExit).then(restoreDoesNotReturn).then(all{assert(s.phase==15),assert(safe),s'=s})
run restoreUncertainTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindContext).then(enterApplication).then(armOuterExit).then(restoreUnknown).then(all{assert(s.phase==16),assert(safe),s'=s})
run nestedTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindContext).then(enterApplication).then(beginNested).then(nestedPublish).then(nestedRoundAcknowledged).then(returnNested).then(armAfterNested).then(restoreReturns).then(all{assert(s.phase==14),assert(safe),s'=s})
run nestedUnknownTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindContext).then(enterApplication).then(beginNested).then(nestedPublish).then(nestedRoundAcknowledged).then(nestedExitUnknown).then(all{assert(s.phase==26),assert(safe),s'=s})
run nestedPublishRetryTest=init.then(arrive).then(maskConfirmed).then(reserveGuard).then(publishRegistry).then(roundAcknowledged).then(releaseSourceRoot).then(bindContext).then(enterApplication).then(beginNested).then(nestedPublicationUnknown).then(queryNestedCommitted).then(nestedRoundAcknowledged).then(returnNested).then(all{assert(s.phase==12),assert(safe),s'=s})
}
