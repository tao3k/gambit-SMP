module smp_interpreter_rte_alias {
  // Two logical call environments. Existing escaped locations can be observed
  // by a closure or multi-shot continuation even after another invocation starts.
  // Values are bounded; identity and mutation, not allocation bytes, are modeled.
  type State = { current: int, v1: int, v2: int, closure: bool, continuation: bool,
    reused: bool, observed: int, resumes: int, bad: bool }
  var s: State
  action init = s' = { current: 1, v1: 11, v2: 0, closure: false,
    continuation: false, reused: false, observed: 0, resumes: 0, bad: false }
  action escapeClosure = all { s.current == 1, not(s.reused), not(s.closure), s' = {...s, closure: true} }
  action capture = all { s.current == 1, not(s.reused), not(s.continuation), s' = {...s, continuation: true} }
  action newCall = all { s.current == 1, s' = {...s, current: 2, v2: 22} }
  // Reuse is a conditional optimization only if no observer retains location 1.
  action reuseCall = all { s.current == 1, not(s.closure), not(s.continuation),
    s' = {...s, current: 2, v1: 22, v2: 22, reused: true} }
  action mutateClosure = all { s.closure, s.v1 != 12, s' = {...s, v1: 12} }
  action observeClosure = all { s.closure, s.observed != s.v1, s' = {...s, observed: s.v1} }
  action resume = all { s.continuation, s.resumes < 2,
    s' = {...s, current: 1, resumes: s.resumes + 1} }
  action step = any { escapeClosure, capture, newCall, reuseCall, mutateClosure,
    observeClosure, resume, s' = s }
  val safe = all { s.reused implies (not(s.closure) and not(s.continuation)),
    s.closure implies not(s.reused), s.continuation implies not(s.reused),
    not(s.bad) }
  run closureMutationTest = init.then(escapeClosure).then(newCall).then(mutateClosure)
    .then(observeClosure).expect(s.observed == 12 and s.v2 == 22 and safe)
  run multishotTest = init.then(capture).then(newCall).then(resume).then(newCall)
    .then(resume).expect(s.resumes == 2 and s.v1 == 11 and safe)
  run noEscapeReuseTest = init.then(reuseCall).expect(s.reused and safe)
  run capturedReuseControlTest = init.then(capture)
    .then(all { s' = {...s, current: 2, v1: 22, reused: true} }).expect(not(safe))
  run closureReuseControlTest = init.then(escapeClosure)
    .then(all { s' = {...s, current: 2, v1: 22, reused: true} }).expect(not(safe))
}
