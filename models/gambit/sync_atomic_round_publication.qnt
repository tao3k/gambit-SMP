module sync_atomic_round_publication {
  // Two directional handoffs of one payload slot. Sender mutex protection
  // alone does not synchronize the receiver's unlocked polling read.
  // Release/acquire is an abstract GNU atomic contract, not a C compiler proof.
  type State = { policy: int, writerEpoch: int, writerStage: int,
    receiverEpoch: int, receiverStage: int, flag: int, payload: int,
    cached: int, acknowledged: Set[int], badRace: bool,
    badPayload: bool, badOverwrite: bool }
  var channel: State
  pure def initial(policy: int): State = {
    policy: policy, writerEpoch: 1, writerStage: 0,
    receiverEpoch: 1, receiverStage: 0, flag: -1, payload: 0,
    cached: 0, acknowledged: Set(), badRace: false,
    badPayload: false, badOverwrite: false,
  }
  action initFixed = channel' = initial(0)
  action initVolatileFlag = channel' = initial(1)
  action initRelaxedPublish = channel' = initial(2)
  action initRelaxedObserve = channel' = initial(3)
  action initResetOnlyReuse = channel' = initial(4)
  action writePayload = all {
    channel.writerStage == 0,
    channel' = { ...channel, writerStage: 1, payload: channel.writerEpoch * 10,
      badOverwrite: channel.badOverwrite or
        (channel.receiverStage == 2 and channel.receiverEpoch < channel.writerEpoch) },
  }
  action publishFlag = all {
    channel.writerStage == 1,
    channel' = { ...channel, writerStage: 2, flag: channel.writerEpoch },
  }
  action senderTail = all {
    channel.writerStage == 2,
    channel' = { ...channel, writerStage: 3 },
  }
  action observeFlag = {
    nondet stale = Set(false, true).oneOf()
    all {
      channel.receiverStage == 0, channel.flag == channel.receiverEpoch,
      val ordered = channel.policy != 2 and channel.policy != 3
      channel' = { ...channel, receiverStage: 1,
        cached: if (ordered or not(stale)) channel.payload else 0,
        badRace: channel.badRace or channel.policy == 1 },
    }
  }
  action resetFlag = all {
    channel.receiverStage == 1,
    channel' = { ...channel, receiverStage: 2, flag: -1 },
  }
  action consumePayload = all {
    channel.receiverStage == 2,
    val value = if (channel.policy == 4) channel.payload else channel.cached
    channel' = { ...channel, receiverStage: 3,
      badPayload: channel.badPayload or value != channel.receiverEpoch * 10 },
  }
  // The next reverse-direction tree round acknowledges payload consumption.
  // Resetting a local flag does not itself authorize the next payload write.
  action acknowledge = all {
    channel.receiverStage == 3,
    channel' = { ...channel, receiverStage: 4,
      acknowledged: channel.acknowledged.union(Set(channel.receiverEpoch)) },
  }
  action nextWriter = all {
    channel.writerEpoch == 1, channel.writerStage == 3,
    channel.acknowledged.contains(1) or (channel.policy == 4 and channel.flag == -1),
    channel' = { ...channel, writerEpoch: 2, writerStage: 0 },
  }
  action nextReceiver = all {
    channel.receiverEpoch == 1, channel.receiverStage == 4,
    channel' = { ...channel, receiverEpoch: 2, receiverStage: 0, cached: 0 },
  }
  val atomicSafe = not(channel.badRace)
  val payloadSafe = not(channel.badPayload)
  val releaseSafe = payloadSafe
  val acquireSafe = payloadSafe
  val reuseSafe = not(channel.badOverwrite)
  val safe = atomicSafe and payloadSafe and reuseSafe
  val terminal = channel.writerEpoch == 2 and channel.writerStage == 3 and
    channel.receiverEpoch == 2 and channel.receiverStage == 4
  action finished = all { terminal, channel' = channel }
  action step = any { writePayload, publishFlag, senderTail, observeFlag,
    resetFlag, consumePayload, acknowledge, nextWriter, nextReceiver, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(channel)).implies(eventually(terminal))
}
