// Adversarial Quint specification for Gambit-SMP adaptive STW drained-fromspace
// OS page reclamation (configure --enable-gc-fromspace-reclaim=auto|off|N).
// Challenges:
//   1. Strictly inward page-rounding geometry across 4K/16K/64K pages
//   2. Semispace parity separation (never touches header, live dest half, or metadata)
//   3. STW drain/pin gating and custom-allocator isolation
//   4. Flag-overridable adaptive machine policy (auto from RAM/LLC/max_heap, off, explicit N)
module gc_fromspace_reclaim {
  pure val HALF_BYTES = 524288      // (___MSECTION_SIZE >> 1) * 8 = 512 KiB
  pure val METADATA_BYTES = 65536   // scan bitmap + 2*section_claim + 2*raw_stack_map
  pure val MIB = 1048576
  pure val FLOOR_MIN_BYTES = 16 * MIB
  pure val ADAPTIVE_CAP_BYTES = 128 * MIB
  pure val FALLBACK_CAP_BYTES = 64 * MIB
  pure val MAX_HEAP_FLOOR_BYTES = 16 * MIB

  type GcPhase = str // "MUTATING" | "DRAINING" | "RETIRED"

  // Strictly inward page rounding: [pageLo, pageHi) subseteq [lo, hi)
  pure def roundUp(addr: int, ps: int): int =
    if (addr % ps == 0) addr else addr + (ps - (addr % ps))

  pure def roundDown(addr: int, ps: int): int =
    addr - (addr % ps)

  pure def interiorRange(lo: int, hi: int, ps: int): { plo: int, phi: int, valid: bool } = {
    val plo = roundUp(lo, ps)
    val phi = roundDown(hi, ps)
    { plo: plo, phi: phi, valid: hi > lo and plo >= lo and phi <= hi and phi > plo }
  }

  // Adversarial mutant: outward rounding (corrupts header / live half / trailing metadata!)
  pure def outwardRangeMutant(lo: int, hi: int, ps: int): { plo: int, phi: int, valid: bool } = {
    val plo = roundDown(lo, ps)
    val phi = roundUp(hi, ps)
    { plo: plo, phi: phi, valid: phi > plo }
  }

  pure def rangesOverlap(aLo: int, aHi: int, bLo: int, bHi: int): bool =
    aLo < bHi and bLo < aHi

  // Machine-adaptive minimum section threshold:
  //   policy < 0  => disabled (represented as -1; canReclaim returns false)
  //   policy > 0  => explicit user override (policy sections)
  //   policy == 0 => adaptive from (physMemBytes, minHeapBytes, maxHeapBytes)
  pure def maxInt(a: int, b: int): int = if (a >= b) a else b
  pure def minInt(a: int, b: int): int = if (a <= b) a else b

  // CPU+RAM-adaptive dead-half byte threshold: divides RAM by 64 * max(1, cpuCount)
  // so aggregate dead from-space across C parallel workers never exceeds RAM / 64!
  pure def adaptiveTargetDeadBytes(physMemBytes: int, cpuCount: int,
                                   minHeapBytes: int, maxHeapBytes: int): int = {
    val effCpus = if (cpuCount > 0) cpuCount else 1
    val cacheFloor = maxInt(FLOOR_MIN_BYTES, minHeapBytes * 4)
    val baseTarget =
      if (physMemBytes > 0)
        minInt(ADAPTIVE_CAP_BYTES, maxInt(cacheFloor, physMemBytes / (64 * effCpus)))
      else
        minInt(FALLBACK_CAP_BYTES, cacheFloor)
    if (maxHeapBytes > 0) {
      val capTarget = maxInt(MAX_HEAP_FLOOR_BYTES, maxHeapBytes / 4)
      minInt(baseTarget, capTarget)
    } else {
      baseTarget
    }
  }

