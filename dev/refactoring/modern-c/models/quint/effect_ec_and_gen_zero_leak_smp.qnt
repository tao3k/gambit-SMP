// Quint formal model for (gambit effect):
//   1. Consumed one-shot effect-continuation zero-leak slot clearing across
//      ALL paths (fast 1-arg AND slow 0/2/N-arg / nested-prompt / marks) while
//      strictly preserving slots whenever promoted to MULTISHOT_COW.
//   2. Generator caller metacontinuation & handler-chain detachment on both
//      yield (SUSPENDED) and completion (DONE), preventing dead-caller pinning.

module effect_ec_and_gen_zero_leak_smp {
  // Effect continuation states
  pure val EC_LIVE     = 0
  pure val EC_CONSUMED = 1
  pure val EC_MULTI    = 2

  // Generator states
  pure val GEN_INIT      = 0
  pure val GEN_RUNNING   = 1
  pure val GEN_SUSPENDED = 2
  pure val GEN_DONE      = 3

  var ecState: int
  var ecSlotsRetained: bool
  var ecMultishotBroken: bool

  var genState: int
  var genRetainsCallerMc: bool
  var genRetainsCells: bool
  var invalidApiCrashed: bool

  action init = all {
    ecState' = EC_LIVE,
    ecSlotsRetained' = true,
    ecMultishotBroken' = false,
    genState' = GEN_INIT,
    genRetainsCallerMc' = false,
    genRetainsCells' = true,
    invalidApiCrashed' = false,
  }

  // One-shot resume (fast or slow path): wins LIVE -> CONSUMED and clears all 6 slots
  action resumeOneShot(slowPath: bool): bool = all {
    ecState == EC_LIVE,
    ecState' = EC_CONSUMED,
    ecSlotsRetained' = false,
    ecMultishotBroken' = ecMultishotBroken,
    genState' = genState,
    genRetainsCallerMc' = genRetainsCallerMc,
    genRetainsCells' = genRetainsCells,
    invalidApiCrashed' = invalidApiCrashed,
  }

  // Promote LIVE -> MULTI (or replay already MULTI): MUST preserve slots
  action resumeMultishot = all {
    (ecState == EC_LIVE or ecState == EC_MULTI),
    ecState' = EC_MULTI,
    ecSlotsRetained' = ecSlotsRetained,
    ecMultishotBroken' = (ecMultishotBroken or not(ecSlotsRetained)),
    genState' = genState,
    genRetainsCallerMc' = genRetainsCallerMc,
    genRetainsCells' = genRetainsCells,
    invalidApiCrashed' = invalidApiCrashed,
  }

  // Resume called after promotion to MULTI: preserves slots (does not clear)
  action resumeAfterPromotion = all {
    ecState == EC_MULTI,
    ecState' = EC_MULTI,
    ecSlotsRetained' = ecSlotsRetained,
    ecMultishotBroken' = (ecMultishotBroken or not(ecSlotsRetained)),
    genState' = genState,
    genRetainsCallerMc' = genRetainsCallerMc,
    genRetainsCells' = genRetainsCells,
    invalidApiCrashed' = invalidApiCrashed,
  }

  // Generator starts or resumes: installs caller mc-cell/h-cell while RUNNING
  action genEnterRunning = all {
    (genState == GEN_INIT or genState == GEN_SUSPENDED),
    genState' = GEN_RUNNING,
    genRetainsCallerMc' = true,
    genRetainsCells' = genRetainsCells,
    ecState' = ecState,
    ecSlotsRetained' = ecSlotsRetained,
    ecMultishotBroken' = ecMultishotBroken,
    invalidApiCrashed' = invalidApiCrashed,
  }

