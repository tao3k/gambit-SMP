module failure_campaign_scope {
  // Scope disposition is not a successful runtime result or a repaired bug.
  type State = { bound: bool, closed: bool, budget: bool, runner: bool,
    overlap: bool, checked: bool, excluded: bool, selected: bool, policy: str }
  var s: State
  pure def initial(bound: bool, closed: bool, budget: bool, runner: bool,
                   overlap: bool, policy: str): State = {
    bound: bound, closed: closed, budget: budget, runner: runner,
    overlap: overlap, checked: false, excluded: false, selected: false, policy: policy,
  }
  action init = {
    nondet bound = Set(false, true).oneOf()
    nondet closed = Set(false, true).oneOf()
    nondet budget = Set(false, true).oneOf()
    nondet runner = Set(false, true).oneOf()
    nondet overlap = Set(false, true).oneOf()
    s' = initial(bound, closed, budget, runner, overlap, "strict")
  }
  action initUnknown = s' = initial(true, false, true, true, false, "ignore-unknown")
  action initAssertion = s' = initial(true, true, false, true, false, "ignore-assertion")
  action initOverlap = s' = initial(true, true, true, true, true, "ignore-overlap")
  val disjointBudget = s.bound and s.closed and s.budget and s.runner and not(s.overlap)
  action classify = all {
    not(s.checked),
    s' = { ...s, checked: true,
      excluded: disjointBudget or s.policy != "strict",
      selected: not(disjointBudget or s.policy != "strict") },
  }
  action step = any { classify, s' = s }
  val safe = (not(s.excluded) or disjointBudget)
    and (not(s.checked) or (s.selected != s.excluded))
  temporal completion = weakFair(classify, s).implies(eventually(s.checked))
}
