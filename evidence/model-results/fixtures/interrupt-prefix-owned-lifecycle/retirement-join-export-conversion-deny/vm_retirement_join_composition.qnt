module vm_retirement_join_composition {
  import sync_slot_retained_resources as S from "./sync_slot_retained_resources"
  export S.s
  // One retired slot, two incarnations. A successful join witnesses OS exit;
  // a failed join does not. One transient join failure is the progress bound,
  // not a guarantee supplied by POSIX or the current Gambit caller.
  type State = { policy: int, flow: int, population: int, failedFirst: bool,
    joinOld: str, exited: int -> bool, gcDone: bool,
    badGc: bool, badReuse: bool }
  var vm: State
  pure def initial(policy: int, failedFirst: bool): State = {
    policy: policy, flow: 0, population: 2, failedFirst: failedFirst,
    joinOld: "waiting", exited: Map(0 -> false, 1 -> false), gcDone: false,
    badGc: false, badReuse: false,
  }
  val initialSlot = S::initial(0)
  action hold = all { vm' = vm, S::s' = S::s }
  val slotPhase = S::s.phase
  val fairnessState = (vm, S::s)
  action initFixed = {
    nondet failedFirst = Set(false, true).oneOf()
    all { vm' = initial(0, failedFirst), S::s' = S::initial(0) }
  }
  action initIgnoredJoinGc = all {
    vm' = initial(1, true), S::s' = S::initial(0),
  }
  action initIgnoredJoinReuse = all {
    vm' = initial(2, true), S::s' = S::initial(0),
  }
  action initJoinOnlyCleanup = all {
    vm' = initial(3, false), S::s' = S::initial(3),
  }
  action publishReducedPopulation = all {
    vm.flow == 0,
    vm' = { ...vm, flow: 1, population: 1 }, S::s' = S::s,
  }
  action senderStep = all {
    vm.flow > 0, vm.flow < 6,
    any { S::lock, S::publish, S::unlock, S::signal }, vm' = vm,
  }
  action receiverStep = all {
    vm.flow > 0, vm.flow < 6,
    any { S::receiveOld, S::childExit, S::receiveNew, S::newChildExit },
    vm' = vm,
  }
  action threadExit = {
    nondet g = Set(0, 1).oneOf()
    all {
      not(vm.exited.get(g)),
      (g == 0 and S::s.phase == 2) or (g == 1 and S::s.phase == 5),
      vm' = { ...vm, exited: vm.exited.set(g, true) }, S::s' = S::s,
    }
  }
  action joinOld = all {
    vm.flow == 1, vm.joinOld == "waiting", S::s.sender.get(0) >= 2,
    vm.failedFirst or vm.exited.get(0),
    vm' = { ...vm,
      joinOld: if (vm.failedFirst) "failed" else "ok",
      flow: if (vm.failedFirst and vm.policy == 0) 1 else 2 },
    S::s' = S::s,
  }
  action recoverJoin = all {
    vm.flow == 1, vm.joinOld == "failed", vm.policy == 0, vm.exited.get(0),
    vm' = { ...vm, joinOld: "ok", flow: 2 }, S::s' = S::s,
  }
  action nextGc = all {
    vm.flow == 2, not(vm.gcDone),
    vm' = { ...vm, gcDone: true,
      badGc: vm.badGc or S::s.phase < 2 }, S::s' = S::s,
  }
  action reuseSlot = all {
    vm.flow == 2, vm.gcDone, S::joinAndReuse,
    vm' = { ...vm, flow: 3, population: 2,
      badReuse: vm.badReuse or not(vm.exited.get(0)) or vm.joinOld != "ok" },
  }
  action joinNew = all {
    vm.flow == 3, S::s.phase == 5, vm.exited.get(1),
    vm' = { ...vm, flow: 4, population: 1 }, S::s' = S::s,
  }
  action sealVm = all {
    vm.flow == 4, S::sealVmAdmission, vm' = { ...vm, flow: 5 },
  }
  // Counterexample: joining the retiring receiver is not sender-tail drain.
  action sealAfterJoinOnly = all {
    vm.policy == 3, vm.flow == 2, S::s.phase == 2,
    vm' = { ...vm, flow: 5 }, S::s' = { ...S::s, phase: 6 },
  }
  action cleanupVm = all {
    vm.flow == 5, S::destroyVmResources,
    vm' = { ...vm, flow: 6, population: 0 },
  }
  val populationSafe = not(vm.badGc)
  val reuseSafe = not(vm.badReuse)
  val cleanupSafe = S::resourceSafe
  val safe = populationSafe and reuseSafe and S::safe
  val terminal = vm.flow == 6 and S::terminal
  action finished = all { terminal, vm' = vm, S::s' = S::s }
  action step = any { publishReducedPopulation, senderStep, receiverStep,
    threadExit, joinOld, recoverJoin, nextGc, reuseSlot, joinNew, sealVm,
    sealAfterJoinOnly, cleanupVm, finished }
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set((vm, S::s))).implies(eventually(terminal))
}