  pure def effectiveThresholdSections(policy: int, physMemBytes: int, cpuCount: int,
                                      minHeapBytes: int, maxHeapBytes: int): int =
    if (policy < 0) -1
    else if (policy > 0) policy
    else {
      val targetBytes = adaptiveTargetDeadBytes(physMemBytes, cpuCount, minHeapBytes, maxHeapBytes)
      maxInt(1, (targetBytes + HALF_BYTES - 1) / HALF_BYTES)
    }

  var phase: GcPhase
  var destHalf: int            // 0 or 1
  var allDrained: bool         // all participants restored & source_drained
  var sourcePins: int          // aggregate active source_pins on source half
  var customAlloc: bool        // custom_msection_alloc != 0
  var nbSections: int
  var pageSize: int            // 4096 | 16384 | 65536
  var baseOffset: int          // sizeof(___msection prefix before base[0]), e.g. 40, 48, 64
  var policy: int              // -1 = off, 0 = auto, >0 = explicit N
  var physMemBytes: int        // OS physical RAM in bytes (0 if unknown)
  var cpuCount: int            // OS online CPU count (0 if unknown)
  var minHeapBytes: int        // Gambit setup_params.min_heap (LLC/2 default)
  var maxHeapBytes: int        // Gambit setup_params.max_heap (0 = unbounded)
  var headerIntact: bool
  var destDataIntact: bool
  var metadataIntact: bool
  var liveSourceIntact: bool
  var reclaimOps: int
  var lastPlo: int
  var lastPhi: int
  var lastReclaimedHalf: int

  pure def srcHalfOf(dest: int): int = 1 - dest

  pure def halfLo(baseOff: int, h: int): int = baseOff + h * HALF_BYTES
  pure def halfHi(baseOff: int, h: int): int = baseOff + (h + 1) * HALF_BYTES
  pure def metaLo(baseOff: int): int = baseOff + 2 * HALF_BYTES
  pure def metaHi(baseOff: int): int = baseOff + 2 * HALF_BYTES + METADATA_BYTES

  pure def canReclaim(ph: GcPhase, drained: bool, pins: int, custom: bool,
                      nSec: int, pol: int, physMem: int, cpus: int,
                      minH: int, maxH: int): bool = {
    val thr = effectiveThresholdSections(pol, physMem, cpus, minH, maxH)
    ph == "DRAINING" and drained and pins == 0 and not(custom) and thr > 0 and nSec >= thr
  }

  action init = all {
    phase' = "MUTATING",
    destHalf' = 0,
    allDrained' = false,
    sourcePins' = 0,
    customAlloc' = false,
    nbSections' = 64,
    pageSize' = 16384,
    baseOffset' = 40,
    policy' = 0,
    physMemBytes' = 32 * 1024 * MIB,
    cpuCount' = 12,
    minHeapBytes' = 4 * MIB,
    maxHeapBytes' = 0,
    headerIntact' = true,
    destDataIntact' = true,
    metadataIntact' = true,
    liveSourceIntact' = true,
    reclaimOps' = 0,
    lastPlo' = 0,
    lastPhi' = 0,
    lastReclaimedHalf' = -1,
  }

  action configureGeometry(ps: int, bo: int, custom: bool, nSec: int,
                           pol: int, physMem: int, cpus: int, minH: int, maxH: int): bool = all {
    phase == "MUTATING",
    ps == 4096 or ps == 16384 or ps == 65536,
    bo >= 32 and bo <= 256,
    nSec >= 2 and nSec <= 16384,
    pol >= -1 and pol <= 4096,
    physMem >= 0,
    cpus >= 0,
    minH >= 0,
    maxH >= 0,
    pageSize' = ps,
    baseOffset' = bo,
    customAlloc' = custom,
    nbSections' = nSec,
    policy' = pol,
    physMemBytes' = physMem,
    cpuCount' = cpus,
    minHeapBytes' = minH,
    maxHeapBytes' = maxH,
    phase' = phase,
    destHalf' = destHalf,
    allDrained' = allDrained,
    sourcePins' = sourcePins,
    headerIntact' = headerIntact,
    destDataIntact' = destDataIntact,
    metadataIntact' = metadataIntact,
    liveSourceIntact' = liveSourceIntact,
    reclaimOps' = reclaimOps,
    lastPlo' = lastPlo,
    lastPhi' = lastPhi,
    lastReclaimedHalf' = lastReclaimedHalf,
  }

