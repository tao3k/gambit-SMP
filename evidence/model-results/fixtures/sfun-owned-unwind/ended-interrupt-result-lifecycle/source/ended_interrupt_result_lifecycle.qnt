module ended_interrupt_result_lifecycle {
  // Validated target, result-mutex registration, propagation and termination.
  // Low-level locking and mutex-owner registration are atomic abstractions.
  // result: 0=fresh, 1=target-owned, 2=abandoned, 3=delivered.
  type State = { policy: str, phase: int, ended: bool, locked: bool,
                 result: int, outcome: int }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, phase: 0, ended: false, locked: false, result: 0, outcome: 0,
  }
  action initFixed = s' = initial("combined")
  action initLeakedLock = s' = initial("leaked-lock")
  action initOmittedAbandon = s' = initial("omitted-abandon")
  action register = all {
    s.phase == 0,
    s' = if (s.ended) { ...s, phase: 4, result: 2, outcome: 2 }
         else { ...s, phase: 1, result: 1 },
  }
  action terminate = all {
    not(s.ended), not(s.locked),
    s' = { ...s, ended: true,
      result: if (s.result == 1 and s.policy != "omitted-abandon") 2 else s.result },
  }
  action acquire = all {
    s.phase == 1, not(s.locked), s' = { ...s, phase: 2, locked: true },
  }
  action propagate = all {
    s.phase == 2, s.locked,
    s' = { ...s, phase: 3, locked: s.ended and s.policy == "leaked-lock" },
  }
  action deliver = all {
    s.phase == 3, not(s.ended), not(s.locked), s.result == 1,
    s' = { ...s, result: 3 },
  }
  action awaitResult = all {
    s.phase == 3, Set(2, 3).contains(s.result),
    s' = { ...s, phase: 4, outcome: s.result },
  }
  val releaseSafe = s.phase < 3 or not(s.locked)
  val abandonmentSafe = not(s.ended) or s.result != 1
  val outcomeSafe = s.phase != 4 or
    (Set(2, 3).contains(s.outcome) and s.outcome == s.result)
  val safe = releaseSafe and abandonmentSafe and outcomeSafe
  val terminal = s.phase == 4
  action finished = all { terminal, s' = s }
  action step = any { register, terminate, acquire, propagate, deliver, awaitResult, finished }
  // Finite nonterminal actions are acyclic. Fairness is an explicit assumption,
  // not a proof of scheduler fairness or progress of the native lock primitives.
  temporal completion = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
