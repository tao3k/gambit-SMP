# Stage-One Shared Metadata Implementation Milestone

## One Candidate, One Admission

This is the implementation breakdown of the selected
[complete package](stage-one-integration.md), not a second protocol or a native
qualification receipt. The [composition results](stage-one-integration-validation.md)
support conditional design properties; they do not establish C refinement,
native correctness or speedup. All three registered native obligations remain
open. This milestone awards none of the other lane's native progress.

The deliverable is **one coordinated repaired source candidate**, using one
effective build configuration and a complete matched rebuild of the runtime,
generated C, libraries and extensions. Internal work units below may be reviewed
separately, but no intermediate subset is admitted as the complete SMP repair.
There is no defective-old-SMP fallback or mixed-version extension path.

Preserve portable Scheme-to-C compilation, proper tail calls, supported
continuation and nested-FFI behavior, canonical interned identity, VM-local
values and existing ordinary allocation/resolved-global fast paths. Do not
replace the collector, serialize Scheme execution, change TLS or add a Python
workflow. Internal ABI/layout changes are allowed only as part of this rebuilt
candidate, not as an excuse to weaken supported public semantics.

## Source Authority And Handoff

The research source is Gambit
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` with the existing
[overlay source lock](../../evidence/research/processor-interrupt-collective-wait/source.lock.json).
Chez `41d5ffca7a07cbfc8807e719dedcc70ed74811cd` and OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91` are reference mechanisms, not
drop-in runtime implementations. Their precise transfers and exclusions are in
the integration design and [compatibility audit](c-backend-compatibility.md).

Before implementation, select the native owner's then-current repaired source
and record its differences from this research lock through the existing source
and evidence contracts. Preserve already-correct constructor catchup and
lifecycle fixes; do not replace them with this older research overlay. Recheck
affected premises if those differences touch the boundaries below. The present
publication does not mutate that owner's source, patches, fixture, checkpoint,
budget or native receipts, and does not start a competing build.

## Coordinated Source Work Units

| Work unit | Source and implementation responsibility | Required join before admission |
| --- | --- | --- |
| Resource lifetime and permanent reservation | `lib/mem.c`, `lib/setup.c` and private state/header declarations: enroll P/M with exact partial-init ownership; protect permanent cursor, alignment, refill and psection linking for every caller, including NULL permanent allocation. | Raw allocation remains noncollecting; failure unwinds only acquired resources and preserves the original error. No rewind across another reservation; no new guard on movable allocation. |
| Canonical metadata and global publication | Interner/global helpers in `lib/mem.c` and private `lib/mem.h`: central M transaction; existing V membership protocol; private already-owned helpers; nesting V -> M -> P. On binding miss, recheck before private record allocation, initialize before linking, prepare active-VM slots, then publish count and binding. | Same-name identity, reverse/list membership, active-VM root coverage and binding/index correspondence agree. Constructor catchup/link/enable stays indivisible under V. Optional rehash OOM after insertion keeps the successful insertion. |
| Discovery and generated-code contract | `include/gambit.h.in`, affected generator inputs and generated runtime/module C: paired binding and permanent-head publication/observation; audit all enabled direct readers. | No unsynchronized live plain access mixes with the publication accessors. Stable resolved `glotbl` value access stays direct. Actual root/map/reload/RA behavior is checked if any new service boundary is introduced. |
| Reader capture and delivery | `lib/_kernel.scm`, `lib/os_tty.c`, `lib/_geiser/_geiser.scm`: keep reviewed leaf TTY traversal distinct from allocating capture/revalidation and unlocked Scheme delivery. | Capacity and relocated roots remain valid; callbacks, exceptions and continuation exits do not retain M/P. Capture certifies membership, not mutable global values or later insertions. |
| Matched artifact and native acceptance | Existing Recipe, source lock, Session and checkpoint interfaces; native tests registered with the existing Scheme DSL. | All preceding joins hold for the same repaired source/configuration and rebuilt artifacts. Historical failures and unchanged source-bound stage receipts remain distinguishable; no new execution engine or progress counter. |

Lifetime support precedes use of P/M. The transaction, discovery and reader
changes must be integrated together before enabling the repaired protocol.
Native acceptance starts only after that integrated candidate is frozen. These
dependencies organize implementation; they are not instructions for an agent's
investigation order or new hard-coded framework stages.

## Cross-Cutting Review Conditions

- **Actual waits:** nonrecursive acquire/release mutexes are the proposed P/M
  primitive, not spin/ticket locks around variable-latency raw allocation.
  Every owner must finish without Scheme service, a collecting allocator,
  callbacks or a reverse lock acquisition. Raw OS allocation and fair scheduling
  remain progress assumptions, not bounded-latency guarantees. If a required
  caller violates this envelope, revise its split/root/reload protocol and model
  before admitting code; do not insert collective service while holding P/M/V.
- **Entry and exits:** retain supported processor ownership and traced activation
  roots. NULL allocation class is not host attachment. Fixed save slots and raw
  C backups cannot implement nested traced roots. Supported normal/error/nonlocal
  exits must discharge the resources they own; a return-site unlock alone does
  not establish this for continuation or foreign unwinding.
