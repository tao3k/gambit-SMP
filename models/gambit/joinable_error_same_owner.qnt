module joinable_error_same_owner {
  // One retired processor, one exclusive owner. Source order is
  // recover_retired_processors: ___thread_join, and only ___NO_ERR then
  // ___transfer_mem_pstate, ___cleanup_mem_pstate, clear join_pending, and
  // decrement pending_join_count. An error returns with the slot still pending.
  // ___vm_resize_pstate refuses to continue while that count is nonzero.
  // cleanup_interrupts_pstate / ___cleanup_os_pstate on the exiting thread are
  // not host quiet of an old handler generation. Chez and OCaml separate
  // membership withdrawal from descriptor and handler quiescence; that
  // distinction is the extra event below, not their runtime transplanted here.
  // policy 0 is the candidate join order. policy 1 drops the count on error.
  // policy 2 is the same join order plus quiet while the join is still owned.
  // policy 3 transfers without a successful join. policy 4 resizes from a
  // hostQuiet flag that no action earned.
  type State = {
    policy: int, failedOnce: bool, pending: bool, joined: bool,
    transferred: bool, count: int, oldHandler: bool, hostQuiet: bool,
    quietEarned: bool, resized: bool, abandoned: bool, crossed: bool
  }
  var s: State
  pure def initial(policy: int, hostQuiet: bool): State = {
    policy: policy, failedOnce: false, pending: true, joined: false,
    transferred: false, count: 1, oldHandler: true, hostQuiet: hostQuiet,
    quietEarned: false, resized: false, abandoned: false, crossed: false
  }
  action initReviewed = s' = initial(2, false)
  action initIgnore = s' = initial(1, false)
  action initSourceResize = s' = initial(0, false)
  action initEarlyTransfer = s' = initial(3, false)
  action initGivenQuiet = s' = initial(4, true)
  action joinFail = all {
    s.pending, not(s.joined), not(s.failedOnce), not(s.transferred),
    s' = { ...s, failedOnce: true }
  }
  action joinOk = all {
    s.pending, not(s.joined), not(s.transferred),
    s' = { ...s, joined: true }
  }
  // Not an effect of seal, sigaction, local interrupt cleanup, or join.
  action quietWhileOwned = all {
    s.policy == 2, s.pending, s.oldHandler, not(s.hostQuiet), not(s.quietEarned),
    s' = { ...s, oldHandler: false, hostQuiet: true, quietEarned: true }
  }
  action transferClear = all {
    s.joined, s.pending, not(s.transferred),
    s.policy != 2 or s.quietEarned,
    s' = { ...s, transferred: true, pending: false, count: 0 }
  }
  action ignoreDrop = all {
    s.policy == 1, s.pending, s.failedOnce, not(s.joined), not(s.transferred),
    s' = { ...s, pending: false, count: 0, abandoned: true }
  }
  action transferWithoutJoin = all {
    s.policy == 3, s.pending, not(s.joined), not(s.transferred),
    s' = { ...s, transferred: true }
  }
  action resizeOwned = all {
    s.policy == 2, s.count == 0, s.joined, s.transferred, s.quietEarned,
    not(s.oldHandler), not(s.resized),
    s' = { ...s, resized: true }
  }
  action resizeSource = all {
    s.policy == 0, s.count == 0, s.transferred, not(s.resized),
    s' = { ...s, resized: true, crossed: s.oldHandler or not(s.hostQuiet) }
  }
  action resizeOnPremise = all {
    s.policy == 4, s.count == 0, s.hostQuiet, not(s.quietEarned), not(s.resized),
    s' = { ...s, resized: true }
  }
  val terminal =
    s.policy == 2 and s.resized and s.quietEarned and s.joined and
    s.transferred and not(s.pending) and not(s.oldHandler) and
    not(s.abandoned) and not(s.crossed)
  action done = all { terminal, s' = s }
  action step = any {
    joinFail, joinOk, quietWhileOwned, transferClear, ignoreDrop,
    transferWithoutJoin, resizeOwned, resizeSource, resizeOnPremise, done
  }
  val safe =
    not(s.abandoned) and not(s.crossed) and
    (not(s.transferred) or s.joined) and
    (not(s.resized) or (s.quietEarned and not(s.oldHandler) and s.count == 0)) and
    (not(s.quietEarned) or s.hostQuiet) and
    (s.count != 0 or not(s.pending))
  val retentionSafe = not(s.abandoned)
  val noCross = not(s.crossed)
  val orderSafe = not(s.transferred) or s.joined
  val earnedQuiet = not(s.resized) or s.quietEarned
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}
