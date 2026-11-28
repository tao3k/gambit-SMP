// Guard publication for one generated write group. The poll reads stack_trip.
// The installed header copies that trip from context.stack_limit at refresh.
// A write into the processor field alone does not move the trip. The heap
// numbers are the measured half: past 65536, hard end 65535, soft limit
// 9221 words before past, fudge 9222. This is finite arithmetic, not a
// sealed GSI and not the 295/300 campaign.
module guard_publication {
  pure def half: int = 65536
  pure def fudge: int = 9222
  pure def breakWords: int = 4

  pure def poll(fp: int, trip: int): bool = fp < trip
  pure def burst(soft: int, words: int): int = soft + words
  pure def pushBreak(fp: int): int = fp - breakWords
  pure def stackInside(fp: int): bool = fp >= 0
  pure def heapInside(cursor: int, hard: int, past: int): bool =
    0 <= cursor and cursor <= hard and hard <= past

  run staleTripMissesRaisedContextLimitTest =
    assert(poll(10, 100) and not(poll(10, 0)))

  run refreshedTripUsesContextLimitTest =
    assert(poll(4, fudge) and not(poll(fudge, fudge)))

  run processorFieldIsNotThePollTripTest =
    assert(poll(4, fudge) and not(poll(4, 0)))

  run breakFromBaseLeavesHalfTest =
    assert(pushBreak(0) == -4 and not(stackInside(pushBreak(0))))

  run breakWithItsOwnRoomStaysInsideTest =
    assert(pushBreak(breakWords) == 0 and stackInside(pushBreak(breakWords)))

  run measuredHeapBurstLeavesHalfTest =
    assert(burst(half - 9221, fudge) == half + 1 and
           not(heapInside(burst(half - 9221, fudge), half - 1, half)))

  run fudgeBeforeHardEndStaysInsideTest =
    assert(heapInside(burst((half - 1) - fudge, fudge), half - 1, half) and
           burst((half - 1) - fudge, fudge) == half - 1)

  run censusRejectsFourWordsBelowTest =
    assert(not(stackInside(-4)) and stackInside(0))

  type Guard = {
    contextLimit: int,
    processorLimit: int,
    trip: int,
    fp: int,
    hp: int,
    hard: int,
    refreshed: bool,
    spins: int,
    allocated: bool
  }

  var g: Guard

  action init = g' = {
    contextLimit: half, processorLimit: 0, trip: 0, fp: 4,
    hp: half - 9221, hard: half - 1, refreshed: false, spins: 0,
    allocated: false
  }

  action raiseContextLimit = all {
    not(g.allocated),
    g' = { ...g, contextLimit: fudge, refreshed: false }
  }

  action writeProcessorField = all {
    not(g.allocated),
    g' = { ...g, processorLimit: 1 }
  }

  action refreshTrip = all {
    g' = { ...g, trip: g.contextLimit, refreshed: true }
  }

  val cursorInside =
    stackInside(g.fp) and heapInside(burst(g.hp, fudge), g.hard, half)

  action allocateDescriptor = all {
    g.refreshed and cursorInside and not(poll(g.fp, g.trip)),
    g' = { ...g, allocated: true }
  }

  action collectWhileOutside = all {
    not(cursorInside) and not(g.allocated),
    g' = { ...g, spins: g.spins + 1 }
  }

  val admitted =
    g.allocated and g.refreshed and g.trip == g.contextLimit and
    g.spins == 0 and cursorInside

  run unrefreshedContextLimitDoesNotMoveTripTest =
    init.then(raiseContextLimit)
      .expect(g.contextLimit == fudge and g.trip == 0 and not(g.refreshed) and
              not(g.allocated))

  run refreshCopiesContextLimitTest =
    init.then(raiseContextLimit).then(writeProcessorField).then(refreshTrip)
      .expect(g.refreshed and g.trip == g.contextLimit and
              g.trip != g.processorLimit and not(g.allocated))

  run outsideCursorCannotAllocateTest =
    init.then(raiseContextLimit).then(refreshTrip)
      .expect(not(cursorInside) and not(g.allocated))

  run repeatedCollectionOutsideIsNotAGrantTest =
    init.then(raiseContextLimit).then(refreshTrip)
      .then(collectWhileOutside).then(collectWhileOutside)
      .expect(g.spins == 2 and not(g.allocated) and not(admitted))

  action repairHeap = all {
    g.refreshed and stackInside(g.fp),
    g' = { ...g, hp: 0, hard: half }
  }

  action standAtGuard = all {
    g.refreshed and stackInside(g.trip),
    g' = { ...g, fp: g.trip }
  }

  run repairedHeapAllocatesOnceTest =
    init.then(raiseContextLimit).then(refreshTrip).then(repairHeap)
      .then(standAtGuard).then(allocateDescriptor)
      .expect(admitted and g.allocated and g.spins == 0)
}
