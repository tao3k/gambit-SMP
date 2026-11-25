module smp_heap_limit_lock_release {
  // Models the ordering of the heap-limit interval refusal only; mutex and
  // fatal implementations, real C control flow and concurrent liveness remain
  // separate production obligations.
  type State = { locked: bool, invalid: bool, failed: bool, continued: bool }
  var s: State
  action init = s' = { locked: true, invalid: true, failed: false, continued: false }
  action unlock = all { s.locked, s' = {...s, locked: false} }
  action refuse = all { s.invalid, not(s.locked), s' = {...s, failed: true} }
  action valid = s' = {...s, invalid: false}
  action continueValid = all { not(s.invalid), not(s.locked), s' = {...s, continued: true} }
  val safe = not(s.failed) or not(s.locked)
  run invalidUnlockTest = init.then(unlock).then(refuse).expect(s.failed and safe)
  run validUnlockTest = init.then(valid).then(unlock).then(continueValid).expect(s.continued and safe)
  run fatalWhileHeldControlTest = init.then(all { s' = {...s, failed: true} }).expect(not(safe))
}
