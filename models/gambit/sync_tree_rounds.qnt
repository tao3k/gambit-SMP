module sync_tree_rounds {
  // Source protocol characterization, NOT a proposed repair. Fixed population;
  // coherent atomic mailboxes; excludes weak memory, mutexes and VM resizing.
  val workers = Set(0, 1, 2, 3)
  var s: { pc: int -> int, epoch: int -> int,
           up: int -> int, down: int -> int, bad: bool }

  action init = s' = {
    pc: workers.mapBy(_ => 0), epoch: workers.mapBy(_ => 1),
    up: workers.mapBy(_ => 0), down: workers.mapBy(_ => 0), bad: false,
  }

  // pc 0/1 read children in SOURCE ORDER, 2 publish upward, 3 read reply,
  // 4/5 publish replies in source order, 6 return and enter the next round.
  pure def child(w: int, slot: int): int = 2 * w + slot + 1
  def receiveEnabled(w: int, slot: int): bool =
    s.pc.get(w) == slot and
      (if (child(w, slot) >= 4) true else s.up.get(child(w, slot)) != 0)
  action receive(w: int, slot: int): bool = {
    val c = child(w, slot)
    all {
      receiveEnabled(w, slot),
      s' = { ...s, pc: s.pc.set(w, slot + 1),
             up: if (c < 4) s.up.set(c, 0) else s.up,
             bad: s.bad or (if (c < 4) s.up.get(c) != s.epoch.get(w) else false) },
    }
  }
  action publishUp(w: int): bool = all {
    s.pc.get(w) == 2,
    s' = { ...s, pc: s.pc.set(w, if (w == 0) 4 else 3),
           up: if (w == 0) s.up else s.up.set(w, s.epoch.get(w)),
           bad: s.bad or (w != 0 and s.up.get(w) != 0) },
  }
  action receiveDown(w: int): bool = all {
    s.pc.get(w) == 3, s.down.get(w) != 0,
    s' = { ...s, pc: s.pc.set(w, 4), down: s.down.set(w, 0),
           bad: s.bad or s.down.get(w) != s.epoch.get(w) },
  }
  action publishDown(w: int, slot: int): bool = {
    val c = child(w, slot)
    all {
      s.pc.get(w) == slot + 4,
      s' = { ...s, pc: s.pc.set(w, slot + 5),
             down: if (c < 4) s.down.set(c, s.epoch.get(w)) else s.down,
             bad: s.bad or (if (c < 4) s.down.get(c) != 0 else false) },
    }
  }
  action nextRound(w: int): bool = all {
    s.pc.get(w) == 6,
    s' = { ...s, pc: s.pc.set(w, if (s.epoch.get(w) == 2) 7 else 0),
           epoch: s.epoch.set(w, s.epoch.get(w) + 1) },
  }
  val terminal = workers.forall(w => s.pc.get(w) == 7)
  def canAdvance(w: int): bool = or {
    receiveEnabled(w, 0), receiveEnabled(w, 1),
    Set(2, 4, 5, 6).contains(s.pc.get(w)),
    s.pc.get(w) == 3 and s.down.get(w) != 0,
  }
  action step = {
    nondet w = workers.oneOf()
    any { receive(w, 0), receive(w, 1), publishUp(w), receiveDown(w),
          publishDown(w, 0), publishDown(w, 1), nextRound(w),
          all { terminal, s' = s } }
  }
  val safe = not(s.bad) and (terminal or workers.exists(w => canAdvance(w)))
  val channelsDrained = not(terminal) or workers.forall(w =>
    s.up.get(w) == 0 and s.down.get(w) == 0)
}
