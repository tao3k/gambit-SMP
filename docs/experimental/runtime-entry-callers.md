# Shared Metadata Callers And Refactor Decisions

## Scope And Source Authority

This follows the [entry contract audit](runtime-entry-contracts.md) without
changing runtime code, TLS, locks or native qualification. Existing models are
extended only for the reader-topology gap and a legal-parallelism witness.
[Original validation](runtime-entry-validation.md) remains historical; changed
model bytes require a new receipt rather than inheriting that result.

Gambit source-lock SHA-256 remains
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`
on baseline `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Candidate `mem.c`, `setup.c` and `_kernel.scm` hashes were rechecked against
that lock. Candidate line numbers below refer to this overlay, not a cache
checkout. Chez remains `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`;
OCaml remains `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`.

## Existing Entry Classification

Baseline `configure.ac:1247-1301` independently selects multiple VM instances,
multiple OS threads within a VM, and the SMP Scheme scheduler. These are
capabilities, not automatic attachment or proof an application started workers.
The explanatory parallelism notice at `4132` is inside `if false`; it is not
an executable guard. Current-profile admission uses actual compiled flags.

| Entry / write | Actual source and caller premise | Classification |
| --- | --- | --- |
| `init_symkey_glo1/2`: static symbol headers, hashes, bindings and chains | Candidate `setup.c:3517-3621`, global entry callers `7151-7152` plus internal recursive traversal. Global setup performs this before VM/P0 setup, thread binding and the first `___run`. | Startup-exclusive under serialized global setup with no pre-existing users. Do not classify these particular plain stores as a runtime race. Overlapping global setup violates that premise. |
| Public `string->symbol` / `string->keyword` misses | Baseline `lib/gambit/symkey/symkey.scm:55-62` and the keyword analogue; candidate `_kernel.scm:3801-3825`, `mem.c:2346-2404`. Distinct runtime processors or explicitly owned VMs reach shared intern/permanent storage without global setup. | Existing execution paths can overlap. Same-name identity, distinct-name allocation and rehash are separate obligations. Source reachability is established; native overlap/defect reproduction is not. |
| `___make_global_var` check/create/bind | Candidate `mem.c:1611-1646`, `_kernel.scm:3867-3874`, dynamic fixup helper `setup.c:1909-1935`. List registration has a narrower lock than the outer operation; that lock is conditional on `!___SINGLE_VM`, not on threaded execution alone. | Conditional Stage-One scope. A single-VM threaded build cannot borrow the multi-VM list lock as its proof. Callable low-level entries do not establish general eval/compiler/load thread safety. |
| `___setup_vmstate` on separately owned storage | Candidate `setup.c:5393-5490` initializes VM/P0 resources and membership, not the global `init_symkey_glo1/2` sequence. The independent-VM fixture reuses already initialized permanent module/thunk objects. | Explicit-owner embedding experiment. Successful parallel child VM startup does not establish parallel dynamic loading or arbitrary attachment to an existing processor. |
| Dynamic object loading / fixup | Candidate `setup.c:2488-2517,1939-2000`. Fixup has an explicit multiple-VM atomicity TODO and sets DONE before later validation/payload work. `_kernel.scm:5230` separately has a registry atomicity TODO. | Reachable dynamic entry, but full concurrent/reentrant initialization support is not established. Existing fixup/generation models already record relevant obligations; no new native causal claim follows. |
| SFUN callback on an already owned processor | Candidate header `10112-10128,14723-14777`; `setup.c:3696-3845`. Marker, return origin and lifetime admission exist; entry reads an existing pstate. | Caller retains execution ownership, GC participation and return origin. Independent processor owners may run concurrently; two host threads do not gain ownership of one register/stack/catcher merely by obtaining two leases. |
| Global lifecycle / foreign-thread switching | Candidate `setup.c:5494` states global host lifecycle serialization. Child VM ownership is a separate operation. | Concurrent global setup/cleanup, auto-attachment, cross-VM nested switching and restartable module generations require separate Stage-Two decisions. |

The memory-lock macros at candidate `mem.c:393-411` do not close the permanent
allocator gap: reservation and psection linking at `1195-1306` do not acquire
them. Thread-safe system malloc does not serialize the caller's `palloc_ptr`
or `psections` updates. Growth/failure and machine arithmetic remain unmodeled.

## Readers Are Part Of The Operation

Candidate `mem.c:2272-2343` directly looks up interned names;
`_kernel.scm:3833-3845` reaches that lookup via a CFUN. Rehash at
`mem.c:2177-2228` changes existing `SYMKEY_NEXT_FIELD` links before publishing
the new table. Retaining old table/object addresses does not retain traversal.

A real allocating reader is baseline public `apropos` at
`lib/_repl.scm:5120-5219`. Its `##global-var-table-foldl` reaches candidate
`_kernel.scm:3847-3862,3900-3917` and invokes a Scheme callback while traversing
the intern chain. That callback allocates tables/strings/lists. A proposed
short critical traversal must not silently hold a non-reentrant lock across
arbitrary Scheme callbacks or assume GC cannot happen there.

Candidate `mem.c:2406-2436` also defines `___for_each_symkey` with a C visitor,
but no in-tree callsite/public table export was found in the reviewed runtime,
header and kernel slice. A definition alone is not a supported concurrent host
entry. Its external contract remains unresolved, not assumed.

Discriminating abstract schedule: old bucket A->B; lookup for already-present
B captures A; the sole writer places A in a new bucket by clearing A.next;
lookup follows that changed link and misses B before table publication. Writer
serialization alone cannot prevent this. Exact-name lookup and enumeration
need not have identical consistency guarantees: this is not a new requirement
that an enumeration see every concurrent insertion.

