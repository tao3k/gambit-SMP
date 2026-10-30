module stack_handler_producer {
  // A stack bound is not enough to admit a handler entry. The native
  // call-preflight candidate reached the C-conversion handler with temp4=0;
  // the main VM's temp4 write watchpoint saw no producer before the fault.
  // This model keeps an authorized C error and a corrupt control transfer
  // distinct. It does not assert which one occurred in the native run.
  type State = {
    phase: str,
    stackBounded: bool,
    frameValid: bool,
    cErrorProduced: bool,
    errorCodeTaggedFixnum: bool,
    handlerTargetValid: bool,
    fault: bool
  }
  var s: State

  action init = s' = {
    phase: "call-boundary", stackBounded: false, frameValid: true,
    cErrorProduced: false, errorCodeTaggedFixnum: false,
    handlerTargetValid: false, fault: false
  }
  action preflight = all {
    s.phase == "call-boundary",
    s' = { ...s, phase: "body", stackBounded: true }
  }
  action produceCError = all {
    s.phase == "body",
    s' = { ...s, phase: "handler", cErrorProduced: true,
      errorCodeTaggedFixnum: true, handlerTargetValid: true }
  }
  action misroute = all {
    s.phase == "body",
    s' = { ...s, phase: "handler", frameValid: false }
  }
  action uninitializedErrorRoute = all {
    s.phase == "body",
    s' = { ...s, phase: "handler" }
  }
  action dispatch = all {
    s.phase == "handler",
    s' = { ...s, phase: "done", fault: not(s.handlerTargetValid) }
  }
  val entrySound = s.phase != "handler" or
    (s.stackBounded and s.frameValid and s.cErrorProduced and
      s.errorCodeTaggedFixnum and
      s.handlerTargetValid)

  run authorizedProducerTest = init.then(preflight).then(produceCError)
    .then(all { assert(entrySound), s' = s }).then(dispatch)
    .then(all { assert(not(s.fault)), s' = s })
  run corruptControlFlowCounterexampleTest = init.then(preflight).then(misroute)
    .then(all { assert(not(entrySound)), s' = s }).then(dispatch)
    .then(all { assert(s.fault), s' = s })
  run missingProducerCounterexampleTest = init.then(preflight)
    .then(uninitializedErrorRoute)
    .then(all { assert(not(entrySound)), s' = s }).then(dispatch)
    .then(all { assert(s.fault), s' = s })
  run nativeTaggedValueRejectsNormalProducerTest = init.then(preflight)
    .then(misroute)
    .then(all {
      assert(not(s.errorCodeTaggedFixnum)),
      assert(not(s.cErrorProduced)),
      assert(not(entrySound)),
      s' = s
    })
}
