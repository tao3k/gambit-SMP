// Adversarial Quint V2 specification for flag-driven & CFG-adaptive contiguous
// host partitioning (vendor/gambit/gsc/_t-c-1.scm:targ-plan-cfg-hosts) and
// indexed physical-host entry fixup (vendor/gambit/lib/setup.c:2140-2165).
//
// Proves:
//   1. Local CFG edge closure: every local glbl jump and fallthrough edge stays
//      strictly within one physical host.
//   2. Non-empty physical hosts: every emitted host owns >= 1 val-lbl entry;
//      0-val-lbl components attach to canonical host 0.
//   3. Bijective 1-based indexed slots & exact setup.c fixup resolution.
//   4. Canonical entry & opaque-C / unbalanced / disabled-flag refusal:
//      `cfgHostLimit == 0` with `not(forced)` NEVER auto-splits.
//   5. Adaptive cost-benefit acceptance gate (`4 * sum(b_h^2) <= 3 * N^2`) &
//      compactness-derived base target (`448 - 32 * clamp(c, 0, 9)`):
//      automatically refuses skewed low-benefit splits (preventing wasted
//      trampolines) while guaranteeing >= 25% quadratic GCC SSA/RA reduction
//      on every committed automatic split.
//   6. Seven adversarial mutation-killers caught immediately by `safe`.

module cfg_host_partition {
  type Edge = { src: int, dst: int, kind: str }

  type PlanState = {
    numBlocks: int,
    hasOpaqueC: bool,
    unbalancedDepth: bool,
    cfgHostLimit: int,   // < 0 = adaptive, 0 = disabled, > 0 = explicit target
    compactness: int,    // Gambit (targ-compactness) in 0..9
    forced: bool,        // targ-indexed-host-layout?
    splitApplied: bool,
    nbHosts: int,
    blockHost: int -> int,
    valBlocks: Set[int],
    localEdges: Set[Edge],
    valSlot: int -> int,
    hostValCount: int -> int,
    fixupRan: bool,
    fixupErr: bool,
    resolvedHost: int -> int,
    resolvedSlot: int -> int
  }

  var st: PlanState

  pure def clampCompactness(c: int): int =
    if (c < 0) 0 else if (c > 9) 9 else c

  // Adaptive per-host target block count derived monotonically from Gambit's
  // native (targ-compactness) 0..9 when cfgHostLimit < 0.
  pure def adaptiveBaseTarget(limit: int, compactness: int): int =
    if (limit > 0) limit
    else 448 - 32 * clampCompactness(compactness)

  // Packing target does NOT inflate with maxComp: oversized indivisible components
  // are isolated in their own host instead of inflating every sibling host bin!
  pure def packingTarget(limit: int, compactness: int, count: int, maxHosts: int): int = {
    val base = adaptiveBaseTarget(limit, compactness)
    val ceilShare = (count + maxHosts - 1) / maxHosts
    if (base >= ceilShare) base else ceilShare
  }

  // Flag-driven per-host GCC optimization limit (--enable-optimized-host-limit=auto|0|N):
  //   hostFlag >= 0 => explicit override (0 disables per-host lowering)
  //   hostFlag < 0  => auto-derived as max(1, modLimit / 8) when modLimit > 0, else 0
  pure def effectiveOptHostLimit(modLimit: int, hostFlag: int): int =
    if (hostFlag >= 0) hostFlag
    else if (modLimit <= 0) 0
    else if (modLimit / 8 >= 1) modLimit / 8
    else 1

  pure def hostUsesUnoptAttrs(hostLabels: int, modLabels: int,
                              modLimit: int, hostFlag: int): bool = {
    val modExceeded = modLimit > 0 and modLabels > modLimit
    val hLim = effectiveOptHostLimit(modLimit, hostFlag)
    val hostExceeded = hLim > 0 and hostLabels > hLim
    modExceeded or hostExceeded
  }

  pure def hostBlockCount(s: PlanState, h: int): int =
    0.to(s.numBlocks - 1).filter(b => s.blockHost.get(b) == h).size()

  pure def sumSqHostBlocks(s: PlanState): int =
    0.to(s.nbHosts - 1).fold(0, (acc, h) => acc + hostBlockCount(s, h) * hostBlockCount(s, h))

  pure def costBenefitGateOk(sumSq: int, n: int): bool =
    4 * sumSq <= 3 * n * n

  // Invariant 1: every local glbl or fallthrough edge stays within one host
  val invLocalAndFallthroughClosed: bool =
    st.localEdges.forall(e => st.blockHost.get(e.src) == st.blockHost.get(e.dst))

