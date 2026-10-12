module gc_work_closure {
  // Paper-guided composition: two workers, graph 1 -> 2 -> 1, two phases.
  // One object stands for a chunk's pending region, not a real block layout.
  // Queue release/acquire and count/wait are atomic abstractions. Mutators stop.
  // Fault controls are not claims that the current Gambit source permits them.
  type State = { fault: int, phase: int, work: int -> int,
    owner: int -> int, copied: int -> int, visible: int -> int,
    scans: int -> int, active: int -> bool, arrived: int -> bool,
    count: int, done: bool, staleRead: bool, badPhase: bool }
  // Work: 0 undiscovered, 1 local root, 2 private copy, 4 queued,
  // 5 scanning, 6 scanned. A forwarding identity may exist in state 2.
  pure def initialState(fault: int): State = {
    fault: fault, phase: 0, work: Map(1 -> 1, 2 -> 0),
    owner: Map(1 -> 1, 2 -> 0), copied: Map(1 -> 0, 2 -> 0),
    visible: Map(1 -> 0, 2 -> 0), scans: Map(1 -> 0, 2 -> 0),
    active: Map(1 -> true, 2 -> true), arrived: Map(1 -> false, 2 -> false),
    count: 2, done: false, staleRead: false, badPhase: false,
  }
  action initOld = s' = initialState(1)
  action initEarlyIdle = s' = initialState(2)
  action initDuplicateClaim = s' = initialState(3)
  action initEarlyPhase = s' = initialState(4)
  action initFixed = s' = initialState(0)
  var s: State

  action claim(o: int, w: int): bool = all {
    not(s.done), s.active.get(w), s.work.get(o) == 1, s.owner.get(o) == w,
    s' = { ...s, work: s.work.set(o, 2) },
  }
  action copyWord(o: int): bool = all {
    not(s.done), s.work.get(o) == 2, s.active.get(s.owner.get(o)),
    s.copied.get(o) < 2,
    s' = { ...s, copied: s.copied.set(o, s.copied.get(o) + 1) },
  }
  action publish(o: int): bool = all {
    not(s.done), s.work.get(o) == 2, s.active.get(s.owner.get(o)),
    s.copied.get(o) == 2 or s.fault == 1,
    s' = { ...s, work: s.work.set(o, 4),
      visible: s.visible.set(o, s.copied.get(o)) },
  }
  action scanLocal(o: int, w: int): bool = all {
    not(s.done), s.active.get(w), s.owner.get(o) == w,
    s.work.get(o) == 2, s.copied.get(o) == 2,
    s' = { ...s, work: s.work.set(o, 5),
      scans: s.scans.set(o, s.scans.get(o) + 1) },
  }
  action acquire(o: int, w: int): bool = all {
    not(s.done), s.active.get(w), s.work.get(o) == 4,
    s' = { ...s, work: s.work.set(o, if (s.fault == 3) 4 else 5),
      owner: s.owner.set(o, w), scans: s.scans.set(o, s.scans.get(o) + 1),
      staleRead: s.staleRead or s.visible.get(o) != 2 },
  }
  action finishScan(o: int): bool = all {
    not(s.done), s.work.get(o) == 5, s.active.get(s.owner.get(o)),
    // Scanning reveals an edge. Already discovered canonical work is retained.
    val target = if (o == 1) 2 else 1
    val fresh = s.work.get(target) == 0
    s' = { ...s,
      work: if (fresh) s.work.set(o, 6).set(target, 1) else s.work.set(o, 6),
      owner: if (fresh) s.owner.set(target, s.owner.get(o)) else s.owner },
  }
  action idle(w: int): bool = all {
    not(s.done), s.active.get(w),
    s.fault == 2 or Set(1, 2).forall(o =>
      s.work.get(o) != 4 and not(s.owner.get(o) == w and
        Set(1, 2, 5).contains(s.work.get(o)))),
    s' = { ...s, active: s.active.set(w, false),
      count: s.count - 1, done: s.count == 1 },
  }
  action wake(w: int): bool = all {
    not(s.done), not(s.active.get(w)), s.count > 0,
    Set(1, 2).exists(o => s.work.get(o) == 4),
    s' = { ...s, active: s.active.set(w, true), count: s.count + 1 },
  }
  action arrive(w: int): bool = all {
    s.done or s.fault == 4, not(s.arrived.get(w)),
    s' = { ...s, arrived: s.arrived.set(w, true) },
  }
  action nextPhase = all {
    s.phase == 0, s.arrived.get(1), s.arrived.get(2),
    s' = { ...initialState(s.fault), phase: 1,
      staleRead: s.staleRead,
      badPhase: s.badPhase or not(s.done) or
        Set(1, 2).exists(o => s.work.get(o) != 6) },
  }
  action finished = all {
    s.phase == 1, s.done, s.arrived.get(1), s.arrived.get(2), s' = s,
  }
  action step = any {
    claim(1, 1), claim(1, 2), claim(2, 1), claim(2, 2),
    copyWord(1), copyWord(2), publish(1), publish(2),
    scanLocal(1, 1), scanLocal(1, 2), scanLocal(2, 1), scanLocal(2, 2),
    acquire(1, 1), acquire(1, 2), acquire(2, 1), acquire(2, 2),
    finishScan(1), finishScan(2), idle(1), idle(2), wake(1), wake(2),
    arrive(1), arrive(2), nextPhase, finished,
  }
  val publicationSafe = not(s.staleRead)
  val terminationSafe = not(s.done) or Set(1, 2).forall(o => s.work.get(o) == 6)
  val ownershipSafe = Set(1, 2).forall(o => s.scans.get(o) <= 1)
  val phaseSafe = not(s.badPhase)
  val counted = s.count == (if (s.active.get(1)) 1 else 0) +
                          (if (s.active.get(2)) 1 else 0)
  val safe = publicationSafe and terminationSafe and ownershipSafe and phaseSafe and counted
}
