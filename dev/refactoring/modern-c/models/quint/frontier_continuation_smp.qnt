// Frontier Multicore Continuation Protocol:
// - Atomic 3-state continuation ownership (ONE_SHOT_LIVE -> ONE_SHOT_CONSUMED | MULTISHOT_COW)
// - Multi-prompt delimitation & continuation barriers (SRFI-226)
// - ZGC-style Stack Watermark x SATB concurrent scanning handoff

module frontier_continuation_smp {
  // Continuation ownership states:
  // 0 = ONE_SHOT_LIVE, 1 = ONE_SHOT_CONSUMED, 2 = MULTISHOT_COW
  type ContState = int

  // SATB major GC phases: 0 = IDLE, 1 = MARKING
  type GcPhase = int

  pure val CORES: Set[int] = Set(0, 1, 2)
  pure val CONTS: Set[int] = Set(0, 1)
  pure val PROMPTS: Set[int] = Set(0, 1)

  var contState: int -> ContState
  var oneShotClaims: int -> int         // total successful one-shot claims per cont
  var cowResumes: int -> int            // total multi-shot COW resumes per cont
  var frameShaded: int -> bool          // whether cont's frame roots are SATB-shaded
  var watermarkArmed: int -> bool       // whether return watermark barrier is armed for cont
  var gcPhase: GcPhase
  var promptActive: int -> bool         // whether prompt tag is currently on stack
  var barrierBetween: int -> bool       // whether a continuation barrier blocks prompt tag
  var abortViolations: int
  var satbMissedRoots: int

  action init = all {
    contState' = CONTS.mapBy(_ => 0),
    oneShotClaims' = CONTS.mapBy(_ => 0),
    cowResumes' = CONTS.mapBy(_ => 0),
    frameShaded' = CONTS.mapBy(_ => false),
    watermarkArmed' = CONTS.mapBy(_ => false),
    gcPhase' = 0,
    promptActive' = PROMPTS.mapBy(_ => true),
    barrierBetween' = PROMPTS.mapBy(p => p == 1),
    abortViolations' = 0,
    satbMissedRoots' = 0,
  }

  // Start a concurrent SATB major cycle: arm stack watermarks on all live continuations.
  action startSatbMajor = all {
    gcPhase == 0,
    gcPhase' = 1,
    watermarkArmed' = CONTS.mapBy(k => contState.get(k) != 1),
    frameShaded' = CONTS.mapBy(_ => false),
    contState' = contState,
    oneShotClaims' = oneShotClaims,
    cowResumes' = cowResumes,
    promptActive' = promptActive,
    barrierBetween' = barrierBetween,
    abortViolations' = abortViolations,
    satbMissedRoots' = satbMissedRoots,
  }

  // Finish SATB major cycle once all non-consumed continuations are shaded.
  action finishSatbMajor = all {
    gcPhase == 1,
    CONTS.forall(k => contState.get(k) == 1 or frameShaded.get(k)),
    gcPhase' = 0,
    watermarkArmed' = CONTS.mapBy(_ => false),
    frameShaded' = frameShaded,
    contState' = contState,
    oneShotClaims' = oneShotClaims,
    cowResumes' = cowResumes,
    promptActive' = promptActive,
    barrierBetween' = barrierBetween,
    abortViolations' = abortViolations,
    satbMissedRoots' = satbMissedRoots,
  }

  // Concurrent GC worker lazily shades a suspended continuation's frames.
  action gcShadeContinuation(k: int): bool = all {
    gcPhase == 1,
    contState.get(k) != 1,
    not(frameShaded.get(k)),
    frameShaded' = frameShaded.set(k, true),
    watermarkArmed' = watermarkArmed.set(k, false),
    gcPhase' = gcPhase,
    contState' = contState,
    oneShotClaims' = oneShotClaims,
    cowResumes' = cowResumes,
    promptActive' = promptActive,
    barrierBetween' = barrierBetween,
    abortViolations' = abortViolations,
    satbMissedRoots' = satbMissedRoots,
  }

