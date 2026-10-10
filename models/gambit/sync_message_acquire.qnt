module sync_message_acquire {
  var acquire: bool
  var release: bool
  var payloadVisible: bool
  var payloadWritten: bool
  var flagPublished: bool
  var flagObserved: bool
  var cachedPayload: int
  var phase: int
  var consumedPayload: int

  action initOld = all {
    acquire' = false, payloadWritten' = false, flagPublished' = false,
    release' = false, payloadVisible' = false,
    flagObserved' = false, cachedPayload' = 0, phase' = 0, consumedPayload' = -1,
  }
  action initFixed = all {
    acquire' = true, payloadWritten' = false, flagPublished' = false,
    release' = true, payloadVisible' = false,
    flagObserved' = false, cachedPayload' = 0, phase' = 0, consumedPayload' = -1,
  }
  action initReleaseOnly = all {
    acquire' = false, release' = true, payloadVisible' = false,
    payloadWritten' = false, flagPublished' = false, flagObserved' = false,
    cachedPayload' = 0, phase' = 0, consumedPayload' = -1,
  }
  action initAcquireOnly = all {
    acquire' = true, release' = false, payloadVisible' = false,
    payloadWritten' = false, flagPublished' = false, flagObserved' = false,
    cachedPayload' = 0, phase' = 0, consumedPayload' = -1,
  }
  action writePayload = all {
    not(payloadWritten), payloadWritten' = true,
    release' = release, payloadVisible' = payloadVisible,
    acquire' = acquire, flagPublished' = flagPublished, flagObserved' = flagObserved,
    cachedPayload' = cachedPayload, phase' = phase, consumedPayload' = consumedPayload,
  }
  // The old source fences AFTER the flag store; that does not order the
  // payload before an observer that spins without taking the sender mutex.
  action publishFlag = all {
    payloadWritten, not(flagPublished), flagPublished' = true,
    release' = release, payloadVisible' = (release or payloadVisible),
    acquire' = acquire, payloadWritten' = payloadWritten, flagObserved' = flagObserved,
    cachedPayload' = cachedPayload, phase' = phase, consumedPayload' = consumedPayload,
  }
  action propagatePayload = all {
    payloadWritten, not(payloadVisible), payloadVisible' = true,
    release' = release, acquire' = acquire, payloadWritten' = payloadWritten,
    flagPublished' = flagPublished, flagObserved' = flagObserved,
    cachedPayload' = cachedPayload, phase' = phase, consumedPayload' = consumedPayload,
  }
  // Without a receive fence, a stale payload read may precede flag observation.
  // Its visibility is nondeterministic; this is a weak-memory abstraction.
  action observeFlag(fresh: bool): bool = all {
    flagPublished, phase == 0, phase' = 1, flagObserved' = true,
    cachedPayload' = if (payloadVisible and (fresh or acquire)) 1 else 0,
    release' = release, payloadVisible' = payloadVisible,
    acquire' = acquire, payloadWritten' = payloadWritten, flagPublished' = flagPublished,
    consumedPayload' = consumedPayload,
  }
  action consume = all {
    phase == 1, phase' = 2, consumedPayload' = cachedPayload,
    release' = release, payloadVisible' = payloadVisible,
    acquire' = acquire, payloadWritten' = payloadWritten, flagPublished' = flagPublished,
    flagObserved' = flagObserved, cachedPayload' = cachedPayload,
  }
  action idle = all {
    phase == 2, phase' = phase, consumedPayload' = consumedPayload,
    release' = release, payloadVisible' = payloadVisible,
    acquire' = acquire, payloadWritten' = payloadWritten, flagPublished' = flagPublished,
    flagObserved' = flagObserved, cachedPayload' = cachedPayload,
  }
  action step = any { writePayload, publishFlag, propagatePayload,
                      observeFlag(false), observeFlag(true), consume, idle }
  val safe = phase != 2 or consumedPayload == 1
  val acquireSafe = safe
  val releaseSafe = safe
}
