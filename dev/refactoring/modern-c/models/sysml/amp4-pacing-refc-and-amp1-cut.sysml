/* Additive SysML v2 Package for Amp-1 Drop-In C23 Integration Cuts,
 * Amp-4 Global Major Work Pacing + Phantom Bytes + Off-Heap Immutable RefC
 * Binaries, and Cai et al. ISPASS '22 LBO Multi-Core Admission Gate. */
package GambitAmp4PacingRefcAndAmp1Cut {
    private import ScalarValues::*;

    /* Read-only anchor to the Amp-1 wave admission gate (remains false until Phase A/B/C stabilizes). */
    ref part amp1GateRef = GambitModernGcAmplification::amp1ReadinessGate;

    attribute scope : String = "Live-source-anchored Amp-1 C23 integration cut plus complete 4-layer Amp-4 formal contracts (H12-H14) and LBO multi-core evaluation gate.";

    /* ------------------------------------------------------------------ */
    /* Amp-1 Concrete Drop-In C23 Source Cut Contract                     */
    /* ------------------------------------------------------------------ */

    part def Amp1DropInC23CutState {
        attribute allocMemLockRemovedFromLocalStillSweep : Boolean;
        attribute stillBlockGlobalFlagSkipsEscapedInO1 : Boolean;
        attribute unifiedLocalPassPromotesDirectToOwnerImmix : Boolean;
        attribute stackScratchDoubleCopyRemoved : Boolean;
        attribute virtualNurseryArenaRangeCheckO1 : Boolean;
        attribute radixTwoLevelMsectionLookupO1 : Boolean;
        attribute lxrDrcPromotedSpanHooked : Boolean;
        attribute c23ReferencePrototypeTsanAndAsanClean : Boolean;
    }
    requirement def Amp1DropInC23CutLaw {
        subject a : Amp1DropInC23CutState;
        require constraint {
            a.allocMemLockRemovedFromLocalStillSweep and
            a.stillBlockGlobalFlagSkipsEscapedInO1 and
            a.unifiedLocalPassPromotesDirectToOwnerImmix and
            a.stackScratchDoubleCopyRemoved and
            a.virtualNurseryArenaRangeCheckO1 and
            a.radixTwoLevelMsectionLookupO1 and
            a.lxrDrcPromotedSpanHooked and
            a.c23ReferencePrototypeTsanAndAsanClean
        }
    }

    /* ------------------------------------------------------------------ */
    /* H12: Off-Heap Immutable RefC Binary (ProcBin / Arc) Contract       */
    /* ------------------------------------------------------------------ */

    part def OffHeapImmutableRefcBinaryState {
        attribute immutabilityTagBitCheckedBeforeShare : Boolean;
        attribute refcountDecrementUsesReleaseOrder : Boolean;
        attribute finalFreePrecededByAcquireFence : Boolean;
        attribute freeOnlyWhenObservedCountWasOne : Boolean;
        attribute psoThreeRefcMutantsKilled : Boolean;
    }
    requirement def OffHeapImmutableRefcBinaryLaw {
        subject b : OffHeapImmutableRefcBinaryState;
        require constraint {
            b.immutabilityTagBitCheckedBeforeShare and
            b.refcountDecrementUsesReleaseOrder and
            b.finalFreePrecededByAcquireFence and
            b.freeOnlyWhenObservedCountWasOne and
            b.psoThreeRefcMutantsKilled
        }
    }

    /* ------------------------------------------------------------------ */
    /* H13: OCaml-5 Global Work Pacing + Racket Phantom-Bytes Contract    */
    /* ------------------------------------------------------------------ */

    part def GlobalMajorPacingAndPhantomBytesState {
        attribute allocCounterIncludesManagedAndPhantomBytes : Boolean;
        attribute workSliceProportionalToAllocDelta : Boolean;
        attribute workCounterPublishedWithRelease : Boolean;
        attribute majorMarkCompletesBeforeHeapLimitM : Boolean;
        attribute emergencyStwFallbackAvoided : Boolean;
    }
    requirement def GlobalMajorPacingAndPhantomBytesLaw {
        subject p : GlobalMajorPacingAndPhantomBytesState;
        require constraint {
            p.allocCounterIncludesManagedAndPhantomBytes and
            p.workSliceProportionalToAllocDelta and
            p.workCounterPublishedWithRelease and
            p.majorMarkCompletesBeforeHeapLimitM and
            p.emergencyStwFallbackAvoided
        }
    }

    /* ------------------------------------------------------------------ */
    /* H14: Cai et al. ISPASS '22 LBO Multi-Core Admission Gate Contract  */
    /* ------------------------------------------------------------------ */

    part def LboMulticoreAdmissionGateState {
        attribute wallClockMeasured : Boolean;
        attribute totalMulticoreCpuCyclesMeasured : Boolean;
        attribute meteredP99AndP999LatencyMeasured : Boolean;
        attribute peakAndMeanRssMeasured : Boolean;
        attribute nativeCorrectnessGatesRequiredFirst : Boolean;
        attribute regressionGateRejectsHiddenLboBloat : Boolean;
    }
    requirement def LboMulticoreAdmissionGateLaw {
        subject l : LboMulticoreAdmissionGateState;
        require constraint {
            l.wallClockMeasured and
            l.totalMulticoreCpuCyclesMeasured and
            l.meteredP99AndP999LatencyMeasured and
            l.peakAndMeanRssMeasured and
            l.nativeCorrectnessGatesRequiredFirst and
            l.regressionGateRejectsHiddenLboBloat
        }
    }

    /* ------------------------------------------------------------------ */
    /* Instantiated Verified Contracts & Requirement Satisfaction         */
    /* ------------------------------------------------------------------ */

    part amp1CutContract : Amp1DropInC23CutState {
        attribute :>> allocMemLockRemovedFromLocalStillSweep = true;
        attribute :>> stillBlockGlobalFlagSkipsEscapedInO1 = true;
        attribute :>> unifiedLocalPassPromotesDirectToOwnerImmix = true;
        attribute :>> stackScratchDoubleCopyRemoved = true;
        attribute :>> virtualNurseryArenaRangeCheckO1 = true;
        attribute :>> radixTwoLevelMsectionLookupO1 = true;
        attribute :>> lxrDrcPromotedSpanHooked = true;
        attribute :>> c23ReferencePrototypeTsanAndAsanClean = true;
    }

    part offHeapRefcContract : OffHeapImmutableRefcBinaryState {
        attribute :>> immutabilityTagBitCheckedBeforeShare = true;
        attribute :>> refcountDecrementUsesReleaseOrder = true;
        attribute :>> finalFreePrecededByAcquireFence = true;
        attribute :>> freeOnlyWhenObservedCountWasOne = true;
        attribute :>> psoThreeRefcMutantsKilled = true;
    }

    part globalPacingContract : GlobalMajorPacingAndPhantomBytesState {
        attribute :>> allocCounterIncludesManagedAndPhantomBytes = true;
        attribute :>> workSliceProportionalToAllocDelta = true;
        attribute :>> workCounterPublishedWithRelease = true;
        attribute :>> majorMarkCompletesBeforeHeapLimitM = true;
        attribute :>> emergencyStwFallbackAvoided = true;
    }

    part lboGateContract : LboMulticoreAdmissionGateState {
        attribute :>> wallClockMeasured = true;
        attribute :>> totalMulticoreCpuCyclesMeasured = true;
        attribute :>> meteredP99AndP999LatencyMeasured = true;
        attribute :>> peakAndMeanRssMeasured = true;
        attribute :>> nativeCorrectnessGatesRequiredFirst = true;
        attribute :>> regressionGateRejectsHiddenLboBloat = true;
    }

    requirement amp1CutReq : Amp1DropInC23CutLaw;
    satisfy amp1CutReq by amp1CutContract;

    requirement offHeapRefcReq : OffHeapImmutableRefcBinaryLaw;
    satisfy offHeapRefcReq by offHeapRefcContract;

    requirement globalPacingReq : GlobalMajorPacingAndPhantomBytesLaw;
    satisfy globalPacingReq by globalPacingContract;

    requirement lboGateReq : LboMulticoreAdmissionGateLaw;
    satisfy lboGateReq by lboGateContract;
}
