module vm_kernel_entry_lifecycle {
  // Two bounded VM participants, not a runtime CPU/thread constant.
  // Kernel, TLS and drain transitions must be refined to the linked producer.
  type VM = { phase: str, tls: bool, kernel: bool, permanentModule: bool,
    cohort: int, rootOwner: int, argumentOwner: int, gcDone: bool, quarantined: bool }
  var vms: int -> VM
  var bypass: bool
  pure def fresh(id: int): VM = { phase: "fresh", tls: false, kernel: false,
    permanentModule: true, cohort: 0, rootOwner: id, argumentOwner: id,
    gcDone: false, quarantined: false }
  action init = all { vms' = Map(1 -> fresh(1), 2 -> fresh(2)), bypass' = false }
  action initBypass = all { vms' = Map(1 -> fresh(1), 2 -> fresh(2)), bypass' = true }
  action construct(id: int): bool = all { vms.get(id).phase == "fresh",
    vms' = vms.set(id, { ...vms.get(id), phase: "constructed", cohort: 1 }), bypass' = bypass }
  action attach(id: int): bool = all { vms.get(id).phase == "constructed", not(vms.get(id).tls),
    vms' = vms.set(id, { ...vms.get(id), tls: true }), bypass' = bypass }
  action loadKernel(id: int): bool = all { vms.get(id).phase == "constructed",
    (vms.get(id).tls and vms.get(id).permanentModule and vms.get(id).argumentOwner == id) or bypass,
    vms' = vms.set(id, { ...vms.get(id), phase: "kernel", kernel: true }), bypass' = bypass }
  action startCohort(id: int): bool = all { vms.get(id).phase == "kernel",
    vms' = vms.set(id, { ...vms.get(id), phase: "running", cohort: 2 }), bypass' = bypass }
  action collect(id: int): bool = all { vms.get(id).phase == "running", not(vms.get(id).gcDone),
    vms' = vms.set(id, { ...vms.get(id), gcDone: true }), bypass' = bypass }
  action borrowRoot(id: int): bool = all { bypass, vms.get(id).phase == "running",
    vms.get(id).rootOwner == id,
    vms' = vms.set(id, { ...vms.get(id), rootOwner: 3-id }), bypass' = bypass }
  action borrowModule(id: int): bool = all { bypass, vms.get(id).phase == "constructed",
    vms.get(id).permanentModule,
    vms' = vms.set(id, { ...vms.get(id), permanentModule: false }), bypass' = bypass }
  action wrongArgument(id: int): bool = all { bypass, vms.get(id).phase == "constructed",
    vms.get(id).argumentOwner == id,
    vms' = vms.set(id, { ...vms.get(id), argumentOwner: 3-id }), bypass' = bypass }
  action drain(id: int): bool = all { vms.get(id).phase == "running", vms.get(id).gcDone,
    vms' = vms.set(id, { ...vms.get(id), phase: "drained", cohort: 0 }), bypass' = bypass }
  action failJoin(id: int): bool = all { vms.get(id).phase == "running", not(vms.get(id).quarantined),
    vms' = vms.set(id, { ...vms.get(id), phase: "retained", quarantined: true }), bypass' = bypass }
  action retire(id: int): bool = all { vms.get(id).phase == "drained" or
      (bypass and Set("running", "retained").contains(vms.get(id).phase)),
    vms' = vms.set(id, { ...vms.get(id), phase: "retired" }), bypass' = bypass }
  action hold = all { vms' = vms, bypass' = bypass }
  action step = {
    nondet id = Set(1, 2).oneOf()
    any { construct(id), attach(id), loadKernel(id), startCohort(id), collect(id),
      borrowRoot(id), borrowModule(id), wrongArgument(id), drain(id), failJoin(id), retire(id), hold }
  }
  val safe = Set(1, 2).forall(id => {
    val vm = vms.get(id)
    (vm.kernel implies vm.tls and vm.permanentModule and vm.argumentOwner == id) and vm.rootOwner == id and
      (vm.phase == "retired" implies vm.cohort == 0 and not(vm.quarantined))
  })
  val simultaneouslyThreaded = Set(1, 2).forall(id =>
    vms.get(id).phase == "running" and vms.get(id).cohort > 1)
  run independentCohortsTest = init.then(construct(1)).then(construct(2))
    .then(attach(1)).then(attach(2)).then(loadKernel(1)).then(loadKernel(2))
    .then(startCohort(1)).then(startCohort(2))
    .then(all { assert(simultaneouslyThreaded), assert(safe), vms' = vms, bypass' = bypass })
    .then(collect(1)).then(collect(2)).then(drain(1)).then(drain(2)).then(retire(1)).then(retire(2))
    .then(all { assert(safe), vms' = vms, bypass' = bypass })
  run missingTlsControlTest = initBypass.then(construct(1)).then(loadKernel(1))
    .then(all { assert(not(safe)), vms' = vms, bypass' = bypass })
  run borrowedModuleControlTest = initBypass.then(construct(1)).then(attach(1))
    .then(borrowModule(1)).then(loadKernel(1))
    .then(all { assert(not(safe)), vms' = vms, bypass' = bypass })
  run crossVmRootControlTest = initBypass.then(construct(1)).then(attach(1))
    .then(loadKernel(1)).then(startCohort(1)).then(borrowRoot(1))
    .then(all { assert(not(safe)), vms' = vms, bypass' = bypass })
  run wrongPstateArgumentControlTest = initBypass.then(construct(1)).then(attach(1))
    .then(wrongArgument(1)).then(loadKernel(1))
    .then(all { assert(not(safe)), vms' = vms, bypass' = bypass })
  run failedJoinRetainsOwnershipTest = init.then(construct(1)).then(attach(1))
    .then(loadKernel(1)).then(startCohort(1)).then(failJoin(1))
    .then(all { assert(safe), assert(vms.get(1).cohort == 2),
      assert(vms.get(1).phase == "retained"), vms' = vms, bypass' = bypass })
  run prematureCleanupControlTest = initBypass.then(construct(1)).then(attach(1))
    .then(loadKernel(1)).then(startCohort(1)).then(failJoin(1)).then(retire(1))
    .then(all { assert(not(safe)), vms' = vms, bypass' = bypass })
}
