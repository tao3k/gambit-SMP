// Two mutable fields in one generation-2 card, target generations 0 and 1.
// Two stopped-mutator collections, first cg=0 then cg=1. No weak fields.
module GenerationCards {
  const Buffered: bool
  const Mutation: str
  type State = { phase: int, round: int, writes: int, slots: int -> int,
    generations: int -> int, youngest: int, buffered: Set[int],
    scanned: Set[int], lost: bool }
  var s: State
  action init = s' = { phase: 0, round: 0, writes: 0,
    slots: Map(1 -> 2, 2 -> 2), generations: Map(0 -> 0, 1 -> 1),
    youngest: 3, buffered: Set(), scanned: Set(), lost: false }
  pure def targetGeneration(st: State, target: int): int =
    if (target == 2) 2 else st.generations.get(target)
  // 2 denotes an immediate value: it creates no younger-generation edge.
  action write(slot: int, target: int): bool = all {
    s.phase == 0, s.writes < 2,
    s' = { ...s, slots: s.slots.set(slot, target), writes: s.writes + 1,
      buffered: if (Buffered and target != 2 and Mutation != "omit-barrier")
        s.buffered.union(Set(slot)) else s.buffered,
      // S_dirty_set may conservatively mark youngest=0, not the exact age.
      youngest: if (not(Buffered) and target != 2 and Mutation != "omit-barrier")
        0 else s.youngest },
  }
  action begin = all {
    s.phase == 0,
    s' = { ...s, phase: 1, scanned: Set(), buffered: Set(),
      youngest: if (s.buffered.size() > 0 and Mutation != "drop-buffer")
        0 else s.youngest },
  }
  action sweep = all {
    s.phase == 1,
    s' = { ...s, phase: 2, scanned:
      if (s.youngest <= s.round)
        Set(1, 2).filter(slot => s.slots.get(slot) != 2 and
          targetGeneration(s, s.slots.get(slot)) <= s.round and
          (Mutation != "skip-field" or slot == 1))
          .map(slot => s.slots.get(slot))
      else Set() },
  }
  action finish = all {
    s.phase == 2,
    val live = Set(0, 1).filter(o => Set(1, 2).exists(slot => s.slots.get(slot) == o))
    val nextGenerations = Set(0, 1).mapBy(o =>
      if (s.scanned.contains(o)) s.round + 1 else s.generations.get(o))
    val nextYoungest = live.fold(3, (g, o) => {
      val age = nextGenerations.get(o)
      if (age < g) age else g
    })
    s' = { ...s, phase: if (s.round == 0) 0 else 3, round: s.round + 1,
      writes: 0, generations: nextGenerations,
      youngest: if (Mutation == "clear-retained") 3 else nextYoungest,
      lost: s.lost or live.exists(o =>
        s.generations.get(o) <= s.round and not(s.scanned.contains(o))) },
  }
  action step = any { write(1, 0), write(1, 1), write(1, 2),
    write(2, 0), write(2, 1), write(2, 2), begin, sweep, finish }
  val boundaryCovered = s.phase == 0 implies Set(1, 2).forall(slot =>
    targetGeneration(s, s.slots.get(slot)) >= 2 or
    s.youngest <= targetGeneration(s, s.slots.get(slot)) or s.buffered.contains(slot))
  val Safe = not(s.lost) and boundaryCovered
}
