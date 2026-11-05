module ordered_registry_delivery {
 import ordered_delivery_parameters.* from "./ordered_delivery_parameters"
 // Two distinct logical effect occurrences have equal registration payload 7.
 type State={gen:int,trace:List[int],entries:List[int],applied:Set[int],acked:Set[int],receipts:int->int,nextId:int,op:int,pending:bool,
  unknown:bool,owner:bool,receiptGen:int,outcome:int,boundary:int,parsed:bool,parseGen:int,
  saved:bool,roots:bool,drained:bool,cache:bool,workspace:int}
 pure val initial:State={gen:0,trace:List(),entries:List(),applied:Set(),acked:Set(),receipts:Map(0->-1,1->-1),nextId:0,op:-1,pending:false,
  unknown:false,owner:true,receiptGen:-1,outcome:0,boundary:-1,parsed:false,parseGen:-1,
  saved:false,roots:true,drained:false,cache:false,workspace:0}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,workspace:WorkspaceCount-1}
 action prepareEffect=all {s.outcome==0,not(s.pending),s.nextId<2,s.owner,s.roots,
  s'={...s,op:s.nextId,nextId:s.nextId+1,pending:true,receiptGen:-1}}
 action commitEffect=all {s.pending,s.owner,not(s.applied.contains(s.op)),s.op==s.nextId-1,s.outcome==0,
  s'={...s,gen:s.gen+1,trace:s.trace.append(s.op),entries:List(7).concat(s.entries),applied:s.applied.union(Set(s.op)),receipts:s.receipts.set(s.op,s.gen+1),receiptGen:s.gen+1}}
 action loseAck=all {s.pending,s.applied.contains(s.op),s'={...s,unknown:true}}
 action retryDelivery=all {s.pending,s.owner,s.applied.contains(s.op),s'={...s,receiptGen:s.receipts.get(s.op)}}
 action deliverAck=all {s.pending,s.owner,s.applied.contains(s.op),s.receiptGen==s.receipts.get(s.op),
  s'={...s,pending:false,unknown:false,acked:s.acked.union(Set(s.op))}}
 action loseOwner=all {s.pending,s'={...s,owner:false}}
 action returnMacro=all {s.outcome==0,not(s.pending),s.applied==s.acked,s'={...s,outcome:1,boundary:s.gen}}
 action parseNext=all {s.outcome==1,not(s.pending),s.applied==s.acked,s'={...s,parsed:true,parseGen:s.boundary}}
 action failMacro=all {s.outcome==0,s'={...s,outcome:2}}
 action resolveFailure=all {s.outcome==2,s.pending,s.owner,not(s.applied.contains(s.op)),
  s'={...s,pending:false,unknown:false,receiptGen:-1}}
 action saveContinuation=all {s.roots,not(s.drained),s'={...s,saved:true}}
 action retireContinuation=all {s.saved,s'={...s,saved:false}}
 // New legitimate semantic activation has a new EventId even at the same source site.
 action resumeActivation=all {s.outcome==2,s.saved,not(s.pending),not(s.unknown),s.nextId<2,
  s'={...s,outcome:0,saved:false,boundary:-1}}
 action cacheAttach=all {s.outcome==1,not(s.pending),not(s.unknown),s.applied==s.acked,s'={...s,cache:true}}
 action drain=all {s.outcome!=0,not(s.pending),not(s.unknown),not(s.saved),s'={...s,roots:false,drained:true}}
 def safe=s.gen==s.trace.length() and s.gen==s.entries.length() and s.gen==s.applied.size() and
  (s.trace==List() or s.trace==List(0) or s.trace==List(1) or s.trace==List(0,1)) and
  (s.pending or s.unknown or s.saved implies s.roots and not(s.drained)) and
  (s.receiptGen>=0 implies s.applied.contains(s.op) and s.receiptGen==s.receipts.get(s.op)) and
  (s.parsed implies s.outcome==1 and not(s.pending) and s.applied==s.acked and s.parseGen==s.boundary and s.boundary==s.gen) and
  (s.cache implies s.outcome==1 and not(s.unknown) and s.applied==s.acked)
 action step=any {prepareEffect,commitEffect,loseAck,retryDelivery,deliverAck,returnMacro,parseNext,failMacro,resolveFailure,
  saveContinuation,retireContinuation,resumeActivation,cacheAttach,drain,loseOwner,s'=s}
 action duplicateCommit=s'={...s,gen:s.gen+1,entries:List(7).concat(s.entries),trace:s.trace.append(s.op)}
 action dedupByPayload=s'={...s,gen:s.gen+1,trace:s.trace.append(s.op),applied:s.applied.union(Set(s.op)),receipts:s.receipts.set(s.op,s.gen+1),receiptGen:s.gen+1}
 action rollbackPrefix=s'={...s,gen:0,entries:List()}
 action earlyParse=s'={...s,parsed:true,parseGen:s.gen,outcome:1,boundary:s.gen}
 action wrongReceipt=s'={...s,receiptGen:0}
 action loseCustody=s'={...s,roots:false,drained:true}
 action replayAsRetry=s'={...s,gen:s.gen+1,entries:List(7).concat(s.entries)}
 action wrongBoundary=s'={...s,parseGen:0}
 run orderedPairTest=init.then(prepareEffect).then(commitEffect).then(deliverAck).then(prepareEffect).then(commitEffect).then(deliverAck).then(returnMacro).then(parseNext).expect(safe and s.entries==List(7,7))
 run acknowledgementRetryTest=init.then(prepareEffect).then(commitEffect).then(loseAck).then(retryDelivery).then(deliverAck).expect(safe and s.gen==1)
 run exceptionPrefixTest=init.then(prepareEffect).then(commitEffect).then(loseAck).then(failMacro).then(retryDelivery).then(deliverAck).then(drain).expect(safe and s.gen==1)
 run precommitFailureTest=init.then(prepareEffect).then(failMacro).then(resolveFailure).then(drain).expect(safe and s.gen==0)
 run savedCustodyTest=init.then(saveContinuation).then(prepareEffect).then(commitEffect).then(loseAck).then(failMacro).expect(safe and s.roots and s.pending)
 run newActivationTest=init.then(saveContinuation).then(prepareEffect).then(commitEffect).then(deliverAck).then(failMacro).then(resumeActivation).then(prepareEffect).then(commitEffect).then(deliverAck).then(returnMacro).then(parseNext).expect(safe and s.gen==2)
 run abortedIdentityTest=init.then(saveContinuation).then(prepareEffect).then(failMacro).then(resolveFailure).then(resumeActivation).then(prepareEffect).then(commitEffect).then(deliverAck).then(returnMacro).then(parseNext).expect(safe and s.trace==List(1) and s.receiptGen==1)
 run cacheNoReplayTest=init.then(prepareEffect).then(commitEffect).then(deliverAck).then(returnMacro).then(cacheAttach).then(parseNext).expect(safe and s.gen==1)
 run unavailableAuthorityTest=init.then(prepareEffect).then(commitEffect).then(loseAck).then(loseOwner).then(failMacro).expect(safe and s.pending and s.roots and not(s.owner))
 run emptyMacroTest=init.then(returnMacro).then(parseNext).expect(safe and s.gen==0)
 run otherContextTest=initOther.then(prepareEffect).then(commitEffect).then(deliverAck).then(returnMacro).then(parseNext).expect(safe and s.workspace==1)
 run continuationDrainTest=init.then(saveContinuation).then(failMacro).then(retireContinuation).then(drain).expect(safe and s.drained)
 run duplicateDeliveryControlTest=init.then(prepareEffect).then(commitEffect).then(duplicateCommit).expect(not(safe))
 run equalPayloadDedupControlTest=init.then(prepareEffect).then(commitEffect).then(deliverAck).then(prepareEffect).then(dedupByPayload).expect(not(safe))
 run rollbackControlTest=init.then(prepareEffect).then(commitEffect).then(failMacro).then(rollbackPrefix).expect(not(safe))
 run prematureParseControlTest=init.then(prepareEffect).then(commitEffect).then(earlyParse).expect(not(safe))
 run receiptIdentityControlTest=init.then(prepareEffect).then(commitEffect).then(wrongReceipt).expect(not(safe))
 run unknownCustodyControlTest=init.then(prepareEffect).then(commitEffect).then(loseAck).then(failMacro).then(loseCustody).expect(not(safe))
 run semanticReplayControlTest=init.then(prepareEffect).then(commitEffect).then(deliverAck).then(failMacro).then(replayAsRetry).expect(not(safe))
 run staleParseControlTest=init.then(prepareEffect).then(commitEffect).then(deliverAck).then(returnMacro).then(parseNext).then(wrongBoundary).expect(not(safe))
}
