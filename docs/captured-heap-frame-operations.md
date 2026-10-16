# Captured Heap Frame Operations

## Decision Before Execution

The new exact-image kernel incident reads an invalid RA from a purported heap
frame before RETN metadata decoding. Existing queue and stack-relock models do
not execute captured-frame physical copy/link coordinates. This component
targets that missing protocol, not a new generic lock hypothesis. The expected
benefit is checking a source candidate's layout/publication premises before
another full bootstrap/stress; no runtime speedup or repair is predicted.

## Source Operations

The model follows the current source-locked `mark_captured_continuation`,
`scan`'s sFRAME branch, and the kernel break handler's heap-frame branch:

- A shared MISC lock serializes two aliases capturing the same stack chain.
- Capture stores RA first at heap body[0], then copies payload slots in order.
- It restores the next stack frame's RA from the preceding frame's link before
  following that stack frame; its initial top word is deliberately not a label.
- Heap link coordinates are `body + fs - link`. Valid descriptors require
  `0 <= link < fs`, so a link write cannot alias body[0].
- Stack links retain raw forwarding references for the alias capture path.
- Private frame work publishes only after both frames and their chain exist.
- Scan converts raw heap frame links to typed links before mutator consumption.
- The heap break consumer reads RA at body[0] and follows the converted link.

References use the configured header bias: a raw heap reference names
`(bodyWord - 1) * 8`, not the body itself. Actual header macros are checked by
the companion configured-coordinate C fixture.

## Bounds And Controls

Two RETN frames, two root aliases, frame sizes 1..3 and every valid link index
are explored. Six controls omit next-stack-RA restoration, shift a link write
onto RA, publish an actually copied frame before its chain resolves, omit heap
RA, resume before scanning, or omit raw-to-typed link conversion. The early
publication control does not invent an unallocated frame in the queue.

This is an SC projection with stopped mutators, stable stack ownership and
valid incoming labels/descriptors. Heap copy is atomic while private; raw FIFO
mechanics, RETI layouts, arbitrary sizes, actual GC maps, moving payload roots,
weak memory and source participation are not proved here. Those conditions
must remain source requirements, not assumptions silently used as closure.

## Native Coordinate Check

The C fixture uses the producer's actual configured header and GNU GCC. It
checks alignment, RA/link slots, raw/typed reference bias, two-frame copy,
caller RA restoration and heap return coordinates for all 18,496 shape pairs
with sizes 1..16. It does not call the production collector or establish that
the real incident frame has a valid identity, extent or descriptor.

The initial C attempt was rejected before execution while the model recipe held
the source lease. A subsequent compile rejected expression operands passed to
the unparenthesized FP_STK macros. The fixture now uses pointer variables, like
the real source. Both DENY receipts are retained; no header macro or warning
policy was changed to admit the check.

The first abstract model result preceded correction of reference/header bias;
another result preceded the more faithful early-publication control. Both are
retained as historical observations, not the current source-bound model result.
No unchanged full stress is admitted and no sixth native gate closes.

## Checked Result

The header-biased, realistic-publication model completes in 47.012 whole
seconds: 1,080 distinct states, 1,764 generated, zero queued, safety and
weak-fair completion PASS. All six controls produce decoded counterexamples.
The configured-header C coordinate recipe passes all 18,496 shape pairs in
14.558 whole seconds. The portable result binds both sources and recipes under
`evidence/fixtures/darwin-btq-public-provenance/captured-frame-model.json`.

The registered heap-return view now includes this finite model context, while
retaining NATIVE_DENY and both source gaps. Withdrawing model context must not
remove the incident or close/reopen the source obligation. Real input frame
identity/extent, descriptor validity and RA provenance remain the next source
audit targets; no observed crash is assigned to a particular omitted operation.

## Unified Decoder Observation

The `darwin-frame-ra-boundary` diagnostic retains the preceding 23-file
candidate, changing only its Darwin GNU header. All seven RETN/RETI descriptor
entry macros check the necessary RETURN tag before dereferencing metadata.
The helper reports the expansion site and RA, then aborts on an incorrect tag;
it does not replace data, skip collector work or admit correctly tagged pointers.

