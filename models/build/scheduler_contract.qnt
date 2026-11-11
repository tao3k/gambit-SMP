module scheduler_contract {
  // Unit-weight, two-credit slice. Parent/child budgets and fairness stay open.
  import incremental_build.* from "./incremental_build"
  run twoReadyJobsTest = initMacro.then(start(0)).then(finish(0)).then(publish(0))
    .then(start(1)).then(finish(1)).then(publish(1)).then(start(2)).then(start(3))
    .expect(safe and s.used == 2)
  run cancelDoesNotRefundRunningTest = initMacro.then(start(0)).then(cancel)
    .expect(safe and s.used == 1 and s.phase.get(0) == 1)
  run settledCancelRefundTest = initMacro.then(start(0)).then(cancel).then(finish(0)).then(discard(0))
    .expect(safe and s.used == 0 and s.phase.get(0) == 4)
  run thirdJobControlTest = initOverBudget.then(start(0)).then(finish(0)).then(publish(0))
    .then(start(1)).then(finish(1)).then(publish(1)).then(start(2)).then(start(3)).then(start(4))
    .expect(not(budgetSafe) and accountingSafe and s.used == 3)
}
