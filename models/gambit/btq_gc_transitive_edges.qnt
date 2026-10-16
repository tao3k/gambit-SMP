module btq_gc_transitive_edges {
  // Conditional access contract, not a collector repair or a red-black proof.
  // One queue owns a parent/sibling/child path. A second queue stays independent.
  type State = { fault: int, phase: int, queueLocked: bool, epoch: int,
    rootGeneration: int, cachedRoot: int, edgeGeneration: int, childGeneration: int,
    childLive: bool, otherWriter: bool, otherQueueWrites: int,
    accessed: bool, badAccess: bool }
  var s: State
  pure def initial(fault: int): State = {
    fault: fault, phase: 0, queueLocked: false, epoch: 0,
    rootGeneration: 0, cachedRoot: 0, edgeGeneration: 0, childGeneration: 0,
    childLive: true, otherWriter: false, otherQueueWrites: 0,
    accessed: false, badAccess: false,
  }
  action initFixed = s' = initial(0)
  action initRootOnly = s' = initial(1)
  action initWrongQueueLock = s' = initial(2)
  action initDuplicateDestination = s' = initial(3)
  action lockQueue = all {
    s.phase == 0, s' = { ...s, phase: 1, queueLocked: true },
  }
  action publishRoots = all { s.phase == 1, s' = { ...s, phase: 2 } }
  // Both paths permit collection while this queue lock is held. The physical
  // collector must establish child closure; merely updating the root is not it.
  action copyGraph = all {
    s.phase == 2,
    s' = { ...s, phase: 3, epoch: 1, rootGeneration: 1,
      childGeneration: 1, edgeGeneration: if (s.fault == 1) 0 else 1 },
  }
  // This models the previously extracted duplicate-input control, not a claim
  // that the current native crash was caused by that producer schedule.
  action duplicateDestination = all {
    s.phase == 3, s.fault == 3,
    s' = { ...s, phase: 4, childGeneration: 2 },
  }
  action finishCopy = all { s.phase == 3, s.fault != 3, s' = { ...s, phase: 4 } }
  action reloadRoot = all {
    s.phase == 4, s' = { ...s, phase: 5, cachedRoot: s.rootGeneration },
  }
  action unownedSameQueueWriter = all {
    s.phase == 5, s.fault == 2, not(s.otherWriter),
    s' = { ...s, childLive: false, otherWriter: true },
  }
  action inspectChildColor = all {
    s.phase == 5, (s.fault != 2 or s.otherWriter),
    s' = { ...s, phase: 6, accessed: true,
      badAccess: not(s.queueLocked) or not(s.childLive)
        or s.cachedRoot != s.rootGeneration or s.edgeGeneration != s.childGeneration },
  }
  action unlockQueue = all {
    s.phase == 6, s' = { ...s, phase: 7, queueLocked: false },
  }
  action otherQueueWrite = all {
    s.otherQueueWrites == 0, s' = { ...s, otherQueueWrites: 1 },
  }
  action advance = any { lockQueue, publishRoots, copyGraph, duplicateDestination,
    finishCopy, reloadRoot, unownedSameQueueWriter, inspectChildColor, unlockQueue }
  action step = any { advance, otherQueueWrite, s' = s }
  val rootReloaded = not(s.accessed) or s.cachedRoot == s.rootGeneration
  val safe = rootReloaded and not(s.badAccess)
  temporal completion = weakFair(advance, s).and(weakFair(otherQueueWrite, s))
    .implies(eventually(s.phase == 7 and s.otherQueueWrites == 1))
}
