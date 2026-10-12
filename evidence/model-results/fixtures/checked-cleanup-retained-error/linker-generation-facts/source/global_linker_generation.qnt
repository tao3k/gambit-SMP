module global_linker_generation {
  // Two serialized global setup generations. No VM/GC drain is assumed proven.
  // policy 0: abstract complete reconstruction; 1: current destructive reuse;
  // policy 2: restore linker entries only; 3: explicit unsupported reentry.
  type State = { policy: int, phase: int, generation: int,
    functionEntry: bool, fixupGeneration: int, calledData: bool,
    usedStaleFixups: bool, refused: bool }
  var s: State
  action initFixed = {
    nondet policy = Set(0, 3).oneOf()
    s' = { policy: policy, phase: 0, generation: 1,
      functionEntry: true, fixupGeneration: 0, calledData: false,
      usedStaleFixups: false, refused: false }
  }
  action initDestructiveReuse = s' = { policy: 1, phase: 0, generation: 1,
    functionEntry: true, fixupGeneration: 0, calledData: false,
    usedStaleFixups: false, refused: false }
  action initLinkerOnlyReset = s' = { policy: 2, phase: 0, generation: 1,
    functionEntry: true, fixupGeneration: 0, calledData: false,
    usedStaleFixups: false, refused: false }
  action firstResolve = all {
    s.phase == 0,
    s' = { ...s, phase: 1, functionEntry: false },
  }
  action firstFixup = all {
    s.phase == 1,
    s' = { ...s, phase: 2, fixupGeneration: s.generation },
  }
  action cleanup = all {
    s.phase == 2,
    // The static link table and module fixup flag survive global heap cleanup.
    s' = { ...s, phase: 3 },
  }
  action reentry = all {
    s.phase == 3,
    s' = if (s.policy == 3) { ...s, phase: 6, refused: true }
      else { ...s, phase: 4, generation: 2,
        functionEntry: if (s.policy == 1) s.functionEntry else true,
        fixupGeneration: if (s.policy == 0) 0 else s.fixupGeneration },
  }
  action secondResolve = all {
    s.phase == 4,
    s' = { ...s, phase: if (s.functionEntry) 5 else 6,
      functionEntry: false, calledData: not(s.functionEntry) },
  }
  action secondFixup = all {
    s.phase == 5,
    s' = { ...s, phase: 6,
      usedStaleFixups: s.fixupGeneration != 0 and
        s.fixupGeneration != s.generation,
      fixupGeneration: if (s.fixupGeneration == 0) s.generation
        else s.fixupGeneration },
  }
  val terminal = s.phase == 6
  action finished = all { terminal, s' = s }
  action step = any { firstResolve, firstFixup, cleanup, reentry,
    secondResolve, secondFixup, finished }
  val callableTarget = not(s.calledData)
  val generationCurrent = not(s.usedStaleFixups)
  val safe = callableTarget and generationCurrent
  temporal completion = weakFair(step, s).implies(eventually(terminal))
}
