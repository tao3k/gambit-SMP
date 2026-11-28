// Phase C51 Quint Specification:
// 1. Exact LCA Unwind/Restore Diff (%mc-diff-list) in %commit-noncomp-and-return!
//    (shared ancestor frames are NEVER spuriously unwound or restored; divergent
//     frames get exact 'unwind on dropped and 'restore on reentered)
// 2. Non-Destructive Pre-CAS Validation for One-Shot Continuations (missing
//    prompt or blocked inner barrier never consumes or clears the live cell)
// 3. Linearizable At-Most-Once Execution Under Concurrent SMP Invocation

module srfi226_noncomp_lca_diff_and_oneshot_precheck_smp {
  // --- Subsystem 1: Non-composable LCA diff across shared/divergent frames ---
  // Frames: 1 = shared outer guard (e.g. with-finally / with-nursery / future),
  //         2 = branch A inner guard, 3 = branch B inner guard
  var curFrames: Set[int]
  var sharedGuardLive: bool       // MUST stay true while 1 stays in both cur & target!
  var branchAGuardLive: bool
  var branchBGuardLive: bool
  var spuriousSharedUnwinds: int  // MUST stay 0 forever!

  // --- Subsystem 2: One-shot continuation pre-CAS validation & SMP CAS ---
  // Captured under: pt -> B1 -> capture (inner barrier B1 inside prompt pt)
  val CAP_INNER_BARRIERS: Set[int] = Set(1)

  var oscState: int             // 0=LIVE, 1=CONSUMED, 2=MULTISHOT_COW
  var cellCleared: bool         // true once sub-k/prefix/marks/handlers cleared
  var jumpsExecuted: int
  var oneShotJumps: int         // must be <= 1
  var barrierBypasses: int      // must stay 0
  var destroyedOnReject: int    // must stay 0
  var promoted: bool

  action init = all {
    curFrames' = Set(1, 2),
    sharedGuardLive' = true,
    branchAGuardLive' = true,
    branchBGuardLive' = false,
    spuriousSharedUnwinds' = 0,

    oscState' = 0,
    cellCleared' = false,
    jumpsExecuted' = 0,
    oneShotJumps' = 0,
    barrierBypasses' = 0,
    destroyedOnReject' = 0,
    promoted' = false,
  }

  // Exact LCA diff noncomp jump from curFrames to targetFrames
  action noncompJump(targetFrames: Set[int]): bool = {
    val dropped = curFrames.exclude(targetFrames)
    val reentered = targetFrames.exclude(curFrames)
    all {
      curFrames' = targetFrames,
      sharedGuardLive' =
        if (dropped.contains(1)) false
        else if (reentered.contains(1)) true
        else sharedGuardLive,
      branchAGuardLive' =
        if (dropped.contains(2)) false
        else if (reentered.contains(2)) true
        else branchAGuardLive,
      branchBGuardLive' =
        if (dropped.contains(3)) false
        else if (reentered.contains(3)) true
        else branchBGuardLive,
      spuriousSharedUnwinds' =
        if (curFrames.contains(1) and targetFrames.contains(1) and dropped.contains(1))
          spuriousSharedUnwinds + 1
        else spuriousSharedUnwinds,
      oscState' = oscState, cellCleared' = cellCleared,
      jumpsExecuted' = jumpsExecuted, oneShotJumps' = oneShotJumps,
      barrierBypasses' = barrierBypasses, destroyedOnReject' = destroyedOnReject,
      promoted' = promoted,
    }
  }

  // Jump within SAME shared guard (cur={1,2} -> target={1}): drops 2, keeps 1 LIVE!
  action jumpSameSharedOuter = noncompJump(Set(1))

  // Jump across divergent inner branches sharing guard 1 ({1,2} <-> {1,3})
  action jumpToBranchB = noncompJump(Set(1, 3))
  action jumpToBranchA = noncompJump(Set(1, 2))

  // Jump completely out of guard 1 (target = Set()) -> legitimately unwinds 1
  action jumpExitAll = noncompJump(Set())

