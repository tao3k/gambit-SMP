// Three tickets, two senders, two target contexts on one receiver worker.
// Each publication/wake is a locked transition, not a C instruction model.
module RemoteWorkAccounting {
  import WorkObligations.* from "WorkObligations"
  const Mutation: str
  val workers = Set(1, 2, 3)
  val tickets = Set(1, 2, 3)
  val sender = Map(1 -> 1, 2 -> 3, 3 -> 1)
  val targetContext = Map(1 -> 20, 2 -> 21, 3 -> 20)
  val contextOwner = Map(20 -> 2, 21 -> 2)
  type State = { phase: int -> str, holder: int -> int,
    active: int -> bool, running: int, mutex: int, done: bool }
  var s: State
  action init = s' = { phase: Map(1 -> "local", 2 -> "local", 3 -> "local"),
    holder: sender, active: Map(1 -> true, 2 -> false, 3 -> true),
    running: 2, mutex: 0, done: false }
  def workAt(w: int): Set[int] = tickets.filter(t =>
    s.holder.get(t) == w and s.phase.get(t) != "complete")
  def phaseIs(p: str): Set[int] = tickets.filter(t => s.phase.get(t) == p)
  action lock(w: int): bool = all {
    not(s.done), s.mutex == 0, s' = { ...s, mutex: w },
  }
  action unlock(w: int): bool = all {
    not(s.done), s.mutex == w, s' = { ...s, mutex: 0 },
  }
  action discover(t: int): bool = all {
    not(s.done), s.active.get(sender.get(t)), s.phase.get(t) == "local",
    s' = { ...s, phase: s.phase.set(t, "outbound") },
  }
  action post(t: int): bool = all {
    not(s.done), s.mutex == sender.get(t),
    s.active.get(sender.get(t)), s.phase.get(t) == "outbound",
    val receiver = contextOwner.get(targetContext.get(t))
    val wake = not(s.active.get(receiver))
    s' = { ...s, phase: s.phase.set(t,
        if (Mutation == "lost-ticket") "lost" else "inbound"),
      holder: s.holder.set(t, receiver),
      active: if (Mutation == "missing-wake") s.active else s.active.set(receiver, true),
      running: if (Mutation == "missing-wake") s.running
        else if (wake or Mutation == "double-count") s.running + 1 else s.running },
  }
  action receive(t: int): bool = all {
    not(s.done), s.mutex == s.holder.get(t), s.active.get(s.holder.get(t)),
    s.phase.get(t) == "inbound",
    s' = { ...s, phase: s.phase.set(t, "scanning") },
  }
  action scan(t: int): bool = all {
    not(s.done), s.active.get(s.holder.get(t)), s.phase.get(t) == "scanning",
    s' = { ...s, phase: s.phase.set(t, "complete") },
  }
  // Chez's locked decrement/recheck is collapsed to a stable accounting state.
  action park(w: int): bool = all {
    not(s.done), s.mutex == w, s.active.get(w),
    workAt(w).size() == 0 or (Mutation == "unflushed-idle" and
      workAt(w).forall(t => s.phase.get(t) == "outbound")),
    s' = { ...s, active: s.active.set(w, false), running: s.running - 1 },
  }
  // Deliberately inspect only this worker's inbox, as in the source protocol.
  action finish(w: int): bool = all {
    not(s.done), s.mutex == w, s.running == 0,
    workAt(w).filter(t => s.phase.get(t) == "inbound").size() == 0,
    s' = { ...s, done: true },
  }
  action step = any {
    nondet w = workers.oneOf()
    any { lock(w), unlock(w), park(w), finish(w) },
    nondet t = tickets.oneOf()
    any { discover(t), post(t), receive(t), scan(t) },
  }
  val conserved = tickets.forall(t => Set("local", "outbound", "inbound",
    "scanning", "complete").contains(s.phase.get(t)))
  val counted = s.running == activeCount(s.active, workers)
  val covered = workers.forall(w => workAt(w).size() > 0 implies s.active.get(w))
  val routed = tickets.forall(t =>
    (s.phase.get(t) == "inbound" or s.phase.get(t) == "scanning") implies
      s.holder.get(t) == contextOwner.get(targetContext.get(t)))
  val closure = s.done implies (phaseIs("complete") == tickets and
    noOutstanding(phaseIs("local"), phaseIs("outbound"),
      phaseIs("inbound"), phaseIs("scanning")))
  val Safe = conserved and counted and covered and routed and closure
}