  action beginStwCollection(initialPins: int): bool = all {
    phase == "MUTATING",
    initialPins >= 0 and initialPins <= 4,
    phase' = "DRAINING",
    destHalf' = 1 - destHalf,
    allDrained' = false,
    sourcePins' = initialPins,
    customAlloc' = customAlloc,
    nbSections' = nbSections,
    pageSize' = pageSize,
    baseOffset' = baseOffset,
    policy' = policy,
    physMemBytes' = physMemBytes,
    cpuCount' = cpuCount,
    minHeapBytes' = minHeapBytes,
    maxHeapBytes' = maxHeapBytes,
    headerIntact' = headerIntact,
    destDataIntact' = destDataIntact,
    metadataIntact' = metadataIntact,
    liveSourceIntact' = liveSourceIntact,
    reclaimOps' = reclaimOps,
    lastPlo' = lastPlo,
    lastPhi' = lastPhi,
    lastReclaimedHalf' = -1,
  }

  action releaseSourcePin: bool = all {
    phase == "DRAINING",
    sourcePins > 0,
    sourcePins' = sourcePins - 1,
    phase' = phase,
    destHalf' = destHalf,
    allDrained' = allDrained,
    customAlloc' = customAlloc,
    nbSections' = nbSections,
    pageSize' = pageSize,
    baseOffset' = baseOffset,
    policy' = policy,
    physMemBytes' = physMemBytes,
    cpuCount' = cpuCount,
    minHeapBytes' = minHeapBytes,
    maxHeapBytes' = maxHeapBytes,
    headerIntact' = headerIntact,
    destDataIntact' = destDataIntact,
    metadataIntact' = metadataIntact,
    liveSourceIntact' = liveSourceIntact,
    reclaimOps' = reclaimOps,
    lastPlo' = lastPlo,
    lastPhi' = lastPhi,
    lastReclaimedHalf' = lastReclaimedHalf,
  }

  action finishDrain: bool = all {
    phase == "DRAINING",
    sourcePins == 0,
    not(allDrained),
    allDrained' = true,
    phase' = phase,
    destHalf' = destHalf,
    sourcePins' = sourcePins,
    customAlloc' = customAlloc,
    nbSections' = nbSections,
    pageSize' = pageSize,
    baseOffset' = baseOffset,
    policy' = policy,
    physMemBytes' = physMemBytes,
    cpuCount' = cpuCount,
    minHeapBytes' = minHeapBytes,
    maxHeapBytes' = maxHeapBytes,
    headerIntact' = headerIntact,
    destDataIntact' = destDataIntact,
    metadataIntact' = metadataIntact,
    liveSourceIntact' = liveSourceIntact,
    reclaimOps' = reclaimOps,
    lastPlo' = lastPlo,
    lastPhi' = lastPhi,
    lastReclaimedHalf' = lastReclaimedHalf,
  }

