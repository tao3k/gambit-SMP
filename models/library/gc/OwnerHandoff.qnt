// One ticket, two collector workers, one cross-owner transfer. Mutators stop.
module OwnerHandoff {
  import WorkObligations.* from "WorkObligations"
  const Mutation: str
  type State = { local: Set[int], outbound: Set[int], inbound: Set[int],
    scanning: Set[int], active: int -> bool, count: int, completed: bool,
    wrongOwner: bool, done: bool }
  var s: State
  action init = s' = { local: Set(1), outbound: Set(), inbound: Set(),
    scanning: Set(), active: Map(1 -> true, 2 -> false), count: 1,
    completed: false, wrongOwner: false, done: false }
  action discoverRemote = all {
    not(s.done), s.active.get(1), s.local.contains(1),
    s' = { ...s, local: Set(), outbound: Set(1) },
  }
  // Queue publication and waking/accounting for the receiver share one lock.
  action send = all {
    not(s.done), s.active.get(1), s.outbound.contains(1),
    s' = { ...s, outbound: Set(),
      inbound: if (Mutation == "lost-ticket") Set() else Set(1),
      active: if (Mutation == "unaccounted-wake") s.active else s.active.set(2, true),
      count: if (Mutation == "unaccounted-wake" or s.active.get(2))
        s.count else s.count + 1 },
  }
  action acquire = all {
    not(s.done), s.active.get(2), s.inbound.contains(1),
    s' = { ...s, inbound: Set(), scanning: Set(1),
      wrongOwner: Mutation == "wrong-owner" },
  }
  action scan = all {
    not(s.done), s.active.get(2), s.scanning.contains(1),
    s' = { ...s, scanning: Set(), completed: true },
  }
  action idle(w: int): bool = all {
    not(s.done), s.active.get(w),
    (if (w == 1) s.local.size() == 0 and s.outbound.size() == 0
     else s.inbound.size() == 0 and s.scanning.size() == 0)
      or Mutation == "early-idle",
    s' = { ...s, active: s.active.set(w, false), count: s.count - 1 },
  }
  action finish = all {
    not(s.done), s.count == 0, s' = { ...s, done: true },
  }
  action step = any { discoverRemote, send, acquire, scan, idle(1), idle(2), finish }
  val conserved = s.local.size() + s.outbound.size() + s.inbound.size() +
    s.scanning.size() + (if (s.completed) 1 else 0) == 1
  val counted = s.count == activeCount(s.active, Set(1, 2))
  val covered = (s.local.size() + s.outbound.size() > 0 implies s.active.get(1)) and
    (s.inbound.size() + s.scanning.size() > 0 implies s.active.get(2))
  val closureSafe = s.done implies (s.completed and
    noOutstanding(s.local, s.outbound, s.inbound, s.scanning))
  val Safe = conserved and counted and covered and closureSafe and not(s.wrongOwner)
}
