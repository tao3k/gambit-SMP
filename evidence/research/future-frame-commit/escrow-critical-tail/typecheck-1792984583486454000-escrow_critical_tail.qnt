module escrow_critical_tail {
// One preallocated slot; external is another retained/nested owner.
// Qualified tails and known landing receipts are native premises, not cancellation guarantees.
type State={stage:int,free:int,slot:int,external:int,registered:int,queued:int,cancel:int,supervisor:int,lock:int,pin:int,tailQualified:int,nodeReceipt:int}
pure val initial:State={stage:0,free:1,slot:0,external:0,registered:0,queued:1,cancel:0,supervisor:0,lock:0,pin:0,tailQualified:0,nodeReceipt:0}
var s:State
action init=s'=initial
val safe=all{s.stage>=0,s.free>=0,s.slot>=0,s.external>=0,s.registered>=0,s.queued>=0,s.cancel>=0,s.supervisor>=0,s.lock>=0,s.pin>=0,s.tailQualified>=0,s.nodeReceipt>=0,s.stage<=9,s.free<=1,s.slot<=1,s.external<=1,s.registered<=2,s.queued<=1,s.cancel<=3,s.supervisor<=1,s.lock<=2,s.pin<=2,s.tailQualified<=1,s.nodeReceipt<=1,s.free+s.slot+s.external==1,s.stage==0 implies all{s.slot==0,s.registered==0,s.queued==1},s.stage==1 implies all{s.slot==1,s.registered==0,s.queued==1,s.cancel==1},s.stage==2 implies all{s.slot==1,(s.registered==1 or s.registered==2),s.queued==1,s.cancel==1},s.stage>=3 and s.stage<=8 implies all{s.slot==1,s.registered==1,s.queued==0},s.stage>=3 and s.stage<=7 implies s.cancel==1,s.stage==9 implies all{s.slot==0,s.registered==0,s.queued==0,s.cancel==3,s.supervisor==0,s.lock==0,s.pin==0},s.registered>=1 implies s.slot==1,s.lock>=1 implies all{s.cancel==1,s.registered==1,s.slot==1},s.pin>=1 implies all{s.registered==1,s.slot==1,s.cancel==1},s.pin==2 implies s.lock==2,s.tailQualified==1 implies s.stage>=5,s.nodeReceipt==1 implies s.stage>=7,s.stage>=7 implies s.nodeReceipt==1,s.supervisor==1 implies s.stage==8,s.cancel>=2 implies all{s.stage>=8,s.lock==0,s.pin==0},s.cancel==2 implies all{s.stage==8,s.supervisor==1,s.slot==1,s.registered==1}}
action disableCancel=all{s.stage==0 and s.cancel==0,s'={...s,cancel:1}}
action exhaustPool=all{s.stage==0 and s.free==1,s'={...s,free:0,external:1}}
action returnExternalSlot=all{s.external==1,s'={...s,free:1,external:0}}
action claimSlot=all{s.stage==0 and s.cancel==1 and s.free==1,s'={...s,stage:1,free:0,slot:1}}
action releaseUnpublishedSlot=all{s.stage==1 and s.registered==0,s'={...s,stage:0,free:1,slot:0}}
action registerKnown=all{s.stage==1 and s.registered==0,s'={...s,stage:2,registered:1}}
action registerUnknown=all{s.stage==1 and s.registered==0,s'={...s,stage:2,registered:2}}
action reconcileRegistration=all{s.stage==2 and s.registered==2,s'={...s,registered:1}}
action popKnownEscrow=all{s.stage==2 and s.registered==1 and s.cancel==1,s'={...s,stage:3,queued:0}}
action escapeToken=all{s.stage==3,s'={...s,stage:4}}
action knownTokenEndpoint=all{(s.stage==3 or s.stage==4),s'={...s,stage:5}}
action qualifyNodeTail=all{s.stage==5 and s.cancel==1 and s.tailQualified==0,s'={...s,tailQualified:1}}
action completeQualifiedNodeTail=all{s.stage==5 and s.cancel==1 and s.tailQualified==1,s'={...s,stage:7,nodeReceipt:1}}
action unknownNodeCompletion=all{s.stage==5 and s.tailQualified==0,s'={...s,stage:6}}
action knownNodeBackendReceipt=all{s.stage==6,s'={...s,stage:7,nodeReceipt:1}}
action publishDone=all{s.stage==7 and s.nodeReceipt==1,s'={...s,stage:8}}
action acquireMap=all{s.cancel==1 and s.registered==1 and s.lock==0,s'={...s,lock:1}}
action issuePin=all{s.lock==1 and s.pin==0,s'={...s,pin:1}}
action unlockMap=all{s.lock==1,s'={...s,lock:0}}
action escapeHoldingMap=all{s.lock==1,s'={...s,lock:2}}
action knownOwnerLanding=all{s.lock==2 and s.pin<=1,s'={...s,lock:1}}
action returnPinKnown=all{s.lock==1 and s.pin==1 and s.cancel==1,s'={...s,pin:0}}
action returnPinUnknown=all{s.lock==1 and s.pin==1 and s.cancel==1,s'={...s,pin:2,lock:2}}
action knownPinReturnLanding=all{s.lock==2 and s.pin==2,s'={...s,pin:0,lock:1}}
action handoffSupervisor=all{s.stage==8 and s.cancel==1 and s.lock==0 and s.pin==0 and s.supervisor==0,s'={...s,supervisor:1}}
action beginRestoreCancel=all{s.stage==8 and s.cancel==1 and s.supervisor==1 and s.lock==0 and s.pin==0,s'={...s,cancel:2}}
action knownRestoreReturn=all{s.cancel==2 and s.supervisor==1,s'={...s,cancel:3}}
action retireSlot=all{s.stage==8 and s.cancel==3 and s.supervisor==1 and s.lock==0 and s.pin==0 and s.registered==1 and s.slot==1,s'={...s,stage:9,free:1,slot:0,registered:0,supervisor:0}}
action step=any{disableCancel,exhaustPool,returnExternalSlot,claimSlot,releaseUnpublishedSlot,registerKnown,registerUnknown,reconcileRegistration,popKnownEscrow,escapeToken,knownTokenEndpoint,qualifyNodeTail,completeQualifiedNodeTail,unknownNodeCompletion,knownNodeBackendReceipt,publishDone,acquireMap,issuePin,unlockMap,escapeHoldingMap,knownOwnerLanding,returnPinKnown,returnPinUnknown,knownPinReturnLanding,handoffSupervisor,beginRestoreCancel,knownRestoreReturn,retireSlot,all{s'=s}}
run normalTest=init.then(disableCancel).then(claimSlot).then(registerKnown).then(popKnownEscrow).then(knownTokenEndpoint).then(qualifyNodeTail).then(completeQualifiedNodeTail).then(publishDone).then(handoffSupervisor).then(beginRestoreCancel).then(knownRestoreReturn).then(retireSlot).then(all{assert(safe),s'=s})
run poolFullTest=init.then(disableCancel).then(exhaustPool).then(all{assert(safe),s'=s})
run unknownRegisterTest=init.then(disableCancel).then(claimSlot).then(registerUnknown).then(all{assert(safe),s'=s})
run unknownTokenTest=init.then(disableCancel).then(claimSlot).then(registerKnown).then(popKnownEscrow).then(escapeToken).then(all{assert(safe),s'=s})
run unknownPinTest=init.then(disableCancel).then(claimSlot).then(registerKnown).then(popKnownEscrow).then(knownTokenEndpoint).then(qualifyNodeTail).then(completeQualifiedNodeTail).then(publishDone).then(acquireMap).then(issuePin).then(returnPinUnknown).then(all{assert(safe),s'=s})
run restoreNoReturnTest=init.then(disableCancel).then(claimSlot).then(registerKnown).then(popKnownEscrow).then(knownTokenEndpoint).then(qualifyNodeTail).then(completeQualifiedNodeTail).then(publishDone).then(handoffSupervisor).then(beginRestoreCancel).then(all{assert(safe),s'=s})
run knownPinLandingTest=init.then(disableCancel).then(claimSlot).then(registerKnown).then(popKnownEscrow).then(knownTokenEndpoint).then(qualifyNodeTail).then(completeQualifiedNodeTail).then(publishDone).then(acquireMap).then(issuePin).then(returnPinUnknown).then(knownPinReturnLanding).then(unlockMap).then(handoffSupervisor).then(beginRestoreCancel).then(knownRestoreReturn).then(retireSlot).then(all{assert(safe),s'=s})
}