## Chez: Transfer The Surrounding Contract

Pinned `c/intern.c:155-304` serializes lookup/create/insertion with `tc_mutex`,
but computes bucket indexing before acquiring it. The surrounding active-thread
and collector contract therefore matters. `S_resize_oblist` at `66-100`
rewrites links and frees the old array; the reviewed collector caller is
`c/gc.c:1794`. This is not a concurrent-mutator resize guarantee.
`c/types.h:363-421` defines participation and tc-before-allocation lock order.

`c/alloc.c:208-225` separates queuing collector work during allocation from
firing the Scheme collector procedure, with `during_alloc` and lock-owner
guards. This is not Gambit's sync-only participation protocol.
`c/thread.c:535-600` permits condition-wait deactivation only for collector
conditions or enabled interrupts. No unconditional poll/deactivation rule follows.

`c/prim5.c:298-312` traverses `s_oblist` without an internal tc-mutex acquisition;
`s/prims.ss:141-144` exposes it through an ordinary foreign procedure. This audit
does not establish a snapshot guarantee or C memory-model proof for that API.
Chez is a reference for selected mechanisms, not proof that every table reader
is internally locked or implements a stronger consistency contract.

## OCaml: Slow-Path Roots And Escaped Slots

The named-value table is process-global. Pinned `runtime/callback.c:387-431`
protects lookup/update and registers/updates each global root. A domain lock
alone cannot serialize accesses by other domains; the table boundary differs.

`runtime/unix.c:649-657` and `runtime/win32.c:1451-1465` show the actual slow
path: enter a no-pending blocking section, wait for the metadata mutex, then
reacquire runtime execution. `callback.c:395` discards the old string address
because it may have moved. `CAMLparam` and address reload are part of the
protocol. Transfer to Gambit requires its own eligible wait, root publication,
service and reload contract, not a call to this helper or blanket polling.

`caml_named_value` returns a stable C slot address after unlocking. The contents
are not thereby immutable or accessible without runtime ownership.
`runtime/globroots.c:151-180` maintains root classification and then writes the
value; a caller using the returned slot no longer holds the named-table lock.
Do not infer a complete concurrent payload-update theorem from table lookup.
`caml_iterate_named_values` invokes an internal C visitor under the lock; that
does not establish arbitrary reentrant user-callback safety under such a lock.

## Stage-One Decisions Worth Discussing

| Candidate | Concrete source boundary | Benefit, cost and acceptance boundary |
| --- | --- | --- |
| Runtime-shared metadata operation | `mem.c` permanent reservation, intern lookup/create/rehash and new-global binding; `_kernel.scm` readers only where required. | Highest-value bounded correctness candidate. Preserve interned identity, VM-local values and normal generated-code allocation fast paths. Resolve all readers, lock order, eligible GC-safe waits and OOM/retry before choosing a mechanism. Header/layout changes require a coherent producer rebuild; a small edit is not necessarily cheap to qualify. No speedup predicted. |
| Capture versus allocating enumeration callback | `##symkey-table-foldl`, global-var wrapper and real `apropos` consumer. | A snapshot/capture boundary could release topology protection before user code. Snapshot allocation/GC, retention and enumeration consistency must first be specified. No snapshot implementation or stronger API guarantee is selected. |
| Existing-owned callback contract | Existing SFUN/CFUN marker/return origin and lifetime admission. | Preserve normal, nested and exceptional behavior plus independent execution. No new defect in a valid owned caller was established, so no runtime refactor is justified merely to centralize code. Existing cleanup repairs remain intact. |

Acceptance for the first candidate needs exact-source same-name identity,
colliding keys and forced-rehash readers, distinct-name reservations, separate
VM owners, global-variable identity, OOM/retry and original GC/FFI stress.
These require an actual reviewed candidate; models alone are insufficient.
No native campaign or duplicate bootstrap is launched by this design review.

## Stage Two Remains Separate

Arbitrary foreign-thread attach/detach, cross-VM nested callbacks, restartable
runtime/module generations, general concurrent/reentrant module initialization
and a scalable metadata algorithm are semantic/ABI milestones. Do not hide
them inside a small synchronization patch. Shared nothing, a new collector,
metadata copied into TLS and a global VM execution lock are not selected.
The C backend and FFI remain constraints, not causes to discard.

## Existing Model Extensions

`runtime_metadata_allocation.qnt` has two explicit profiles: original word
reservation/publication and a two-node reader/rehash topology. Its new
`initUnprotectedRehash` keeps head/object addresses stable and uses one writer,
yet misses an existing key. The positive reader profile excludes link changes
during lookup or starts after publication. This is a required abstract history,
not a mutex/RCU implementation. Separate profiles do not prove their combined
allocator, GC and callback protocol.

`runtime_host_entry.qnt` adds a legal distinct-processor parallelism witness.
The expected counterexample to `universalSerialization` is an allowed state,
not a protocol failure; it checks that safety was not obtained by banning all
simultaneous execution. `RuntimeEntryContracts.lean` adds independent-owner
compatibility, the finite retained-head/changed-link counterexample and a
conditional stable-topology lemma. It does not prove source readers acquire
the required protection or an unbounded hash-table traversal theorem.

Existing serial-number transaction, module-fixup, linker-generation, foreign
admission and nested-unwind models retain their identities and limits. No
duplicate interner, attachment or module model is added.