  action retireAndMaybeReclaim: bool = {
    val sh = srcHalfOf(destHalf)
    val lo = halfLo(baseOffset, sh)
    val hi = halfHi(baseOffset, sh)
    val rng = interiorRange(lo, hi, pageSize)
    val doReclaim = canReclaim(phase, allDrained, sourcePins, customAlloc,
                               nbSections, policy, physMemBytes, cpuCount,
                               minHeapBytes, maxHeapBytes) and rng.valid
    val hitHdr = doReclaim and rangesOverlap(rng.plo, rng.phi, 0, baseOffset)
    val hitDest = doReclaim and rangesOverlap(rng.plo, rng.phi, halfLo(baseOffset, destHalf), halfHi(baseOffset, destHalf))
    val hitMeta = doReclaim and rangesOverlap(rng.plo, rng.phi, metaLo(baseOffset), metaHi(baseOffset))
    all {
      phase == "DRAINING",
      allDrained,
      sourcePins == 0,
      phase' = "RETIRED",
      destHalf' = destHalf,
      allDrained' = allDrained,
      sourcePins' = sourcePins,
      customAlloc' = customAlloc,
      nbSections' = nbSections,
      pageSize' = pageSize,
      baseOffset' = baseOffset,
      policy' = policy,
      physMemBytes' = physMemBytes,
      cpuCount' = cpuCount,
      minHeapBytes' = minHeapBytes,
      maxHeapBytes' = maxHeapBytes,
      headerIntact' = (headerIntact and not(hitHdr)),
      destDataIntact' = (destDataIntact and not(hitDest)),
      metadataIntact' = (metadataIntact and not(hitMeta)),
      liveSourceIntact' = liveSourceIntact,
      reclaimOps' = if (doReclaim) reclaimOps + 1 else reclaimOps,
      lastPlo' = if (doReclaim) rng.plo else 0,
      lastPhi' = if (doReclaim) rng.phi else 0,
      lastReclaimedHalf' = if (doReclaim) sh else -1,
    }
  }

  action resumeMutators(nextNbSections: int): bool = all {
    phase == "RETIRED",
    nextNbSections >= 2 and nextNbSections <= 16384,
    phase' = "MUTATING",
    nbSections' = nextNbSections,
    allDrained' = false,
    destHalf' = destHalf,
    sourcePins' = sourcePins,
    customAlloc' = customAlloc,
    pageSize' = pageSize,
    baseOffset' = baseOffset,
    policy' = policy,
    physMemBytes' = physMemBytes,
    cpuCount' = cpuCount,
    minHeapBytes' = minHeapBytes,
    maxHeapBytes' = maxHeapBytes,
    headerIntact' = headerIntact,
    destDataIntact' = destDataIntact,
    metadataIntact' = metadataIntact,
    liveSourceIntact' = liveSourceIntact,
    reclaimOps' = reclaimOps,
    lastPlo' = 0,
    lastPhi' = 0,
    lastReclaimedHalf' = -1,
  }

  // Adversarial Mutant 1: outward page rounding touches header/live half/metadata
  action mutantOutwardRoundReclaim: bool = {
    val sh = srcHalfOf(destHalf)
    val lo = halfLo(baseOffset, sh)
    val hi = halfHi(baseOffset, sh)
    val rng = outwardRangeMutant(lo, hi, pageSize)
    val hitHdr = rangesOverlap(rng.plo, rng.phi, 0, baseOffset)
    val hitDest = rangesOverlap(rng.plo, rng.phi, halfLo(baseOffset, destHalf), halfHi(baseOffset, destHalf))
    val hitMeta = rangesOverlap(rng.plo, rng.phi, metaLo(baseOffset), metaHi(baseOffset))
    all {
      phase == "DRAINING", allDrained, sourcePins == 0,
      phase' = "RETIRED", destHalf' = destHalf, allDrained' = allDrained, sourcePins' = sourcePins,
      customAlloc' = customAlloc, nbSections' = nbSections, pageSize' = pageSize, baseOffset' = baseOffset,
      policy' = policy, physMemBytes' = physMemBytes, cpuCount' = cpuCount, minHeapBytes' = minHeapBytes, maxHeapBytes' = maxHeapBytes,
      headerIntact' = (headerIntact and not(hitHdr)),
      destDataIntact' = (destDataIntact and not(hitDest)),
      metadataIntact' = (metadataIntact and not(hitMeta)),
      liveSourceIntact' = liveSourceIntact,
      reclaimOps' = reclaimOps + 1, lastPlo' = rng.plo, lastPhi' = rng.phi, lastReclaimedHalf' = sh,
    }
  }

