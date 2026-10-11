module sync_resource_retirement {
  // One processor slot, one already-admitted sender, two resource generations.
  // Source-shaped retain policy detects reinitialization without destruction.
  // Naive destruction/reuse controls expose unlock-before-signal lifetime gaps.
  // Drain is a required ownership contract, not an implemented source repair.
  type State = { policy: int, generation: int, mutexLive: bool, cvLive: bool,
    sender: int, senderGeneration: int, flag: bool, consumed: bool,
    retired: bool, disposed: bool, users: int,
    badInit: bool, badSignal: bool, badEpoch: bool }
  var s: State
  pure def initialState(policy: int): State = {
    policy: policy, generation: 1, mutexLive: true, cvLive: true,
    sender: 0, senderGeneration: 1, flag: false, consumed: false,
    retired: false, disposed: false, users: 0,
    badInit: false, badSignal: false, badEpoch: false,
  }
  action initOld = s' = initialState(0)
  action initEarlyDestroy = s' = initialState(1)
  action initEarlyReuse = s' = initialState(1)
  action initFixed = s' = initialState(2)

  action beginSend = all {
    s.sender == 0, not(s.retired), s.mutexLive, s.cvLive,
    s' = { ...s, sender: 1, users: 1, senderGeneration: s.generation },
  }
  action publish = all {
    s.sender == 1,
    s' = { ...s, sender: 2, flag: true },
  }
  action unlock = all {
    s.sender == 2,
    s' = { ...s, sender: 3 },
  }
  // Fast-path receiver may observe the flag before the sender signals.
  action receive = all {
    s.flag, not(s.consumed),
    s' = { ...s, consumed: true },
  }
  action signal = all {
    s.sender == 3,
    s' = { ...s, sender: 4, users: 0,
      badSignal: s.badSignal or not(s.cvLive),
      badEpoch: s.badEpoch or (s.cvLive and s.senderGeneration != s.generation) },
  }
  action retire = all {
    s.consumed, not(s.retired), s.generation == 1,
    s' = { ...s, retired: true },
  }
  action dispose = all {
    s.retired, not(s.disposed), s.sender >= 3,
    s.policy != 2 or s.users == 0,
    s' = { ...s, disposed: true,
      mutexLive: s.policy == 0, cvLive: s.policy == 0 },
  }
  action reuse = all {
    s.disposed, s.generation == 1,
    s.policy != 2 or s.users == 0,
    s' = { ...s, generation: 2, mutexLive: true, cvLive: true,
      badInit: s.badInit or s.mutexLive or s.cvLive },
  }
  action finished = all { s.generation == 2, s.sender == 4, s' = s }
  action step = any { beginSend, publish, unlock, receive, signal,
                      retire, dispose, reuse, finished }
  val initializationSafe = not(s.badInit)
  val signalSafe = not(s.badSignal)
  val generationSafe = not(s.badEpoch)
  val safe = initializationSafe and signalSafe and generationSafe
}
