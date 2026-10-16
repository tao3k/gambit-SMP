// A stopped-mutator, SC interaction profile, not a product/refinement of the
// stand-alone models. Three owners, one old record, one mask and one young target.
module ResweepCards {
  import ScanCoverage.* from "../library/gc/ScanCoverage"
  const Mutation: str
  type State = { round: int, stage: str, mark: bool, spanning: bool,
    buffered: bool, youngest: int, age: int, maskReady: bool,
    span: Set[int], fields: Set[int], active: Set[int], running: int,
    lost: bool, modeConfused: bool, done: bool }
  var s: State
  val requiredFields = Set(0, 1)
  val spanSegments = Set(0, 1)
  val owners = Set(0, 1, 2)
  action init = {
    nondet mark = Set(false, true).oneOf()
    nondet spanning = Set(false, true).oneOf()
    nondet buffered = Set(false, true).oneOf()
    s' = { round: 0, stage: "mutator", mark: mark, spanning: spanning,
      buffered: buffered, youngest: if (buffered) 3 else 0, age: 0,
      maskReady: false, span: Set(), fields: Set(), active: Set(), running: 0,
      lost: false, modeConfused: false, done: false }
  }
  // Flush remembered writes before the card's first scan. A copy-mode record
  // can share trailing bitmap metadata with an in-place object.
  action begin = all {
    s.stage == "mutator", s.round < 2,
    s' = { ...s, stage: "card", buffered: false,
      youngest: if (s.buffered) 0 else s.youngest,
      active: Set(0), running: 1 }
  }
  action establishSpan = all {
    s.stage == "card", s.span == Set(),
    s' = { ...s, span: if (s.spanning and Mutation != "missing-tail")
        spanSegments else Set(0),
      modeConfused: Mutation == "bitmap-mode" and not(s.mark) and s.spanning }
  }
  // The referencing record is routed to its remote mask owner, not declared
  // fully scanned using the temporary zero-length mask.
  action requestShape = all {
    s.stage == "card", s.span != Set(), s.youngest <= s.round,
    s' = { ...s, stage: "shape-out", active: Set(0), running: 1 }
  }
  action postShape = all {
    s.stage == "shape-out",
    s' = { ...s, stage: if (Mutation == "drop-resweep") "lost" else "shape-in",
      active: Set(1), running: 1, lost: s.lost or Mutation == "drop-resweep" }
  }
  action resolveShape = all {
    s.stage == "shape-in",
    s' = { ...s, stage: "return-out", maskReady: true }
  }
  action returnShape = all {
    s.stage == "return-out",
    s' = { ...s, stage: "resweep", active: Set(0), running: 1 }
  }
  action partialScan = all {
    Mutation == "partial-shape", s.stage == "shape-out",
    s' = { ...s, stage: "promote", fields: Set(0), lost: true }
  }
  action requestTarget = all {
    s.stage == "resweep", s.maskReady,
    s' = { ...s, stage: "target-out" }
  }
  action postTarget = all {
    s.stage == "target-out",
    s' = { ...s, stage: "target-in", active: Set(2), running: 1 }
  }
  action resolveTarget = all {
    s.stage == "target-in",
    s' = { ...s, stage: "scan", active: Set(0), running: 1 }
  }
  action scan = all {
    s.stage == "scan",
    s' = { ...s, stage: "promote", fields: requiredFields,
      lost: s.lost or (s.mark and s.spanning and
        not(completeSpan(spanSegments, s.span))) }
  }
  action promote = all {
    s.stage == "promote",
    s' = { ...s, stage: "finish", age: s.round + 1,
      youngest: if (Mutation == "clear-card") 3 else s.round + 1 }
  }
  action finishRound = all {
    s.stage == "finish", completeShape(s.maskReady, requiredFields, s.fields),
    s' = { ...s, round: s.round + 1, stage: if (s.round == 0) "mutator" else "done",
      span: if (s.round == 0) Set() else s.span,
      maskReady: if (s.round == 0) false else s.maskReady,
      fields: if (s.round == 0) Set() else s.fields,
      active: Set(), running: 0, done: s.round == 1 }
  }
  action prematureFinish = all {
    Mutation == "early-finish", s.stage == "target-out",
    s' = { ...s, done: true, active: Set(), running: 0 }
  }
  action step = any { begin, establishSpan, requestShape, postShape,
    resolveShape, returnShape, partialScan, requestTarget, postTarget,
    resolveTarget, scan, promote, finishRound, prematureFinish }
  val Safe = all {
    not(s.lost), not(s.modeConfused), s.running == s.active.size(),
    s.active.subseteq(owners),
    s.stage == "mutator" implies remembered(s.age, s.youngest, s.buffered),
    Set("promote", "finish", "done").contains(s.stage) implies
      completeShape(s.maskReady, requiredFields, s.fields),
    s.done implies s.stage == "done" and s.round == 2 and s.running == 0
  }
  // A decoded negative trace is a reachability witness, not a safety failure.
  val NeverCompleted = not(s.done and s.mark and s.spanning)
}
