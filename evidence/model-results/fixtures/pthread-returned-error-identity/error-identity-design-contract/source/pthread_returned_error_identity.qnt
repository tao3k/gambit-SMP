module pthread_returned_error_identity {
  // Error numbers are abstract identities, not Scheme-tag encodings. Create
  // success alone publishes a new handle and invokes the common initializer.
  type State = { policy: int, operation: str, result: int, ambient: int,
    errnoNow: int, phase: int, error: int, handle: int, initialized: int }
  var s: State
  pure def initial(policy: int, operation: str, result: int, ambient: int): State = {
    policy: policy, operation: operation, result: result, ambient: ambient,
    errnoNow: ambient, phase: 0, error: 0, handle: 17, initialized: 0,
  }
  action initFixed = {
    nondet operation = Set("create", "join").oneOf()
    nondet result = Set(0, 11, 22).oneOf()
    nondet ambient = Set(0, 4, 35).oneOf()
    s' = initial(0, operation, result, ambient)
  }
  action initAmbientErrno = s' = initial(1, "create", 11, 0)
  action invoke = all {
    s.phase == 0,
    s' = { ...s, phase: 1,
      error: if (s.result == 0) 0 else if (s.policy == 1)
        (if (s.ambient == 0) -1 else s.ambient) else s.result,
      handle: if (s.operation == "create" and s.result == 0) 23 else s.handle,
      initialized: if (s.operation == "create" and s.result == 0) 1 else 0 },
  }
  val errorIdentity = s.phase == 0 or s.error == s.result
  val errnoStable = s.errnoNow == s.ambient
  val handleOwnership = s.phase == 0 or
    (if (s.operation == "create" and s.result == 0)
      s.handle == 23 and s.initialized == 1
    else s.handle == 17 and s.initialized == 0)
  val safe = errorIdentity and errnoStable and handleOwnership
  val terminal = s.phase == 1
  action finished = all { terminal, s' = s }
  action step = any { invoke, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