  // Atomic one-shot claim (C23 atomic_exchange LIVE -> CONSUMED) with watermark barrier.
  action claimOneShot(core: int, k: int): bool = all {
    contState.get(k) == 0,
    contState' = contState.set(k, 1),
    oneShotClaims' = oneShotClaims.set(k, oneShotClaims.get(k) + 1),
    // Return watermark barrier: if SATB is active and watermark is armed,
    // mutator cooperatively shades frame roots before overwriting stack.
    frameShaded' = if (gcPhase == 1 and watermarkArmed.get(k))
                     frameShaded.set(k, true)
                   else
                     frameShaded,
    watermarkArmed' = watermarkArmed.set(k, false),
    satbMissedRoots' = satbMissedRoots,
    gcPhase' = gcPhase,
    cowResumes' = cowResumes,
    promptActive' = promptActive,
    barrierBetween' = barrierBetween,
    abortViolations' = abortViolations,
  }

  // Lazy promotion from ONE_SHOT_LIVE -> MULTISHOT_COW (CAS LIVE -> MULTISHOT_COW).
  action promoteToMultiShot(core: int, k: int): bool = all {
    contState.get(k) == 0,
    contState' = contState.set(k, 2),
    oneShotClaims' = oneShotClaims,
    cowResumes' = cowResumes,
    frameShaded' = frameShaded,
    watermarkArmed' = watermarkArmed,
    gcPhase' = gcPhase,
    promptActive' = promptActive,
    barrierBetween' = barrierBetween,
    abortViolations' = abortViolations,
    satbMissedRoots' = satbMissedRoots,
  }

  // Multi-shot COW resume (copies immutable snapshot; watermark shades if SATB active).
  action resumeMultiShotCow(core: int, k: int): bool = all {
    contState.get(k) == 2,
    cowResumes' = cowResumes.set(k, cowResumes.get(k) + 1),
    frameShaded' = if (gcPhase == 1 and watermarkArmed.get(k))
                     frameShaded.set(k, true)
                   else
                     frameShaded,
    watermarkArmed' = watermarkArmed.set(k, false),
    contState' = contState,
    oneShotClaims' = oneShotClaims,
    gcPhase' = gcPhase,
    promptActive' = promptActive,
    barrierBetween' = barrierBetween,
    abortViolations' = abortViolations,
    satbMissedRoots' = satbMissedRoots,
  }

  // Delimited abort to prompt tag p: allowed only if prompt is active and no barrier intervenes.
  action abortToPrompt(p: int): bool = all {
    promptActive.get(p),
    not(barrierBetween.get(p)),
    abortViolations' = abortViolations,
    contState' = contState,
    oneShotClaims' = oneShotClaims,
    cowResumes' = cowResumes,
    frameShaded' = frameShaded,
    watermarkArmed' = watermarkArmed,
    gcPhase' = gcPhase,
    promptActive' = promptActive,
    barrierBetween' = barrierBetween,
    satbMissedRoots' = satbMissedRoots,
  }

  action step = any {
    startSatbMajor,
    finishSatbMajor,
    nondet k = CONTS.oneOf() { gcShadeContinuation(k) },
    nondet c = CORES.oneOf() {
      nondet k = CONTS.oneOf() {
        any {
          claimOneShot(c, k),
          promoteToMultiShot(c, k),
          resumeMultiShotCow(c, k),
        }
      }
    },
    nondet p = PROMPTS.oneOf() { abortToPrompt(p) },
  }

  // Safety invariants
  val noDoubleOneShotResume =
    CONTS.forall(k => oneShotClaims.get(k) <= 1)

  val consumedNeverPromotedOrResumed =
    CONTS.forall(k => contState.get(k) == 1 implies cowResumes.get(k) == 0)

  val multishotNeverOneShotClaimed =
    CONTS.forall(k => contState.get(k) == 2 implies oneShotClaims.get(k) == 0)

  val noSatbMissedRoots =
    satbMissedRoots == 0

  val noBarrierViolation =
    abortViolations == 0

  val watermarkClearedImpliesShadedInSatb =
    (gcPhase == 1) implies
      CONTS.forall(k => (contState.get(k) != 1 and not(watermarkArmed.get(k))) implies frameShaded.get(k))

  val allInvariants = all {
    noDoubleOneShotResume,
    consumedNeverPromotedOrResumed,
    multishotNeverOneShotClaimed,
    noSatbMissedRoots,
    noBarrierViolation,
    watermarkClearedImpliesShadedInSatb,
  }
}
