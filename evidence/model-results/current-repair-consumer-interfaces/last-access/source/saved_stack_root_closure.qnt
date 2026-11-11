module saved_stack_root_closure {
  import saved_stack_arena_ownership.* from "./saved_stack_arena_ownership"

  // A's head frame plus an older frame and a second origin into that older
  // frame. Roles are a finite census, not processor counts or runtime slots.
  // A permanent carrier is not traversed by an ordinary object reference.
  type Graph = { fault: int, anchor: bool, collection: bool,
    rawOrigins: Set[str], workPending: bool, cycleClosed: bool }
  var g: Graph
  pure def graphInitial(fault: int): Graph = { fault: fault, anchor: false,
    collection: false, rawOrigins: Set("tail-link", "escaped-origin"),
    workPending: false, cycleClosed: false }
  // One imported initialization site avoids Quint's shared-init/step
  // conversion restriction. Each assertion selects its immutable cohort.
  action initClosure = {
    nondet fault = Set(0, 1, 2, 3).oneOf()
    all { initFixed, g' = graphInitial(fault) }
  }
  action keepA = all { a' = a, keepR }

  action retirePrefix = all { any { save, detach, publish,
    retireExecutor, cleanupSlot, reinitializeSlot }, g' = g }
  // A direct, enumerated survivor root or an explicit payload scanner is
  // required. Which actual source path supplies it remains unproved.
  action establishRoot = all { a.phase == 5, not(g.anchor), keepA,
    g' = { ...g, anchor: true } }
  action restoreHead = all { g.anchor, restoreRaw, g' = g }
  action consumeHead = all { consumeRawFrame, g' = g }
  action collect = all { g.anchor or g.fault == 1, beginCollection,
    g' = { ...g, collection: true } }
  // A copied head does not discharge every origin into its older chain.
  // Target-space scan work also has a lifetime distinct from raw backing.
  action forwardHead = all { finishCollection,
    g' = { ...g, workPending: true } }
  action retargetOrigin = {
    nondet origin = g.rawOrigins.oneOf()
    all { a.phase == 9, not(a.recycled), keepA,
      g' = { ...g, rawOrigins: g.rawOrigins.exclude(Set(origin)) } }
  }
  action drainTargetWork = all { a.phase == 9, g.workPending, keepA,
    g' = { ...g, workPending: false } }
  action closeCycle = all { a.phase == 9, not(g.cycleClosed),
    (g.rawOrigins == Set() and not(g.workPending)) or
      (g.fault == 2) or (g.fault == 3 and g.rawOrigins == Set()),
    keepA, g' = { ...g, cycleClosed: true } }
  // This projects reuse in a later cycle. It does not claim the candidate
  // physically reuses its old half at the instant its last raw read ends.
  action nextCycleReuse = all { g.cycleClosed, recycleOldHalf, g' = g }
  action resumeHead = all { a.recycled, resumeCopied, g' = g }
  val rootCovered = not(g.collection) or g.anchor
  val chainCovered = not(a.recycled) or g.rawOrigins == Set()
  val phaseCovered = not(a.recycled) or not(g.workPending)
  val rootCoverage = g.fault != 1 or rootCovered
  val chainCoverage = g.fault != 2 or chainCovered
  val phaseCoverage = g.fault != 3 or phaseCovered
  val closureSafe = g.fault != 0 or (safe and rootCovered and chainCovered and phaseCovered)
  val closureTerminal = a.phase == 7 or a.phase == 10
  val noRetainedAliasesAfterHeadReturn = not(g.fault == 0 and a.phase == 7 and
    g.rawOrigins != Set() and not(a.recycled))
  val noClosedChainReuse = not(g.fault == 0 and a.phase == 10 and a.recycled and
    g.rawOrigins == Set() and not(g.workPending) and g.cycleClosed)
  action closureFinished = all { closureTerminal, keepA, g' = g }
  action closureStep = any { retirePrefix, establishRoot, restoreHead, consumeHead,
    collect, forwardHead, retargetOrigin, drainTargetWork, closeCycle,
    nextCycleReuse, resumeHead, closureFinished }
  temporal closureCompletion = always(g.fault != 0) or
    (always(closureTerminal or enabled(closureStep)) and
    // Every nonterminal action changes g or a; no hidden-state-only move.
    weakFair(closureStep, Set((g, a)))
      .implies(eventually(closureTerminal)))
}
