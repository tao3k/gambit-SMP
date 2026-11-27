/* Additive SysML v2 Structural Amplification Model for Gambit SMP Modern GC.
 * Strictly disjoint from all sealed Family 7-12 and sibling Phase A/B/C packages. */
package GambitModernGcAmplification {
    private import ScalarValues::*;

    /* Read-only canonical package anchors. */
    ref part runtimeCompositionRef = GambitRuntimeComposition::blueprintModule0;
    ref part genBarrierRef = GambitGenerationalBarrier::protocol;

    attribute scope : String = "Post-Phase A/B/C structural amplification architecture (Amp-1 through Amp-4): unified lock-free local movable+still nursery, contiguous virtual nursery arena + O(1) radix/aligned msection directory, OCaml-5 256-entry prefetch ring + addrmap overflow compression, opportunistic major slices during STW spin, incremental stack-frame watermark scanning, LXR SATB-with-interruptions + line-reuse-epoch remset safety, Chez static/immortal generation + Immix overflow block, and compositional (L,g,s) MemBalancer + off-heap immutable RefC binaries.";
    attribute nonImportPolicy : String = "No read barriers (LVB/Brooks/VM-trap); no free-list replacement of Immix contiguous mature space; no DLG immutable duplication violating Scheme eq?; no one-shot restriction on call/cc; no C23 non-atomic data races.";

    /* ------------------------------------------------------------------ */
    /* 1. Formal Requirements (Laws) for Amp-1 through Amp-4              */
    /* ------------------------------------------------------------------ */

    part def UnifiedLocalNurseryState {
        attribute localSweepActive : Boolean;
        attribute globalAllocMutexHeld : Boolean;
        attribute stillDeltaAtomicFlush : Boolean;
        attribute escapedStillMarkedGlobal : Boolean;
        attribute globalStillSkippedLocally : Boolean;
        attribute zeroCrossNurseryPointers : Boolean;
        attribute mixedMovableStillSupported : Boolean;
        attribute directMaturePromotion : Boolean;
    }
    requirement def UnifiedLocalNurseryLaw {
        subject u : UnifiedLocalNurseryState;
        require constraint {
            u.stillDeltaAtomicFlush and
            u.zeroCrossNurseryPointers and
            u.mixedMovableStillSupported and
            u.directMaturePromotion and
            (not u.localSweepActive or not u.globalAllocMutexHeld) and
            (not u.escapedStillMarkedGlobal or u.globalStillSkippedLocally)
        }
    }

    part def ContiguousArenaRadixState {
        attribute contiguousNurseryReserved : Boolean;
        attribute isYoungRangeCheckO1 : Boolean;
        attribute msectionLookupO1 : Boolean;
        attribute disjointFromMatureSpace : Boolean;
        attribute perProcessorSliceUnique : Boolean;
    }
    requirement def ContiguousArenaRadixLaw {
        subject a : ContiguousArenaRadixState;
        require constraint {
            a.contiguousNurseryReserved and
            a.isYoungRangeCheckO1 and
            a.msectionLookupO1 and
            a.disjointFromMatureSpace and
            a.perProcessorSliceUnique
        }
    }

    part def PrefetchRingAndAddrmapState {
        attribute prefetchRingCapacity256 : Boolean;
        attribute prefetchMinOccupancy64 : Boolean;
        attribute dualCachelinePrefetch : Boolean;
        attribute markStackOverflowCompressed : Boolean;
        attribute boundedMarkQueueMemory : Boolean;
    }
    requirement def PrefetchRingAndAddrmapLaw {
        subject p : PrefetchRingAndAddrmapState;
        require constraint {
            p.prefetchRingCapacity256 and
            p.prefetchMinOccupancy64 and
            p.dualCachelinePrefetch and
            (not p.markStackOverflowCompressed or p.boundedMarkQueueMemory)
        }
    }

    part def OpportunisticStwSpinState {
        attribute stwPhaseEntering : Boolean;
        attribute stwPhaseFlipping : Boolean;
        attribute spinWorkActive : Boolean;
        attribute spinExitReleasePublished : Boolean;
        attribute coordinatorAcquireObserved : Boolean;
        attribute boundedSliceWork : Boolean;
    }
    requirement def OpportunisticStwSpinLaw {
        subject s : OpportunisticStwSpinState;
        require constraint {
            s.boundedSliceWork and
            (not s.spinWorkActive or (s.stwPhaseEntering and not s.stwPhaseFlipping)) and
            (not s.stwPhaseFlipping or (not s.spinWorkActive and s.spinExitReleasePublished and s.coordinatorAcquireObserved))
        }
    }

    part def IncrementalStackWatermarkState {
        attribute minorScanUsesWatermark : Boolean;
        attribute frameMutationBelowWatermark : Boolean;
        attribute returnUnwoundBelowWatermark : Boolean;
        attribute callccReinstatedStack : Boolean;
        attribute watermarkInvalidated : Boolean;
        attribute allYoungFrameRootsFound : Boolean;
    }
    requirement def IncrementalStackWatermarkLaw {
        subject w : IncrementalStackWatermarkState;
        require constraint {
            (not (w.frameMutationBelowWatermark or w.returnUnwoundBelowWatermark or w.callccReinstatedStack) or w.watermarkInvalidated) and
            (not w.minorScanUsesWatermark or w.allYoungFrameRootsFound)
        }
    }

    part def LxrSatbAndLineReuseState {
        attribute satbTraceActive : Boolean;
        attribute objectUnmarkedInSatb : Boolean;
        attribute promptRcDeleteAttempted : Boolean;
        attribute deleteDeferredUntilSatbEnd : Boolean;
        attribute lineRecycledEpochBumped : Boolean;
        attribute staleRemsetEpochMismatch : Boolean;
        attribute staleRemsetRejected : Boolean;
        attribute zeroReadBarrier : Boolean;
    }
    requirement def LxrSatbAndLineReuseLaw {
        subject x : LxrSatbAndLineReuseState;
        require constraint {
            x.zeroReadBarrier and
            (not (x.satbTraceActive and x.objectUnmarkedInSatb and x.promptRcDeleteAttempted) or x.deleteDeferredUntilSatbEnd) and
            (not (x.lineRecycledEpochBumped and x.staleRemsetEpochMismatch) or x.staleRemsetRejected)
        }
    }

    part def StaticGenAndOverflowImmixState {
        attribute staticGenSkippedByDefault : Boolean;
        attribute staticDirtyBarrierArmed : Boolean;
        attribute mediumOverflowRoutedToCleanBlock : Boolean;
        attribute recycledHolePreserved : Boolean;
        attribute pinnedBlocksNeverEvacuated : Boolean;
    }
    requirement def StaticGenAndOverflowImmixLaw {
        subject g : StaticGenAndOverflowImmixState;
        require constraint {
            g.staticGenSkippedByDefault and
            g.staticDirtyBarrierArmed and
            g.mediumOverflowRoutedToCleanBlock and
            g.recycledHolePreserved and
            g.pinnedBlocksNeverEvacuated
        }
    }

    part def MemBalancerAndOffHeapBinState {
        attribute sqrtLgsRuleActive : Boolean;
        attribute ewmaSmoothedRateAndSpeed : Boolean;
        attribute minimumHeadroomEminGuarded : Boolean;
        attribute compositionalAcrossProcesses : Boolean;
        attribute offHeapBinaryImmutableTagged : Boolean;
        attribute offHeapBinaryAtomicRefcount : Boolean;
        attribute lboCyclesAndWallClockMeasured : Boolean;
    }
    requirement def MemBalancerAndOffHeapBinLaw {
        subject m : MemBalancerAndOffHeapBinState;
        require constraint {
            m.sqrtLgsRuleActive and
            m.ewmaSmoothedRateAndSpeed and
            m.minimumHeadroomEminGuarded and
            m.compositionalAcrossProcesses and
            m.offHeapBinaryImmutableTagged and
            m.offHeapBinaryAtomicRefcount and
            m.lboCyclesAndWallClockMeasured
        }
    }

    /* ------------------------------------------------------------------ */
    /* 2. Instantiated Architecture Components & Requirement Satisfaction */
    /* ------------------------------------------------------------------ */

    part amp1UnifiedLocalNursery : UnifiedLocalNurseryState {
        attribute :>> localSweepActive = true;
        attribute :>> globalAllocMutexHeld = false;
        attribute :>> stillDeltaAtomicFlush = true;
        attribute :>> escapedStillMarkedGlobal = true;
        attribute :>> globalStillSkippedLocally = true;
        attribute :>> zeroCrossNurseryPointers = true;
        attribute :>> mixedMovableStillSupported = true;
        attribute :>> directMaturePromotion = true;
    }

    part amp1ContiguousArenaRadix : ContiguousArenaRadixState {
        attribute :>> contiguousNurseryReserved = true;
        attribute :>> isYoungRangeCheckO1 = true;
        attribute :>> msectionLookupO1 = true;
        attribute :>> disjointFromMatureSpace = true;
        attribute :>> perProcessorSliceUnique = true;
    }

    part amp2PrefetchRing : PrefetchRingAndAddrmapState {
        attribute :>> prefetchRingCapacity256 = true;
        attribute :>> prefetchMinOccupancy64 = true;
        attribute :>> dualCachelinePrefetch = true;
        attribute :>> markStackOverflowCompressed = true;
        attribute :>> boundedMarkQueueMemory = true;
    }

    part amp2OpportunisticStwSpin : OpportunisticStwSpinState {
        attribute :>> stwPhaseEntering = true;
        attribute :>> stwPhaseFlipping = false;
        attribute :>> spinWorkActive = true;
        attribute :>> spinExitReleasePublished = true;
        attribute :>> coordinatorAcquireObserved = true;
        attribute :>> boundedSliceWork = true;
    }

    part amp2IncrementalStackWatermark : IncrementalStackWatermarkState {
        attribute :>> minorScanUsesWatermark = true;
        attribute :>> frameMutationBelowWatermark = true;
        attribute :>> returnUnwoundBelowWatermark = false;
        attribute :>> callccReinstatedStack = false;
        attribute :>> watermarkInvalidated = true;
        attribute :>> allYoungFrameRootsFound = true;
    }

    part amp3LxrSatbAndLineReuse : LxrSatbAndLineReuseState {
        attribute :>> satbTraceActive = true;
        attribute :>> objectUnmarkedInSatb = true;
        attribute :>> promptRcDeleteAttempted = true;
        attribute :>> deleteDeferredUntilSatbEnd = true;
        attribute :>> lineRecycledEpochBumped = true;
        attribute :>> staleRemsetEpochMismatch = true;
        attribute :>> staleRemsetRejected = true;
        attribute :>> zeroReadBarrier = true;
    }

    part amp3StaticGenAndOverflow : StaticGenAndOverflowImmixState {
        attribute :>> staticGenSkippedByDefault = true;
        attribute :>> staticDirtyBarrierArmed = true;
        attribute :>> mediumOverflowRoutedToCleanBlock = true;
        attribute :>> recycledHolePreserved = true;
        attribute :>> pinnedBlocksNeverEvacuated = true;
    }

    part amp4MemBalancerAndOffHeap : MemBalancerAndOffHeapBinState {
        attribute :>> sqrtLgsRuleActive = true;
        attribute :>> ewmaSmoothedRateAndSpeed = true;
        attribute :>> minimumHeadroomEminGuarded = true;
        attribute :>> compositionalAcrossProcesses = true;
        attribute :>> offHeapBinaryImmutableTagged = true;
        attribute :>> offHeapBinaryAtomicRefcount = true;
        attribute :>> lboCyclesAndWallClockMeasured = true;
    }

    requirement amp1UnifiedLocalNurseryReq : UnifiedLocalNurseryLaw;
    satisfy amp1UnifiedLocalNurseryReq by amp1UnifiedLocalNursery;

    requirement amp1ContiguousArenaRadixReq : ContiguousArenaRadixLaw;
    satisfy amp1ContiguousArenaRadixReq by amp1ContiguousArenaRadix;

    requirement amp2PrefetchRingReq : PrefetchRingAndAddrmapLaw;
    satisfy amp2PrefetchRingReq by amp2PrefetchRing;

    requirement amp2OpportunisticStwSpinReq : OpportunisticStwSpinLaw;
    satisfy amp2OpportunisticStwSpinReq by amp2OpportunisticStwSpin;

    requirement amp2IncrementalStackWatermarkReq : IncrementalStackWatermarkLaw;
    satisfy amp2IncrementalStackWatermarkReq by amp2IncrementalStackWatermark;

    requirement amp3LxrSatbAndLineReuseReq : LxrSatbAndLineReuseLaw;
    satisfy amp3LxrSatbAndLineReuseReq by amp3LxrSatbAndLineReuse;

    requirement amp3StaticGenAndOverflowReq : StaticGenAndOverflowImmixLaw;
    satisfy amp3StaticGenAndOverflowReq by amp3StaticGenAndOverflow;

    requirement amp4MemBalancerAndOffHeapReq : MemBalancerAndOffHeapBinLaw;
    satisfy amp4MemBalancerAndOffHeapReq by amp4MemBalancerAndOffHeap;

    /* ------------------------------------------------------------------ */
    /* 3. Program Admission Gate: Phase A/B/C Stabilization -> Amp-1      */
    /* ------------------------------------------------------------------ */

    part def AmpWaveAdmissionState {
        attribute paperLocksComplete : Boolean;
        attribute evidenceChainVerified : Boolean;
        attribute formalModelsVerified : Boolean;
        attribute hardwareMicrobenchRecorded : Boolean;
        attribute phaseABCStabilized : Boolean;
        attribute amp1ImplementationAdmitted : Boolean;
    }
    requirement def AmpWaveAdmissionLaw {
        subject g : AmpWaveAdmissionState;
        require constraint {
            g.paperLocksComplete and
            g.evidenceChainVerified and
            g.formalModelsVerified and
            g.hardwareMicrobenchRecorded and
            (not g.amp1ImplementationAdmitted or g.phaseABCStabilized)
        }
    }

    part amp1ReadinessGate : AmpWaveAdmissionState {
        attribute :>> paperLocksComplete = true;
        attribute :>> evidenceChainVerified = true;
        attribute :>> formalModelsVerified = true;
        attribute :>> hardwareMicrobenchRecorded = true;
        attribute :>> phaseABCStabilized = false;
        attribute :>> amp1ImplementationAdmitted = false;
    }

    requirement amp1ReadinessGateReq : AmpWaveAdmissionLaw;
    satisfy amp1ReadinessGateReq by amp1ReadinessGate;
}
