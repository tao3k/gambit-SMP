# Root Interpretation: Publication, Reachability And Lifetime

## Missing Composition, Not A New Collector

The existing [handoff](stage-one-handoff-recipe.md),
[retained-reader contract](reader-resumption-contract.md) and
[VM-cell contract](vm-cell-ownership-contract.md) require actual generated root
maps. The existing nested FFI model checks root ownership/reload and error exit;
the VM-reader and callback-retirement models check different admission/drain
protocols. None by itself says that the interpretation data used by a still-live
Scheme frame, captured continuation or admitted scanner remains available from
the correct producer. This adds that condition to the existing FFI model rather
than a second root stack, loader, collector or generic retirement engine.

## Pinned Source Correspondence

Vendor revisions remain Gambit `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`,
Chez `41d5ffca7a07cbfc8807e719dedcc70ed74811cd` and OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`. Baseline lines are not claims
about the native owner's newer overlay or its qualification.

| Source | Actual mechanism | Transfer premise / limitation |
| --- | --- | --- |
| Gambit `include/gambit.h.in:9301-9318` | RETI/RETN extract frame size, link and inline/out-of-line GC maps from a label descriptor. | Storage for a saved value is insufficient without the right descriptor and its live-slot interpretation. Matching layout size alone is not matching producer/liveness. |
| Gambit `lib/mem.c:3900-3968,4106-4140` | Native and heap-frame scanning resolve a saved RA to interpretation data, then call `mark_frame`. Captured continuations are reached after the current stack walk. | Native-frame return does not end all Scheme interpretation dependencies. Actually enumerated frames, valid RAs and complete maps must match generated code and effective configuration. |
| Gambit `lib/os_dyn.c:408-454,1080-1087` | Global dynamic-module cleanup unloads loader handles unless disabled; the source documents a profiling-exit constraint. | Loader storage and runtime/host callbacks can outlive a local Scheme call. This is not a supported hot-unload API or proof that all native cleanup paths are drained. Preserve the supported global cleanup contract. |
| OCaml `runtime/frame_descriptors.c:28-62,173-193,284-320,323-359` | Descriptor removal is queued as zombies; actual descriptor-table changes/cleanup occur under the declared STW protocol. Registration runs on all domains. The removal mutex cannot release the domain lock at some callers. | Separate withdrawal requests, scanner exclusion and physical interpretation-storage lifetime. Copying its mutex or STW call is not a Gambit solution: Gambit has generated label descriptors, not this descriptor hash-table ABI. |
| OCaml `runtime/frame_descriptors.c:251-268` | The copy-and-register variant stores a copied frametable with its list node; freeing that node frees the copy too. | Ownership depends on which registration variant actually supplied storage. A deferred list-node free is not a universal guarantee for external code/table memory or live frames. |
| Chez `s/mkgc.ss:245-270,970-991` | Generated tracing handles a continuation's return address and stack, and includes a thread stack's RA when copying it. | Learn that control-state interpretation belongs to the traced graph, not merely the current OS/C activation. Do not transplant Chez's native-code representation or claim all tracing modes from these excerpts. |
| Existing `vm_list_reader_retirement.qnt` and `callback_retirement_composition.qnt` | Admitted readers must drain before storage release; native return-origin frames have separate lifetime obligations. | Reuse those contracts. Neither VM reader drainage nor native callback count alone enumerates every retained Scheme continuation or descriptor consumer. |

The root location, its current relocated value, its map/RA producer and the
storage containing that interpretation are four different facts. A hash proves
input identity, not that a generated live-slot map is complete. A native count
of zero proves neither absence of reachable Scheme continuations nor absence
of a scanner that already resolved metadata.

## Existing-Model Join And Assumptions

### Concrete Map Producer And Scanner

The pinned baseline contains a concrete producer/consumer chain, not an
universal C-local root finder:

| Boundary | Pinned source | Obligation for the implementation Recipe |
| --- | --- | --- |
| Live variables -> slot order | Gambit `gsc/_t-c-2.scm:825-904` | Normal/task returns use live frame slots. Internal returns additionally account for saved GVM registers and the return slot, with aligned/reserved frame layout. Audit the actual return kind, not just a label with the right version. |
| Slot predicates -> bits/chunks | Gambit `gsc/_t-c-3.scm:471-520` | The map builder sets bit `i` from the supplied liveness predicate; chunk emission uses actual frame size, including internal-frame expansion. This does not prove the upstream liveness analysis complete. |
| Label -> inline/out-of-line descriptor | Gambit `gsc/_t-c-1.scm:1947-2012` | Frame size, link, return kind and GC map travel together. Out-of-line descriptors emit the chunk sequence; matching structure size alone is insufficient. |
| Descriptor -> visited slots | Gambit `lib/mem.c:3817-3896` | `mark_frame` groups set bits into `mark_array` calls and advances chunks at word boundaries. A correctly owned but unmapped live slot is not repaired by descriptor retention. |
| Registered C roots -> relocated values | Chez `c/alloc.c:97-103`, `c/gc.c:1307-1311` | Registration records slot addresses; the collector explicitly relocates those slots. This is process-global protection, not a nestable root-frame ABI or a map for arbitrary C locals. |

For each newly introduced safepoint, the handoff must enumerate the actual
live movable inputs and retained values, then show their storage, bit positions,
return-kind/RA correspondence, scanner coverage and reload. Cover inline and
out-of-line maps and internal saved-register layouts in the fully rebuilt
configuration. Ordinary dead slots and alignment padding are not automatically
roots. Do not replace completeness with a full-file hash or mark every raw word
as a Scheme object. The finite model checks a missing inner root despite correct
producer/readiness/lifetime; it does not verify these physical encodings.

### Publication Edges Have A Payload And A Scope

The following distinctions constrain the Stage-One refactor; they do not
attribute a native failure or prescribe a new atomic/lock:

| Observation | What it establishes | What it cannot establish by itself |
| --- | --- | --- |
| Gambit slot-count release and matching GC acquires, as audited in the [publication ledger](stage-one-closure-audit.md#reader-and-publication-ledger) | Earlier initialized per-VM slot coverage carried by that publication history. | Later `prm` initialization, a symbol binding written afterwards, another writer's payload without a connecting edge, or safe reclamation. |
| Generated static descriptor contents | The map is emitted together with its label descriptor under the effective C backend configuration. | A new mutable runtime map needing its own atomics is not implied. Reachability through loader/fixup and supported execution entry still need their actual publication/ownership chain. |
| OCaml `runtime/globroots.c:64-87,150-178,197-235` | Root-list insertion/deletion uses `roots_mutex`; generational mutation changes root classification before assigning `*r`; dynamic-root scanning snapshots a list head under the mutex and traverses outside it. | That mutex does not enclose the final root-value write. Copying it is not proof of arbitrary simultaneous mutation/scanning, immutable Gambit links, or external module-storage lifetime. The reference runtime's domain/collector participation and list-storage assumptions remain required. |
| Chez `c/intern.c:155-228`, `c/gc.c:120-135` | Interner operations have a mutator-side owned interval; parallel sweep explicitly excludes `tc_mutex` acquisition and cannot assume a Scheme thread's current context. | Holding the interner lock while invoking a collector or transplanting a mutator's ownership into a GC worker is not licensed. Collector-phase ownership remains a separate premise. |

For every exposed field, record the initializing writer, the exact publication
event, the reader that observes that event, mutations allowed afterwards and
the condition ending its lifetime. A C release/acquire argument requires a
matching synchronization history for that payload; source order or acquire on
an unrelated field is not such a history. A lock argument requires the actual
reader to share the interval, or a separately established snapshot/phase
protocol. Actual C data-race freedom and compiler mappings remain source/native
obligations, not properties proved by these sequential finite histories.

### Whole-Package Handoff Boundary

The smallest first-stage package remains leaf reservation/interner plus every
enabled record/reader companion in the [closure audit](stage-one-closure-audit.md#small-refactor-packages-and-real-acceptance).
Its handoff has three jointly required witnesses: complete roots at each
collecting boundary, payload-specific publication/reader correspondence, and
live interpretation storage through every admitted consumer. None substitutes
for the others. Pure noncollecting leaf code does not gain a safepoint by this
review. A collecting/reentrant path must use the supported rooted execution
boundary, revalidate derived state after waiting and deliver outside ownership.
Dynamic unloading/restart, new foreign-entry abilities or a new collector
protocol remain separate Stage-Two milestones; they are not hidden first-stage
preconditions. These are design obligations for the implementation owner, not
new passed native requirements or a reason to rerun its bootstrap here.

`ffi_gc_frame_protocol.qnt` gains a descriptor-lifetime projection that reuses
the existing nested enter/collect/error/exit/reload transitions. It retains a
Scheme interpretation consumer inside the nested invocation, returns through
the existing normal/error exits, then permits a metadata scanner to resolve the
descriptor before the retained consumer is discharged. Closing future admission
does not erase that already-admitted scanner or retained consumer.

Controls separately omit initialized map publication, substitute another map
producer, reclaim after native frames drain while a Scheme consumer survives,
reclaim while an admitted metadata scan is active, or omit an inner live root
from an otherwise ready, correctly sourced map. Correct safety requires
the right available interpretation for every remaining consumer. Completion is
conditional on the finite modeled exits, scan and explicit consumer discharge;
it is not a promise that arbitrary user code releases a retained continuation.

The fields are logical witnesses, not new per-call/module counters or a request
to register/unregister every Gambit frame. Atomic map publication, actually
enumerated consumers, valid control origins and fair completing actions are
premises. No C weak-memory, physical root-map completeness, concurrent moving
collector, arbitrary foreign continuation return, hot-unload/restart or native
latency theorem follows. The model scans interpretation metadata; it does not
authorize concurrent Scheme mutation during an actual GC scan.

Lean's `descriptorRetirementExcludesConsumers` states the conditional closure:
if every live consumer's interpretation dependency is available, reclaimed
interpretation data has no live dependent consumer. The source must establish
the complete consumer census, dependency edges and true availability. This
does not turn an absent/unregistered consumer into proof that none exists.
`generatedMapRelocation` reuses `bindingCoverageComposes`: complete coverage of
live slots plus correct relocation of each mapped slot entails relocation of
the live slots, for arbitrary slot/value types. Both inputs remain actual
compiler/scanner obligations. Equal producer identities alone do not supply
coverage; a deliberately false control is retained for that conflation.

## Stage-One Recipe And Native Handoff

- Bind current compiler, runtime, headers, effective macros and actual generated
  C/label/root maps as one producer identity. Check concrete live inputs,
  accumulator/callback captures, RA, spill/reload and valid normal/error return
  paths; source-lock hashes alone do not prove this semantic correspondence.
- Preserve the existing lifetime of generated module/descriptor storage through
  every valid frame, captured continuation and admitted scanner. Keep static
  data static and module metadata with its supported module/runtime lifetime.
  Stage One does not add hot unload, a frametable registry or an OCaml barrier.
- Account for the actual global cleanup order and enabled loader/profiling/host
  callbacks before release. Do not infer a process-wide release condition from
  one VM's native call count, a detached VM-list entry or an unlinked table head.
  Reuse existing join/retention/root-transfer and lifecycle repairs, not cache
  cleanup or a new blanket free-and-retry path.
- On the native owner's fully rebuilt candidate, exercise generated stack and
  heap/continuation frames with distinct live root identities, forced collection,
  caught errors and supported retained resumption. Independently verify values,
  root relocation and producer/map identity. Teardown tests use supported exits,
  preserve pending-join failures and must not create unsupported live hot unload.
- Keep resolved Scheme/global accesses and ordinary allocation on their existing
  fast paths. Retaining already-required interpretation storage is not evidence
  of a new leak; actual lifetime/retained bytes and multicore costs need native
  observation. No extra global lock or per-root registry lookup is selected.

The first-stage research package is a linked conditional Recipe, not complete
source/native closure. General unload/restart, new collector barriers and new
foreign entry abilities remain separate Experimental milestones. No runtime
source, native fixture, bootstrap/stress or native checkpoint is changed here.
