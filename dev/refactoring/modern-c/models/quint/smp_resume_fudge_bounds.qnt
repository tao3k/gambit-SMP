module smp_resume_fudge_bounds {
  // Integer abstraction of collection-round's post-handoff normalization and
  // memory-lifecycle's publication. Physical ownership and C pointer validity
  // are assumptions, not established by this bounded arithmetic model.
  pure def normalize(cursor: int, limit: int, fudge: int, nextLimit: int): (int, int) =
    if (cursor > limit - fudge) (0, nextLimit) else (cursor, limit)

  pure def publishedLimit(cursor: int, limit: int, fudge: int, heapAvail: int): int =
    cursor + (if (heapAvail < limit - cursor - fudge) heapAvail else limit - cursor - fudge)

  pure def fits(cursor: int, words: int, limit: int): bool =
    cursor >= 0 and words > 0 and cursor <= limit and words <= limit - cursor

  // Both formulae are integer abstractions. The production implementation
  // avoids constructing limit-fudge as a C pointer outside its allocation.
  pure def needsRefill(cursor: int, limit: int, fudge: int): bool =
    limit - cursor < fudge

  // For each bounded state, the replacement interval has at least a fudge
  // region; heapAvail is nonnegative as in prepare_mem_pstate.
  pure def valid(cursor: int, limit: int, fudge: int, nextLimit: int, heapAvail: int): bool =
    cursor >= 0 and cursor <= limit and fudge >= 6 and nextLimit >= fudge and heapAvail >= 0

  pure def safe(cursor: int, limit: int, fudge: int, nextLimit: int, heapAvail: int): bool = {
    val region = normalize(cursor, limit, fudge, nextLimit)
    val hp = region._1
    val end = region._2
    val poll = publishedLimit(hp, end, fudge, heapAvail)
    hp <= poll and poll <= end - fudge and fits(hp, 6, end)
  }

  run boundedFudgeTest = assert(
    Set(0, 1, 5, 6, 7, 8, 12).forall(cursor =>
      Set(6, 7, 8, 12).forall(limit =>
        Set(6, 8).forall(fudge =>
          Set(6, 8, 12).forall(nextLimit =>
            Set(0, 1, 20).forall(avail =>
              not(valid(cursor, limit, fudge, nextLimit, avail)) or
              safe(cursor, limit, fudge, nextLimit, avail)))))))

  run noNormalizationControlTest = assert(not(fits(7, 6, 8)))
  run pollThresholdIsNotPhysicalEndTest = assert(
    publishedLimit(0, 8, 6, 0) == 0 and fits(0, 6, 8))
  run shortReplacementControlTest = assert(not(safe(7, 8, 6, 5, 0)))
  run refillEquivalentTest = assert(
    Set(0, 1, 6, 7, 8).forall(cursor =>
      Set(0, 1, 6, 8).forall(limit =>
        Set(0, 1, 6, 8).forall(fudge =>
          cursor > limit or ((cursor > limit - fudge) == needsRefill(cursor, limit, fudge))))))
  run refillShortIntervalTest = assert(needsRefill(0, 1, 6) and not(needsRefill(0, 6, 6)))
}