Two-pass bootstrap passes (177.213 stage seconds, 259.962 child whole seconds).
The complete unchanged four-file compiled stress run remains DENY: three pass,
tfib aborts, zero timeouts. It takes 57.412 native-stage seconds, 66.275 child
whole seconds and 67.949 outer seconds. The failing group records
`FRAME-RA-BOUNDARY file=_kernel.c line=12002 ra=0x12800 tag=0`.
No capture/scan decoder reports an invalid tag in this execution. This is not
proof that the particular consumed frame passed through those checks, nor that
its header, allocation generation or lifetime was valid. There is no PID-bound
write-origin observation or established common cause with the previous image.

The result is retained under
`evidence/fixtures/darwin-frame-ra-boundary/native-observation.json`, and the
existing heap-return Evidence view includes `RA_TAG_REJECTED` without closing
its source requirement. The next discriminator is the purported frame's actual
header/type/extent at consumption versus its RA contents, not another
coordinate-model run, another ticket fence, or an unchanged stress retry.

## Stack Allocation Counterevidence

The heap-identity successor completes two-pass bootstrap (145.425 stage
seconds; 227.140 child whole seconds). Its full unchanged compiled stress
inventory remains DENY: three pass, tfib fails with SIGBUS, zero timeouts.
Elapsed time is 68.218 native-stage seconds, 77.243 child whole seconds and
78.961 outer seconds. Neither heap-identity nor RA diagnostic reports a hit.
This does not discharge either diagnostic premise.

The exact-image incident is now in `___stack_limit +140`. A debug mem.c object
compiled with the production command plus debug information has identical text
and named text relocations to production. DWARF maps the fault to mem.c:7720,
the NULL store in the new first break frame after selecting a reused section:
`stur xzr, [x0, #-0x10]`. The computed stack start and fault address both have
alignment remainder 1 modulo 8. Register x3, the just-loaded free-list successor,
equals the current processor SCM reference according to this configured
layout. It is not the original selected head identity. No corrupting writer,
child PID association or common cause with the RA incident is established.

Portable mapping and observation are under
`evidence/fixtures/darwin-heap-frame-identity/`. No raw personal report path is
required to read the retained source/word/instruction facts.

## Section Ownership Model

`models/gambit/stack_allocator_frame_lifetime.qnt` moves the source requirement
upstream of frame decoding: a per-processor linked section pool, overflow,
captured stack roots, first-break undo invalidation and two semispace epochs.
The model has four logical sections and a six-mutator-transition prefix; these
are finite bounds, not host concurrency settings. Allocation membership,
exclusive pool ownership, captured-root generations and raw stack-write
eligibility are checked together. Sharing a stack/heap section retains a
separate bounds-splitting assumption; root evacuation is atomic here. Fresh
section allocation assumes the existing ALLOC ownership protocol, not arbitrary
SCM/C metadata writes or compiler transformation correctness.

The final source-bound check exhausts 6,048 distinct / 11,546 generated states,
zero queued, with safety and weak-fair finite-prefix completion. Three omitted
protocol controls produce decoded counterexamples: missing ownership
invalidation, retaining the pool across GC, and resuming before root evacuation.
A separate two-state observation import rejects a non-section raw pool entry.
That action is explicitly not a legal source transition; it represents the
failed entry requirement, not an invented causal explanation. Whole model run
time is 41.528 seconds. No unchanged native retry is admitted from it.

Retained rejected attempts include two type errors, vacuous root insertion into
an empty map caught by missing negative controls, list trace non-admission, and
an unadmitted initial-state-only observation. The final model uses a source-like
linked pool and a total root map, with all four counterexamples admitted. The
earlier vacuous positive result is not current proof.

The existing heap-return Evidence view now has both conditional model contexts,
the earlier RA rejection and the new invalid allocator-entry observation.
Withdrawing both model contexts must retain the same open requirement and four
source gaps. The bounded legal pool transitions do not explain the native entry;
the next source audit must cover writes/aliases outside those transitions.
Neither adding a defensive abort nor repeating the existing invalidation and
pool-reset fixes would meet the required repair/native-qualification closure.

## Pool Metadata Separation Hypothesis

The source audit identifies three raw pool-link operations: stack pop, heap
pop and overflow-undo push. All use `msection.base[0]` in the diagnostic parent.
The Darwin GNU candidate `darwin-section-pool-metadata` moves that link into a
dedicated `msection.pool_next` field, retaining O(1) allocation order and the
original Linux branch. Its allocation extent is derived from `sizeof_msection`;
the full bootstrap must rebuild all layout consumers.

