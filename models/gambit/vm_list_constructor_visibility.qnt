module vm_list_constructor_visibility {
  // Fresh non-root VM, one root registration and one ordinary interrupt.
  // This characterizes existing constructor guards, not retirement safety.
  type State = { policy: str, writer: str, lock: bool, linked: bool,
    linksReady: bool, roots: int, generation: int, p0Ready: bool,
    ordinaryEnabled: bool, registrarDone: bool, registrationFails: bool,
    reader: str, captured: bool, sameThread: bool, badRoots: bool,
    badLinks: bool, badP0: bool, deadlock: bool }
  var s: State
  pure def initial(policy: str, generation: int, registrationFails: bool, sameThread: bool): State = {
    policy: policy, writer: "acquire", lock: false, linked: false,
    linksReady: false, roots: 0, generation: generation, p0Ready: false,
    ordinaryEnabled: false, registrarDone: false, registrationFails: registrationFails,
    reader: "enter", captured: false, sameThread: sameThread,
    badRoots: false, badLinks: false, badP0: false, deadlock: false,
  }
  action initOld = s' = initial("early-roots", 1, false, true)
  action initEarlyLinks = s' = initial("early-links", 1, false, true)
  action initEarlyEnable = s' = initial("early-enable", 1, false, true)
  action initMutexHandler = s' = initial("mutex-handler", 1, false, true)
  action init = {
    nondet generation = Set(0, 1).oneOf()
    nondet registrationFails = Set(false, true).oneOf()
    nondet sameThread = Set(false, true).oneOf()
    s' = initial("source", generation, registrationFails, sameThread)
  }
  action acquire = all {
    not(s.deadlock), s.writer == "acquire",
    s' = { ...s, writer: "roots", lock: true },
  }
  action setupRoots = all {
    not(s.deadlock), s.writer == "roots",
    s' = { ...s, writer: "links",
      roots: if (s.policy == "early-roots") 0 else s.generation },
  }
  action setupLinks = all {
    not(s.deadlock), s.writer == "links",
    s' = { ...s, writer: "publish", linksReady: s.policy != "early-links" },
  }
  action publish = all {
    not(s.deadlock), s.writer == "publish",
    s' = { ...s, writer: "unlock", linked: true,
      ordinaryEnabled: s.policy == "early-enable" },
  }
  action unlock = all {
    not(s.deadlock), s.writer == "unlock",
    s' = { ...s, writer: "p0", lock: false },
  }
  action setupP0 = all {
    not(s.deadlock), s.writer == "p0",
    s' = { ...s, writer: "done", p0Ready: true, ordinaryEnabled: true },
  }
  action registerGlobal = all {
    not(s.deadlock), not(s.registrarDone), not(s.lock),
    // The root-table reader/writer holds vm_list_mut throughout this transaction.
    s' = { ...s, registrarDone: true,
      badRoots: s.badRoots or (s.linked and s.roots < s.generation),
      roots: if (s.linked and not(s.registrationFails)) s.generation + 1 else s.roots,
      generation: if (s.registrationFails) s.generation else s.generation + 1 },
  }
  action enterInterrupt = all {
    not(s.deadlock), s.reader == "enter",
    s' = if (s.policy == "mutex-handler" and s.lock and s.sameThread)
      { ...s, reader: "blocked", deadlock: true }
      else if (s.policy == "mutex-handler" and s.lock) { ...s }
      else { ...s, reader: "use", captured: s.linked },
  }
  action useInterrupt = all {
    not(s.deadlock), s.reader == "use",
    s' = { ...s, reader: "done",
      badLinks: s.badLinks or (s.captured and not(s.linksReady)),
      badP0: s.badP0 or (s.captured and s.ordinaryEnabled and not(s.p0Ready)) },
  }
  val terminal = s.writer == "done" and s.reader == "done" and s.registrarDone
  action finished = all { terminal, s' = s }
  action step = any { acquire, setupRoots, setupLinks, publish, unlock,
    setupP0, registerGlobal, enterInterrupt, useInterrupt, finished }
  val rootsSafe = not(s.badRoots)
  val linksSafe = not(s.badLinks)
  val p0ReadSafe = not(s.badP0)
  val reentrySafe = not(s.deadlock)
  val guardSound = rootsSafe and linksSafe and p0ReadSafe and reentrySafe
  temporal progress = always(terminal or enabled(step)) and
    weakFair(step, Set(s)).implies(eventually(terminal))
}
