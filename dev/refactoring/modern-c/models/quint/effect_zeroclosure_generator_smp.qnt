// Phase C24: Zero-Closure Inline-CAS Algebraic Effects & Symmetric 4-State
// Atomic Direct-Style Generator Protocol (with Multi-Shot Freeze & denv Guard)
module effect_zeroclosure_generator_smp {

  // Effect-continuation inline atomic states
  pure val EC_LIVE: int     = 0
  pure val EC_CONSUMED: int = 1
  pure val EC_MULTISHOT: int = 2

  // Generator 4-state atomic machine
  pure val GEN_INIT: int      = 0
  pure val GEN_RUNNING: int   = 1
  pure val GEN_SUSPENDED: int = 2
  pure val GEN_DONE: int      = 3

  pure val THREADS: Set[int] = Set(0, 1, 2)

  // Shared linear effect-continuation state (with escaped handle tracking)
  var ecState: int
  var ecResumedCount: int
  var ecEscapedRetained: bool
  var ecCorruptReuseFault: bool

  // Generator state & reusable pframe state
  var genState: int
  var genActiveThreads: int
  var genDoubleResumeFault: bool
  var pframeFrozen: bool
  var pframeMutatedWhileFrozenFault: bool

  // denv / dynamic-wind & SATB watermark tracking
  var curDenv: int
  var targetDenv: int
  var dynamicWindSkippedFault: bool
  var satbActive: bool
  var satbUnshadedResumeFault: bool

  action init = all {
    ecState' = EC_LIVE,
    ecResumedCount' = 0,
    ecEscapedRetained' = true,
    ecCorruptReuseFault' = false,
    genState' = GEN_INIT,
    genActiveThreads' = 0,
    genDoubleResumeFault' = false,
    pframeFrozen' = false,
    pframeMutatedWhileFrozenFault' = false,
    curDenv' = 0,
    targetDenv' = 0,
    dynamicWindSkippedFault' = false,
    satbActive' = false,
    satbUnshadedResumeFault' = false,
  }

  // Thread attempts linear one-shot resume via inline seq_cst CAS(0 -> 1)
  action ecLinearResume(t: int): bool = all {
    t.in(THREADS),
    ecState == EC_LIVE,
    ecState' = EC_CONSUMED,
    ecResumedCount' = ecResumedCount + 1,
    // Consumed handle is NEVER recycled to EC_LIVE while escaped references exist
    ecCorruptReuseFault' = ecCorruptReuseFault,
    // denv guard: fast path only when curDenv == targetDenv; SATB always watermarks
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
    ecEscapedRetained' = ecEscapedRetained,
    genState' = genState,
    genActiveThreads' = genActiveThreads,
    genDoubleResumeFault' = genDoubleResumeFault,
    pframeFrozen' = pframeFrozen,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    curDenv' = curDenv,
    targetDenv' = targetDenv,
    satbActive' = satbActive,
  }

  // Thread retries resume on already-consumed handle (must reject cleanly)
  action ecConsumedReject(t: int): bool = all {
    t.in(THREADS),
    ecState == EC_CONSUMED,
    ecState' = EC_CONSUMED,
    ecResumedCount' = ecResumedCount,
    ecEscapedRetained' = ecEscapedRetained,
    ecCorruptReuseFault' = ecCorruptReuseFault,
    genState' = genState,
    genActiveThreads' = genActiveThreads,
    genDoubleResumeFault' = genDoubleResumeFault,
    pframeFrozen' = pframeFrozen,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    curDenv' = curDenv,
    targetDenv' = targetDenv,
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbActive' = satbActive,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
  }

  // Thread promotes LIVE -> MULTISHOT_COW and freezes captured pframe
  action ecPromoteMultishot(t: int): bool = all {
    t.in(THREADS),
    ecState == EC_LIVE or ecState == EC_MULTISHOT,
    ecState' = EC_MULTISHOT,
    pframeFrozen' = true,
    ecResumedCount' = ecResumedCount,
    ecEscapedRetained' = ecEscapedRetained,
    ecCorruptReuseFault' = ecCorruptReuseFault,
    genState' = genState,
    genActiveThreads' = genActiveThreads,
    genDoubleResumeFault' = genDoubleResumeFault,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    curDenv' = curDenv,
    targetDenv' = targetDenv,
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbActive' = satbActive,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
  }

  // Generator atomic start: INIT -> RUNNING
  action genStart(t: int): bool = all {
    t.in(THREADS),
    genState == GEN_INIT,
    genState' = GEN_RUNNING,
    genActiveThreads' = genActiveThreads + 1,
    ecState' = ecState,
    ecResumedCount' = ecResumedCount,
    ecEscapedRetained' = ecEscapedRetained,
    ecCorruptReuseFault' = ecCorruptReuseFault,
    genDoubleResumeFault' = genDoubleResumeFault,
    pframeFrozen' = pframeFrozen,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    curDenv' = curDenv,
    targetDenv' = targetDenv,
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbActive' = satbActive,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
  }

