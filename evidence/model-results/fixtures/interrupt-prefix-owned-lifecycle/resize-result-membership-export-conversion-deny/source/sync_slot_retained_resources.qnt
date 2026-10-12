module sync_slot_retained_resources {
  // Two slot incarnations share one mutex/condition pair. A fast receive can
  // precede the remote sender's unlock/signal. Condition signals carry no epoch.
  // VM destruction assumes admission is closed and all remote users are drained.
  type State = { policy: int, phase: int, sender: int -> int,
    message: Set[int], owner: int, live: bool, initCount: int,
    badReinit: bool, badUse: bool, badDestroy: bool }
  var s: State
  pure def initial(policy: int): State = {
    policy: policy, phase: 0, sender: Map(0 -> 0, 1 -> 0), message: Set(),
    owner: -1, live: true, initCount: 1,
    badReinit: false, badUse: false, badDestroy: false,
  }
  action initFixed = s' = initial(0)
  action initRepeatedInitialization = s' = initial(1)
  action initChildDestruction = s' = initial(2)
  action initUndrainedVmDestruction = s' = initial(3)
  def activeSender(g: int): bool = s.sender.get(g) > 0 and s.sender.get(g) < 4
  val allSendersDone = Set(0, 1).forall(g => s.sender.get(g) == 4)
  action lock = {
    nondet g = Set(0, 1).oneOf()
    all {
      s.sender.get(g) == 0, s.owner == -1,
      (g == 0 and s.phase == 0) or (g == 1 and s.phase == 3),
      s' = { ...s, sender: s.sender.set(g, 1), owner: g,
        badUse: s.badUse or not(s.live) },
    }
  }
  action publish = {
    nondet g = Set(0, 1).oneOf()
    all { s.sender.get(g) == 1,
      s' = { ...s, sender: s.sender.set(g, 2), message: s.message.union(Set(g)) } }
  }
  action unlock = {
    nondet g = Set(0, 1).oneOf()
    all { s.sender.get(g) == 2,
      s' = { ...s, sender: s.sender.set(g, 3), owner: -1,
        badUse: s.badUse or not(s.live) } }
  }
  action signal = {
    nondet g = Set(0, 1).oneOf()
    all { s.sender.get(g) == 3,
      s' = { ...s, sender: s.sender.set(g, 4),
        badUse: s.badUse or not(s.live) } }
  }
  action receiveOld = all {
    s.phase == 0, s.message.contains(0),
    s' = { ...s, phase: 1 },
  }
  action childExit = all {
    s.phase == 1,
    s' = { ...s, phase: 2, live: if (s.policy == 2) false else s.live,
      badDestroy: s.badDestroy or (s.policy == 2 and activeSender(0)) },
  }
  // Joining the receiver does not join the remote sender.
  action joinAndReuse = all {
    s.phase == 2,
    s' = { ...s, phase: 3, message: Set(),
      initCount: if (s.policy == 1) s.initCount + 1 else s.initCount,
      badReinit: s.badReinit or (s.policy == 1 and s.live) },
  }
  action receiveNew = all {
    s.phase == 3, s.message.contains(1), s' = { ...s, phase: 4 },
  }
  action newChildExit = all { s.phase == 4, s' = { ...s, phase: 5 } }
  action sealVmAdmission = all { s.phase == 5, s' = { ...s, phase: 6 } }
  action destroyVmResources = all {
    s.phase == 6, allSendersDone or s.policy == 3,
    s' = { ...s, phase: 7, live: false,
      badDestroy: s.badDestroy or not(allSendersDone) },
  }
  val resourceSafe = not(s.badUse) and not(s.badDestroy) and
    (not(Set(0, 1).exists(g => activeSender(g))) or s.live)
  val initializationSafe = not(s.badReinit) and s.initCount == 1
  val messageSafe = s.phase != 4 or s.message.contains(1)
  val safe = resourceSafe and initializationSafe and messageSafe
  val terminal = s.phase == 7 and allSendersDone
  action finished = all { terminal, s' = s }
  action step = any { lock, publish, unlock, signal, receiveOld, childExit,
    joinAndReuse, receiveNew, newChildExit, sealVmAdmission, destroyVmResources, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
