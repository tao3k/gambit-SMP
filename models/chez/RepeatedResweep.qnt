// Finite stopped-mutator profile; repeated dependencies are an abstraction of
// remote masks/targets, not an assertion that Chez uses this exact field layout.
module RepeatedResweep {
  import ScanCoverage.* from "../library/gc/ScanCoverage"
  const Mutation: str
  val shapes = Set("scalar", "pair", "vector", "mixed-record", "closure", "wide-frame")
  pure def strongFields(shape: str): Set[int] =
    if (shape == "scalar") Set()
    else if (shape == "pair") Set(0, 1)
    else if (shape == "vector") Set(0, 1, 2, 3)
    else if (shape == "wide-frame") Set(1, 3)
    else Set(0, 2)
  pure def dependencies(shape: str): int =
    if (shape == "scalar" or shape == "pair" or shape == "vector") 0
    else if (shape == "wide-frame") 4 else 2
  pure def nextOwner(resolved: int): int = if (resolved % 2 == 0) 1 else 2
  type State = { shape: str, round: int, stage: str, resolved: int,
    preserved: int, visits: int, holder: int, scanned: Set[int],
    age: int, youngest: int, done: bool }
  var s: State
  action init = {
    nondet shape = shapes.oneOf()
    s' = { shape: shape, round: 0, stage: "scan", resolved: 0,
      preserved: 0, visits: 0, holder: 0, scanned: Set(),
      age: 0, youngest: 0, done: false }
  }
  action defer = all {
    s.stage == "scan", s.resolved < dependencies(s.shape),
    s' = { ...s, stage: "outbound", preserved: s.resolved }
  }
  action post = all {
    s.stage == "outbound",
    s' = { ...s, stage: "inbound", holder: nextOwner(s.resolved) }
  }
  action resolve = all {
    s.stage == "inbound", s.holder == nextOwner(s.resolved),
    s' = { ...s, stage: "return", resolved: s.resolved + 1,
      visits: s.visits + 1 }
  }
  action requeue = all {
    s.stage == "return",
    s' = { ...s, stage: if (Mutation == "drop-second" and s.visits == 2)
        "complete" else "scan", holder: 0,
      resolved: if (Mutation == "forget-prefix" and s.visits == 2)
        0 else s.resolved }
  }
  action scan = all {
    s.stage == "scan", s.resolved == dependencies(s.shape)
      or (Mutation == "worker-bound" and s.visits >= 3)
      or Mutation == "zero-mask-complete",
    s' = { ...s, stage: "complete",
      scanned: if (Mutation == "skip-field") strongFields(s.shape).exclude(Set(3))
        else strongFields(s.shape) }
  }
  action promote = all {
    s.stage == "complete",
    s' = { ...s, stage: if (s.round == 0) "scan" else "done",
      round: s.round + 1, age: s.round + 1, youngest: s.round + 1,
      resolved: if (s.round == 0) 0 else s.resolved,
      preserved: if (s.round == 0) 0 else s.preserved,
      visits: if (s.round == 0) 0 else s.visits,
      scanned: if (s.round == 0) Set() else s.scanned, done: s.round == 1 }
  }
  action step = any { defer, post, resolve, requeue, scan, promote }
  val Safe = all {
    s.resolved >= s.preserved,
    s.stage == "inbound" implies s.holder == nextOwner(s.resolved),
    Set("complete", "done").contains(s.stage) implies
      completeShape(s.resolved == dependencies(s.shape), strongFields(s.shape), s.scanned),
    remembered(s.age, s.youngest, false),
    s.done implies s.stage == "done" and s.round == 2
  }
  // Four remote visits exceed the three modeled owners in each completed round.
  val NoRepeatedCompletion = not(s.done and s.shape == "wide-frame" and s.visits == 4)
}
