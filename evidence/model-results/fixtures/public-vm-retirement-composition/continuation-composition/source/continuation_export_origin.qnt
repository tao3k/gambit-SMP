module continuation_export_origin {
  // Source characterization, not a repaired collector. One pending frame link.
  // Addresses are ordinal words within one section, not runtime tuning values.
  // Recursive entry with an uncopied saved frame is a refinement premise.
  type State = { entry: str, phase: str, localScan: bool,
    start: int, end: int, cursor: int, stage: str,
    queued: bool, consumed: bool, producerDone: bool,
    consumedPhase: str, readPending: bool }
  var s: State

  action init = {
    nondet entry = Set("roots", "traversal").oneOf()
    nondet localScan = Set(false, true).oneOf()
    nondet start = 1.to(3).oneOf()
    nondet words = 1.to(3).oneOf()
    nondet offset = 0.to(words).oneOf()
    s' = { entry: entry, phase: entry, localScan: localScan,
      start: start, end: start + words,
      cursor: if (localScan) start + offset else start - 1,
      stage: "copied", queued: false, consumed: false,
      producerDone: false, consumedPhase: "none", readPending: false }
  }

  // end_heap_chunk writes its marker before testing scan_ptr membership.
  // The next frame exceeds the section limit; rollover is not the threshold
  // optimization and happens before *ptr=forw completes this frame's link.
  action endSection = all {
    s.stage == "copied",
    s' = { ...s, stage: "rolled",
      queued: not(s.cursor >= s.start and s.cursor < s.end + 1) },
  }
  action nextFrame = all {
    s.stage == "rolled",
    s' = { ...s, stage: "complete", producerDone: true },
  }
  // Existing BARRIER after root copying, before mark_reachable_from_marked.
  action rootBarrier = all {
    s.phase == "roots", s.producerDone,
    s' = { ...s, phase: "traversal" },
  }
  // Queue ownership is exclusive. ___sFRAME scanning does not take misc lock.
  action consume = all {
    s.phase == "traversal", s.queued, not(s.consumed),
    s' = { ...s, queued: false, consumed: true,
      consumedPhase: s.phase, readPending: not(s.producerDone) },
  }
  val terminal = s.producerDone and s.phase == "traversal" and
    (s.localScan or s.consumed)
  action finished = all { terminal, s' = s }
  action step = any { endSection, nextFrame, rootBarrier, consume, finished }

  val localExclusion = not(s.localScan) or (not(s.queued) and not(s.consumed))
  val rootProtection = s.entry != "roots" or not(s.readPending)
  val originClassified = not(s.readPending) or
    (s.entry == "traversal" and not(s.localScan) and s.consumedPhase == "traversal")
  val guardSound = localExclusion and rootProtection and originClassified
  // Not included in positive acceptance: traversal eligibility can violate it.
  val readiness = not(s.readPending)
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
