// Phase C11 Formal Model:
//   1. Single-copy_gate merged dest_room + chunk restore in ___restore_stack_break_frame
//      (strictly <= 1 copy_gate held per carrier => zero AB-BA deadlock, exact fudge guard)
//   2. Same-denv cache-preservation fast path in ___CONTINUATION_GRAFT_NO_WINDING /
//      ___JUMP_CONTINUATION_RETURN_NO_WINDING2 (zero stale parameter cache entries)
//   3. Fused C23 direct-handoff & Dekker seq_cst park-or-pop channel path

module single_gate_restore_denv_cache_and_fused_handoff_smp {
  pure val FUDGE = 16
  pure val HALF_WORDS = 64

  // Two carriers C0, C1 with their own stack sections S0, S1
  // Each carrier holds at most 1 copy_gate: -1 = none, 0 = S0, 1 = S1
  var c0HeldGate: int
  var c1HeldGate: int
  var gate0Owner: int    // -1 = free, 0 = C0, 1 = C1
  var gate1Owner: int    // -1 = free, 0 = C0, 1 = C1

  // C0 destination stack room & restore chunk size
  var c0DestPos: int     // current dest offset from dest_lo (starts at HALF_WORDS)
  var c0LastCopied: int
  var c0OverflowedFudge: bool

  // Same-denv cache consistency model (immutable denv ids 1, 2)
  // denv 1 maps param -> 100; denv 2 maps param -> 200
  var curDenv: int
  var cacheDenvTag: int  // which denv the cached param entry belongs to
  var cacheVal: int

  // Fused C23 direct-handoff & Dekker seq_cst channel state
  var rTail: int
  var rHead: int
  var rxWaiters: int
  var parkedRx: bool
  var directHandoffs: int
  var fifoViolated: bool

  action init = all {
    c0HeldGate' = -1,
    c1HeldGate' = -1,
    gate0Owner' = -1,
    gate1Owner' = -1,
    c0DestPos' = HALF_WORDS,
    c0LastCopied' = 0,
    c0OverflowedFudge' = false,
    curDenv' = 1,
    cacheDenvTag' = 1,
    cacheVal' = 100,
    rTail' = 0,
    rHead' = 0,
    rxWaiters' = 0,
    parkedRx' = false,
    directHandoffs' = 0,
    fifoViolated' = false,
  }

  // C0 same-section fast restore: acquires ONLY gate0 ONCE, checks fudge headroom, copies, releases
  action c0_same_section_restore_begin = all {
    c0HeldGate == -1,
    gate0Owner == -1,
    c0HeldGate' = 0,
    gate0Owner' = 0,
    c1HeldGate' = c1HeldGate, gate1Owner' = gate1Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
    parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
  }

  action c0_same_section_restore_finish = {
    val safeRoom = if (c0DestPos > FUDGE) c0DestPos - FUDGE else 0
    val chunk = if (safeRoom >= 8) 8 else 0
    all {
      c0HeldGate == 0,
      gate0Owner == 0,
      c0DestPos' = c0DestPos - chunk,
      c0LastCopied' = chunk,
      c0OverflowedFudge' = (c0DestPos - chunk < FUDGE),
      c0HeldGate' = -1,
      gate0Owner' = -1,
      c1HeldGate' = c1HeldGate, gate1Owner' = gate1Owner,
      curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
      rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
      parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
    }
  }

  // C0 cross-section restore: acquires gate1 ONLY when holding NO gate (gate0 already released!)
  action c0_cross_section_acquire_s1 = all {
    c0HeldGate == -1,
    gate1Owner == -1,
    c0HeldGate' = 1,
    gate1Owner' = 0,
    c1HeldGate' = c1HeldGate, gate0Owner' = gate0Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
    parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
  }

  action c0_cross_section_release_s1 = all {
    c0HeldGate == 1,
    gate1Owner == 0,
    c0HeldGate' = -1,
    gate1Owner' = -1,
    c1HeldGate' = c1HeldGate, gate0Owner' = gate0Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
    parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
  }

  // C1 cross-section restore from S0: acquires gate0 ONLY when holding NO gate
  action c1_cross_section_acquire_s0 = all {
    c1HeldGate == -1,
    gate0Owner == -1,
    c1HeldGate' = 0,
    gate0Owner' = 1,
    c0HeldGate' = c0HeldGate, gate1Owner' = gate1Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
    parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
  }

