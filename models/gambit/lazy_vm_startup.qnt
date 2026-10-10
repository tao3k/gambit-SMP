module lazy_vm_startup {
  // PR988 publishes started before resizing. Inject one unsuccessful resize,
  // then a second caller. Fixed commits readiness only after successful resize.
  // Does not model recursive startup callbacks, concurrent callers or VM shrink.
  var repair: bool
  var started: bool
  var processors: int
  var phase: int
  var returnedReady: bool
  action initOld = all {
    repair' = false, started' = false, processors' = 1,
    phase' = 0, returnedReady' = false,
  }
  action initFixed = all {
    repair' = true, started' = false, processors' = 1,
    phase' = 0, returnedReady' = false,
  }
  action beginFirst = all {
    phase == 0, phase' = 1, started' = not(repair),
    repair' = repair, processors' = processors, returnedReady' = returnedReady,
  }
  action finishFirst(success: bool): bool = all {
    phase == 1, phase' = 2,
    started' = (if (repair) success else started),
    processors' = if (success) 4 else 1,
    repair' = repair, returnedReady' = returnedReady,
  }
  action secondCaller = all {
    phase == 2, phase' = if (started) 4 else 3,
    returnedReady' = started,
    started' = started, processors' = processors, repair' = repair,
  }
  action retrySuccess = all {
    phase == 3, phase' = 4, started' = true, processors' = 4,
    returnedReady' = true, repair' = repair,
  }
  action idle = all {
    phase == 4, phase' = phase, started' = started, processors' = processors,
    returnedReady' = returnedReady, repair' = repair,
  }
  action step = any { beginFirst, finishFirst(false), finishFirst(true),
                      secondCaller, retrySuccess, idle }
  val safe = not(returnedReady) or processors == 4
}
