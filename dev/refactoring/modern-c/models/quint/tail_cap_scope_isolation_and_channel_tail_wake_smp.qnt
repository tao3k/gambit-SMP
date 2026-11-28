// -*- mode: quint; -*-
// Phase C53: Lexical Tail-Capability Creation-Site Dynamic Scope Isolation
// (`effect/capability.scm`) & O(1)-Stack Tail-Recursive Channel Wakeup Cascade
// (`fiber/channel-ring.scm`).

module tail_cap_scope_isolation_and_channel_tail_wake_smp {

  // Handler frame identifiers:
  //   1 = outer_e2 (enclosing handler at capability creation)
  //   2 = inner_e2 (inner handler installed inside call-with-tail-capability)
  //   3 = resumer_e3 (extra handler installed around cross-extent resume)
  //   4 = extra_inner (additional inner handler)

  // --- Tail-Capability Scope Isolation State ---
  var hStack: List[int]
  var capLive: bool
  var capOuterTop: int          // 1 when outer_e2 was top at creation
  var capBodyActive: bool
  var savedPrefix: List[int]
  var savedTarget: List[int]
  var resolvedInCap: int        // handler observed by (perform e2) inside cap
  var crossExtentResumed: bool
  var postReturnInnerSeen: bool
  var postReturnResumerSeen: bool
  var excUnwoundOk: bool
  var continuableExcOk: bool

  // --- Channel Tail-Wake Cascade State (cap = 1) ---
  var bufCount: int             // 0 or 1
  var rxWaiters: int
  var txWaiters: int
  var rxWoken: int
  var txWoken: int
  var wakeMode: str             // "idle" | "wake_rx" | "wake_tx"
  var wakeStackDepth: int
  var maxWakeStackDepth: int
  var wokeBeforeRecurse: bool

  pure def listContains(xs: List[int], v: int): bool =
    xs.foldl(false, (acc, x) => acc or x == v)

  pure def prefixBefore(xs: List[int], stop: int): List[int] =
    xs.foldl({ found: false, acc: [] }, (st, x) =>
      if (st.found or x == stop) { found: true, acc: st.acc }
      else { found: false, acc: st.acc.append(x) }
    ).acc

  pure def tailFrom(xs: List[int], stop: int): List[int] =
    xs.foldl({ found: false, acc: [] }, (st, x) =>
      if (st.found) { found: true, acc: st.acc.append(x) }
      else {
        if (x == stop) { found: true, acc: [x] }
        else { found: false, acc: [] }
      }
    ).acc

  pure def concatLists(a: List[int], b: List[int]): List[int] =
    b.foldl(a, (acc, x) => acc.append(x))

  pure def firstE2Handler(xs: List[int]): int =
    xs.foldl(0, (acc, x) =>
      if (acc != 0) acc
      else {
        if (x == 1 or x == 2) x else 0
      }
    )

  action init = all {
    hStack' = [1],
    capLive' = true,
    capOuterTop' = 1,
    capBodyActive' = false,
    savedPrefix' = [],
    savedTarget' = [],
    resolvedInCap' = 0,
    crossExtentResumed' = false,
    postReturnInnerSeen' = false,
    postReturnResumerSeen' = false,
    excUnwoundOk' = true,
    continuableExcOk' = true,
    bufCount' = 1,
    rxWaiters' = 3,
    txWaiters' = 3,
    rxWoken' = 0,
    txWoken' = 0,
    wakeMode' = "idle",
    wakeStackDepth' = 0,
    maxWakeStackDepth' = 0,
    wokeBeforeRecurse' = true,
  }

