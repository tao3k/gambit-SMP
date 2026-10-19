module gc_table_iteration {
  // Three rooted keys with stable logical identities and arbitrary GC rehashes.
  // Original projection assumes atomic capture after buffer allocation.
  // The separate capture projection below checks preparation/wait/delivery;
  // neither projection proves source refinement or an actual collector.
  type Capture = { policy: int, phase: int, count: int, capacity: int,
    copied: int, epoch: int, rootEpoch: int, localEpoch: int,
    rooted: bool, relocated: bool, guard: bool, buffer: bool,
    ready: bool, outcome: int, delivered: int }
  pure def captureInitial(policy: int): Capture = {
    policy: policy, phase: 0, count: 2, capacity: 0, copied: 0,
    epoch: 0, rootEpoch: 0, localEpoch: 0, rooted: policy != 1,
    relocated: false, guard: false, buffer: false,
    ready: false, outcome: 0, delivered: 0,
  }
  type State = { snapshot: bool, phase: int, layout: int, index: int,
    seen0: int, seen1: int, seen2: int, typedCopy: bool, invalidCopy: bool,
    capture: Capture }
  var s: State
  pure def initial(snapshot: bool): State = {
    snapshot: snapshot, phase: 0, layout: 0, index: 0,
    seen0: 0, seen1: 0, seen2: 0, typedCopy: true, invalidCopy: false,
    capture: captureInitial(0),
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  // Rejected native prototype: WEAK/SUBTYPED storage is not VECTOR-tagged.
  action initWrongTagCopy = s' = { ...initial(true), typedCopy: false }
  pure def keyAt(layout: int, index: int): int =
    if (layout == 0) (if (index == 0) 0 else if (index == 1) 1 else 2)
    else if (layout == 1) (if (index == 0) 1 else if (index == 1) 0 else 2)
    else if (layout == 2) (if (index == 0) 2 else if (index == 1) 1 else 0)
    else if (layout == 3) (if (index == 0) 0 else if (index == 1) 2 else 1)
    else if (layout == 4) (if (index == 0) 1 else if (index == 1) 2 else 0)
    else (if (index == 0) 2 else if (index == 1) 0 else 1)
  action visit = all {
    s.phase == 0,
    val key = keyAt(if (s.snapshot) 0 else s.layout, s.index)
    s' = { ...s, phase: 1,
      seen0: s.seen0 + (if (key == 0) 1 else 0),
      seen1: s.seen1 + (if (key == 1) 1 else 0),
      seen2: s.seen2 + (if (key == 2) 1 else 0),
      invalidCopy: s.invalidCopy or (s.snapshot and not(s.typedCopy)) },
  }
  action callbackGc(layout: int): bool = all {
    s.phase == 1, s' = { ...s, layout: layout },
  }
  action advance = all {
    s.phase == 1,
    s' = { ...s, phase: if (s.index == 2) 2 else 0, index: s.index + 1 },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any { visit, callbackGc(0), callbackGc(1), callbackGc(2),
    callbackGc(3), callbackGc(4), callbackGc(5), advance, finished }
  val encodingSafe = not(s.invalidCopy)
  val safe = encodingSafe and (s.phase != 2 or (s.seen0 == 1 and s.seen1 == 1 and s.seen2 == 1))

  // One finite membership growth and one moving-GC epoch. These are bounds,
  // not runtime settings. Root publication/service uses existing protocols.
  action initCapture = s' = initial(true)
  action initUnrootedWait = s' = { ...initial(true), capture: captureInitial(1) }
  action initStaleReload = s' = { ...initial(true), capture: captureInitial(2) }
  action initGuardedCallback = s' = { ...initial(true), capture: captureInitial(3) }
  action initUncheckedCapacity = s' = { ...initial(true), capture: captureInitial(4) }
  action initIgnoredAllocationFailure = s' = { ...initial(true), capture: captureInitial(5) }
  action planCapture = all {
    s.capture.phase == 0,
    s' = { ...s, capture: { ...s.capture, phase: 1, capacity: s.capture.count } },
  }
  action growMembership = all {
    s.capture.phase < 5, not(s.capture.guard), s.capture.count == 2,
    s' = { ...s, capture: { ...s.capture, count: 3 } },
  }
  action allocateCapture = all {
    s.capture.phase == 1, not(s.capture.guard),
    s' = { ...s, capture: { ...s.capture, phase: 2, buffer: true } },
  }
  action failCaptureAllocation = all {
    s.capture.phase == 1,
    s' = { ...s, capture: { ...s.capture,
      phase: if (s.capture.policy == 5) 4 else 5, outcome: 1 } },
  }
  action relocateWaitingRoots = all {
    s.capture.phase == 2, not(s.capture.relocated),
    s' = { ...s, capture: { ...s.capture, epoch: 1, relocated: true,
      rootEpoch: if (s.capture.rooted) 1 else 0 } },
  }
  action acquireAndReload = all {
    s.capture.phase == 2,
    s' = { ...s, capture: { ...s.capture, phase: 3, guard: true,
      localEpoch: if (s.capture.policy == 2) s.capture.localEpoch else s.capture.rootEpoch } },
  }
  action revalidateAndCopy = all {
    s.capture.phase == 3,
    s' = { ...s, capture:
      if (s.capture.capacity < s.capture.count and s.capture.policy != 4)
        { ...s.capture, phase: 0, guard: false, buffer: false }
      else { ...s.capture, phase: 4, ready: true, copied: s.capture.count,
        guard: s.capture.policy == 3 } },
  }
  // Each delivery is one callback. Failure retains only the delivered prefix.
  // This does not model Scheme continuation capture/reinvocation.
  action deliverCapture(callbackFails: bool): bool = all {
    s.capture.phase == 4, s.capture.delivered < s.capture.copied,
    val done = callbackFails or s.capture.delivered + 1 == s.capture.copied
    s' = { ...s, capture: { ...s.capture, phase: if (done) 5 else 4, guard: false,
      buffer: not(done), delivered: s.capture.delivered + 1,
      outcome: if (callbackFails) 2 else 0 } },
  }
  action captureFinished = all { s.capture.phase == 5, s' = s }
  action captureStep = any { planCapture, growMembership, allocateCapture,
    failCaptureAllocation, relocateWaitingRoots, acquireAndReload,
    revalidateAndCopy, deliverCapture(false), deliverCapture(true), captureFinished }
  val captureRootSafe = s.capture.phase != 3 or
    (s.capture.rooted and s.capture.rootEpoch == s.capture.epoch)
  val captureReloadSafe = s.capture.phase != 3 or s.capture.localEpoch == s.capture.epoch
  val captureDeliverySafe = s.capture.phase != 4 or not(s.capture.guard)
  val captureCapacitySafe = s.capture.phase != 4 or s.capture.capacity >= s.capture.copied
  val captureFailureSafe = s.capture.phase != 4 or (s.capture.ready and s.capture.outcome == 0)
  val captureSafe = all {
    captureRootSafe, captureReloadSafe, captureDeliverySafe,
    captureCapacitySafe, captureFailureSafe,
    s.capture.phase != 4 or all { s.capture.ready, s.capture.buffer,
      not(s.capture.guard), s.capture.capacity >= s.capture.copied,
      s.capture.localEpoch == s.capture.epoch, s.capture.outcome == 0 },
    s.capture.phase != 5 or all { not(s.capture.guard), not(s.capture.buffer),
      s.capture.delivered <= s.capture.copied,
      s.capture.outcome != 0 or s.capture.delivered == s.capture.copied },
  }
  temporal captureCompletion = weakFair(captureStep, s).implies(eventually(s.capture.phase == 5))
}
