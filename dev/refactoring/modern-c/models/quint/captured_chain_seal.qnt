module captured_chain_seal {
 type State={n:int,copied:int,sealed:int,published:int,target:int,ended:int,reserved:bool,initialized:bool,deferred:bool,owner:bool,suffixReady:bool,retag:bool,done:bool}
 pure val initial:State={n:3,copied:0,sealed:0,published:0,target:0,ended:0,reserved:false,initialized:false,deferred:false,owner:true,suffixReady:false,retag:false,done:false}
 var s:State
 pure def sourceFrameReadable(oldHalf:bool, liveClaim:bool, aligned:bool,
                              available:int, frameWords:int, retiSlot:int):bool =
   oldHalf and liveClaim and aligned and frameWords>0 and frameWords<=available
   and retiSlot<available
 pure def sourceBreakReadable(physical:int, consumed:int, nextSlot:int):bool =
   physical-consumed>nextSlot
 pure def parkedWords(top:int, recordedTop:int, recordedBreak:int, physical:int):int =
   if (top>=recordedTop and top<=recordedBreak) recordedBreak-top else physical
 pure def parkedSuccessorAgrees(base:int, recordedBreak:int, isBreak:bool):bool =
   (base==recordedBreak)==isBreak
 pure def undoMatches(top:int, brk:int, recordedTop:int, recordedBreak:int):bool =
   top==recordedTop and brk==recordedBreak
 pure def breakRestoreReadable(held:bool, liveClaim:bool, available:int,
                               frameWords:int, retiSlot:int):bool =
   held and sourceFrameReadable(true,liveClaim,true,available,frameWords,retiSlot)
 pure def reflectedSlotWritable(admitted:bool, slot:int, fs:int, linkSlot:int, retiSlot:int):bool =
   admitted and slot>0 and slot<=fs and slot!=linkSlot and slot!=retiSlot
 run reflectedPayloadWriteTest=assert(reflectedSlotWritable(true,2,4,1,4))
 run reflectedWideIndexControlTest=assert(not(reflectedSlotWritable(true,4294967298,4,1,4)))
 run reflectedMetadataSlotControlTest=assert(
   not(reflectedSlotWritable(true,1,4,1,4)) and not(reflectedSlotWritable(true,4,4,1,4)))
 run reflectedUnadmittedWriteControlTest=assert(not(reflectedSlotWritable(false,2,4,1,4)))
 action init=s'=initial
 action initEmpty=s'={...initial,n:0}
 val safe=all{
 s.n>=0,s.sealed>=0,s.sealed<=s.copied,s.copied<=s.n,s.copied<=s.sealed+2,
 s.published>=0,s.published<=s.sealed,
 not(s.initialized) implies s.copied<=s.sealed+1,
 s.initialized implies s.reserved,
 (s.reserved or s.copied>s.sealed or s.deferred) implies s.owner,
 s.deferred implies (s.target>0 and s.target<=s.copied),
 (s.ended==1 or s.ended==2) implies (s.copied==s.sealed and not(s.reserved)),
 s.ended==2 implies s.suffixReady,
 s.retag implies (s.ended==1 or s.ended==2),
 s.done implies (not(s.owner) and not(s.deferred) and s.retag and s.published==s.sealed)}
 action reserve=all{s.owner,s.ended==0,not(s.reserved),not(s.initialized),s.copied<s.n,s'={...s,reserved:true}}
 action initializeCopy=all{s.owner,s.reserved,not(s.initialized),s.ended==0,s.copied<s.n,s'={...s,copied:s.copied+1,initialized:true}}
 action resolvePrevious=all{s.initialized,s.copied==s.sealed+2,s'={...s,sealed:s.sealed+1}}
 action finishInstall=all{s.initialized,s.copied==s.sealed+1,s'={...s,initialized:false,reserved:false}}
 action deferChunk=all{s.owner,s.ended==0,not(s.reserved),s.copied==s.sealed+1,not(s.deferred),s'={...s,deferred:true,target:s.copied}}
 action publishDeferred=all{s.deferred,s.sealed>=s.target,s'={...s,deferred:false}}
 action publishPrefix=all{s.owner,s'={...s,published:s.sealed}}
 action certifySuffix=all{s.owner,s.ended==0,s'={...s,suffixReady:true}}
 action terminal=all{s.owner,s.ended==0,not(s.reserved),s.copied==s.n,s'={...s,sealed:s.copied,ended:1}}
 action forwarded=all{s.owner,s.ended==0,not(s.reserved),s.copied<s.n,s.suffixReady,s'={...s,sealed:s.copied,ended:2}}
 action capacityFailure=all{s.owner,s.ended==0,not(s.reserved),s'={...s,ended:3}}
 action retagRoot=all{(s.ended==1 or s.ended==2),s'={...s,retag:true}}
 action release=all{s.owner,s.retag,not(s.deferred),s.published==s.sealed,s'={...s,owner:false,done:true}}
 action step=any{reserve,initializeCopy,resolvePrevious,finishInstall,deferChunk,publishDeferred,publishPrefix,certifySuffix,terminal,forwarded,capacityFailure,retagRoot,release,all{s'=s}}
 action first=reserve.then(initializeCopy).then(finishInstall)
 action subsequent=reserve.then(initializeCopy).then(resolvePrevious).then(finishInstall)
 run fullChainTest=init.then(first).then(deferChunk).then(subsequent).then(publishDeferred).then(publishPrefix).then(deferChunk).then(subsequent).then(publishDeferred).then(terminal).then(publishPrefix).then(retagRoot).then(release).then(all{assert(safe and s.done and s.copied==3),s'=s})
 run terminalPendingTest=init.then(first).then(subsequent).then(subsequent).then(deferChunk).then(terminal).then(publishDeferred).then(all{assert(safe and s.copied==s.sealed),s'=s})
 run forwardedSuffixTest=init.then(first).then(deferChunk).then(certifySuffix).then(forwarded).then(publishDeferred).then(publishPrefix).then(retagRoot).then(release).then(all{assert(safe and s.done and s.copied==1),s'=s})
 run emptyChainTest=initEmpty.then(terminal).then(retagRoot).then(release).then(all{assert(safe and s.done and s.copied==0),s'=s})
 run failureCustodyTest=init.then(first).then(deferChunk).then(capacityFailure).then(all{assert(safe and s.owner and s.deferred and not(s.done)),s'=s})
 run transientTwoDebtTest=init.then(first).then(reserve).then(initializeCopy).then(all{assert(safe and s.copied==s.sealed+2),s'=s})
 run earlyReleaseControlTest=init.then(first).then(all{s'={...s,owner:false}}).then(all{assert(not(safe)),s'=s})
 run earlyPublishControlTest=init.then(first).then(all{s'={...s,published:s.copied}}).then(all{assert(not(safe)),s'=s})
 run unknownSuffixControlTest=init.then(first).then(all{s'={...s,sealed:s.copied,ended:2}}).then(all{assert(not(safe)),s'=s})
 run activeFrameFitsLogicalBreakTest=assert(sourceFrameReadable(true,true,true,4,4,-1))
 run activeLogicalSkipRefusedTest=assert(not(sourceFrameReadable(true,true,true,4,8,-1)))
 run savedRetiOutsideGrantRefusedTest=assert(not(sourceFrameReadable(true,true,true,4,4,4)))
 run forwardedReadNeedsLiveOldClaimTest=assert(not(sourceFrameReadable(true,false,true,4,4,-1)))
 run capturedBreakNeedsPhysicalRoomTest=assert(not(sourceBreakReadable(8,6,2)))
 run parkedBoundRejectsInHalfSkipTest=assert(
   not(sourceFrameReadable(true,true,true,parkedWords(10,8,14,25),6,-1)))
 run olderSuffixRetainsPhysicalBoundTest=assert(parkedWords(16,8,14,25)==25)
 run parkedEndNeedsBreakSuccessorTest=assert(not(parkedSuccessorAgrees(14,14,false)))
 run parkedUndoRejectsChangedTopTest=assert(not(undoMatches(9,14,8,14)))
 run breakRestoreWithLiveSectionGateTest=assert(breakRestoreReadable(true,true,4,4,-1))
 run breakRestoreWithoutSectionGateRefusedTest=assert(not(breakRestoreReadable(false,true,4,4,-1)))
 run breakRestoreRetiOutsideParkedRefusedTest=assert(not(breakRestoreReadable(true,true,4,4,4)))
}

// Two logical segments in one half. This module composes custody cuts.
// Frame-size arithmetic and concrete memory ordering belong to their owners.
module raw_suffix_handoff {
  type State = {
    aEnd: int, bEnd: int, sourcePin: bool, targetPin: bool,
    edgeInstalled: bool, crossingDone: bool, revision: int, writer: bool,
    frozen: bool, attempt: int, copies: int, phase: int, ack: bool,
    aliasLive: bool, retired: bool, generation: int
  }
  var h: State
  action init = h' = {
    aEnd: 0, bEnd: 0, sourcePin: false, targetPin: false,
    edgeInstalled: false, crossingDone: false, revision: 0, writer: false,
    frozen: false, attempt: 0, copies: 0, phase: 0, ack: false,
    aliasLive: false, retired: false, generation: 1
  }
  action captureA = all { h.aEnd == 0, h' = {...h, aEnd: 12, aliasLive: true} }
  action captureB = all { h.aEnd == 12, h.bEnd == 0, h' = {...h, bEnd: 8} }
  action pinSource = all { h.bEnd == 8, not(h.edgeInstalled), not(h.sourcePin),
    h' = {...h, sourcePin: true} }
  def successorAdmissible(generation: int): bool =
    h.sourcePin and h.aliasLive and not(h.retired) and generation == h.generation
  action pinSuccessor = all { successorAdmissible(1), not(h.targetPin),
    h' = {...h, targetPin: true, edgeInstalled: true} }
  action finishCrossing = all { h.sourcePin, h.targetPin, h.edgeInstalled,
    h' = {...h, sourcePin: false, crossingDone: true} }
  def writable(revision: int): bool =
    h.targetPin and not(h.frozen) and revision == h.revision
  action claimWriter = all { writable(0), not(h.writer), h' = {...h, writer: true} }
  action publishRewrite = all { h.writer, writable(0),
    h' = {...h, revision: 1, writer: false} }
  def freezeAdmissible: bool = h.crossingDone and not(h.writer) and not(h.frozen)
  action freeze = all { freezeAdmissible, h' = {...h, frozen: true} }

  // phase 1: reserved; 2: forwarding visible and scan debt held;
  // 3: target and scan custody committed. No delivered ACK is assumed.
  def copyAdmissible: bool = h.frozen and h.targetPin and h.attempt == 0
  action beginCopy = all { copyAdmissible, h' = {...h, attempt: 1, phase: 1, copies: 1} }
  action publishForwarding = all { h.phase == 1, h' = {...h, phase: 2} }
  action commitScan = all { h.phase == 2, h' = {...h, phase: 3} }
  def queryResult(attempt: int): int =
    if (attempt != h.attempt or attempt == 0 or h.retired) 0 else h.phase
  action acknowledgeOriginal = all { queryResult(1) == 3, not(h.ack),
    h' = {...h, ack: true} }
  action releaseTarget = all { h.ack, h.targetPin, h' = {...h, targetPin: false} }
  action dropAlias = all { h.ack, h.aliasLive, h' = {...h, aliasLive: false} }
  def retireAdmissible: bool =
    h.ack and not(h.aliasLive or h.sourcePin or h.targetPin or h.writer or h.retired)
  action retire = all { retireAdmissible, h' = {...h, retired: true} }
  action reuseHalf = all { h.retired, h.generation == 1, h' = {...h, generation: 2} }

  val safe = all {
    h.bEnd == 8 implies h.aEnd == 12,
    h.crossingDone implies h.edgeInstalled,
    (h.edgeInstalled and not(h.crossingDone)) implies (h.sourcePin and h.targetPin),
    (h.edgeInstalled and not(h.ack)) implies h.targetPin,
    h.writer implies (h.targetPin and not(h.frozen)),
    h.copies <= 1,
    h.ack implies (h.attempt == 1 and h.phase == 3),
    (h.phase == 2 or (h.phase == 3 and not(h.ack))) implies (h.targetPin and h.aliasLive),
    h.retired implies (h.ack and not(h.sourcePin or h.targetPin or h.aliasLive or h.writer))
  }
  action step = any { captureA, captureB, pinSource, pinSuccessor, finishCrossing,
    claimWriter, publishRewrite, freeze, beginCopy, publishForwarding, commitScan,
    acknowledgeOriginal, releaseTarget, dropAlias, retire, reuseHalf, h' = h }

  action twoCaptures = init.then(captureA).then(captureB)
  action crossed = twoCaptures.then(pinSource).then(pinSuccessor).then(finishCrossing)
  action lostAck = crossed.then(claimWriter).expect(not(freezeAdmissible))
    .then(publishRewrite).then(freeze).then(beginCopy).then(publishForwarding)

  pure def containedFrame(top: int, frameWords: int, start: int, logicalEnd: int): bool =
    start <= top and top < logicalEnd and frameWords > 0 and frameWords <= logicalEnd - top
  run distinctRecordedSpansAcceptExactFramesTest = assert(
    containedFrame(12, 4, 12, 16) and containedFrame(4, 4, 4, 8))
  run recordedCaptureObjectGapRefusedTest = assert(not(
    containedFrame(10, 2, 4, 8) or containedFrame(10, 2, 12, 16)))
  run olderRecordedEndRejectsInHalfOverrunTest = assert(not(containedFrame(12, 8, 12, 16)))

  run doubleCaptureToRetireTest = lostAck
    .expect(safe and queryResult(1) == 2 and queryResult(2) == 0 and not(copyAdmissible))
    .then(commitScan).expect(queryResult(1) == 3 and not(h.ack) and not(retireAdmissible))
    .then(acknowledgeOriginal).expect(not(retireAdmissible))
    .then(releaseTarget).then(dropAlias).then(retire).then(reuseHalf)
    .expect(safe and h.copies == 1 and queryResult(1) == 0 and not(successorAdmissible(1)))
  run staleSuccessorBeforeReadTest = twoCaptures.then(pinSource)
    .expect(successorAdmissible(1) and not(successorAdmissible(0)))
  run freezeWinsBeforeStoreTest = crossed.then(freeze).expect(not(writable(0)))
  run overwrittenEndControlTest = twoCaptures
    .then(all { h' = {...h, aEnd: h.bEnd} }).expect(not(safe))
  run droppedSourcePinControlTest = twoCaptures.then(pinSource).then(pinSuccessor)
    .then(all { h' = {...h, sourcePin: false} }).expect(not(safe))
  run duplicateCopyControlTest = lostAck
    .then(all { h' = {...h, copies: 2} }).expect(not(safe))
  run ackFromForwardingWordControlTest = lostAck
    .then(all { h' = {...h, ack: true} }).expect(not(safe))
}