  // Install inner handler 2 inside call-with-tail-capability body
  action pushInnerHandler = all {
    capLive,
    not(capBodyActive),
    not(listContains(hStack, 2)),
    hStack' = concatLists([2], hStack),
    capLive' = capLive,
    capOuterTop' = capOuterTop,
    capBodyActive' = capBodyActive,
    savedPrefix' = savedPrefix,
    savedTarget' = savedTarget,
    resolvedInCap' = resolvedInCap,
    crossExtentResumed' = crossExtentResumed,
    postReturnInnerSeen' = postReturnInnerSeen,
    postReturnResumerSeen' = postReturnResumerSeen,
    excUnwoundOk' = excUnwoundOk,
    continuableExcOk' = continuableExcOk,
    bufCount' = bufCount,
    rxWaiters' = rxWaiters,
    txWaiters' = txWaiters,
    rxWoken' = rxWoken,
    txWoken' = txWoken,
    wakeMode' = wakeMode,
    wakeStackDepth' = wakeStackDepth,
    maxWakeStackDepth' = maxWakeStackDepth,
    wokeBeforeRecurse' = wokeBeforeRecurse,
  }

  // Simulate call-with-tail-capability body itself resumed under extra resumer handler 3
  action resumeBodyInNewExtent = all {
    capLive,
    not(capBodyActive),
    not(listContains(hStack, 3)),
    hStack' = hStack.append(3),
    capLive' = capLive,
    capOuterTop' = capOuterTop,
    capBodyActive' = capBodyActive,
    savedPrefix' = savedPrefix,
    savedTarget' = savedTarget,
    resolvedInCap' = resolvedInCap,
    crossExtentResumed' = crossExtentResumed,
    postReturnInnerSeen' = postReturnInnerSeen,
    postReturnResumerSeen' = postReturnResumerSeen,
    excUnwoundOk' = excUnwoundOk,
    continuableExcOk' = continuableExcOk,
    bufCount' = bufCount,
    rxWaiters' = rxWaiters,
    txWaiters' = txWaiters,
    rxWoken' = rxWoken,
    txWoken' = txWoken,
    wakeMode' = wakeMode,
    wakeStackDepth' = wakeStackDepth,
    maxWakeStackDepth' = maxWakeStackDepth,
    wokeBeforeRecurse' = wokeBeforeRecurse,
  }

  // Enter perform-cap on a tail capability: split at capOuterTop and shift hStack to target
  action performCapEnter = {
    val pref = prefixBefore(hStack, capOuterTop)
    val targ = tailFrom(hStack, capOuterTop)
    all {
      capLive,
      not(capBodyActive),
      length(targ) > 0,
      savedPrefix' = pref,
      savedTarget' = targ,
      hStack' = targ,
      capBodyActive' = true,
      resolvedInCap' = firstE2Handler(targ),
      capLive' = capLive,
      capOuterTop' = capOuterTop,
      crossExtentResumed' = false,
      postReturnInnerSeen' = postReturnInnerSeen,
      postReturnResumerSeen' = postReturnResumerSeen,
      excUnwoundOk' = excUnwoundOk,
      continuableExcOk' = continuableExcOk,
      bufCount' = bufCount,
      rxWaiters' = rxWaiters,
      txWaiters' = txWaiters,
      rxWoken' = rxWoken,
      txWoken' = txWoken,
      wakeMode' = wakeMode,
      wakeStackDepth' = wakeStackDepth,
      maxWakeStackDepth' = maxWakeStackDepth,
      wokeBeforeRecurse' = wokeBeforeRecurse,
    }
  }

  // Inside cap body: outer suspending e2 suspends and resumes under extra resumer handler 3
  action capOuterSuspendAndResume = all {
    capBodyActive,
    not(listContains(hStack, 3)),
    hStack' = hStack.append(3),
    crossExtentResumed' = true,
    capLive' = capLive,
    capOuterTop' = capOuterTop,
    capBodyActive' = capBodyActive,
    savedPrefix' = savedPrefix,
    savedTarget' = savedTarget,
    resolvedInCap' = resolvedInCap,
    postReturnInnerSeen' = postReturnInnerSeen,
    postReturnResumerSeen' = postReturnResumerSeen,
    excUnwoundOk' = excUnwoundOk,
    continuableExcOk' = continuableExcOk,
    bufCount' = bufCount,
    rxWaiters' = rxWaiters,
    txWaiters' = txWaiters,
    rxWoken' = rxWoken,
    txWoken' = txWoken,
    wakeMode' = wakeMode,
    wakeStackDepth' = wakeStackDepth,
    maxWakeStackDepth' = maxWakeStackDepth,
    wokeBeforeRecurse' = wokeBeforeRecurse,
  }

