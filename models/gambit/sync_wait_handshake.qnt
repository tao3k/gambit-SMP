module sync_wait_handshake {
  // POSIX mutex/condition-variable abstraction for SYNC_GET/SEND_MSG.
  // initOld splits atomic wait ONLY as a fault control; source does not do so.
  var atomicWait: bool
  var receiver: int
  var sender: int
  var owner: int
  var ready: bool
  var sleeping: bool
  var wakePending: bool

  action initOld = all {
    atomicWait' = false, receiver' = 0, sender' = 0, owner' = -1,
    ready' = false, sleeping' = false, wakePending' = false,
  }
  action initFixed = all {
    atomicWait' = true, receiver' = 0, sender' = 0, owner' = -1,
    ready' = false, sleeping' = false, wakePending' = false,
  }
  action change(r: int, p: int, lock: int, value: bool, sleep: bool, wake: bool): bool = all {
    receiver' = r, sender' = p, owner' = lock, ready' = value,
    sleeping' = sleep, wakePending' = wake, atomicWait' = atomicWait,
  }
  // Bounded spin expiry; no timer or spurious wake is needed for this check.
  action spinExit = all { receiver == 0,
    change(1, sender, owner, ready, sleeping, wakePending) }
  action receiverLock = all { receiver == 1, owner == -1,
    change(2, sender, 0, ready, sleeping, wakePending) }
  action predicate = all { receiver == 2, owner == 0,
    change(if (ready) 5 else 3, sender, if (ready) -1 else 0,
           ready, sleeping, wakePending) }
  action wait = all { receiver == 3, owner == 0,
    change(if (atomicWait) 4 else 6, sender, -1, ready, atomicWait, wakePending) }
  action splitSleep = all { receiver == 6,
    change(4, sender, owner, ready, true, wakePending) }
  action resume = all { receiver == 4, wakePending, owner == -1,
    change(2, sender, 0, ready, false, false) }
  action senderLock = all { sender == 0, owner == -1,
    change(receiver, 1, 1, ready, sleeping, wakePending) }
  action publish = all { sender == 1, owner == 1,
    change(receiver, 2, owner, true, sleeping, wakePending) }
  // SYNC_SEND_MSG unlocks before signaling; keep that actual source order.
  action senderUnlock = all { sender == 2, owner == 1,
    change(receiver, 3, -1, ready, sleeping, wakePending) }
  action signal = all { sender == 3,
    change(receiver, 4, owner, ready, sleeping, wakePending or sleeping) }
  action idle = all { receiver == 5, sender == 4,
    change(receiver, sender, owner, ready, sleeping, wakePending) }
  action step = any { spinExit, receiverLock, predicate, wait, splitSleep,
                      resume, senderLock, publish, signal, senderUnlock, idle }
  // ready+sleeping is legal between publication and scheduling the awakened
  // receiver. Only completed send with no pending wake is a lost-wake dead end.
  val safe = not(receiver == 4 and sender == 4 and not(wakePending))
}
