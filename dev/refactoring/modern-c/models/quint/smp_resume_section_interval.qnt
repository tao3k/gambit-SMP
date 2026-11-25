module smp_resume_section_interval {
  // Integer-address abstraction of the production guard; section lifetime,
  // exclusive ownership, pointer provenance and concurrent movement are external.
  pure def aligned(n: int): bool = n % 8 == 0
  pure def matches(base: int, past: int, start: int, cursor: int, limit: int): bool =
    base > 0 and base <= start and start <= cursor and cursor <= limit and limit <= past
      and aligned(base) and aligned(past) and aligned(start) and aligned(cursor) and aligned(limit)
  run validIntervalTest = assert(matches(8, 72, 16, 24, 64))
  run wrongHalfNegativeTest = assert(not(matches(16, 72, 8, 24, 64)))
  run invertedCursorNegativeTest = assert(not(matches(8, 72, 16, 64, 56)))
  run pastEndNegativeTest = assert(not(matches(8, 64, 16, 24, 72)))
  run misalignedNegativeTest = assert(not(matches(8, 72, 16, 25, 64)))
}