  // Adversarial Mutant 2: reclaiming while source pins > 0 or before drain completes
  action mutantPrematureReclaim: bool = {
    val sh = srcHalfOf(destHalf)
    val rng = interiorRange(halfLo(baseOffset, sh), halfHi(baseOffset, sh), pageSize)
    all {
      phase == "DRAINING", sourcePins > 0 or not(allDrained),
      phase' = phase, destHalf' = destHalf, allDrained' = allDrained, sourcePins' = sourcePins,
      customAlloc' = customAlloc, nbSections' = nbSections, pageSize' = pageSize, baseOffset' = baseOffset,
      policy' = policy, physMemBytes' = physMemBytes, cpuCount' = cpuCount, minHeapBytes' = minHeapBytes, maxHeapBytes' = maxHeapBytes,
      headerIntact' = headerIntact, destDataIntact' = destDataIntact, metadataIntact' = metadataIntact,
      liveSourceIntact' = false,
      reclaimOps' = reclaimOps + 1, lastPlo' = rng.plo, lastPhi' = rng.phi, lastReclaimedHalf' = sh,
    }
  }

  // Adversarial Mutant 3: reclaiming destination half instead of source half
  action mutantWrongParityReclaim: bool = {
    val rng = interiorRange(halfLo(baseOffset, destHalf), halfHi(baseOffset, destHalf), pageSize)
    val hitDest = rangesOverlap(rng.plo, rng.phi, halfLo(baseOffset, destHalf), halfHi(baseOffset, destHalf))
    all {
      phase == "DRAINING", allDrained, sourcePins == 0,
      phase' = "RETIRED", destHalf' = destHalf, allDrained' = allDrained, sourcePins' = sourcePins,
      customAlloc' = customAlloc, nbSections' = nbSections, pageSize' = pageSize, baseOffset' = baseOffset,
      policy' = policy, physMemBytes' = physMemBytes, cpuCount' = cpuCount, minHeapBytes' = minHeapBytes, maxHeapBytes' = maxHeapBytes,
      headerIntact' = headerIntact, destDataIntact' = (destDataIntact and not(hitDest)),
      metadataIntact' = metadataIntact, liveSourceIntact' = liveSourceIntact,
      reclaimOps' = reclaimOps + 1, lastPlo' = rng.plo, lastPhi' = rng.phi, lastReclaimedHalf' = destHalf,
    }
  }

  // Adversarial Mutant 4: reclaiming custom-allocator sections
  action mutantCustomAllocReclaim: bool = {
    val sh = srcHalfOf(destHalf)
    val rng = interiorRange(halfLo(baseOffset, sh), halfHi(baseOffset, sh), pageSize)
    all {
      phase == "DRAINING", allDrained, sourcePins == 0, customAlloc,
      phase' = "RETIRED", destHalf' = destHalf, allDrained' = allDrained, sourcePins' = sourcePins,
      customAlloc' = customAlloc, nbSections' = nbSections, pageSize' = pageSize, baseOffset' = baseOffset,
      policy' = policy, physMemBytes' = physMemBytes, cpuCount' = cpuCount, minHeapBytes' = minHeapBytes, maxHeapBytes' = maxHeapBytes,
      headerIntact' = headerIntact, destDataIntact' = destDataIntact, metadataIntact' = metadataIntact,
      liveSourceIntact' = liveSourceIntact,
      reclaimOps' = reclaimOps + 1, lastPlo' = rng.plo, lastPhi' = rng.phi, lastReclaimedHalf' = sh,
    }
  }

  // Adversarial Mutant 5: ignoring disabled policy (-1) and reclaiming anyway
  action mutantBypassDisabledPolicyReclaim: bool = {
    val sh = srcHalfOf(destHalf)
    val rng = interiorRange(halfLo(baseOffset, sh), halfHi(baseOffset, sh), pageSize)
    all {
      phase == "DRAINING", allDrained, sourcePins == 0, policy < 0,
      phase' = "RETIRED", destHalf' = destHalf, allDrained' = allDrained, sourcePins' = sourcePins,
      customAlloc' = customAlloc, nbSections' = nbSections, pageSize' = pageSize, baseOffset' = baseOffset,
      policy' = policy, physMemBytes' = physMemBytes, cpuCount' = cpuCount, minHeapBytes' = minHeapBytes, maxHeapBytes' = maxHeapBytes,
      headerIntact' = headerIntact, destDataIntact' = destDataIntact, metadataIntact' = metadataIntact,
      liveSourceIntact' = liveSourceIntact,
      reclaimOps' = reclaimOps + 1, lastPlo' = rng.plo, lastPhi' = rng.phi, lastReclaimedHalf' = sh,
    }
  }