  // Generator yields: detaches caller mc-cell/h-cell cdr BEFORE storing SUSPENDED
  action genYieldDetach = all {
    genState == GEN_RUNNING,
    genState' = GEN_SUSPENDED,
    genRetainsCallerMc' = false,
    genRetainsCells' = genRetainsCells,
    ecState' = ecState,
    ecSlotsRetained' = ecSlotsRetained,
    ecMultishotBroken' = ecMultishotBroken,
    invalidApiCrashed' = invalidApiCrashed,
  }

  // Generator finishes: detaches caller mc AND clears reusable cells BEFORE DONE
  action genFinishClear = all {
    genState == GEN_RUNNING,
    genState' = GEN_DONE,
    genRetainsCallerMc' = false,
    genRetainsCells' = false,
    ecState' = ecState,
    ecSlotsRetained' = ecSlotsRetained,
    ecMultishotBroken' = ecMultishotBroken,
    invalidApiCrashed' = invalidApiCrashed,
  }

  // Buggy action: slow-path one-shot resume forgets to clear ec slots
  action buggySlowOneShotRetainsSlots = all {
    ecState == EC_LIVE,
    ecState' = EC_CONSUMED,
    ecSlotsRetained' = true,
    ecMultishotBroken' = ecMultishotBroken,
    genState' = genState,
    genRetainsCallerMc' = genRetainsCallerMc,
    genRetainsCells' = genRetainsCells,
    invalidApiCrashed' = invalidApiCrashed,
  }

  // Buggy action: generator finishes without detaching caller mc-cell cdr
  action buggyGenFinishLeaksCallerMc = all {
    genState == GEN_RUNNING,
    genState' = GEN_DONE,
    genRetainsCallerMc' = true,
    genRetainsCells' = true,
    ecState' = ecState,
    ecSlotsRetained' = ecSlotsRetained,
    ecMultishotBroken' = ecMultishotBroken,
    invalidApiCrashed' = invalidApiCrashed,
  }

  action step = any {
    resumeOneShot(false),
    resumeOneShot(true),
    resumeMultishot,
    resumeAfterPromotion,
    genEnterRunning,
    genYieldDetach,
    genFinishClear,
  }

  val invConsumedEcZeroLeak: bool = ((ecState == EC_CONSUMED) implies not(ecSlotsRetained))
  val invMultishotPreserved: bool = ((ecState == EC_MULTI) implies (ecSlotsRetained and not(ecMultishotBroken)))
  val invSuspendedGenDetached: bool = ((genState == GEN_SUSPENDED) implies not(genRetainsCallerMc))
  val invDoneGenZeroLeak: bool = ((genState == GEN_DONE) implies (not(genRetainsCallerMc) and not(genRetainsCells)))
  val invApiSafe: bool = not(invalidApiCrashed)

  val safety: bool = all {
    invConsumedEcZeroLeak,
    invMultishotPreserved,
    invSuspendedGenDetached,
    invDoneGenZeroLeak,
    invApiSafe,
  }

  run slowOneShotZeroLeakTest = {
    init
      .then(resumeOneShot(true))
      .expect(safety and ecState == EC_CONSUMED and not(ecSlotsRetained))
  }

  run multishotPreservationTest = {
    init
      .then(resumeMultishot)
      .then(resumeAfterPromotion)
      .then(resumeMultishot)
      .expect(safety and ecState == EC_MULTI and ecSlotsRetained)
  }

  run genYieldAndFinishDetachTest = {
    init
      .then(genEnterRunning)
      .then(genYieldDetach)
      .then(genEnterRunning)
      .then(genFinishClear)
      .expect(safety and genState == GEN_DONE and not(genRetainsCallerMc) and not(genRetainsCells))
  }

  run buggySlowEcLeakDetectedTest = {
    init
      .then(buggySlowOneShotRetainsSlots)
      .expect(not(invConsumedEcZeroLeak))
  }

  run buggyGenCallerMcLeakDetectedTest = {
    init
      .then(genEnterRunning)
      .then(buggyGenFinishLeaksCallerMc)
      .expect(not(invDoneGenZeroLeak))
  }
}
