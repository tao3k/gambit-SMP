// Two coverage classes: Scheme-emitted C and linker-emitted C.
// Native inventories refine these classes; this is not a compiler-correctness proof.
module bootstrap_cohort {
  type Cohort = {host:bool, argv:bool, generated:Set[int], target:bool,
    selfGenerated:Set[int], selfBuilt:bool, semantics:bool, hostLinked:bool}
  var s:Cohort
  val classes=Set(0,1)
  pure val empty:Cohort={host:false,argv:false,generated:Set(),target:false,
    selfGenerated:Set(),selfBuilt:false,semantics:false,hostLinked:false}
  action init={s'=empty}
  action qualifyHost=all{not(s.host),s'={...s,host:true}}
  action canonicalize=all{s.host,not(s.argv),s'={...s,argv:true}}
  action emit={nondet i=classes.oneOf();all{s.host,s.argv,not(s.generated.contains(i)),
    s'={...s,generated:s.generated.union(Set(i))}}}
  action buildTarget=all{s.generated==classes,s.argv,not(s.target),s'={...s,target:true}}
  action selfEmit={nondet i=classes.oneOf();all{s.target,not(s.selfGenerated.contains(i)),
    s'={...s,selfGenerated:s.selfGenerated.union(Set(i))}}}
  action buildSelf=all{s.target,s.selfGenerated==classes,not(s.selfBuilt),s'={...s,selfBuilt:true}}
  // The native oracle must separately establish the real map/GC result.
  action observeSemantics=all{s.selfBuilt,not(s.semantics),s'={...s,semantics:true}}
  action step=any{qualifyHost,canonicalize,emit,buildTarget,selfEmit,buildSelf,observeSemantics,s'=s}
  val safe=all{
    s.generated.size()>0 implies (s.host and s.argv),
    s.target implies (s.generated==classes and s.argv),
    s.selfGenerated.size()>0 implies s.target,
    s.selfBuilt implies (s.target and s.selfGenerated==classes),
    s.semantics implies s.selfBuilt,
    not(s.hostLinked)
  }
  action check=all{safe,s'=s}
  run fullChainTest=init.then(qualifyHost).then(canonicalize).then(emit).then(emit)
    .then(buildTarget).then(selfEmit).then(selfEmit).then(buildSelf).then(observeSemantics).then(check)
  action legacyTarget={s'={...empty,host:true,argv:true,generated:Set(0),target:true}}
  action onlyProcessArgv={s'={...empty,host:true,generated:Set(0)}}
  action hostPassAsSelf={s'={...empty,host:true,argv:true,generated:classes,target:true,selfBuilt:true}}
  action nativeBeforeBootstrap={s'={...empty,semantics:true}}
  action importHostRuntime={s'={...empty,hostLinked:true}}

  // Family 6 construction prerequisite. These integers stand for exact
  // identities supplied by the native receipt and input-resolution adapter.
  type HostControlKey = {
    source: int, moduleInput: int, prelude: int, command: int,
    profile: int, diagnosticBudget: int
  }
  type HostLeg = {
    key: HostControlKey, runId: int, declaredHost: int, executedHost: int,
    evidenceBound: bool, inputsStable: bool, formalPreludeApplied: bool,
    parseReturned: bool, naturalExit: bool, freshC: bool, c23: bool, quiescent: bool
  }

  pure def hostLegBound(leg: HostLeg, current: HostControlKey, selectedHost: int): bool =
    leg.key == current and leg.declaredHost == selectedHost and
      leg.executedHost == selectedHost and leg.evidenceBound and leg.inputsStable and
      leg.formalPreludeApplied and leg.quiescent

  pure def hostLegComplete(leg: HostLeg): bool =
    leg.parseReturned and leg.naturalExit and leg.freshC and leg.c23

  pure def hostControlMatched(current: HostControlKey, candidateHost: int,
                             referenceHost: int, candidate: HostLeg, reference: HostLeg): bool =
    candidateHost != referenceHost and candidate.runId != reference.runId and
      hostLegBound(candidate, current, candidateHost) and
      hostLegBound(reference, current, referenceHost)

  pure def family6CanBuild(current: HostControlKey, candidateHost: int,
                           referenceHost: int, candidate: HostLeg, reference: HostLeg): bool =
    hostControlMatched(current, candidateHost, referenceHost, candidate, reference) and
      hostLegComplete(candidate)

  pure val hostControlInput: HostControlKey = {
    source: 1, moduleInput: 2, prelude: 3, command: 4, profile: 5, diagnosticBudget: 120
  }
  pure def completeHostLeg(host: int, runId: int): HostLeg = {
    key: hostControlInput, runId: runId, declaredHost: host, executedHost: host,
    evidenceBound: true, inputsStable: true, formalPreludeApplied: true,
    parseReturned: true, naturalExit: true, freshC: true, c23: true, quiescent: true
  }

  run family6MatchedPreludeControlAllowsConstructionTest =
    assert(family6CanBuild(hostControlInput, 10, 20, completeHostLeg(10, 1), completeHostLeg(20, 2)))

  run family6ChangedPreludeOrCeilingCannotMatchTest = {
    val reference = completeHostLeg(20, 2)
    assert(not(hostControlMatched(hostControlInput, 10, 20, completeHostLeg(10, 1),
      {...reference, key: {...hostControlInput, prelude: 8}})) and
      not(hostControlMatched(hostControlInput, 10, 20, completeHostLeg(10, 1),
        {...reference, key: {...hostControlInput, diagnosticBudget: 600}})))
  }

  run family6StaleOrSubstitutedEvidenceCannotMatchTest = {
    val candidate = completeHostLeg(10, 1)
    val reference = completeHostLeg(20, 2)
    assert(not(hostControlMatched(hostControlInput, 10, 20, candidate, {...reference, evidenceBound: false})) and
      not(hostControlMatched(hostControlInput, 10, 20, candidate, {...reference, executedHost: 30})) and
      not(hostControlMatched(hostControlInput, 10, 20, candidate, {...reference, runId: 1})))
  }

  run family6ReferenceSuccessAndBoundParseFailureAreDiagnosticTest = {
    val candidate = {...completeHostLeg(10, 1), parseReturned: false, naturalExit: false, freshC: false, c23: false}
    val reference = completeHostLeg(20, 2)
    assert(hostControlMatched(hostControlInput, 10, 20, candidate, reference) and
      not(family6CanBuild(hostControlInput, 10, 20, candidate, reference)))
  }

  run family6BoundReferenceFailureDoesNotBlockCompleteSelectedHostTest = {
    val reference = {...completeHostLeg(20, 2), parseReturned: false, naturalExit: false, freshC: false, c23: false}
    assert(family6CanBuild(hostControlInput, 10, 20, completeHostLeg(10, 1), reference))
  }

  run family6FalseExitZeroOrMissingSyntaxCannotReleaseBuildTest = {
    val candidate = completeHostLeg(10, 1)
    val reference = completeHostLeg(20, 2)
    assert(not(family6CanBuild(hostControlInput, 10, 20, {...candidate, freshC: false}, reference)) and
      not(family6CanBuild(hostControlInput, 10, 20, {...candidate, c23: false}, reference)) and
      not(family6CanBuild(hostControlInput, 10, 20, {...candidate, quiescent: false}, reference)) and
      not(family6CanBuild(hostControlInput, 10, 20, {...candidate, formalPreludeApplied: false}, reference)))
  }
  type Gate2Emission = {
    selectedEmitter: int, actualEmitter: int, makeInputs: int, observedInputs: int,
    cRun: int, gvmRun: int, retainedC: int, emittedC: int,
    completed: bool, reviewed: bool, linked: bool, historicalLineage: bool
  }

  pure def gate2Pair(e: Gate2Emission): bool =
    e.completed and e.selectedEmitter == e.actualEmitter and e.makeInputs == e.observedInputs and
      e.cRun == e.gvmRun and e.retainedC == e.emittedC

  pure def gate2SiteBound(e: Gate2Emission): bool =
    gate2Pair(e) and e.reviewed and e.linked and e.historicalLineage

  pure val gate2Example: Gate2Emission = {
    selectedEmitter: 1, actualEmitter: 1, makeInputs: 2, observedInputs: 2,
    cRun: 3, gvmRun: 3, retainedC: 4, emittedC: 4,
    completed: true, reviewed: true, linked: true, historicalLineage: true
  }
  run gate2SameInvocationTest = assert(gate2SiteBound(gate2Example))
  run gate2CrossInvocationTest =
    assert(not(gate2Pair({...gate2Example, gvmRun: 5})))
  run gate2InputOrArtifactMismatchTest =
    assert(not(gate2Pair({...gate2Example, observedInputs: 5})) and
           not(gate2Pair({...gate2Example, actualEmitter: 5})) and
           not(gate2Pair({...gate2Example, emittedC: 5})) and
           not(gate2Pair({...gate2Example, completed: false})))
  run gate2HistoricalAndReviewGapTest =
    assert(gate2Pair(gate2Example) and
           not(gate2SiteBound({...gate2Example, reviewed: false})) and
           not(gate2SiteBound({...gate2Example, linked: false})) and
           not(gate2SiteBound({...gate2Example, historicalLineage: false})))

  // Pass-1 self-hosted emitter bug caught in family6-local-admit-successor-run-s2c:
  // proc-obj-name already returns a tagged string; under (declare (not safe)),
  // unchecked symbol->string reads body[0] (two UTF-32 code units, e.g. "##" =
  // 0x0000002300000023 whose low tag bits equal ___tPAIR = 3) into global root
  // c#targ-proc-gate2-name, faulting census_array on the next GC.
  type Gate2NameCell = {
    inputKind: str, storedKind: str, lowTagBits: int
  }

  pure def gcSafeGlobalRoot(cell: Gate2NameCell): bool =
    cell.storedKind == "false" or cell.storedKind == "string" or cell.storedKind == "symbol"

  pure def uncheckedSymbolNameProjection(inputKind: str, prefixDoubleSharp: bool): Gate2NameCell =
    if (inputKind == "symbol") {
      { inputKind: inputKind, storedKind: "string", lowTagBits: 1 }
    } else {
      { inputKind: inputKind, storedKind: "raw-utf32-word", lowTagBits: if (prefixDoubleSharp) 3 else 0 }
    }

  pure def checkedGate2ProcName(inputKind: str): Gate2NameCell =
    if (inputKind == "symbol" or inputKind == "string") {
      { inputKind: inputKind, storedKind: "string", lowTagBits: 1 }
    } else {
      { inputKind: inputKind, storedKind: "false", lowTagBits: 2 }
    }

  run gate2UncheckedSymbolToStringOnStringCorruptsGlobalRootTest = {
    val corrupted = uncheckedSymbolNameProjection("string", true)
    assert(corrupted.storedKind == "raw-utf32-word" and
           corrupted.lowTagBits == 3 and
           not(gcSafeGlobalRoot(corrupted)))
  }

  run gate2CheckedProcNamePreservesStringGlobalRootTest = {
    val fromString = checkedGate2ProcName("string")
    val fromSymbol = checkedGate2ProcName("symbol")
    assert(gcSafeGlobalRoot(fromString) and fromString.storedKind == "string" and
           gcSafeGlobalRoot(fromSymbol) and fromSymbol.storedKind == "string")
  }
}
