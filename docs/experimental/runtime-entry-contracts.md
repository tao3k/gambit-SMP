# Experimental Runtime Metadata And Host Entry Contracts

## Status And Reproducible Inputs

This is an Experimental contract audit, not a selected runtime repair. It
preserves the C backend, supported FFI/continuation semantics and heap identities.
The repaired runtime, generated C and extensions use one revision/configuration
and a complete rebuild; defective SMP protocols and mixed-binary compatibility
are not preservation requirements. Internal ABI changes require coordinated
producer changes rather than a fallback to old inline instructions.
It neither advances native gates nor changes the other qualification lane.
The two [implementation horizons](smp-design-foundations.md)
remain distinct. An abstract protocol below is not a claim that C implements it.

Gambit baseline is `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Current overlay authority is
`evidence/research/processor-interrupt-collective-wait/source.lock.json`
(SHA-256 `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`)
and its declared cumulative patch. Candidate paths/lines below refer to that
overlay, never a required cache checkout. Chez and OCaml gitlinks remain
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd` and
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91` respectively.

## Actual Entries And Concurrency Premises

| Entry | Source chain | Ownership already supplied | Concurrency classification / open premise |
| --- | --- | --- | --- |
| Scheme `string->symbol` | Baseline `lib/gambit/symkey/symkey.scm:55-62`; candidate `_kernel.scm:3801-3825`; `mem.c:2380-2405` | Caller is executing on its processor; CFUN saves/restores execution state. | Direct runtime call, not a processor-zero relay. Once the configured SMP scheduler executes Scheme on two processors, no caller-exclusive lock is visible in this chain. Read/miss/create and permanent allocation can overlap. This is source reachability, not a reproduced race. |
| New global variable | Candidate `_kernel.scm:3867-3874`; `mem.c:1611-1646`; baseline `_eval.scm:524`, `_module.scm:115` | `___glo_list_add` serializes multi-VM list insertion and prepares per-VM slot storage. | The outer absence check, permanent allocation and symbol binding are outside that insertion lock. Concurrent dynamic evaluator/module work needs a separately established entry contract; do not label all eval/load thread-safe by inference. |
| Runtime-created processor | Candidate `setup.c:979-1010`, `_thread.scm:3288-3345` | Runtime binds the worker's pstate, joins the initiating collective and runs the thunk. | Distinct processors can execute in one VM; there is no general interpreter-wide lock demonstrated here. Disabling Scheme interrupts is not OS-thread exclusion. |
| Independent VM owner | `models/gambit/native/independent_threaded_vms_public.scm:22-50` | Fixture constructs its own VM/P0, initializes the OS-thread record, binds it, runs, cleans up and clears TLS. | Explicit-owner embedding experiment, not arbitrary attachment to an existing processor. VM-local value cells do not make runtime-global intern tables or permanent allocation VM-local. Existing fixture success is not an interning-contention test. |
| Generated C-to-Scheme callback | Candidate header `10112-10128`, `14723-14777`; `setup.c:3696-3845` | Existing pstate, marker/return origin, admission and per-frame lifetime accounting. | Valid existing caller ownership is required. Admission protects lifetime, not exclusive use of processor registers/stack/catcher. Arbitrary external-thread auto-attachment and cross-VM nested switching are not established supported contracts. |
| Global setup/cleanup | Candidate `setup.c:5494-5545`, `7026-7240` | Host serialization is an explicit lifecycle precondition. | Multi-VM parallel execution does not authorize overlapping global setup/cleanup. Global restart also has separate static-linker generation obligations. |
| Dynamic object load | Candidate `setup.c:2488-2517`; baseline `_eval.scm:5569`, `_module.scm:562-575`; candidate `_kernel.scm:5230-5382` | Object-loader and module-stage bookkeeping exist. | No end-to-end parallel initialization contract established. `##register-module-descr!` explicitly has an atomicity TODO. Loader-internal locking does not by itself serialize fixups or user initialization. |

