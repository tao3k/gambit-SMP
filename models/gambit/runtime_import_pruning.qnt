module runtime_import_pruning {
  // Owner/phase/slot is the cell identity after expansion. Declaration names
  // and reexporting modules do not own the cells to which they resolve.
  type Binding = { owner: str, phase: int, slot: str }
  type Cell = { binding: Binding, value: int, epoch: int }
  type Reply = { binding: Binding, value: int }
  type Loader = { cells: int -> Cell, effects: List[str], effectCount: int, images: Set[str] }
  type State = {
    stage: str, epoch: int, planEpoch: int, usedEpoch: int, opaque: bool, pathChanged: bool,
    splitActive: bool, pathRequested: bool,
    lookedUp: bool, expanded: bool, phaseEpoch: int, phaseCells: Set[int],
    reference: Loader, pruned: Loader, reply: Reply, expected: Reply,
    startupMode: str, startupImages: Set[str],
    residentArtifact: bool, wrapperEpoch: int, residentEpoch: int,
    carrierDigest: int, borrowedEpoch: int,
    claim: int, waiter: int, faulted: bool, cycleRejected: bool, writes: int,
    control: str,
  }

  pure val live: Binding = { owner: "parser-core", phase: 0, slot: "parse" }
  pure val helper: Binding = { owner: "reader", phase: 0, slot: "helper" }
  pure val config: Binding = { owner: "reader-config", phase: 0, slot: "setting" }
  pure val macroHelper: Binding = { owner: "reader", phase: 1, slot: "helper" }
  pure val macro: Binding = { owner: "reader", phase: 1, slot: "define-parser" }
  pure val mixed: Binding = { owner: "mixed-init", phase: 0, slot: "value" }
  pure val late: Binding = { owner: "buffered-reader", phase: 0, slot: "read" }
  pure val socket: Binding = { owner: "datagram", phase: 0, slot: "recv" }
  pure val missing: Binding = { owner: "absent", phase: 0, slot: "read" }
  pure val lexical: Binding = { owner: "local", phase: 0, slot: "read" }
  pure val wrongOwner: Binding = { ...live, owner: "io-facade" }
  pure val runtime = Set(live, helper, config, mixed, late, socket)
  pure val effects = List("read-helper", "mixed-init", "root")
  pure val noReply: Reply = { binding: missing, value: -1 }

  pure def value(b: Binding): int =
    if (b == live) 17 else if (b == helper) 23 else if (b == mixed) 31
    else if (b == config) 7 else if (b == late) 999 else if (b == socket) 41 else -1

  // The root sees `parse` through a facade reexport. Initialization also
  // owns a hidden reference to reader/helper and an inseparable mixed body.
  pure val exports = Map("parse" -> "facade-parse", "facade-parse" -> "parser-core-parse")
  pure val definitions = Map("parser-core-parse" -> live)
  pure val resolved = definitions.get(exports.get(exports.get("parse")))
  pure val runtimeRefs = Set(resolved)
  pure val initRefs = Set(helper, mixed)
  pure val edges = Set({ from: helper, to: config })
  pure def closure(roots: Set[Binding]): Set[Binding] =
    runtime.fold(roots, (reached, _) =>
      reached.union(edges.filter(e => reached.contains(e.from)).map(e => e.to)))
  pure val retained = closure(runtimeRefs.union(initRefs))

  // Numeric slots encode the fixed finite carrier for the shared TLC trace
  // reader. An allocated cell still carries the full expanded binding key.
  pure def key(b: Binding): int =
    if (b == live) 1 else if (b == helper) 2 else if (b == config) 3
    else if (b == mixed) 4 else if (b == late) 5 else if (b == socket) 6
    else if (b == macro) 7 else if (b == macroHelper) 8 else 0
  pure def emptyCell(b: Binding): Cell = { binding: b, value: -1, epoch: 0 }
  pure val emptyEffects = List("none", "none", "none")
  pure val emptyLoader: Loader = {
    cells: Map(1 -> emptyCell(live), 2 -> emptyCell(helper), 3 -> emptyCell(config),
               4 -> emptyCell(mixed), 5 -> emptyCell(late), 6 -> emptyCell(socket)),
    effects: emptyEffects, effectCount: 0, images: Set(),
  }
  pure val initial: State = {
    stage: "new", epoch: 1, planEpoch: 0, usedEpoch: 0, opaque: false, pathChanged: false,
    splitActive: false, pathRequested: false,
    lookedUp: false, expanded: false, phaseEpoch: 0, phaseCells: Set(),
    reference: emptyLoader, pruned: emptyLoader, reply: noReply, expected: noReply,
    startupMode: "pending", startupImages: Set(),
    residentArtifact: false, wrapperEpoch: 0, residentEpoch: 0,
    carrierDigest: 0, borrowedEpoch: 0,
    claim: 0, waiter: 0, faulted: false, cycleRejected: false, writes: 0,
    control: "none",
  }
  var s: State

  pure def cell(l: Loader, b: Binding): Cell = l.cells.get(key(b))
  pure def present(l: Loader, b: Binding): bool =
    if (runtime.contains(b)) cell(l, b).epoch > 0 else false
  pure def supplied(l: Loader): Set[Binding] = runtime.filter(b => present(l, b))

  pure def publish(l: Loader, b: Binding, epoch: int, image: bool): Loader =
    if (present(l, b)) l else {
      cells: l.cells.put(key(b), { binding: b, value: value(b), epoch: epoch }),
      effects: l.effects, effectCount: l.effectCount,
      images: if (image) l.images.union(Set(b.owner)) else l.images,
    }

  pure def loadAll(l: Loader, bindings: Set[Binding], epoch: int): Loader =
    bindings.fold(l, (known, b) => publish(known, b, epoch, true))

  pure def initialize(l: Loader): Loader = {
    ...l,
    effects: List(
      if (present(l, helper) and present(l, config)) "read-helper" else "unbound-helper",
      if (present(l, mixed)) "mixed-init" else "unloaded-mixed", "root"),
    effectCount: l.effectCount + 3,
  }

  pure def observe(l: Loader, b: Binding): Reply =
    if (present(l, b)) { binding: cell(l, b).binding, value: cell(l, b).value }
    else { binding: b, value: -1 }

  pure def write(l: Loader, b: Binding, n: int): Loader = {
    ...l, cells: l.cells.put(key(b), { ...cell(l, b), value: n }),
  }

  val ready = s.stage == "ready"
  val knownPlan = s.planEpoch == s.epoch and not(s.opaque)
  val sameObservation = s.reply == s.expected
  pure val transformerCells = Set(key(macro), key(macroHelper))
  val phaseSafe = all {
    s.phaseEpoch >= 0 and s.phaseEpoch <= s.epoch,
    if (s.phaseEpoch == 0) s.phaseCells == Set() else s.phaseCells == transformerCells,
    s.expanded implies s.phaseEpoch > 0,
    (not(s.expanded) and not(s.pathChanged)) implies s.phaseEpoch == 0,
    (s.pathChanged and s.lookedUp) implies s.phaseEpoch == 1,
  }
  val effectsSafe = if (ready) all {
    s.reference.effects == effects, s.pruned.effects == s.reference.effects,
    s.reference.effectCount == 3, s.pruned.effectCount == s.reference.effectCount,
  } else all {
    s.pruned.effects == emptyEffects, s.reference.effects == emptyEffects,
    s.pruned.effectCount == 0, s.reference.effectCount == 0,
  }
  val currentPlan = s.usedEpoch == 0 or s.usedEpoch == s.epoch
  val opaqueSafe = s.opaque and ready implies runtime.subseteq(supplied(s.pruned))
  val pathSafe = s.pathChanged implies all {
    ready, not(s.splitActive), not(s.pathRequested),
    s.epoch == 2, runtime.subseteq(supplied(s.pruned)),
    cell(s.pruned, late).epoch == 1, cell(s.pruned, socket).epoch == 1,
  }
  val cellsSafe = ready implies all {
    supplied(s.reference) == runtime,
    retained.subseteq(supplied(s.pruned)),
    supplied(s.pruned).forall(b => all {
      runtime.contains(b), b.phase == 0,
      observe(s.pruned, b) == observe(s.reference, b),
      cell(s.pruned, b).epoch >= 1,
      cell(s.pruned, b).epoch <= s.epoch,
    }),
  }
  val ownershipSafe = all {
    s.claim >= 0 and s.claim <= 2,
    s.splitActive implies (s.stage == "planned" and not(s.pathChanged)),
    s.claim != 0 implies (ready and not(s.faulted) and not(present(s.pruned, late))),
    s.waiter != 0 implies (s.claim != 0 and s.waiter != s.claim),
    s.faulted implies (s.claim == 0 and not(present(s.pruned, late))),
    s.cycleRejected implies s.faulted,
  }
  val residentSafe = s.residentEpoch == 0 or all {
    s.residentArtifact, s.wrapperEpoch == s.residentEpoch, cell(s.pruned, late).epoch == s.residentEpoch,
    not(s.pathChanged) implies s.residentEpoch == s.epoch,
    s.pruned.images.contains("buffered-reader-wrapper") or s.borrowedEpoch != 0,
    not(s.pruned.images.contains(late.owner)), present(s.pruned, late),
  }
  val carrierSafe = s.borrowedEpoch == 0 or all {
    ready, s.residentArtifact,
    s.borrowedEpoch == s.phaseEpoch and s.borrowedEpoch == s.carrierDigest,
    s.borrowedEpoch == s.wrapperEpoch,
    not(s.pruned.images.contains("buffered-reader-wrapper")),
  }
  // Independent footprint oracle for this graph and its fixed native layout.
  // These sets are specified from the fixture, independently of closure and
  // publication. Freeze the cut before a later eval can legitimately widen it.
  pure val preciseImages = Set("parser-core", "reader", "reader-config", "mixed-init")
  pure val ordinaryImages = preciseImages.union(Set("buffered-reader", "datagram"))
  val startupExact = if (ready) {
    if (s.startupMode == "ordinary") s.startupImages == ordinaryImages
    else if (s.startupMode == "wrapper")
      s.startupImages == preciseImages.union(Set("buffered-reader-wrapper"))
    else s.startupMode == "precise" and s.startupImages == preciseImages
  } else s.startupMode == "pending" and s.startupImages == Set()

  val semanticSafe = all {
    sameObservation, phaseSafe, effectsSafe, currentPlan, opaqueSafe, pathSafe, cellsSafe, ownershipSafe,
    residentSafe, carrierSafe,
  }
  val safe = semanticSafe and startupExact

  action init = s' = initial
  action lookupExport = all {
    s.stage == "new", not(s.lookedUp),
    s' = { ...s, lookedUp: true, reply: { binding: macro, value: 0 }, expected: { binding: macro, value: 0 } },
  }
  action expandMacro = all {
    (s.stage == "new" or ready), s.lookedUp, not(s.expanded),
    s' = { ...s, expanded: true, phaseCells: transformerCells,
      phaseEpoch: if (s.phaseEpoch == 0) s.epoch else s.phaseEpoch },
  }
  action selectResidentArtifact = all {
    s.stage == "new", not(s.residentArtifact), s' = { ...s, residentArtifact: true },
  }
  action opaqueInterface = all {
    s.stage == "new", not(s.opaque), s' = { ...s, opaque: true },
  }
  action plan = all {
    s.stage == "new",
    s' = { ...s, stage: "planned", planEpoch: s.epoch },
  }
  // A split initializer has claimed an image but has yet to publish it.
  // The path writer waits for that claim even after an opaque cut.
  action beginSplit = all {
    s.stage == "planned", knownPlan, not(s.splitActive), not(s.pathRequested),
    s' = { ...s, splitActive: true },
  }
  action requestDuringSplit = all {
    s.splitActive, not(s.pathRequested), s' = { ...s, pathRequested: true },
  }
  action opaqueDuringSplit = all {
    s.splitActive, not(s.opaque), s' = { ...s, opaque: true },
  }
  action finishSplit = all { s.splitActive, s' = { ...s, splitActive: false } }
  action replaceArtifact = all {
    s.stage == "planned", s.epoch == 1, not(s.splitActive), not(s.pathRequested),
    s' = { ...s, epoch: 2 },
  }
  // The already-loaded phase supplies a recipe. Registration does not run it.
  action registerPhaseCarrier(digest: int): bool = all {
    (s.stage == "new" or s.stage == "planned"), s.phaseEpoch > 0, s.carrierDigest == 0,
    s' = { ...s, carrierDigest: digest },
  }
  action publishImport(demand: Set[Binding], useEpoch: int, borrow: bool): bool = all {
    s.stage == "planned", not(s.splitActive),
    val pruned = initialize(loadAll(emptyLoader, demand, s.epoch))
    val mixedWrapper = s.residentArtifact and useEpoch != 0
    val needsWrapper = mixedWrapper and not(borrow)
    val startup = if (needsWrapper) pruned.images.union(Set("buffered-reader-wrapper")) else pruned.images
    // Derive the expected mode from admission inputs. Taking the fallback or
    // opening a wrapper cannot change the requirement that it is checked against.
    val startupMode =
      if (s.opaque or s.planEpoch != s.epoch) "ordinary"
      else if (s.residentArtifact and (s.phaseEpoch != s.epoch or s.carrierDigest != s.epoch)) "wrapper"
      else "precise"
    s' = { ...s, stage: "ready", usedEpoch: useEpoch,
      wrapperEpoch: if (mixedWrapper) useEpoch else 0,
      borrowedEpoch: if (borrow) useEpoch else 0,
      startupMode: startupMode, startupImages: startup,
      reference: initialize(loadAll(emptyLoader, runtime, s.epoch)),
      pruned: { ...pruned, images: startup },
    },
  }
  action finishImport(demand: Set[Binding], useEpoch: int): bool =
    publishImport(demand, useEpoch,
      s.residentArtifact and useEpoch != 0 and s.phaseEpoch == useEpoch and s.carrierDigest == useEpoch)
  action commit = if (knownPlan) finishImport(retained, s.planEpoch) else finishImport(runtime, 0)
  action replaceBeforeDemand = all {
    ready, s.epoch == 1, not(present(s.pruned, late)),
    s' = { ...s, epoch: 2, usedEpoch: 0 },
  }
  // An explicit search-path change after an import drains its prior logical
  // instance using the old path. Replacement during an uncommitted claim
  // continues to use the separate epoch-validation action above.
  action changePath = all {
    ready, s.epoch == 1, s.claim == 0, not(s.faulted), not(s.splitActive),
    s' = { ...s, pathChanged: true, pathRequested: false, epoch: 2, usedEpoch: 0,
      pruned: loadAll(s.pruned, runtime, s.epoch),
      phaseEpoch: if (s.lookedUp) s.epoch else s.phaseEpoch,
      phaseCells: if (s.lookedUp) transformerCells else s.phaseCells },
  }
  action rootRead = all {
    ready,
    s' = { ...s, reply: observe(s.pruned, resolved), expected: observe(s.reference, live) },
  }
  action missingRead = all {
    ready,
    s' = { ...s, reply: observe(s.pruned, missing), expected: noReply },
  }
  action lexicalRead = all {
    ready,
    s' = { ...s, reply: { binding: lexical, value: 313 }, expected: { binding: lexical, value: 313 } },
  }
  action demand(b: Binding): bool = all {
    ready, s.claim == 0, not(s.faulted),
    val seen = publish(s.pruned, b, s.epoch, true)
    s' = { ...s, pruned: seen, reply: observe(seen, b), expected: observe(s.reference, b) },
  }
  action writeLate = all {
    ready, s.claim == 0, not(s.faulted), s.writes == 0,
    val candidate = write(publish(s.pruned, late, s.epoch, true), late, 321)
    val reference = write(s.reference, late, 321)
    s' = { ...s, writes: 1, pruned: candidate, reference: reference,
      reply: observe(candidate, late), expected: observe(reference, late) },
  }
  action opaqueObserver = all {
    ready, s.claim == 0, not(s.faulted), not(s.opaque),
    s' = { ...s, opaque: true, pruned: loadAll(s.pruned, runtime, s.epoch) },
  }

  // Two observer threads may contend for one late binding. Preparing a
  // mixed initializer's resident code makes the body callable without
  // recording a second image; ordinary fallback still opens the body.
  action claimLate(worker: int): bool = all {
    ready, s.claim == 0, not(s.faulted), not(present(s.pruned, late)),
    s' = { ...s, claim: worker },
  }
  action awaitOther(worker: int): bool = all {
    ready, s.claim != 0, s.claim != worker, s.waiter == 0,
    s' = { ...s, waiter: worker },
  }
  action rejectSelfWait(worker: int): bool = all {
    ready, s.claim == worker, s.wrapperEpoch != s.epoch,
    s' = { ...s, claim: 0, waiter: 0, faulted: true, cycleRejected: true },
  }
  action finishLate(worker: int): bool = all {
    ready, s.claim == worker,
    val reuse = s.wrapperEpoch == s.epoch
    val result = publish(s.pruned, late, s.epoch, not(reuse))
    s' = { ...s, claim: 0, waiter: 0, pruned: result, reply: observe(result, late),
      expected: observe(s.reference, late), residentEpoch: if (reuse) s.epoch else 0 },
  }
  action failLate(worker: int): bool = all {
    ready, s.claim == worker,
    // Failure admission is separate from the successful-value relation.
    // The failed body remains unavailable to all subsequent candidate readers.
    s' = { ...s, claim: 0, waiter: 0, faulted: true },
  }

  action settle = any { finishLate(1), finishLate(2), failLate(1), failLate(2), finishSplit }
  temporal claimProgress = weakFair(settle, Set(s)).implies(always(all {
    (s.claim != 0).implies(eventually(s.claim == 0)),
    s.splitActive.implies(eventually(not(s.splitActive))),
  }))

  action normal = any {
    lookupExport, expandMacro, selectResidentArtifact, opaqueInterface, plan,
    registerPhaseCarrier(1), registerPhaseCarrier(2),
    beginSplit, requestDuringSplit, opaqueDuringSplit,
    replaceArtifact, replaceBeforeDemand, changePath, commit, rootRead, missingRead, lexicalRead,
    demand(late), demand(socket), writeLate, opaqueObserver, claimLate(1), claimLate(2),
    awaitOther(1), awaitOther(2), rejectSelfWait(1), rejectSelfWait(2), settle, s' = s,
  }

  run scopeTest = init.then(plan).then(commit).then(rootRead).then(all {
    assert(safe and s.reply.binding == live and not(present(s.pruned, socket))), s' = s,
  })
  run macroPhaseTest = init.then(lookupExport).then(all {
    assert(safe and s.phaseCells == Set()), s' = s,
  }).then(expandMacro).then(plan).then(commit).then(all {
    assert(safe and s.phaseCells.contains(key(macroHelper)) and present(s.pruned, helper)), s' = s,
  })
  run namedDemandTest = init.then(plan).then(commit).then(demand(late)).then(all {
    assert(safe and s.reply.value == 999 and not(present(s.pruned, socket))), s' = s,
  })
  run lexicalShadowTest = init.then(plan).then(commit).then(lexicalRead).then(all {
    assert(safe and s.reply.binding == lexical and not(present(s.pruned, late))
      and not(present(s.pruned, socket))), s' = s,
  })
  run repeatedWriteTest = init.then(plan).then(commit).then(writeLate).then(demand(late)).then(all {
    assert(safe and s.reply.value == 321 and not(present(s.pruned, socket))), s' = s,
  })
  run opaqueTest = init.then(plan).then(commit).then(opaqueObserver).then(all {
    assert(safe and present(s.pruned, socket)), s' = s,
  })
  run changeArtifactTest = init.then(plan).then(replaceArtifact).then(commit).then(all {
    assert(safe and s.usedEpoch == 0 and cell(s.pruned, late).epoch == 2), s' = s,
  })
  run residentTest = init.then(selectResidentArtifact).then(plan).then(commit).then(claimLate(1)).then(finishLate(1)).then(all {
    assert(safe and present(s.pruned, late) and not(s.pruned.images.contains(late.owner))), s' = s,
  })
  run stickyFailureTest = init.then(plan).then(commit).then(claimLate(1)).then(failLate(1)).then(all {
    assert(safe and s.faulted and not(present(s.pruned, late))), s' = s,
  })

  run staleResidentFallbackTest = init.then(selectResidentArtifact).then(plan).then(commit)
    .then(claimLate(2)).then(replaceBeforeDemand).then(finishLate(2)).then(all {
      assert(safe and s.residentEpoch == 0 and s.pruned.images.contains(late.owner)
        and cell(s.pruned, late).epoch == 2), s' = s,
    })
  run mixedOpaqueImportTest = init.then(opaqueInterface).then(plan).then(commit).then(all {
    assert(safe and s.usedEpoch == 0 and present(s.pruned, mixed) and present(s.pruned, socket)), s' = s,
  })
  run absentNameTest = init.then(plan).then(commit).then(missingRead).then(all {
    assert(safe and not(present(s.pruned, late)) and not(present(s.pruned, socket))), s' = s,
  })

  run pathBarrierTest = init.then(plan).then(commit).then(changePath).then(demand(late)).then(all {
    assert(safe and s.pathChanged and s.reply.value == 999 and cell(s.pruned, late).epoch == 1), s' = s,
  })
  action residentPhase = selectResidentArtifact.then(lookupExport).then(expandMacro)
  run carrierReuseTest = init.then(residentPhase).then(registerPhaseCarrier(1)).then(all {
    assert(safe and s.pruned.effectCount == 0), s' = s,
  }).then(plan).then(commit).then(rootRead).then(all {
    assert(safe and s.borrowedEpoch == 1 and s.pruned.effectCount == 3), s' = s,
  })
  run carrierWrongBodyTest = init.then(residentPhase).then(registerPhaseCarrier(2)).then(plan).then(commit).then(all {
    assert(safe and s.borrowedEpoch == 0 and s.pruned.images.contains("buffered-reader-wrapper")), s' = s,
  })
  run macroPathBarrierTest = init.then(lookupExport).then(plan).then(commit).then(changePath)
    .then(all { assert(safe and not(s.expanded) and s.phaseEpoch == 1), s' = s })
    .then(expandMacro).then(all { assert(safe and s.expanded and s.phaseEpoch == 1), s' = s })
  run opaqueSplitPathTest = init.then(plan).then(beginSplit).then(opaqueDuringSplit)
    .then(requestDuringSplit).then(finishSplit).then(commit).then(changePath).then(all {
      assert(safe and s.pathChanged and s.opaque and not(s.splitActive) and s.pruned.effectCount == 3), s' = s,
    })
  run disjointWaiterTest = init.then(plan).then(commit).then(claimLate(1)).then(awaitOther(2))
    .then(finishLate(1)).then(all { assert(safe and s.waiter == 0 and present(s.pruned, late)), s' = s })
  run rejectSelfWaitTest = init.then(selectResidentArtifact).then(plan).then(commit)
    .then(claimLate(1)).then(replaceBeforeDemand).then(rejectSelfWait(1)).then(all {
      assert(safe and s.cycleRejected and s.claim == 0 and s.waiter == 0), s' = s,
    })

  // Fault switches enter the same transition graph, with one wrong action.
  action skipInit = finishImport(runtimeRefs.union(Set(mixed)), s.planEpoch)
  action keepStale = finishImport(retained, s.planEpoch)
  action skipRead = all { ready, not(present(s.pruned, late)),
    s' = { ...s, reply: observe(s.pruned, late), expected: observe(s.reference, late) },
  }
  action flattenAlias = all { ready,
    s' = { ...s, reply: observe(s.pruned, wrongOwner), expected: observe(s.reference, live) },
  }
  action visitOnLookup = all { s.stage == "new",
    s' = { ...s, lookedUp: true, phaseCells: Set(key(macro)) },
  }
  action loseAuxiliary = all { s.stage == "new", s.lookedUp,
    s' = { ...s, expanded: true, phaseEpoch: s.epoch, phaseCells: Set(key(macro), key(helper)) },
  }
  action skipOpaque = all { ready, not(s.opaque), not(present(s.pruned, socket)),
    s' = { ...s, opaque: true },
  }
  action replayInit = all { ready, s' = { ...s, pruned: initialize(s.pruned) } }
  action publishAfterFailure = all { ready, s.faulted,
    s' = { ...s, pruned: publish(s.pruned, late, s.epoch, true) },
  }

  action initSkipInit = { s' = { ...initial, stage: "planned", planEpoch: 1 } }
  action initStale = { s' = { ...initial, stage: "planned", planEpoch: 1, epoch: 2 } }
  action initAuxiliary = { s' = { ...initial, lookedUp: true } }
  action reuseStaleResident = all {
    ready, s.claim != 0, s.wrapperEpoch > 0, s.wrapperEpoch != s.epoch,
    s' = { ...s, claim: 0, waiter: 0, residentEpoch: s.wrapperEpoch,
      pruned: publish(s.pruned, late, s.wrapperEpoch, false) },
  }
  action publishPathBeforeDrain = all {
    ready, s.epoch == 1,
    s' = { ...s, pathChanged: true, epoch: 2, usedEpoch: 0 },
  }
  action waitOnSelf = all {
    ready, s.claim != 0, s.wrapperEpoch != s.epoch,
    s' = { ...s, waiter: s.claim },
  }
  pure val readyFixture = { ...initial, stage: "ready", planEpoch: 1, usedEpoch: 1,
    startupMode: "precise", startupImages: preciseImages,
    reference: initialize(loadAll(emptyLoader, runtime, 1)),
    pruned: initialize(loadAll(emptyLoader, retained, 1)),
  }
  action initReady = s' = readyFixture
  action initFaulted = s' = { ...readyFixture, faulted: true }

  val oldReadSafe = sameObservation
  val oldWaitSafe = ownershipSafe
  val oldOrderSafe = effectsSafe
  val oldResidentSafe = residentSafe
  val oldSplitPathSafe = pathSafe
  val oldMacroPathSafe = phaseSafe
  val oldCarrierSafe = carrierSafe
  action initOldRead = s' = { ...readyFixture, control: "read" }
  action initOldWait = s' = { ...readyFixture, control: "wait", claim: 1 }
  action initOldOrder = s' = { ...readyFixture, control: "order" }
  action initOldResident = s' = {
    ...readyFixture, control: "resident", claim: 1, residentArtifact: true, epoch: 2, usedEpoch: 0,
    wrapperEpoch: 1, pruned: { ...readyFixture.pruned, images: readyFixture.pruned.images.union(Set("buffered-reader-wrapper")) },
  }
  action initOldSplitPath = s' = {
    ...initial, stage: "planned", planEpoch: 1, splitActive: true,
    opaque: true, pathRequested: true, control: "split-path",
  }
  action publishOverSplit = all {
    s.splitActive, s.opaque, s.pathRequested,
    s' = { ...s, pathChanged: true, pathRequested: false, epoch: 2 },
  }
  action initOldMacroPath = s' = { ...readyFixture, lookedUp: true, control: "macro-path" }
  action publishBeforePhase = all {
    ready, s.lookedUp, s.phaseEpoch == 0, s.epoch == 1,
    s' = { ...s, pathChanged: true, epoch: 2, usedEpoch: 0,
      pruned: loadAll(s.pruned, runtime, s.epoch) },
  }
  action initOldCarrier = s' = {
    ...initial, stage: "planned", planEpoch: 1, lookedUp: true, expanded: true, phaseEpoch: 1,
    phaseCells: transformerCells, residentArtifact: true, carrierDigest: 2, control: "carrier",
  }
  action borrowWrongBody = publishImport(retained, s.planEpoch, true)
  action initOldEagerScope = s' = { ...initial, stage: "planned", planEpoch: 1, control: "eager-scope" }
  action eagerScope = finishImport(retained.union(Set(socket)), s.planEpoch)
  action initOldUnneededFallback = s' = { ...initial, stage: "planned", planEpoch: 1, control: "unneeded-fallback" }
  action unneededFallback = finishImport(runtime, 0)
  action initOldExtraImage = s' = { ...readyFixture, control: "extra-image" }
  action extraImage = all {
    ready,
    val withProxy = s.startupImages.union(Set("import-proxy"))
    s' = { ...s, startupImages: withProxy, pruned: { ...s.pruned, images: withProxy } },
  }
  action manualDropInitializer = finishImport(retained.exclude(Set(mixed)), s.planEpoch)
  val oldEagerScopeSafe = startupExact
  val oldExtraImageSafe = startupExact
  val oldUnneededFallbackSafe = startupExact
  action step = any {
    normal,
    all { s.control == "read", skipRead },
    all { s.control == "wait", waitOnSelf },
    all { s.control == "order", replayInit },
    all { s.control == "resident", reuseStaleResident },
    all { s.control == "split-path", publishOverSplit },
    all { s.control == "macro-path", publishBeforePhase },
    all { s.control == "carrier", borrowWrongBody },
    all { s.control == "eager-scope", eagerScope },
    all { s.control == "extra-image", extraImage },
    all { s.control == "unneeded-fallback", unneededFallback },
  }

  run startupDemandTest = init.then(plan).then(commit).then(rootRead).then(demand(socket)).then(all {
    assert(safe and s.startupImages == preciseImages
      and s.pruned.images.contains("datagram") and s.reply.value == 41), s' = s,
  })
  run startupEagerScopeControlTest = initOldEagerScope.then(eagerScope).then(rootRead).then(all {
    assert(semanticSafe and not(startupExact) and s.startupImages.exclude(preciseImages) == Set("datagram")), s' = s,
  })
  run startupUnneededFallbackControlTest = initOldUnneededFallback.then(unneededFallback).then(rootRead).then(all {
    assert(semanticSafe and not(startupExact) and s.startupImages == ordinaryImages), s' = s,
  })
  run startupExtraImageControlTest = initOldExtraImage.then(extraImage).then(rootRead).then(all {
    assert(semanticSafe and not(startupExact) and s.startupImages.exclude(preciseImages) == Set("import-proxy")), s' = s,
  })
  run startupManualDropControlTest = init.then(plan).then(manualDropInitializer).then(rootRead).then(all {
    assert(sameObservation and not(effectsSafe) and not(s.startupImages.contains("mixed-init"))), s' = s,
  })

  run missingInitControlTest = initSkipInit.then(skipInit).then(all { assert(not(effectsSafe)), s' = s })
  run staleControlTest = initStale.then(keepStale).then(all { assert(not(currentPlan)), s' = s })
  run missingReadControlTest = initReady.then(skipRead).then(all { assert(not(sameObservation)), s' = s })
  run flattenedAliasControlTest = initReady.then(flattenAlias).then(all { assert(not(sameObservation)), s' = s })
  run lookupVisitControlTest = init.then(visitOnLookup).then(all { assert(not(phaseSafe)), s' = s })
  run helperPhaseControlTest = initAuxiliary.then(loseAuxiliary).then(all { assert(not(phaseSafe)), s' = s })
  run opaqueControlTest = initReady.then(skipOpaque).then(all { assert(not(opaqueSafe)), s' = s })
  run replayEffectsControlTest = initReady.then(replayInit).then(all { assert(not(effectsSafe)), s' = s })
  run staleResidentControlTest = init.then(selectResidentArtifact).then(plan).then(commit)
    .then(claimLate(2)).then(replaceBeforeDemand).then(reuseStaleResident)
    .then(all { assert(not(residentSafe)), s' = s })
  run pathBarrierControlTest = initReady.then(publishPathBeforeDrain).then(all { assert(not(pathSafe)), s' = s })
  run macroPathControlTest = initOldMacroPath.then(publishBeforePhase)
    .then(all { assert(not(oldMacroPathSafe)), s' = s })
  run staleCarrierControlTest = initOldCarrier.then(borrowWrongBody)
    .then(all { assert(not(oldCarrierSafe)), s' = s })
  run splitPathControlTest = initOldSplitPath.then(publishOverSplit)
    .then(all { assert(not(oldSplitPathSafe)), s' = s })
  run selfWaitControlTest = initOldWait.then(waitOnSelf).then(all { assert(not(oldWaitSafe)), s' = s })
  run failedPublicationControlTest = initFaulted.then(publishAfterFailure).then(all { assert(not(ownershipSafe)), s' = s })
}
