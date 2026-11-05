module consumer_publication {
  // Candidate extension for source review. Current source has no owner word
  // and no completed-operation record. ___TICKETLOCK_LOCK2 still reserves with
  // fetch-add and spins only until ___TICKETLOCK_READ_CURRENT equals that
  // thread-local ticket. The candidate release-stores (holder, ticket) to a
  // distinct word at that loop exit. The spin does not read that word.
  // barrier_sync_op still stores sync_op0, release-stores the flag, and the
  // child acquire-loads, resets the flag, then copies. The candidate
  // release-stores the copied pair (seen round, op) after that copy. The next
  // payload still waits for the post-copy upward send. The flag is not the
  // round id. A stack word and a sticky read of the owner word without
  // current are not this consumer. A split read of the completed pair and a
  // mailbox flag sample are not this publication.
  type State = {
    next: int, current: int, t1: int, t2: int, p1: int, p2: int,
    pubH: int, pubT: int, w1: int, w2: int,
    stackH: int, stackDone: bool, certH: int, certT: int, certDone: bool,
    liveH: int, liveDone: bool,
    round: int, payload: int, flag: int, phase: int,
    seenRound: int, copied: int, doneSeq: int, doneOp: int,
    readSeq: int, readOp: int, readDone: bool,
    splitSeq: int, splitOp: int, splitStage: int,
    repH: int, repT: int, repOp: int, repSeq: int, repDone: bool,
    flagOp: int, flagSeen: bool, republish: bool
  }
  var s: State
  pure def start(bad: bool): State = {
    next: 0, current: 0, t1: -1, t2: -1, p1: 0, p2: 0,
    pubH: 0, pubT: -1, w1: -1, w2: 0,
    stackH: 0, stackDone: false, certH: 0, certT: -1, certDone: false,
    liveH: 0, liveDone: false,
    round: 0, payload: 0, flag: 0, phase: 0,
    seenRound: 0, copied: 0, doneSeq: 0, doneOp: 0,
    readSeq: 0, readOp: 0, readDone: false,
    splitSeq: 0, splitOp: 0, splitStage: 0,
    repH: 0, repT: -1, repOp: 0, repSeq: 0, repDone: false,
    flagOp: 0, flagSeen: false, republish: bad
  }
  action initProtocol = s' = start(false)
  action initCohort = s' = start(true)
  action reserve1 = all {
    s.p1 == 0,
    s' = { ...s, t1: s.next, next: s.next + 1, p1: 1 },
  }
  action reserve2 = all {
    s.p2 == 0,
    s' = { ...s, t2: s.next, next: s.next + 1, p2: 1 },
  }
  action publish1 = all {
    s.p1 == 1, s.current == s.t1,
    s' = { ...s, p1: 2, pubH: 1, pubT: s.t1 },
  }
  action publish2 = all {
    s.p2 == 1, s.current == s.t2,
    s' = { ...s, p2: 2, pubH: 2, pubT: s.t2 },
  }
  action unlock1 = all {
    s.p1 == 2, s' = { ...s, p1: 3, current: s.current + 1 },
  }
  action unlock2 = all {
    s.p2 == 2, s' = { ...s, p2: 3, current: s.current + 1 },
  }
  action stackScan = all {
    not(s.stackDone),
    val match1 = s.w1 >= 0 and s.w1 == s.current
    val match2 = s.w2 >= 0 and s.w2 == s.current
    s' = { ...s, stackDone: true,
      stackH: if (match1 and not(match2)) 1
        else if (match2 and not(match1)) 2 else 0 },
  }
  action certifyHit = all {
    not(s.certDone), s.pubH > 0, s.pubT == s.current,
    s' = { ...s, certDone: true, certH: s.pubH, certT: s.pubT },
  }
  action certifyMiss = all {
    not(s.certDone), not(s.pubH > 0 and s.pubT == s.current),
    s' = { ...s, certDone: true, certH: 0, certT: -1 },
  }
  action liveRead = all {
    not(s.liveDone), s.pubH > 0,
    s' = { ...s, liveDone: true, liveH: s.pubH },
  }
  action store1 = all {
    s.phase == 0, s' = { ...s, phase: 1, round: 1, payload: 1 },
  }
  action release1 = all {
    s.phase == 1, s' = { ...s, phase: 2, flag: 1 },
  }
  action acquire = all {
    s.phase == 2, s.flag == 1, s' = { ...s, phase: 3, seenRound: s.round },
  }
  action reset = all {
    s.phase == 3, s' = { ...s, phase: 4, flag: 0 },
  }
  action overwrite = all {
    s.phase == 4, s.republish,
    s' = { ...s, round: 2, payload: 2, flag: 1 },
  }
  action copy = all {
    s.phase == 4, s' = { ...s, phase: 5, copied: s.payload },
  }
  action publishDone = all {
    s.phase == 5,
    s' = { ...s, phase: 6, doneSeq: s.seenRound, doneOp: s.copied },
  }
  action upward = all {
    s.phase == 6, s' = { ...s, phase: 7 },
  }
  action store2 = all {
    s.phase == 7, not(s.republish),
    s' = { ...s, phase: 8, round: 2, payload: 2 },
  }
  action release2 = all {
    s.phase == 8, s' = { ...s, phase: 9, flag: 1 },
  }
  action acquire2 = all {
    s.phase == 9, s.flag == 1, s' = { ...s, phase: 10, seenRound: s.round },
  }
  action reset2 = all {
    s.phase == 10, s' = { ...s, phase: 11, flag: 0 },
  }
  action copy2 = all {
    s.phase == 11, s' = { ...s, phase: 12, copied: s.payload },
  }
  action publishDone2 = all {
    s.phase == 12,
    s' = { ...s, phase: 13, doneSeq: s.seenRound, doneOp: s.copied },
  }
  action atomicRead = all {
    not(s.readDone), s.doneSeq > 0,
    s' = { ...s, readDone: true, readSeq: s.doneSeq, readOp: s.doneOp },
  }
  action splitSeq = all {
    s.splitStage == 0, s.doneSeq > 0,
    s' = { ...s, splitStage: 1, splitSeq: s.doneSeq },
  }
  action splitOp = all {
    s.splitStage == 1,
    s' = { ...s, splitStage: 2, splitOp: s.doneOp },
  }
  action flagSample = all {
    not(s.flagSeen), s.flag == 1,
    s' = { ...s, flagSeen: true, flagOp: s.payload },
  }
  action assemble = all {
    not(s.repDone), s.certDone, s.readDone,
    s' = { ...s, repDone: true, repH: s.certH, repT: s.certT,
      repOp: s.readOp, repSeq: s.readSeq },
  }
  val terminal = s.p1 == 3 and s.p2 == 3 and s.phase == 13
  action finished = all { terminal, s' = s }
  action step = any {
    reserve1, reserve2, publish1, publish2, unlock1, unlock2,
    stackScan, certifyHit, certifyMiss, liveRead,
    store1, release1, acquire, reset, overwrite, copy, publishDone, upward,
    store2, release2, acquire2, reset2, copy2, publishDone2,
    atomicRead, splitSeq, splitOp, flagSample, assemble, finished
  }
  val ownerConsumer =
    not(s.p1 == 2 and s.p2 == 2) and
    (s.pubH == 0 or s.pubT != s.current or
      (s.pubH == 1 and s.p1 == 2 and s.t1 == s.current) or
      (s.pubH == 2 and s.p2 == 2 and s.t2 == s.current)) and
    (not(s.certDone) or s.certH == 0 or
      (s.certH == 1 and s.p1 >= 2 and s.t1 == s.certT) or
      (s.certH == 2 and s.p2 >= 2 and s.t2 == s.certT))
  val recordAgrees = not(s.readDone) or s.readOp == s.readSeq
  val jointCertificates = not(s.repDone) or (
    (s.repH == 0 or
      (s.repH == 1 and s.p1 >= 2 and s.t1 == s.repT) or
      (s.repH == 2 and s.p2 >= 2 and s.t2 == s.repT)) and
    (s.repOp == 0 or s.repOp == s.repSeq))
  val stackSound = s.stackH == 0 or
    (s.stackH == 1 and s.p1 == 2) or (s.stackH == 2 and s.p2 == 2)
  val liveSound = s.liveH == 0 or
    (s.liveH == 1 and s.p1 == 2) or (s.liveH == 2 and s.p2 == 2)
  val splitAgrees = s.splitStage != 2 or s.splitOp == s.splitSeq
  val flagLive = not(s.flagSeen) or
    (s.flag == 1 and s.flagOp == s.payload and s.flagOp == s.round)
  val jointSameActor = not(s.repDone) or s.repH == 0 or s.repH == 1
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