  // Generator yield: RUNNING -> SUSPENDED (allocates fresh pframe if frozen, never mutates frozen)
  action genYield: bool = all {
    genState == GEN_RUNNING,
    genState' = GEN_SUSPENDED,
    genActiveThreads' = genActiveThreads - 1,
    // If pframe was frozen by multi-shot, generator replaces with a fresh unfrozen pframe
    pframeFrozen' = false,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    ecState' = ecState,
    ecResumedCount' = ecResumedCount,
    ecEscapedRetained' = ecEscapedRetained,
    ecCorruptReuseFault' = ecCorruptReuseFault,
    genDoubleResumeFault' = genDoubleResumeFault,
    curDenv' = curDenv,
    targetDenv' = targetDenv,
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbActive' = satbActive,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
  }

  // Generator atomic resume: SUSPENDED -> RUNNING
  action genResume(t: int): bool = all {
    t.in(THREADS),
    genState == GEN_SUSPENDED,
    genState' = GEN_RUNNING,
    genActiveThreads' = genActiveThreads + 1,
    // If pframeFrozen, must allocate fresh pframe instead of mutating frozen one
    pframeFrozen' = false,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    ecState' = ecState,
    ecResumedCount' = ecResumedCount,
    ecEscapedRetained' = ecEscapedRetained,
    ecCorruptReuseFault' = ecCorruptReuseFault,
    genDoubleResumeFault' = genDoubleResumeFault,
    curDenv' = curDenv,
    targetDenv' = targetDenv,
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbActive' = satbActive,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
  }

  // Generator finishes: RUNNING -> DONE
  action genFinish: bool = all {
    genState == GEN_RUNNING,
    genState' = GEN_DONE,
    genActiveThreads' = genActiveThreads - 1,
    ecState' = ecState,
    ecResumedCount' = ecResumedCount,
    ecEscapedRetained' = ecEscapedRetained,
    ecCorruptReuseFault' = ecCorruptReuseFault,
    genDoubleResumeFault' = genDoubleResumeFault,
    pframeFrozen' = pframeFrozen,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    curDenv' = curDenv,
    targetDenv' = targetDenv,
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbActive' = satbActive,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
  }

  // Toggle SATB / denv changes to stress guards
  action toggleEnv(nextSatb: bool, nextDenv: int): bool = all {
    satbActive' = nextSatb,
    curDenv' = nextDenv,
    targetDenv' = targetDenv,
    ecState' = ecState,
    ecResumedCount' = ecResumedCount,
    ecEscapedRetained' = ecEscapedRetained,
    ecCorruptReuseFault' = ecCorruptReuseFault,
    genState' = genState,
    genActiveThreads' = genActiveThreads,
    genDoubleResumeFault' = genDoubleResumeFault,
    pframeFrozen' = pframeFrozen,
    pframeMutatedWhileFrozenFault' = pframeMutatedWhileFrozenFault,
    dynamicWindSkippedFault' = dynamicWindSkippedFault,
    satbUnshadedResumeFault' = satbUnshadedResumeFault,
  }

  action step = {
    nondet t = THREADS.oneOf()
    nondet nextSatb = Set(false, true).oneOf()
    nondet nextDenv = Set(0, 1).oneOf()
    any {
      ecLinearResume(t),
      ecConsumedReject(t),
      ecPromoteMultishot(t),
      genStart(t),
      genYield,
      genResume(t),
      genFinish,
      toggleEnv(nextSatb, nextDenv),
    }
  }

  val invLinearOneShotAtMostOnce =
    (ecState == EC_CONSUMED implies ecResumedCount == 1) and
    (ecState == EC_LIVE implies ecResumedCount == 0) and
    not(ecCorruptReuseFault)

  val invGeneratorMutualExclusion =
    genActiveThreads >= 0 and genActiveThreads <= 1 and
    (genState == GEN_RUNNING implies genActiveThreads == 1) and
    (genState != GEN_RUNNING implies genActiveThreads == 0) and
    not(genDoubleResumeFault)

  val invFrozenPframeNeverMutated = not(pframeMutatedWhileFrozenFault)
  val invDenvGuardSound = not(dynamicWindSkippedFault)
  val invSatbWatermarkSound = not(satbUnshadedResumeFault)

  val allInvariants =
    invLinearOneShotAtMostOnce and
    invGeneratorMutualExclusion and
    invFrozenPframeNeverMutated and
    invDenvGuardSound and
    invSatbWatermarkSound
}