- **Callbacks and raw readers:** review actual effects, not a function-pointer
  signature. Ordinary nested FFI outside guarded leaf intervals remains valid.
  V/queue-owned teardown reentry and escaped mutable raw table iteration are not
  newly guaranteed. If a required supported caller relies on them, its contract
  must be resolved within the candidate, not silently prohibited. TTY's leaf
  proof does not justify running a generic external visitor under M; preserve
  supported sequential behavior and explicitly qualify concurrent capability
  and OOM reporting at that API boundary.
- **Lifecycle and profiles:** distinguish failed private initialization from
  restart after published teardown. Drain users before reclamation; never use
  normal admitted cleanup on an unadmitted partial prefix. Normalize POSIX/Windows
  initializer results and check actual capability macros, including multiple
  single-threaded VMs. Native GNU atomic requirements of the existing registry
  are not satisfied by a silently sequential configure fallback.

## Existing Models And Source Joins

| Existing asset | Implementation obligation it informs | Boundary still requiring evidence |
| --- | --- | --- |
| `runtime_metadata_allocation.qnt` | Reservation, topology, record publication, V/M/P order and private-prefix unwind profiles. | Profiles are separate projections; actual weak memory, allocator/OS behavior and full startup cleanup are not proved. |
| `runtime_metadata_vm_publication.qnt` importing the constructor and metadata models | Binding -> registered index -> current-VM roots, precommit abort and constructor interleavings. | Finite imported transition composition is not many-writer C/GC/FFI refinement. |
| `runtime_host_entry.qnt`, `predicate_lock_retry_rooting.qnt` | Execution ownership, restoration and broad service effects rather than GC-only assumptions. | Native entry, waiting and exception paths must establish the assumed ownership/effect facts. |
| `gc_table_iteration.qnt`, `ffi_gc_frame_protocol.qnt`, `nested_foreign_unwind.qnt` | Capture capacity/root reload, unlocked delivery, nested traced ownership and exit origins. | Real generated maps and continuation/foreign exits need source and native correspondence. |
| `RuntimeEntryContracts.lean` and false-claim controls | Arbitrary-set binding coverage bridge, reservation arithmetic, ownership and order consequences. | Conditional premises must hold in the implemented source; Lean is not a proof of C atomics or the collector. |
| Existing module-fixup and linker-generation models | Preserve module readiness and generation/lifetime boundaries while metadata changes. | Global slot readiness is not initialized module payload or permission for concurrent loading/restart. |

Do not add another model for an already-covered local property. Extend an
existing projection or the composition only when the frozen implementation
exposes a missing interaction; retain the motivating source trace and negative
control. Model and source identities remain bound through existing evidence.

## Real Acceptance Checklist

- [ ] Freeze one integrated repaired source/configuration; enumerate enabled
  C/startup/Scheme/generated readers and writers, including required debug,
  low-level and C++ branches. Bind source, compiler and effective macro identity.
- [ ] Establish owned P/M/V lifetime, full caller coverage and actual wait/exit
  effects. Review the lock graph including callback and collective-service edges;
  an absent observed deadlock is not a lock-order proof.
- [ ] Exercise independent and same-name permanent allocations, collisions and
  rehash, global creation overlapping VM construction and GC, acquire-visible
  binding reads, leaf TTY and allocating Geiser/fold capture. Check identity,
  initialized records, per-VM slot coverage and no lost/duplicate membership.
- [ ] Exercise supported normal/error/nested-FFI/continuation exits and available
  allocation/init failure cutpoints. Retain errors and partial results with their
  identities. Missing supported fault coverage is untested, not passed; do not
  introduce unapproved injection hooks to manufacture coverage.
- [ ] Cleanly regenerate affected C and completely rebuild runtime, libraries,
  modules and extensions for each admitted profile. Run the required bootstrap,
  original interpreted/compiled stresses, GSI/GSC and Gerbil/FFI acceptance on
  those matched artifacts. No bootstrap is launched by this design publication;
  the future repaired candidate cannot inherit an older producer's result.
- [ ] Measure the existing sequential and parallel performance workloads with
  host-adaptive concurrency. Keep existing gates independent of watchdogs;
  no disabled SMP, blanket execution serialization or relaxed threshold.
  Only genuine target progress, not heartbeat output or model transitions,
  extends a no-progress watchdog. Preserve every failed or timed-out run.
- [ ] Submit a source/model/native/performance matrix through the existing DSL.
  Resume unchanged applicable stages through the existing checkpoint; cache
  deletion does not erase historical evidence, and evidence retention does not
  certify a stale artifact. Admit the package only after every required row passes.

Implementation and all native checklist rows are **pending**, not failed or
passed by this research review. No aggregate SMP completion count is changed.

## Later Experimental Milestones

Concurrent/generational collection, a new root-frame ABI, lock-free reclamation,
arbitrary external-thread attachment, concurrent module initialization, general
raw-view snapshots and post-teardown runtime restart require their own explicit
design/compatibility decisions. They are not hidden Stage-One prerequisites or
reasons to discard Gambit's C backend, continuations or FFI. A required existing
supported behavior discovered during implementation must instead be reconciled
before this milestone is admitted; it cannot be relabeled as future work merely
to obtain a green result.
