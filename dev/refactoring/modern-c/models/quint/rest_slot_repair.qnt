// One rest refusal after a moving collection. Heap root words may change.
// Immediate words stay. The argument cursor is not popped. This is not a GSI trace.
module rest_slot_repair {
  type Slot = { heap: bool, word: int }
  type Cut = { kind: int, cursor: int, entered: bool }
  pure def moved(before: Slot, after: Slot): bool =
    before.heap and after.heap and before.word != after.word
  pure def stable(before: Slot, after: Slot): bool =
    not(before.heap) and before.word == after.word
  pure def refused(cut: Cut, remaining: int): bool =
    cut.kind == 1 and cut.cursor == remaining and not(cut.entered)

  run heapSlotRewrittenTest =
    assert(moved({ heap: true, word: 11 }, { heap: true, word: 19 }))
  run immediateSlotStableTest =
    assert(stable({ heap: false, word: 0 }, { heap: false, word: 0 }))
  run cursorUnchangedOnRefusalTest =
    assert(refused({ kind: 1, cursor: 2, entered: false }, 2))
  run keywordCursorUnchangedTest =
    assert(refused({ kind: 1, cursor: 4, entered: false }, 4))
  run exactFitIsNotRefusalTest =
    assert(not(refused({ kind: 0, cursor: 0, entered: true }, 2)))
}
