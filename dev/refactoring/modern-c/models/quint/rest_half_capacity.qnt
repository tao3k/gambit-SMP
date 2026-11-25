// A legal rest has at most 8192 arguments. Each emitted pair is 3 words.
// An empty half of 65536 words can hold that batch. One word less cannot.
// This is not a GSI trace.
module rest_half_capacity {
  pure def pairWords: int = 3
  pure def maxArgs: int = 8192
  pure def halfWords: int = 65536
  pure def fullBatch: int = maxArgs * pairWords
  pure def fits(words: int, room: int): bool = words >= 0 and words <= room

  run fullBatchFitsEmptyHalfTest =
    assert(fullBatch == 24576 and fits(fullBatch, halfWords))
  run oneWordShortOfBatchRefusedTest =
    assert(not(fits(fullBatch, fullBatch - 1)))
  run argumentLimitBelowHalfTest =
    assert(maxArgs < halfWords and pairWords * maxArgs < halfWords)
  pure def refused(words: int, room: int): bool =
    not(fits(words, room))
  // Only the capacity predicate is checked. No stores are represented here.
  // This 24576-word batch is not the ordinary 10-word rest admission.
  pure def ordinaryCompleteDemand: int = 10
  run shortCapacityPredicateOnlyTest =
    assert(refused(fullBatch, fullBatch - 1))
  run ordinaryTenIsNotTheMaxArgBatchTest =
    assert(ordinaryCompleteDemand != fullBatch and ordinaryCompleteDemand < halfWords)
}
