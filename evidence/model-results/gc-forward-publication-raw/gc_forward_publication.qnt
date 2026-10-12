module gc_forward_publication {
  // One two-word object, two competing workers, one private destination chunk.
  // Address publication by CAS precedes copying. References may be redirected
  // immediately; scanning requires completed chunk publication. Mutators stop.
  // Abstract release/acquire makes copied words visible at queue publication;
  // this is not a C weak-memory proof. Faults are controls, not source findings.
  // The root-slot contract is distinct from object aliasing: a redirected slot
  // must not be marked again as an old-space reference within the same cycle.
  type State = { fault: int, owner: int, refs: int -> int, copied: int,
           visible: int, queued: bool, scanned: bool, staleRead: bool,
           active: int -> bool, resumed: bool, canonicalForwarded: bool }
  var s: State

  pure def initialState(fault: int): State = {
    fault: fault, owner: 0, refs: Map(1 -> 0, 2 -> 0), copied: 0,
    visible: 0, queued: false, scanned: false, staleRead: false,
    active: Map(1 -> true, 2 -> true), resumed: false, canonicalForwarded: false,
  }
  action initOld = s' = initialState(1)
  action initUncountedProducer = s' = initialState(2)
  action initDuplicateSlot = s' = initialState(3)
  action initRelocatedPayload = s' = initialState(4)
  action initFixed = s' = initialState(0)

  // The first CAS winner owns its private destination. The loser's speculative
  // reservation is omitted: it redirects its reference, never scans that copy.
  action claim(w: int): bool = all {
    not(s.resumed), s.active.get(w), s.owner == 0,
    s' = { ...s, owner: w, refs: s.refs.set(w, w) },
  }
  action redirect(w: int): bool = all {
    not(s.resumed), s.active.get(w), s.owner != 0, s.refs.get(w) == 0,
    s' = { ...s, refs: s.refs.set(w, s.owner) },
  }
  action copyWord = all {
    not(s.resumed), s.owner != 0, s.active.get(s.owner), s.copied < 2,
    s' = { ...s, copied: s.copied + 1 },
  }
  // Injected input schedule supported by the extracted mark_array experiment;
  // native root/scan ownership has not been shown to permit this schedule.
  action revisitSlot = all {
    not(s.resumed), s.fault == 3, s.owner != 0, s.active.get(s.owner),
    s.copied == 2, not(s.canonicalForwarded),
    s' = { ...s, canonicalForwarded: true },
  }
  action publish = all {
    not(s.resumed), s.owner != 0, s.active.get(s.owner),
    not(s.queued), not(s.scanned), (s.copied == 2 or s.fault == 1),
    s' = { ...s, queued: true, visible: s.copied },
  }
  action scan(w: int): bool = all {
    not(s.resumed), s.active.get(w), s.queued,
    s' = { ...s, queued: false, scanned: true,
           staleRead: s.staleRead or s.visible != 2,
           canonicalForwarded: s.canonicalForwarded or (s.fault == 4) },
  }
  action idle(w: int): bool = all {
    not(s.resumed), s.active.get(w), s.refs.get(w) != 0,
    (w != s.owner or (s.copied == 2 and s.scanned) or s.fault == 2),
    s' = { ...s, active: s.active.set(w, false) },
  }
  action wake(w: int): bool = all {
    not(s.resumed), not(s.active.get(w)), s.queued,
    s.active.get(1) or s.active.get(2),
    s' = { ...s, active: s.active.set(w, true) },
  }
  action resume = all {
    not(s.resumed), not(s.active.get(1)), not(s.active.get(2)),
    s' = { ...s, resumed: true },
  }
  action finished = all { s.resumed, s' = s }
  action step = any { claim(1), claim(2), redirect(1), redirect(2), copyWord,
    revisitSlot, publish, scan(1), scan(2), idle(1), idle(2), wake(1), wake(2), resume, finished }

  val publicationSafe = not(s.staleRead)
  val terminationSafe = not(s.resumed) or
    (s.copied == 2 and s.scanned and not(s.queued))
  val identitySafe = (s.refs.get(1) == 0 or s.refs.get(1) == s.owner) and
                     (s.refs.get(2) == 0 or s.refs.get(2) == s.owner)
  val destinationSafe = not(s.canonicalForwarded)
  val payloadInputSafe = not(s.canonicalForwarded)
  val safe = publicationSafe and terminationSafe and identitySafe and destinationSafe
}