The existing QNT adds a separately labeled fault envelope, not a claimed source
transition: an escaped payload write alters the in-band pool link before pop.
The in-band version has a decoded three-state counterexample; the separated
metadata version exhausts three states successfully. The original legal
ownership/roots/semispace check still exhausts 6,048 states. All five negative
controls are admitted. Framework time is 76.915 seconds, with original budgets.
Results are bound in `evidence/fixtures/darwin-section-pool-metadata/model-observation.json`.

This is deliberately a falsifiable layout-repair hypothesis. Neither the
observed selected-head corruption nor the original writer is established by
the payload envelope. Separate metadata cannot repair an unrelated invalid
head pointer, out-of-bounds write into the C header, or stale frame ownership.
Bootstrap and all unchanged native stress files must determine whether it is
a usable repair; model PASS alone is not admission. Historical model bytes and
native DENYs remain retained, and no performance improvement is claimed yet.

### Audited Alternative Not Promoted

Overflow undo uses `set_stack_msection`, whereas fresh allocation can split
bounds through `set_stack_msection_possibly_sharing_with_heap`. That difference
alone is not a demonstrated repair opportunity. With the default allocator,
sharing is reached after assigned sections exhaust the arena. The following
overflow cannot use the pool while stack equals heap, and the approximate
free-space check triggers GC before retaining an undo link to that shared
section. GC resets the pool and first-break eligibility. A hypothetical undo
into a shared section therefore needs an actual legal producer path, not just
an isolated synthetic state. No setter substitution is included in this
candidate; custom allocators or a violated arena-accounting premise would need
separate evidence. This avoids adding another symptom-oriented change without
the missing source correspondence.

### Bootstrap Progress Contract

The first layout candidate attempt retains a TIMEOUT at 277.143 stage seconds
under the former 270-second wall-clock transport. Its log reaches second-pass
phase3 without build errors. The bootstrap capability had not passed a progress
callback to the already existing process transport. The corrected local call renews
the same window only at the fixed ordered phase boundaries; the running phase
is not counted as completed. Repeated markers, output volume and heartbeats do
not renew it. Final exit, build errors, exact two-per-phase inventory and source
closure remain independently required. Eight watchdog tests and thirty focused
watchdog/seed/custody tests pass. The timeout and verified interrupted-link
repair are retained; they are not native-correctness evidence.

The retained retry completes both bootstrap passes: 225.830 stage seconds,
217.925 make seconds, exit zero and exactly two occurrences of each phase.
It still used the earlier sealed implementation, not the corrected local
callback. Its final ASCENT review was not dispatched because the old whole-run
deadline had expired; the original whole-run DENY is retained unchanged.
The existing completed-producer interface revalidated only that final review
through the original sealed rules runner, within its original ten-second
review window. No native failure was recovered and no rebuild was performed.
The resulting producer is bound in
`evidence/research/current-source-full-bootstrap/darwin-section-pool-completed-producer.json`.
The updated framework is separately sealed as engine
`8ea18e4c20d4159c190dcd3b13633f9d0d1f3b8ab5fb493818b388f9c5eb9b3d`;
46 completed-producer/watchdog tests pass. Native stress consumes the completed
producer through that seal; bootstrap completion is not a stress pass.

### Native Falsification And Model Feedback

The complete unchanged compiled stress inventory now finishes: three pass,
tfib fails with signal 11 and none time out. Native stage time is 79.548
seconds; outer framework time is 96.883 seconds. The image-bound incident
still faults at `___stack_limit +140`, the first-break NULL store; its
computed stack start has low alignment bits 1. Child PID and the original
writer are not bound. Do not infer a common cause solely from this site.
`native-observation.json` retains the failure and denies an unchanged retry.

The existing model now separates the narrow payload-alias proof from a native
selected-section observation import. The latter has a two-state negative
control for `rawStackWriteSafe`; independent metadata does not imply that
the selected raw pointer is a section. The separation-only positive still
exhausts three states. The sealed recipe and ASCENT pass, 54.460 child whole
seconds, recorded in `selected-entry-model.json`; this is not source repair.
Earlier 6,048-state protocol results remain historical, not rerun evidence
for the new source bytes. Exact earlier bytes are retained in
`models/gambit/history/stack_allocator_metadata_envelope.qnt` and the
bootstrap's versioned input archive. Evidence binds the current native DENY.

The remaining source obligation is to identify how a non-section becomes the
selected head: audit the sole undo push, both pops, raw first-break restore,
GC reset and any writes crossing the processor-object/raw-memory boundary.
Do not replace that obligation with a defensive abort, repeated invalidation,
discarded pool entries or a new layout-only experiment.