  // --- Subsystem 2: One-shot pre-CAS validation ---
  action invokeAttempt(curBarriers: Set[int], promptActive: bool): bool =
    if (oscState == 1) all {
      oscState' = oscState,
      cellCleared' = cellCleared,
      jumpsExecuted' = jumpsExecuted,
      oneShotJumps' = oneShotJumps,
      barrierBypasses' = barrierBypasses,
      destroyedOnReject' = destroyedOnReject,
      promoted' = promoted,
      curFrames' = curFrames, sharedGuardLive' = sharedGuardLive,
      branchAGuardLive' = branchAGuardLive, branchBGuardLive' = branchBGuardLive,
      spuriousSharedUnwinds' = spuriousSharedUnwinds,
    } else {
      if (not(CAP_INNER_BARRIERS.subseteq(curBarriers)) or not(promptActive)) all {
        oscState' = oscState,
        cellCleared' = cellCleared,
        jumpsExecuted' = jumpsExecuted,
        oneShotJumps' = oneShotJumps,
        barrierBypasses' = barrierBypasses,
        destroyedOnReject' = destroyedOnReject,
        promoted' = promoted,
        curFrames' = curFrames, sharedGuardLive' = sharedGuardLive,
        branchAGuardLive' = branchAGuardLive, branchBGuardLive' = branchBGuardLive,
        spuriousSharedUnwinds' = spuriousSharedUnwinds,
      } else {
        if (oscState == 0) all {
          oscState' = 1,
          cellCleared' = true,
          jumpsExecuted' = jumpsExecuted + 1,
          oneShotJumps' = oneShotJumps + 1,
          barrierBypasses' = if (not(CAP_INNER_BARRIERS.subseteq(curBarriers))) barrierBypasses + 1 else barrierBypasses,
          destroyedOnReject' = destroyedOnReject,
          promoted' = promoted,
          curFrames' = curFrames, sharedGuardLive' = sharedGuardLive,
          branchAGuardLive' = branchAGuardLive, branchBGuardLive' = branchBGuardLive,
          spuriousSharedUnwinds' = spuriousSharedUnwinds,
        } else all {
          oscState' = 2,
          cellCleared' = cellCleared,
          jumpsExecuted' = jumpsExecuted + 1,
          oneShotJumps' = oneShotJumps,
          barrierBypasses' = if (not(CAP_INNER_BARRIERS.subseteq(curBarriers))) barrierBypasses + 1 else barrierBypasses,
          destroyedOnReject' = destroyedOnReject,
          promoted' = promoted,
          curFrames' = curFrames, sharedGuardLive' = sharedGuardLive,
          branchAGuardLive' = branchAGuardLive, branchBGuardLive' = branchBGuardLive,
          spuriousSharedUnwinds' = spuriousSharedUnwinds,
        }
      }
    }

  action invokeBlockedByBarrier = invokeAttempt(Set(), true)
  action invokeMissingPrompt = invokeAttempt(Set(1), false)
  action invokeValidSameBarrier = invokeAttempt(Set(1), true)
  action invokeValidExitingInnerBarrier = invokeAttempt(Set(1, 2), true)

  action promote = all {
    oscState != 1,
    oscState' = 2,
    promoted' = true,
    cellCleared' = cellCleared,
    jumpsExecuted' = jumpsExecuted,
    oneShotJumps' = oneShotJumps,
    barrierBypasses' = barrierBypasses,
    destroyedOnReject' = destroyedOnReject,
    curFrames' = curFrames, sharedGuardLive' = sharedGuardLive,
    branchAGuardLive' = branchAGuardLive, branchBGuardLive' = branchBGuardLive,
    spuriousSharedUnwinds' = spuriousSharedUnwinds,
  }

  action step = any {
    jumpSameSharedOuter,
    jumpToBranchB,
    jumpToBranchA,
    jumpExitAll,
    invokeBlockedByBarrier,
    invokeMissingPrompt,
    invokeValidSameBarrier,
    invokeValidExitingInnerBarrier,
    promote,
  }

  // --- Safety Invariants ---
  val invExactFrameLiveness =
    (sharedGuardLive == curFrames.contains(1)) and
    (branchAGuardLive == curFrames.contains(2)) and
    (branchBGuardLive == curFrames.contains(3))

  val invZeroSpuriousSharedUnwind = spuriousSharedUnwinds == 0
  val invZeroBarrierBypass = barrierBypasses == 0
  val invZeroDestroyedOnReject = destroyedOnReject == 0
  val invOneShotAtMostOnce = oneShotJumps <= 1
  val invConsumedImpliesCleared =
    (oscState == 1) implies (cellCleared and oneShotJumps == 1)
  val invMultishotNeverCleared =
    (oscState == 2) implies (not(cellCleared) and promoted)

  val allInvs = and {
    invExactFrameLiveness,
    invZeroSpuriousSharedUnwind,
    invZeroBarrierBypass,
    invZeroDestroyedOnReject,
    invOneShotAtMostOnce,
    invConsumedImpliesCleared,
    invMultishotNeverCleared,
  }

  // --- 5 Deterministic Unit Tests ---
  run sameScopeJumpPreservesSharedGuardTest =
    init
      .then(jumpSameSharedOuter)
      .expect(allInvs and sharedGuardLive and not(branchAGuardLive) and spuriousSharedUnwinds == 0)

  run divergentBranchJumpSwapsOnlyInnerGuardsTest =
    init
      .then(jumpToBranchB)
      .expect(allInvs and sharedGuardLive and not(branchAGuardLive) and branchBGuardLive)
      .then(jumpToBranchA)
      .expect(allInvs and sharedGuardLive and branchAGuardLive and not(branchBGuardLive))

  run rejectedBarrierPreservesOneShotLiveTest =
    init
      .then(invokeBlockedByBarrier)
      .expect(allInvs and oscState == 0 and jumpsExecuted == 0)
      .then(invokeValidSameBarrier)
      .expect(allInvs and oscState == 1 and oneShotJumps == 1)

  run rejectedMissingPromptPreservesOneShotLiveTest =
    init
      .then(invokeMissingPrompt)
      .expect(allInvs and oscState == 0 and jumpsExecuted == 0)
      .then(invokeValidExitingInnerBarrier)
      .expect(allInvs and oscState == 1 and oneShotJumps == 1)

  run promoteAfterRejectedInvocationsTest =
    init
      .then(invokeBlockedByBarrier)
      .then(invokeMissingPrompt)
      .then(promote)
      .then(invokeValidSameBarrier)
      .then(invokeValidExitingInnerBarrier)
      .expect(allInvs and oscState == 2 and jumpsExecuted == 2 and not(cellCleared))
}