  // Return from perform-cap: O(1) fast restore when hStack == savedTarget, else splice savedPrefix ++ hStack
  action performCapReturn = {
    val restored = if (hStack == savedTarget) concatLists(savedPrefix, savedTarget)
                   else concatLists(savedPrefix, hStack)
    all {
      capBodyActive,
      hStack' = restored,
      capBodyActive' = false,
      savedPrefix' = [],
      savedTarget' = [],
      postReturnInnerSeen' = (firstE2Handler(restored) == 2),
      postReturnResumerSeen' = listContains(restored, 3),
      capLive' = capLive,
      capOuterTop' = capOuterTop,
      resolvedInCap' = resolvedInCap,
      crossExtentResumed' = crossExtentResumed,
      excUnwoundOk' = excUnwoundOk,
      continuableExcOk' = continuableExcOk,
      bufCount' = bufCount,
      rxWaiters' = rxWaiters,
      txWaiters' = txWaiters,
      rxWoken' = rxWoken,
      txWoken' = txWoken,
      wakeMode' = wakeMode,
      wakeStackDepth' = wakeStackDepth,
      maxWakeStackDepth' = maxWakeStackDepth,
      wokeBeforeRecurse' = wokeBeforeRecurse,
    }
  }

  // Continuable exception raised inside perform-cap:
  // temporarily restores savedPrefix ++ hStack for cur-eh, then re-shifts back to hStack on return.
  action capContinuableException = {
    val visibleToHandler = concatLists(savedPrefix, hStack)
    all {
      capBodyActive,
      // Upon return from continuable handler, hStack is restored to saved-h (still isolated from 2)
      hStack' = hStack,
      continuableExcOk' = (not(listContains(hStack, 2)) and (length(savedPrefix) == 0 or listContains(visibleToHandler, 2))),
      capLive' = capLive,
      capOuterTop' = capOuterTop,
      capBodyActive' = capBodyActive,
      savedPrefix' = savedPrefix,
      savedTarget' = savedTarget,
      resolvedInCap' = resolvedInCap,
      crossExtentResumed' = crossExtentResumed,
      postReturnInnerSeen' = postReturnInnerSeen,
      postReturnResumerSeen' = postReturnResumerSeen,
      excUnwoundOk' = excUnwoundOk,
      bufCount' = bufCount,
      rxWaiters' = rxWaiters,
      txWaiters' = txWaiters,
      rxWoken' = rxWoken,
      txWoken' = txWoken,
      wakeMode' = wakeMode,
      wakeStackDepth' = wakeStackDepth,
      maxWakeStackDepth' = maxWakeStackDepth,
      wokeBeforeRecurse' = wokeBeforeRecurse,
    }
  }

  // Escaping exception raised inside perform-cap caught by inner with-exception-catcher:
  // restores savedPrefix ++ hStack so inner with-handler pops inner frame 2 cleanly,
  // leaving cap live and hStack == target (outer_e2 intact!).
  action capInnerCatcherEscape = {
    val restoredBeforeInnerPop = concatLists(savedPrefix, hStack)
    val afterInnerPop = tailFrom(restoredBeforeInnerPop, capOuterTop)
    all {
      capBodyActive,
      hStack' = afterInnerPop,
      capBodyActive' = false,
      savedPrefix' = [],
      savedTarget' = [],
      excUnwoundOk' = (capLive and firstE2Handler(afterInnerPop) == 1 and not(listContains(afterInnerPop, 2))),
      capLive' = capLive,
      capOuterTop' = capOuterTop,
      resolvedInCap' = resolvedInCap,
      crossExtentResumed' = crossExtentResumed,
      postReturnInnerSeen' = postReturnInnerSeen,
      postReturnResumerSeen' = postReturnResumerSeen,
      continuableExcOk' = continuableExcOk,
      bufCount' = bufCount,
      rxWaiters' = rxWaiters,
      txWaiters' = txWaiters,
      rxWoken' = rxWoken,
      txWoken' = txWoken,
      wakeMode' = wakeMode,
      wakeStackDepth' = wakeStackDepth,
      maxWakeStackDepth' = maxWakeStackDepth,
      wokeBeforeRecurse' = wokeBeforeRecurse,
    }
  }

