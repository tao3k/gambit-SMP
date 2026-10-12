module eager_tail_scan_partition {
  // Source mark_array eagerly owns slot 0; scan owns slots 1..size-1.
  // Publication transfers a disjoint interval, not the whole object's work.
  type State = { policy: str, size: int, copied: bool, queued: bool,
    scanner: bool, cursor: int, producerDone: bool, producerActive: bool,
    scannerDone: bool, resumed: bool, fields: int -> int,
    visits: int -> int, invalidInput: bool }
  var s: State
  pure def initial(policy: str, fieldCount: int): State = {
    policy: policy, size: fieldCount, copied: false, queued: false,
    scanner: false, cursor: 1, producerDone: false, producerActive: true,
    scannerDone: false, resumed: false,
    fields: 0.to(fieldCount - 1).mapBy(_ => 0),
    visits: 0.to(fieldCount - 1).mapBy(_ => 0), invalidInput: false,
  }
  action initOld = s' = initial("scan-first-too", 2)
  action initEarlyIdle = s' = initial("idle-after-export", 2)
  action initFixed = {
    nondet fieldCount = 1.to(4).oneOf()
    s' = initial("disjoint-slots", fieldCount)
  }
  action copyBody = all { not(s.copied), s' = { ...s, copied: true } }
  action publish = all {
    s.copied, not(s.queued), not(s.scanner), not(s.scannerDone),
    s' = { ...s, queued: true,
      producerActive: if (s.policy == "idle-after-export") false else s.producerActive },
  }
  action markFirst = all {
    s.copied, s.producerActive, not(s.producerDone), not(s.resumed),
    s' = { ...s, producerDone: true,
      fields: s.fields.set(0, 1), visits: s.visits.set(0, s.visits.get(0) + 1),
      invalidInput: s.invalidInput or s.fields.get(0) != 0 },
  }
  action claimScan = all {
    s.queued, not(s.scanner),
    s' = { ...s, queued: false, scanner: true,
      cursor: if (s.policy == "scan-first-too") 0 else 1 },
  }
  action markRest = all {
    s.scanner, s.cursor < s.size, not(s.resumed),
    s' = { ...s, cursor: s.cursor + 1,
      fields: s.fields.set(s.cursor, 1),
      visits: s.visits.set(s.cursor, s.visits.get(s.cursor) + 1),
      invalidInput: s.invalidInput or s.fields.get(s.cursor) != 0 },
  }
  action finishScan = all {
    s.scanner, s.cursor == s.size,
    s' = { ...s, scanner: false, scannerDone: true },
  }
  action producerIdle = all {
    s.producerDone, s.producerActive,
    s' = { ...s, producerActive: false },
  }
  action resume = all {
    not(s.resumed), not(s.producerActive), s.scannerDone, not(s.queued),
    s' = { ...s, resumed: true },
  }
  action finished = all { s.resumed, s' = s }
  action step = any { copyBody, publish, markFirst, claimScan,
    markRest, finishScan, producerIdle, resume, finished }
  val inputSafe = not(s.invalidInput) and
    0.to(s.size - 1).forall(i => s.visits.get(i) <= 1)
  val completionSafe = not(s.resumed) or
    0.to(s.size - 1).forall(i => s.visits.get(i) == 1)
  val safe = inputSafe and completionSafe
  temporal progress = always(s.resumed or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(s.resumed))
}
