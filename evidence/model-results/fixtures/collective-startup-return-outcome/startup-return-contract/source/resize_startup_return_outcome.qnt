module resize_startup_return_outcome {
  // One slot abstracts startup outcome; no host CPU limit is implied.
  type State = { fixed: bool, root: bool, ready: bool, inputError: int,
    settled: bool, status: int, outputError: int, dispatched: bool,
    admitted: bool }
  var s: State
  pure def initial(fixed: bool, root: bool, ready: bool, error: int): State = {
    fixed: fixed, root: root, ready: ready, inputError: error,
    settled: false, status: if (ready) 1 else 0, outputError: error,
    dispatched: false, admitted: false,
  }
  action initMissingReady = s' = initial(false, false, false, 0)
  action initFixed = {
    nondet root = Set(false, true).oneOf()
    nondet ready = Set(false, true).oneOf()
    nondet error = Set(0, 1).oneOf()
    s' = initial(true, root, ready, error)
  }
  action settle = all {
    not(s.settled),
    s' = { ...s, settled: true,
      status: if (s.ready) 1 else -1,
      outputError: if (s.fixed and not(s.root) and not(s.ready)
        and s.inputError == 0) 2 else s.inputError },
  }
  action dispatch = all {
    s.settled, not(s.dispatched),
    s' = { ...s, dispatched: true, admitted: s.outputError == 0 },
  }
  val startupNotAdmitted = not(s.dispatched and not(s.root) and not(s.ready))
    or not(s.admitted)
  val rootErrorPreserved = not(s.settled and s.root)
    or s.outputError == s.inputError
  val existingErrorPreserved = not(s.settled and s.inputError != 0)
    or s.outputError == s.inputError
  val readySuccessPreserved = not(s.dispatched and s.ready and s.inputError == 0)
    or s.admitted
  val safe = startupNotAdmitted and rootErrorPreserved
    and existingErrorPreserved and readySuccessPreserved
  action finished = all { s.dispatched, s' = s }
  action step = any { settle, dispatch, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(s.dispatched))
}