  // Start tail-recursive channel wakeup cascade from a sender pushing into empty cap=1 ring
  action startChannelWakeCascade = all {
    wakeMode == "idle",
    bufCount == 1,
    rxWaiters > 0,
    wakeMode' = "wake_rx",
    wakeStackDepth' = 1,
    maxWakeStackDepth' = if (maxWakeStackDepth < 1) 1 else maxWakeStackDepth,
    wokeBeforeRecurse' = true,
    bufCount' = bufCount,
    rxWaiters' = rxWaiters,
    txWaiters' = txWaiters,
    rxWoken' = rxWoken,
    txWoken' = txWoken,
    hStack' = hStack,
    capLive' = capLive,
    capOuterTop' = capOuterTop,
    capBodyActive' = capBodyActive,
    savedPrefix' = savedPrefix,
    savedTarget' = savedTarget,
    resolvedInCap' = resolvedInCap,
    crossExtentResumed' = crossExtentResumed,
    postReturnInnerSeen' = postReturnInnerSeen,
    postReturnResumerSeen' = postReturnResumerSeen,
    excUnwoundOk' = excUnwoundOk,
    continuableExcOk' = continuableExcOk,
  }

  // %ch-wake-one-receiver!: pop rk + pop item + wake rk FIRST + tail-call %ch-wake-one-sender!
  action tailWakeOneReceiver = {
    val nextMode = if (txWaiters > 0) "wake_tx" else "idle"
    val nextDepth = if (txWaiters > 0) 1 else 0
    all {
      wakeMode == "wake_rx",
      rxWaiters > 0,
      bufCount == 1,
      rxWaiters' = rxWaiters - 1,
      bufCount' = 0,
      rxWoken' = rxWoken + 1,
      wokeBeforeRecurse' = (rxWoken + 1 > rxWoken),
      wakeMode' = nextMode,
      wakeStackDepth' = nextDepth,
      maxWakeStackDepth' = if (maxWakeStackDepth < nextDepth) nextDepth else maxWakeStackDepth,
      txWaiters' = txWaiters,
      txWoken' = txWoken,
      hStack' = hStack,
      capLive' = capLive,
      capOuterTop' = capOuterTop,
      capBodyActive' = capBodyActive,
      savedPrefix' = savedPrefix,
      savedTarget' = savedTarget,
      resolvedInCap' = resolvedInCap,
      crossExtentResumed' = crossExtentResumed,
      postReturnInnerSeen' = postReturnInnerSeen,
      postReturnResumerSeen' = postReturnResumerSeen,
      excUnwoundOk' = excUnwoundOk,
      continuableExcOk' = continuableExcOk,
    }
  }

