# Shared Metadata Transactions And Callback Delivery

## Decision And Authority

This is a Stage-One design for discussion, not an implemented runtime patch.
It extends the [caller audit](runtime-entry-callers.md) and existing models;
it does not select a mutex, modify TLS, serialize VM execution, or qualify a
native candidate. Preserve the C backend, supported public FFI/continuation
semantics, interned identity and per-VM global values. Require one repaired
revision/effective configuration and complete matched rebuild; do not preserve
defective old SMP mechanisms or add a mixed-binary fallback. Coordinated
internal generated/runtime ABI changes are permitted. No performance improvement
is claimed.

Gambit baseline is `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the
[source lock](../../evidence/research/processor-interrupt-collective-wait/source.lock.json)
and its cumulative patch. The lock digest is
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`;
candidate line references below refer to that overlay, not a cache directory.
Chez is `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`, OCaml is
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`, both under `vendor/`.

## Complete Operations, Not Individual Stores

| Operation | Protected logical unit and publication | Excluded inference |
| --- | --- | --- |
| Exact-name intern | Read current table/bucket, compare, create fully initialized permanent name/object, recheck if preparation released protection, select one canonical object, insert/count, optionally grow and relink. Duplicate preparation must never publish two identities. | A lock on insertion alone does not protect lookup/create or old readers during rehash. |
| Permanent reservation | Reserve a disjoint interval and publish a fully linked psection before another allocator uses it. All users of the shared arena need compatible participation, including descriptors outside interning. | Thread-safe malloc, per-VM execution ownership and an intern-only guard do not protect the shared cursor/list. |
| New global binding | Check symbol binding, prepare global record and required per-VM cells/segments, link/register, then expose the binding under one compatible operation contract. | The existing multi-VM list lock neither encloses the outer operation nor exists in every single-VM threaded profile. |
| Exact lookup | Use one stable topology from bucket selection through the final link read, or an alternative validated history with retry. | Stable permanent addresses and a retained table head do not preserve mutated links. |
| Object-to-global reverse lookup | Candidate `mem.c:1506-1608` searches global lists/value cells and then the symbol table; `_kernel.scm:3887-3893` exposes the entry. Include both traversals and the applicable VM cell ownership. | Protecting only name lookup leaves these readers outside the proposed transaction; reachability does not establish concurrent value mutation is supported. |
| Enumeration | Capture a specified membership under compatible topology protection, release protection, then invoke callbacks over that capture. | Snapshot membership does not freeze values or callback effects and does not include every later insertion. |

The public runtime path is distinct from startup: static initialization runs
before VM/P0 binding under exclusive host lifecycle setup. A private operation
contract must distinguish **startup-exclusive** from **valid active mutator**.
Do not invent a pstate before startup or infer exclusive execution from NULL.

Candidate `mem.c:1728-1743,1953-1965` uses `___alloc_scmobj(NULL, ...)` to
select permanent storage; NULL does **not** say that the caller is inactive,
unattached, or has no live Scheme references. Existing interner/private global
helpers in `lib/mem.h` lack an explicit processor argument. A possible small
refactor is private context plumbing separating allocation class from execution
authority; it must not change exported ABI or silently use TLS as authority.

## Preparation, Revalidation And Commit

Two implementation shapes remain open: a no-Scheme-GC bounded transaction with
compatible arena reservation, or preparation outside topology protection with
a canonical recheck before commit. Neither is yet selected. C allocation is
not automatically nonblocking or failure-free. Before implementation, audit
lock order with VM registration, allocation, loader state and GC participation.
Do not simply reuse `vm_list_mut` or a global runtime lock.
The collector must not need a metadata resource held by a participant waiting
for that collection. A no-Scheme-GC critical section still needs a bounded exit
and compatible waiting participants; it is not permission to ignore GC.

For either shape:

1. Identify execution owner, GC membership, root ownership and storage class.
2. Publish live roots before any wait/allocation that can permit collection.
3. Wait only through a source-validated participation path; distinguish
   collector service from arbitrary Scheme callbacks or interrupt delivery.
4. Reacquire valid execution and reload references before computing addresses,
   hashing/comparing movable inputs or resuming copy.
5. Recheck all predicates that could change while protection was released.
   A cached bucket index, count or miss is not a transaction reservation.
6. Commit only initialized data. Return errors after releasing owned guards
   and temporary resources, without undoing other callers' reservations.

Candidate header `8090-8105` implements `GC_SAVE1/2/3` with fixed `saved[]`
slots, not an arbitrarily nested root stack. `c_intf.c:6511-6552` demonstrates
an actual save/allocate/restore use, not permission to nest it through an
unknown service helper. Root-slot ownership, callee clobbers, return-address
handling and unwind must be audited using the existing
[FFI frame model](../../models/gambit/ffi_gc_frame_protocol.qnt) and
[retry rooting model](../../models/gambit/predicate_lock_retry_rooting.qnt).
Publishing a root without reloading it is insufficient.

## Enumeration Capture And Scheme Delivery

The actual allocating consumer is `apropos` in baseline `_repl.scm:5120-5219`,
via candidate `_kernel.scm:3847-3862,3900-3917`. It is not safe to extend a
non-reentrant metadata critical section across that Scheme callback.

The concrete candidate to review is a private capture helper plus the existing
fold entry, not a new public enumeration API:

1. Read required capacity under compatible topology protection; release it.
2. Allocate a **typed, Scheme-owned** capture outside protection. Keep live
   inputs/capture correctly rooted through allocation and waits.
3. Reacquire protection through the validated wait path, reload the capture,
   and revalidate capacity against the current membership. Retained count
   alone does not protect links against rehash.
4. If too small, release protection and discard only the private temporary;
   plan/retry. On fit, copy initialized identities without invoking Scheme or
   allocation inside protected traversal.
5. Release topology protection, then run the existing Scheme fold over the
   captured identities. No native guard or manual C lease may span arbitrary
   callback return, exception, continuation escape or nested enumeration.

This is a membership capture, not frozen values: later value updates remain
subject to their own ownership contract. Callback insertions are not required
to appear in the capture. Preserve sequential fold result, arity, error and
identity semantics; compare actual ordering/weak-entry/global-binding behavior
before strengthening a public consistency guarantee. Concurrent mutation of
the input name itself is a separate caller precondition, not solved here.

Candidate `mem.c:1797-1940,2040-2059` distinguishes still allocation from
ordinary Scheme allocation: still objects start with refcount 1, may trigger
GC, and need an explicit release contract. Nonmoving does not mean no GC or
automatic cleanup. A C-still buffer is therefore **not** a drop-in alternative
to a Scheme-owned vector. The exact available Scheme allocation/root-frame
path must be established before selecting helper signatures.

Capacity retries require bounded intervening growth/fair acquisition for the
finite completion argument. Continuous unbounded insertion is not proved
wait-free; measure retries/allocated bytes and check overflow/maximum size.
Do not obtain progress by holding a lock across user code.

## Failure Cutpoints And Rollback

| Cutpoint in current candidate | Existing visible behavior | Required preservation / open obligation |
| --- | --- | --- |
| Permanent name succeeds, later object allocation fails (`mem.c:2346-2404`) | Error is returned; an unpublished name can remain in the permanent arena until cleanup. | Logical rollback means no invalid publication, released private guards/roots and original error. It does not require physical arena rewind. |
| Insert succeeds, optional table growth fails (`2177-2228`) | Old table already contains the new identity/count; resize is skipped and interning succeeds. | Do not turn best-effort growth failure into failed insertion or discard the canonical object. |
| Rehash starts rewriting existing links | Readers can no longer rely on the old topology. | Validate size/allocation and all fallible preparation before relinking; no Scheme escape during partial topology mutation. |
| Global registration fails (`1611-1646` and list helper) | Binding is not published; earlier prepared VM segment capacity can remain. | Audit segment initialization, registration order and cleanup. Do not erase capacity used by another operation or claim all-or-nothing physical rollback. |
| Capture allocation or capacity retry | No user callback has executed. | No partial delivery, no held guard, release/drop private temporary by its actual ownership class. |
| User callback raises or escapes after capture | Prior callback effects may already exist. | No framework-driven replay or rollback of user effects; no metadata guard/manual buffer lease requiring normal return. Explicit Scheme continuation reinvocation retains its language semantics. Full continuation compatibility remains a native obligation. |

Rewinding a process-wide permanent cursor after another caller reserved later
storage can destroy a live reservation. Avoid that proposed cleanup strategy;
it is not a diagnosed existing rewind in Gambit. Resource retention, bounded
growth and eventual global cleanup must be evaluated separately from identity
correctness and error propagation.

## What Transfers From Chez And OCaml

| Reference | Useful mechanism | Non-transferable or unproved premise |
| --- | --- | --- |
| Chez `c/intern.c:155-304`, `c/types.h:363-421` | Whole-operation boundary plus active-thread/collector and allocation lock-order contract. | Collector-side oblist resize is not arbitrary concurrent-mutator resize. `c/prim5.c:298-312` does not establish a snapshot API. |
| Chez `c/alloc.c:208-225`, `c/thread.c:535-600` | Explicit eligibility for collection/service and wait deactivation. | Not a Gambit sync-only poll recipe; cannot assume every allocation can invoke callbacks while protected. |
| Chez `c/segment.c:84-86,99-102` and platform branches | Allocation failure has an explicit abnormal-exit policy at this layer. | This path does not prove recoverable local rollback. Importing it would change Gambit's error contract. |
| OCaml `runtime/callback.c:387-431`, `unix.c:649-657` | Root inputs, release/reacquire runtime on contended wait, discard/reload movable addresses. | Domain lock alone does not serialize the process-global named table. A stable returned slot is not immutable payload. |
| OCaml `callback.c:407-417`, `memory.c:627-634` | Allocation and root publication are visible failure cutpoints. | `caml_stat_alloc` may raise; no local unlock on that failure is visible in this snippet. This is an unresolved reusable unwind proof, **not a reproduced OCaml bug** or a policy to copy. |
| OCaml `callback.c:442-454` | Internal visitor has an explicit mutex boundary. | Not evidence that arbitrary allocating/reentrant Scheme callbacks may run under a native metadata guard. |

## Source Scope And Staging

**First small-refactor candidate:** private permanent reservation + interner
lookup/create/rehash + all live exact readers, followed by capture/delivery in
the existing kernel fold. Review `lib/mem.c`, private `lib/mem.h` signatures,
and only the needed `_kernel.scm` CFUN/fold boundary. Root/RA changes may require
header or C-interface work and a coherent producer rebuild; do not call it a
one-file patch. No generated allocation fast path should gain a metadata lock.

**Conditional follow-up:** new-global check/create/register/bind. Include it in
the same release only after ordering with VM registration and per-VM GC roots
is closed; otherwise retain the missing obligation explicitly. Do not claim
the interner fix closes global binding or concurrent evaluator/loading.

**Stage Two:** general reentrant/parallel module initialization, arbitrary host
attachment/switching, runtime generations, scalable nonblocking metadata or a
collector redesign. Keep these linked but outside the first repair.

## Existing Models And Composition Limits

[gc_table_iteration.qnt](../../models/gambit/gc_table_iteration.qnt) retains its
original traversal/GC/tag controls. Its additional capture projection composes
finite preparation, allocation failure, one wait-time relocation, root reload,
capacity revalidation, protected copy, unlocked delivery and callback failure.
Delivery failure retains only the actually delivered prefix, not a fictitious
whole-batch completion. Explicit Scheme continuation reinvocation is not modeled.
Five controls remove rooting, reload, unlocked delivery, capacity checking or
allocation-failure handling. Callback membership can grow after capture without
changing delivered membership. This is not a new GC/lock simulator.

Reuse [metadata reservation](../../models/gambit/runtime_metadata_allocation.qnt),
[serial-number transaction](../../models/gambit/serial_number_transaction.qnt),
FFI-frame and retry-rooting protocols for their distinct obligations.
[Lean contracts](../../models/gambit/lean/RuntimeEntryContracts.lean) add
parameterized no-rewind, copy-index-bound and stale-local consequences. These
conditional arithmetic/epoch lemmas are not source refinement or a collector.

Still missing: real lock ownership/order, callee effects on fixed root slots,
moving-GC/RA implementation correspondence, arbitrary continuation unwind,
unbounded growth, weak C memory, allocator overflow/alignment and actual source
failure recovery. Positive model behavior is a design obligation, not evidence
that current Gambit already implements it.

## Real Acceptance Before Runtime Adoption

| Obligation | Real test and required observation |
| --- | --- |
| Whole-operation identity | Concurrent same/colliding/distinct names, forced rehash and exact readers; one canonical identity, no lost pre-existing key and disjoint initialized reservations. |
| VM separation | Distinct valid VM/processor owners on available host CPUs; shared canonical symbols but isolated VM value cells. No global execution serialization. |
| GC-compatible waits | Force GC while a real metadata waiter retains movable input/capture; verify root publication, root-slot ownership, participation, RA/reference reload and eventual completion. |
| Capture | Force growth between planning and copy; verify safe retry. Allocating, mutating, nested, raising and continuation-escaping callbacks must never retain a metadata guard or follow live mutable links. |
| Failure | Source-supported deterministic failures before publication, during optional growth and segment/capture preparation; preserve the above error/success distinctions and retry safety. No unapproved interposition or release-only test hooks. If unavailable, mark this obligation untested, not passed. |
| Compatibility | Existing sequential fold/FFI/error behavior, exact supported flags, original interpreted/compiled stress and full required GSI/GSC tests. No blanket eval/load-thread-safety claim. |
| Cost | Exact-source baseline/candidate, host-adaptive concurrency, uncontended and contended latency, capture bytes/retries, GC pauses and complete build/test times. Preserve existing performance gates; no speed claim from formal checks. |

Use source-bound checkpoints to reuse genuinely unchanged passed stages;
changed producer inputs require affected-stage revalidation. Watchdogs observe
real stage/test progress, not synthetic heartbeats or an accumulated retry
budget. This design review does not start a native campaign, rerun bootstrap,
change the native lane's progress, or overwrite any failure record.
