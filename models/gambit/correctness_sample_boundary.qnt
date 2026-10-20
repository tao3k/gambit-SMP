module correctness_sample_boundary {
  // Release publication is two matched rounds with no failure and no drift.
  // An 8/12 correctness timing, a failed sample, a drifted sample, and a
  // single unmatched round are not that population.
  type State = {
    control: int, rounds: int, failed: bool, stable: bool, published: bool
  }
  var s: State
  pure def initial(control: int): State = {
    control: control, rounds: 0, failed: false, stable: true, published: false
  }
  action initMatched = s' = initial(0)
  action initCorrectness = s' = initial(1)
  action initFailed = s' = initial(2)
  action initSingle = s' = initial(3)
  action initDrift = s' = initial(4)
  action sample = all {
    s.control == 0, s.rounds < 2, not(s.failed), s.stable, not(s.published),
    s' = { ...s, rounds: s.rounds + 1 }
  }
  action publishMatched = all {
    s.control == 0, s.rounds == 2, not(s.failed), s.stable, not(s.published),
    s' = { ...s, published: true }
  }
  action publishCorrectness = all {
    s.control == 1, not(s.published),
    s' = { ...s, rounds: 1, published: true }
  }
  action publishFailed = all {
    s.control == 2, not(s.published),
    s' = { ...s, failed: true, rounds: 1, published: true }
  }
  action oneRound = all {
    s.control == 3, s.rounds == 0, not(s.published),
    s' = { ...s, rounds: 1 }
  }
  action publishSingle = all {
    s.control == 3, s.rounds == 1, not(s.published),
    s' = { ...s, published: true }
  }
  action drift = all {
    s.control == 4, s.stable, not(s.published),
    s' = { ...s, stable: false, rounds: 2 }
  }
  action publishDrift = all {
    s.control == 4, not(s.stable), s.rounds == 2, not(s.published),
    s' = { ...s, published: true }
  }
  val terminal =
    s.control == 0 and s.published and s.rounds == 2 and not(s.failed) and s.stable
  action done = all { terminal, s' = s }
  action step = any {
    sample, publishMatched, publishCorrectness, publishFailed,
    oneRound, publishSingle, drift, publishDrift, done
  }
  val safe =
    not(s.published) or (s.control == 0 and s.rounds == 2 and not(s.failed) and s.stable)
  val notCorrectness = s.control != 1 or not(s.published)
  val notFailed = not(s.published) or not(s.failed)
  val twoRounds = not(s.published) or s.rounds == 2
  val noDrift = not(s.published) or s.stable
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}
