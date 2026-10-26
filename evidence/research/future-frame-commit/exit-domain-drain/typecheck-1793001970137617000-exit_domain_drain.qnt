module exit_domain_drain {
// Two distinct registrations may share proc/clientData; native receipt authorities are external premises.
type State={phase:int,a:int,b:int,ack:int,parent:int,samePair:int,tailLive:int,tailDone:int,admission:int,keyGate:int,lookupPin:int,data:int,slot:int,cache:int,joined:int,miss:int,deps:int,cacheDone:int,allOwners:int,key:int}
pure val initial:State={phase:0,a:0,b:0,ack:0,parent:0,samePair:0,tailLive:0,tailDone:0,admission:1,keyGate:1,lookupPin:0,data:0,slot:0,cache:0,joined:0,miss:0,deps:0,cacheDone:0,allOwners:0,key:1}
var s:State
action init=s'=initial
val safe=all{all{s.phase>=0,s.phase<=6},all{s.a>=0,s.a<=8},all{s.b>=0,s.b<=8},all{s.ack>=0,s.ack<=2},all{s.parent>=0,s.parent<=2},all{s.samePair>=0,s.samePair<=1},all{s.tailLive>=0,s.tailLive<=1},all{s.tailDone>=0,s.tailDone<=1},all{s.admission>=0,s.admission<=1},all{s.keyGate>=0,s.keyGate<=1},all{s.lookupPin>=0,s.lookupPin<=1},all{s.data>=0,s.data<=1},all{s.slot>=0,s.slot<=1},all{s.cache>=0,s.cache<=1},all{s.joined>=0,s.joined<=1},all{s.miss>=0,s.miss<=1},all{s.deps>=0,s.deps<=1},all{s.cacheDone>=0,s.cacheDone<=1},all{s.allOwners>=0,s.allOwners<=1},all{s.key>=0,s.key<=1},s.phase==0 implies all{s.admission==1,s.keyGate==1,s.tailLive==0,s.tailDone==0},s.phase>=1 implies s.admission==0,s.phase<=1 implies all{s.keyGate==1,s.slot==s.data,s.deps==0},s.phase>=2 implies all{s.keyGate==0,(s.a==0 or s.a==5),(s.b==0 or s.b==5),s.ack!=2,s.tailLive==0,s.tailDone==1},s.phase>=3 implies all{s.slot==0,s.lookupPin==0,s.deps==1},s.phase>=4 implies s.data==0,s.phase<=5 implies s.key==1,s.phase==6 implies all{s.key==0,s.cacheDone==1,s.allOwners==1,s.cache==0},s.lookupPin==1 implies all{s.phase<=2,s.key==1},s.data==1 implies s.cache==1,s.a>=1 and s.a<=8 and s.phase<=1 implies s.data==1,s.b>=1 and s.b<=8 and s.phase<=1 implies s.data==1,s.b==0 implies all{s.ack==0,s.parent==0},s.b==1 implies all{s.ack!=1,s.data==1},s.b>=2 implies all{s.parent>=0,(s.ack==1 or s.ack==2)},s.a>=3 and s.a<=4 implies s.phase==1,s.b>=3 and s.b<=4 implies s.phase==1,(s.a==6 or s.a==7 or s.a==8) implies s.phase<=1,(s.b==6 or s.b==7 or s.b==8) implies s.phase<=1,s.tailLive==1 implies all{s.phase==1,s.tailDone==0},s.tailDone==1 implies s.tailLive==0,s.cacheDone==1 implies all{s.phase>=5,s.data==0,s.slot==0,s.lookupPin==0,s.cache==0},s.allOwners==1 implies all{s.phase>=5,s.cacheDone==1},s.phase<=4 implies all{s.cacheDone==0,s.allOwners==0},s.cache==0 implies s.data==0}
action seedRegistrationA=all{s.phase==0 and s.a==0,s'={...s,a:2,data:1,slot:1,cache:1}}
action chooseDuplicatePair=all{s.phase==0 and s.b==0 and s.samePair==0,s'={...s,samePair:1}}
action reserveExternalB=all{s.phase==0 and s.a==2 and s.b==0,s'={...s,b:1,parent:0}}
action beginDrain=all{s.phase==0,s'={...s,phase:1,admission:0}}
action reserveChildB=all{s.phase==1 and s.a==3 and s.b==0,s'={...s,b:1,parent:1}}
action reserveTailB=all{s.phase==1 and s.tailLive==1 and s.b==0,s'={...s,b:1,parent:2,data:1,slot:1,cache:1}}
action publishBKnown=all{s.b==1 and s.ack==0,s'={...s,b:2,ack:1}}
action publishBUnknown=all{s.b==1 and s.ack==0,s'={...s,b:2,ack:2}}
action publicationAbsentUnknown=all{s.b==1 and s.ack==0,s'={...s,ack:2}}
action reconcileAcceptedB=all{s.b>=2 and s.ack==2,s'={...s,ack:1}}
action reconcileAbsentAndRolledBackB=all{s.b==1 and s.ack==2,s'={...s,b:0,ack:0,parent:0}}
action popA=all{s.phase==1 and s.a==2 and s.b!=2,s'={...s,a:3}}
action popB=all{s.phase==1 and s.b==2,s'={...s,b:3}}
action returnA=all{s.a==3,s'={...s,a:4}}
action returnB=all{s.b==3,s'={...s,b:4}}
action callbackUnknownA=all{s.a==3,s'={...s,a:8}}
action freeNodeAKnown=all{s.a==4 or s.a==6,s'={...s,a:5}}
action freeNodeBKnown=all{s.b==4 or s.b==6,s'={...s,b:5}}
action freeNodeAUnknown=all{s.a==4 or s.a==6,s'={...s,a:7}}
action freeNodeBUnknown=all{s.b==4 or s.b==6,s'={...s,b:7}}
action cancelNewestDuplicateB=all{s.b==2 and s.samePair==1,s'={...s,b:6}}
action cancelQueuedA=all{s.a==2 and not(s.b==2 and s.samePair==1),s'={...s,a:6}}
action reentrantFinalizeJoin=all{s.phase==1 and (s.a==3 or s.b==3) and s.joined==0,s'={...s,joined:1}}
action beginSubsystemTail=all{s.phase==1 and (s.a==0 or s.a==5) and (s.b==0 or s.b==5) and s.ack!=2 and s.tailLive==0 and s.tailDone==0,s'={...s,tailLive:1}}
action finishSubsystemTail=all{s.phase==1 and s.tailLive==1 and s.b!=1 and s.ack!=2,s'={...s,tailLive:0,tailDone:1}}
action closeProducers=all{s.phase==1 and (s.a==0 or s.a==5) and (s.b==0 or s.b==5) and s.ack!=2 and s.tailLive==0 and s.tailDone==1,s'={...s,phase:2,keyGate:0}}
action attestNoTsdDependencies=all{s.phase==2 and s.deps==0,s'={...s,deps:1}}
action acquireLookup=all{s.key==1 and s.keyGate==1 and s.lookupPin==0,s'={...s,lookupPin:1}}
action lookupAbsent=all{s.lookupPin==1 and s.data==0 and s.miss==0,s'={...s,miss:1}}
action releaseLookup=all{s.lookupPin==1,s'={...s,lookupPin:0}}
action detachTableSlot=all{s.phase==2 and s.lookupPin==0 and s.deps==1,s'={...s,phase:3,slot:0}}
action freeTsdData=all{s.phase==3 and s.slot==0 and s.lookupPin==0 and s.deps==1,s'={...s,phase:4,data:0}}
action issueDataDrainReceipt=all{s.phase==4,s'={...s,phase:5}}
action cancelAbsentFromReceipt=all{s.phase>=3 and s.slot==0 and s.miss==0,s'={...s,miss:1}}
action attestCacheAndOwnerRoster=all{s.phase==5 and s.lookupPin==0,s'={...s,cacheDone:1,allOwners:1,cache:0}}
action deleteGenericKey=all{s.phase==5 and s.cacheDone==1 and s.allOwners==1 and s.lookupPin==0 and s.key==1,s'={...s,phase:6,key:0}}
action step=any{seedRegistrationA,chooseDuplicatePair,reserveExternalB,beginDrain,reserveChildB,reserveTailB,publishBKnown,publishBUnknown,publicationAbsentUnknown,reconcileAcceptedB,reconcileAbsentAndRolledBackB,popA,popB,returnA,returnB,callbackUnknownA,freeNodeAKnown,freeNodeBKnown,freeNodeAUnknown,freeNodeBUnknown,cancelNewestDuplicateB,cancelQueuedA,reentrantFinalizeJoin,beginSubsystemTail,finishSubsystemTail,closeProducers,attestNoTsdDependencies,acquireLookup,lookupAbsent,releaseLookup,detachTableSlot,freeTsdData,issueDataDrainReceipt,cancelAbsentFromReceipt,attestCacheAndOwnerRoster,deleteGenericKey,all{s'=s}}
run normalTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA.then(freeNodeAKnown)).then(beginSubsystemTail.then(finishSubsystemTail).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)).then(all{assert(safe),s'=s})
run duplicateSelfDeleteTest=init.then(seedRegistrationA).then(chooseDuplicatePair).then(beginDrain).then(popA).then(reserveChildB).then(publishBKnown).then(cancelNewestDuplicateB).then(freeNodeBKnown).then(returnA.then(freeNodeAKnown)).then(beginSubsystemTail.then(finishSubsystemTail).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)).then(all{assert(safe),s'=s})
run unknownAckChildRunsTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(reserveChildB).then(publishBUnknown).then(returnA).then(freeNodeAKnown).then(popB).then(returnB).then(freeNodeBKnown).then(reconcileAcceptedB).then(beginSubsystemTail.then(finishSubsystemTail).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)).then(all{assert(safe),s'=s})
run tailCreatesHandlerTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA.then(freeNodeAKnown)).then(beginSubsystemTail).then(reserveTailB).then(publishBKnown).then(finishSubsystemTail).then(popB).then(returnB).then(freeNodeBKnown).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt).then(all{assert(safe),s'=s})
run reentrantJoinTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(reentrantFinalizeJoin).then(returnA.then(freeNodeAKnown)).then(all{assert(safe),s'=s})
run unknownNodeFreeTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA).then(freeNodeAUnknown).then(all{assert(safe),s'=s})
run unknownCallbackTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(callbackUnknownA).then(all{assert(safe),s'=s})
run emptyLookupTest=init.then(acquireLookup).then(lookupAbsent).then(releaseLookup).then(all{assert(safe),s'=s})
run keyAfterExternalRosterTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA.then(freeNodeAKnown)).then(beginSubsystemTail.then(finishSubsystemTail).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)).then(cancelAbsentFromReceipt).then(attestCacheAndOwnerRoster).then(deleteGenericKey).then(all{assert(safe),s'=s})
run unknownNoCommitTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(reserveChildB).then(publicationAbsentUnknown).then(returnA).then(freeNodeAKnown).then(reconcileAbsentAndRolledBackB).then(beginSubsystemTail.then(finishSubsystemTail).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)).then(all{assert(safe),s'=s})
run emptyQueueStillInflightTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(all{assert(not(s.phase==1 and (s.a==0 or s.a==5) and (s.b==0 or s.b==5) and s.ack!=2 and s.tailLive==0 and s.tailDone==0)),assert(safe),s'=s})
run reentryNotDrainTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(reentrantFinalizeJoin).then(all{assert(not(s.phase==2 and s.lookupPin==0 and s.deps==1)),assert(safe),s'=s})
run unknownRegistrationNotClosedTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(reserveChildB).then(publicationAbsentUnknown).then(returnA).then(freeNodeAKnown).then(all{assert(not(s.phase==1 and (s.a==0 or s.a==5) and (s.b==0 or s.b==5) and s.ack!=2 and s.tailLive==0 and s.tailDone==1)),assert(safe),s'=s})
run tailChildStillQueuedTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA.then(freeNodeAKnown)).then(beginSubsystemTail).then(reserveTailB).then(publishBKnown).then(finishSubsystemTail).then(all{assert(not(s.phase==1 and (s.a==0 or s.a==5) and (s.b==0 or s.b==5) and s.ack!=2 and s.tailLive==0 and s.tailDone==1)),assert(safe),s'=s})
run pendingNodeFreeNotClosedTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA).then(freeNodeAUnknown).then(all{assert(not(s.phase==1 and (s.a==0 or s.a==5) and (s.b==0 or s.b==5) and s.ack!=2 and s.tailLive==0 and s.tailDone==0)),assert(safe),s'=s})
run dataReceiptNotRosterTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA.then(freeNodeAKnown)).then(beginSubsystemTail.then(finishSubsystemTail).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)).then(all{assert(not(s.phase==5 and s.cacheDone==1 and s.allOwners==1 and s.lookupPin==0 and s.key==1)),assert(safe),s'=s})
run lookupPinBlocksDetachTest=init.then(seedRegistrationA).then(beginDrain).then(popA).then(returnA.then(freeNodeAKnown)).then(beginSubsystemTail).then(finishSubsystemTail).then(acquireLookup).then(closeProducers).then(attestNoTsdDependencies).then(all{assert(not(s.phase==2 and s.lookupPin==0 and s.deps==1)),assert(safe),s'=s})
}
