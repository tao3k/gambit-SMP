# Shared Metadata: Stage-One Synchronization Package

## Decision And Authority

This refines the [entry/publication audit](stage-one-closure-audit.md), not a
runtime patch. Keep the C backend, exported allocator/FFI ABI, VM-local values,
valid continuation behavior and generated direct-global/allocation fast paths.
Do not change TLS, start native qualification or alter the other lane's source
lock/checkpoint. No throughput or native-failure-causality claim follows here.

Authority: Gambit `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the existing
[overlay lock](../../evidence/research/processor-interrupt-collective-wait/source.lock.json)
and cumulative patch; line references below are overlay references unless a
vendor path is given. Chez is `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`;
OCaml is `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`.

The discussion-level choice is **one central reservation boundary, one complete
metadata boundary, and the existing registry protocol**, not a lock at every
call site. An ordinary nonrecursive mutex with acquire/release semantics is the
candidate primitive for the new boundaries: raw allocation and name comparison
have variable latency, so a spin/ticket lock is not the default. This selects a
reviewable design, not permission to implement it or a real-time guarantee.

All components use one repaired source/configuration and are rebuilt together;
there is no mixed-binary or defective-old-SMP compatibility path. Preserve C
code generation, valid continuation/FFI semantics and fast paths, not incorrect
historical synchronization. The [matched rebuild contract](c-backend-compatibility.md)
owns that distinction; historical receipts keep their original identities.

## Resources And Acquisition Order

| Resource | Protected history | Explicitly outside it |
| --- | --- | --- |
| P: process permanent reservation | Alignment, cursor/limit reservation, new psection allocation/link and publication as one operation. | Object initialization after reservation, table membership, VM registry and Scheme service. |
| M: process metadata transaction | Exact lookup/create/insertion/rehash, bucket/NEXT traversal, canonical global check/create/bind and structural reverse lookup. One boundary for symbols and keywords initially. | User callbacks, collecting allocation, synchronous service and ordinary VM value reads/writes. |
| V: existing `vm_list_mut` | VM membership and per-VM global segment preparation/count publication. Preserve its admission/lease/drain algorithm. | New ownership of all Scheme execution, permanent allocation fast paths or arbitrary callbacks. |

The proposed nesting order is **V -> M -> P**, with either resource skipped
when unnecessary. Interning uses M -> P; standalone exported permanent allocation
uses P only. A global creation may reserve a private record under P, release P,
then acquire V -> M and recheck the binding. It must never carry M or P into a
later V acquisition. Inside V -> M, a private already-locked list helper avoids
reacquiring V; the startup-facing wrapper retains the old private function
signature. Neither a recursive mutex nor try/retry hides a reversed order.

This revises the earlier *prospective* topology -> registry suggestion:
`setup.c:5125-5140,5280-5389` calls processor/VM cleanup while holding V.
`cleanup_interrupts_pstate:519-545` holds the procedural queue mutex and calls
`release_procedural_interrupt:267-275`, which invokes an externally supplied
`execute_fn(..., FAL)`. Registration at `252-264` does not establish a leaf
effect restriction. A release callback that interns would introduce V -> M;
M -> V elsewhere would therefore be unsafe to assume. This is a reachable
callback boundary and a prospective cycle, **not a reproduced native deadlock**.

Stage One permits that callback's leaf interning/P reservation only under the
same lifecycle contract; it does **not** newly allow VM construction, global
creation requiring V, recursive queue operations, Scheme entry or shutdown from
inside a V/queue-owned release callback. Some already reacquire V today. Such
capabilities need an explicitly reviewed callback-detachment/retirement design,
not a silent new prohibition on previously established supported behavior.
External callback compatibility must be checked before publishing a patch.

Registry signal readers (`setup.c:113-243`) do not call these release callbacks.
They deliver interrupt flags and `___device_select_abort`; the reviewed
`os_io.c:1538-1563` path performs write/SetEvent, not Scheme metadata lookup.
Their progress still depends on the existing async-resource/lifetime contract;
this review does not prove OS wakeup calls have bounded latency.

## Central Permanent Reservation And Failure

`mem.c:1195-1306` includes **two** shared histories: psection linking and the
current section cursor. Protecting cursor addition alone is insufficient.

1. Under P, validate request arithmetic/alignment without wrap, calculate the
   aligned range and reserve it if it fits. Release P before initializing the
   returned private object. An uninitialized reservation is not an interned object.
2. Preserve both slow branches: standalone large/high-waste allocation links a
   psection without replacing the active cursor; ordinary refill links a section
   and updates cursor/limit only after successful raw allocation.
3. Initially retain raw OS allocation inside P: it has no Scheme callback/GC in
   the reviewed path and avoids a second speculative-refill protocol. Moving it
   outside P requires revalidation, orphan-section handling and a separate
   cost/benefit decision. No collecting still-heap allocator may be substituted.
4. Return the original error, release P/M/V actually acquired, and publish no
   partial object/binding. Never rewind over another completed reservation.
   Existing abandoned permanent names/records can survive until global cleanup;
   that compatibility behavior is not per-operation memory reclamation.
5. Rehash growth remains optional after successful insertion: allocation failure
   preserves the old valid table and successful insertion (`2177-2228`). Do not
   introduce a new insertion-failure result or partially relink before allocating.

P must cover NULL allocator callers, not just interners: module descriptors,
UTF-8 conversion and exported `___alloc_scmobj` also use permanent storage.
NULL specifies storage, not host execution/GC ownership. Existing host lifecycle
and valid-processor entry preconditions remain in force.

## Readers: Two Different Adaptations

| Reader | Concrete adaptation | Compatibility/latency premise |
| --- | --- | --- |
| Exact intern/find and private structural reverse scans | One M-owned traversal, using private unlocked subroutines inside an already-owned transaction. | No nested wrapper acquisition; stable identity does not imply stable NEXT links. Mutable primitive/value payload has a separate synchronization contract. |
| TTY `visit_symbol` (`vendor/gambit/lib/os_tty.c:6719-6855`) | Keep the reviewed C prefix/common-prefix/lexicographic visitor under M; retain only the permanent result symbol, then unlock before C completion-buffer allocation. | Caller owns the line-edit buffer. No Scheme/service/metadata reentry in this visitor. Measure O(entries * compared name length) hold time and GC delay; no hard latency bound is inferred. |
| Generic `___for_each_symkey` C visitor | Do not silently run arbitrary visitors under nonrecursive M. Keep a private reviewed leaf traversal for TTY; define generic delivery through a stable captured membership sequence if concurrent use is supported. | Callback signatures alone do not certify effects. Capturing C buffers and reporting OOM through a void callback API require a compatibility decision; unknown external concurrent callers are not claimed closed. |
| Kernel fold and Geiser | Reuse Scheme-owned rooted capture/revalidate/copy and unlocked callback delivery. Replace Geiser's raw table/NEXT walk, not just its getter. | `interesting?` allocates and calls `##make-global-var`; running it under M would recurse into M/V. Preserve prefix filtering, procedure check, sorting and error behavior, not a snapshot of mutable global values. |
| Escaped `##symbol-table`/`##keyword-table` | Preserve sequential getter behavior; known allocating in-tree consumers migrate. | Atomic head/getter alone cannot make escaped mutable NEXT links concurrent snapshots. Unknown raw concurrent clients remain an explicit API milestone. |