The baseline manual `doc/gambit.txi:9843-9847` still describes single-thread
execution. Its pthread example explicitly serializes Scheme calls in the host.
Those are historical constraints, not evidence that the current SMP worker
entry is serialized or that arbitrary host threads work in threaded-VM builds.

## Shared State Boundaries

| Resource | Positive existing guarantee | Obligation not discharged by that guarantee |
| --- | --- | --- |
| Interned identity and names | Permanent lifetime, shared runtime table. | Whole find/create/publish uniqueness; synchronized readers during rehash. Rehash rewrites existing NEXT links, so retaining the old table does not provide a snapshot. |
| Permanent allocator | `___alloc_scmobj(NULL, ...)` uses runtime-global permanent storage, not a VM's moving allocation cursor. | Reservation must not return overlapping intervals; psection linking, growth, overflow and cleanup need their own complete ownership scope. A lock only around table insertion cannot establish this. |
| VM global value cells | Stable segments are prepared under `vm_list_mut` and published with release operations. | Exactly one global-variable binding per symbol; read-side acquire/cell rooting and full GC correspondence remain separate. |
| Callback frame admission | Acquired frames prevent retirement; marker failure and unwind have explicit cleanup. | Owning a lifetime lease does not establish GC registration or exclusive processor execution. Root publication does not itself promise GC service during arbitrary C waits. |

Two same-name callers can both observe absence before either binds a result.
Two distinct-name callers can still collide on the permanent allocation cursor.
These are different obligations; serializing a VM-local table would not protect
a runtime-global allocator used by other VMs. No native failure is attributed
to either schedule without an exact-source discriminating test.

## Reference Mechanisms And Transfer Conditions

Chez `c/intern.c:155-304` holds `tc_mutex` across lookup/creation/insertion;
`S_intern4` explicitly requires an already-held mutex. `c/types.h:363-421`
specifies active-thread transitions and tc-before-allocation mutex ordering.
Oblist resize is called in the collector (`c/gc.c:1794`), not established as
an arbitrary concurrent mutator operation. Do not move Chez's lock boundary
into Gambit without reconciling GC progress and root lifetime.

Chez `c/thread.c:191-244` distinguishes new activation, reactivation and
already-active entry, returning destroy/deactivate/noop restoration modes in
the normal branch. The WRITE_XOR_EXECUTE_CODE branch differs.
`c/ffi.c:617-622,794-797` applies these only when the callback's activation
adjustment option is enabled. Automatic activation is not universal.

OCaml `runtime/callback.c:387-431` combines table locking with generational
global-root registration/update. It reacquires the string address after a
potentially moving wait. `runtime/caml/platform.h:80-109` makes lock/domain/STW
compatibility explicit. A stable returned C slot is not permission to access
the pointed-to OCaml object without runtime ownership.

OCaml `otherlibs/systhreads/caml/threads.h:31-79` distinguishes foreign-thread
registration from domain-lock acquisition. `st_stubs.c:833-919` validates a
running domain's identity, registers a thread, releases execution ownership
before returning, and detaches through the matching contract. This is not
per-process serialization and not a model for treating every TLS store as
attachment. Existing registration restrictions are part of the reference.

## Experimental Model Index And Reuse

Executable QNT assets stay in the existing `models/gambit` root required by the
shared verifier; this Experimental index/manifest organizes them without a
second runner or a cache-dependent model tree.

