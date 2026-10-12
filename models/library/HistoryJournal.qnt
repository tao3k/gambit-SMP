// Observation journal and independently published analysis protocol.
// Finite identities are exploration bounds, not production capacity limits.
module HistoryJournal {
  const Mutation: str
  pure val Attempts = Set(1, 2)
  type State = { observed: Set[int], prepared: Set[int], complete: Set[int],
    closed: Set[int], failed: Set[int], published: Set[int],
    baseHead: int -> int, baseRevision: int -> int, observation: int -> int,
    head: int, revision: int, inventory: int, lineage: int, forkParent: int, forkRevision: int,
    retained: bool, sound: bool, casSound: bool }
  var q: State
  action init = q' = {observed: Set(1), prepared: Set(), complete: Set(),
    closed: Set(), failed: Set(), published: Set(),
    baseHead: Map(1 -> 0, 2 -> 0), baseRevision: Map(1 -> 0, 2 -> 0),
    observation: Map(1 -> 1, 2 -> 1), head: 1, revision: 0,
    inventory: 0, lineage: 0, forkParent: -1, forkRevision: -1, retained: true, sound: true, casSound: true}
  action Observe = { nondet o = Attempts.oneOf();
    q' = {...q, observed: q.observed.union(Set(o))} }
  action Prepare = { nondet a = Attempts.oneOf(); nondet o = q.observed.oneOf();
    all {not(q.prepared.contains(a)), not(q.closed.contains(a)),
      q' = {...q, prepared: q.prepared.union(Set(a)),
        baseHead: q.baseHead.set(a, q.head), baseRevision: q.baseRevision.set(a, q.revision),
        observation: q.observation.set(a, o)}} }
  action Complete = { nondet a = q.prepared.oneOf();
    q' = {...q, complete: q.complete.union(Set(a))} }
  action Fail = { nondet a = q.prepared.oneOf();
    q' = {...q, prepared: q.prepared.exclude(Set(a)), complete: q.complete.exclude(Set(a)),
      closed: q.closed.union(Set(a)), failed: q.failed.union(Set(a)),
      observed: if (Mutation == "lost-observation") q.observed.exclude(Set(q.observation.get(a))) else q.observed,
      retained: q.retained and Mutation != "lost-observation",
      head: if (Mutation == "failed-publication") q.observation.get(a) else q.head,
      sound: q.sound and Mutation != "failed-publication"} }
  action Publish = { nondet a = q.prepared.oneOf(); all {
    q.complete.contains(a) or Mutation == "early-publication",
    (q.baseHead.get(a) == q.head and q.baseRevision.get(a) == q.revision) or
      (Mutation == "observation-only" and q.baseHead.get(a) == q.head),
    q' = {...q, head: q.observation.get(a), revision: q.revision + 1,
      prepared: q.prepared.exclude(Set(a)), complete: q.complete.exclude(Set(a)),
      closed: q.closed.union(Set(a)), published: q.published.union(Set(a)),
      sound: q.sound and q.complete.contains(a),
      casSound: q.casSound and q.baseRevision.get(a) == q.revision} } }
  action Conflict = { nondet a = q.prepared.oneOf(); all {
    q.baseRevision.get(a) != q.revision,
    q' = {...q, prepared: q.prepared.exclude(Set(a)), complete: q.complete.exclude(Set(a)),
      closed: q.closed.union(Set(a)), failed: q.failed.union(Set(a))} } }
  action InventoryChange = q' = {...q, inventory: 1 - q.inventory,
    lineage: if (Mutation == "inventory-lineage") 1 - q.inventory else q.lineage}
  action Fork = all {q.forkParent == -1, q' = {...q, forkParent: q.head, forkRevision: q.revision}}
  action Idle = q' = q
  action step = any {Observe, Prepare, Complete, Fail, Publish, Conflict, InventoryChange, Fork, Idle}
  val TypeOK = all {q.observed.subseteq(Attempts), q.prepared.subseteq(Attempts),
    q.complete.subseteq(q.prepared), q.closed.subseteq(Attempts),
    q.failed.subseteq(q.closed), q.published.subseteq(q.closed),
    q.revision >= 0, q.revision <= 2, Attempts.contains(q.head),
    Set(0,1).contains(q.inventory), Set(-1,1,2).contains(q.forkParent),
    Set(-1,0,1,2).contains(q.forkRevision)}
  val Safe = all {TypeOK, q.retained, q.sound, q.casSound, q.lineage == 0,
    q.failed.intersect(q.published) == Set(),
    q.published.forall(a => q.observed.contains(q.observation.get(a)))}
  temporal FailureKeepsHead = (Fail implies (q.head,q.revision).next() == (q.head,q.revision)).orKeep(q).always()
  temporal ForkKeepsParent = (q.forkParent != -1 implies
    (q.forkParent,q.forkRevision).next() == (q.forkParent,q.forkRevision)).orKeep(q).always()
  temporal ClosePending = (weakFair(Complete, Set(q)) and weakFair(Publish, Set(q)) and
    weakFair(Conflict, Set(q)) and weakFair(Fail, Set(q))).implies(
      Attempts.forall(a => always(q.prepared.contains(a) implies eventually(q.closed.contains(a)))))
  temporal Properties = FailureKeepsHead and ForkKeepsParent and ClosePending
}