  action step = any {
    nondet ps = oneOf(Set(4096, 16384, 65536))
    nondet bo = oneOf(Set(40, 64))
    nondet ca = oneOf(Set(false, true))
    nondet ns = oneOf(Set(16, 86, 256, 4096))
    nondet pol = oneOf(Set(-1, 0, 128))
    nondet prof = oneOf(Set(
      { ram: 0, cpus: 0, minH: 4 * MIB, maxH: 0 },
      { ram: 12 * 1024 * MIB, cpus: 12, minH: 4 * MIB, maxH: 0 },
      { ram: 32 * 1024 * MIB, cpus: 12, minH: 4 * MIB, maxH: 0 },
      { ram: 64 * 1024 * MIB, cpus: 16, minH: 4 * MIB, maxH: 256 * MIB },
      { ram: 256 * 1024 * MIB, cpus: 64, minH: 8 * MIB, maxH: 0 }
    ))
    configureGeometry(ps, bo, ca, ns, pol, prof.ram, prof.cpus, prof.minH, prof.maxH),
    nondet pins = oneOf(Set(0, 1, 2))
    beginStwCollection(pins),
    releaseSourcePin,
    finishDrain,
    retireAndMaybeReclaim,
    nondet nextNs = oneOf(Set(16, 86, 256, 8000))
    resumeMutators(nextNs),
  }

  // --- Core Safety Invariants ---
  val geometryAndDataIntactInv =
    headerIntact and destDataIntact and metadataIntact and liveSourceIntact

  val interiorAlignmentInv =
    lastReclaimedHalf == -1 or (
      lastReclaimedHalf == srcHalfOf(destHalf) and
      lastPlo % pageSize == 0 and
      lastPhi % pageSize == 0 and
      lastPlo >= halfLo(baseOffset, lastReclaimedHalf) and
      lastPhi <= halfHi(baseOffset, lastReclaimedHalf) and
      lastPhi > lastPlo
    )

  val customAllocNeverReclaimedInv =
    not(customAlloc) or lastReclaimedHalf == -1

  val policyAndThresholdRespectedInv = {
    val thr = effectiveThresholdSections(policy, physMemBytes, cpuCount, minHeapBytes, maxHeapBytes)
    lastReclaimedHalf == -1 or (thr > 0 and nbSections >= thr)
  }

  val safetyInv =
    geometryAndDataIntactInv and interiorAlignmentInv and
    customAllocNeverReclaimedInv and policyAndThresholdRespectedInv

