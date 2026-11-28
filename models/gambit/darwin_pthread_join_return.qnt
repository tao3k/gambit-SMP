module darwin_pthread_join_return {
  // Darwin pthread_join returns, measured on this host. This does not edit
  // joinable_error_same_owner.qnt. It separates observations that model was
  // too coarse to keep apart. Milestone stays 8. Not a source patch and not 9/12.
  //
  // control 0 is the Gambit resize graph: the worker is not inside
  // pthread_join of the owner. ___thread_join waits for ___thread_exit and
  // returns 0. Calling it earlier, while the worker is still in the VM, does
  // not produce an errno.
  // control 1: the worker is blocked on a mutex the owner holds. pthread_join
  // does not return. It is not EDEADLK.
  // control 2: the owner calls pthread_join first, and only then does the
  // worker call pthread_join of the owner. The owner's call does not return.
  // control 3: the worker is already inside pthread_join of the owner. The
  // owner's first pthread_join returns 11. The same owner's next call also
  // returns 11 until the worker has left. A later 0 is that platform cycle
  // after the worker exits, not the resize graph.
  // control 4: a pre-join flag is treated as closure.
  // first: -1 no return, 0 pthread_join returned 0, 11 EDEADLK.
  type State = {
    control: int, worker: int, first: int, sameOwnerZero: bool,
    closed: bool, milestone: int
  }
  var s: State
  pure def initial(control: int, worker: int): State = {
    control: control, worker: worker, first: -1, sameOwnerZero: false,
    closed: false, milestone: 8
  }
  action initResize = s' = initial(0, 0)
  action initMutex = s' = initial(1, 0)
  action initOwnerFirst = s' = initial(2, 0)
  action initCycle = s' = initial(3, 1)
  action initFlag = s' = initial(4, 0)
  action resizeJoinReturnsZero = all {
    s.control == 0, s.worker == 0, s.first == -1, not(s.closed),
    s' = { ...s, worker: 2, first: 0 }
  }
  action pretendMutexIsErrno = all {
    s.control == 1, s.first == -1, not(s.closed),
    s' = { ...s, first: 11 }
  }
  action pretendOwnerFirstIsErrno = all {
    s.control == 2, s.first == -1, not(s.closed),
    s' = { ...s, first: 11 }
  }
  action observeCycleEleven = all {
    s.control == 3, s.worker == 1, s.first == -1, not(s.closed),
    s' = { ...s, first: 11 }
  }
  action retryWhileWorkerStillJoins = all {
    s.control == 3, s.worker == 1, s.first == 11, not(s.sameOwnerZero),
    s' = { ...s, sameOwnerZero: true }
  }
  action workerLeavesCycle = all {
    s.control == 3, s.worker == 1, s.first == 11, not(s.sameOwnerZero),
    s' = { ...s, worker: 2 }
  }
  action sameOwnerAfterWorkerExits = all {
    s.control == 3, s.worker == 2, s.first == 11, not(s.sameOwnerZero),
    not(s.closed),
    s' = { ...s, sameOwnerZero: true }
  }
  action closeFromFlag = all {
    s.control == 4, not(s.closed),
    s' = { ...s, closed: true }
  }
  val terminal =
    s.control == 0 and s.worker == 2 and s.first == 0 and not(s.sameOwnerZero) and
    not(s.closed) and s.milestone == 8
  action done = all { terminal, s' = s }
  action step = any {
    resizeJoinReturnsZero, pretendMutexIsErrno, pretendOwnerFirstIsErrno,
    observeCycleEleven, retryWhileWorkerStillJoins, workerLeavesCycle,
    sameOwnerAfterWorkerExits, closeFromFlag, done
  }
  val safe =
    s.milestone == 8 and not(s.closed) and
    (s.control != 0 or s.first != 11) and
    (not(s.sameOwnerZero) or (s.control == 3 and s.worker == 2 and s.first == 11))
  val mutexIsNotAnErrno = s.control != 1 or s.first == -1
  val ownerFirstIsNotEdeadlk = s.control != 2 or s.first == -1
  val retryStaysEleven = not(s.sameOwnerZero) or s.worker == 2
  val flagIsNotClosure = not(s.closed)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}
