module stack_trip_owner_limit {
  // SC projection of a sender's split load/store around owner section switch.
  // Old section is lower addressed; all coordinates use a single arena here.
  type State = {phase: str, sender: str, sampled: int, start: int,
    limit: int, trip: int, fp: int, target: int, burst: int,
    ownerGuard: bool, switched: bool}
  var s: State
  action init = {
    nondet burst = Set(1, 2, 4).oneOf()
    s' = {phase: "switch", sender: "sample", sampled: 0, start: 12,
      limit: 8, trip: 8, fp: 12, target: 12, burst: burst,
      ownerGuard: true, switched: false}
  }
  action initTripOnly = {
    nondet burst = Set(1, 2, 4).oneOf()
    s' = {phase: "switch", sender: "sample", sampled: 0, start: 12,
      limit: 8, trip: 8, fp: 12, target: 12, burst: burst,
      ownerGuard: false, switched: false}
  }
  action sample = all {s.sender == "sample",
    s' = {...s, sender: "publish", sampled: s.start}}
  action publish = all {s.sender == "publish",
    s' = {...s, sender: "done", trip: s.sampled}}
  action switchSection = all {s.phase == "switch",
    // prepare_mem_pstate installs the new owner limit and refreshes trip.
    s' = {...s, phase: "poll", start: 44, limit: 40, trip: 40,
      fp: 44, target: 44, switched: true}}
  action poll = all {s.phase == "poll",
    s' = {...s, phase: if (s.fp < s.trip or
      (s.ownerGuard and s.fp < s.limit)) "overflow" else "write"}}
  action write = all {s.phase == "write", s.target >= 32,
    s' = {...s, phase: "poll", fp: s.fp - s.burst,
      target: s.fp - s.burst}}
  action overflow = all {s.phase == "overflow",
    s' = {...s, phase: "poll", fp: 44, target: 44}}
  action step = any {sample, publish, switchSection, poll, write, overflow}
  // Current section floor=32, fudge=8; each write burst <=4 words.
  val safe = not(s.switched) or s.target >= 32
}