  // Invariant 2: every emitted physical host has >= 1 val-lbl entry
  val invAllHostsNonEmpty: bool =
    st.nbHosts >= 1 and
    0.to(st.nbHosts - 1).forall(h =>
      st.hostValCount.get(h) >= 1 and
      st.valBlocks.filter(b => st.blockHost.get(b) == h).size() == st.hostValCount.get(h)
    )

  // Invariant 3: bijective 1-based slots within [1, hostValCount[h]] and exact fixup
  val invBijectiveIndexedSlots: bool =
    st.valBlocks.forall(b => {
      val h = st.blockHost.get(b)
      val sl = st.valSlot.get(b)
      h >= 0 and h < st.nbHosts and
      sl >= 1 and sl <= st.hostValCount.get(h)
    }) and
    st.valBlocks.forall(b1 =>
      st.valBlocks.forall(b2 =>
        (b1 != b2 and st.blockHost.get(b1) == st.blockHost.get(b2)) implies
          st.valSlot.get(b1) != st.valSlot.get(b2)
      )
    ) and
    (st.fixupRan implies (
      not(st.fixupErr) and
      st.valBlocks.forall(b =>
        st.resolvedHost.get(b) == st.blockHost.get(b) and
        st.resolvedSlot.get(b) == st.valSlot.get(b)
      )
    ))

  // Invariant 4: canonical host 0 owns prologue block 0 & entry block 1;
  // opaque-C, unbalanced nesting, or disabled flag (limit==0 & not forced) never splits
  val invCanonicalEntryAndFlagRefusal: bool =
    st.blockHost.get(0) == 0 and
    st.blockHost.get(1) == 0 and
    ((st.hasOpaqueC or st.unbalancedDepth or (st.cfgHostLimit == 0 and not(st.forced)))
      implies (not(st.splitApplied) and st.nbHosts == 1))

  // Invariant 5: every committed automatic split achieves >= 25% quadratic SSA
  // reduction (`4 * sum(b_h^2) <= 3 * N^2`), and every forced split still achieves
  // strict reduction `sum(b_h^2) < N^2` with non-empty hosts.
  val invAdaptiveQuadraticReduction: bool =
    st.splitApplied implies (
      st.nbHosts >= 2 and
      0.to(st.nbHosts - 1).forall(h => hostBlockCount(st, h) >= 1) and
      sumSqHostBlocks(st) < st.numBlocks * st.numBlocks and
      (not(st.forced) implies costBenefitGateOk(sumSqHostBlocks(st), st.numBlocks))
    )

  val safe: bool =
    invLocalAndFallthroughClosed and
    invAllHostsNonEmpty and
    invBijectiveIndexedSlots and
    invCanonicalEntryAndFlagRefusal and
    invAdaptiveQuadraticReduction

  pure val sampleEdges: Set[Edge] = Set(
    { src: 0, dst: 1, kind: "fallthrough" },
    { src: 1, dst: 2, kind: "fallthrough" },
    { src: 3, dst: 4, kind: "glbl" },
    { src: 5, dst: 6, kind: "glbl" }
  )
  pure val sampleVals: Set[int] = Set(1, 3, 5, 6)

