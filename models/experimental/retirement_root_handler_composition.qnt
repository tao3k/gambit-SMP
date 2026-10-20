module retirement_root_handler_composition {
  import public_vm_retirement_composition as P from "../gambit/public_vm_retirement_composition"
  // Experimental refinement after valid owned cohort/join preflight. P owns
  // foreign/registry admission and resource/memory release. No join retry is
  // invented. Additional logical owners are not a proposed runtime root ABI.
  type State = { policy: int, borrower: bool, publisher: bool,
    sourceRoot: bool, destinationRoot: bool, payloadLive: bool, exitKind: int,
    installed: bool, handler: int, badHandler: bool }
  var h: State
  pure def initial(policy: int): State = {
    policy: policy, borrower: true, publisher: true,
    sourceRoot: true, destinationRoot: false, payloadLive: true, exitKind: 0,
    installed: true, handler: 0, badHandler: false,
  }
  action initFixed = all {
    P::s' = P::initial("owned", false, false, false), h' = initial(0),
  }
  action initDroppedRoot = all {
    P::s' = P::initial("owned", false, false, false), h' = initial(1),
  }
  action initPayloadForgotten = all {
    P::s' = P::initial("owned", false, false, false), h' = initial(2),
  }
  action initHandlerForgotten = all {
    P::s' = P::initial("owned", false, false, false), h' = initial(3),
  }
  action initBorrowerForgotten = all {
    P::s' = P::initial("owned", false, false, false), h' = initial(4),
  }
  action protocolStep = all {
    any { P::readerEnter, P::readerLeave, P::readerCancel,
      P::request, P::close, P::drain }, h' = h,
  }
  action transferRoot = all {
    P::s.memory, h.payloadLive, h.sourceRoot, not(h.destinationRoot),
    P::s' = P::s, h' = { ...h, destinationRoot: true },
  }
  action leaveBorrower(kind: int): bool = all {
    h.borrower, not(P::s.registryGate),
    not(h.payloadLive) or h.destinationRoot or h.policy == 1,
    P::s' = P::s,
    h' = { ...h, borrower: false, sourceRoot: false, exitKind: kind },
  }
  action normalExit = all { h.policy != 1, leaveBorrower(1) }
  action nonlocalExit = leaveBorrower(2)
  action finishPublisher = all {
    h.publisher, not(P::s.registryGate),
    P::s' = P::s, h' = { ...h, publisher: false },
  }
  action consumePayload = all {
    P::s.memory, P::s.resource, h.payloadLive,
    h.sourceRoot or h.destinationRoot,
    P::s' = P::s, h' = { ...h, payloadLive: false },
  }
  // handler: 0 not delivered, 1 delivered before admission, 2 finished/cancelled.
  action deliverHandler = all {
    h.installed, h.handler == 0,
    P::s' = P::s, h' = { ...h, handler: 1 },
  }
  action uninstall = all {
    not(P::s.registryGate), h.installed,
    P::s' = P::s, h' = { ...h, installed: false,
      handler: if (h.handler == 0) 2 else h.handler },
  }
  // Environmental completion, not an effect of registry drain or uninstall.
  action finishHandler = all {
    h.handler == 1, P::s' = P::s,
    h' = { ...h, handler: 2,
      badHandler: h.badHandler or not(P::s.memory and P::s.resource) },
  }
  action releaseResources = all {
    not(h.borrower) or h.policy == 4,
    not(h.publisher),
    not(h.payloadLive) or h.policy == 2,
    not(h.installed), h.handler == 2 or h.policy == 3,
    P::release, h' = h,
  }
  action reclaim = all { P::reclaim, h' = h }
  val rooted = not(h.payloadLive) or
    (P::s.memory and P::s.resource and (h.sourceRoot or h.destinationRoot))
  val externalQuiet = P::s.resource or
    (not(h.installed) and h.handler == 2 and not(h.borrower) and not(h.publisher))
  val safe = P::safe and rooted and externalQuiet and not(h.badHandler)
  val terminal = P::terminal and not(h.payloadLive) and not(h.borrower) and
    not(h.publisher) and not(h.installed) and h.handler == 2
  action finished = all { terminal, P::s' = P::s, h' = h }
  action step = any { protocolStep, transferRoot, normalExit, nonlocalExit,
    finishPublisher, consumePayload, deliverHandler, uninstall, finishHandler,
    releaseResources, reclaim, finished }
  // Finite environment: an already delivered handler eventually completes.
  // Not proof of arbitrary host progress, physical GC or C memory ordering.
  temporal completion = weakFair(step, Set((P::s, h))).implies(eventually(terminal))
  action closeAdmission = all { P::request, h' = h }
  action closeRegistry = all { P::close, h' = h }
  run normalRootHandoffTest = initFixed.then(closeAdmission).then(closeRegistry)
    .then(transferRoot).then(normalExit).expect(rooted and h.exitKind == 1)
  run nonlocalRootHandoffTest = initFixed.then(closeAdmission).then(closeRegistry)
    .then(transferRoot).then(nonlocalExit).expect(rooted and h.exitKind == 2)
}