  // --- Tests (nominal + CPU/RAM machine adaptation + 5 adversarial mutation killers = 9/9) ---
  run nominalMultiRoundReclaimAndFlipTest =
    init
      .then(configureGeometry(16384, 40, false, 8000, 0, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(2))
      .then(releaseSourcePin)
      .then(releaseSourcePin)
      .then(finishDrain)
      .then(retireAndMaybeReclaim)
      .then(all {
        assert(safetyInv),
        assert(reclaimOps == 1),
        assert(lastReclaimedHalf == 0),
        assert(lastPhi - lastPlo == 496 * 1024),
        resumeMutators(12000),
      })
      .then(beginStwCollection(0))
      .then(finishDrain)
      .then(retireAndMaybeReclaim)
      .then(all {
        assert(safetyInv),
        assert(reclaimOps == 2),
        assert(lastReclaimedHalf == 1),
        assert(lastPhi - lastPlo == 496 * 1024),
        resumeMutators(12000),
      })

  run adaptiveScalingAcrossMachinesTest =
    init.expect(
      // 12 GiB / 12-core laptop: 16 MiB dead half -> 32 sections (12 workers <= 192 MiB aggregate!)
      effectiveThresholdSections(0, 12 * 1024 * MIB, 12, 4 * MIB, 0) == 32 and
      // 32 GiB / 12-core workstation: 42.67 MiB dead half -> 86 sections (8 workers <= 344 MiB!)
      effectiveThresholdSections(0, 32 * 1024 * MIB, 12, 4 * MIB, 0) == 86 and
      // 16 GiB / 4-core runner: 64 MiB dead half -> 128 sections
      effectiveThresholdSections(0, 16 * 1024 * MIB, 4, 4 * MIB, 0) == 128 and
      // 64 GiB / 16-core server: identical 64 MiB per-core share -> 128 sections (scale-invariant!)
      effectiveThresholdSections(0, 64 * 1024 * MIB, 16, 4 * MIB, 0) == 128 and
      // 256 GiB / 4-core high-RAM: capped at 128 MiB dead half -> 256 sections
      effectiveThresholdSections(0, 256 * 1024 * MIB, 4, 8 * MIB, 0) == 256 and
      // Explicit -:h256M tightens 256 GiB server down to 64 MiB -> 128 sections
      effectiveThresholdSections(0, 256 * 1024 * MIB, 4, 8 * MIB, 256 * MIB) == 128 and
      // Explicit override policy = 200
      effectiveThresholdSections(200, 32 * 1024 * MIB, 12, 4 * MIB, 0) == 200 and
      // Disabled policy = -1
      effectiveThresholdSections(-1, 32 * 1024 * MIB, 12, 4 * MIB, 0) == -1
    )

  run disabledPolicyZeroReclaimTest =
    init
      .then(configureGeometry(16384, 40, false, 12000, -1, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(0))
      .then(finishDrain)
      .then(retireAndMaybeReclaim)
      .then(all {
        assert(safetyInv),
        assert(reclaimOps == 0),
        assert(lastReclaimedHalf == -1),
        resumeMutators(12000),
      })

  run belowThresholdZeroSyscallTest =
    init
      .then(configureGeometry(16384, 40, false, 32, 0, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(0))
      .then(finishDrain)
      .then(retireAndMaybeReclaim)
      .then(all {
        assert(safetyInv),
        assert(reclaimOps == 0),
        assert(lastReclaimedHalf == -1),
        resumeMutators(32),
      })

  run outwardRoundMutantKilledTest =
    init
      .then(configureGeometry(16384, 40, false, 4096, 0, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(0))
      .then(finishDrain)
      .then(mutantOutwardRoundReclaim)
      .then(all {
        assert(not(safetyInv)),
        assert(not(headerIntact)),
        assert(not(destDataIntact)),
        resumeMutators(4096),
      })

  run prematurePinReclaimMutantKilledTest =
    init
      .then(configureGeometry(16384, 40, false, 4096, 0, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(1))
      .then(mutantPrematureReclaim)
      .then(all {
        assert(not(safetyInv)),
        assert(not(liveSourceIntact)),
        releaseSourcePin,
      })

  run wrongParityReclaimMutantKilledTest =
    init
      .then(configureGeometry(16384, 40, false, 4096, 0, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(0))
      .then(finishDrain)
      .then(mutantWrongParityReclaim)
      .then(all {
        assert(not(safetyInv)),
        assert(not(destDataIntact)),
        resumeMutators(4096),
      })

  run customAllocReclaimMutantKilledTest =
    init
      .then(configureGeometry(16384, 40, true, 4096, 0, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(0))
      .then(finishDrain)
      .then(mutantCustomAllocReclaim)
      .then(all {
        assert(not(safetyInv)),
        assert(not(customAllocNeverReclaimedInv)),
        resumeMutators(4096),
      })

  run disabledPolicyBypassMutantKilledTest =
    init
      .then(configureGeometry(16384, 40, false, 12000, -1, 32 * 1024 * MIB, 12, 4 * MIB, 0))
      .then(beginStwCollection(0))
      .then(finishDrain)
      .then(mutantBypassDisabledPolicyReclaim)
      .then(all {
        assert(not(safetyInv)),
        assert(not(policyAndThresholdRespectedInv)),
        resumeMutators(12000),
      })
}
