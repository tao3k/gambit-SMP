module ticket_observer_snapshot {
  // Two writers sharing one diagnostic slot and one reader. Atomic fields,
  // acquire/release publication and fences are premises, not C refinement.
  // Unique tags do not wrap. Dropped records grant no observation authority.
  type State = {
    exclusive: bool, unique: bool, epochCheck: bool, clearExit: bool,
    a: int, b: int, claim: int, seq: int, data1: int, data2: int,
    epoch: int, stamp: int, aEpoch: int, bEpoch: int,
    reader: int, v1: int, v2: int, ra: int, rb: int, readStamp: int,
    startEpoch: int, decisionEpoch: int, accepted: bool,
    barrier: int, loggedActive: bool, barrierRead: bool, overlapWitness: bool,
    barrierAccepted: bool
  }
  var s: State
  pure def initial(exclusive: bool, unique: bool, epochCheck: bool,
                   clearExit: bool): State = {
    exclusive: exclusive, unique: unique, epochCheck: epochCheck, clearExit: clearExit,
    a: 0, b: 0, claim: 0, seq: 0, data1: 0, data2: 0,
    epoch: 0, stamp: 0, aEpoch: 0, bEpoch: 0,
    reader: 0, v1: 0, v2: 0, ra: 0, rb: 0, readStamp: 0,
    startEpoch: 0, decisionEpoch: 0, accepted: false,
    barrier: 0, loggedActive: false, barrierRead: false,
    overlapWitness: false, barrierAccepted: false
  }
  action initFixed = s' = initial(true, true, true, true)
  action initNoClaim = s' = initial(false, true, true, true)
  action initReusedTag = s' = initial(true, false, true, true)
  action initNoEpoch = s' = initial(true, true, false, true)
  action initStaleBarrier = s' = initial(true, true, true, false)
  pure def phase(s: State, who: int): int = if (who == 1) s.a else s.b
  action begin(who: int): bool = all {
    phase(s, who) == 0, s.claim == 0 or not(s.exclusive),
    s' = if (who == 1)
      { ...s, a: 1, aEpoch: s.epoch, claim: who, seq: 2 * who - 1 }
    else { ...s, b: 1, bEpoch: s.epoch, claim: who, seq: 2 * who - 1 },
  }
  action drop(who: int): bool = all {
    phase(s, who) == 0, s.exclusive, s.claim != 0,
    s' = if (who == 1) { ...s, a: 4 } else { ...s, b: 4 },
  }
  action writeFirst(who: int): bool = all {
    phase(s, who) == 1, s.claim == who or not(s.exclusive),
    s' = if (who == 1) { ...s, a: 2, data1: who }
         else { ...s, b: 2, data1: who },
  }
  action writeSecond(who: int): bool = all {
    phase(s, who) == 2, s.claim == who or not(s.exclusive),
    s' = if (who == 1) { ...s, a: 3, data2: who }
         else { ...s, b: 3, data2: who },
  }
  action commit(who: int): bool = all {
    phase(s, who) == 3, s.claim == who or not(s.exclusive),
    val tag = if (s.unique) 2 * who else 2
    s' = if (who == 1) { ...s, a: 4, claim: 0, seq: tag, stamp: s.aEpoch }
         else { ...s, b: 4, claim: 0, seq: tag, stamp: s.bEpoch },
  }
  action newEpoch = all { s.epoch == 0, s' = { ...s, epoch: 1 } }
  action readVersion = all {
    s.reader == 0, s' = { ...s, reader: 1, v1: s.seq, startEpoch: s.epoch },
  }
  action readFirst = all { s.reader == 1, s' = { ...s, reader: 2, ra: s.data1 } }
  action readSecond = all {
    s.reader == 2, s' = { ...s, reader: 3, rb: s.data2, readStamp: s.stamp },
  }
  action validate = all {
    s.reader == 3,
    s' = { ...s, reader: 4, v2: s.seq, decisionEpoch: s.epoch,
      accepted: s.v1 > 0 and s.v1 % 2 == 0 and s.v1 == s.seq and
        (not(s.epochCheck) or (s.startEpoch == s.epoch and s.readStamp == s.epoch)) },
  }
  action enterBarrier = all {
    s.barrier == 0, s' = { ...s, barrier: 1, loggedActive: true },
  }
  action leaveBarrier = all {
    s.barrier == 1,
    s' = { ...s, barrier: 2, loggedActive: not(s.clearExit) },
  }
  action observeBarrier = all {
    not(s.barrierRead),
    s' = { ...s, barrierRead: true, barrierAccepted: s.loggedActive,
      overlapWitness: s.barrier == 1 },
  }
  val terminal = s.a == 4 and s.b == 4 and s.reader == 4 and
    s.barrier == 2 and s.barrierRead and s.epoch == 1
  action finished = all { terminal, s' = s }
  action step = any {
    begin(1), begin(2), drop(1), drop(2), writeFirst(1), writeFirst(2),
    writeSecond(1), writeSecond(2), commit(1), commit(2), newEpoch,
    readVersion, readFirst, readSecond, validate, enterBarrier, leaveBarrier,
    observeBarrier, finished
  }
  val coherent = not(s.accepted) or
    (s.ra > 0 and s.ra == s.rb and s.ra == s.v2 / 2)
  val namespaceSafe = not(s.accepted) or s.readStamp == s.decisionEpoch
  val barrierSafe = not(s.barrierAccepted) or s.overlapWitness
  val serializedSnapshot = coherent
  val uniqueSnapshot = coherent
  val safe = coherent and namespaceSafe and barrierSafe
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
