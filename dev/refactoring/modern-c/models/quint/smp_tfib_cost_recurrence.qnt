module smp_tfib_cost_recurrence {
  // Conditional source-level arithmetic, not a measured execution trace.
  // Every completed tfib node calls short-delay once; busy-sleep enters for
  // every integer from the nonnegative initial value down through zero.
  type State = { n: int, previous: int, current: int }
  var s: State
  action init = s' = { n: 1, previous: 1, current: 1 }
  action advance = all { s.n < 15,
    s' = { n: s.n + 1, previous: s.current,
      current: 1 + s.previous + s.current } }
  pure def busyCalls(delay: int): int = delay + 1
  pure def rtePayloadBytes(calls: int): int = calls * 4 * 8
  pure def rteAccountedBytes(calls: int): int = 2 * rtePayloadBytes(calls)
  // A linear projection under the stated sample-rate assumption. Compare
  // products so truncation cannot accidentally admit a workload.
  pure def sampleRateFits(sampleMicros: int, samples: int, totalDelays: int,
                          budgetMicros: int): bool =
    sampleMicros * totalDelays <= budgetMicros * samples
  // The two populations run in sequence. Within p2 these shards overlap.
  pure def maxMicros(a: int, b: int): int = if (a >= b) a else b
  pure def remainingBeforeP1(remainingAtP2Launch: int, interrupt: int,
                             interrupt2: int, tfibAndTerminate: int): int =
    remainingAtP2Launch - maxMicros(maxMicros(interrupt, interrupt2), tfibAndTerminate)
  // Round the launch budget up and completed durations down. Give the
  // censored shard zero cost only for this optimistic historical bound.
  pure val historicalP1CeilingMicros =
    remainingBeforeP1(290993032, 97067252, 188382800, 0)
  run leafCountTest = init.expect(s.current == 1 and s.previous == 1)
  run twoCountTest = init.then(advance).expect(s.n == 2 and s.current == 3)
  run busyZeroTest = init.expect(busyCalls(0) == 1)
  run fifteenCountTest = init
    .then(advance).then(advance).then(advance).then(advance).then(advance)
    .then(advance).then(advance).then(advance).then(advance).then(advance)
    .then(advance).then(advance).then(advance).then(advance)
    .expect(s.n == 15 and s.current == 1973 and
      s.current * 5000 == 9865000 and
      s.current * 5000 * busyCalls(6000) == 59199865000)
  run wrongLeafControlTest = init.expect(not(s.current == 0))
  run wrongDelayControlTest = init.expect(not(busyCalls(6000) == 6000))
  run sampleRateUnitControlTest = assert(sampleRateFits(1000, 1, 2, 2000))
  run fastestP1NumericSampleExceedsBudgetTest =
    assert(not(sampleRateFits(687690, 1000, 9865000, 295000000)))
  run fastestP2NumericSampleExceedsBudgetTest =
    assert(not(sampleRateFits(740476, 1000, 9865000, 295000000)))
  run originalP2OverlapLeavesP1CeilingTest =
    assert(historicalP1CeilingMicros == 102610232)
  run p1CannotReuseFullEnvelopeControlTest =
    assert(sampleRateFits(200000000, 9865000, 9865000, 295000000) and
      not(sampleRateFits(200000000, 9865000, 9865000, historicalP1CeilingMicros)))
  run rteSemispaceAccountingTest =
    assert(rtePayloadBytes(6002000) == 192064000 and rteAccountedBytes(6002000) == 384128000)
  run busyPayloadProjectionTest =
    assert(rtePayloadBytes(59199865000) == 1894395680000)
  run treatingAccountedBytesAsPayloadRefusedTest =
    assert(rteAccountedBytes(6002000) != rtePayloadBytes(6002000))
}
