module native_compiler_options_correspondence {
  // A logged command permits investigation, never native correctness admission.
  type State = { oldLevel: int, newLevel: int, archiveBound: bool,
    sourceBound: bool, producerBound: bool, commandReviewed: bool,
    causeReviewed: bool, budgetBound: bool, phase: str, category: str,
    used: bool, bypass: bool }
  var s: State
  pure def initial(bypass: bool): State = {
    oldLevel: 1, newLevel: 0, archiveBound: true, sourceBound: true,
    producerBound: true, commandReviewed: true, causeReviewed: true,
    budgetBound: true, phase: "c-to-dynamic-module", category: "budget",
    used: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  action alter = all { not(s.used), any {
    s' = { ...s, oldLevel: 0 }, s' = { ...s, newLevel: 2 },
    s' = { ...s, archiveBound: false }, s' = { ...s, sourceBound: false },
    s' = { ...s, producerBound: false }, s' = { ...s, commandReviewed: false },
    s' = { ...s, causeReviewed: false }, s' = { ...s, budgetBound: false },
    s' = { ...s, phase: "scheme-to-c" }, s' = { ...s, category: "assertion" }
  } }
  val bound = s.newLevel >= 0 and s.newLevel < s.oldLevel and s.oldLevel <= 3 and
    s.archiveBound and s.sourceBound and s.producerBound and s.commandReviewed and
    s.causeReviewed and s.budgetBound and s.phase == "c-to-dynamic-module" and
    s.category == "budget"
  action use = all { not(s.used), bound or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { alter, use, hold }
  val safe = not(s.used) or bound
  run reviewedCommandTest = init.then(use).then(all { assert(safe), assert(s.used), s' = s })
  run sourceDriftControlTest = initBypass.then(s' = { ...s, sourceBound: false })
    .then(use).then(all { assert(not(safe)), s' = s })
  run missingAssociationControlTest = initBypass.then(s' = { ...s, commandReviewed: false })
    .then(use).then(all { assert(not(safe)), s' = s })
  run wrongPhaseControlTest = initBypass.then(s' = { ...s, phase: "scheme-to-c" })
    .then(use).then(all { assert(not(safe)), s' = s })
}
