// Pure contracts; no object layout, locking scheme or at-most-once scanning.
module WorkObligations {
  pure def canonicalReferences(refs: int -> int, slots: Set[int],
      unset: int, canonical: int): bool = slots.forall(r =>
        refs.get(r) == unset or refs.get(r) == canonical)
  pure def activeCount(active: int -> bool, workers: Set[int]): int =
    workers.filter(w => active.get(w)).size()
  pure def allWorkComplete(work: int -> int, objects: Set[int],
      complete: int): bool = objects.forall(o => work.get(o) == complete)
  pure def noOutstanding(privateWork: Set[int], outbound: Set[int],
      inbound: Set[int], scanning: Set[int]): bool =
    privateWork.size() + outbound.size() + inbound.size() + scanning.size() == 0
  // Ownership covers published work as well as private work. A different
  // worker's nonempty queue does not prevent this worker becoming idle.
  pure def localDrained(work: int -> int, owner: int -> int,
      objects: Set[int], unfinished: Set[int], worker: int): bool =
    objects.forall(o => not(owner.get(o) == worker and unfinished.contains(work.get(o))))
  pure def producersCovered(work: int -> int, owner: int -> int,
      active: int -> bool, objects: Set[int], unfinished: Set[int]): bool =
    objects.forall(o => if (unfinished.contains(work.get(o))) active.get(owner.get(o)) else true)
}
