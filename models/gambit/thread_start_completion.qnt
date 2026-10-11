module thread_start_completion {
  // Original fixture: two main work units versus one worker unit are not a
  // completion relation under independent SMP scheduling. Join supplies it.
  // Runtime join/writes visibility are assumed, not proved by this model.
  type State = { fixed: bool, mainWork: int, workerWork: bool, published: bool,
                 joined: bool, asserted: bool, wrong: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, mainWork: 0, workerWork: false, published: false,
    joined: false, asserted: false, wrong: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action mainWork = all {
    not(s.asserted), s.mainWork < 2, s' = { ...s, mainWork: s.mainWork + 1 },
  }
  action workerWork = all {
    not(s.workerWork), s' = { ...s, workerWork: true },
  }
  action publish = all {
    s.workerWork, not(s.published), s' = { ...s, published: true },
  }
  action join = all {
    s.fixed, s.mainWork == 2, s.published, not(s.joined),
    s' = { ...s, joined: true },
  }
  action assertion = all {
    s.mainWork == 2, not(s.asserted), not(s.fixed) or s.joined,
    s' = { ...s, asserted: true, wrong: not(s.published) },
  }
  action finished = all { s.asserted, s.published, s' = s }
  action step = any { mainWork, workerWork, publish, join, assertion, finished }
  val safe = not(s.wrong)
}
