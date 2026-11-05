module owner_defined_certificate {
  // Resolved owner contract. Payload words are relaxed atomics between
  // release fences; the reader installs them only after two acquire fences
  // and a matching even seq. CURRENT is the snapshot taken at that call
  // (rT == rSeen and obsP == 2). It is not required to stay live.
  // The report always carries the interrupt-site coverage bound.
  // An uninstrumented acquire does not write the certificate.
  // Status: 1 ABSENT, 2 CURRENT, 3 HISTORICAL, 4 CONFLICT.
  type State = {
    next: int, current: int, t1: int, t2: int, p1: int, p2: int,
    cert1: bool, cert2: bool, bare1: bool, bare2: bool,
    seq: int, odd: bool, wRel: bool, wRel2: bool,
    hold: int, ticket: int, wroteH: bool, wroteT: bool,
    done1: bool, done2: bool,
    rStage: int, rSeq: int, rH: int, rT: int, rSeen: int, obsP: int,
    rClass: int, rBound: int,
    naiveDone: bool, naiveH: int, naiveT: int, naiveAccept: bool,
    promote: bool
  }
  var s: State
  pure def initial(mode: int): State = {
    next: 0, current: 0, t1: -1, t2: -1, p1: 0, p2: 0,
    cert1: false, cert2: false, bare1: false, bare2: false,
    seq: 0, odd: false, wRel: false, wRel2: false,
    hold: -1, ticket: -1, wroteH: false, wroteT: false,
    done1: false, done2: false,
    rStage: 0, rSeq: -1, rH: -1, rT: -1, rSeen: -1, obsP: -1,
    rClass: 0, rBound: 0,
    naiveDone: false, naiveH: -1, naiveT: -1, naiveAccept: false,
    promote: mode == 1
  }
  action initProtocol = s' = initial(0)
  action initPromote = s' = initial(1)
  action reserve1 = all {
    s.p1 == 0, s' = { ...s, p1: 1, t1: s.next, next: s.next + 1 },
  }
  action reserve2 = all {
    s.p2 == 0, s' = { ...s, p2: 1, t2: s.next, next: s.next + 1 },
  }
  action acquireCert1 = all {
    s.p1 == 1, s.current == s.t1,
    s' = { ...s, p1: 2, cert1: true },
  }
  action acquireCert2 = all {
    s.p2 == 1, s.current == s.t2,
    s' = { ...s, p2: 2, cert2: true },
  }
  action acquireBare1 = all {
    s.p1 == 1, s.current == s.t1,
    s' = { ...s, p1: 2, bare1: true },
  }
  action acquireBare2 = all {
    s.p2 == 1, s.current == s.t2,
    s' = { ...s, p2: 2, bare2: true },
  }
  action begin1 = all {
    s.cert1, s.p1 == 2, not(s.odd), not(s.done1),
    s' = { ...s, odd: true, seq: s.seq + 1, wRel: false, wRel2: false,
      wroteH: false, wroteT: false },
  }
  action begin2 = all {
    s.cert2, s.p2 == 2, not(s.odd), not(s.done2),
    s' = { ...s, odd: true, seq: s.seq + 1, wRel: false, wRel2: false,
      wroteH: false, wroteT: false },
  }
  action releaseWrite = all {
    s.odd, not(s.wRel), s' = { ...s, wRel: true },
  }
  action writeH1 = all {
    s.odd, s.wRel, s.cert1, s.p1 == 2, not(s.wroteH),
    s' = { ...s, wroteH: true, hold: 1 },
  }
  action writeT1 = all {
    s.odd, s.wRel, s.cert1, s.p1 == 2, not(s.wroteT),
    s' = { ...s, wroteT: true, ticket: s.t1 },
  }
  action writeH2 = all {
    s.odd, s.wRel, s.cert2, s.p2 == 2, not(s.wroteH),
    s' = { ...s, wroteH: true, hold: 2 },
  }
  action writeT2 = all {
    s.odd, s.wRel, s.cert2, s.p2 == 2, not(s.wroteT),
    s' = { ...s, wroteT: true, ticket: s.t2 },
  }
  action releaseEven = all {
    s.odd, s.wRel, s.wroteH, s.wroteT, not(s.wRel2),
    s' = { ...s, wRel2: true },
  }
  action end1 = all {
    s.odd, s.wRel2, s.cert1, s.p1 == 2, s.hold == 1, s.ticket == s.t1,
    s' = { ...s, odd: false, seq: s.seq + 1, done1: true },
  }
  action end2 = all {
    s.odd, s.wRel2, s.cert2, s.p2 == 2, s.hold == 2, s.ticket == s.t2,
    s' = { ...s, odd: false, seq: s.seq + 1, done2: true },
  }
  action unlock1 = all {
    s.p1 == 2, not(s.odd), s.bare1 or s.done1,
    s' = { ...s, p1: 3, current: s.current + 1 },
  }
  action unlock2 = all {
    s.p2 == 2, not(s.odd), s.bare2 or s.done2,
    s' = { ...s, p2: 3, current: s.current + 1 },
  }
  action loadSeq = all {
    s.rStage == 0,
    s' = if (s.odd) { ...s, rStage: 5, rClass: 4, rBound: 1 }
      else { ...s, rStage: 1, rSeq: s.seq, rBound: 1 },
  }
  action acquirePayload = all {
    s.rStage == 1, s' = { ...s, rStage: 2 },
  }
  action loadPayload = all {
    s.rStage == 2, s' = { ...s, rStage: 3, rH: s.hold, rT: s.ticket },
  }
  action acquireSeq = all {
    s.rStage == 3, s' = { ...s, rStage: 4 },
  }
  action classify = all {
    s.rStage == 4,
    s' = if (s.odd or s.seq != s.rSeq) { ...s, rStage: 5, rClass: 4 }
      else if (s.rH < 0) { ...s, rStage: 5, rClass: 1, rSeen: s.current }
      else if (s.rT == s.current)
        { ...s, rStage: 5, rClass: 2, rSeen: s.current,
          obsP: if (s.rH == 1) s.p1 else s.p2 }
      else { ...s, rStage: 5, rClass: 3, rSeen: s.current,
        obsP: if (s.rH == 1) s.p1 else s.p2 },
  }
  action naiveRead = all {
    not(s.naiveDone), s.odd, s.wRel,
    s' = { ...s, naiveDone: true, naiveAccept: true, naiveH: s.hold, naiveT: s.ticket },
  }
  action promoteHistorical = all {
    s.promote, s.rClass == 3, s' = { ...s, rClass: 2 },
  }
  val terminal = s.p1 == 3 and s.p2 == 3 and s.rStage == 5 and not(s.promote)
  action finished = all { terminal, s' = s }
  action step = any {
    reserve1, reserve2, acquireCert1, acquireCert2, acquireBare1, acquireBare2,
    begin1, begin2, releaseWrite, writeH1, writeT1, writeH2, writeT2,
    releaseEven, end1, end2, unlock1, unlock2,
    loadSeq, acquirePayload, loadPayload, acquireSeq, classify,
    naiveRead, promoteHistorical, finished
  }
  val acquired1 = s.p1 >= 2 and s.cert1 and s.t1 == s.rT and s.rH == 1
  val acquired2 = s.p2 >= 2 and s.cert2 and s.t2 == s.rT and s.rH == 2
  val liveOwner =
    s.odd or s.hold < 0 or s.ticket != s.current or
    ((s.hold == 1 and s.p1 == 2 and s.t1 == s.current) or
     (s.hold == 2 and s.p2 == 2 and s.t2 == s.current))
  val ownerImpl =
    not(s.p1 == 2 and s.p2 == 2) and
    liveOwner and
    (s.rStage == 0 or s.rBound == 1) and
    (s.rClass != 2 or (s.rT == s.rSeen and s.obsP == 2 and (acquired1 or acquired2))) and
    (s.rClass != 3 or acquired1 or acquired2)
  val naiveSound = not(s.naiveAccept) or
    ((s.naiveH == 1 and s.t1 == s.naiveT) or (s.naiveH == 2 and s.t2 == s.naiveT))
  val stickyLive = s.rClass != 2 or
    ((s.rH == 1 and s.p1 == 2 and s.rT == s.current) or
     (s.rH == 2 and s.p2 == 2 and s.rT == s.current))
  val missMeansFree = (s.rClass != 1 and s.rClass != 3) or
    not(s.p1 == 2 or s.p2 == 2)
  val promotedIsCurrent = not(s.promote) or s.rClass != 2 or s.rT == s.rSeen
  temporal completion = weakFair(step, Set(s)).implies(eventually(terminal))
}
