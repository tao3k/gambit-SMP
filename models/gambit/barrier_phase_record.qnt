module barrier_phase_record {
  // Implementation check for the barrier half of the consumer contract.
  // The winner kind is elected before publication. The round comes from the
  // VM counter at election, not from the recurring flag. The record is a
  // seqlock of (round, op, phase=COMPLETED_PAST). ABSENT is seq 0, including
  // while the participant is blocked before election. The report copies an
  // independent HISTORICAL owner status beside the barrier status. Inferring
  // one cycle, publishing the entry proposal, and treating the flag as the
  // round are rejected readers. Seq does not wrap.
  // Barrier status: 0 undecided, 1 ABSENT, 2 COMPLETED_PAST, 4 CONFLICT.
  // Owner view 3 is HISTORICAL. Pair value 9 is the rejected SAME_CYCLE code.
  type State = {
    part: int, entryOp: int, elected: int, round: int, flag: int, flagBack: bool,
    seq: int, odd: bool, op: int, recRound: int, tag: int,
    wroteOp: bool, wroteRound: bool, wroteTag: bool,
    rStage: int, rSeq: int, rOp: int, rRound: int, rTag: int, rStatus: int,
    naiveDone: bool, naiveOp: int, naiveRound: int, naiveAccept: bool,
    flagDone: bool, flagClaim: int,
    ownerView: int, reported: bool, pairO: int, pairB: int,
    mislabel: bool, infer: bool
  }
  var s: State
  pure def start(mode: int): State = {
    part: 0, entryOp: 7, elected: 0, round: 0, flag: 1, flagBack: false,
    seq: 0, odd: false, op: 0, recRound: 0, tag: 0,
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
  action block = all {
    s.part == 0, not(s.mislabel), s' = { ...s, part: 1 },
  }
  action elect = all {
    s.part == 1, not(s.mislabel),
    s' = { ...s, part: 2, elected: 3, round: 1 },
  }
  action copy = all {
    s.part == 2, s' = { ...s, part: 3 },
  }
  action begin = all {
    s.part == 3, not(s.odd),
    s' = { ...s, part: 4, odd: true, seq: s.seq + 1 },
  }
  action writeOp = all {
    s.part == 4, s.odd, not(s.wroteOp),
    s' = { ...s, wroteOp: true, op: s.elected },
  }
  action writeRound = all {
    s.part == 4, s.odd, not(s.wroteRound),
    s' = { ...s, wroteRound: true, recRound: s.round },
  }
  action writeTag = all {
    s.part == 4, s.odd, not(s.wroteTag),
    s' = { ...s, wroteTag: true, tag: 1 },
  }
  action endPub = all {
    s.part == 4, s.wroteOp, s.wroteRound, s.wroteTag,
    s.op == s.elected, s.recRound == s.round, s.tag == 1,
    s' = { ...s, part: 5, odd: false, seq: s.seq + 1 },
  }
  action finish = all {
    s.part == 5, s' = { ...s, part: 6 },
  }
  action mispublish = all {
    s.mislabel, s.part == 0, not(s.odd),
    s' = { ...s, part: 5, seq: 2, op: s.entryOp, recRound: 0, tag: 1 },
  }
  action readSeq1 = all {
    s.rStage == 0,
    s' = if (s.odd) { ...s, rStage: 3, rStatus: 4 }
      else if (s.seq == 0) { ...s, rStage: 3, rStatus: 1 }
      else { ...s, rStage: 1, rSeq: s.seq },
  }
  action readFields = all {
    s.rStage == 1,
    s' = { ...s, rStage: 2, rOp: s.op, rRound: s.recRound, rTag: s.tag },
  }
  action readSeq2 = all {
    s.rStage == 2,
    s' = if (s.odd or s.seq != s.rSeq) { ...s, rStage: 3, rStatus: 4 }
      else if (s.rTag == 1) { ...s, rStage: 3, rStatus: 2 }
      else { ...s, rStage: 3, rStatus: 1 },
  }
  action naiveRead = all {
    not(s.naiveDone), s.odd,
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
    not(s.reported), s.rStage == 3, not(s.infer),
    s' = { ...s, reported: true, pairO: s.ownerView, pairB: s.rStatus },
  }
  action inferCycle = all {
    s.infer, not(s.reported), s.rStatus == 2, s.ownerView == 3,
    s' = { ...s, reported: true, pairO: 9, pairB: 9 },
  }
  val terminal = s.part == 6 and s.rStage == 3 and s.reported
  action finished = all { terminal, s' = s }
  action step = any {
    block, elect, copy, begin, writeOp, writeRound, writeTag, endPub, finish,
    mispublish, readSeq1, readFields, readSeq2, naiveRead,
    flagSample, flagReset, flagReuse, assemble, inferCycle, finished
  }
  val barrierImpl =
    s.rStatus != 5 and s.pairO != 9 and s.pairB != 9 and
    (s.rStatus != 2 or
      (s.rOp == s.elected and s.rOp != s.entryOp and s.rRound == s.round and s.rTag == 1)) and
    (not(s.reported) or (s.pairO == s.ownerView and s.pairB == s.rStatus))
  val absentIsIdle = s.rStatus != 1 or s.part != 1
  val completedMeansInBarrier = s.rStatus != 2 or s.part < 6
  val flagIsRound = not(s.flagDone) or s.flagClaim == s.round
  val naiveSound = not(s.naiveAccept) or
    (s.naiveOp == s.elected and s.naiveRound == s.round and s.elected != 0)
  val noInfer = s.pairO != 9
  val winnerOnMislabel = s.rStatus != 2 or (s.rOp == s.elected and s.rOp != s.entryOp)
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
