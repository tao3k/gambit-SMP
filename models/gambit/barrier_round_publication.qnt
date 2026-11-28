module barrier_round_publication {
  // Candidate barrier_sync_op, after the reader patch: the parent stores
  // sync_op0, then SYNC_SEND_MSG release-stores the flag. The child
  // acquire-loads that flag, SYNC_INIT_MSG resets it to SYNC_WAITING, and
  // only then copies sync_op0. The next upward send happens after that copy,
  // and the next parent payload waits for that send. The flag value can
  // recur; it is not a round id. A third party that does not consume the
  // mailbox does not get this order. republish drops the wait and is not
  // the participant protocol.
  type State = {
    round: int, payload: int, flag: int, phase: int, seenRound: int,
    copied: int, third: int, thirdRound: int, republish: bool
  }
  var s: State
  pure def start(republish: bool): State = {
    round: 0, payload: 0, flag: 0, phase: 0, seenRound: 0,
    copied: 0, third: 0, thirdRound: 0, republish: republish
  }
  action initParticipant = s' = start(false)
  action initCohort = s' = start(true)
  action store1 = all {
    s.phase == 0, s' = { ...s, phase: 1, round: 1, payload: 1 },
  }
  action release1 = all {
    s.phase == 1, s.payload == 1, s' = { ...s, phase: 2, flag: 1 },
  }
  action acquire = all {
    s.phase == 2, s.flag == 1, s' = { ...s, phase: 3, seenRound: s.round },
  }
  action reset = all {
    s.phase == 3, s' = { ...s, phase: 4, flag: 0 },
  }
  action copy = all {
    s.phase == 4, s' = { ...s, phase: 5, copied: s.payload },
  }
  action upward = all {
    s.phase == 5, s' = { ...s, phase: 6 },
  }
  action store2 = all {
    s.phase == 6, not(s.republish),
    s' = { ...s, phase: 7, round: 2, payload: 2 },
  }
  action release2 = all {
    s.phase == 7, s' = { ...s, phase: 8, flag: 1 },
  }
  action overwrite = all {
    s.phase == 4, s.republish,
    s' = { ...s, round: 2, payload: 2, flag: 1 },
  }
  action thirdSample = all {
    s.flag == 1, s.third == 0,
    s' = { ...s, third: s.payload, thirdRound: s.round },
  }
  val terminal = s.phase == 8
  action finished = all { terminal, s' = s }
  action step = any {
    store1, release1, acquire, reset, copy, upward, store2, release2,
    overwrite, thirdSample, finished
  }
  val participantCopy = s.copied == 0 or s.copied == s.seenRound
  val thirdPartySound = s.third == 0 or
    (s.third == s.payload and s.thirdRound == s.round)
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
