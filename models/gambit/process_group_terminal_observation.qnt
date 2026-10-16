module process_group_terminal_observation {
  type State = { policy: str, group: str, remaining: int, parentReaped: bool,
    outcome: str }
  var s: State
  pure def initial(policy, reaped) = { policy: policy, group: "unobserved",
    remaining: 2, parentReaped: reaped, outcome: "observing" }
  action init = s' = initial("strict", true)
  action initGuess = s' = initial("guess", true)
  action initUnreaped = s' = initial("ignore-parent", false)
  action denied = all { s.outcome == "observing", s.remaining > 0,
    s' = { ...s, group: "unknown", remaining: s.remaining - 1 } }
  action absent = all { s.outcome == "observing", s.remaining > 0,
    s' = { ...s, group: "absent", remaining: s.remaining - 1 } }
  action present = all { s.outcome == "observing", s.remaining > 0,
    s' = { ...s, group: "present", remaining: s.remaining - 1, outcome: "rejected" } }
  action accept = all { s.outcome == "observing",
    (s.group == "absent" and (s.parentReaped or s.policy == "ignore-parent")) or
      (s.group == "unknown" and s.policy == "guess"),
    s' = { ...s, outcome: "accepted" } }
  action reject = all { s.outcome == "observing", s.remaining == 0 or
    (s.group == "absent" and not(s.parentReaped)),
    s' = { ...s, outcome: "rejected" } }
  val terminal = s.outcome != "observing"
  action finished = all { terminal, s' = s }
  action step = any { denied, absent, present, accept, reject, finished }
  val safe = s.outcome != "accepted" or (s.group == "absent" and s.parentReaped)
  val noStall = terminal or enabled(step)
  val contract = safe and noStall
  run resolvedPermissionTest = init.then(denied).then(absent).then(accept)
    .then(all { assert(safe), assert(s.outcome == "accepted"), s' = s })
  run unknownBudgetTest = init.then(denied).then(denied).then(reject)
    .then(all { assert(safe), assert(s.outcome == "rejected"), s' = s })
  run guessedControlTest = initGuess.then(denied).then(accept)
    .then(all { assert(not(safe)), s' = s })
  run unreapedControlTest = initUnreaped.then(absent).then(accept)
    .then(all { assert(not(safe)), s' = s })
}
