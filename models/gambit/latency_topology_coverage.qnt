module latency_topology_coverage {
  // Two planned groups abstract omission of an entire CPU-derived topology.
  var selected: Set[int]
  var samples: int -> int
  var published: bool
  var headerOnly: bool
  val planned = Set(2, 3)
  action init = all { selected' = planned, samples' = Map(2 -> 0, 3 -> 0),
    published' = false, headerOnly' = false }
  action initHeaderOnly = all { selected' = planned, samples' = Map(2 -> 0, 3 -> 0),
    published' = false, headerOnly' = true }
  action omit = all { not(published), selected == planned, selected' = Set(2),
    samples' = samples, published' = published, headerOnly' = headerOnly }
  action sample = {
    nondet group = planned.oneOf()
    all { not(published), selected.contains(group), samples.get(group) < 2,
      selected' = selected, samples' = samples.set(group, samples.get(group) + 1),
      published' = published, headerOnly' = headerOnly }
  }
  val complete = selected == planned and planned.forall(group => samples.get(group) == 2)
  action publish = all { not(published),
    if (headerOnly) selected.forall(group => samples.get(group) == 2) else complete,
    selected' = selected, samples' = samples, published' = true, headerOnly' = headerOnly }
  action hold = all { selected' = selected, samples' = samples,
    published' = published, headerOnly' = headerOnly }
  action step = any { omit, sample, publish, hold }
  val safe = not(published) or complete
}
