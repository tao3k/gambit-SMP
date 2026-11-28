module gc_work_contract {
  // Existing object/phase model, fixed relocating stopped-mutator cohort.
  import CollectionContract(Relocate = true, Mutation = "none").* from "../library/gc/CollectionContract"
  action injectedEarlyFinish = all { not(s.done), s.claimed, s' = { ...s, done: true } }
  run completeWorkTest = init.then(claim).then(redirect(1)).then(redirect(2)).then(initialize)
    .then(publish).then(acquire).then(scan).then(finish).expect(Safe and s.done)
  run rescanBeforeFinishTest = init.then(claim).then(redirect(1)).then(redirect(2)).then(initialize)
    .then(publish).then(acquire).then(scan).then(rescan).then(acquire).then(scan).then(finish)
    .expect(Safe and s.done and s.rescans == 1)
  run privateDebtRetainedTest = init.then(claim).expect(Safe and s.privateWork and not(s.done))
  run earlyFinishControlTest = init.then(claim).then(redirect(1)).then(redirect(2))
    .then(injectedEarlyFinish).expect(not(closureSafe))
}
