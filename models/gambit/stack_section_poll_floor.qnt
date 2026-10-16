module stack_section_poll_floor {
  // Relative words; the native guard is the current tospace floor plus fudge.
  pure val floor = 0
  pure val guard = 8
  type State = { phase: str, fp: int, target: int, staleTrip: int,
    frameWords: int, physicalGuard: bool, trapped: bool }
  var s: State
  action init = {
    nondet words = Set(1, 2, 4).oneOf()
    s' = { phase: "poll", fp: 12, target: 12, staleTrip: -100,
      frameWords: words, physicalGuard: true, trapped: false }
  }
  action initStaleTripOnly = s' = {
    phase: "poll", fp: 12, target: 12, staleTrip: -100,
    frameWords: 4, physicalGuard: false, trapped: false }
  action poll = all {
    s.phase == "poll",
    s' = { ...s, phase: if (s.fp < s.staleTrip or
        (s.physicalGuard and s.fp < guard)) "overflow" else "write" }
  }
  action frameWrite = all { s.phase == "write",
    s' = { ...s, phase: "poll", fp: s.fp - s.frameWords,
      target: s.fp - s.frameWords } }
  action overflow = all { s.phase == "overflow",
    s' = { ...s, phase: "poll", fp: 12, target: 12, trapped: true } }
  action step = any { poll, frameWrite, overflow }
  val safe = s.target >= floor
  // This assumes a poll before each bounded burst and a maximum burst <= fudge.
  // It does not establish those compiler premises or explain why stack_trip was low.
}
