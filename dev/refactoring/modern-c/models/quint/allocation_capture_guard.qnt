module allocation_capture_guard {
type State={phase:int,captured:int,guard:int,disabled:int,owner:int,root:int,child:int,calls:int}
pure val initial:State={phase:0,captured:0,guard:0,disabled:0,owner:0,root:0,child:0,calls:0}
var s:State
action init=s'=initial
val safe=any{all{s.phase==0,s.captured==0,s.guard==0,s.disabled==0,s.owner==0,s.root==0,s.child==0,s.calls==0},
all{s.phase==1,s.captured==0,s.guard==1,s.disabled==0,s.owner==1,s.root==1,s.child==0,s.calls==0},
all{s.phase==2,s.captured==0,s.guard==1,s.disabled==1,s.owner==1,s.root==1,s.child==0,s.calls==0},
all{s.phase==3,s.captured==0,s.guard==1,s.disabled==1,s.owner==1,s.root==1,s.child==0,s.calls==1},
all{s.phase==4,s.captured==0,s.guard==1,s.disabled==1,s.owner==1,s.root==1,s.child==0,s.calls==1},
all{s.phase==5,s.captured==1,s.guard==1,s.disabled==1,s.owner==1,s.root==1,s.child==0,s.calls==1},
all{s.phase==6,s.captured==1,s.guard==1,s.disabled==1,s.owner==2,s.root==1,s.child==0,s.calls==1},
all{s.phase==7,s.captured==1,s.guard==1,s.disabled==0,s.owner==2,s.root==1,s.child==0,s.calls==1},
all{s.phase==8,s.captured==1,s.guard==1,s.disabled==0,s.owner==2,s.root==1,s.child==0,s.calls==1},
all{s.phase==8,s.captured==1,s.guard==1,s.disabled==0,s.owner==2,s.root==1,s.child==1,s.calls==1},
all{s.phase==8,s.captured==1,s.guard==1,s.disabled==0,s.owner==2,s.root==1,s.child==2,s.calls==1},
all{s.phase==9,s.captured==1,s.guard==1,s.disabled==0,s.owner==2,s.root==1,s.child==0,s.calls==1},
all{s.phase==9,s.captured==1,s.guard==1,s.disabled==0,s.owner==2,s.root==1,s.child==2,s.calls==1},
all{s.phase==10,s.captured==1,s.guard==1,s.disabled==2,s.owner==2,s.root==1,s.child==0,s.calls==1},
all{s.phase==10,s.captured==1,s.guard==1,s.disabled==2,s.owner==2,s.root==1,s.child==2,s.calls==1},
all{s.phase==10,s.captured==1,s.guard==1,s.disabled==2,s.owner==2,s.root==1,s.child==3,s.calls==1},
all{s.phase==11,s.captured==0,s.guard==1,s.disabled==2,s.owner==3,s.root==1,s.child==0,s.calls==1},
all{s.phase==12,s.captured==0,s.guard==0,s.disabled==0,s.owner==0,s.root==0,s.child==0,s.calls==1},
all{s.phase==13,s.captured==0,s.guard==0,s.disabled==0,s.owner==0,s.root==0,s.child==0,s.calls==0},
all{s.phase==14,s.captured==1,s.guard==1,s.disabled==2,s.owner==2,s.root==1,s.child==0,s.calls==1},
all{s.phase==15,s.captured==1,s.guard==0,s.disabled==0,s.owner==4,s.root==0,s.child==0,s.calls==1},
all{s.phase==15,s.captured==1,s.guard==0,s.disabled==0,s.owner==4,s.root==0,s.child==2,s.calls==1},
all{s.phase==16,s.captured==0,s.guard==1,s.disabled==1,s.owner==2,s.root==1,s.child==0,s.calls==1},
all{s.phase==17,s.captured==0,s.guard==1,s.disabled==2,s.owner==2,s.root==1,s.child==0,s.calls==1}}
action issue=all{(s.phase==0),s'={...s,phase:1,captured:0,guard:1,disabled:0,owner:1,root:1,child:0,calls:0}}
action metadataReject=all{(s.phase==0),s'={...s,phase:13,captured:0,guard:0,disabled:0,owner:0,root:0,child:0,calls:0}}
action maskReject=all{(s.phase==1),s'={...s,phase:13,captured:0,guard:0,disabled:0,owner:0,root:0,child:0,calls:0}}
action cancelBeforeMask=all{(s.phase==1),s'={...s,phase:13,captured:0,guard:0,disabled:0,owner:0,root:0,child:0,calls:0}}
action maskConfirmed=all{(s.phase==1),s'={...s,phase:2,captured:0,guard:1,disabled:1,owner:1,root:1,child:0,calls:0}}
action invoke=all{(s.phase==2),s'={...s,phase:3,captured:0,guard:1,disabled:1,owner:1,root:1,child:0,calls:1}}
action nativeReturn=all{(s.phase==3),s'={...s,phase:4,captured:0,guard:1,disabled:1,owner:1,root:1,child:0,calls:1}}
action capture=all{(s.phase==4),s'={...s,phase:5,captured:1,guard:1,disabled:1,owner:1,root:1,child:0,calls:1}}
action armExitOwner=all{(s.phase==5),s'={...s,phase:6,captured:1,guard:1,disabled:1,owner:2,root:1,child:0,calls:1}}
action restoreReturns=all{(s.phase==6),s'={...s,phase:7,captured:1,guard:1,disabled:0,owner:2,root:1,child:0,calls:1}}
action restoreAbandons=all{(s.phase==6),s'={...s,phase:10,captured:1,guard:1,disabled:2,owner:2,root:1,child:0,calls:1}}
action restoreUnknown=all{(s.phase==6),s'={...s,phase:14,captured:1,guard:1,disabled:2,owner:2,root:1,child:0,calls:1}}
action nativeNull=all{(s.phase==3),s'={...s,phase:16,captured:0,guard:1,disabled:1,owner:2,root:1,child:0,calls:1}}
action finishNull=all{(s.phase==16),s'={...s,phase:12,captured:0,guard:0,disabled:0,owner:0,root:0,child:0,calls:1}}
action restoreNullAbandons=all{(s.phase==16),s'={...s,phase:17,captured:0,guard:1,disabled:2,owner:2,root:1,child:0,calls:1}}
action startLogger=all{(s.phase==7),s'={...s,phase:8,captured:1,guard:1,disabled:0,owner:2,root:1,child:0,calls:1}}
action skipLogger=all{(s.phase==7),s'={...s,phase:9,captured:1,guard:1,disabled:0,owner:2,root:1,child:0,calls:1}}
action loggerReturns=all{(s.phase==8 and s.child!=1),s'={...s,phase:9,captured:1,guard:1,disabled:0,owner:2,root:1,calls:1}}
action loggerError=all{(s.phase==8 and s.child!=1),s'={...s,phase:9,captured:1,guard:1,disabled:0,owner:2,root:1,calls:1}}
action nestedEnter=all{(s.phase==8 and s.child==0),s'={...s,phase:8,captured:1,guard:1,disabled:0,owner:2,root:1,child:1,calls:1}}
action nestedKnownExit=all{(s.phase==8 and s.child==1),s'={...s,phase:8,captured:1,guard:1,disabled:0,owner:2,root:1,child:2,calls:1}}
action nestedUnknownExit=all{(s.phase==8 and s.child==1),s'={...s,phase:10,captured:1,guard:1,disabled:2,owner:2,root:1,child:3,calls:1}}
action capturedThrow=all{((s.phase==7 or s.phase==8 or s.phase==9) and s.child!=1),s'={...s,phase:10,captured:1,guard:1,disabled:2,owner:2,root:1,calls:1}}
action handoff=all{(s.phase==9),s'={...s,phase:15,captured:1,guard:0,disabled:0,owner:4,root:0,calls:1}}
action unrecordedEscape=all{(s.phase==4),s'={...s,phase:11,captured:0,guard:1,disabled:2,owner:3,root:1,child:0,calls:1}}
action inflightEscape=all{(s.phase==3),s'={...s,phase:11,captured:0,guard:1,disabled:2,owner:3,root:1,child:0,calls:1}}
action step=any{issue,metadataReject,maskReject,cancelBeforeMask,maskConfirmed,invoke,nativeReturn,capture,armExitOwner,restoreReturns,restoreAbandons,restoreUnknown,nativeNull,finishNull,restoreNullAbandons,startLogger,skipLogger,loggerReturns,loggerError,nestedEnter,nestedKnownExit,nestedUnknownExit,capturedThrow,handoff,unrecordedEscape,inflightEscape,all{s'=s}}
run loggerSuccessTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(capture).then(armExitOwner).then(restoreReturns).then(startLogger).then(loggerReturns).then(handoff).then(all{assert(s.phase==15),assert(safe),s'=s})
run noLoggerTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(capture).then(armExitOwner).then(restoreReturns).then(skipLogger).then(handoff).then(all{assert(s.phase==15),assert(safe),s'=s})
run nestedSuccessTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(capture).then(armExitOwner).then(restoreReturns).then(startLogger).then(nestedEnter).then(nestedKnownExit).then(loggerReturns).then(handoff).then(all{assert(s.phase==15),assert(safe),s'=s})
run nestedUnknownTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(capture).then(armExitOwner).then(restoreReturns).then(startLogger).then(nestedEnter).then(nestedUnknownExit).then(all{assert(s.phase==10),assert(safe),s'=s})
run lostPointerTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(unrecordedEscape).then(all{assert(s.phase==11),assert(safe),s'=s})
run allocatorUnknownTest=init.then(issue).then(maskConfirmed).then(invoke).then(inflightEscape).then(all{assert(s.phase==11),assert(safe),s'=s})
run restoreCancellationTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(capture).then(armExitOwner).then(restoreAbandons).then(all{assert(s.phase==10),assert(safe),s'=s})
run restoreUncertainTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(capture).then(armExitOwner).then(restoreUnknown).then(all{assert(s.phase==14),assert(safe),s'=s})
run nullKnownTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeNull).then(finishNull).then(all{assert(s.phase==12),assert(safe),s'=s})
run nullRestorationAbandonedTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeNull).then(restoreNullAbandons).then(all{assert(s.phase==17),assert(safe),s'=s})
run loggerFailureStillAllocatedTest=init.then(issue).then(maskConfirmed).then(invoke).then(nativeReturn).then(capture).then(armExitOwner).then(restoreReturns).then(startLogger).then(loggerError).then(handoff).then(all{assert(s.phase==15),assert(safe),s'=s})
run maskFailureTest=init.then(issue).then(maskReject).then(all{assert(s.phase==13),assert(safe),s'=s})
}