TTY's retained symbol/name is permanent in the reviewed interner, but the device
buffer and runtime generation still require live ownership. Geiser captures
membership at a consistent instant; later insertions need not appear in the
current completion. Its global values are read when the predicate executes.
Do not claim a consistent environment/value snapshot across user callbacks.

## Global Record Publication: Three Observer Contracts

For a missing binding, prepare a private permanent record, acquire V -> M (M
only for single-VM profiles), **recheck** the binding, initialize `prm`/structural
fields before making the record reachable, prepare all live VM slots under V,
link/register, release-publish the new count, then release-publish the symbol's
binding. An already present canonical record wins; private preparation is not a
second binding. On segment failure, retain safe initialized surplus capacity
but no new count/list node/binding. No failure-prone operation follows structural
publication in this proposed leaf transaction.

| Observer | Required synchronization | What it does not certify |
| --- | --- | --- |
| Multi-VM GC slot range | Existing acquire count/table/segment after initialized cells (`mem.c:1370-1499,7307-7331`). Keep constructor catch-up under V. | Count is not a record/binding or user payload certificate. |
| Structural list/reverse reader | M excludes concurrent link/record initialization; initialize fields before linking. V -> M writers serialize with constructors. | M does not synchronize a separate writer of user mutable values or primitive payload unless that writer joins the contract. |
| Dynamic symbol binding reader | Paired release store/acquire load on binding discovery, including the shared `GLOBALVARSTRUCT` access path and relevant direct accesses; no mixed unsynchronized live plain accesses. | Address-stable generated `glotbl` accesses need no new per-value metadata mutex. Later payload mutation remains separate. |

Header `5950-5958` currently uses a plain lvalue field and casts. Preserve the
raw lvalue representation for initialization/layout compatibility, but route
**live discovery** through the acquire accessor. Update every in-tree live
publisher/read site consistently; a release store alone is insufficient.
Generated code and extensions must be fully rebuilt with the repaired header
and effective configuration; external serialization is not a substitute for
that qualification. Unchanged struct layout does not certify the inline
instruction protocol. Static `init_symkey_glo1/2` must retain hash relocation
and exclusive startup order, not apply dynamic `prm = FAL` to static records.

