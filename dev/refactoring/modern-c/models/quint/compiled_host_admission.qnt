module compiled_host_admission {
  // Family 7 (7/12: stress-gsc) stateful concurrent protocol model.
  // Models dynamic .o1 producer/ABI binding, compiled write-group demand admission,
  // Fix 1C register scrubbing before GC root scan, Fix 1A-ext primlock deferral,
  // post-GC cursor reload before first compiled write, Feeley (1993) back-edge
  // ___POLL retention in (not safe) tight loops, and cross-module .o1 <-> lib/_thread.o
  // interrupt closure delivery with single settlement.
  //
  // Scope: finite two-processor abstract protocol model. Physical address arithmetic,
  // C memory ordering, and native workload completion remain separate Lean/CBMC/native gates.

  type Proc = {
    phase: str,             // "idle" | "demand_short" | "scrubbed" | "parked_gc" | "reloaded" | "writing" | "looping"
    epoch: int,
    reloaded: bool,
    room: int,
    needWords: int,
    demandActive: bool,
    hasRawSpillInReg: bool,
    regsScrubbed: bool,
    primlockHeld: bool,
    interruptDeferred: bool,
    loopHasPoll: bool,
    pollChecked: bool,
    wroteWords: int
  }

  type State = {
    // Artifact cohort identity (Link 3 -> Link 4)
    producerId: int,
    emittedCProducer: int,
    linkedO1Producer: int,
    dynamicGstateExportsBound: bool,
    o1Loaded: bool,
    lblCount: int,
    // Collector & synchronization epoch
    gcEpoch: int,
    gcRequested: bool,
    gcScannedCorruptReg: bool,
    gcRendezvousStarved: bool,
    // Two SMP processors (p0 runs compiled .o1 host; p1 runs peer / interrupt target)
    p0: Proc,
    p1: Proc,
    // Cross-module .o1 closure interrupt settlement (.o1 inc! inside lib/_thread.o)
    intrPending: bool,
    intrClaimed: bool,
    intrSettledCount: int,
    intrUnwound: bool,
    // Safety-violation flags for explicit counterexample falsifiers
    illegalLoad: bool,
    illegalFirstWrite: bool,
    duplicateSettlement: bool
  }

  pure def initProc: Proc = {
    phase: "idle",
    epoch: 1,
    reloaded: true,
    room: 16,
    needWords: 0,
    demandActive: false,
    hasRawSpillInReg: false,
    regsScrubbed: true,
    primlockHeld: false,
    interruptDeferred: false,
    loopHasPoll: true,
    pollChecked: false,
    wroteWords: 0
  }

  var s: State

  action init = {
    s' = {
      producerId: 9,
      emittedCProducer: 0,
      linkedO1Producer: 0,
      dynamicGstateExportsBound: false,
      o1Loaded: false,
      lblCount: 240,
      gcEpoch: 1,
      gcRequested: false,
      gcScannedCorruptReg: false,
      gcRendezvousStarved: false,
      p0: initProc,
      p1: initProc,
      intrPending: false,
      intrClaimed: false,
      intrSettledCount: 0,
      intrUnwound: false,
      illegalLoad: false,
      illegalFirstWrite: false,
      duplicateSettlement: false
    }
  }

  // Phase 1 & 2: gsc/gsc emits .c and gambuild-C links dynamic .o1 only when ___GSTATE dynamic exports are bound
  action compileAndLinkO1(prod: int, labels: int): bool = all {
    not(s.o1Loaded),
    prod > 0,
    labels > 0,
    labels < 6000,
    s' = { ...s, emittedCProducer: prod, linkedO1Producer: prod, dynamicGstateExportsBound: true, lblCount: labels }
  }

  // Negative fault injection: dynamic .o1 referencing raw external symbols without ___GSTATE ___EXT exports
  action faultMissingDynamicGstateExport(prod: int, labels: int): bool = all {
    not(s.o1Loaded),
    prod > 0,
    s' = { ...s, emittedCProducer: prod, linkedO1Producer: prod, dynamicGstateExportsBound: false, o1Loaded: true, illegalLoad: true, lblCount: labels }
  }

  // Phase 3: gsi loads .o1 only when emitted .c, linked .o1, and ___GSTATE exports match the active producer
  action loadO1IntoGsi = all {
    not(s.o1Loaded),
    s.emittedCProducer == s.producerId,
    s.linkedO1Producer == s.producerId,
    s.dynamicGstateExportsBound,
    s.lblCount < 6000,
    s' = { ...s, o1Loaded: true }
  }

  // Negative fault injection: loading a stale .o1 compiled by a different producer
  action faultLoadStaleO1 = all {
    not(s.o1Loaded),
    s.linkedO1Producer != 0,
    s.linkedO1Producer != s.producerId,
    s' = { ...s, o1Loaded: true, illegalLoad: true }
  }

  // Compiled .o1 fast-path write group: sufficient room on current epoch
  action compiledWriteGroupFast(need: int): bool = all {
    s.o1Loaded,
    s.p0.phase == "idle",
    s.p0.epoch == s.gcEpoch,
    s.p0.reloaded,
    need > 0,
    s.p0.room >= need,
    s' = {
      ...s,
      p0: { ...s.p0, phase: "writing", needWords: need, demandActive: true, wroteWords: need, room: s.p0.room - need }
    }
  }

  // Compiled .o1 shortage path: insufficient room triggers ___group_demand_enter -> handler_stack_limit
  action compiledWriteGroupShortage(need: int, rawSpill: bool, holdsLock: bool): bool = all {
    s.o1Loaded,
    s.p0.phase == "idle",
    need > 0,
    s.p0.room < need,
    s' = {
      ...s,
      gcRequested: true,
      p0: {
        ...s.p0,
        phase: "demand_short",
        needWords: need,
        demandActive: true,
        hasRawSpillInReg: rawSpill,
        regsScrubbed: not(rawSpill),
        primlockHeld: holdsLock,
        reloaded: false
      }
    }
  }

  // Fix 1C: handler_stack_limit / handler_heap_limit / handler_force push regs then scrub R1..R4
  action scrubRegsBeforeGc = all {
    s.p0.phase == "demand_short",
    s' = {
      ...s,
      p0: { ...s.p0, phase: "scrubbed", hasRawSpillInReg: false, regsScrubbed: true }
    }
  }

  // Peer processor p1 enters (declare (not safe) (fixnum)) tight loop with Feeley back-edge ___POLL
  action peerEnterNotSafeLoop(withPoll: bool): bool = all {
    s.o1Loaded,
    s.p1.phase == "idle",
    s' = { ...s, p1: { ...s.p1, phase: "looping", loopHasPoll: withPoll, pollChecked: false } }
  }

  // Peer services back-edge ___POLL when gcRequested is raised
  action peerServiceBackedgePoll = all {
    s.p1.phase == "looping",
    s.p1.loopHasPoll,
    s.gcRequested,
    s' = { ...s, p1: { ...s.p1, phase: "parked_gc", pollChecked: true, reloaded: false } }
  }

  // Negative fault injection: eliding ___POLL on a (not safe) back-edge starves GC rendezvous
  action faultLoopWithoutPollStarvesGc = all {
    s.p1.phase == "looping",
    not(s.p1.loopHasPoll),
    s.gcRequested,
    s' = { ...s, gcRendezvousStarved: true }
  }

  // GC runs once p0 scrubbed registers and p1 is not actively blocking rendezvous
  action gcCollectAdvanceEpoch = all {
    s.gcRequested,
    s.p0.phase == "scrubbed",
    s.p0.regsScrubbed,
    not(s.p0.hasRawSpillInReg),
    s.p1.phase == "idle" or s.p1.phase == "parked_gc",
    s' = {
      ...s,
      gcEpoch: s.gcEpoch + 1,
      gcRequested: false,
      p0: {
        ...s.p0,
        phase: "parked_gc",
        // Fix 1A-ext: while primlockHeld or demandActive, interrupt dispatch is deferred
        interruptDeferred: s.p0.primlockHeld or s.p0.demandActive,
        room: s.p0.needWords + 16,
        reloaded: false
      },
      p1: { ...s.p1, phase: "idle", epoch: s.gcEpoch + 1, reloaded: true, room: 16 }
    }
  }

  // Negative fault injection: entering GC without Fix 1C scrub exposes raw F64 bits to mark_registers
  action faultGcWithUnscrubbedReg = all {
    s.gcRequested,
    s.p0.phase == "demand_short",
    s.p0.hasRawSpillInReg,
    not(s.p0.regsScrubbed),
    s' = { ...s, gcScannedCorruptReg: true }
  }

  // Post-GC unwind to caller pre-ADJFP label and explicit ___R_HEAP / ___R_ALL cursor reload
  action unwindAndReloadCursor = all {
    s.p0.phase == "parked_gc",
    s' = { ...s, p0: { ...s.p0, phase: "reloaded", epoch: s.gcEpoch, reloaded: true } }
  }

  // First compiled store inside .o1 write group: requires matching epoch, reload, and full room
  action firstCompiledWrite = all {
    s.p0.phase == "reloaded",
    s.p0.reloaded,
    s.p0.epoch == s.gcEpoch,
    s.p0.room >= s.p0.needWords,
    s.p0.needWords > 0,
    s' = {
      ...s,
      p0: { ...s.p0, phase: "writing", wroteWords: s.p0.needWords, room: s.p0.room - s.p0.needWords }
    }
  }

  // Negative fault injection: writing after GC without ___R_HEAP reload (stale epoch)
  action faultWriteWithoutReload = all {
    s.p0.phase == "parked_gc",
    not(s.p0.reloaded),
    s' = { ...s, illegalFirstWrite: true, p0: { ...s.p0, phase: "writing", wroteWords: s.p0.needWords } }
  }

  // Negative fault injection: writing a group larger than admitted room (short write-group grant)
  action faultShortWriteGroupStore(words: int): bool = all {
    s.o1Loaded,
    s.p0.phase == "idle",
    words > s.p0.room,
    s' = { ...s, illegalFirstWrite: true, p0: { ...s.p0, phase: "writing", needWords: words, wroteWords: words } }
  }

  // Commit write group and clear demand state
  action commitWriteGroup = all {
    s.p0.phase == "writing",
    not(s.illegalFirstWrite),
    s' = {
      ...s,
      p0: {
        ...s.p0,
        phase: "idle",
        needWords: 0,
        demandActive: false,
        primlockHeld: false,
        interruptDeferred: false,
        wroteWords: 0
      }
    }
  }

  // Cross-module interrupt: .o1 compiled closure inc! queued into lib/_thread.o ##thread-intr-service!
  action queueCrossModuleInterrupt = all {
    s.o1Loaded,
    not(s.intrPending),
    not(s.intrClaimed),
    s' = { ...s, intrPending: true }
  }

  action claimCrossModuleInterrupt = all {
    s.intrPending,
    not(s.intrClaimed),
    not(s.p0.primlockHeld),
    s' = { ...s, intrPending: false, intrClaimed: true }
  }

  // Terminal settlement (normal return or exception unwind) occurs at most once
  action settleCrossModuleInterrupt(exceptionUnwind: bool): bool = all {
    s.intrClaimed,
    s.intrSettledCount == 0,
    s' = {
      ...s,
      intrClaimed: false,
      intrSettledCount: s.intrSettledCount + 1,
      intrUnwound: exceptionUnwind
    }
  }

  action step = any {
    compileAndLinkO1(9, 240),
    loadO1IntoGsi,
    compiledWriteGroupFast(4),
    compiledWriteGroupShortage(24, true, true),
    scrubRegsBeforeGc,
    peerEnterNotSafeLoop(true),
    peerServiceBackedgePoll,
    gcCollectAdvanceEpoch,
    unwindAndReloadCursor,
    firstCompiledWrite,
    commitWriteGroup,
    queueCrossModuleInterrupt,
    claimCrossModuleInterrupt,
    settleCrossModuleInterrupt(false),
    settleCrossModuleInterrupt(true),
    s' = s
  }

  val safe = all {
    s.o1Loaded implies (s.emittedCProducer == s.producerId and s.linkedO1Producer == s.producerId and s.dynamicGstateExportsBound and s.lblCount < 6000),
    not(s.illegalLoad),
    not(s.gcScannedCorruptReg),
    not(s.gcRendezvousStarved),
    not(s.illegalFirstWrite),
    (s.p0.phase == "writing") implies (s.p0.reloaded and s.p0.epoch == s.gcEpoch and s.p0.room >= 0),
    (s.p0.primlockHeld and s.p0.phase == "parked_gc") implies s.p0.interruptDeferred,
    s.intrSettledCount <= 1,
    not(s.duplicateSettlement)
  }

  // Positive 1: Full compiled .o1 shortage -> Fix 1C scrub -> peer (not safe) back-edge poll -> GC -> unwind/reload -> first write -> commit
  run compiledShortageReloadCommitTest = init
    .then(compileAndLinkO1(9, 240))
    .then(loadO1IntoGsi)
    .then(peerEnterNotSafeLoop(true))
    .then(compiledWriteGroupShortage(24, true, true))
    .then(scrubRegsBeforeGc)
    .then(peerServiceBackedgePoll)
    .then(gcCollectAdvanceEpoch)
    .expect(s.gcEpoch == 2 and s.p0.interruptDeferred and not(s.p0.reloaded) and safe)
    .then(unwindAndReloadCursor)
    .then(firstCompiledWrite)
    .then(commitWriteGroup)
    .expect(s.p0.phase == "idle" and s.p0.epoch == 2 and safe)

  // Positive 2: Cross-module .o1 interrupt closure invocation + exception unwind with single settlement
  run crossModuleInterruptSingleSettleTest = init
    .then(compileAndLinkO1(9, 240))
    .then(loadO1IntoGsi)
    .then(queueCrossModuleInterrupt)
    .then(claimCrossModuleInterrupt)
    .then(settleCrossModuleInterrupt(true))
    .expect(s.intrSettledCount == 1 and s.intrUnwound and safe)

  // Negative 1: Stale .o1 built by mismatched producer is falsified
  run staleO1ProducerMismatchRefusedTest = init
    .then(compileAndLinkO1(8, 240))
    .then(faultLoadStaleO1)
    .expect(not(safe))

  // Negative 2: Omitting Fix 1C register scrub corrupts GC mark_registers
  run unscrubbedRegisterSpillCorruptsGcTest = init
    .then(compileAndLinkO1(9, 240))
    .then(loadO1IntoGsi)
    .then(compiledWriteGroupShortage(24, true, false))
    .then(faultGcWithUnscrubbedReg)
    .expect(not(safe))

  // Negative 3: Short write-group grant attempting first store beyond room is falsified
  run shortWriteGroupFirstStoreRefusedTest = init
    .then(compileAndLinkO1(9, 240))
    .then(loadO1IntoGsi)
    .then(faultShortWriteGroupStore(20))
    .expect(not(safe))

  // Negative 4: Missing ___R_HEAP reload after GC attempts stale-epoch first write
  run missingPostSafepointReloadRefusedTest = init
    .then(compileAndLinkO1(9, 240))
    .then(loadO1IntoGsi)
    .then(compiledWriteGroupShortage(24, true, false))
    .then(scrubRegsBeforeGc)
    .then(gcCollectAdvanceEpoch)
    .then(faultWriteWithoutReload)
    .expect(not(safe))

  // Negative 5: Eliding Feeley back-edge ___POLL in (not safe) loop starves GC rendezvous
  run elidedNotSafeBackedgePollStarvesRendezvousTest = init
    .then(compileAndLinkO1(9, 240))
    .then(loadO1IntoGsi)
    .then(peerEnterNotSafeLoop(false))
    .then(compiledWriteGroupShortage(24, false, false))
    .then(scrubRegsBeforeGc)
    .then(faultLoopWithoutPollStarvesGc)
    .expect(not(safe))

  // Negative 6: Missing ___GSTATE ___EXT dynamic-bundle export fails Darwin -bundle link/load
  run missingDynamicGstateExportFailsLinkTest = init
    .then(faultMissingDynamicGstateExport(9, 240))
    .expect(not(safe))
}
