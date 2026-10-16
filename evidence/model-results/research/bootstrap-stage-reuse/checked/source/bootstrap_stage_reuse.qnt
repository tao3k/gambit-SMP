module bootstrap_stage_reuse {
  // Two compiler generations, not two hardware workers. Exactness abbreviates
  // source, compiler, profile, generated inputs and retained artifact hashes.
  type State = { policy: str, exact: bool, cache: bool, reviewed: bool,
    committed: int, active: bool, complete: bool, charged: int,
    cost: int, admitted: bool, historical: int, launchBound: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, exact: true,
    cache: true, reviewed: false, committed: 0, active: false, complete: false,
    charged: 3, cost: 0, admitted: false, historical: 3, launchBound: false }
  action init = s' = initial("checked")
  action initStale = s' = initial("stale-cache")
  action initPartial = s' = initial("partial-pass")
  action initReset = s' = initial("reset-progress")
  action review = all { not(s.active), not(s.admitted), s.cache, s.exact,
    not(s.reviewed), s' = { ...s, reviewed: true } }
  action begin = all { not(s.active), not(s.admitted), s.committed < 2, s.cache,
    s.reviewed, s.exact or s.policy == "stale-cache",
    s' = { ...s, active: true, complete: false,
      launchBound: s.exact and s.cache and s.reviewed } }
  action finish = all { s.active, not(s.complete),
    s' = { ...s, complete: true } }
  action commit = all { s.active, s.complete, s.exact,
    s' = { ...s, committed: s.committed + 1, active: false,
      complete: false, charged: s.charged + 1, cost: s.cost + 1 } }
  // Outer quiescence and charging do not certify a pass interrupted before
  // terminal success. Reuse still requires the full artifact inventory.
  action interrupt = all { s.active,
    s' = { ...s, active: false, complete: false, cache: false,
      charged: s.charged + 1, cost: s.cost + 1 } }
  action drift = all { s.exact, not(s.admitted),
    s' = { ...s, exact: false } }
  action clear = all { s.cache, not(s.active), not(s.admitted),
    s' = { ...s, cache: false,
      historical: if (s.policy == "reset-progress") 0 else s.historical } }
  action admit = all { not(s.active), s.cache, not(s.admitted),
    (s.committed == 2 and s.exact and s.reviewed) or
      (s.policy == "partial-pass" and s.committed == 1),
    s' = { ...s, admitted: true } }
  action hold = s' = s
  action step = any { review, begin, finish, commit, interrupt, drift, clear, admit, hold }
  val exactLaunch = s.active.implies(s.launchBound)
  val completePasses = s.admitted.implies(s.committed == 2 and s.exact and s.reviewed and s.cache)
  val progressRetained = s.historical == 3
  val charged = s.charged == 3 + s.cost
  val safe = exactLaunch and completePasses and progressRetained and charged and
    s.committed >= 0 and s.committed <= 2
  val noStall = enabled(step)
  // Terminal progress, not eventual success under finite resources. A drift
  // can prevent commit; interrupt remains enabled and preserves the failure.
  temporal progress = (weakFair(commit, Set(s)) and weakFair(interrupt, Set(s)))
    .implies(always(s.active.implies(eventually(not(s.active)))))
  run twoPassesTest = init.then(review).then(begin).then(finish).then(commit)
    .then(begin).then(finish).then(commit).then(admit)
    .then(all { assert(safe), assert(s.admitted), s' = s })
  run interruptedSecondPassTest = init.then(review).then(begin).then(finish).then(commit)
    .then(begin).then(interrupt)
    .then(all { assert(safe), assert(s.committed == 1), assert(not(s.admitted)), s' = s })
  run staleCacheControlTest = initStale.then(review).then(drift).then(begin)
    .then(all { assert(not(exactLaunch)), s' = s })
  run partialPassControlTest = initPartial.then(review).then(begin).then(finish).then(commit).then(admit)
    .then(all { assert(not(completePasses)), s' = s })
  run cleanupProgressControlTest = initReset.then(clear)
    .then(all { assert(not(progressRetained)), s' = s })
}
