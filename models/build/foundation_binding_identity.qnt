module foundation_binding_identity {
  import foundation_binding_parameters.* from "./foundation_binding_parameters"
  val Workers = Set(0, 1)
  pure def binding(ctx: int, phi: int, name: int): int =
    if (name == 1) -1 else phi * 100 + (if (ctx == Definition or ctx >= 3) 1 else ctx * 10 + 1)
  pure def toggle(m: int, marks: List[int]): List[int] =
    if (marks.length() == 0) List(m)
    else if (marks.head() == m) marks.tail() else List(m).concat(marks)
  type State = { certified: bool, stateful: bool, fault: int,
    quoteContext: int -> int, mark: int, alias: int, distinct: int,
    sharedPhiWrites: int, privatePhiWrites: int -> int,
    active: Set[int], calls: int, moduleCounter: int, results: List[int],
    generation: int, cachedGeneration: int, badReuse: bool }
  var s: State
  pure def initial(certified: bool, stateful: bool, fault: int): State = {
    certified: certified, stateful: stateful, fault: fault,
    quoteContext: Workers.mapBy(w =>
      if (fault == 1) Consumer + w else if (fault == 8) 3 + w else Definition),
    mark: 10, alias: if (fault == 2) 12 else 10,
    distinct: if (fault == 3) 10 else 11,
    sharedPhiWrites: 0, privatePhiWrites: Workers.mapBy(_ => 0), active: Set(),
    calls: 0, moduleCounter: 0, results: List(), generation: 0,
    cachedGeneration: 0, badReuse: false }
  action init = s' = initial(true, false, 0)
  action initActual = s' = initial(SourceClosed, false, 0)
  action initStateful = s' = initial(true, true, 0)
  action initCapture = s' = initial(true, false, 1)
  action initAlias = s' = initial(true, false, 2)
  action initMerge = s' = initial(true, false, 3)
  action initSharedPhi = s' = initial(true, false, 4)
  action initReset = s' = initial(true, true, 5)
  action initPhaseCollapse = s' = initial(true, false, 6)
  action initNameOnly = s' = initial(true, false, 7)
  action initContextClone = s' = initial(true, false, 8)
  def resolved(w: int, phi: int): int = binding(s.quoteContext.get(w), if (s.fault == 6) 0 else phi, 0)
  def bindingOK = Workers.forall(w => Set(0, 1).forall(p => resolved(w, p) == binding(Definition, p, 0)))
  def contextAliasOK = s.quoteContext.get(0) == s.quoteContext.get(1)
  def markOK = toggle(s.mark, List(s.alias)).length() == 0 and
    toggle(s.distinct, List(s.mark)).length() == 2
  def parallelReady = s.certified and not(s.stateful) and bindingOK and contextAliasOK and markOK
  def safe = bindingOK and contextAliasOK and markOK and s.sharedPhiWrites == 0
    and s.moduleCounter == s.calls and not(s.badReuse)
    and (s.active.size() < 2 or parallelReady)
  def currentImageReady = parallelReady and s.cachedGeneration == s.generation
  action start(w: int): bool = all { currentImageReady, not(s.active.contains(w)),
    s' = { ...s, active: s.active.union(Set(w)) } }
  action shiftLookup(w: int): bool = all { s.active.contains(w),
    s' = if (s.fault == 4) { ...s, sharedPhiWrites: s.sharedPhiWrites + 1 }
      else { ...s, privatePhiWrites: s.privatePhiWrites.set(w, s.privatePhiWrites.get(w) + 1) } }
  // One effect owner linearizes stateful invocations; fresh counters would change observations.
  action moduleCall = all { s.stateful, s.active.size() == 0,
    val counterValue = if (s.fault == 5) 1 else s.moduleCounter + 1
    s' = { ...s, calls: s.calls + 1, moduleCounter: counterValue, results: s.results.append(counterValue) } }
  action changeGeneration = s' = { ...s, generation: s.generation + 1 }
  action reuseQuote = all {
    s.cachedGeneration == s.generation or s.fault == 7,
    s' = { ...s, badReuse: s.badReuse or s.cachedGeneration != s.generation } }
  action step = any {
    nondet w = Workers.oneOf()
    any { start(w), shiftLookup(w) },
    changeGeneration, reuseQuote, moduleCall, s' = s
  }
  run observedFoundationBlocksTest = initActual.expect(safe and not(parallelReady))
  run quotedDefinitionWinsTest = init.expect(safe and resolved(0, 0) != binding(Consumer, 0, 0))
  run consumerShadowDistinctTest = init.expect(binding(Consumer, 0, 0) != binding(Alternate, 0, 0))
  run quotedAliasPreservedTest = init.expect(safe and contextAliasOK and resolved(0, 0) == resolved(1, 0))
  run missingBindingTest = init.expect(binding(Definition, 0, 1) == -1)
  run phaseIdentityTest = init.expect(safe and resolved(0, 0) != resolved(0, 1))
  run markAliasesCancelTest = init.expect(safe and toggle(s.mark, List(s.alias)) == List())
  run distinctMarksDoNotCancelTest = init.expect(safe and toggle(s.distinct, List(s.mark)).length() == 2)
  run privatePhiCacheTest = init.then(start(0)).then(start(1)).then(shiftLookup(0))
    .expect(safe and s.privatePhiWrites.get(0) == 1 and s.privatePhiWrites.get(1) == 0)
  run statefulParallelDeniedTest = initStateful.expect(safe and not(parallelReady))
  run statefulInstancePreservedTest = initStateful.then(moduleCall).then(moduleCall)
    .expect(safe and s.results == List(1, 2))
  run sameGenerationReuseTest = init.then(reuseQuote).expect(safe)
  run changedGenerationBlocksStartTest = init.then(changeGeneration).expect(safe and not(currentImageReady))
  run definitionRebaseControlTest = initCapture.expect(not(safe) and not(bindingOK))
  run freshPerOccurrenceControlTest = initAlias.expect(not(safe) and not(markOK))
  run collapsedMarkControlTest = initMerge.expect(not(safe) and not(markOK))
  run sharedLazyWriteControlTest = initSharedPhi.then(start(0)).then(shiftLookup(0))
    .expect(not(safe) and s.sharedPhiWrites == 1)
  run resetStatefulProviderControlTest = initReset.then(moduleCall).then(moduleCall)
    .expect(not(safe) and s.results == List(1, 1))
  run collapsedPhaseControlTest = initPhaseCollapse.expect(not(safe) and not(bindingOK))
  run nameOnlyCutoffControlTest = initNameOnly.then(changeGeneration).then(reuseQuote)
    .expect(not(safe) and s.badReuse)
  run duplicatedContextControlTest = initContextClone.expect(bindingOK and not(contextAliasOK) and not(safe))
}
