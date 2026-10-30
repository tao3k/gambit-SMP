package GambitCopyCustody {
  private import ScalarValues::*;
  attribute runtimeAdmitted:Boolean=false;
  attribute commitAdmitted:Boolean=false;
  attribute sourceLock:String="evidence/research/modern-c-bootstrap/frame-custody-source.lock.json";
  part def Contract {
    attribute id:String; attribute cSource:String; attribute invariant:String;
    attribute quint:String; attribute lean:String; attribute open:String; attribute sourceScope:String;
    attribute nativeMethod:String; attribute nativeArtifact:String; attribute nativeClass:String; attribute nativeScope:String;
  }
  part frozenCensus:Contract {
    attribute :>> id="COPY-FROZEN";
    attribute :>> sourceScope="C-simulation:COPY-FROZEN";
    attribute :>> nativeMethod="native-bootstrap"; attribute :>> nativeArtifact="evidence/research/modern-c-bootstrap/frame-custody-bootstrap.recipe.json"; attribute :>> nativeClass="native-bootstrap"; attribute :>> nativeScope="51 generated products and full two-pass bootstrap; not a universal packing proof";
    attribute :>> cSource="mem.c setup_stack_heap_vmstate; ___garbage_collect_pstate";
    attribute :>> invariant="Every participant flushes fp/hp, freezes roots, then closes the old-set barrier before the source census or any parity flip. The census counts allocated words, not live words. Two initial destination intervals per participant are necessary, not sufficient.";
    attribute :>> quint="copy_custody.freeze; copy_custody.plan";
    attribute :>> lean="Gambit.CopyCustody.copyBoundNeedsUniqueSources";
    attribute :>> open="Per-worker contiguous capacity, captured-frame duplication, chunk markers/terminal fragments and full root ownership remain unproved. No added heap multiplier is credited.";
  }
  part copySource:Contract {
    attribute :>> id="COPY-SOURCE";
    attribute :>> sourceScope="C-simulation:COPY-SOURCE";
    attribute :>> nativeMethod="native-whole"; attribute :>> nativeArtifact="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> nativeClass="native-whole"; attribute :>> nativeScope="p11 compiler and host-managed runtime, 80 roots, eleven GCs and multi-shot results, natural shutdown";
    attribute :>> cSource="mem.c require_fromspace_copy_source; change_object_scan_state; publish_object_scan; mark_array; mark_captured_continuation; scan";
    attribute :>> invariant="A MOVABLE forwarding attempt must refer to the frozen fromspace half. A tospace input is rejected before forwarding; failure coordinates are retained. CAS losers do not increment copied_words. A winning first field is Tail work and later scan skips it.";
    attribute :>> quint="copy_custody.forward; copy_custody.initializeCopy; copy_custody.publish; copy_custody.claim; copy_custody.observeDuplicate; copy_custody.completeTail; copy_custody.scan";
    attribute :>> lean="Gambit.CopyCustody.copyBoundNeedsUniqueSources; Gambit.CopyCustody.claimPreservesUniqueIdentities; Gambit.CopyCustody.duplicateTaskDoesNotCreateWriter";
    attribute :>> open="Destination objects now publish READY after initialization, claim OWNED before field repair and finish DONE. Repeated tasks acquire no second field-write authority; original owner and Tail debts must drain before termination. This is not yet a proof that chunk/root cells are uniquely scanned; C CAS/read memory order and forwarding-before-payload publication need refinement. Runtime guard costs logarithmic lookup per forwarding attempt.";
  }
  part abortDomain:Contract {
    attribute :>> id="ABORT-ISOLATION";
    attribute :>> sourceScope="C-simulation:ABORT-ISOLATION";
    attribute :>> nativeMethod="native-fault"; attribute :>> nativeArtifact="evidence/research/modern-c-bootstrap/scan-ownership-isolation-multi.scm"; attribute :>> nativeClass="native-fault-control"; attribute :>> nativeScope="three healthy members finish three collections while an unpublished native actor stays held and join is unknown; safety exit only";
    attribute :>> cSource="setup.c start_processor_execution; ___vm_resize_pstate; os_thread.c start_pthread_thread; mem.c ___isolate_aborted_resize";
    attribute :>> invariant="An immutable ABORT permit is independent of join. All contexts initialized, no unknown create, no RUN permit, no allocated movable/still/RC payload, and no activation marker allow heap claims to detach. Native record, gate and descriptors remain retained and cannot be reused. The retained request thunk is scanned by worker zero.";
    attribute :>> quint="copy_custody.abort; copy_custody.unknownJoin; copy_custody.isolate; copy_custody.collectHealthy";
    attribute :>> lean="Gambit.CopyCustody.isolationDoesNotRequireJoin; Gambit.CopyCustody.nativeReuseStillNeedsJoin";
    attribute :>> open="Published retiree, unknown create, raw native borrow, owner interruption or failed isolation remains retained and GC-inadmissible. This is not arbitrary owner-death recovery or a native handle reaper. Current allocation rollback control reaches startup wait failure; four of five controls pass. Its original failure is retained and cannot be erased by scoped unknown-join success.";
  }
  part chunkTransport:Contract {
    attribute :>> id="CHUNK-TRANSPORT";
    attribute :>> sourceScope="C-simulation:CHUNK-TRANSPORT";
    attribute :>> nativeMethod="native-whole"; attribute :>> nativeArtifact="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> nativeClass="native-whole"; attribute :>> nativeScope="p11 compiler and host-managed runtime with explicit FIFO gate and frontier, 80 roots and eleven GCs; not C simulation";
    attribute :>> cSource="mem.c lock_chunk_fifo; unlock_chunk_fifo; take_heap_chunk; require_chunk_transition; end_heap_chunk; scan_complete_heap_chunk; scan_movable_objs_to_scan; mark_reachable_from_marked";
    attribute :>> invariant="Local frontier holds a chunk identity before root copying. Private close publishes queued once; own and stolen dequeue acquire the same FIFO gate and claim queued-to-held before head advance; reaching the terminal marker drains held authority. No unlocked head/tail reads. Chunk completion does not pay object, Tail or frame-link debt.";
    attribute :>> quint="copy_custody.closePrivate; copy_custody.closeHeld; copy_custody.takeChunk; copy_custody.selectFrontier; copy_custody.drainChunk";
    attribute :>> lean="Gambit.CopyCustody.localChunkCannotBeQueued; Gambit.CopyCustody.chunkCompletionDoesNotPayTail; Gambit.CopyCustody.sourceChargePlusPacking";
    attribute :>> open="Packed link/object positions must be disjoint and C adapters must implement acquire/release. A prior p11 own-FIFO claim reached DRAINED state under the generic ticket-lock protocol. The CAS gate retires that transport dependency, not all runtime locks. No fairness, interrupted worker takeover, complete frame-link partition or general physical capacity proof is claimed.";
  }
  part def Handoff { ref part producer:Contract; ref part consumer:Contract; attribute obligation:String; }
  part frameAccess:Contract {
    attribute :>> id="FRAME-ACCESS";
    attribute :>> sourceScope="C-simulation:FRAME-ACCESS";
    attribute :>> nativeMethod="native-whole"; attribute :>> nativeArtifact="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> nativeClass="native-whole"; attribute :>> nativeScope="p11 compiler/host runtime, multi-shot continuation and wide roots; frame-domain serialization and ordinary/link partition; not arbitrary FFI writer admission";
    attribute :>> cSource="mem.c acquire_frame_access; release_frame_access; mark_captured_continuation_locked; mark_captured_continuation; mark_continuation; mark_frame; scan; ___frame_ordinary_root_begin";
    attribute :>> invariant="Initial captured-link read, stack-root repair, stack-to-heap construction and destination frame-link access share one acquire/release domain. Ordinary root runs exclude the structural link without writing FAL; heap-frame link repair is explicit. READY covers raw payload, while frame access gates semantic link completion. Queue gates are released before frame access.";
    attribute :>> quint="copy_custody.acquireConstructor; copy_custody.beginFrameChain; copy_custody.publishFrameRaw; copy_custody.repairFrameLink; copy_custody.releaseFrameAccess; copy_custody.acquireScanner; copy_custody.scanOrdinaryFrame";
    attribute :>> lean="Gambit.CopyCustody.ordinaryRootsExcludeLink; Gambit.CopyCustody.frameGateExcludesSecondRole";
    attribute :>> open="VM-wide serialization may reduce root-scan parallelism. Actual C pointer/root-map refinement, active-stack versus captured-segment separation, module metadata lifetime and unmanaged FFI writers remain premises. New-stack restoration is private until final resumption barrier; arbitrary failed-worker takeover is not admitted.";
  }
  part copyReservation:Contract {
    attribute :>> id="COPY-RESERVATION";
    attribute :>> sourceScope="C-simulation:COPY-RESERVATION";
    attribute :>> nativeMethod="native-whole"; attribute :>> nativeArtifact="vendor/gambit/tests/frame-continuation-roots.scm"; attribute :>> nativeClass="native-whole"; attribute :>> nativeScope="whole p11 map/root workload; contiguous per-copy grants and normal CAS-result handling; unknown owner recovery and full-round packing excluded";
    attribute :>> cSource="mem.c reserve_copy; cancel_copy; commit_copy; finish_tail; mark_array; mark_captured_continuation_locked; garbage_collect_mark_weak_phase";
    attribute :>> invariant="An actual private contiguous interval precedes header write and source CAS. Known loss cancels the entire unpublished interval, including alignment slack; known win initializes/publishes then commits. Tail is recorded before publication and paid only when its cell is repaired. Reserved minus cancelled equals copied plus committed padding at the completed marking cut. Unknown outcome cannot authorize refund.";
    attribute :>> quint="copy_custody.reservePrivateCopy; copy_custody.loseForwarding; copy_custody.winForwarding; copy_custody.initializeReserved; copy_custody.commitReservation; copy_custody.unknownReservation";
    attribute :>> lean="Gambit.CopyCustody.refundPreservesReservationCharge; Gambit.CopyCustody.commitPreservesReservationCharge; Gambit.CopyCustody.unknownCannotRefund; Gambit.CopyCustody.generatedFrameCopyUpperBound";
    attribute :>> open="Per-copy interval admission is not a complete pre-flip capacity transaction. Current private-context allocation, source census U, frame Amax and marker/terminal packing need a full-round proof. Generator validates stored fs below 16384 and expands internal frames; the 8192 runtime declaration is not that proof. Counter overflow, native cancellation observability and all allocator adapters need qualification.";
  }
  part censusToCopy:Handoff { ref part :>> producer=frozenCensus; ref part :>> consumer=copySource;
    attribute :>> obligation="Source upper bound may become capacity evidence only after unique scanning and destination packing are proved."; }
  part abortToGC:Handoff { ref part :>> producer=abortDomain; ref part :>> consumer=frozenCensus;
    attribute :>> obligation="Old collective publishes abort_isolated before healthy GC; detached empty intervals may be reused, stable native identity must not be overwritten."; }  attribute physicalPackingClosed:Boolean=false;
  part transportToObject:Handoff { ref part :>> producer=chunkTransport; ref part :>> consumer=copySource;
    attribute :>> obligation="Disjoint chunk traversal requests do not replace the per-object write claim; copy-winner Tail and special frame links retain separate custody."; }
  part frameToObject:Handoff { ref part :>> producer=frameAccess; ref part :>> consumer=copySource;
    attribute :>> obligation="A scanner claiming a raw-ready frame must acquire the frame domain before reading the structural link or ordinary roots; constructor writes precede release."; }
  part reservationToCensus:Handoff { ref part :>> producer=copyReservation; ref part :>> consumer=frozenCensus;
    attribute :>> obligation="Private grants and known-result refunds provide physical accounting premises; they do not alone establish U, Amax or a pre-flip whole-round grant."; }
  part reservationToFrame:Handoff { ref part :>> producer=copyReservation; ref part :>> consumer=frameAccess;
    attribute :>> obligation="Captured-frame payload construction uses the same contiguous reservation and commit endpoints; frame/link publication does not erase allocation debt."; }
  attribute capacityRule:String="Conditional: G=L-Amax-4-ceil(L/K)>0; heap sections <= W+floor(U/G); P >= N+2W+floor(U/G)+R+Q includes restoration and retained domains. U, Amax, source identity, packing and Tail/worker closure must be proved before issuing a pre-flip grant. No automatic heap growth from this formula is implemented.";
  part def Benefit { attribute id:String; attribute eliminated:String; attribute added:String; attribute bound:String; attribute gate:String; }
  part scanBenefit:Benefit {
    attribute :>> id="object-scan-authority";
    attribute :>> eliminated="Second ordinary field writer on duplicate chunk/frontier delivery; pair fast path bypassing authority";
    attribute :>> added="Per-destination READY/OWNED/DONE packed CAS state, initialization publication and first-field Tail exclusion";
    attribute :>> bound="Two bits per destination word: 16384 bytes per 1048576-byte section in the measured profile. O(M) trailer reset plus object state lookups/CAS. No speed or RSS claim.";
    attribute :>> gate="Native whole passes; packed CAS/C memory-order and arbitrary root/FFI refinement remain open";
  }
  part abortBenefit:Benefit {
    attribute :>> id="native-heap-custody-split";
    attribute :>> eliminated="Whole-VM GC refusal solely because a never-entered empty startup actor lacks a successful join";
    attribute :>> added="Empty-domain/immutable ABORT checks, retained native records and source root, fixed isolated receipt";
    attribute :>> bound="Unknown 3-to-5 growth detaches four empty section claims; three healthy members complete three GCs while one native actor remains held. No native handle or OS-stack refund is claimed.";
    attribute :>> gate="Known managed abort only; published retiree, unknown create, raw borrow and native reclamation remain excluded";
  }
  part capacityBenefit:Benefit {
    attribute :>> id="pre-copy-accounting";
    attribute :>> eliminated="Using a post-copy heap resize or aggregate logical free words as evidence of pre-copy capacity";
    attribute :>> added="Frozen source census, per-worker copy counts, explicit physical packing and restoration proof obligations";
    attribute :>> bound="No new Scheme root cells or configured heap increase in the transport cut. The historical transport VM was 90016 bytes; current configured VM is 95144 bytes, including all worker state. Existing trailer remains 16384 bytes per section; overlapping fields must not be added twice.";
    attribute :>> gate="General U/Amax/packing and pre-flip all-or-retain allocator transaction are not implemented or admitted";
  }
  part transportBenefit:Benefit {
    attribute :>> id="explicit-chunk-transport";
    attribute :>> eliminated="Allocation-range ownership inference, duplicated own/stolen dequeue implementations, unlocked head/tail prefilter, collector FIFO dependency on volatile ticket-grant polling";
    attribute :>> added="Worker-owned frontier and active progress fields, chunk claim/drain CAS in existing non-object trailer positions, acquire-CAS/release-clear FIFO gate";
    attribute :>> bound="Zero additional trailer bytes per section over object scan authority. Worker 120 to 168 bytes; VM 86944 to 90016 bytes, a 3072-byte total delta including all 64 worker slots. Three p11 graph GCs publish/take 239/239, 253/253, 241/241 chunks with zero observed duplicate object scans. Extra atomic attempts per steal and identity lookups are paid; no speed/RSS reduction is inferred.";
    attribute :>> gate="Whole native, finite history and conditional laws are separate from actual C pointer/memory-order simulation and capacity admission";
  }
  part frameBenefit:Benefit {
    attribute :>> id="frame-root-partition";
    attribute :>> eliminated="Unlocked initial link read, frame constructor/scanner races, temporary FAL writes used to suppress structural-link scanning";
    attribute :>> added="One VM frame access gate, explicit ordinary-root cursor excluding the link, independent heap-link repair and live frame descriptor/payload admission";
    attribute :>> bound="Worker 248 bytes (80 added); VM 95144 bytes (5128 added over transport). One gate serializes frame-domain operations. No speed or peak-RSS claim.";
    attribute :>> gate="Normal multi-shot/GC qualification does not admit unmanaged FFI writers, arbitrary metadata or failed collector owners";
  }
  part reservationBenefit:Benefit {
    attribute :>> id="private-copy-grants";
    attribute :>> eliminated="Duplicated inline capacity loops and alloc-- rollback tied to one header; alignment padding published before knowing the CAS result";
    attribute :>> added="Private begin/header/past grant, complete known-loss cancellation, commit endpoint and Tail/conservation records";
    attribute :>> bound="No configured heap increase. The shared frame/grant records add 5128 VM bytes total; this overlaps the frame benefit and must not be added twice. No whole-round peak reduction is claimed; a shared bump allocator cannot reuse this private rollback contract.";
    attribute :>> gate="Amax and full-round physical reservation, unknown outcome recovery and finite counter bounds remain open";
  }
}
