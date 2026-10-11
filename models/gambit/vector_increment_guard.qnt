module vector_increment_guard {
  // Public increment's optional delta is a fixnum, unlike arbitrary vector
  // elements. Unsafe fetch-add must not run for an invalid explicit delta.
  type State = { fixed: bool, phase: int, explicit: bool, fixnum: bool,
                 mutated: bool, error: bool }
  var s: State
  pure def initial(fixed: bool): State = {
    fixed: fixed, phase: 0, explicit: false, fixnum: true,
    mutated: false, error: false,
  }
  action initOld = s' = initial(false)
  action initFixed = s' = initial(true)
  action choose(explicit: bool, fixnum: bool): bool = all {
    s.phase == 0,
    s' = { ...s, phase: 1, explicit: explicit, fixnum: fixnum },
  }
  action dispatch = all {
    s.phase == 1,
    val invalid = s.explicit and not(s.fixnum)
    val rejected = s.fixed and invalid
    s' = { ...s, phase: 2, mutated: not(rejected), error: rejected },
  }
  action finished = all { s.phase == 2, s' = s }
  action step = any { choose(false, true), choose(true, true),
                      choose(true, false), dispatch, finished }
  val safe = s.phase != 2 or
    (if (s.explicit and not(s.fixnum)) s.error and not(s.mutated)
     else not(s.error) and s.mutated)
}
