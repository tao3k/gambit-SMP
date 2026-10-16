module native_compiler_configuration_correspondence {
  // Embedded configuration is evidence of build inputs, not a past invocation.
  type State = { imageBound: bool, identityBound: bool, currentBound: bool,
    scopeBound: bool, reviewed: bool, flagsEnabled: bool, oldLevel: int,
    newLevel: int, originalBudget: int, requestedBudget: int, category: str,
    mode: str, commandClaimed: bool, driverClaimed: bool,
    runtimeClaimed: bool, used: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    imageBound: true, identityBound: true, currentBound: true, scopeBound: true,
    reviewed: true, flagsEnabled: true, oldLevel: 1, newLevel: 0,
    originalBudget: 3, requestedBudget: 3, category: "budget", mode: "gsc",
    commandClaimed: false, driverClaimed: false, runtimeClaimed: false,
    used: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  action alter = all { not(s.used), any {
    s' = { ...s, imageBound: false }, s' = { ...s, identityBound: false },
    s' = { ...s, currentBound: false }, s' = { ...s, scopeBound: false },
    s' = { ...s, reviewed: false }, s' = { ...s, flagsEnabled: false },
    s' = { ...s, oldLevel: 0 }, s' = { ...s, newLevel: 2 },
    s' = { ...s, requestedBudget: 4 }, s' = { ...s, category: "assertion" },
    s' = { ...s, mode: "gsi" }, s' = { ...s, commandClaimed: true },
    s' = { ...s, driverClaimed: true }, s' = { ...s, runtimeClaimed: true }
  } }
  val evidenceBound = s.imageBound and s.identityBound and s.currentBound and
    s.scopeBound and s.reviewed and s.flagsEnabled
  val boundary = not(s.commandClaimed) and not(s.driverClaimed) and not(s.runtimeClaimed)
  val boundedInvestigation = s.category == "budget" and s.mode == "gsc" and
    s.newLevel >= 0 and s.newLevel < s.oldLevel and s.oldLevel <= 3 and
    s.requestedBudget > 0 and s.requestedBudget <= s.originalBudget
  val bound = evidenceBound and boundary and boundedInvestigation
  action use = all { not(s.used), bound or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { alter, use, hold }
  val safe = not(s.used) or bound
  run imageConfigurationTest = init.then(use).then(all { assert(safe), assert(s.used), s' = s })
  run wrongImageControlTest = initBypass.then(s' = { ...s, imageBound: false })
    .then(use).then(all { assert(not(safe)), s' = s })
  run inventedCommandControlTest = initBypass.then(s' = { ...s, commandClaimed: true })
    .then(use).then(all { assert(not(safe)), s' = s })
  run expandedBudgetControlTest = initBypass.then(s' = { ...s, requestedBudget: 4 })
    .then(use).then(all { assert(not(safe)), s' = s })
}
