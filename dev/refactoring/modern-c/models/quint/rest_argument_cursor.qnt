// Refusal leaves the caller's next stack argument and the free-cursor
// sentinel unchanged, and it does not pop or write a pair. The numbers are
// the cut-arg measurement shape: tagged 4, 9 and 7, sentinel 1380275028.
// This is not a GSI trace and not the 295/300 campaign.
module rest_argument_cursor {
  pure def sentinel: int = 1380275028
  type Refusal = {
    cursor: int,
    entryArg: int,
    cutArg: int,
    heapWord: int,
    pops: int,
    writes: int
  }
  pure def held(cut: Refusal): bool =
    cut.entryArg == cut.cutArg and
    cut.heapWord == sentinel and
    cut.pops == 0 and
    cut.writes == 0

  run ordinaryArgumentHeldTest =
    assert(held({ cursor: 2, entryArg: 32, cutArg: 32,
                  heapWord: sentinel, pops: 0, writes: 0 }))
  run keyRestArgumentHeldTest =
    assert(held({ cursor: 2, entryArg: 72, cutArg: 72,
                  heapWord: sentinel, pops: 0, writes: 0 }))
  run restKeyArgumentHeldTest =
    assert(held({ cursor: 4, entryArg: 56, cutArg: 56,
                  heapWord: sentinel, pops: 0, writes: 0 }))
  run taggedCallArgumentsTest =
    assert(4 * 8 == 32 and 9 * 8 == 72 and 7 * 8 == 56)
  run cutArgMatchesEntryTest =
    assert(not(held({ cursor: 2, entryArg: 32, cutArg: 0,
                      heapWord: sentinel, pops: 0, writes: 0 })))
  run heapWordIsSentinelTest =
    assert(not(held({ cursor: 2, entryArg: 32, cutArg: 32,
                      heapWord: 0, pops: 0, writes: 0 })))
  run poppedCursorIsNotHeldTest =
    assert(not(held({ cursor: 1, entryArg: 32, cutArg: 32,
                      heapWord: sentinel, pops: 1, writes: 1 })))
}
