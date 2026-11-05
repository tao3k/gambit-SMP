// Bounded abstract control protocol; GC/complete source views and producer sealing are explicit premises.
module request_retirement {
 val W=2
 val K=3
 val G=2
 val Keys=0.to(K*G-1)
 type S={ready:bool,gate:bool,gen:int,next:int,floor:int,gc:bool,handlesClosed:bool,
  issued:Set[int],settled:Set[int],queued:Set[int],records:Set[int],roots:Set[int],
  source:Set[int],need:Set[int],sourceAck:Set[int],resultAck:Set[int],closed:Set[int],
  owners:Set[int],escrow:Set[int],consumers:Set[int],qpin:Set[int],dpin:Set[int],scan:Set[int],scanSource:Set[int],
  terminal:Set[int],effects:int->int,slot:int->int,oom:int,rejected:int}
 var s:S
 def current(k:int):bool=k/K==s.gen
 def inWindow(k:int):bool=current(k) and k%K>=s.floor and k%K<s.next
 val allocatable=s.ready and s.gate and s.next<K and s.next-s.floor<W
 action init=s'={ready:true,gate:true,gen:0,next:0,floor:0,gc:false,handlesClosed:false,
  issued:Set(),settled:Set(),queued:Set(),records:Set(),roots:Set(),source:Set(),need:Set(),
  sourceAck:Set(),resultAck:Set(),closed:Set(),owners:Set(),escrow:Set(),consumers:Set(),qpin:Set(),dpin:Set(),scan:Set(),scanSource:Set(),terminal:Set(),
  effects:Keys.mapBy(_=>0),slot:0.to(W-1).mapBy(_=>-1),oom:0,rejected:0}
 action poolInitFail=all{s.issued.size()==0,s'={...s,ready:false,gate:false,oom:s.oom+1}}
 // No request/key is issued on preflight OOM; the complete caller frame remains natural root.
 action preflightFail=all{s.ready,s'={...s,oom:s.oom+1}}
 action reserve=all{allocatable,
  val k=s.gen*K+s.next
  s'={...s,next:s.next+1,issued:s.issued.union(Set(k)),records:s.records.union(Set(k)),
    source:s.source.union(Set(k)),need:s.need.union(Set(k)),owners:s.owners.union(Set(k)),slot:s.slot.set(k%W,k)}}
 action queue(k:int):bool=all{s.records.contains(k),not(s.closed.contains(k)),s'= {...s,queued:s.queued.union(Set(k))}}
 action pinDelivery(k:int):bool=all{s.queued.contains(k),inWindow(k),s.records.contains(k),not(s.settled.contains(k)),
   s'={...s,dpin:s.dpin.union(Set(k))}}
 action accept(k:int):bool=all{s.dpin.contains(k),s.records.contains(k),not(s.closed.contains(k)),not(s.gc),
   not(s.roots.contains(k)),not(s.terminal.contains(k)),s.source.contains(k),s.effects.get(k)==0,
   s'={...s,roots:s.roots.union(Set(k)),effects:s.effects.set(k,1)}}
 action unpinDelivery(k:int):bool=all{s.dpin.contains(k),s'={...s,dpin:s.dpin.exclude(Set(k)),queued:s.queued.exclude(Set(k))}}
 // Key-only late envelopes cannot carry a dereferenceable control/source pointer.
 action rejectLate(k:int):bool=all{s.queued.contains(k),(not(inWindow(k)) or s.settled.contains(k) or s.closed.contains(k)),
   not(s.dpin.contains(k)),s'={...s,queued:s.queued.exclude(Set(k)),rejected:s.rejected+1}}
 action retry(k:int):bool=all{s.issued.contains(k),s'={...s,queued:s.queued.union(Set(k))}}
 action pinQuery(k:int):bool=all{inWindow(k),s.records.contains(k),not(s.settled.contains(k)),s'={...s,qpin:s.qpin.union(Set(k))}}
 action unpinQuery(k:int):bool=all{s.qpin.contains(k),s'={...s,qpin:s.qpin.exclude(Set(k))}}
 action sourceAck(k:int):bool=all{s.records.contains(k),s.roots.contains(k) or s.terminal.contains(k),
   s'={...s,sourceAck:s.sourceAck.union(Set(k))}}
 action releaseSource(k:int):bool=all{s.sourceAck.contains(k),not(s.scan.contains(k)),
   s'={...s,source:s.source.exclude(Set(k))}}
 action closeProducer(k:int):bool=all{s.records.contains(k),s'={...s,closed:s.closed.union(Set(k))}}
 action takeEscrow(k:int):bool=all{s.records.contains(k),s.source.contains(k) or s.roots.contains(k),
   s'={...s,escrow:s.escrow.union(Set(k))}}
 action exitOwner(k:int):bool=all{s.escrow.contains(k),s.closed.contains(k),s'={...s,owners:s.owners.exclude(Set(k))}}
 action consume(k:int):bool=all{s.roots.contains(k),not(s.closed.contains(k)),s'={...s,consumers:s.consumers.union(Set(k))}}
 action drainConsumer(k:int):bool=all{s.closed.contains(k),s'={...s,consumers:s.consumers.exclude(Set(k))}}
 action cancelOrFinish(k:int):bool=all{s.records.contains(k),s.closed.contains(k),not(s.consumers.contains(k)),not(s.gc),not(s.scan.contains(k)),
   s'={...s,roots:s.roots.exclude(Set(k)),need:s.need.exclude(Set(k)),terminal:s.terminal.union(Set(k))}}
 action resultAck(k:int):bool=all{s.terminal.contains(k),s'={...s,resultAck:s.resultAck.union(Set(k))}}
 // Compact to a fixed bitmap bit only after every pointer-bearing view is gone.
 action summarize(k:int):bool=all{s.records.contains(k),s.terminal.contains(k),s.sourceAck.contains(k),s.resultAck.contains(k),
   s.closed.contains(k),not(s.source.contains(k)),not(s.roots.contains(k)),not(s.qpin.contains(k)),not(s.dpin.contains(k)),not(s.scan.contains(k)),not(s.consumers.contains(k)),
   s'={...s,records:s.records.exclude(Set(k)),settled:s.settled.union(Set(k))}}
 action advance=all{s.floor<s.next,s.settled.contains(s.gen*K+s.floor),s'={...s,floor:s.floor+1}}
 action closeGC=all{not(s.gc),s'={...s,gc:true,scan:s.records.intersect(s.source.union(s.roots)),scanSource:s.records.intersect(s.source)}}
 action endGC=all{s.gc,s'={...s,gc:false,scan:Set(),scanSource:Set()}}
 action closeDomain=all{s.gate,s'={...s,gate:false}}
 // External seal excludes all old raw borrowers/producers; no timing or join-error inference.
 action sealHandles=all{not(s.gate),s.floor==s.next,not(s.gc),s.qpin.size()==0,s.dpin.size()==0,
   s'={...s,handlesClosed:true}}
 action rotate=all{s.handlesClosed,not(s.gate),s.floor==s.next,s.next==K,s.gen+1<G,
   s'={...s,gen:s.gen+1,next:0,floor:0,gate:true,handlesClosed:false,slot:0.to(W-1).mapBy(_=>-1)}}
 action idle=s'=s
 val safe=all{0<=s.floor,s.floor<=s.next,s.next<=K,s.next-s.floor<=W,s.gen<G,
  s.records.size()<=W,s.records.subseteq(s.issued),s.settled.subseteq(s.issued),s.records.intersect(s.settled).size()==0,
  s.need.subseteq(s.source.union(s.roots)),s.roots.subseteq(s.records),s.scan.subseteq(s.source.union(s.roots)),s.scanSource.subseteq(s.source),
  s.qpin.subseteq(s.records),s.dpin.subseteq(s.records),s.consumers.subseteq(s.roots),
  s.issued.forall(k=> s.owners.contains(k) or (s.escrow.contains(k) and s.closed.contains(k))),
  s.settled.forall(k=>s.sourceAck.contains(k) and s.resultAck.contains(k) and s.closed.contains(k)),
  0.to(s.floor-1).forall(i=>s.settled.contains(s.gen*K+i)),
  s.records.forall(k=>inWindow(k) and s.slot.get(k%W)==k),
  Keys.forall(k=>s.effects.get(k)<=1),
  not(s.ready) implies s.issued.size()==0}
 action step=any{reserve,preflightFail,closeGC,endGC,closeDomain,sealHandles,rotate,idle,
  nondet k=Keys.oneOf()
  any{queue(k),pinDelivery(k),accept(k),unpinDelivery(k),retry(k),rejectLate(k),pinQuery(k),unpinQuery(k),sourceAck(k),releaseSource(k),
    closeProducer(k),takeEscrow(k),exitOwner(k),consume(k),drainConsumer(k),cancelOrFinish(k),resultAck(k),summarize(k)},poolInitFail}
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action complete(k:int):bool=closeProducer(k).then(cancelOrFinish(k)).then(sourceAck(k)).then(releaseSource(k)).then(resultAck(k)).then(summarize(k))
 action published=init.then(reserve).then(queue(0))
 action accepted=published.then(pinDelivery(0)).then(accept(0)).then(unpinDelivery(0))
 action pairInit=init.then(reserve).then(reserve)
 action exhausted=init.then(reserve).then(complete(0)).then(advance).then(reserve).then(complete(1)).then(advance).then(reserve).then(complete(2)).then(advance)
 action rotated=exhausted.then(closeDomain).then(sealHandles).then(rotate)
 action badMaxSeen=s'={...s,floor:s.next}
 action badWrap=s'={...s,next:0,floor:0}
 action badDuplicate(k:int):bool=s'={...s,effects:s.effects.set(k,2)}
 action badFreePinned(k:int):bool=s'={...s,records:s.records.exclude(Set(k)),settled:s.settled.union(Set(k))}
 action badDropSource(k:int):bool=s'={...s,source:s.source.exclude(Set(k))}
 action badExit(k:int):bool=s'={...s,owners:s.owners.exclude(Set(k))}
 action badReuseSlot=s'={...s,slot:s.slot.set(0,2)}
 action badFailAfterEffect(k:int):bool=s'={...s,roots:s.roots.exclude(Set(k)),source:s.source.exclude(Set(k))}
 action badTerminalNoResult(k:int):bool=s'={...s,records:s.records.exclude(Set(k)),settled:s.settled.union(Set(k))}
 run outOfOrderKeepsHoleTest=pairInit.then(complete(1)).then(check)
 run fillHoleAdvancesBothTest=pairInit.then(complete(1)).then(complete(0)).then(advance).then(advance).then(check)
 run lateBeforePrefixRejectedTest=pairInit.then(complete(1)).then(retry(1)).then(rejectLate(1)).then(check)
 run lateAfterPrefixRejectedTest=init.then(reserve).then(complete(0)).then(advance).then(retry(0)).then(rejectLate(0)).then(check)
 run boundedWindowRejectsThirdWithoutIssueTest=pairInit.then(all{assert(not(allocatable)),s'=s}).then(check)
 run headHoleBlocksReuseButNotGCTest=pairInit.then(complete(1)).then(closeGC).then(endGC).then(check)
 run safeSlotReuseAfterPrefixTest=pairInit.then(complete(0)).then(advance).then(reserve).then(check)
 run oldEnvelopeAfterSlotReuseRejectedTest=pairInit.then(complete(0)).then(advance).then(reserve).then(retry(0)).then(rejectLate(0)).then(check)
 run publishedDuplicateAcceptsOnlyOnceTest=accepted.then(retry(0)).then(pinDelivery(0)).then(unpinDelivery(0)).then(check)
 run allocatorFailureBeforeIssueKeepsNaturalFrameTest=init.then(preflightFail).then(check)
 run poolInitFailureMakesVmUnavailableTest=init.then(poolInitFail).then(all{assert(not(allocatable)),s'=s}).then(check)
 run postPublicationOomDoesNotCancelOwnershipTest=published.then(preflightFail).then(pinDelivery(0)).then(accept(0)).then(unpinDelivery(0)).then(check)
 run pendingOomExceptionUsesReservedEscrowTest=published.then(preflightFail).then(takeEscrow(0)).then(closeProducer(0)).then(exitOwner(0)).then(complete(0)).then(rejectLate(0)).then(check)
 run gcCloseKeepsPendingSourceTest=published.then(closeGC).then(preflightFail).then(takeEscrow(0)).then(closeProducer(0)).then(exitOwner(0)).then(endGC).then(complete(0)).then(check)
 run gcScanDelaysPhysicalSourceReleaseTest=accepted.then(closeGC).then(sourceAck(0)).then(check)
 run queryPinSurvivesTerminalAndOomTest=accepted.then(pinQuery(0)).then(preflightFail).then(closeProducer(0)).then(cancelOrFinish(0)).then(sourceAck(0)).then(releaseSource(0)).then(resultAck(0)).then(unpinQuery(0)).then(summarize(0)).then(check)
 run deliveryPinBlocksSummaryTest=published.then(pinDelivery(0)).then(closeProducer(0)).then(cancelOrFinish(0)).then(sourceAck(0)).then(releaseSource(0)).then(resultAck(0)).then(unpinDelivery(0)).then(summarize(0)).then(check)
 run acceptedConsumerDrainsBeforeSummaryTest=accepted.then(consume(0)).then(takeEscrow(0)).then(closeProducer(0)).then(exitOwner(0)).then(drainConsumer(0)).then(complete(0)).then(check)
 run sourceAckDoesNotImplyResultAckTest=accepted.then(sourceAck(0)).then(releaseSource(0)).then(check)
 run lostResultKeepsControlWindowTest=accepted.then(closeProducer(0)).then(cancelOrFinish(0)).then(sourceAck(0)).then(releaseSource(0)).then(check)
 run sequenceExhaustionDoesNotWrapTest=exhausted.then(all{assert(not(allocatable)),s'=s}).then(check)
 run rotationNeedsClosedDomainTest=exhausted.then(closeDomain).then(sealHandles).then(rotate).then(check)
 run oldGenerationRejectedAfterRotationTest=rotated.then(reserve).then(retry(0)).then(rejectLate(0)).then(check)
 run sameSequenceDifferentGenerationTest=rotated.then(reserve).then(queue(3)).then(pinDelivery(3)).then(accept(3)).then(unpinDelivery(3)).then(check)
 run holeMaxSeenCounterexampleTest=pairInit.then(complete(1)).then(badMaxSeen).then(reject)
 run numericWrapCounterexampleTest=published.then(badWrap).then(reject)
 run duplicateEffectCounterexampleTest=accepted.then(badDuplicate(0)).then(reject)
 run pinnedQueryFreedCounterexampleTest=accepted.then(pinQuery(0)).then(closeProducer(0)).then(cancelOrFinish(0)).then(sourceAck(0)).then(releaseSource(0)).then(resultAck(0)).then(badFreePinned(0)).then(reject)
 run earlySourceReleaseCounterexampleTest=published.then(badDropSource(0)).then(reject)
 run exceptionWithoutEscrowCounterexampleTest=published.then(closeProducer(0)).then(badExit(0)).then(reject)
 run slotReusedOverHoleCounterexampleTest=pairInit.then(badReuseSlot).then(reject)
 run postEffectOomCannotForgetOwnershipCounterexampleTest=accepted.then(badFailAfterEffect(0)).then(reject)
 run sourceAckIsNotResultReceiptCounterexampleTest=accepted.then(closeProducer(0)).then(cancelOrFinish(0)).then(sourceAck(0)).then(releaseSource(0)).then(badTerminalNoResult(0)).then(reject)
 run scanReferencePreventsFreeCounterexampleTest=accepted.then(closeGC).then(sourceAck(0)).then(badDropSource(0)).then(reject)
 action allExhausted=rotated.then(reserve).then(complete(3)).then(advance).then(reserve).then(complete(4)).then(advance).then(reserve).then(complete(5)).then(advance).then(closeDomain).then(sealHandles)
 run finalGenerationExhaustionRefusesTest=allExhausted.then(all{assert(not(allocatable)),assert(s.gen+1>=G),s'=s}).then(check)
 run cancelledBeforeFirstDeliveryRejectsLateTest=published.then(complete(0)).then(advance).then(rejectLate(0)).then(check)
 run issuedButUnpublishedAbortLeavesNoHoleTest=init.then(reserve).then(complete(0)).then(advance).then(check)
 action negativeInit=pairInit.then(complete(1))
 action negativeStep=badMaxSeen
}
