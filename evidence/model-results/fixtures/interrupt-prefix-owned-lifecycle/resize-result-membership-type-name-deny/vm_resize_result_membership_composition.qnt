module vm_resize_result_membership_composition {
  import sync_slot_retained_resources as S from "./sync_slot_retained_resources"
  
  // One retired slot, two incarnations. A successful join witnesses OS exit;
  // a failed join does not. One transient join failure is the progress bound,
  // not a guarantee supplied by POSIX or the current Gambit caller.
  type retire_State = { policy: int, flow: int, population: int, failedFirst: bool,
    joinOld: str, exited: int -> bool, gcDone: bool,
    badGc: bool, badReuse: bool }
  var retire_vm: retire_State
  pure def retire_initial(policy: int, failedFirst: bool): retire_State = {
    policy: policy, flow: 0, population: 2, failedFirst: failedFirst,
    joinOld: "waiting", exited: Map(0 -> false, 1 -> false), gcDone: false,
    badGc: false, badReuse: false,
  }
  action retire_initFixed = {
    nondet failedFirst = Set(false, true).oneOf()
    all { retire_vm' = retire_initial(0, failedFirst), S::s' = S::initial(0) }
  }
  action retire_initIgnoredJoinGc = all {
    retire_vm' = retire_initial(1, true), S::s' = S::initial(0),
  }
  action retire_initIgnoredJoinReuse = all {
    retire_vm' = retire_initial(2, true), S::s' = S::initial(0),
  }
  action retire_initJoinOnlyCleanup = all {
    retire_vm' = retire_initial(3, false), S::s' = S::initial(3),
  }
  action retire_publishReducedPopulation = all {
    retire_vm.flow == 0,
    retire_vm' = { ...retire_vm, flow: 1, population: 1 }, S::s' = S::s,
  }
  action retire_senderStep = all {
    retire_vm.flow > 0, retire_vm.flow < 6,
    any { S::lock, S::publish, S::unlock, S::signal }, retire_vm' = retire_vm,
  }
  action retire_receiverStep = all {
    retire_vm.flow > 0, retire_vm.flow < 6,
    any { S::receiveOld, S::childExit, S::receiveNew, S::newChildExit },
    retire_vm' = retire_vm,
  }
  action retire_threadExit = {
    nondet g = Set(0, 1).oneOf()
    all {
      not(retire_vm.exited.get(g)),
      (g == 0 and S::s.phase == 2) or (g == 1 and S::s.phase == 5),
      retire_vm' = { ...retire_vm, exited: retire_vm.exited.set(g, true) }, S::s' = S::s,
    }
  }
  action retire_joinOld = all {
    retire_vm.flow == 1, retire_vm.joinOld == "waiting", S::s.sender.get(0) >= 2,
    retire_vm.failedFirst or retire_vm.exited.get(0),
    retire_vm' = { ...retire_vm,
      joinOld: if (retire_vm.failedFirst) "failed" else "ok",
      flow: if (retire_vm.failedFirst and retire_vm.policy == 0) 1 else 2 },
    S::s' = S::s,
  }
  action retire_recoverJoin = all {
    retire_vm.flow == 1, retire_vm.joinOld == "failed", retire_vm.policy == 0, retire_vm.exited.get(0),
    retire_vm' = { ...retire_vm, joinOld: "ok", flow: 2 }, S::s' = S::s,
  }
  action retire_nextGc = all {
    retire_vm.flow == 2, not(retire_vm.gcDone),
    retire_vm' = { ...retire_vm, gcDone: true,
      badGc: retire_vm.badGc or S::s.phase < 2 }, S::s' = S::s,
  }
  action retire_reuseSlot = all {
    retire_vm.flow == 2, retire_vm.gcDone, S::joinAndReuse,
    retire_vm' = { ...retire_vm, flow: 3, population: 2,
      badReuse: retire_vm.badReuse or not(retire_vm.exited.get(0)) or retire_vm.joinOld != "ok" },
  }
  action retire_joinNew = all {
    retire_vm.flow == 3, S::s.phase == 5, retire_vm.exited.get(1),
    retire_vm' = { ...retire_vm, flow: 4, population: 1 }, S::s' = S::s,
  }
  action retire_sealVm = all {
    retire_vm.flow == 4, S::sealVmAdmission, retire_vm' = { ...retire_vm, flow: 5 },
  }
  // Counterexample: joining the retiring receiver is not sender-tail drain.
  action retire_sealAfterJoinOnly = all {
    retire_vm.policy == 3, retire_vm.flow == 2, S::s.phase == 2,
    retire_vm' = { ...retire_vm, flow: 5 }, S::s' = { ...S::s, phase: 6 },
  }
  action retire_cleanupVm = all {
    retire_vm.flow == 5, S::destroyVmResources,
    retire_vm' = { ...retire_vm, flow: 6, population: 0 },
  }
  val retire_populationSafe = not(retire_vm.badGc)
  val retire_reuseSafe = not(retire_vm.badReuse)
  val retire_cleanupSafe = S::resourceSafe
  val retire_safe = retire_populationSafe and retire_reuseSafe and S::safe
  val retire_terminal = retire_vm.flow == 6 and S::terminal
  action retire_finished = all { retire_terminal, retire_vm' = retire_vm, S::s' = S::s }
  action retire_step = any { retire_publishReducedPopulation, retire_senderStep, retire_receiverStep,
    retire_threadExit, retire_joinOld, retire_recoverJoin, retire_nextGc, retire_reuseSlot, retire_joinNew, retire_sealVm,
    retire_sealAfterJoinOnly, retire_cleanupVm, retire_finished }
  temporal retire_progress = always(retire_terminal or enabled(retire_step)) and
    weakFair(retire_step, Set((retire_vm, S::s))).implies(eventually(retire_terminal))
  action retirementHold = all { retire_vm' = retire_vm, S::s' = S::s }
  import resize_result_distribution as R from "./resize_result_distribution"
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
      retire_vm' = retire_initial(0, failedFirst), S::s' = S::initial(0),
      R::reply' = R::initial("tagged-acknowledged", 2, requester1, requester2,
        if (failedFirst) 1 else 0, 0),
    }
  }
  action initLocalResult = all {
    control' = { policy: 1, phase: 0 },
    retire_vm' = retire_initial(0, true), S::s' = S::initial(0),
    R::reply' = R::initial("local-result", 2, 1, 1, 1, 0),
  }
  action initStaleMembership = all {
    control' = { policy: 2, phase: 0 },
    retire_vm' = retire_initial(0, false), S::s' = S::initial(0),
    R::reply' = R::initial("tagged-acknowledged", 2, 1, 1, 0, 0),
  }
  action initPublishUndrained = all {
    control' = { policy: 3, phase: 0 },
    retire_vm' = retire_initial(1, true), S::s' = S::initial(0),
    R::reply' = R::initial("tagged-acknowledged", 2, 1, 1, 1, 0),
  }
  action retirementStep = all {
    any { retire_publishReducedPopulation, retire_senderStep, retire_threadExit,
      retire_joinOld, retire_recoverJoin },
    R::reply' = R::reply, control' = control,
  }
  action receiverStep = all {
    // The new processor cannot leave startup and run its body before the
    // growth result has been consumed by the whole committed population.
    S::s.phase != 4 or R::terminal,
    retire_receiverStep, R::reply' = R::reply, control' = control,
  }
  action beginFirstResult = all {
    control.phase == 0, retire_vm.flow == 2,
    control' = { ...control, phase: 1 }, retirementHold, R::reply' = R::reply,
  }
  action resultStep = all {
    control.phase == 1 or (control.phase == 3 and S::s.phase >= 4),
    any { R::executeLocal, R::publish, R::returnResult },
    control' = control, retirementHold,
  }
  action nextGc = all {
    control.phase == 1, R::reply.returned == R::nodes,
    retire_nextGc, R::reply' = R::reply, control' = control,
  }
  action nextRequestAndGrow = all {
    control.phase == 1, R::reply.returned == R::nodes,
    retire_reuseSlot, R::nextRequest,
    control' = { ...control, phase: 2 },
  }
  action prepareGrowthMembership = all {
    control.phase == 2,
    R::reply' = { ...R::reply, population: if (control.policy == 2) 2 else 3 },
    control' = { ...control, phase: 3 }, retirementHold,
  }
  action shutdownStep = all {
    control.phase == 3, R::terminal,
    any { retire_joinNew, retire_sealVm, retire_cleanupVm },
    R::reply' = R::reply, control' = control,
  }
  val resultSafe = R::resultSafe
  val membershipSafe = control.phase != 3 or R::reply.population == 3
  val publicationRetirementSafe = not(R::reply.ready) or retire_vm.joinOld == "ok"
  val safe = R::safe and retire_safe and membershipSafe and publicationRetirementSafe
  val terminal = retire_terminal and R::terminal
  action finished = all {
    terminal, control' = control, retirementHold, R::reply' = R::reply,
  }
  action step = any { retirementStep, receiverStep, beginFirstResult, resultStep,
    nextGc, nextRequestAndGrow, prepareGrowthMembership, shutdownStep, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set((control, (retire_vm, S::s), R::reply))).implies(eventually(terminal))
}