  // %ch-wake-one-sender!: pop sk + push item + wake sk FIRST + tail-call %ch-wake-one-receiver!
  action tailWakeOneSender = {
    val nextMode = if (rxWaiters > 0) "wake_rx" else "idle"
    val nextDepth = if (rxWaiters > 0) 1 else 0
    all {
      wakeMode == "wake_tx",
      txWaiters > 0,
      bufCount == 0,
      txWaiters' = txWaiters - 1,
      bufCount' = 1,
      txWoken' = txWoken + 1,
      wokeBeforeRecurse' = (txWoken + 1 > txWoken),
      wakeMode' = nextMode,
      wakeStackDepth' = nextDepth,
      maxWakeStackDepth' = if (maxWakeStackDepth < nextDepth) nextDepth else maxWakeStackDepth,
      rxWaiters' = rxWaiters,
      rxWoken' = rxWoken,
      hStack' = hStack,
      capLive' = capLive,
      capOuterTop' = capOuterTop,
      capBodyActive' = capBodyActive,
      savedPrefix' = savedPrefix,
      savedTarget' = savedTarget,
      resolvedInCap' = resolvedInCap,
      crossExtentResumed' = crossExtentResumed,
      postReturnInnerSeen' = postReturnInnerSeen,
      postReturnResumerSeen' = postReturnResumerSeen,
      excUnwoundOk' = excUnwoundOk,
      continuableExcOk' = continuableExcOk,
    }
  }

  action step = any {
    pushInnerHandler,
    resumeBodyInNewExtent,
    performCapEnter,
    capOuterSuspendAndResume,
    performCapReturn,
    capContinuableException,
    capInnerCatcherEscape,
    startChannelWakeCascade,
    tailWakeOneReceiver,
    tailWakeOneSender,
  }

  // --- Safety Invariants ---
  val invNoInnerHijack =
    (not(capBodyActive)) or (not(listContains(hStack, 2)) and resolvedInCap == 1)

  val invOuterAlwaysPresent =
    listContains(hStack, 1)

  val invExceptionCoherency =
    excUnwoundOk and continuableExcOk

  val invChannelO1Stack =
    maxWakeStackDepth <= 1 and wakeStackDepth <= 1 and wokeBeforeRecurse

  val invChannelConservation =
    (bufCount == 0 or bufCount == 1) and rxWaiters >= 0 and txWaiters >= 0

  val allInvs =
    invNoInnerHijack and invOuterAlwaysPresent and invExceptionCoherency and
    invChannelO1Stack and invChannelConservation

  // --- 5 Unit Tests ---
  run tailCapScopeIsolationTest =
    init
      .then(pushInnerHandler)
      .then(performCapEnter)
      .expect(resolvedInCap == 1 and not(listContains(hStack, 2)))
      .then(performCapReturn)
      .expect(firstE2Handler(hStack) == 2 and postReturnInnerSeen)

  run tailCapCrossExtentSuspendResumeSpliceTest =
    init
      .then(pushInnerHandler)
      .then(performCapEnter)
      .then(capOuterSuspendAndResume)
      .expect(listContains(hStack, 3) and not(listContains(hStack, 2)))
      .then(performCapReturn)
      .expect(firstE2Handler(hStack) == 2 and listContains(hStack, 3) and postReturnInnerSeen and postReturnResumerSeen)

  run tailCapContinuableAndInnerCatcherExcTest =
    init
      .then(pushInnerHandler)
      .then(performCapEnter)
      .then(capContinuableException)
      .expect(continuableExcOk and not(listContains(hStack, 2)))
      .then(capInnerCatcherEscape)
      .expect(excUnwoundOk and capLive and firstE2Handler(hStack) == 1)

  run tailCapResumedExtentBoundaryTest =
    init
      .then(resumeBodyInNewExtent)
      .then(pushInnerHandler)
      .then(performCapEnter)
      .expect(resolvedInCap == 1 and listContains(hStack, 3) and not(listContains(hStack, 2)))
      .then(performCapReturn)
      .expect(firstE2Handler(hStack) == 2 and listContains(hStack, 3))

  run channelTailWakeCascadeO1StackTest =
    init
      .then(startChannelWakeCascade)
      .then(tailWakeOneReceiver)
      .then(tailWakeOneSender)
      .then(tailWakeOneReceiver)
      .then(tailWakeOneSender)
      .then(tailWakeOneReceiver)
      .then(tailWakeOneSender)
      .expect(rxWoken == 3 and txWoken == 3 and rxWaiters == 0 and txWaiters == 0 and maxWakeStackDepth == 1 and wakeStackDepth == 0)
}
