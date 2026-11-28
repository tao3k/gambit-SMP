package GambitStressGsiSectionRealization {
 private import ScalarValues::*;
 ref part planning=GambitStressGsiRestoration::plan;
 ref part family=GambitModernCDeliveryPlan::a6;

 attribute invariant:String="Each physical section has a private claim per semispace. Only the carrier may park, resume or release its stack claim. Heap use remains sticky until epoch retirement. A reusable claim has no heap use and is absent from the active stack.";
 attribute acquire:String="heap-sections.inc: fresh stack and heap setters, both shared-fallback partitions and the copy-worker arena producer. startup-reservation.inc clears returned grants only on existing known rollback.";
 attribute undo:String="allocation-limits.inc: consume the canonical first-break edge, restore the predecessor's parked floor, then publish the outgoing exclusive section to the carrier reuse list. Preserve the copy path when the outgoing section has heap use.";
 attribute reuse:String="Both limit slow paths take the same carrier claim. The intrusive link is private metadata. Heap reuse charges the outgoing heap words as fresh heap acquisition does.";
 attribute retire:String="After the continuation move and still/weak cleanup, each frozen member publishes a source-drained receipt at the cleanup collective. The coordinator checks every roster entry against its context, collection epoch and old half before clearing any old claim or resizing. One missing receipt retains the complete old claim set.";
 attribute nativeBoundary:String="The paired C fixture reproduces the old floor loss and exercises real undo and two-parity retirement. It seeds the pre-undo state and does not simulate an arbitrarily delayed concurrent GC reader.";
 attribute causalBoundary:String="The unchanged compiled p2 TFIB still exits abnormally on the candidate. The old-reader transition is a distinct obligation and a common underlying fault is unproved.";
 attribute resumeCutModel:String="dev/refactoring/modern-c/models/quint/stress_gsi_resume_cut.qnt";
 attribute historicalAllocationContract:String="models/gambit/tfib_gc_handoff.qnt::reservedWrite supplies the range and generation falsifier. DEV models the missing old-reader retirement and resumed writer ordering only.";
 attribute fastWriter:String="vendor/gambit/lib/_thread.c::thread-join-wait L1 emits ALLOC_CLO(4UL) before CHECK_HEAP. module_generation.h.in and object_access.h.in determine header, alignment and complete write extent.";
 attribute cursorPublication:String="collection-round.inc hands off an arena or empty span and moves the continuation. Old claims retire after physical readers drain. memory-lifecycle.inc prepare_mem_pstate publishes context hp and processor heap_limit. Generated host entry reloads hp through R_ALL and R_HEAP. The C emitter charges each closure group before emission. The physical reserve beyond the poll limit must cover the complete emitted region.";
 attribute readerNegative:String="The collector-diagnostics fixture pauses a pthread immediately before the last load in move_continuation. The positive path joins before retiring. The negative path clears claim metadata while the reader is held, detects early retirement, and retains the storage. Production collective ordering and native stale-cursor injection remain open.";
 attribute readerControlOutcome:String="The exact selected delta under the existing Bazel profile observed both C markers. The test owns pthread ordering. Production collective refinement remains open.";
 attribute nativeFamily:String="Exact combined producer in the same cache and Bazel profile, one original p2 then p1 four-file GSI campaign under 295s inner and 300s outer bounds. Reject spliced, missing or incomplete results. Preserve 5/12.";
 attribute currentFamilyOutcome:String="One unspliced current-delta attempt. p2 passed two interrupt files; the TFIB and terminate shard timed out on TFIB without a completion marker. p1 did not start. Children reaped, shared cache restored. Whole family and submission remain open.";
 attribute extraClaimsPerSection:Integer=2;
 attribute admissionOpen:Boolean=true;
}
