module vm_registry_shutdown_seal {
  // Global shutdown is terminal for this runtime generation. Private VM
  // constructors/global setup are quiesced by the lifecycle owner, not modeled
  // as admitted registry readers. No proof of concurrent global reinitialization.
  type State = { policy: str, open: bool, sealed: bool, alive: bool,
    reader: str, admitted: bool, writer: str, shutdown: str, badRead: bool }
  var s: State
  pure def initial(policy: str): State = {
    policy: policy, open: true, sealed: false, alive: true, reader: "new",
    admitted: false, writer: "close", shutdown: "seal", badRead: false,
  }
  action init = s' = initial("terminal-bit")
  action initReopenOld = s' = initial("writer-reopens-terminal")
  action enter = all {
    s.reader == "new", s.open,
    s' = { ...s, reader: "use", admitted: true },
  }
  action cancel = all {
    s.reader == "new", s.sealed, not(s.open), s' = { ...s, reader: "done" },
  }
  action use = all {
    s.reader == "use",
    s' = { ...s, reader: "leave", badRead: s.badRead or not(s.alive) },
  }
  action leave = all {
    s.reader == "leave", s' = { ...s, reader: "done", admitted: false },
  }
  action writerClose = all {
    s.writer == "close", s' = { ...s, open: false, writer: "drain" },
  }
  action writerDrain = all {
    s.writer == "drain", not(s.admitted), s' = { ...s, writer: "open" },
  }
  action writerOpen = all {
    s.writer == "open",
    s' = { ...s, writer: "done",
      open: not(s.sealed) or s.policy == "writer-reopens-terminal" },
  }
  action seal = all {
    s.shutdown == "seal", s' = { ...s, open: false, sealed: true, shutdown: "drain" },
  }
  action retire = all {
    s.shutdown == "drain", not(s.admitted),
    s' = { ...s, alive: false, shutdown: "done" },
  }
  val terminal = s.reader == "done" and s.writer == "done" and s.shutdown == "done"
  action finished = all { terminal, s' = s }
  action step = any { enter, cancel, use, leave, writerClose, writerDrain,
    writerOpen, seal, retire, finished }
  val admissionSafe = not(s.sealed) or not(s.open)
  val lifetimeSafe = not(s.badRead) and (not(s.admitted) or s.alive)
  val safe = admissionSafe and lifetimeSafe
  val noStall = terminal or enabled(step)
  run writerReopenControlTest = initReopenOld.then(writerClose).then(writerDrain)
    .then(seal).then(retire).then(writerOpen).then(enter).then(use)
    .then(all { assert(not(safe)), assert(s.badRead), s' = s })
  run terminalSealTest = init.then(writerClose).then(writerDrain).then(seal)
    .then(retire).then(writerOpen).then(cancel)
    .then(all { assert(terminal), assert(safe), s' = s })
  run admittedReaderShutdownTest = init.then(enter).then(seal).then(use).then(leave)
    .then(retire).then(writerClose).then(writerDrain).then(writerOpen)
    .then(all { assert(terminal), assert(safe), s' = s })
}
