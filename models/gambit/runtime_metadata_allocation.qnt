module runtime_metadata_allocation {
  // Fixed histories assume a uniformly rebuilt repaired runtime/generated-C
  // configuration. Bad policies are counterexamples, not supported legacy
  // execution modes or mixed-binary compatibility paths.
  // Experimental reservation/publication and reader-topology contracts.
  // profile 0 reserves words; profile 1 looks up B during A->B rehash;
  // profile 2 distinguishes slot-count and complete-record publication;
  // profile 3 composes leaf resource ordering with independent reservation;
  // profile 4 rolls back the new private guard/memory setup prefix.
  // Separate profiles do not prove table/weak-memory/GC composition.
  // Two requests expose interference; this is not a runtime worker limit.
  // Separate publication projection: slot/count coverage is not full record
  // readiness. Visibility is an abstract required edge, not a C11 simulator.
  type Publication = { policy: int, phase: int, slots: bool, prm: bool,
    count: bool, binding: bool, visibleRecord: bool,
    gcObserved: bool, recordObserved: bool, badGc: bool, badRecord: bool }
  pure def publicationInitial(policy: int): Publication = {
    policy: policy, phase: 0, slots: false, prm: false, count: false,
    binding: false, visibleRecord: false, gcObserved: false,
    recordObserved: false, badGc: false, badRecord: false,
  }
  // Resource composition of the proposed leaf package, not existing C locks.
  // Resources: 0 registry, 1 metadata, 2 permanent reservation. Commands:
  // nonnegative acquire; -1 reserve; -2/-3/-4 release; -5 stale snapshot.
  // Three operations are witnesses, not a native concurrency setting.
  type Package = { policy: int, pc: int -> int, owner: int -> int,
    cursor: int, stale: int, base: int -> int, reserved: Set[int] }
  pure def packageInitial(policy: int): Package = {
    policy: policy, pc: Map(0 -> 0, 1 -> 0, 2 -> 0),
    owner: Map(0 -> -1, 1 -> -1, 2 -> -1), cursor: 0, stale: 0,
    base: Map(0 -> 0, 1 -> 0, 2 -> 0), reserved: Set(),
  }
  pure def program(policy: int, i: int): List[int] =
    if (i == 0) {
      if (policy == 1) List(1, 0, 2, -1, -4, -2, -3)
      else if (policy == 3) List(1, 1, 2, -1, -4, -3)
      else List(1, 2, -1, -4, -3)
    } else if (i == 1) List(0, 1, 2, -1, -4, -3, -2)
    else if (policy == 2) List(-5, -1)
    else List(2, -1, -4)
  // 0/1 are prospective P/M initialization, 2/3 first/second table attempts.
  // Owned resource 2 denotes entered memory setup, including partial storage.
  // Retry is before publication only. Existing V/OS/interrupts and module
  // generation are outside this projection and keep their own obligations.
  type Prefix = { policy: int, phase: int, attempt: int, failAt: int,
    owned: Set[int], leaked: bool, invalidDestroy: bool }
  pure def prefixInitial(policy: int, failAt: int): Prefix = {
    policy: policy, phase: 0, attempt: 0, failAt: failAt,
    owned: Set(), leaked: false, invalidDestroy: false,
  }
  // Separate same-key commit projection. A preliminary miss is not a right
  // to create after waiting. Best-effort growth follows successful insertion.
  // Policies: correct; skip owned recheck; report growth OOM as insert failure;
  // retract the committed key after growth OOM. No new runtime mode is added.
  type KeyCommit = { policy: int, pc: int -> int, owner: int, binding: int,
    live: Set[int], ready: Set[int], misses: Set[int], result: int -> int,
    error: int -> int, allocFail: int, growFails: bool, allocations: int }
  pure def keyInitial(policy: int, allocFail: int, growFails: bool): KeyCommit = {
    policy: policy, pc: Map(0 -> 0, 1 -> 0), owner: -1, binding: 0,
    live: Set(), ready: Set(), misses: Set(), result: Map(0 -> 0, 1 -> 0),
    error: Map(0 -> 0, 1 -> 0), allocFail: allocFail, growFails: growFails,
    allocations: 0,
  }
  type State = { policy: int, cursor: int, stage: int -> int,
    size: int -> int, snapshot: int -> int, base: int -> int,
    ready: Set[int], published: Set[int], profile: int,
    readerPhase: int, readerNode: int, found: bool,
    rehashPhase: int, nextA: int, publication: Publication, package: Package,
    prefix: Prefix, key: KeyCommit }
  var s: State
  pure def initial(policy: int, a: int, b: int): State = {
    policy: policy, cursor: 0, stage: Map(0 -> 0, 1 -> 0),
    size: Map(0 -> a, 1 -> b), snapshot: Map(0 -> 0, 1 -> 0),
    base: Map(0 -> 0, 1 -> 0), ready: Set(), published: Set(),
    profile: 0, readerPhase: 0, readerNode: -1, found: false,
    rehashPhase: 0, nextA: 1, publication: publicationInitial(0),
    package: packageInitial(0),
    prefix: prefixInitial(0, 4),
    key: keyInitial(0, -1, false),
  }
  action initFixed = {
    nondet a = Set(1, 2).oneOf()
    nondet b = Set(1, 2).oneOf()
    nondet profile = Set(0, 1, 2, 3, 4).oneOf()
    nondet failAt = Set(0, 1, 2, 3, 4).oneOf()
    s' = { ...initial(0, a, b), profile: profile,
      prefix: prefixInitial(0, if (profile == 4) failAt else 4) }
  }
  action initSplitReservation = s' = initial(1, 2, 1)
  action initEarlyPublish = s' = initial(2, 2, 1)
  // Exactly one writer: writer-writer serialization cannot protect readers.
  action initUnprotectedRehash = s' = { ...initial(3, 1, 1), profile: 1 }
  action readCursor(i: int): bool = all {
    s.profile == 0,
    s.stage.get(i) == 0,
    s' = { ...s, stage: s.stage.set(i, 1),
      snapshot: s.snapshot.set(i, s.cursor) },
  }
  action reserve(i: int): bool = {
    val start = if (s.policy == 1) s.snapshot.get(i) else s.cursor
    all {
      s.profile == 0,
      s.stage.get(i) == 1,
      s' = { ...s, stage: s.stage.set(i, 2), base: s.base.set(i, start),
        cursor: start + s.size.get(i) },
    }
  }
  action initialize(i: int): bool = all {
    s.profile == 0,
    s.stage.get(i) == 2,
    s' = { ...s, stage: s.stage.set(i, 3), ready: s.ready.union(Set(i)) },
  }
  action publish(i: int): bool = all {
    s.profile == 0,
    s.stage.get(i) == 3 or (s.policy == 2 and s.stage.get(i) == 2),
    s' = { ...s, stage: s.stage.set(i, 4), published: s.published.union(Set(i)) },
  }
  // B remains logically present. Old bucket A->B becomes new buckets A / B.
  // Retaining old heads does not retain the old NEXT topology.
  action beginLookup = all {
    s.profile == 1, s.readerPhase == 0,
    s.policy == 3 or s.rehashPhase == 0 or s.rehashPhase == 3,
    s' = { ...s, readerPhase: 1,
      readerNode: if (s.rehashPhase == 3) 1 else 0 },
  }
  action visitNode = all {
    s.profile == 1, s.readerPhase == 1,
    s' = if (s.readerNode == 0) { ...s, readerNode: s.nextA }
      else { ...s, readerPhase: 2, found: s.readerNode == 1 },
  }
  action beginRehash = all {
    s.profile == 1, s.rehashPhase == 0,
    s.policy == 3 or s.readerPhase != 1,
    s' = { ...s, rehashPhase: 1 },
  }
  action relinkA = all {
    s.profile == 1, s.rehashPhase == 1,
    s' = { ...s, rehashPhase: 2, nextA: -1 },
  }
  action publishRehash = all {
    s.profile == 1, s.rehashPhase == 2,
    s' = { ...s, rehashPhase: 3 },
  }
  val terminal = if (s.profile == 0)
    s.stage.get(0) == 4 and s.stage.get(1) == 4
    else if (s.profile == 1) s.readerPhase == 2 and s.rehashPhase == 3
    else if (s.profile == 2) publicationTerminal
    else if (s.profile == 3) packageTerminal else prefixTerminal
  action finished = all { terminal, s' = s }
  action step = {
    nondet i = Set(0, 1).oneOf()
    any { readCursor(i), reserve(i), initialize(i), publish(i),
      beginLookup, visitNode, beginRehash, relinkA, publishRehash,
      publicationStep, packageStep, prefixStep, finished }
  }
  val reservationSafe = s.stage.get(0) < 2 or s.stage.get(1) < 2 or
    s.base.get(0) + s.size.get(0) <= s.base.get(1) or
    s.base.get(1) + s.size.get(1) <= s.base.get(0)
  val publicationSafe = s.published.subseteq(s.ready)
  val readerSafe = s.profile != 1 or s.readerPhase != 2 or s.found
  val safe = reservationSafe and publicationSafe and readerSafe and
    (s.profile != 2 or recordPublicationSafe) and
    (s.profile != 3 or packageSafe) and (s.profile != 4 or prefixSafe)
  temporal completion = weakFair(step, s).implies(eventually(terminal))

  action initRecordPublication = s' = { ...initial(0, 1, 1), profile: 2 }
  action initCountAsRecord = s' = { ...initial(0, 1, 1), profile: 2, publication: publicationInitial(1) }
  action initUnorderedBinding = s' = { ...initial(0, 1, 1), profile: 2, publication: publicationInitial(2) }
  action prepareSlots = all {
    s.publication.phase == 0,
    s' = { ...s, publication: { ...s.publication, phase: 1, slots: true } },
  }
  // Current source's count can precede prm initialization; a GC slot reader
  // and a record reader therefore cannot borrow one another's readiness.
  action publishSlotCount = all {
    s.publication.phase == 1,
    s' = { ...s, publication: { ...s.publication, phase: 2, count: true } },
  }
  action initializeRecord = all {
    s.publication.phase == 2,
    s' = { ...s, publication: { ...s.publication, phase: 3, prm: true } },
  }
  action publishBinding = all {
    s.publication.phase == 3,
    s' = { ...s, publication: { ...s.publication, phase: 4, binding: true,
      visibleRecord: s.publication.policy != 2 } },
  }
  action observeSlots = all {
    s.publication.count, not(s.publication.gcObserved),
    s' = { ...s, publication: { ...s.publication, gcObserved: true,
      badGc: not(s.publication.slots) } },
  }
  action observeRecord = all {
    not(s.publication.recordObserved),
    if (s.publication.policy == 1) s.publication.count else s.publication.binding,
    s' = { ...s, publication: { ...s.publication, recordObserved: true,
      badRecord: not(s.publication.prm and s.publication.binding and s.publication.visibleRecord) } },
  }
  val publicationTerminal = s.publication.phase == 4 and
    s.publication.gcObserved and s.publication.recordObserved
  action publicationFinished = all { publicationTerminal, s' = s }
  action publicationStep = all {
    s.profile == 2,
    any { prepareSlots, publishSlotCount, initializeRecord,
      publishBinding, observeSlots, observeRecord, publicationFinished },
  }
  val slotReaderSafe = not(s.publication.badGc)
  val recordReaderSafe = not(s.publication.badRecord)
  val orderedBindingSafe = not(s.publication.badRecord)
  val recordPublicationSafe = slotReaderSafe and recordReaderSafe
  temporal publicationCompletion = weakFair(publicationStep, s).implies(eventually(publicationTerminal))

  action initReverseRegistryOrder = s' = { ...initial(0, 1, 1), profile: 3, package: packageInitial(1) }
  action initArenaBypass = s' = { ...initial(0, 1, 1), profile: 3, package: packageInitial(2) }
  action initMetadataCallback = s' = { ...initial(0, 1, 1), profile: 3, package: packageInitial(3) }
  pure def command(p: Package, i: int): int =
    if (p.pc.get(i) < program(p.policy, i).length())
      program(p.policy, i).nth(p.pc.get(i)) else -9
  action packageAction(i: int): bool = {
    val p = s.package
    val cmd = command(p, i)
    val advanced = { ...p, pc: p.pc.set(i, p.pc.get(i) + 1) }
    val acquireResource = if (cmd >= 0) cmd else 0
    val releaseResource = if (cmd <= -2 and cmd >= -4) -cmd - 2 else 0
    val start = if (p.policy == 2 and i == 2) p.stale else p.cursor
    any {
      all { cmd >= 0, p.owner.get(acquireResource) == -1,
        s' = { ...s, package: { ...advanced, owner: p.owner.set(acquireResource, i) } } },
      all { cmd == -1,
        p.owner.get(2) == i or (p.policy == 2 and i == 2),
        s' = { ...s, package: { ...advanced, cursor: start + 1,
          base: p.base.set(i, start), reserved: p.reserved.union(Set(i)) } },
      },
      all { cmd <= -2, cmd >= -4,
        p.owner.get(releaseResource) == i,
        s' = { ...s, package: { ...advanced, owner: p.owner.set(releaseResource, -1) } },
      },
      all { cmd == -5,
        s' = { ...s, package: { ...advanced, stale: p.cursor } } },
    }
  }
  val packageTerminal = Set(0, 1, 2).forall(i =>
    s.package.pc.get(i) == program(s.package.policy, i).length())
  action packageStep = all {
    s.profile == 3,
    nondet i = Set(0, 1, 2).oneOf()
    any { packageAction(i), all { packageTerminal, s' = s } },
  }
  val packageOrderSafe = not(s.package.owner.get(1) == 0 and
    s.package.owner.get(0) == 1 and command(s.package, 0) == 0 and
    command(s.package, 1) == 1)
  val packageCallbackSafe = not(s.package.owner.get(1) == 0 and
    command(s.package, 0) == 1)
  val packageReservationSafe = Set(0, 1, 2).forall(i =>
    Set(0, 1, 2).forall(j => i == j or not(s.package.reserved.contains(i)) or
      not(s.package.reserved.contains(j)) or s.package.base.get(i) != s.package.base.get(j)))
  val packageSafe = packageOrderSafe and packageCallbackSafe and packageReservationSafe

  action initLeakedPrivatePrefix = s' = { ...initial(0, 1, 1),
    profile: 4, prefix: prefixInitial(1, 3) }
  action initDestroyBeforeInit = s' = { ...initial(0, 1, 1),
    profile: 4, prefix: prefixInitial(2, 0) }
  action initializePrefix = all {
    s.prefix.phase < 4, s.prefix.phase != s.prefix.failAt,
    s' = { ...s, prefix: { ...s.prefix, phase: s.prefix.phase + 1,
      owned: s.prefix.owned.union(Set(if (s.prefix.phase < 2)
        s.prefix.phase else 2)) } },
  }
  action failPrefix = all {
    s.prefix.phase < 4, s.prefix.phase == s.prefix.failAt,
    s' = { ...s, prefix: { ...s.prefix, phase: 5,
      owned: if (s.prefix.phase == 2) s.prefix.owned.union(Set(2))
        else s.prefix.owned } },
  }
  action rollbackPrefix = {
    val resource = if (s.prefix.owned.contains(2)) 2
      else if (s.prefix.owned.contains(1)) 1 else 0
    all {
      s.prefix.phase == 5, s.prefix.policy != 1,
      s.prefix.owned != Set(),
      s' = { ...s, prefix: { ...s.prefix,
        owned: s.prefix.owned.exclude(Set(resource)) } },
    }
  }
  action destroyBeforeInit = all {
    s.prefix.phase == 5, s.prefix.policy == 2,
    not(s.prefix.invalidDestroy),
    s' = { ...s, prefix: { ...s.prefix,
      invalidDestroy: not(s.prefix.owned.contains(1)) } },
  }
  action retryPrivatePrefix = all {
    s.prefix.phase == 5, s.prefix.attempt == 0,
    s.prefix.owned == Set() or s.prefix.policy == 1,
    s' = { ...s, prefix: { ...s.prefix, phase: 0, attempt: 1,
      failAt: 4, owned: Set(), leaked: s.prefix.owned != Set() } },
  }
  val prefixTerminal = s.prefix.phase == 4
  action prefixStep = all {
    s.profile == 4,
    any { initializePrefix, failPrefix, rollbackPrefix,
      destroyBeforeInit, retryPrivatePrefix,
      all { prefixTerminal, s' = s } },
  }
  val privatePrefixReleased = not(s.prefix.leaked)
  val initializedOnlyDestroyed = not(s.prefix.invalidDestroy)
  val prefixSafe = privatePrefixReleased and initializedOnlyDestroyed and
    (not(prefixTerminal) or s.prefix.owned == Set(0, 1, 2))

  action initKeyCommit = {
    nondet allocFail = Set(-1, 0, 1).oneOf()
    nondet growFails = Set(false, true).oneOf()
    s' = { ...initial(0, 1, 1), key: keyInitial(0, allocFail, growFails) }
  }
  action initStaleKeyMiss = s' = { ...initial(0, 1, 1), key: keyInitial(1, -1, false) }
  action initGrowthError = s' = { ...initial(0, 1, 1), key: keyInitial(2, -1, true) }
  action initGrowthRollback = s' = { ...initial(0, 1, 1), key: keyInitial(3, -1, true) }
  action probeKey(i: int): bool = all {
    s.key.pc.get(i) == 0,
    s' = { ...s, key: { ...s.key,
      pc: s.key.pc.set(i, if (s.key.binding == 0) 1 else 6),
      misses: if (s.key.binding == 0) s.key.misses.union(Set(i)) else s.key.misses,
      result: s.key.result.set(i, s.key.binding) } },
  }
  action acquireKey(i: int): bool = all {
    s.key.pc.get(i) == 1, s.key.owner == -1,
    s' = { ...s, key: { ...s.key, owner: i, pc: s.key.pc.set(i, 2) } },
  }
  action recheckKey(i: int): bool = {
    val create = if (s.key.policy == 1) s.key.misses.contains(i) else s.key.binding == 0
    all {
      s.key.pc.get(i) == 2, s.key.owner == i,
      s' = { ...s, key: { ...s.key, pc: s.key.pc.set(i, if (create) 3 else 6),
        result: s.key.result.set(i, if (create) 0 else s.key.binding),
        owner: if (create) i else -1 } },
    }
  }
  action prepareKey(i: int): bool = {
    val failed = s.key.allocFail == i
    all {
      s.key.pc.get(i) == 3, s.key.owner == i,
      s' = { ...s, key: { ...s.key, pc: s.key.pc.set(i, if (failed) 6 else 4),
        owner: if (failed) -1 else i,
        error: s.key.error.set(i, if (failed) 7 else 0),
        ready: if (failed) s.key.ready else s.key.ready.union(Set(i + 1)),
        allocations: s.key.allocations + (if (failed) 0 else 1) } },
    }
  }
  // Complete typed initialization and topology/count commit are abstracted.
  // This does not establish actual C visibility or global-variable slot roots.
  action commitKey(i: int): bool = all {
    s.key.pc.get(i) == 4, s.key.owner == i,
    s' = { ...s, key: { ...s.key, binding: i + 1,
      live: s.key.live.union(Set(i + 1)), result: s.key.result.set(i, i + 1),
      pc: s.key.pc.set(i, 5) } },
  }
  action finishKeyGrowth(i: int): bool = {
    val retract = s.key.growFails and s.key.policy == 3
    all {
      s.key.pc.get(i) == 5, s.key.owner == i,
      s' = { ...s, key: { ...s.key, owner: -1, pc: s.key.pc.set(i, 6),
        error: s.key.error.set(i, if (s.key.growFails and s.key.policy == 2) 7 else 0),
        binding: if (retract) 0 else s.key.binding,
        live: if (retract) s.key.live.exclude(Set(i + 1)) else s.key.live } },
    }
  }
  val keyTerminal = Set(0, 1).forall(i => s.key.pc.get(i) == 6) and s.key.owner == -1
  action keyFinished = all { keyTerminal, s' = s }
  action keyStep = {
    nondet i = Set(0, 1).oneOf()
    any { probeKey(i), acquireKey(i), recheckKey(i), prepareKey(i), commitKey(i),
      finishKeyGrowth(i), keyFinished }
  }
  val keyCanonicalSafe = s.key.live.size() <= 1
  val keyOutcomeSafe = Set(0, 1).forall(i =>
    s.key.result.get(i) == 0 or s.key.error.get(i) == 0)
  val keyRetentionSafe = Set(0, 1).forall(i =>
    s.key.result.get(i) == 0 or s.key.live.contains(s.key.result.get(i)))
  val keySafe = keyCanonicalSafe and keyOutcomeSafe and keyRetentionSafe and
    s.key.live.subseteq(s.key.ready) and s.key.allocations <= 1
  temporal keyCompletion = weakFair(keyStep, s).implies(eventually(keyTerminal))
}
