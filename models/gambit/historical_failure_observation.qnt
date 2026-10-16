module historical_failure_observation {
  type Binding = { retained: bool, bytes: bool, fields: bool, budget: bool, reviewed: bool,
                   loaded: bool, used: bool, bypass: bool }
  var s: Binding
  pure def initial(bypass: bool): Binding = {
    retained: true, bytes: true, fields: true, budget: true, reviewed: false,
    loaded: false, used: false, bypass: bypass,
  }
  action init = s' = initial(false)
  action initBypass = s' = initial(true)
  val bound = s.retained and s.bytes and s.fields and s.budget and s.reviewed
  action load = all { not(s.loaded), s' = { ...s, loaded: true } }
  action review = all { s.loaded, not(s.reviewed), s' = { ...s, reviewed: true } }
  action driftBytes = all { not(s.used), s.bytes, s' = { ...s, bytes: false } }
  action driftFields = all { not(s.used), s.fields, s' = { ...s, fields: false } }
  action expandBudget = all { not(s.used), s.budget, s' = { ...s, budget: false } }
  action dropOriginal = all { not(s.used), s.retained, s' = { ...s, retained: false } }
  // Loading recovered data never makes it execution authority. Recheck at use.
  action use = all { s.loaded, not(s.used), bound or s.bypass, s' = { ...s, used: true } }
  action hold = s' = s
  action step = any { load, review, driftBytes, driftFields, expandBudget, dropOriginal, use, hold }
  val safe = s.used.implies(bound)
  run checkedVersionTest = init.then(load).then(review).then(use)
    .then(all { assert(s.used), assert(safe), s' = s })
  run loadedIsNotReviewedTest = init.then(load)
    .then(all { assert(not(bound)), assert(not(s.used)), assert(safe), s' = s })
  run postReviewDriftTest = init.then(load).then(review).then(driftBytes)
    .then(all { assert(not(bound)), assert(safe), s' = s })
  run bypassControlTest = initBypass.then(load).then(dropOriginal).then(use)
    .then(all { assert(not(safe)), s' = s })
}
