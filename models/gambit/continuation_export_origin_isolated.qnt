module continuation_export_origin_isolated {
  // Source characterization, not a repaired collector. One pending frame link.
  // Addresses are ordinal words within one section, not runtime tuning values.
  // Recursive entry with an uncopied saved frame is a refinement premise.
  type State = { entry: str, phase: str, localScan: bool,
    start: int, end: int, cursor: int, stage: str,
    queued: bool, consumed: bool, producerDone: bool,
    consumedPhase: str, readPending: bool }
  var geometryState: State

  action init = {
    nondet entry = Set("roots", "traversal").oneOf()
    nondet localScan = Set(false, true).oneOf()
    nondet start = 1.to(3).oneOf()
    nondet words = 1.to(3).oneOf()
    nondet offset = 0.to(words).oneOf()
    geometryState' = { entry: entry, phase: entry, localScan: localScan,
      start: start, end: start + words,
      cursor: if (localScan) start + offset else start - 1,
      stage: "copied", queued: false, consumed: false,
      producerDone: false, consumedPhase: "none", readPending: false }
  }

  // end_heap_chunk writes its marker before testing scan_ptr membership.
  // The next frame exceeds the section limit; rollover is not the threshold
  // optimization and happens before *ptr=forw completes this frame'geometryState link.
  action endSection = all {
    geometryState.stage == "copied",
    geometryState' = { ...geometryState, stage: "rolled",
      queued: not(geometryState.cursor >= geometryState.start and geometryState.cursor < geometryState.end + 1) },
  }
  action nextFrame = all {
    geometryState.stage == "rolled",
    geometryState' = { ...geometryState, stage: "complete", producerDone: true },
  }
  // Existing BARRIER after root copying, before mark_reachable_from_marked.
  action rootBarrier = all {
    geometryState.phase == "roots", geometryState.producerDone,
    geometryState' = { ...geometryState, phase: "traversal" },
  }
  // Queue ownership is exclusive. ___sFRAME scanning does not take misc lock.
  action consume = all {
    geometryState.phase == "traversal", geometryState.queued, not(geometryState.consumed),
    geometryState' = { ...geometryState, queued: false, consumed: true,
      consumedPhase: geometryState.phase, readPending: not(geometryState.producerDone) },
  }
  val terminal = geometryState.producerDone and geometryState.phase == "traversal" and
    (geometryState.localScan or geometryState.consumed)
  action finished = all { terminal, geometryState' = geometryState }
  action step = any { endSection, nextFrame, rootBarrier, consume, finished }

  val localExclusion = not(geometryState.localScan) or (not(geometryState.queued) and not(geometryState.consumed))
  val rootProtection = geometryState.entry != "roots" or not(geometryState.readPending)
  val originClassified = not(geometryState.readPending) or
    (geometryState.entry == "traversal" and not(geometryState.localScan) and geometryState.consumedPhase == "traversal")
  val guardSound = localExclusion and rootProtection and originClassified
  // Not included in positive acceptance: traversal eligibility can violate it.
  val readiness = not(geometryState.readPending)
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(geometryState)).implies(eventually(terminal))
}
