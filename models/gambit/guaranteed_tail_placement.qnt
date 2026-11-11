module guaranteed_tail_placement {
  // Abstract words, NOT native memory samples. One backing region [0,24),
  // copy/write fence 14, future context [16,24), logical limit21 and guard3.
  // Baseline illustrative phase maximum =20+24+8+4=56. Candidate metadata=6.
  type State = { phase:int, backed:bool, planLive:bool, guarantee:bool,
    receiverAccepted:bool, forwarded:bool, ready:bool, contextOwner:bool,
    replyKnown:bool, qCredit:int, fresh:int, copyEnd:int, cursor:int,
    epoch:int, proofEpoch:int, entryValid:bool, pending:bool, peak:int, historyFloor:int,
    extra:int, quarantined:bool }
  var s: State
  pure def larger(a:int,b:int):int = if(a>=b) a else b
  pure def occupancy(t:State):int = 20 + (if(t.backed) 24 else 0) + t.fresh + 6 + t.extra
  pure def observed(t:State):State = { ...t, peak:larger(t.peak,occupancy(t)), historyFloor:larger(t.historyFloor,occupancy(t)) }
  action init = s'={phase:0,backed:false,planLive:false,guarantee:false,
    receiverAccepted:false,forwarded:false,ready:false,contextOwner:false,
    replyKnown:true,qCredit:0,fresh:0,copyEnd:0,cursor:16,
    epoch:1,proofEpoch:1,entryValid:false,pending:false,peak:26,historyFloor:26,
    extra:0,quarantined:false}
  val safe = s.copyEnd<=14 and s.copyEnd>=0 and s.cursor>=16 and s.cursor<=24 and
    s.fresh>=0 and s.qCredit>=0 and s.qCredit<=8 and s.peak>=occupancy(s) and s.peak>=s.historyFloor and
    (s.qCredit==0 or (s.backed and s.planLive and s.guarantee and s.receiverAccepted and s.fresh==0)) and
    (not(s.forwarded) or (s.backed and s.planLive)) and
    (not(s.contextOwner) or (s.ready and s.backed and s.planLive)) and
    (not(s.entryValid) or (s.contextOwner and s.replyKnown and s.proofEpoch==s.epoch)) and
    (not(s.quarantined) or (s.backed and not(s.entryValid)))
  action acquireGuaranteed = all {s.phase==0,
    s'=observed({...s,phase:1,backed:true,planLive:true,guarantee:true,
      receiverAccepted:true,qCredit:8,fresh:0})}
  action acquireSeparate = all {s.phase==0,
    s'=observed({...s,phase:1,backed:true,planLive:true,fresh:8})}
  action refuseBeforeAcquisition = all {s.phase==0,s'={...s,phase:8}}
  action rejectAcquiredBeforeForward = all {s.phase==1,not(s.forwarded),
    s'={...s,phase:8,backed:false,planLive:false,guarantee:false,
      receiverAccepted:false,qCredit:0,fresh:0}}
  action copy = all {s.phase==1,s.backed,s.planLive,
    s'={...s,phase:2,forwarded:true,copyEnd:14,ready:true}}
  action commit = all {s.phase==2,s.ready,
    s'={...s,phase:3,contextOwner:true,replyKnown:false}}
  action readBack = all {s.phase==3,s.contextOwner,
    s'={...s,replyKnown:true,entryValid:true,proofEpoch:s.epoch}}
  // Late physical refund: never reclassify it as preflight Qg credit.
  action lateRefund = all {s.phase==3,s.contextOwner,s.replyKnown,not(s.guarantee),
    s'={...s,fresh:0}}
  action fastSpan = all {s.phase==3,s.entryValid,s.cursor<=21,
    s'={...s,cursor:s.cursor+3}}
  action requestSlow = all {s.phase==3,s.entryValid,s.cursor>21,
    s'={...s,phase:4,entryValid:false,pending:true}}
  action rebindAfterGc = all {s.phase==4,s.pending,
    s'={...s,phase:3,epoch:s.epoch+1,proofEpoch:s.epoch+1,
      cursor:16,entryValid:true,pending:false}}
  action addRestoreOverlap = all {s.phase==2,
    s'=observed({...s,extra:8})}
  action releaseRestoreOverlap = all {s.phase==3,s.extra>0,s'={...s,extra:0}}
  action quarantine = all {s.forwarded,not(s.contextOwner),
    s'={...s,phase:9,quarantined:true,entryValid:false}}
  action stutter = s'=s
  action step = any {acquireGuaranteed,acquireSeparate,refuseBeforeAcquisition,
    rejectAcquiredBeforeForward,copy,commit,readBack,lateRefund,fastSpan,
    requestSlow,rebindAfterGc,addRestoreOverlap,releaseRestoreOverlap,quarantine,stutter}
  action badCopyIntoFutureTail = s'={...s,copyEnd:17}
  action badCreditWithoutBacking = s'={...s,qCredit:8,guarantee:true,planLive:true,receiverAccepted:true}
  action badDoubleFreshCredit = s'={...s,fresh:8}
  action badSmallGuard = s'={...s,cursor:25}
  action badStaleEntry = s'={...s,epoch:s.epoch+1}
  action badRefundPublishedPlan = s'={...s,backed:false,planLive:false}
  action badUnknownReentry = s'={...s,entryValid:true}
  action badForgetEarlierPeak = s'={...s,peak:occupancy(s)}
  action guaranteedRun = acquireGuaranteed.then(copy).then(commit).then(readBack)
  action lateRun = acquireSeparate.then(copy).then(commit).then(readBack).then(lateRefund)
  run guaranteedPeakTest = init.then(guaranteedRun).expect(safe and s.peak==50 and s.peak<56)
  run lateRefundNoPeakGainTest = init.then(lateRun).expect(safe and s.peak==58 and occupancy(s)==50)
  run otherPhaseDefeatsQgTest = init.then(acquireGuaranteed).then(copy).then(addRestoreOverlap)
    .then(commit).then(readBack).then(releaseRestoreOverlap).expect(safe and s.peak==58)
  run guardAtEqualityTest = init.then(guaranteedRun).then(fastSpan).then(fastSpan).expect(safe and s.cursor==22)
  run slowReloadTest = init.then(guaranteedRun).then(fastSpan).then(fastSpan).then(requestSlow)
    .then(rebindAfterGc).then(fastSpan).expect(safe and s.epoch==2 and s.cursor==19)
  run preflightRefusalTest = init.then(refuseBeforeAcquisition).expect(safe and not(s.forwarded))
  run knownPrivateRefundTest = init.then(acquireGuaranteed).then(rejectAcquiredBeforeForward).expect(safe and not(s.backed) and s.peak==50)
  run futureSuffixExclusionControlTest = init.then(acquireGuaranteed).then(badCopyIntoFutureTail).expect(not(safe))
  run unbackedCreditControlTest = init.then(badCreditWithoutBacking).expect(not(safe))
  run doubleCreditControlTest = init.then(acquireGuaranteed).then(badDoubleFreshCredit).expect(not(safe))
  run insufficientGuardControlTest = init.then(guaranteedRun).then(badSmallGuard).expect(not(safe))
  run staleBindingControlTest = init.then(guaranteedRun).then(badStaleEntry).expect(not(safe))
  run unknownCommitCustodyTest = init.then(acquireGuaranteed).then(copy).then(commit).expect(safe and not(s.replyKnown) and not(s.entryValid))
  run unknownCommitEntryControlTest = init.then(acquireGuaranteed).then(copy).then(commit).then(badUnknownReentry).expect(not(safe))
  run forwardedRefundControlTest = init.then(acquireGuaranteed).then(copy).then(badRefundPublishedPlan).expect(not(safe))
  run postForwardFailureTest = init.then(acquireGuaranteed).then(copy).then(quarantine).expect(safe and s.backed)
  run lateRefundPeakRewriteControlTest = init.then(lateRun).then(badForgetEarlierPeak).expect(not(safe))
}
