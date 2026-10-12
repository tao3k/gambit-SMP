module vm_resize_result_membership_composition {
  import vm_retirement_join_composition as V from "./vm_retirement_join_composition"
  import resize_result_distribution as R from "./resize_result_distribution"
  import sync_slot_retained_resources as S from "./sync_slot_retained_resources"
  // V owns root plus the retiring slot; one extra retained processor is the
  // nonzero requester. Actual population is V's local population plus that peer.
  // Shrink 3->2 then grow 2->3. Status includes a recovered first join error.
  type State = { policy: int, phase: int }
  var control: State
  action initFixed = {
    nondet requester1 = Set(0, 1).oneOf()
    nondet requester2 = Set(0, 1).oneOf()
    nondet failedFirst = Set(false, true).oneOf()
    all {
      control' = { policy: 0, phase: 0 },
      V::vm' = V::initial(0, failedFirst), S::s' = S::initial(0),
      R::reply' = R::initial("tagged-acknowledged", 2, requester1, requester2,
        if (failedFirst) 1 else 0, 0),
    }
  }
  action initLocalResult = all {
    control' = { policy: 1, phase: 0 },
    V::vm' = V::initial(0, true), S::s' = S::initial(0),
    R::reply' = R::initial("local-result", 2, 1, 1, 1, 0),
  }
  action initStaleMembership = all {
    control' = { policy: 2, phase: 0 },
    V::vm' = V::initial(0, false), S::s' = S::initial(0),
    R::reply' = R::initial("tagged-acknowledged", 2, 1, 1, 0, 0),
  }
  action initPublishUndrained = all {
    control' = { policy: 3, phase: 0 },
    V::vm' = V::initial(1, true), S::s' = S::initial(0),
    R::reply' = R::initial("tagged-acknowledged", 2, 1, 1, 1, 0),
  }
  action retirementStep = all {
    any { V::publishReducedPopulation, V::senderStep, V::threadExit,
      V::joinOld, V::recoverJoin },
    R::reply' = R::reply, control' = control,
  }
  action receiverStep = all {
    // The new processor cannot leave startup and run its body before the
    // growth result has been consumed by the whole committed population.
    V::slotPhase != 4 or R::terminal,
    V::receiverStep, R::reply' = R::reply, control' = control,
  }
  action beginFirstResult = all {
    control.phase == 0, V::vm.flow == 2,
    control' = { ...control, phase: 1 }, V::hold, R::reply' = R::reply,
  }
  action resultStep = all {
    control.phase == 1 or (control.phase == 3 and V::slotPhase >= 4),
    any { R::executeLocal, R::publish, R::returnResult },
    control' = control, V::hold,
  }
  action nextGc = all {
    control.phase == 1, R::reply.returned == R::nodes,
    V::nextGc, R::reply' = R::reply, control' = control,
  }
  action nextRequestAndGrow = all {
    control.phase == 1, R::reply.returned == R::nodes,
    V::reuseSlot, R::nextRequest,
    control' = { ...control, phase: 2 },
  }
  action prepareGrowthMembership = all {
    control.phase == 2,
    R::reply' = { ...R::reply, population: if (control.policy == 2) 2 else 3 },
    control' = { ...control, phase: 3 }, V::hold,
  }
  action shutdownStep = all {
    control.phase == 3, R::terminal,
    any { V::joinNew, V::sealVm, V::cleanupVm },
    R::reply' = R::reply, control' = control,
  }
  val resultSafe = R::resultSafe
  val membershipSafe = control.phase != 3 or R::reply.population == 3
  val publicationRetirementSafe = not(R::reply.ready) or V::vm.joinOld == "ok"
  val sharedSlotIdentity = V::slotPhase == S::s.phase
  val safe = R::safe and V::safe and membershipSafe and publicationRetirementSafe and sharedSlotIdentity
  val terminal = V::terminal and R::terminal
  action finished = all {
    terminal, control' = control, V::hold, R::reply' = R::reply,
  }
  action step = any { retirementStep, receiverStep, beginFirstResult, resultStep,
    nextGc, nextRequestAndGrow, prepareGrowthMembership, shutdownStep, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set((control, V::fairnessState, R::reply))).implies(eventually(terminal))
}
