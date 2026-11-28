module host_root_participation {
  import host_root_publication_lifetime.* from "./host_root_publication_lifetime"
  import host_root_publication_instance(role = "handoff") as P from "./host_root_publication_lifetime"

  // The imported phase 1 establishes the coarse record-publication state.
  // It is not source evidence that the real host has stopped mutating roots.
  // Track the latter separately without changing the imported protocol.
  type Participation = { policy: int, frozen: bool, parked: bool,
    payload: int, handed: int, observed: int }
  var p: Participation
  // Ghost transition rank makes imported metadata-only moves visible to
  // fairness without exporting/changing the previously qualified models.
  // Every nonterminal move is acyclic in this cohort; no heartbeat action.
  var transitionRank: int
  pure def participationInitial(policy: int): Participation = {
    policy: policy, frozen: false, parked: false,
    payload: 0, handed: -1, observed: -1 }
  // One initialization call preserves the imported state identity and avoids
  // Quint's init/step reuse restriction. The immutable scenario tag partitions
  // the corrected cohort (0) and the two deliberate omissions (1 and 2).
  action initParticipation = {
    nondet scenario = Set(0, 1, 2).oneOf()
    all { initFixed, p' = participationInitial(scenario), transitionRank' = 0,
      P::s' = P::initial(if (scenario == 2) "release-only" else "release-acquire") }
  }
  action keepHost = all { h' = h, keepV, keepL }
  action keepP = P::s' = P::s

  action prepareRecord = all { any { saveRoot, initializeRecord }, p' = p, keepP }
  action publishRecord = all { publishAndBlock, p' = p, keepP }
  // A root value may change while its already-published owner is executing.
  // This is one bounded last-write opportunity, not a concurrent-GC design.
  action writeActiveRoot = all { h.phase == 1, not(p.frozen), p.payload == 0,
    p' = { ...p, payload: 1 }, keepHost, keepP }
  action freezeRootState = all { h.phase == 1, not(p.frozen), P::initialize,
    p' = { ...p, frozen: true, handed: p.payload }, keepHost }
  action releaseExecution = all { p.frozen, not(p.parked), P::publish,
    p' = { ...p, parked: true }, keepHost }

  action admitRootReader = all { p.parked or p.policy == 1,
    admitScanner, p' = p, keepP }
  action acquireRootRecord = all { loadRecord,
    if (p.policy == 1) keepP else P::load, p' = p }
  action registerRootReader = all { registerScanner, p' = p, keepP }
  action observeRoots = all { scanRoots,
    if (p.policy == 1) keepP else P::use,
    p' = { ...p, observed: if (p.policy == 1) p.payload
      else if (P::s.acquiredInit) p.handed else -1 } }
  action resumeOwnedHost = all { p.parked, resumeHost, p' = p, keepP }
  action finishHostRecord = all { any { lastHostUse, close, retireRecord }, p' = p, keepP }

  val finalRootObserved = not(h.scanned and p.frozen) or p.observed == p.handed
  val rootObservationSafe = p.policy != 1 or finalRootObserved
  val readerEligible = not(h.scanned) or (p.frozen and p.parked)
  val handoffOrderingSafe = p.policy != 2 or P::safe
  val participationSafe = p.policy != 0 or
    (safe and finalRootObserved and readerEligible and P::safe)
  val participationTerminal = terminal and p.parked and P::terminal
  val noChangedRootCleanup = not(p.policy == 0 and participationTerminal and
    p.handed == 1 and p.observed == 1)
  action participationFinished = all { participationTerminal, keepHost, p' = p,
    keepP, transitionRank' = transitionRank }
  action participationStep = any { participationFinished,
    all { not(participationTerminal),
      any { prepareRecord, publishRecord, writeActiveRoot, freezeRootState,
        releaseExecution, admitRootReader, acquireRootRecord, registerRootReader,
        observeRoots, resumeOwnedHost, finishHostRecord },
      transitionRank' = transitionRank + 1 } }
  // Record publication and final-state handoff are separate logical edges.
  // They may map to one physical mutex/collective edge if all required writes
  // precede it; this does not prescribe another runtime fence or counter.
  // The ghost rank changes for every real transition, including imported
  // metadata-only moves. Fairness cannot silently omit their final reclaim.
  // This is conditional model scheduling, not a native watchdog or OS proof.
  temporal participationCompletion = always(p.policy != 0) or
    (always(participationTerminal or enabled(participationStep)) and
      weakFair(participationStep, Set(transitionRank))
        .implies(eventually(participationTerminal)))
}
