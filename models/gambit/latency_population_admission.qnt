module latency_population_admission {
  // Two owners and two rounds abstract exact planned trajectory coverage.
  var a: int
  var b: int
  var failed: bool
  var stable: bool
  var published: bool
  var policy: str
  action init = all { a' = 0, b' = 0, failed' = false, stable' = true,
    published' = false, policy' = "complete" }
  action initSurvivors = all { a' = 0, b' = 0, failed' = false, stable' = true,
    published' = false, policy' = "survivors" }
  action sampleA = all { not(failed), not(published), a < 2,
    a' = a + 1, b' = b, failed' = failed, stable' = stable,
    published' = published, policy' = policy }
  action sampleB = all { not(failed), not(published), b < 2,
    a' = a, b' = b + 1, failed' = failed, stable' = stable,
    published' = published, policy' = policy }
  action timeout = all { not(published),
    a' = a, b' = b, failed' = true, stable' = stable,
    published' = published, policy' = policy }
  action drift = all { not(published),
    a' = a, b' = b, failed' = failed, stable' = false,
    published' = published, policy' = policy }
  action publish = all { not(published),
    (policy == "survivors" and a + b > 0) or
    (policy == "complete" and a == 2 and b == 2 and not(failed) and stable),
    a' = a, b' = b, failed' = failed, stable' = stable,
    published' = true, policy' = policy }
  action hold = all { a' = a, b' = b, failed' = failed, stable' = stable,
    published' = published, policy' = policy }
  action step = any { sampleA, sampleB, timeout, drift, publish, hold }
  val safe = not(published) or (a == 2 and b == 2 and not(failed) and stable)
  run survivorControlTest = initSurvivors.then(sampleA).then(timeout).then(publish)
    .then(all { assert(not(safe)), hold })
  run completePopulationTest = init.then(sampleA).then(sampleB).then(sampleA)
    .then(sampleB).then(publish).then(all { assert(safe), assert(published), hold })
  run partialTimeoutTest = init.then(sampleA).then(sampleB).then(timeout)
    .then(all { assert(safe), assert(not(published)), assert(a + b == 2), hold })
  run sourceDriftTest = init.then(sampleA).then(sampleB).then(sampleA)
    .then(sampleB).then(drift).then(all { assert(safe), assert(not(published)), hold })
}
