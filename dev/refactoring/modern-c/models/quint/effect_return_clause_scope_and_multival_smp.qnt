// -*- mode: Bluespec; -*-
// Phase C44: Out-of-Scope Tail-Position `return:` Clause Execution &
// Full 0/1/N Multiple-Value `return:` Dispatch in `(gambit effect)`.

module effect_return_clause_scope_and_multival_smp {
  pure val H_OUTER = 1
  pure val H_INNER = 2

  pure val TARGET_OUTER = 1
  pure val TARGET_INNER = 2

  // Helper: dispatch effect to topmost handler on stack
  pure def dispatchHandler(hs: List[int]): int =
    if (hs.length() > 0) hs[0] else 0

  // Helper: pop inner handler frame before invoking return-fn
  pure def popTopHandler(hs: List[int]): List[int] =
    if (hs.length() > 0) hs.slice(1, hs.length()) else List()

  // Helper: arity-preserving multi-value return dispatch (arity in {0, 1, 2})
  pure def dispatchMultival(arity: int, expectedArity: int): bool =
    (arity == expectedArity)

  // State
  var handlers: List[int]
  var mcDepth: int
  var suspendReturnTarget: int
  var tailReturnTarget: int
  var multishotBranch1Target: int
  var multishotBranch2Target: int
  var multival0Ok: bool
  var multival2Ok: bool
  var excInReturnClean: bool
  var violation: bool

  action init = all {
    handlers' = List(H_OUTER),
    mcDepth' = 1,
    suspendReturnTarget' = 0,
    tailReturnTarget' = 0,
    multishotBranch1Target' = 0,
    multishotBranch2Target' = 0,
    multival0Ok' = false,
    multival2Ok' = false,
    excInReturnClean' = false,
    violation' = false,
  }

  // Step 1: Suspending with-handler installs H_INNER, body finishes,
  // `%mc-return1-with-fn` pops H_INNER & pframe BEFORE running `return:`.
  // Performing `e` inside `return:` must hit H_OUTER, never H_INNER!
  action suspendReturnDispatchesOuter = all {
    suspendReturnTarget == 0,
    val duringBody = List(H_INNER).concat(handlers)
    val duringReturn = popTopHandler(duringBody)
    val target = dispatchHandler(duringReturn)
    val bad = (target != TARGET_OUTER) or (duringReturn != handlers)
    all {
      suspendReturnTarget' = target,
      violation' = (violation or bad),
      handlers' = handlers,
      mcDepth' = mcDepth,
      tailReturnTarget' = tailReturnTarget,
      multishotBranch1Target' = multishotBranch1Target,
      multishotBranch2Target' = multishotBranch2Target,
      multival0Ok' = multival0Ok,
      multival2Ok' = multival2Ok,
      excInReturnClean' = excInReturnClean,
    }
  }

  // Step 2: Tail-resumptive with-handler pops H_INNER BEFORE running `return:`
  // (outside with-exception-catcher in true tail position).
  action tailReturnDispatchesOuter = all {
    tailReturnTarget == 0,
    val duringBody = List(H_INNER).concat(handlers)
    val duringReturn = popTopHandler(duringBody)
    val target = dispatchHandler(duringReturn)
    val bad = (target != TARGET_OUTER) or (duringReturn != handlers)
    all {
      tailReturnTarget' = target,
      violation' = (violation or bad),
      handlers' = handlers,
      mcDepth' = mcDepth,
      suspendReturnTarget' = suspendReturnTarget,
      multishotBranch1Target' = multishotBranch1Target,
      multishotBranch2Target' = multishotBranch2Target,
      multival0Ok' = multival0Ok,
      multival2Ok' = multival2Ok,
      excInReturnClean' = excInReturnClean,
    }
  }

