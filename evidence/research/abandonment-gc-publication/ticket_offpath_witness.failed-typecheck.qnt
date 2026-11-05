module ticket_offpath_witness {
  // Finite characterization of an off-path serving-ticket witness.
  // The candidate ___TICKETLOCK_LOCK2 local is not in scope after the macro.
  // A residual stack slot is an assumption of the accepting initializer only.
  // barrierStage 2 means sync_op0 was published; it is not a memory handshake.
  // No action writes next/current. This does not preserve a native fault.
  type State = {
    next: int, current: int, waiterTicket: int, waiterSpinning: bool,
    holder: int, spill1: int, spill2: int, live1: bool, live2: bool,
    generation: int, readGeneration: int,
    servingAtStart: int, servingAtEnd: int, intervalClosed: bool,
    sequenceOdd: bool, barrierStage: int, entryOp: int, publishedOp: int,
    acceptedOwner: int, acceptedOp: int, witnessWritesTicket: bool
  }
  pure def initial(spill1: int, spill2: int, readGeneration: int,
                   servingAtEnd: int, intervalClosed: bool, sequenceOdd: bool,
                   barrierStage: int, publishedOp: int,
                   acceptedOwner: int, acceptedOp: int,
                   witnessWritesTicket: bool): State = {
    next: 2, current: 1, waiterTicket: 2, waiterSpinning: true,
    holder: 1, spill1: spill1, spill2: spill2, live1: true, live2: true,
    generation: 1, readGeneration: readGeneration,
    servingAtStart: 1, servingAtEnd: servingAtEnd,
    intervalClosed: intervalClosed, sequenceOdd: sequenceOdd,
    barrierStage: barrierStage, entryOp: 1, publishedOp: publishedOp,
    acceptedOwner: acceptedOwner, acceptedOp: acceptedOp,
    witnessWritesTicket: witnessWritesTicket
  }
  action initOffPath = s' = initial(1, -1, 1, 1, true, false, 2, 2, 0, 0, false)
  action initRegisterOnly = s' = initial(-1, -1, 1, 1, true, false, 2, 2, 1, 2, false)
  action initAmbiguous = s' = initial(1, 1, 1, 1, true, false, 2, 2, 1, 2, false)
  action initStaleGeneration = s' = initial(1, -1, 0, 1, true, false, 2, 2, 1, 2, false)
  action initServingAdvanced = s' = initial(1, -1, 1, 2, false, false, 2, 2, 1, 2, false)
  action initTornSequence = s' = initial(1, -1, 1, 1, true, true, 2, 2, 1, 2, false)
  action initProposalOnly = s' = initial(1, -1, 1, 1, true, false, 1, 1, 1, 1, false)
  action initHotPath = s' = initial(1, -1, 1, 1, true, false, 2, 2, 1, 2, true)
  action spin = all {
    s.waiterSpinning, s.current != s.waiterTicket, not(s.witnessWritesTicket),
    s' = s,
  }
  action readWitness = all {
    not(s.witnessWritesTicket), s.acceptedOwner == 0,
    val match1 = s.live1 and s.spill1 == s.current and s.spill1 >= 0
    val match2 = s.live2 and s.spill2 == s.current and s.spill2 >= 0
    val unique = (match1 and not(match2) and s.holder == 1) or
      (match2 and not(match1) and s.holder == 2)
    val fresh = s.intervalClosed and s.servingAtStart == s.current and
      s.servingAtEnd == s.current and s.readGeneration == s.generation and
      not(s.sequenceOdd)
    s' = { ...s,
      acceptedOwner: if (unique and fresh) s.holder else 0,
      acceptedOp: if (fresh and s.barrierStage == 2 and s.publishedOp > 0)
        s.publishedOp else 0 },
  }
  val terminal = s.acceptedOwner != 0 and s.acceptedOp != 0 and s.waiterSpinning
  action finished = all { terminal, s' = s }
  action step = any { spin, readWitness, finished }
  val failureShape = s.waiterSpinning and s.current != s.waiterTicket and
    s.next == 2 and s.current == 1
  val ownerOk = s.acceptedOwner == 0 or (
    s.acceptedOwner == s.holder and s.intervalClosed and
    s.servingAtStart == s.current and s.servingAtEnd == s.current and
    s.readGeneration == s.generation and not(s.sequenceOdd) and
    ((s.acceptedOwner == 1 and s.live1 and s.spill1 == s.current and
        not(s.live2 and s.spill2 == s.current)) or
     (s.acceptedOwner == 2 and s.live2 and s.spill2 == s.current and
        not(s.live1 and s.spill1 == s.current))))
  val barrierOk = s.acceptedOp == 0 or (
    s.barrierStage == 2 and s.acceptedOp == s.publishedOp and
    s.publishedOp > 0 and s.intervalClosed and not(s.sequenceOdd))
  val noHotPath = not(s.witnessWritesTicket)
  val safe = ownerOk and barrierOk and noHotPath and failureShape
  val ownerSafe = ownerOk and failureShape
  val barrierSafe = barrierOk and failureShape
  val effectSafe = noHotPath and failureShape
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
