module interrupt_requester_cancel_schedules {
  import interrupt_requester_cancel_composition as C from "./interrupt_requester_cancel_composition"

  run gcBeforeCancelThenThrowTest = C::initFixed
    .then(C::extractStep).then(C::acquireStep).then(C::propagateStep)
    .then(C::beginCallback).then(C::collect).then(C::requestCancel)
    .then(C::unlinkWaiter).then(C::commitCancel).then(C::throwCallback)
    .then(C::protocol)
    .expect(C::safe and C::terminal and C::requester.canceled and
            C::requester.callback == 3 and not(C::requester.woken))

  run cancelThenGcThenThrowTest = C::initFixed
    .then(C::extractStep).then(C::acquireStep).then(C::propagateStep)
    .then(C::beginCallback).then(C::requestCancel).then(C::unlinkWaiter)
    .then(C::commitCancel).then(C::collect).then(C::throwCallback)
    .then(C::protocol)
    .expect(C::safe and C::terminal and C::requester.canceled and
            C::requester.callback == 3 and not(C::requester.woken))

  run cancelThenGcThenReturnTest = C::initFixed
    .then(C::extractStep).then(C::acquireStep).then(C::propagateStep)
    .then(C::beginCallback).then(C::requestCancel).then(C::unlinkWaiter)
    .then(C::commitCancel).then(C::collect).then(C::returnCallback)
    .then(C::protocol)
    .expect(C::safe and C::terminal and C::requester.canceled and
            C::requester.callback == 2 and not(C::requester.woken))

  run cancelThenGcThenTargetTerminationTest = C::initFixed
    .then(C::extractStep).then(C::acquireStep).then(C::propagateStep)
    .then(C::beginCallback).then(C::requestCancel).then(C::unlinkWaiter)
    .then(C::commitCancel).then(C::collect).then(C::terminateTarget)
    .then(C::protocol)
    .expect(C::safe and C::terminal and C::requester.canceled and
            C::requester.callback == 3 and not(C::requester.woken))
}
