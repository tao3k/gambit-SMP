module exec_gc_polling {
  // PR988's error-pipe wait; file-control failure is explicitly injected.
  // This is a participation obligation, not a reproduced deadlock claim.
  var polling: bool
  var checkConfig: bool
  var nonblocking: bool
  var pendingGC: bool
  var joinedGC: bool
  var phase: int
  action initOld = all {
    polling' = false, checkConfig' = false, nonblocking' = false,
    pendingGC' = false, joinedGC' = false, phase' = 0,
  }
  action initUncheckedPoll = all {
    polling' = true, checkConfig' = false, nonblocking' = false,
    pendingGC' = false, joinedGC' = false, phase' = 0,
  }
  action initFixed = all {
    polling' = true, checkConfig' = true, nonblocking' = false,
    pendingGC' = false, joinedGC' = false, phase' = 0,
  }
  action configure(success: bool): bool = all {
    phase == 0, phase' = if (polling and checkConfig and not(success)) 3 else 1,
    nonblocking' = (polling and success), polling' = polling, checkConfig' = checkConfig,
    pendingGC' = pendingGC, joinedGC' = joinedGC,
  }
  // Child not ready: a blocking read cannot poll INTR_SYNC_OP.
  action waitForChild = all {
    phase == 1, phase' = 2, nonblocking' = nonblocking,
    polling' = polling, checkConfig' = checkConfig,
    pendingGC' = pendingGC, joinedGC' = joinedGC,
  }
  action requestGC = all {
    phase == 2, not(pendingGC), pendingGC' = true,
    phase' = phase, nonblocking' = nonblocking,
    polling' = polling, checkConfig' = checkConfig, joinedGC' = joinedGC,
  }
  action participate = all {
    phase == 2, nonblocking, pendingGC, not(joinedGC), joinedGC' = true,
    phase' = phase, nonblocking' = nonblocking,
    polling' = polling, checkConfig' = checkConfig, pendingGC' = pendingGC,
  }
  action idle = all {
    (phase == 3 or joinedGC), phase' = phase, nonblocking' = nonblocking,
    polling' = polling, checkConfig' = checkConfig,
    pendingGC' = pendingGC, joinedGC' = joinedGC,
  }
  action step = any { configure(false), configure(true), waitForChild,
                      requestGC, participate, idle }
  val safe = phase != 2 or not(pendingGC) or nonblocking or joinedGC
  val configSafe = safe
}
