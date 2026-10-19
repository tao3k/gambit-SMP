module runtime_metadata_vm_publication {
  import runtime_metadata_allocation as M from "./runtime_metadata_allocation"
  import vm_constructor_root_publication as R from "./vm_constructor_root_publication"

  // Compose the actual existing record-publication and constructor transitions.
  // One already-running VM owns slot 0; the writer introduces slot 1. R models
  // a newly constructing VM, not a fixed machine processor count. Both imports
  // assume one fully rebuilt revision/configuration, with abstract visibility.
  type Join = { active: bool, started: bool, done: bool, failed: bool,
    mayFail: bool, rangeObserved: bool, childObserved: bool,
    badRange: bool, badChild: bool }
  var j: Join
  pure def metadataInitial(earlyBinding: bool): M::State = {
    ...M::initial(0, 1, 1), profile: 2,
    publication: { ...M::publicationInitial(0), prm: true,
      phase: if (earlyBinding) 3 else 0 },
  }
  pure def joinInitial(mayFail: bool): Join = {
    active: false, started: false, done: false, failed: false,
      mayFail: mayFail, rangeObserved: false, childObserved: false,
      badRange: false, badChild: false,
  }
  // Private record fields are initialized before any imported publish action.
  // The later initializeRecord transition preserves that already-true bit.
  // Pure initial records avoid sharing one initializer action across controls,
  // which Quint 0.33 cannot translate as both initial and ordinary predicates.
  action initFixed = all {
    M::s' = metadataInitial(false), R::publication' = R::initial("fixed"),
    j' = joinInitial(true),
  }
  action initSplitConstructor = all {
    M::s' = metadataInitial(false), R::publication' = R::initial("split-lock"),
    j' = joinInitial(false),
  }
  action initBindingBeforeRange = all {
    M::s' = metadataInitial(true),
    // Reachable fixed-constructor endpoint for the already-existing slot 0.
    // This control witnesses actual local coverage, not a not-yet-running VM.
    R::publication' = { ...R::initial("fixed"), phase: "running",
      roots: Set(0), count: 1, linked: true, ready: true },
    j' = joinInitial(false),
  }
  action keepMetadata = M::s' = M::s
  action keepConstructor = R::publication' = R::publication
  action keepJoin = j' = j

  action beginWriter = all {
    not(j.started),
    keepMetadata, keepConstructor,
    j' = { ...j, active: true, started: true },
  }
  // active abstracts V ownership throughout the proposed global transaction.
  action writerPrepare = all {
    j.active, M::prepareSlots, keepConstructor, keepJoin,
  }
  // Count publication and live-VM coverage must describe the same registration.
  action writerRegister = all {
    j.active, M::publishSlotCount, R::registerGlobal, keepJoin,
  }
  action writerRecord = all {
    j.active, M::initializeRecord, keepConstructor, keepJoin,
  }
  action writerBind = all {
    j.active, M::publishBinding, keepConstructor, keepJoin,
  }
  action finishWriter = all {
    j.active, M::s.publication.phase == 4,
    keepMetadata, keepConstructor,
    j' = { ...j, active: false, done: true },
  }
  // Failure before structural/count commit publishes no binding/index.
  // Private permanent storage or surplus capacity is not rewound here.
  action abortWriter = all {
    j.active, j.mayFail, M::s.publication.phase < 2,
    keepMetadata, keepConstructor,
    j' = { ...j, active: false, done: true, failed: true },
  }
  action constructorPrepare = all {
    not(j.active), R::prepareRoots, keepMetadata, keepJoin,
  }
  action constructorProcessor = all {
    R::setupProcessor, keepMetadata, keepJoin,
  }
  action constructorPublish = all {
    not(j.active), R::publish, keepMetadata, keepJoin,
  }
  action constructorEnable = all {
    not(j.active), R::enable, keepMetadata, keepJoin,
  }
  action constructorAbort = all {
    R::abort, keepMetadata, keepJoin,
  }
  action observeRecord = all { M::observeRecord, keepConstructor, keepJoin }
  action observeSlots = all { M::observeSlots, keepConstructor, keepJoin }
  // Observers do not take V. A published symbol can be seen before the writer
  // returns. Record visibility alone does not establish its VM slot mapping.
  action observeRange = all {
    M::s.publication.binding, M::s.publication.recordObserved,
    not(j.rangeObserved),
    keepMetadata, keepConstructor,
    j' = { ...j, rangeObserved: true,
      badRange: not(M::s.publication.count and M::s.publication.slots and
        R::publication.globals.contains(1)) },
  }
  action observeChild = all {
    M::s.publication.binding, R::publication.phase == "running",
    not(j.childObserved), keepMetadata, keepConstructor,
    j' = { ...j, childObserved: true,
      badChild: not(R::publication.roots.contains(1)) },
  }
  val terminal = j.done and R::terminal and
    (not(M::s.publication.count) or M::s.publication.gcObserved) and
    (not(M::s.publication.binding) or
      (M::s.publication.recordObserved and j.rangeObserved and
        (R::publication.phase != "running" or j.childObserved)))
  action finished = all { terminal, keepMetadata, keepConstructor, keepJoin }
  action step = any { beginWriter, writerPrepare, writerRegister, writerRecord,
    writerBind, finishWriter, abortWriter, constructorPrepare,
    constructorProcessor, constructorPublish, constructorEnable, constructorAbort,
    observeRecord, observeSlots, observeRange, observeChild, finished }
  val recordBindingReadSafe = not(j.badRange)
  val constructorBindingReadSafe = not(j.badChild)
  val abortUnpublished = not(j.failed) or
    (not(M::s.publication.count) and not(M::s.publication.binding) and
      R::publication.globals == Set(0))
  val safe = M::recordPublicationSafe and R::safe and recordBindingReadSafe and
    constructorBindingReadSafe and abortUnpublished
  // Nonterminal transitions are finite and monotone; only terminal stutters.
  // This assumes terminating/fair leaf operations, not real GC/OS progress.
  temporal completion = weakFair(step, Set((M::s, R::publication, j)))
    .implies(eventually(terminal))
}