GC's table-root observer is also explicit: `mark_symkey_tables:7334-7346` reads
the process table fields through `mark_array`. The reviewed tables are permanent
(`alloc_symkey_table:2160-2173`); the PERM branch of `mark_array:3914-4071` does
not trace/rewrite their contents. A compatible design acquire-loads the published
head into a local permanent root for this observation rather than doing a plain
read of a concurrently replaced global field. This is **not** a rooted snapshot
for ordinary traversers. Do not hold M across the collector's full moving scan.

Single-VM list-root scanning is a different compile-time branch (`7280-7301`):
STW excludes supported mutators of that sole VM, not arbitrary unattached host
threads. Multi-VM GC uses slots instead. Debug reverse-name scans need the same
structural discipline without recursively taking M inside an M-owned traversal.
Live module primitive/value initialization and user `set!` are not made atomic
environment snapshots by record publication.

## Lifecycle, Portability And Reference Transfer

Initialize P/M before `___setup_mem` first allocates tables (`5467-5494`), under
exclusive global setup. Track each initialized resource for partial failure,
keep P/M live through VM/procedural-release cleanup, then free permanent sections
only after all users drain, destroy guards last, and reset on a new supported
generation. Current `setup.c:7051-7140` / `cleanup_os_and_mem:5050-5070` do not
already implement that new prefix. Check initialization failures; copying an
unchecked existing mutex initializer is not a failure contract.

The primitive adapter must have equivalent nonrecursive acquire/release behavior
on supported targets; POSIX mutex and Windows CriticalSection differ in recursion.
The protocol never relies on recursion. Protect process state even when each VM
is single-threaded but multiple VMs execute on different host threads. Do not
compile protection away merely from `SINGLE_THREADED_VMS`.

Chez `c/intern.c:155-304` supports the whole-operation boundary, not a ready-made
Gambit collector/wait adapter. OCaml `runtime/callback.c:387-431` supports shared
named-table lookup/update plus root registration and post-wait reload. Its
`caml_iterate_named_values:434-445` calls a C action under its lock: this does not
authorize arbitrary Gambit Scheme callbacks under M. OCaml's contended wait
(`runtime/unix.c:649-657`) leaves/reenters domain ownership; copying that helper
would import root, hook and exception obligations. Gambit's proposed **leaf**
owners finish without collective service; raw waits still require fair scheduling
and terminating OS operations. This is a conditional progress argument, not a
GC-safe blocking primitive or a bound on collector pauses.

## Discussion Closure And Remaining Acceptance

The Stage-One package is now concrete at design level: P reservation, M
transaction/topology, V -> M ordering, differentiated readers, three publication
contracts, and lifecycle/failure unwind belong together. No symbol-only or
writer-only patch represents this package. The following are explicit review
conditions, not permission to weaken current behavior:

- Confirm rebuilt procedural/C-visitor contracts and consistent generated/header
  protocols; unsupported reentry is not newly promised.
- Check exact atomic accessor availability, alignment and all enabled raw read
  sites in the implementation profile. Models are not a C memory-model proof.
- Bind actual capture root storage/map/reload and exits to its producer. Reuse
  existing capture, FFI and unwind models, not a new GC/FFI ABI.
- Validate same-name identity, exported permanent callers, refill/oversize/OOM,
  TTY/Geiser output and nested/error folds, record readers, VM constructor/GC
  overlap, startup rollback and supported compile profiles on the real candidate.
- Preserve current original stress/performance gates; measure guard contention,
  TTY hold time and GC pauses before a performance claim. Reuse the other lane's
  unchanged native checkpoint; this design does not reset or advance it.

Stage Two owns general callback reentry/parallel loading, new host attachment,
arbitrary raw concurrent views, nonblocking refill/reclamation and collector
architecture changes. These are linked experimental milestones, not prerequisites
invented for every existing supported leaf call.

The existing `runtime_metadata_allocation.qnt` gains a finite resource-composition
profile: interner M -> P, global registration V -> M -> P, and an independent
P-only allocator. Controls reverse V/M order, omit the allocator boundary, or
reenter M from a guarded callback. Other profiles retain publication and rehash
counterexamples. This composes resource acquisition/reservation only, **not**
all table, weak-memory, GC and OS behavior into a complete runtime proof.
Lean extends the existing conditional resource-order and reservation lemmas;
[local validation](shared-metadata-package-validation.md) reports exact results.
