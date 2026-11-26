module gerbil_consumer_closure {
  // Family 11 (11/12: gerbil) downstream consumer producer/ABI closure model.
  // Stages 0..7: boot-gxi, stage0, stage1, stdlib, libgerbil, lang, tools, correctness.
  // Enforces one sealed Gambit producer, exhaustive 4-way dynamic .o1 ABI closure
  // (___IMP_FUNC <-> ___GSTATE <-> setup.c <-> ___EXT, including ___publish_raw_stack_span),
  // precise invalidation on compiler/source delta, and refusal of mixed-ABI reuse
  // or partial-stage promotion.

  pure val TOTAL_STAGES = 8

  type State = {
    activeProducer: int,
    activeAbiSeal: int,
    // 4-way dynamic .o1 export closure (all macro-called ___IMP_FUNC exported via ___GSTATE/___EXT)
    dynamicAbiClosed: bool,
    // For each stage 0..7, stores producer ID that built it (0 = unbuilt/invalidated)
    stageProducer: int -> int,
    stageAbiSeal: int -> int,
    familyAdmitted: bool,
    // Violation flags
    mixedAbiAdmitted: bool,
    partialStagePromoted: bool,
    unexportedDynamicSymbol: bool
  }

  var s: State

  action init = {
    s' = {
      activeProducer: 12,
      activeAbiSeal: 102,
      dynamicAbiClosed: true,
      stageProducer: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0, 7 -> 0),
      stageAbiSeal: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0, 7 -> 0),
      familyAdmitted: false,
      mixedAbiAdmitted: false,
      partialStagePromoted: false,
      unexportedDynamicSymbol: false
    }
  }

  // Build stage k using the active sealed producer only if k == 0 or stage k-1 matches activeProducer & activeAbiSeal
  // Dynamic .o1 compilation stages (k >= 1) additionally require 4-way dynamicAbiClosed.
  action buildStage(k: int): bool = all {
    k >= 0 and k < TOTAL_STAGES,
    (k == 0) or (s.dynamicAbiClosed and s.stageProducer.get(k - 1) == s.activeProducer and s.stageAbiSeal.get(k - 1) == s.activeAbiSeal),
    s' = {
      ...s,
      stageProducer: s.stageProducer.set(k, s.activeProducer),
      stageAbiSeal: s.stageAbiSeal.set(k, s.activeAbiSeal),
      familyAdmitted: false
    }
  }

  // Scheme compiler driver.ss delta invalidates stage1 (2) through correctness (7), keeping boot-gxi (0) & stage0 (1)
  action applyDriverSourceDelta = all {
    s.stageProducer.get(1) == s.activeProducer,
    s' = {
      ...s,
      stageProducer: s.stageProducer.set(2, 0).set(3, 0).set(4, 0).set(5, 0).set(6, 0).set(7, 0),
      stageAbiSeal: s.stageAbiSeal.set(2, 0).set(3, 0).set(4, 0).set(5, 0).set(6, 0).set(7, 0),
      familyAdmitted: false
    }
  }

  // Upgrading Gambit producer/ABI invalidates all 8 downstream stages
  action upgradeGambitProducer(newProd: int, newAbi: int): bool = all {
    newProd > s.activeProducer,
    newAbi > s.activeAbiSeal,
    s' = {
      ...s,
      activeProducer: newProd,
      activeAbiSeal: newAbi,
      stageProducer: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0, 7 -> 0),
      stageAbiSeal: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0, 7 -> 0),
      familyAdmitted: false
    }
  }

  // Admit Family 11 only when dynamicAbiClosed holds and all 8 stages bind the exact same activeProducer and activeAbiSeal
  action admitGerbilFamily = all {
    s.dynamicAbiClosed,
    0.to(TOTAL_STAGES - 1).forall(k =>
      s.stageProducer.get(k) == s.activeProducer and s.stageAbiSeal.get(k) == s.activeAbiSeal
    ),
    s' = { ...s, familyAdmitted: true }
  }

  // Negative fault: a header macro calls a bare ___IMP_FUNC (e.g. ___publish_raw_stack_span)
  // without ___GSTATE/___EXT export, breaking Darwin -bundle -D___DYNAMIC stage0 linking.
  action faultUnexportedDynamicSymbol = all {
    s.stageProducer.get(0) == s.activeProducer,
    s' = { ...s, dynamicAbiClosed: false, unexportedDynamicSymbol: true }
  }

  // Negative fault: reuse stage k-1 from an older producer under a new Gambit producer
  action faultMixedProducerStage(k: int): bool = all {
    k >= 1 and k < TOTAL_STAGES,
    s.stageProducer.get(k - 1) != s.activeProducer,
    s' = { ...s, stageProducer: s.stageProducer.set(k, s.activeProducer), mixedAbiAdmitted: true }
  }

  // Negative fault: promote Family 11 when not all 8 stages are built on activeProducer
  action faultPromotePartialStages = all {
    not(0.to(TOTAL_STAGES - 1).forall(k =>
      s.stageProducer.get(k) == s.activeProducer and s.stageAbiSeal.get(k) == s.activeAbiSeal
    )),
    s' = { ...s, familyAdmitted: true, partialStagePromoted: true }
  }

  action step = any {
    nondet k = oneOf(Set(0, 1, 2, 3, 4, 5, 6, 7))
    buildStage(k),
    applyDriverSourceDelta,
    upgradeGambitProducer(s.activeProducer + 1, s.activeAbiSeal + 1),
    admitGerbilFamily
  }

  val safe = and {
    not(s.mixedAbiAdmitted),
    not(s.partialStagePromoted),
    not(s.unexportedDynamicSymbol),
    s.familyAdmitted implies (s.dynamicAbiClosed and 0.to(TOTAL_STAGES - 1).forall(k =>
      s.stageProducer.get(k) == s.activeProducer and s.stageAbiSeal.get(k) == s.activeAbiSeal
    ))
  }

  run fullEightStageSameProducerClosureTest =
    init
      .then(buildStage(0))
      .then(buildStage(1))
      .then(buildStage(2))
      .then(buildStage(3))
      .then(buildStage(4))
      .then(buildStage(5))
      .then(buildStage(6))
      .then(buildStage(7))
      .then(admitGerbilFamily)
      .expect(s.familyAdmitted and s.dynamicAbiClosed and safe)

  run driverDeltaInvalidatesFromStage1Test =
    init
      .then(buildStage(0))
      .then(buildStage(1))
      .then(buildStage(2))
      .then(buildStage(3))
      .then(applyDriverSourceDelta)
      .expect(s.stageProducer.get(1) == 12 and s.stageProducer.get(2) == 0 and not(s.familyAdmitted) and safe)

  run mixedProducerImageRefusedTest =
    init
      .then(buildStage(0))
      .then(buildStage(1))
      .then(upgradeGambitProducer(13, 103))
      .then(faultMixedProducerStage(2))
      .expect(not(safe) and s.mixedAbiAdmitted)

  run partialStageNoPromotionControlTest =
    init
      .then(buildStage(0))
      .then(buildStage(1))
      .then(buildStage(2))
      .then(faultPromotePartialStages)
      .expect(not(safe) and s.partialStagePromoted)

  run unexportedDynamicSymbolFailsStage0Test =
    init
      .then(buildStage(0))
      .then(faultUnexportedDynamicSymbol)
      .expect(not(safe) and not(s.dynamicAbiClosed) and s.unexportedDynamicSymbol)
}