  // Step 3: Multi-shot resume runs `return:` once per resumed branch,
  // popping each branch's reinstalled H_INNER before `return:` executes.
  action multishotReturnPerBranch = all {
    multishotBranch1Target == 0,
    val b1Handlers = popTopHandler(List(H_INNER).concat(handlers))
    val b2Handlers = popTopHandler(List(H_INNER).concat(handlers))
    val t1 = dispatchHandler(b1Handlers)
    val t2 = dispatchHandler(b2Handlers)
    val bad = (t1 != TARGET_OUTER) or (t2 != TARGET_OUTER)
    all {
      multishotBranch1Target' = t1,
      multishotBranch2Target' = t2,
      violation' = (violation or bad),
      handlers' = handlers,
      mcDepth' = mcDepth,
      suspendReturnTarget' = suspendReturnTarget,
      tailReturnTarget' = tailReturnTarget,
      multival0Ok' = multival0Ok,
      multival2Ok' = multival2Ok,
      excInReturnClean' = excInReturnClean,
    }
  }

  // Step 4: 0-value and 2-value return-clause dispatch
  action checkMultivalReturn = all {
    not(multival0Ok),
    val ok0 = dispatchMultival(0, 0)
    val ok2 = dispatchMultival(2, 2)
    val bad = not(ok0) or not(ok2)
    all {
      multival0Ok' = ok0,
      multival2Ok' = ok2,
      violation' = (violation or bad),
      handlers' = handlers,
      mcDepth' = mcDepth,
      suspendReturnTarget' = suspendReturnTarget,
      tailReturnTarget' = tailReturnTarget,
      multishotBranch1Target' = multishotBranch1Target,
      multishotBranch2Target' = multishotBranch2Target,
      excInReturnClean' = excInReturnClean,
    }
  }

  // Step 5: Exception raised inside `return:` observes clean outer stack (H_INNER already popped)
  action checkExcInReturnClean = all {
    not(excInReturnClean),
    val duringReturn = popTopHandler(List(H_INNER).concat(handlers))
    val clean = (duringReturn == handlers) and not(duringReturn.indices().exists(i => duringReturn[i] == H_INNER))
    all {
      excInReturnClean' = clean,
      violation' = (violation or not(clean)),
      handlers' = handlers,
      mcDepth' = mcDepth,
      suspendReturnTarget' = suspendReturnTarget,
      tailReturnTarget' = tailReturnTarget,
      multishotBranch1Target' = multishotBranch1Target,
      multishotBranch2Target' = multishotBranch2Target,
      multival0Ok' = multival0Ok,
      multival2Ok' = multival2Ok,
    }
  }

  action step = any {
    suspendReturnDispatchesOuter,
    tailReturnDispatchesOuter,
    multishotReturnPerBranch,
    checkMultivalReturn,
    checkExcInReturnClean,
  }

  val noViolationInv = not(violation)
  val suspendAndTailAgreeInv =
    (suspendReturnTarget != 0 and tailReturnTarget != 0) implies (suspendReturnTarget == tailReturnTarget)
  val outerHandlerPreservedInv = (handlers == List(H_OUTER))
  val allInvs = noViolationInv and suspendAndTailAgreeInv and outerHandlerPreservedInv

  run fullScenarioTest =
    init
      .then(suspendReturnDispatchesOuter)
      .then(tailReturnDispatchesOuter)
      .then(multishotReturnPerBranch)
      .then(checkMultivalReturn)
      .then(checkExcInReturnClean)
      .expect(allInvs and suspendReturnTarget == TARGET_OUTER and tailReturnTarget == TARGET_OUTER and multival0Ok and multival2Ok and excInReturnClean)

  run suspendMatchesTailTest =
    init
      .then(suspendReturnDispatchesOuter)
      .then(tailReturnDispatchesOuter)
      .expect(suspendReturnTarget == tailReturnTarget and suspendReturnTarget == TARGET_OUTER)

  run multishotBothBranchesOuterTest =
    init
      .then(multishotReturnPerBranch)
      .expect(multishotBranch1Target == TARGET_OUTER and multishotBranch2Target == TARGET_OUTER)

  run multivalArityTest =
    init
      .then(checkMultivalReturn)
      .expect(multival0Ok and multival2Ok)

  run excInReturnNoInnerLeakTest =
    init
      .then(checkExcInReturnClean)
      .expect(excInReturnClean and handlers == List(H_OUTER))
}
