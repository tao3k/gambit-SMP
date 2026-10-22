module stack_handler_label_binding {
  // The procedure cell points at the intro label. On the observed Darwin/GNU
  // image a label pointer at intro + n slots dispatches to handler n - 1.
  // Both the kernel handlers and dynamic-env return are bound by setup.c.
  type State = {
    phase: str,
    introOffset: int,
    requestedHandler: int,
    dispatchedHandler: int
  }
  var s: State

  action init = s' = {
    phase: "setup", introOffset: 0,
    requestedHandler: -1, dispatchedHandler: -1
  }
  action shiftIntro = all {
    s.phase == "setup",
    s' = { ...s, introOffset: 1 }
  }
  action bindStack = all {
    s.phase == "setup",
    s' = { ...s, phase: "bound", requestedHandler: 2,
      dispatchedHandler: 2 + s.introOffset - 1 }
  }
  action bindSfun = all {
    s.phase == "setup",
    s' = { ...s, phase: "bound", requestedHandler: 0,
      dispatchedHandler: s.introOffset - 1 }
  }
  action bindDynamicReturn = all {
    s.phase == "setup",
    s' = { ...s, phase: "bound", requestedHandler: 1,
      dispatchedHandler: s.introOffset }
  }
  val targetMatches = s.phase != "bound" or
    s.dispatchedHandler == s.requestedHandler

  run observedStackMisrouteTest = init.then(bindStack).then(all {
    assert(not(targetMatches)),
    assert(s.requestedHandler == 2),
    assert(s.dispatchedHandler == 1),
    s' = s
  })
  run shiftedStackTargetTest = init.then(shiftIntro).then(bindStack).then(all {
    assert(targetMatches), s' = s
  })
  run shiftedSfunTargetTest = init.then(shiftIntro).then(bindSfun).then(all {
    assert(targetMatches), s' = s
  })
  run shiftedDynamicReturnTargetTest = init.then(shiftIntro).then(bindDynamicReturn)
    .then(all { assert(targetMatches), s' = s })
}
