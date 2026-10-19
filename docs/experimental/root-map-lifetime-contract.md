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

`ffi_gc_frame_protocol.qnt` gains a descriptor-lifetime projection that reuses
the existing nested enter/collect/error/exit/reload transitions. It retains a
Scheme interpretation consumer inside the nested invocation, returns through
the existing normal/error exits, then permits a metadata scanner to resolve the
descriptor before the retained consumer is discharged. Closing future admission
does not erase that already-admitted scanner or retained consumer.

Controls separately omit initialized map publication, substitute another map
producer, reclaim after native frames drain while a Scheme consumer survives,
or reclaim while an admitted metadata scan is active. Correct safety requires
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
