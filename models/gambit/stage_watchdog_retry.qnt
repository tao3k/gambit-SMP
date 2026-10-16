module stage_watchdog_retry {
  // Two attempts and two phases; audit is retained, phase clocks are local.
  type State = { attempt: int, phase: int, elapsed: int, audit: int,
    startAudit: int, denied: bool, complete: bool, carryQuota: bool, resetInside: bool }
  var s: State
  pure def initial(carry: bool, reset: bool): State = {
    attempt: 0, phase: 0, elapsed: 0, audit: 0, startAudit: 0,
    denied: false, complete: false, carryQuota: carry, resetInside: reset,
  }
  action init = s' = initial(false, false)
  action initCarryQuota = s' = initial(true, false)
  action initResetInside = s' = initial(false, true)
  val active = not(s.denied) and not(s.complete)
  action work = all {
    active, s.elapsed < 3,
    s' = { ...s, elapsed: s.elapsed + 1, audit: s.audit + 1 },
  }
  action expire = all {
    active, s.elapsed >= 3 or (s.carryQuota and s.audit >= 3),
    s' = { ...s, denied: true },
  }
  action finish = all {
    active, s.elapsed > 0, s.elapsed < 3,
    if (s.phase == 0)
      s' = { ...s, phase: 1, elapsed: 0, startAudit: s.audit }
    else s' = { ...s, complete: true },
  }
  action retry = all {
    s.denied, s.attempt == 0,
    s' = { ...s, attempt: 1, phase: 0, elapsed: 0, startAudit: s.audit, denied: false },
  }
  action resetInside = all {
    active, s.resetInside, s.elapsed > 0,
    s' = { ...s, elapsed: 0 },
  }
  action advance = any { work, expire, finish, retry }
  action step = any { advance, resetInside, s' = s }
  val freshAllowance = not(s.denied) or s.audit - s.startAudit >= 3
  val nonResettable = s.elapsed == s.audit - s.startAudit
  val terminal = s.complete or (s.denied and s.attempt == 1)
  temporal completion = weakFair(advance, s).implies(eventually(terminal))
}
