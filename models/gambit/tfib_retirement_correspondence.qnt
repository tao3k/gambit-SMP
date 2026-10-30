module tfib_retirement_correspondence {
  import retirement_pre_exit as R from "./retirement_pre_exit"

  // Reuse the pre-exit protocol, not a second implementation of retirement.
  // mode describes a hypothetical execution. Evidence is a separate projection:
  // a reachable counterexample is NOT evidence that native TFIB took that path.
  // Identity integers are finite equivalence classes, not processor counts.
  type Evidence = { producer: int, execution: int, interval: int,
    coherent: bool, entered: bool, censusComplete: bool, zeroCensus: bool,
    callbackGC: bool, waitCycle: bool }
  type Bridge = { mode: str, active: bool, schemeJoined: bool,
    symptom: str, claimed: bool, fault: bool, witness: Evidence }
  var b: Bridge
  pure def emptyEvidence: Evidence = { producer: 0, execution: 0, interval: 0,
    coherent: false, entered: false, censusComplete: false, zeroCensus: false,
    callbackGC: false, waitCycle: false }
  pure def initial(mode: str, fault: bool): Bridge = {
    mode: mode, active: false, schemeJoined: false, symptom: "none",
    claimed: false, fault: fault, witness: emptyEvidence }
  // Target producer/execution/interval are represented by (0,0,0).
  pure def bound(e: Evidence): bool = e.coherent and e.producer == 0 and
    e.execution == 0 and e.interval == 0
  pure def conflict(e: Evidence): bool = bound(e) and e.entered and e.censusComplete and e.zeroCensus
  pure def entered(e: Evidence): bool = bound(e) and e.entered and not(conflict(e))
  pure def excluded(e: Evidence): bool = bound(e) and e.censusComplete and e.zeroCensus and not(e.entered)
  pure def conditionalHazard(e: Evidence): bool = entered(e) and e.callbackGC and e.waitCycle
  val activationUnknown = not(entered(b.witness)) and not(excluded(b.witness)) and not(conflict(b.witness))
  val evidenceSafe = (not(b.claimed) or conditionalHazard(b.witness)) and
    not(entered(b.witness) and excluded(b.witness)) and
    (not(b.active) or b.mode == "resize")
  // A protocol violation is meaningful only on the modeled activated path.
  // Native acceptance is intentionally not an output of this composition.
  val protocolSafe = not(b.active) or R::safe
  val safe = evidenceSafe and protocolSafe
  action init = all { R::s' = R::initial(0,0,true), b' = initial("resize",false) }
  action initCurrentCallback = all { R::s' = R::initial(1,0,true), b' = initial("resize",false) }
  action initCurrentNormal = all { R::s' = R::initial(1,0,false), b' = initial("resize",false) }
  action initFailedJoin = all { R::s' = R::initial(0,1,true), b' = initial("resize",false) }
  action initCurrentFailedJoin = all { R::s' = R::initial(1,1,false), b' = initial("resize",false) }
  action initSteady = all { R::s' = R::initial(1,0,true), b' = initial("steady",false) }
  action initFalseAttribution = all { R::s' = R::initial(1,0,true), b' = initial("steady",true) }
  action activate = all { b.mode == "resize", not(b.active),
    R::s' = R::s, b' = { ...b, active: true } }
  action schemeJoin = all { not(b.schemeJoined), R::s' = R::s,
    b' = { ...b, schemeJoined: true } }
  // None of these observations encodes a retirement transition or a cause.
  action observeSymptom = all { b.symptom == "none",
    nondet symptom = Set("signal-10", "join-exit-70", "inactivity").oneOf()
    all { R::s' = R::s, b' = { ...b, symptom: symptom } } }
  action retirementStep = all { b.active, R::step, b' = b }
  // Snapshot flags stand for source-bound witnesses on the same interval.
  // Capturing entry does not establish an allocating callback or wait cycle.
  action witnessEntry = all { b.active, not(b.witness.entered),
    R::s' = R::s, b' = { ...b, witness: { ...b.witness,
      coherent: true, entered: true } } }
  action witnessHazard = all { b.active, entered(b.witness), R::s.request,
    R::s.joining or not(R::s.member), not(b.witness.waitCycle),
    R::s' = R::s, b' = { ...b, witness: { ...b.witness,
      callbackGC: true, waitCycle: true } } }
  // Exclusion requires complete observation of the selected interval. Merely
  // not seeing an event, a constant sampled count, or Scheme join is insufficient.
  action witnessSteadyCensus = all { b.mode == "steady", not(b.witness.censusComplete),
    R::s' = R::s, b' = { ...b, witness: { ...b.witness,
      coherent: true, censusComplete: true, zeroCensus: true } } }
  action reportConditionalHazard = all { not(b.claimed),
    conditionalHazard(b.witness) or b.fault,
    R::s' = R::s, b' = { ...b, claimed: true } }
  action hold = all { R::s' = R::s, b' = b }
  action step = any { activate, schemeJoin, observeSymptom, retirementStep,
    witnessEntry, witnessHazard, witnessSteadyCensus, reportConditionalHazard, hold }

  run schemeJoinIsNotRetirementTest = initSteady.then(schemeJoin).then(observeSymptom)
    .then(all { assert(b.schemeJoined), assert(not(b.active)), assert(activationUnknown),
      assert(not(b.claimed)), assert(safe), hold })
  run completeSteadyIntervalExcludesRetirementTest = initSteady.then(witnessSteadyCensus)
    .then(all { assert(excluded(b.witness)), assert(not(activationUnknown)),
      assert(not(conditionalHazard(b.witness))), assert(safe), hold })
  run activatedWithoutWitnessIsUnknownTest = init.then(activate)
    .then(all { assert(b.active), assert(activationUnknown), assert(safe), hold })
  run entryDoesNotProveCallbackHazardTest = init.then(activate).then(witnessEntry)
    .then(all { assert(entered(b.witness)), assert(not(conditionalHazard(b.witness))),
      assert(not(b.claimed)), assert(safe), hold })
  run foreignAndIncompleteWitnessesStayUnknownTest = init.then(all {
    assert(not(entered({ ...emptyEvidence, coherent: true, entered: true, producer: 1 }))),
    assert(not(entered({ ...emptyEvidence, coherent: true, entered: true, execution: 1 }))),
    assert(not(entered({ ...emptyEvidence, coherent: true, entered: true, interval: 1 }))),
    assert(not(entered({ ...emptyEvidence, entered: true }))),
    assert(not(excluded({ ...emptyEvidence, coherent: true }))),
    hold })
  run conflictingCensusDoesNotAuthorizeAttributionTest = init.then(all {
    val contradictory = { ...emptyEvidence, coherent: true, entered: true,
      censusComplete: true, zeroCensus: true, callbackGC: true, waitCycle: true }
    all { assert(conflict(contradictory)), assert(not(entered(contradictory))),
      assert(not(excluded(contradictory))), assert(not(conditionalHazard(contradictory))), hold } })
  // This counterexample is conditional on the modeled resize and callback GC.
  // It does not assign the retained native signal or join exception a cause.
  run currentWithdrawBeforeCallbackControlTest = initCurrentCallback.then(activate)
    .then(all { R::withdraw, b' = b }).then(all { R::joinAttempt, b' = b })
    .then(all { R::startCallback, b' = b }).then(all { R::requestGC, b' = b })
    .then(all { assert(not(R::noCallbackWaitCycle)), assert(activationUnknown),
      assert(not(b.claimed)), hold })
    .then(witnessEntry).then(witnessHazard).then(reportConditionalHazard)
    .then(all { assert(conditionalHazard(b.witness)), assert(b.claimed),
      assert(evidenceSafe), assert(not(protocolSafe)), hold })
  run stagedCallbackHandoffCompletesTest = init.then(activate).then(witnessEntry)
    .then(all { R::startCallback, b' = b }).then(all { R::requestGC, b' = b })
    .then(all { R::serviceGC, b' = b }).then(all { R::callbackReturn, b' = b })
    .then(all { R::handoff, b' = b }).then(all { R::withdraw, b' = b })
    .then(all { R::joinAttempt, b' = b }).then(all { R::exitThread, b' = b })
    .then(all { R::joinSuccess, b' = b }).then(all { R::release, b' = b })
    .then(all { R::survivorGC, b' = b })
    .then(all { assert(R::terminal), assert(safe), assert(not(b.claimed)), hold })
  run currentNormalJoinIsNotMissingBarrierTest = initCurrentNormal.then(activate)
    .then(all { R::withdraw, b' = b }).then(all { R::joinAttempt, b' = b })
    .then(all { R::startCallback, b' = b }).then(all { R::callbackReturn, b' = b })
    .then(all { R::exitThread, b' = b }).then(all { R::joinSuccess, b' = b })
    .then(all { R::handoffAfterJoin, b' = b }).then(all { R::release, b' = b })
    .then(all { R::survivorGC, b' = b })
    .then(all { assert(R::terminal), assert(safe), assert(activationUnknown), hold })
  run stagedFailedJoinRetainsRootsTest = initFailedJoin.then(activate)
    .then(all { R::startCallback, b' = b }).then(all { R::requestGC, b' = b })
    .then(all { R::serviceGC, b' = b }).then(all { R::callbackReturn, b' = b })
    .then(all { R::handoff, b' = b }).then(all { R::withdraw, b' = b })
    .then(all { R::joinAttempt, b' = b }).then(all { R::survivorGC, b' = b })
    .then(all { assert(R::s.live), assert(R::s.phase == 2), assert(R::s.roots == 1),
      assert(safe), hold })
  run currentFailedJoinRootGapControlTest = initCurrentFailedJoin.then(activate)
    .then(all { R::withdraw, b' = b }).then(all { R::joinAttempt, b' = b })
    .then(all { R::survivorGC, b' = b })
    .then(all { assert(R::s.live), assert(R::s.phase == 0),
      assert(not(R::rootsCovered)), assert(activationUnknown), assert(not(b.claimed)), hold })
  run symptomCannotJustifyAttributionControlTest = initFalseAttribution.then(observeSymptom)
    .then(reportConditionalHazard)
    .then(all { assert(not(evidenceSafe)), assert(not(b.active)), hold })
}