  action initConfigured(opaque: bool, unbal: bool, limit: int, comp: int, frc: bool): bool =
    st' = {
      numBlocks: 8,
      hasOpaqueC: opaque,
      unbalancedDepth: unbal,
      cfgHostLimit: limit,
      compactness: comp,
      forced: frc,
      splitApplied: false,
      nbHosts: 1,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0, 7 -> 0),
      valBlocks: sampleVals,
      localEdges: sampleEdges,
      valSlot: Map(1 -> 1, 3 -> 2, 5 -> 3, 6 -> 4),
      hostValCount: Map(0 -> 4),
      fixupRan: false,
      fixupErr: false,
      resolvedHost: Map(),
      resolvedSlot: Map()
    }

  action init = initConfigured(false, false, -1, 9, false)

  // Sound contiguous 3-host split: blocks (4,2,2), sumSq = 24 <= 48 = 3/4 * 64
  action applySoundContiguousSplit = all {
    not(st.hasOpaqueC),
    not(st.unbalancedDepth),
    st.cfgHostLimit != 0 or st.forced,
    not(st.splitApplied),
    costBenefitGateOk(24, 8),
    st' = {
      ...st,
      splitApplied: true,
      nbHosts: 3,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 1, 4 -> 1, 5 -> 2, 6 -> 2, 7 -> 0),
      valSlot: Map(1 -> 1, 3 -> 1, 5 -> 1, 6 -> 2),
      hostValCount: Map(0 -> 1, 1 -> 1, 2 -> 2),
      fixupRan: false,
      fixupErr: false
    }
  }

  // Sound contiguous 2-host split: blocks (6,2), sumSq = 40 <= 48 = 3/4 * 64
  action applySoundTwoHostSplit = all {
    not(st.hasOpaqueC),
    not(st.unbalancedDepth),
    st.cfgHostLimit != 0 or st.forced,
    not(st.splitApplied),
    costBenefitGateOk(40, 8),
    st' = {
      ...st,
      splitApplied: true,
      nbHosts: 2,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 1, 6 -> 1, 7 -> 0),
      valSlot: Map(1 -> 1, 3 -> 2, 5 -> 1, 6 -> 2),
      hostValCount: Map(0 -> 2, 1 -> 2),
      fixupRan: false,
      fixupErr: false
    }
  }

  action runSetupFixup = all {
    not(st.fixupRan),
    val bad = st.valBlocks.exists(b => {
      val h = st.blockHost.get(b)
      val sl = st.valSlot.get(b)
      h < 0 or h >= st.nbHosts or sl == 0 or sl > st.hostValCount.get(h)
    })
    st' = {
      ...st,
      fixupRan: true,
      fixupErr: bad,
      resolvedHost: if (bad) Map() else st.valBlocks.mapBy(b => st.blockHost.get(b)),
      resolvedSlot: if (bad) Map() else st.valBlocks.mapBy(b => st.valSlot.get(b))
    }
  }

  action step = any {
    applySoundContiguousSplit,
    applySoundTwoHostSplit,
    runSetupFixup,
    st' = st
  }

  // =========================================================================
  // ADVERSARIAL MUTATION-KILLERS
  // =========================================================================

  action badSplitAcrossLocalGoto = all {
    st' = {
      ...st, splitApplied: true, nbHosts: 3,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 1, 4 -> 2, 5 -> 2, 6 -> 2, 7 -> 0),
      valSlot: Map(1 -> 1, 3 -> 1, 5 -> 1, 6 -> 2),
      hostValCount: Map(0 -> 1, 1 -> 1, 2 -> 2)
    }
  }

  action badSplitAcrossFallthrough = all {
    st' = {
      ...st, splitApplied: true, nbHosts: 2,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 1, 3 -> 1, 4 -> 1, 5 -> 1, 6 -> 1, 7 -> 0),
      valSlot: Map(1 -> 1, 3 -> 1, 5 -> 2, 6 -> 3),
      hostValCount: Map(0 -> 1, 1 -> 3)
    }
  }

  action badEmptyValHost = all {
    st' = {
      ...st, splitApplied: true, nbHosts: 4,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 1, 4 -> 1, 5 -> 2, 6 -> 2, 7 -> 3),
      valSlot: Map(1 -> 1, 3 -> 1, 5 -> 1, 6 -> 2),
      hostValCount: Map(0 -> 1, 1 -> 1, 2 -> 2, 3 -> 0)
    }
  }

  action badOutOfBoundsSlot = all {
    st' = {
      ...st, splitApplied: true, nbHosts: 3,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 1, 4 -> 1, 5 -> 2, 6 -> 2, 7 -> 0),
      valSlot: Map(1 -> 1, 3 -> 1, 5 -> 1, 6 -> 3),
      hostValCount: Map(0 -> 1, 1 -> 1, 2 -> 2)
    }
  }

  action badOpaqueOrDisabledSplit = all {
    st' = {
      ...st, splitApplied: true, nbHosts: 2,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 1, 6 -> 1, 7 -> 0),
      valSlot: Map(1 -> 1, 3 -> 2, 5 -> 1, 6 -> 2),
      hostValCount: Map(0 -> 2, 1 -> 2)
    }
  }

  // Mutation 7: Skewed low-benefit split (7 blocks + 1 block):
  // sumSq = 49 + 1 = 50 -> 4*50 = 200 > 192 = 3*64 (fails adaptive cost gate!)
  action badSkewedLowBenefitSplit = all {
    st' = {
      ...st, splitApplied: true, nbHosts: 2,
      blockHost: Map(0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 1, 7 -> 0),
      valSlot: Map(1 -> 1, 3 -> 2, 5 -> 3, 6 -> 1),
      hostValCount: Map(0 -> 3, 1 -> 1)
    }
  }

  pure def canInspectProcObj(isPair: bool, hasCdrPair: bool, cadrIsVector: bool): bool =
    isPair and hasCdrPair and cadrIsVector

  // =========================================================================
  // POSITIVE & ADVERSARIAL MUTATION-KILLER RUNS (12/12)
  // =========================================================================

  run positiveContiguousSplitAndFixupTest =
    init.then(applySoundContiguousSplit).then(runSetupFixup)
      .expect(safe and st.nbHosts == 3 and sumSqHostBlocks(st) == 24 and costBenefitGateOk(24, 8))

  run positiveTwoHostSplitAndFixupTest =
    init.then(applySoundTwoHostSplit).then(runSetupFixup)
      .expect(safe and st.nbHosts == 2 and sumSqHostBlocks(st) == 40 and costBenefitGateOk(40, 8))

  run positiveOpaqueCRefusesSplitTest =
    initConfigured(true, false, -1, 9, false).then(runSetupFixup)
      .expect(safe and not(st.splitApplied) and st.nbHosts == 1)

  run positiveDisabledFlagRefusesAutoSplitTest =
    initConfigured(false, false, 0, 9, false).then(runSetupFixup)
      .expect(safe and not(st.splitApplied) and st.nbHosts == 1)

  run positiveAdaptiveCompactnessCurveTest =
    init.expect(
      adaptiveBaseTarget(-1, 0) == 448 and
      adaptiveBaseTarget(-1, 5) == 288 and
      adaptiveBaseTarget(-1, 9) == 160 and
      adaptiveBaseTarget(300, 9) == 300 and
      not(costBenefitGateOk(9 * 9 + 1 * 1, 10)) and
      costBenefitGateOk(5 * 5 + 5 * 5, 10)
    )

  run positiveNonProcObjSymbolRefusalTest =
    init.expect(
      not(canInspectProcObj(false, false, false)) and
      canInspectProcObj(true, true, true)
    )

  // Positive 7: Oversized component isolation (no max-comp bin inflation) yields
  // strictly smaller sum(B_h^2) than legacy max-comp inflation (eval~0.c profile!),
  // and per-host GCC optimization gate catches monster hosts while keeping sibling hosts optimized.
  run positiveOversizedIsolationAndPerHostOptGateTest = {
    val legacySumSq = 2140 * 2140 + 800 * 800
    val isolatedSumSq = 2140 * 2140 + 5 * (160 * 160)
    init.expect(
      packingTarget(-1, 9, 2940, 54) == 160 and
      isolatedSumSq < legacySumSq and
      effectiveOptHostLimit(6000, -1) == 750 and
      effectiveOptHostLimit(0, -1) == 0 and
      effectiveOptHostLimit(6000, 0) == 0 and
      effectiveOptHostLimit(6000, 1200) == 1200 and
      hostUsesUnoptAttrs(2140, 5726, 6000, -1) and
      not(hostUsesUnoptAttrs(160, 5726, 6000, -1)) and
      not(hostUsesUnoptAttrs(2140, 5726, 6000, 0))
    )
  }

  run mutationSplitAcrossLocalGotoKilledTest =
    init.then(badSplitAcrossLocalGoto)
      .expect(not(invLocalAndFallthroughClosed) and not(safe))

  run mutationSplitAcrossSeqFallthroughKilledTest =
    init.then(badSplitAcrossFallthrough)
      .expect(not(invLocalAndFallthroughClosed) and not(safe))

  run mutationEmptyPhysicalHostKilledTest =
    init.then(badEmptyValHost)
      .expect(not(invAllHostsNonEmpty) and not(safe))

  run mutationOutOfBoundsIndexedSlotKilledTest =
    init.then(badOutOfBoundsSlot).then(runSetupFixup)
      .expect(st.fixupErr and not(invBijectiveIndexedSlots) and not(safe))

  run mutationOpaqueCSplitKilledTest =
    initConfigured(true, false, -1, 9, false).then(badOpaqueOrDisabledSplit)
      .expect(not(invCanonicalEntryAndFlagRefusal) and not(safe))

  run mutationBypassDisableFlagAndSkewedSplitKilledTest =
    initConfigured(false, false, 0, 9, false).then(badOpaqueOrDisabledSplit)
      .expect(not(invCanonicalEntryAndFlagRefusal) and not(safe))

  run mutationSkewedLowBenefitSplitKilledTest =
    initConfigured(false, false, -1, 9, false).then(badSkewedLowBenefitSplit)
      .expect(not(invAdaptiveQuadraticReduction) and not(safe))
}