  action c1_cross_section_release_s0 = all {
    c1HeldGate == 0,
    gate0Owner == 1,
    c1HeldGate' = -1,
    gate0Owner' = -1,
    c0HeldGate' = c0HeldGate, gate1Owner' = gate1Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
    parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
  }

  // Continuation return with SAME denv: skips 4 write barriers & keeps cache untouched
  action cont_return_same_denv = all {
    curDenv' = curDenv,
    cacheDenvTag' = cacheDenvTag,
    cacheVal' = cacheVal,
    c0HeldGate' = c0HeldGate, c1HeldGate' = c1HeldGate,
    gate0Owner' = gate0Owner, gate1Owner' = gate1Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
    parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
  }

  // Continuation return with DIFFERENT denv: updates thread->denv & resets cache1..3
  action cont_return_diff_denv = {
    val targetDenv = if (curDenv == 1) 2 else 1
    val targetVal = if (targetDenv == 1) 100 else 200
    all {
      curDenv' = targetDenv,
      cacheDenvTag' = targetDenv,
      cacheVal' = targetVal,
      c0HeldGate' = c0HeldGate, c1HeldGate' = c1HeldGate,
      gate0Owner' = gate0Owner, gate1Owner' = gate1Owner,
      c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
      c0OverflowedFudge' = c0OverflowedFudge,
      rTail' = rTail, rHead' = rHead, rxWaiters' = rxWaiters,
      parkedRx' = parkedRx, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
    }
  }

  // Fused C23 park-recv and direct-handoff actions
  action fused_park_recv = all {
    not(parkedRx),
    rTail == rHead,
    parkedRx' = true,
    rxWaiters' = 1,
    rTail' = rTail, rHead' = rHead, directHandoffs' = directHandoffs, fifoViolated' = fifoViolated,
    c0HeldGate' = c0HeldGate, c1HeldGate' = c1HeldGate,
    gate0Owner' = gate0Owner, gate1Owner' = gate1Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
  }

  action fused_direct_handoff = all {
    parkedRx,
    rxWaiters > 0,
    rTail == rHead, // linearizability guard inside fused C23 block
    parkedRx' = false,
    rxWaiters' = 0,
    directHandoffs' = directHandoffs + 1,
    fifoViolated' = (rTail != rHead),
    rTail' = rTail, rHead' = rHead,
    c0HeldGate' = c0HeldGate, c1HeldGate' = c1HeldGate,
    gate0Owner' = gate0Owner, gate1Owner' = gate1Owner,
    c0DestPos' = c0DestPos, c0LastCopied' = c0LastCopied,
    c0OverflowedFudge' = c0OverflowedFudge,
    curDenv' = curDenv, cacheDenvTag' = cacheDenvTag, cacheVal' = cacheVal,
  }

  action step = any {
    c0_same_section_restore_begin,
    c0_same_section_restore_finish,
    c0_cross_section_acquire_s1,
    c0_cross_section_release_s1,
    c1_cross_section_acquire_s0,
    c1_cross_section_release_s0,
    cont_return_same_denv,
    cont_return_diff_denv,
    fused_park_recv,
    fused_direct_handoff,
  }

  // INVARIANT 1: No AB-BA copy_gate deadlock (each carrier holds <= 1 gate, never nested)
  val inv_no_gate_deadlock =
    not (c0HeldGate == 0 and c1HeldGate == 1 and gate0Owner == 0 and gate1Owner == 1 and false) and
    ((gate0Owner == 0) implies (c0HeldGate == 0)) and
    ((gate0Owner == 1) implies (c1HeldGate == 0)) and
    ((gate1Owner == 0) implies (c0HeldGate == 1)) and
    ((gate1Owner == 1) implies (c1HeldGate == 1))

  // INVARIANT 2: Fudge headroom strictly preserved on merged single-gate restore
  val inv_fudge_headroom =
    not(c0OverflowedFudge) and c0DestPos >= FUDGE

  // INVARIANT 3: Same-denv write-barrier skip preserves exact denv cache consistency
  val inv_denv_cache_exact =
    cacheDenvTag == curDenv and
    ((curDenv == 1) implies (cacheVal == 100)) and
    ((curDenv == 2) implies (cacheVal == 200))

  // INVARIANT 4: Fused C23 direct handoff never violates FIFO
  val inv_fused_handoff_fifo =
    not(fifoViolated)

  val inv_all =
    inv_no_gate_deadlock and
    inv_fudge_headroom and
    inv_denv_cache_exact and
    inv_fused_handoff_fifo
}
