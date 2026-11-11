module allocation_ticket_handoff {
type State={phase:int,ticket:int,owner:int,effect:int,calls:int,frees:int,reserved:int,sourceHold:int}
pure val initial:State={phase:0,ticket:0,owner:0,effect:0,calls:0,frees:0,reserved:0,sourceHold:0}
var s:State
action init=s'=initial
val safe=any{all{s.phase==0,s.ticket==0,s.owner==0,s.effect==0,s.calls==0,s.frees==0,s.reserved==0,s.sourceHold==0},
all{s.phase==1,s.ticket==1,s.owner==1,s.effect==0,s.calls==0,s.frees==0,s.reserved==1,s.sourceHold==1},
all{s.phase==2,s.ticket==1,s.owner==1,s.effect==0,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==1},
all{s.phase==3,s.ticket==1,s.owner==1,s.effect==1,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==1},
all{s.phase==4,s.ticket==1,s.owner==2,s.effect==1,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==1},
all{s.phase==5,s.ticket==0,s.owner==2,s.effect==1,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==0},
all{s.phase==6,s.ticket==1,s.owner==1,s.effect==1,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==1},
all{s.phase==7,s.ticket==1,s.owner==1,s.effect==1,s.calls==1,s.frees==1,s.reserved==1,s.sourceHold==1},
all{s.phase==8,s.ticket==1,s.owner==3,s.effect==2,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==1},
all{s.phase==9,s.ticket==1,s.owner==3,s.effect==2,s.calls==1,s.frees==1,s.reserved==1,s.sourceHold==1},
all{s.phase==10,s.ticket==0,s.owner==0,s.effect==0,s.calls==0,s.frees==0,s.reserved==0,s.sourceHold==0},
all{s.phase==11,s.ticket==0,s.owner==0,s.effect==3,s.calls==1,s.frees==1,s.reserved==0,s.sourceHold==0},
all{s.phase==12,s.ticket==1,s.owner==3,s.effect==1,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==1},
all{s.phase==13,s.ticket==0,s.owner==0,s.effect==0,s.calls==1,s.frees==0,s.reserved==0,s.sourceHold==0},
all{s.phase==14,s.ticket==1,s.owner==1,s.effect==1,s.calls==1,s.frees==0,s.reserved==1,s.sourceHold==1}}
action issue=all{s.phase==0,s'={...s,phase:1,ticket:1,owner:1,effect:0,calls:0,frees:0,reserved:1,sourceHold:1}}
action metadataExhausted=all{s.phase==0,s'={...s,phase:10,ticket:0,owner:0,effect:0,calls:0,frees:0,reserved:0,sourceHold:0}}
action invoke=all{s.phase==1,s'={...s,phase:2,ticket:1,owner:1,effect:0,calls:1,frees:0,reserved:1,sourceHold:1}}
action cancelBeforeInvoke=all{s.phase==1,s'={...s,phase:10,ticket:0,owner:0,effect:0,calls:0,frees:0,reserved:0,sourceHold:0}}
action allocatorNull=all{s.phase==2,s'={...s,phase:13,ticket:0,owner:0,effect:0,calls:1,frees:0,reserved:0,sourceHold:0}}
action allocatorReturn=all{s.phase==2,s'={...s,phase:14,ticket:1,owner:1,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action captureReturn=all{s.phase==14,s'={...s,phase:3,ticket:1,owner:1,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action interruptUnrecordedReturn=all{s.phase==14,s'={...s,phase:8,ticket:1,owner:3,effect:2,calls:1,frees:0,reserved:1,sourceHold:1}}
action allocatorOutcomeUnknown=all{s.phase==2,s'={...s,phase:8,ticket:1,owner:3,effect:2,calls:1,frees:0,reserved:1,sourceHold:1}}
action commit=all{s.phase==3,s'={...s,phase:4,ticket:1,owner:2,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action indexOutcomeUnknown=all{s.phase==3,s'={...s,phase:12,ticket:1,owner:3,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action resolveCommitted=all{s.phase==12,s'={...s,phase:4,ticket:1,owner:2,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action resolveAbsent=all{s.phase==12,s'={...s,phase:3,ticket:1,owner:1,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action observeCommit=all{s.phase==4,s'={...s,phase:5,ticket:0,owner:2,effect:1,calls:1,frees:0,reserved:1,sourceHold:0}}
action retryCommitQuery=all{s.phase==4,s'={...s,phase:4,ticket:1,owner:2,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action requestPrivateAbort=all{s.phase==3,s'={...s,phase:6,ticket:1,owner:1,effect:1,calls:1,frees:0,reserved:1,sourceHold:1}}
action invokePrivateFree=all{s.phase==6,s'={...s,phase:7,ticket:1,owner:1,effect:1,calls:1,frees:1,reserved:1,sourceHold:1}}
action privateFreeKnown=all{s.phase==7,s'={...s,phase:11,ticket:0,owner:0,effect:3,calls:1,frees:1,reserved:0,sourceHold:0}}
action privateFreeUnknown=all{s.phase==7,s'={...s,phase:9,ticket:1,owner:3,effect:2,calls:1,frees:1,reserved:1,sourceHold:1}}
action step=any{issue,metadataExhausted,invoke,cancelBeforeInvoke,allocatorNull,allocatorReturn,captureReturn,interruptUnrecordedReturn,allocatorOutcomeUnknown,commit,indexOutcomeUnknown,resolveCommitted,resolveAbsent,observeCommit,retryCommitQuery,requestPrivateAbort,invokePrivateFree,privateFreeKnown,privateFreeUnknown,all{s'=s}}
run successTest=init.then(issue).then(invoke).then(allocatorReturn).then(captureReturn).then(commit).then(retryCommitQuery).then(observeCommit).then(all{assert(s.phase==5),assert(s.calls==1),assert(s.sourceHold==0),s'=s})
run exhaustionTest=init.then(metadataExhausted).then(all{assert(s.calls==0),assert(s.ticket==0),s'=s})
run rollbackTest=init.then(issue).then(invoke).then(allocatorReturn).then(captureReturn).then(requestPrivateAbort).then(invokePrivateFree).then(privateFreeKnown).then(all{assert(s.frees==1),assert(s.ticket==0),s'=s})
run unknownAllocatorTest=init.then(issue).then(invoke).then(allocatorOutcomeUnknown).then(all{assert(s.ticket==1),assert(s.owner==3),s'=s})
run unknownIndexTest=init.then(issue).then(invoke).then(allocatorReturn).then(captureReturn).then(indexOutcomeUnknown).then(resolveCommitted).then(observeCommit).then(all{assert(s.calls==1),s'=s})
run unknownFreeTest=init.then(issue).then(invoke).then(allocatorReturn).then(captureReturn).then(requestPrivateAbort).then(invokePrivateFree).then(privateFreeUnknown).then(all{assert(s.ticket==1),assert(s.frees==1),s'=s})
run nullTest=init.then(issue).then(invoke).then(allocatorNull).then(all{assert(s.calls==1),assert(s.frees==0),s'=s})
run unrecordedEscapeTest=init.then(issue).then(invoke).then(allocatorReturn).then(interruptUnrecordedReturn).then(all{assert(s.ticket==1),assert(s.owner==3),s'=s})
run beforeInvokeCancelTest=init.then(issue).then(cancelBeforeInvoke).then(all{assert(s.calls==0),assert(s.ticket==0),s'=s})
}
