/* Additive SysML v2 Long-Term Unified Architecture Model.
 * References canonical runtime ownership packages without modifying any sealed
 * Family 7-12 or earlier architecture package digests. */
package GambitLongTermUnifiedArchitecture {
    private import ScalarValues::*;

    /* Canonical package anchors (read-only references). */
    ref part runtimeComposition = GambitRuntimeComposition::blueprintModule0;
    ref part frameContractRef = GambitFrameContract::coordinate0;
    ref part genAdmissionRef = GambitGenerationalAdmission::candidate;
    ref part genBarrierRef = GambitGenerationalBarrier::protocol;
    ref part advantageRef = GambitAdvantageArchitecture::advantage0;
    ref part families8To12Ref = GambitFamilies8To12Composition::bind12;

    attribute scope : String = "Long-term unified architecture blueprint above baseline 824f5dc6 (Tier 1-2 + 3.1p2 + 3.2 + 3.3, 15/15 PR CI green): Wave A (Tier 3.1p3 + fast_span + Darwin dlclose #6) -> Slice 1 (Unified FrameSpec/PointId) -> Slice 2 (Non-Moving Concurrent SATB Major GC) -> Slice 3 (kqueue/epoll Evented SMP I/O + SRFI-230 & Parallel Stdlib) -> Slice 4 (Gerbil SMP Parallel Compiler + Full-Runtime TSan + Same-Source 12/12 Release Seal).";
    attribute zeroThrowawayRule : String = "Every Wave A data-structure and barrier decision must refine the Slice 1 FrameSpec and Slice 2 Concurrent SATB Major GC contracts directly; no semispace-only throwaway assumptions are admitted.";

    /* ------------------------------------------------------------------ */
    /* 1. Formal Requirements (Laws) across Wave A and Slices 1-3         */
    /* ------------------------------------------------------------------ */

    part def RestFastSpanState {
        attribute fastSpanAdmitted : Boolean;
        attribute gcEpochMatched : Boolean;
        attribute restAttemptIdle : Boolean;
        attribute observationInactive : Boolean;
        attribute stackInOwnedFastSpan : Boolean;
        attribute heapInOwnedFastSpan : Boolean;
        attribute sharedStackHeapDisjoint : Boolean;
        attribute copyGateAcquired : Boolean;
    }
    requirement def RestFastSpanLaw {
        subject r : RestFastSpanState;
        require constraint {
            not r.fastSpanAdmitted or
            (r.gcEpochMatched and r.restAttemptIdle and r.observationInactive and
             r.stackInOwnedFastSpan and r.heapInOwnedFastSpan and
             r.sharedStackHeapDisjoint and not r.copyGateAcquired)
        }
    }

    part def GenerationalStillState {
        attribute objectIsYoung : Boolean;
        attribute hasPointerSlots : Boolean;
        attribute stillDirtyFlag : Boolean;
        attribute reachableFromRoots : Boolean;
        attribute externalRefcountPositive : Boolean;
        attribute hasForeignRelease : Boolean;
        attribute atomicCasSinglePush : Boolean;
        attribute foreignReleaseDeferredOutsideStw : Boolean;
        attribute sweptInMinor : Boolean;
        attribute promotedToMature : Boolean;
        attribute satbMarkEpochCompatible : Boolean;
    }
    requirement def GenerationalStillLaw {
        subject st : GenerationalStillState;
        require constraint {
            st.satbMarkEpochCompatible and
            st.atomicCasSinglePush and
            (not st.stillDirtyFlag or st.hasPointerSlots) and
            (not st.hasForeignRelease or st.foreignReleaseDeferredOutsideStw) and
            (not st.sweptInMinor or
             (st.objectIsYoung and not st.reachableFromRoots and not st.externalRefcountPositive)) and
            (not st.promotedToMature or not st.sweptInMinor)
        }
    }

    part def UnifiedFrameSpecState {
        attribute pointIdBound : Boolean;
        attribute ofdResolved : Boolean;
        attribute singleAuthorityLive : Boolean;
        attribute cfsDistinctFromPhysicalF : Boolean;
        attribute rawUnboxedSlotsScrubbed : Boolean;
        attribute cohortMetadataPinned : Boolean;
        attribute frameMutationBarriered : Boolean;
        attribute scanOrRestoreAdmitted : Boolean;
    }
    requirement def UnifiedFrameSpecLaw {
        subject fs : UnifiedFrameSpecState;
        require constraint {
            not fs.scanOrRestoreAdmitted or
            (fs.pointIdBound and fs.ofdResolved and fs.singleAuthorityLive and
             fs.cfsDistinctFromPhysicalF and fs.rawUnboxedSlotsScrubbed and
             fs.cohortMetadataPinned and fs.frameMutationBarriered)
        }
    }

    part def ConcurrentSatbMajorState {
        attribute majorMarkActive : Boolean;
        attribute preStoreOldValGreyed : Boolean;
        attribute weakReadResurrectionShaded : Boolean;
        attribute casOldValShaded : Boolean;
        attribute satbOverflowFallbackArmed : Boolean;
        attribute allocatedBlackDuringMark : Boolean;
        attribute minorDrainsSatbIntoMajor : Boolean;
        attribute parkedFfiRootsFrozen : Boolean;
        attribute globalMarkStackEmpty : Boolean;
        attribute deadWeakEntriesClearedAtRemark : Boolean;
        attribute sweepStarted : Boolean;
        attribute matureNonMoving : Boolean;
    }
    requirement def ConcurrentSatbMajorLaw {
        subject cm : ConcurrentSatbMajorState;
        require constraint {
            cm.matureNonMoving and
            (not cm.majorMarkActive or
             (cm.preStoreOldValGreyed and cm.weakReadResurrectionShaded and
              cm.casOldValShaded and cm.satbOverflowFallbackArmed and
              cm.allocatedBlackDuringMark and cm.minorDrainsSatbIntoMajor and
              cm.parkedFfiRootsFrozen)) and
            (not cm.sweepStarted or (cm.globalMarkStackEmpty and cm.deadWeakEntriesClearedAtRemark))
        }
    }

    part def ConcurrentMajorImmixRecyclingState {
        attribute majorPhaseIdle : Boolean;
        attribute cardAlignedHoleBounds : Boolean;
        attribute allLinesInHoleDead : Boolean;
        attribute closingFillerCoversRemainder : Boolean;
        attribute postRemarkContractionAdmitted : Boolean;
        attribute holeRecycleAdmitted : Boolean;
    }
    requirement def ConcurrentMajorImmixRecyclingLaw {
        subject ir : ConcurrentMajorImmixRecyclingState;
        require constraint {
            (not ir.holeRecycleAdmitted or
             (ir.majorPhaseIdle and ir.cardAlignedHoleBounds and
              ir.allLinesInHoleDead and ir.closingFillerCoversRemainder)) and
            ir.postRemarkContractionAdmitted
        }
    }

    part def ParallelRemarkMarkBufferState {
        attribute localMarkBuffersFlushed : Boolean;
        attribute activeRemarkWorkersZero : Boolean;
        attribute parallelSweepPartitionDisjoint : Boolean;
        attribute majorMarkActive : Boolean;
        attribute idleCoreMarkExecuted : Boolean;
        attribute sweepTransitionAdmitted : Boolean;
    }
    requirement def ParallelRemarkMarkBufferLaw {
        subject pr : ParallelRemarkMarkBufferState;
        require constraint {
            (not pr.sweepTransitionAdmitted or
             (pr.localMarkBuffersFlushed and pr.activeRemarkWorkersZero)) and
            pr.parallelSweepPartitionDisjoint and
            (not pr.idleCoreMarkExecuted or pr.majorMarkActive)
        }
    }

    part def InterruptIdleDekkerState {
        attribute stackTripOffFenced : Boolean;
        attribute waitIdleChecksPendingInterrupt : Boolean;
        attribute crossCoreCardBarrierVmSafe : Boolean;
        attribute weakTableFlagsAcquireLoad : Boolean;
    }
    requirement def InterruptIdleDekkerLaw {
        subject dk : InterruptIdleDekkerState;
        require constraint {
            dk.stackTripOffFenced and
            dk.waitIdleChecksPendingInterrupt and
            dk.crossCoreCardBarrierVmSafe and
            dk.weakTableFlagsAcquireLoad
        }
    }

    part def EventedReactorState {
        attribute reactorParkedInKernel : Boolean;
        attribute blockingStwGc : Boolean;
        attribute fdCloseRequested : Boolean;
        attribute closingRejectsNewBorrows : Boolean;
        attribute fdCustodyDrained : Boolean;
        attribute kernelCloseExecuted : Boolean;
        attribute dekkerWakeBarrierPaired : Boolean;
        attribute srfi230AtomicBoxBarriered : Boolean;
    }
    requirement def EventedReactorParkLaw {
        subject io : EventedReactorState;
        require constraint {
            (not io.reactorParkedInKernel or not io.blockingStwGc) and
            (not io.fdCloseRequested or io.closingRejectsNewBorrows) and
            (not io.kernelCloseExecuted or (io.fdCloseRequested and io.fdCustodyDrained)) and
            io.dekkerWakeBarrierPaired and
            io.srfi230AtomicBoxBarriered
        }
    }

    part def AdaptiveHeapScalingState {
        attribute censusOversizedReleased : Boolean;
        attribute contractionHistoryDecays : Boolean;
        attribute lowerBoundPreserved : Boolean;
        attribute gscContractedBeforeCc1 : Boolean;
        attribute smpHeadroomSublinear : Boolean;
        attribute explicitLivePercentHonored : Boolean;
        attribute largeStillDirectMmap : Boolean;
        attribute mailboxEmptyCheckUnderMutex : Boolean;
        attribute slice2MajorGcCompatible : Boolean;
    }
    requirement def AdaptiveHeapScalingLaw {
        subject m : AdaptiveHeapScalingState;
        require constraint {
            m.censusOversizedReleased and
            m.contractionHistoryDecays and
            m.lowerBoundPreserved and
            m.gscContractedBeforeCc1 and
            m.smpHeadroomSublinear and
            m.explicitLivePercentHonored and
            m.largeStillDirectMmap and
            m.mailboxEmptyCheckUnderMutex and
            m.slice2MajorGcCompatible
        }
    }

    part def GerbilMulticoreMemoryChallengeState {
        attribute sameProducerAbiClosed : Boolean;
        attribute workersWithin8GiBEnvelope : Boolean;
        attribute zeroDualPeakGscCc1Overlap : Boolean;
        attribute stdlibDriverIdleFootprintBounded : Boolean;
        attribute lockPoisoningRejected : Boolean;
    }
    requirement def GerbilMulticoreMemoryChallengeLaw {
        subject g : GerbilMulticoreMemoryChallengeState;
        require constraint {
            g.sameProducerAbiClosed and
            g.workersWithin8GiBEnvelope and
            g.zeroDualPeakGscCc1Overlap and
            g.stdlibDriverIdleFootprintBounded and
            g.lockPoisoningRejected
        }
    }

    /* ------------------------------------------------------------------ */
    /* 2. Primary Academic Paper Anchors                                  */
    /* ------------------------------------------------------------------ */

    part def PaperAnchor {
        attribute paperId : String;
        attribute citation : String;
        attribute targetSlice : String;
        attribute adoptedMechanism : String;
        attribute nonImportBoundary : String;
    }

    part paperFeeleyMiller90 : PaperAnchor {
        attribute :>> paperId = "feeley-miller-lfp-1990";
        attribute :>> citation = "Feeley & Miller, LFP 1990: A Parallel Virtual Machine for Efficient Scheme Compilation";
        attribute :>> targetSlice = "Slice1_UnifiedFrameSpec";
        attribute :>> adoptedMechanism = "Logical FrameSpec/PointId, bidirectional target knowledge, explicit operand storage classes";
        attribute :>> nonImportBoundary = "PVM futures do not imply safe concurrent invocation of one Scheme continuation";
    }
    part paperFeeley2000 : PaperAnchor {
        attribute :>> paperId = "feeley-continuations-2000";
        attribute :>> citation = "Feeley, Scheme Workshop 2000: Portable First-Class Continuations with C Interop";
        attribute :>> targetSlice = "Slice1_UnifiedFrameSpec";
        attribute :>> adoptedMechanism = "Lazy stack/heap frame capture and multi-shot resumption over C frames";
        attribute :>> nonImportBoundary = "Captured mature frames remain mutable via ##frame-set! and require card + SATB barriers";
    }
    part paperDiwan92 : PaperAnchor {
        attribute :>> paperId = "diwan-moss-hudson-pldi-1992";
        attribute :>> citation = "Diwan, Moss & Hudson, PLDI 1992: Compiler Support for Garbage Collection";
        attribute :>> targetSlice = "Slice1_UnifiedFrameSpec";
        attribute :>> adoptedMechanism = "Compiler-emitted exact per-PointId pointer liveness descriptors";
        attribute :>> nonImportBoundary = "Gambit combines dynamic Scheme tags with explicit raw unboxed spill scrubbing";
    }
    part paperYuasa90 : PaperAnchor {
        attribute :>> paperId = "yuasa-satb-1990";
        attribute :>> citation = "Yuasa, JSS 1990: Real-Time Garbage Collection on General-Purpose Machines";
        attribute :>> targetSlice = "Slice2_ConcurrentMajorGc";
        attribute :>> adoptedMechanism = "Pre-store SATB deletion barrier + black allocation during mark for bounded termination";
        attribute :>> nonImportBoundary = "Uniprocessor model replaced by C11/C23 release-acquire and per-processor SATB logs";
    }
    part paperVcgc98 : PaperAnchor {
        attribute :>> paperId = "huelsbergen-winterbottom-vcgc-1998";
        attribute :>> citation = "Huelsbergen & Winterbottom, ISMM 1998: Very Concurrent Mark-&-Sweep GC (VCGC)";
        attribute :>> targetSlice = "Slice2_ConcurrentMajorGc";
        attribute :>> adoptedMechanism = "Color-epoch non-moving concurrent mark + concurrent sweep with coarse phase barriers";
        attribute :>> nonImportBoundary = "Requires explicit C23 atomic mark-bit operations for strict DRF/TSan soundness";
    }
    part paperImmix08 : PaperAnchor {
        attribute :>> paperId = "blackburn-mckinley-immix-2008";
        attribute :>> citation = "Blackburn & McKinley, PLDI 2008: Immix Mark-Region Garbage Collector";
        attribute :>> targetSlice = "Slice2_ConcurrentMajorGc";
        attribute :>> adoptedMechanism = "Line/block mark-region non-moving mature space + opportunistic STW defragmentation on msections";
        attribute :>> nonImportBoundary = "Defragmentation moves only at explicit STW cuts; concurrent cycles stay non-moving";
    }
    part paperOcaml5_2020 : PaperAnchor {
        attribute :>> paperId = "sivaramakrishnan-ocaml5-icfp-2020";
        attribute :>> citation = "Sivaramakrishnan et al., ICFP 2020: Retrofitting Parallelism onto OCaml";
        attribute :>> targetSlice = "Slice2_ConcurrentMajorGc";
        attribute :>> adoptedMechanism = "STW parallel generational Minor GC composed with concurrent SATB Major GC and FFI domain park";
        attribute :>> nonImportBoundary = "Gambit preserves multi-shot continuations and C23 atomics rather than OCaml fiber stacks or volatile fences";
    }
    part paperUenoOhori16 : PaperAnchor {
        attribute :>> paperId = "ueno-ohori-icfp-2016";
        attribute :>> citation = "Ueno & Ohori, ICFP 2016: Fully Concurrent GC for Functional Programs on Multicore Processors";
        attribute :>> targetSlice = "Slice2_ConcurrentMajorGc";
        attribute :>> adoptedMechanism = "Non-moving bitmap-marked segments and lock-free SATB buffers for functional runtimes";
        attribute :>> nonImportBoundary = "Gambit retains tagged words and external still-object refcount headers";
    }
    part paperLemon01 : PaperAnchor {
        attribute :>> paperId = "lemon-kqueue-usenix-2001";
        attribute :>> citation = "Lemon, USENIX ATC 2001: Kqueue Generic and Scalable Event Notification";
        attribute :>> targetSlice = "Slice3_EventedIoAndParallelStdlib";
        attribute :>> adoptedMechanism = "Persistent kernel interest sets (kqueue/epoll), O(ready) dispatch, EVFILT_USER/eventfd wakeups";
        attribute :>> nonImportBoundary = "Explicit userspace FD-generation custody fence remains mandatory to prevent close/reuse ABA";
    }
    part paperLe13 : PaperAnchor {
        attribute :>> paperId = "le-workstealing-weak-memory-ppopp-2013";
        attribute :>> citation = "Le, Pop, Cohen & Zappa Nardelli, PPoPP 2013: Correct & Efficient Work-Stealing for Weak Memory Models";
        attribute :>> targetSlice = "Slice3_EventedIoAndParallelStdlib";
        attribute :>> adoptedMechanism = "C11 relaxed/acquire/release/seq_cst Chase-Lev work-stealing deque sound on ARM64";
        attribute :>> nonImportBoundary = "Deque backing arrays must remain GC-traced Scheme vectors or registered root banks";
    }
    part paperSrfi230 : PaperAnchor {
        attribute :>> paperId = "srfi-230-atomic-operations-2021";
        attribute :>> citation = "Nieper-Wisskirchen, SRFI-230 (Final 2021): Atomic Operations";
        attribute :>> targetSlice = "Slice3_EventedIoAndParallelStdlib";
        attribute :>> adoptedMechanism = "Standard Scheme atomic-box/fxbox/flag/pair and fences lowered to ___ORDERED_WORD_NATIVE";
        attribute :>> nonImportBoundary = "Ordinary Scheme vector-set!/set-car! remain DRF-0 non-atomic stores";
    }

    /* ------------------------------------------------------------------ */
    /* 3. Vertical Slices & Formal Gate Bindings                          */
    /* ------------------------------------------------------------------ */

    part def ArchitectureSlice {
        attribute sliceId : String;
        attribute title : String;
        attribute status : String;
        attribute quintV2Model : String;
        attribute leanProof : String;
        attribute cbmcTarget : String;
        attribute exitGate : String;
    }

    part slice0WaveA : ArchitectureSlice {
        attribute :>> sliceId = "WaveA";
        attribute :>> title = "Tier 3.1p3: Lock-Free Rest Fast-Span, Generational Still, O(Y) Minor GC, Darwin dlclose (#6)";
        attribute :>> status = "STAGE8_CLOSED_COMMITTED";
        attribute :>> quintV2Model = "dev/refactoring/modern-c/models/quint/v2/tier31p3_still_and_rest_fastpath_v2.qnt";
        attribute :>> leanProof = "dev/refactoring/modern-c/models/lean/LongTermUnifiedRefinement.lean";
        attribute :>> cbmcTarget = "tests/contracts/modern-c/weak-memory/ (still_young_sweep + rest_fast_span PSO)";
        attribute :>> exitGate = "par_rest_alloc >= 2.5x p4; par_alloc_gc GC < 15%; p4 Minor GC < 0.4ms; 66/66 PBT; 15/15 PR CI green; Issue #5/#6/#8 updated";
    }
    part slice1FrameSpec : ArchitectureSlice {
        attribute :>> sliceId = "Slice1";
        attribute :>> title = "Unified FrameSpec / PointId Semantic Authority (PlanAbi + GeneratedCheckpoint + ControlRoots)";
        attribute :>> status = "STAGE8_CLOSED_COMMITTED";
        attribute :>> quintV2Model = "dev/refactoring/modern-c/models/quint/v2/unified_framespec_authority_v2.qnt";
        attribute :>> leanProof = "dev/refactoring/modern-c/models/lean/LongTermUnifiedRefinement.lean";
        attribute :>> cbmcTarget = "FrameSpec IFD/OFD encoder-decoder & internal-return cfs/F equivalence harness";
        attribute :>> exitGate = "Single Scheme-emitted FrameSpec consumed by GC, capture/restore, debugger; zero duplicate C macro layout inference; GCC-16 single-host RSS < 4 GiB; 15/15 CI green";
    }
    part slice2ConcurrentMajor : ArchitectureSlice {
        attribute :>> sliceId = "Slice2";
        attribute :>> title = "Non-Moving Immix Mark-Region Mature Space (Line-Hole Recycling) + Parallel Remark/Sweep + Per-Processor Mark Buffers + Idle-Core Marking + Concurrent SATB Major GC";
        attribute :>> status = "PRODUCTION_SYSTEM_V2_ACTIVE";
        attribute :>> quintV2Model = "dev/refactoring/modern-c/models/quint/v2/concurrent_major_satb_v2.qnt";
        attribute :>> leanProof = "dev/refactoring/modern-c/models/lean/LongTermUnifiedRefinement.lean";
        attribute :>> cbmcTarget = "dev/refactoring/modern-c/models/cbmc/slice2_satb_major_pso.c + slice2_interrupt_idle_dekker_pso.c + Apple Clang C23 TSan";
        attribute :>> exitGate = "Parallel STW Remark + Immix line-hole recycling + post-Remark contraction; 0 TSan races across t1/t5/t6/c1/c5; 69/69 multicore PBT; 438/438 official SMP; N=5 AB/BA revision_matrix admitted=true; 15/15 CI green";
    }
    part slice3IoAndStdlib : ArchitectureSlice {
        attribute :>> sliceId = "Slice3";
        attribute :>> title = "kqueue/epoll Evented SMP I/O Reactor + SRFI-230 & Work-Stealing Parallel Stdlib";
        attribute :>> status = "DESIGN_ALIGNED";
        attribute :>> quintV2Model = "dev/refactoring/modern-c/models/quint/v2/evented_io_reactor_park_v2.qnt";
        attribute :>> leanProof = "dev/refactoring/modern-c/models/lean/LongTermUnifiedRefinement.lean";
        attribute :>> cbmcTarget = "FD-generation close/select ABA + Chase-Lev weak-memory C11/PSO harness";
        attribute :>> exitGate = ">10,000 concurrent sockets without FD_SETSIZE limit; 0 STW GC stall during idle reactor wait; SRFI-230 & parallel stdlib linearizability + PBT green";
    }
    part slice4GerbilRelease : ArchitectureSlice {
        attribute :>> sliceId = "Slice4";
        attribute :>> title = "Gerbil SMP Parallel Compiler + Full-Runtime TSan + Same-Source 12/12 Release Seal";
        attribute :>> status = "DESIGN_ALIGNED";
        attribute :>> quintV2Model = "dev/refactoring/modern-c/models/quint/v2/gerbil_multicore_memory_challenge_v2.qnt";
        attribute :>> leanProof = "dev/refactoring/modern-c/models/lean/GerbilProducerClosure.lean";
        attribute :>> cbmcTarget = "tests/contracts/modern-c/gerbil/abi-seal-check/harness.c";
        attribute :>> exitGate = "Gerbil 8/8 stages + parallel stdlib build; wholeRuntimeAdmitted=true on single sealed producer; official Release Tag";
    }
    part memoryEnvelopeTrack : ArchitectureSlice {
        attribute :>> sliceId = "MemoryEnvelope";
        attribute :>> title = "Adaptive Heap Contraction, Sub-Linear O(sqrt(P)) Floor, Direct-mmap Still/Census, & Pre-cc1 gsc Trim (v26 <-> Slice 2)";
        attribute :>> status = "ACTIVE_SYNCED_WITH_SLICE2";
        attribute :>> quintV2Model = "dev/refactoring/modern-c/models/quint/v2/adaptive_heap_scaling_and_reclaim_v2.qnt";
        attribute :>> leanProof = "dev/refactoring/modern-c/models/lean/AdaptiveHeapScalingRefinement.lean";
        attribute :>> cbmcTarget = "dev/refactoring/modern-c/models/cbmc/adaptive_heap_scaling_pso.c";
        attribute :>> exitGate = "Zero O(P) linear floor growth p1..p8; gsc+cc1 dual-peak cut >=1.5 GiB at 8c; stdlib driver fp < 3 GiB; par_rest_alloc >= 2.5x p8; 12/12 same-source PASS";
    }

    /* ------------------------------------------------------------------ */
    /* 4. Interconnection Graph for Direct Native SysML -> D2 Rendering   */
    /* ------------------------------------------------------------------ */

    part def SliceNode {
        attribute label : String;
    }

    part LongTermSliceGraph {
        part baseline824f5dc6 : SliceNode {
            attribute :>> label = "Baseline 824f5dc6 + Sealed v25 12/12 (Tier 1-3.3 / Same-Source 12/12 GREEN)";
        }
        part memoryEnvelope : SliceNode {
            attribute :>> label = "Memory Envelope Track: Direct-mmap Census/Still + Contraction + O(sqrt(P)) Floor + Pre-cc1 Trim";
        }
        part waveA : SliceNode {
            attribute :>> label = "Wave A: Tier 3.1p3 (Rest fast_span + Generational Still + O(Y) Minor + #6)";
        }
        part slice1FrameSpec : SliceNode {
            attribute :>> label = "Slice 1: Unified FrameSpec & PointId Authority";
        }
        part slice2ConcurrentMajor : SliceNode {
            attribute :>> label = "Slice 2 (v2 Production): Immix Line-Hole Recycling + Parallel Remark/Sweep + SATB Major GC";
        }
        part slice3IoAndStdlib : SliceNode {
            attribute :>> label = "Slice 3: kqueue/epoll Reactor + SRFI-230 & Parallel Stdlib";
        }
        part slice4GerbilSeal : SliceNode {
            attribute :>> label = "Slice 4: Gerbil SMP Parallel Compiler + 12/12 Release Seal";
        }

        connection base_to_waveA connect baseline824f5dc6 to waveA;
        connection base_to_memenv connect baseline824f5dc6 to memoryEnvelope;
        connection memenv_to_major connect memoryEnvelope to slice2ConcurrentMajor;
        connection memenv_to_seal connect memoryEnvelope to slice4GerbilSeal;
        connection waveA_to_framespec connect waveA to slice1FrameSpec;
        connection framespec_to_major connect slice1FrameSpec to slice2ConcurrentMajor;
        connection waveA_to_io_stdlib connect waveA to slice3IoAndStdlib;
        connection major_to_seal connect slice2ConcurrentMajor to slice4GerbilSeal;
        connection io_stdlib_to_seal connect slice3IoAndStdlib to slice4GerbilSeal;
    }
}
