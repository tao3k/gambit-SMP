module vm_list_reader_retirement {
  // Independent callback/cleanup participants; bounded witness, not CPU count.
  type State = { policy: str, writer: str, reader: str, admissionOpen: bool,
    linked: bool, alive: bool, snapshot: bool, registered: bool,
    writerLocked: bool, invalidRead: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, writer: "stop", reader: "eligible", admissionOpen: true,
    linked: true, alive: true, snapshot: false, registered: false,
    writerLocked: false, invalidRead: false,
  }
  action initOld = s' = initial("stop-only")
  action initWriterLock = s' = initial("writer-lock")
  action initAtomic = s' = initial("atomic-pointer")
  action initSnapshot = s' = initial("late-registration")
  action initFixed = s' = initial("drain-admitted")
  action enter = all {
    s.reader == "eligible", s.admissionOpen,
    s' = { ...s, reader: "entered" },
  }
  action load = all {
    s.reader == "entered",
    // Atomic loads may return a pointer whose storage is later reclaimed.
    s' = { ...s, reader: if (s.linked) "loaded" else "done", snapshot: s.linked },
  }
  action register = all {
    s.reader == "loaded",
    s' = { ...s, reader: "use", registered: true },
  }
  action dereference = all {
    s.reader == "use",
    s' = { ...s, reader: "done", registered: false,
      invalidRead: s.invalidRead or (s.snapshot and not(s.alive)) },
  }
  action stop = all {
    s.writer == "stop",
    s' = { ...s, writer: "drain", admissionOpen: false,
      writerLocked: s.policy == "writer-lock",
      reader: if (s.reader == "eligible") "done" else s.reader },
  }
  val admittedReader = Set("entered", "loaded", "use").contains(s.reader)
  action drain = all {
    s.writer == "drain",
    if (s.policy == "drain-admitted") not(admittedReader)
      else if (s.policy == "late-registration") not(s.registered) else true,
    s' = { ...s, writer: "unlink" },
  }
  action unlink = all {
    s.writer == "unlink", s' = { ...s, writer: "reclaim", linked: false },
  }
  action reclaim = all {
    s.writer == "reclaim",
    s' = { ...s, writer: "done", alive: false, writerLocked: false },
  }
  val terminal = s.writer == "done" and s.reader == "done"
  action finished = all { terminal, s' = s }
  action step = any { enter, load, register, dereference, stop, drain, unlink, reclaim, finished }
  val readSafe = not(s.invalidRead)
  val writerLockSafe = readSafe
  val atomicPointerSafe = readSafe
  val snapshotDrainSafe = readSafe
  val lifetimeSafe = s.alive or not(admittedReader)
  val safe = readSafe and lifetimeSafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
