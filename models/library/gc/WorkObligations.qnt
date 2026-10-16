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
}
