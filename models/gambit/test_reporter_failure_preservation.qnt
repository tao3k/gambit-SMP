module test_reporter_failure_preservation {
  // Abstracts the two branches of compare-behavior. It does not prove port
  // equivalence or Scheme name resolution; the source lock binds that change.
  type State = { policy: str, checked: int, mismatch: bool,
    failed: bool, reporterError: bool, complete: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, checked: 0,
    mismatch: false, failed: false, reporterError: false, complete: false }
  action init = s' = initial("sticky-failure")
  action initSuppressed = s' = initial("suppressed")
  action initMissing = s' = initial("missing")
  action compare(equal: bool): bool = all {
      s.checked < 2, not(s.reporterError), not(s.complete),
      s' = { ...s, checked: s.checked + 1, mismatch: s.mismatch or not(equal),
        failed: s.failed or (not(equal) and s.policy == "sticky-failure"),
        reporterError: not(equal) and s.policy == "missing" } }
  action finish = all { s.checked == 2, not(s.reporterError), not(s.complete),
    s' = { ...s, complete: true } }
  action hold = all { s' = s }
  action step = {
    nondet equal = Set(false, true).oneOf()
    any { compare(equal), finish, hold }
  }
  val safe = not(s.mismatch) or s.failed or s.reporterError
  val accepted = s.complete and not(s.failed) and not(s.reporterError)
  val admissionSafe = not(accepted) or not(s.mismatch)
  val contract = safe and admissionSafe
  run suppressionControlTest = initSuppressed.then(compare(false)).then(compare(true)).then(finish)
    .then(all { assert(accepted), assert(not(contract)), hold })
  run missingReporterTest = initMissing.then(compare(false))
    .then(all { assert(not(accepted)), assert(contract), hold })
  run stickyFailureTest = init.then(compare(false)).then(compare(true)).then(finish)
    .then(all { assert(s.failed), assert(not(accepted)), assert(contract), hold })
}
