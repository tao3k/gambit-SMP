module continuation_origin_handoff_composition {
  import continuation_saved_stack_origin_isolated as O from "./continuation_saved_stack_origin_isolated"
  import continuation_export_origin_isolated as Q from "./continuation_export_origin_isolated"
  import continuation_link_handoff as H from "./continuation_link_handoff"

  // Retained saved-stack slice and section rollover remain source-refinement
  // premises. Actor/word domains are finite model bounds, not host CPU limits.
  action geometryInit = {
    nondet local = Set(false, true).oneOf()
    nondet start = 1.to(3).oneOf()
    nondet words = 1.to(3).oneOf()
    nondet offset = 0.to(words).oneOf()
    Q::geometryState' = { entry: "roots", phase: "roots", localScan: local,
      start: start, end: start + words,
      cursor: if (local) start + offset else start - 1,
      stage: "copied", queued: false, consumed: false, producerDone: false,
      consumedPhase: "none", readPending: false }
  }
  action geometryOld = {
    nondet local = Set(false, true).oneOf()
    nondet start = 1.to(3).oneOf()
    nondet words = 1.to(3).oneOf()
    nondet offset = 0.to(words).oneOf()
    Q::geometryState' = { entry: "roots", phase: "roots", localScan: local,
      start: start, end: start + words,
      cursor: if (local) start + offset else start - 1,
      stage: "copied", queued: false, consumed: false, producerDone: false,
      consumedPhase: "none", readPending: false }
  }
  action initOld = all { O::initOld, geometryOld, H::initOld }
  action init = all { O::init, geometryInit, H::initFixed }

  action originStep = all {
    O::originState.phase < 5, O::step, Q::geometryState' = Q::geometryState, H::s' = H::s }
  // The root barrier does not scan another thread's retained saved field.
  // Only this derived stack input enables the subsequent frame-copy slice.
  action traversal = all {
    O::scanSavedContinuation, O::originState.raw.contains(O::originState.savedPrevious),
    Q::geometryState' = { ...Q::geometryState, entry: "traversal", phase: "traversal" }, H::s' = H::s }
  action rollover = all {
    O::terminal, Q::endSection, O::originState' = O::originState, H::s' = H::s }
  action completeLink = all {
    O::terminal, Q::nextFrame, H::completeLink, O::originState' = O::originState }
  // In the proposed protocol the exported work stays producer-owned until
  // final link completion. No scanner lock or unbounded storage is prescribed.
  action publish = all {
    O::terminal, Q::geometryState.queued, H::publish, O::originState' = O::originState, Q::geometryState' = Q::geometryState }
  action readLink = all {
    O::terminal, H::readLink, Q::consume, O::originState' = O::originState }
  action maskLink = all {
    H::maskLink, O::originState' = O::originState, Q::geometryState' = Q::geometryState }
  action restoreLink = all {
    H::restoreLink, O::originState' = O::originState, Q::geometryState' = Q::geometryState }
  val terminal = O::terminal and Q::geometryState.producerDone and
    (if (Q::geometryState.localScan) not(Q::geometryState.consumed) else H::s.consumer == 3)
  action finished = all {
    terminal, O::originState' = O::originState, Q::geometryState' = Q::geometryState, H::s' = H::s }
  action step = any { originStep, traversal, rollover, completeLink, publish,
    readLink, maskLink, restoreLink, finished }

  val readySafe = H::readySafe
  val updateSafe = H::updateSafe
  val causal = (H::s.published or Q::geometryState.consumed).implies(
    O::terminal and O::originState.scanInput == "stack" and not(Q::geometryState.localScan))
  val safe = O::guardSound and Q::guardSound and causal and H::safe and
    (Q::geometryState.producerDone == H::s.producerDone)
  val noStall = terminal or enabled(step)
  val state = { origin: O::originState, geometry: Q::geometryState, handoff: H::s }
  temporal progress = weakFair(step, Set(state)).implies(eventually(terminal))
}
