module resize_startup_notification_windows {
  // Two members bound this contract; this is not a runtime CPU limit.
  // Stages: propose, waiting, received, reset, NOOP return, outside loop.
  type State = { fixed: bool, late: bool, kind: int,
    rootStage: int, peerStage: int, rootRound: int, peerRound: int,
    electedRound: int, winner: int, rootSlot: int, peerSlot: int,
    rootFirst: bool, peerFirst: bool, rootFlag: bool, peerFlag: bool,
    issued: bool, completed: bool }
  var s: State
  pure def initial(fixed: bool, late: bool, kind: int): State = {
    fixed: fixed, late: late, kind: kind,
    rootStage: 0, peerStage: 0, rootRound: 0, peerRound: 0,
    electedRound: -1, winner: 252, rootSlot: 252, peerSlot: 24,
    rootFirst: false, peerFirst: true, rootFlag: true, peerFlag: true,
    issued: false, completed: false,
  }
  action initOld = s' = initial(false, false, 14)
  action initFixed = {
    nondet late = Set(false, true).oneOf()
    nondet kind = Set(0, 14, 24).oneOf()
    s' = initial(true, late, kind)
  }
  action rootPropose = all {
    s.rootStage == 0, s' = { ...s, rootStage: 1 },
  }
  action peerPropose = all {
    s.peerStage == 0, s' = { ...s, peerStage: 1 },
  }
  // Both owned slots must participate in the same barrier generation.
  action elect = all {
    s.rootStage == 1, s.peerStage == 1,
    s.rootRound == s.peerRound, s.electedRound < s.rootRound,
    s' = { ...s, electedRound: s.rootRound,
      winner: if (s.rootSlot < s.peerSlot) s.rootSlot else s.peerSlot },
  }
  action rootReceive = all {
    s.rootStage == 1, s.electedRound == s.rootRound,
    s' = { ...s, rootStage: 2 },
  }
  action peerReceive = all {
    s.peerStage == 1, s.electedRound == s.peerRound,
    s' = { ...s, peerStage: 2 },
  }
  action rootReset = all {
    s.rootStage == 2,
    s' = { ...s, rootStage: 3,
      rootFlag: if (s.rootFirst or (s.fixed and s.winner == 24)) false else s.rootFlag },
  }
  action peerReset = all {
    s.peerStage == 2,
    s' = { ...s, peerStage: 3,
      peerFlag: if (s.peerFirst or (s.fixed and s.winner == 24)) false else s.peerFlag },
  }
  // A member may submit the next generation before its peer commits this one.
  action rootCommit = all {
    s.rootStage == 3,
    s' = { ...s, rootFirst: false,
      rootSlot: if (s.winner == s.rootSlot) 252 else s.rootSlot,
      rootStage: if (s.winner == 252) 4 else 0,
      rootRound: if (s.winner == 252) s.rootRound else s.rootRound + 1 },
  }
  action peerCommit = all {
    s.peerStage == 3,
    s' = { ...s, peerFirst: false,
      peerSlot: if (s.winner == s.peerSlot) 252 else s.peerSlot,
      peerStage: if (s.winner == 252) 4 else 0,
      peerRound: if (s.winner == 252) s.peerRound else s.peerRound + 1,
      completed: s.completed or (s.issued and s.winner == s.kind) },
  }
  action rootExit = all {
    s.rootStage == 4,
    s' = { ...s, rootStage: 5, rootRound: s.rootRound + 1 },
  }
  action peerExit = all {
    s.peerStage == 4,
    s' = { ...s, peerStage: 5, peerRound: s.peerRound + 1 },
  }
  // The exiting member can call on_all_processors while its peer is still
  // receiving/resetting/committing/returning from the previous NOOP round.
  action laterRequest = all {
    s.late, not(s.issued), s.peerStage == 5,
    s' = { ...s, issued: true, peerSlot: s.kind, peerStage: 0,
      peerFirst: true, rootFlag: true, peerFlag: true },
  }
  action rootPoll = all {
    s.rootStage == 5, s.rootFlag,
    s' = { ...s, rootStage: 0, rootFirst: true },
  }
  val terminal = s.rootStage == 5 and s.peerStage == 5
    and (not(s.late) or s.completed) and not(s.rootFlag) and not(s.peerFlag)
  val noStrandedSync = not(s.rootStage == 1 and s.peerStage == 5)
    or s.peerFlag or (s.late and not(s.issued))
  val slotRetained = not(s.issued and not(s.completed)) or s.peerSlot == s.kind
  val noResetOvertakesRequest = not(s.issued and not(s.completed)
    and s.rootStage == 2) or s.winner != 24 or s.rootRound >= 2
  val safe = noStrandedSync and slotRetained and noResetOvertakesRequest
  action finished = all { terminal, s' = s }
  action step = any { rootPropose, peerPropose, elect, rootReceive,
    peerReceive, rootReset, peerReset, rootCommit, peerCommit,
    rootExit, peerExit, laterRequest, rootPoll, finished }
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