| Obligation | Asset | Coverage / deliberate exclusions |
| --- | --- | --- |
| Whole lookup/create/publish | Existing `serial_number_transaction.qnt` | Reused compound-transaction counterexample and protocol. This is serial-number identity, not an executable symbol interner or a rehash/reader proof. No duplicate transaction model is introduced. |
| Disjoint allocation and initialized publication | New `runtime_metadata_allocation.qnt` | Two requests, sizes 1/2, split-reservation and early-publication controls. Atomic reservation is the required abstract history, not a selected lock/CAS implementation. No alignment, psection allocation/linking, allocation failure, overflow, weak memory or actual rehash. |
| Host execution versus lifetime authority | New `runtime_host_entry.qnt` | Two distinct host owners, same/different processor, registered/unregistered entries, restoration and drain. Lease-only, missing-registration and lost-binding controls. No automatic attachment implementation, nested native unwind or GC algorithm. Rejection is an abstract contract option, not a public-ABI change. |
| Unbounded arithmetic/ownership consequences | `lean/RuntimeEntryContracts.lean` | Sequential reservations are pairwise disjoint for arbitrary finite size lists; one processor-owner function prevents conflicting execution owners; lifetime leases alone do not. Reuses existing nested-exit accounting. No source refinement, linearizability proof or throughput claim. |
| FFI/GC and retirement | Existing `ffi_gc_frame_protocol.qnt`, `foreign_call_admission.qnt`, `nested_foreign_unwind.qnt`, `callback_retirement_composition.qnt` | Reuse root reload, admission, unwind and retention boundaries. They do not imply a supported arbitrary-host-thread attachment protocol. |
| Module/restart | Existing `module_fixup_publication.qnt`, `global_linker_generation.qnt` | Explicit exclusive-claim refinement and serialized-generation assumptions remain open. Do not duplicate or relabel them as implemented repairs. |

QNT positives require both safety and weak-fair finite completion. Lean negative
controls reject overlapping reservations and incompatible same-processor owners
despite both holding leases. Counterexamples describe missing contracts, not
asserted diagnoses. Finite worker counts are exploration bounds, never host
CPU settings. Python only invokes the existing checkers and records outcomes.

## Stage-One Recipe Boundaries

| Candidate scope | Compatibility / expected benefit | Prerequisite and actual acceptance |
| --- | --- | --- |
| Whole shared-metadata slow operation | Preserve interned identity, VM value isolation, C ABI and allocation fast paths unrelated to metadata. Correctness benefit only; no timing estimate. | Establish eligible callers and all readers/writers first. Same-name identity, distinct-name allocation, resize/read overlap, cross-VM callers, OOM/retry and GC-compatible waiting need exact-source native observations. No lock policy selected. |
| Existing owned callback entry/exit | Preserve current processor owner and return destination; consolidate a missing contract only if demonstrated in that supported path. | Nested same-owner callbacks, typed error, marker allocation failure, nonlocal unwind, resize/retirement overlap and original pressure tests. Lifetime counting alone is not acceptance. |

These are bounded review scopes, not approved patches or complete Recipes.
Their cost includes caller/reader inventory, source refinement and affected
native qualification. No speedup or low validation cost is assumed merely
because a code edit might be small. Existing successful bootstrap stages are
reusable only under the unchanged producer/checkpoint dependency contract.

## Stage-Two Experimental Milestones

Arbitrary external-thread attach/detach; cross-VM nested entry and return-owner
restoration; restartable global runtime/module generations; parallel module
initialization/reentrant initialization; and scalable shared-metadata read/write
protocols each need explicit semantic/ABI decisions. They are not prerequisites
silently imposed on existing valid callers. No shared-nothing migration,
per-symbol TLS copy, universal runtime lock or new collector is selected.

## Qualification Commands And Outstanding Evidence

Use the existing driver with
`--manifest evidence/scenarios/parallel-gc/runtime-entry.manifest.json`.
Store the `verify --out` result in the configured cache. Run the focused
`test_runtime_entry_formal.py` and `test_parallel_gc_evidence_scenario.py`
consumers for guarded Lean proofs and the real Scheme DSL relations.
The original serial-number model is independently reusable through
`check --case serial_number_transaction`; its result does not prove interning.

Open: current-profile native interning overlap, all permanent allocation
callers, reader/rehash compatibility, source-to-abstract reservation refinement,
foreign attachment support, C memory ordering and complete native acceptance.
Model completion must not clear these unknowns or award an SMP gate.
