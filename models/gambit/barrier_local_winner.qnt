module barrier_local_winner {
  // Resolved barrier contract. The caller's proposal can win. COMPLETED_PAST
  // requires an election and op == elected, which may equal the entry op.
  // Publishing the entry op before election is the rejected event. Payload
  // stores follow a release fence; the reader installs them only after
  // acquire fences and a matching seq. ABSENT is not idleness. The flag is
  // not the round. A HISTORICAL owner status beside COMPLETED_PAST is not
  // SAME_CYCLE. Status 2 is COMPLETED_PAST. Pair 9 is SAME_CYCLE.
  type State = {
    part: int, entryOp: int, child: int, elected: int, electedDone: bool,
    round: int, flag: int, flagBack: bool,
    seq: int, odd: bool, wRel: bool, wRel2: bool,
    op: int, recRound: int, tag: int,
    wroteOp: bool, wroteRound: bool, wroteTag: bool,
    rStage: int, rSeq: int, rOp: int, rRound: int, rTag: int, rStatus: int,
    naiveDone: bool, naiveOp: int, naiveRound: int, naiveAccept: bool,
    flagDone: bool, flagClaim: int,
    ownerView: int, reported: bool, pairO: int, pairB: int,
    mislabel: bool, infer: bool
  }
  var s: State
  pure def start(mode: int): State = {
    part: 0, entryOp: 4, child: -1, elected: 0, electedDone: false,
    round: 0, flag: 1, flagBack: false,
    seq: 0, odd: false, wRel: false, wRel2: false,
    op: 0, recRound: 0, tag: 0,
    wroteOp: false, wroteRound: false, wroteTag: false,
    rStage: 0, rSeq: -1, rOp: 0, rRound: 0, rTag: 0, rStatus: 0,
    naiveDone: false, naiveOp: 0, naiveRound: 0, naiveAccept: false,
    flagDone: false, flagClaim: -1,
    ownerView: 3, reported: false, pairO: 0, pairB: 0,
    mislabel: mode == 1, infer: mode == 2
  }
  action initProtocol = s' = start(0)
  action initMislabel = s' = start(1)
  action initInfer = s' = start(2)
  action childLoses = all {
    s.child < 0, not(s.mislabel), s' = { ...s, child: 8 },
  }
  action childWins = all {
    s.child < 0, not(s.mislabel), s' = { ...s, child: 1 },
  }
  action block = all {
    s.part == 0, not(s.mislabel), s' = { ...s, part: 1 },
  }
  action elect = all {
    s.part == 1, s.child >= 0, not(s.mislabel),
    s' = { ...s, part: 2, electedDone: true, round: 1,
      elected: if (s.child < s.entryOp) s.child else s.entryOp },
  }
  action copy = all {
    s.part == 2, s' = { ...s, part: 3 },
  }
  action begin = all {
    s.part == 3, not(s.odd),
    s' = { ...s, part: 4, odd: true, seq: s.seq + 1 },
  }
  action releaseWrite = all {
    s.part == 4, s.odd, not(s.wRel), s' = { ...s, wRel: true },
  }
  action writeOp = all {
    s.part == 4, s.wRel, not(s.wroteOp),
    s' = { ...s, wroteOp: true, op: s.elected },
  }
  action writeRound = all {
    s.part == 4, s.wRel, not(s.wroteRound),
    s' = { ...s, wroteRound: true, recRound: s.round },
  }
  action writeTag = all {
    s.part == 4, s.wRel, not(s.wroteTag),
    s' = { ...s, wroteTag: true, tag: 1 },
  }
  action releaseEven = all {
    s.part == 4, s.wroteOp, s.wroteRound, s.wroteTag, not(s.wRel2),
    s' = { ...s, wRel2: true },
  }
  action endPub = all {
    s.part == 4, s.wRel2, s.op == s.elected, s.recRound == s.round, s.tag == 1,
    s' = { ...s, part: 5, odd: false, seq: s.seq + 1 },
  }
  action finish = all {
    s.part == 5, s' = { ...s, part: 6 },
  }
  action mispublish = all {
    s.mislabel, s.part == 0, not(s.odd), not(s.electedDone),
    s' = { ...s, part: 5, seq: 2, op: s.entryOp, recRound: 0, tag: 1 },
  }
  action loadSeq = all {
    s.rStage == 0,
    s' = if (s.odd) { ...s, rStage: 5, rStatus: 4 }
      else if (s.seq == 0) { ...s, rStage: 5, rStatus: 1 }
      else { ...s, rStage: 1, rSeq: s.seq },
  }
  action acquirePayload = all {
    s.rStage == 1, s' = { ...s, rStage: 2 },
  }
  action loadPayload = all {
    s.rStage == 2,
    s' = { ...s, rStage: 3, rOp: s.op, rRound: s.recRound, rTag: s.tag },
  }
  action acquireSeq = all {
    s.rStage == 3, s' = { ...s, rStage: 4 },
  }
  action classify = all {
    s.rStage == 4,
    s' = if (s.odd or s.seq != s.rSeq) { ...s, rStage: 5, rStatus: 4 }
      else if (s.rTag == 1) { ...s, rStage: 5, rStatus: 2 }
      else { ...s, rStage: 5, rStatus: 1 },
  }
  action naiveRead = all {
    not(s.naiveDone), s.odd, s.wRel,
    s' = { ...s, naiveDone: true, naiveAccept: true, naiveOp: s.op, naiveRound: s.recRound },
  }
  action flagSample = all {
    not(s.flagDone), s.flag == 1,
    s' = { ...s, flagDone: true, flagClaim: s.flag },
  }
  action flagReset = all {
    s.flag == 1, s.part >= 2, s' = { ...s, flag: 0 },
  }
  action flagReuse = all {
    s.flag == 0, not(s.flagBack), s' = { ...s, flag: 1, flagBack: true },
  }
  action assemble = all {
    not(s.reported), s.rStage == 5, not(s.infer),
    s' = { ...s, reported: true, pairO: s.ownerView, pairB: s.rStatus },
  }
  action inferCycle = all {
    s.infer, not(s.reported), s.rStatus == 2, s.ownerView == 3,
    s' = { ...s, reported: true, pairO: 9, pairB: 9 },
  }
  val terminal = s.part == 6 and s.rStage == 5 and s.reported
  action finished = all { terminal, s' = s }
  action step = any {
    childLoses, childWins, block, elect, copy, begin, releaseWrite,
    writeOp, writeRound, writeTag, releaseEven, endPub, finish, mispublish,
    loadSeq, acquirePayload, loadPayload, acquireSeq, classify, naiveRead,
    flagSample, flagReset, flagReuse, assemble, inferCycle, finished
  }
  val barrierImpl =
    s.rStatus != 5 and s.pairO != 9 and s.pairB != 9 and
    (s.rStatus != 2 or
      (s.electedDone and s.rOp == s.elected and s.rRound == s.round and s.rTag == 1)) and
    (not(s.reported) or (s.pairO == s.ownerView and s.pairB == s.rStatus))
  val absentIsIdle = s.rStatus != 1 or s.part != 1
  val completedMeansInBarrier = s.rStatus != 2 or s.part < 6
  val flagIsRound = not(s.flagDone) or s.flagClaim == s.round
  val naiveSound = not(s.naiveAccept) or
    (s.naiveOp == s.elected and s.naiveRound == s.round and s.electedDone)
  val noInfer = s.pairO != 9
  val unelectedEntry = s.rStatus != 2 or s.electedDone
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
