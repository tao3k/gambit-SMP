# Stage-One Entry, Liveness And Publication Closure

## Conclusion And Scope

This consolidates the next source review after the
[wait/root/exit audit](metadata-wait-roots-exits.md). It is a design decision
record, not a runtime patch or native milestone. Preserve C code generation,
public FFI, VM-local values and ordinary generated global/allocation fast paths.
Do not select a lock or TLS change from these models alone.

The earlier preference for Scheme-side retry is **conditional**, not a demand
to turn every C helper into a GC-service adapter. The current permanent interner
path is noncollecting: preserving that bounded leaf envelope is a lower-change
candidate for existing C/startup callers. Any caller that actually waits across
service, collecting allocation or callback still needs explicit roots, reload,
ownership and exit coverage. Moving work into a private C helper does not remove
those obligations.

Source authority remains Gambit baseline
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus the
[source lock](../../evidence/research/processor-interrupt-collective-wait/source.lock.json)
and cumulative patch. Gambit line references below are to that overlay. Chez
and OCaml retain their pinned vendor revisions. This census covers definitions,
callers and field accesses in the reviewed C backend's `lib/`, private/public
headers and relevant generator sources, including compile-time branches. It is
not an enumeration of arbitrary external embeddings, dynamically generated C,
all build profiles or the universal backend. Disabled code is not a live caller.

## C And Startup Entry Census

| Entry | Actual path and execution premise | First-stage adaptation boundary |
| --- | --- | --- |
| Static intern/global setup | `setup.c:3517-3621,7151-7152`, before module/VM execution under exclusive global lifecycle setup. | Preserve startup exclusion and lock initialization order; no service or invented attached processor. |
| Scheme intern/find | `_kernel.scm:3801-3845` to `mem.c:2272-2404`. Name input can be movable; returned names/symbols are permanent. | Preserve noncollecting leaf behavior inside protection, or use a fully published Scheme retry frame outside it. Do not add a collecting call to a previously leaf C helper. |
| Module fixup UTF-8 intern/global creation | `setup.c:1893-1936,2060-2115`; startup and live loading both reach it. | `fem_context.ps` already exists (`1766-1775,2433`) and is read by fixup (`1948`); private context plumbing need not create TLS. Non-NULL pstate alone does not distinguish startup from active execution. |
| Live loader | `___os_load_object_file`, `setup.c:2487-2514`, uses `setup_modules(___PSTATE,...)`; same setup walk as startup. | Account for the live C chain if service/retry is introduced. Process-global linker/fixup DONE state is not made concurrent/reentrant by metadata protection. |
| Permanent descriptor allocation | `setup.c:2429,2458,2473` uses NULL allocation through permanent vector/string helpers. | Arena reservation is shared beyond interning. An interner-only reservation guard cannot cover these callers. NULL selects storage, not GC membership. |
| Low-level code relocation | `setup.c:4487-4570`, `___SUPPORT_LOWLEVEL_EXEC` branch creates globals and embeds value/primitive-cell addresses. | Configuration-dependent C client. Do not infer it is enabled in the current producer; preserve cell-address lifetime if supported. |
| TTY completion C traversal | `os_tty.c:6719-6835` calls `___for_each_symkey`; `mem.c:2406-2433` invokes the visitor before reading NEXT. | A real in-tree reader omitted from the earlier narrower runtime/header/kernel search. `visit_symbol` reads permanent names and updates local completion state; no Scheme call/allocation is in that visitor. C buffer allocation follows traversal. This is not an arbitrary callback contract. |
| Generic permanent allocator ABI | `___alloc_scmobj` is exported through the runtime function table (`setup.c:6708-6718`), and NULL means permanent storage. | Central reservation must remain compatible with callers beyond the named interner helpers. Do not change the public allocator ABI or assume all callers can enter Scheme service. |
| Global/reverse lookup | `mem.c:1505-1644`, `_kernel.scm:3867-3907`; optional legacy `___USE_find_global_var_bound_to` branch at `1650-1680`. | Distinguish record discovery, stable record identity and mutable VM cell payload; cover each enabled reader, not just insertion. |

The internal permanent cursor/psection helpers are confined to `mem.c`; the
reviewed direct `alloc_mem_aligned_perm` callers are permanent object allocation
and global-record allocation. Higher-level NULL helpers share this reservation
path. External code may call exported allocation APIs, so the closure point is
the central reservation, not a list of known source filenames.

## Generated Root Liveness: What Was Actually Established

Three facts must remain distinct:

1. A value was written to stack/register storage.
2. The collector enumerates that live storage at the relevant return point.
3. After collection, execution reloads the relocated value and valid RA before
   using it or writing cached state back.

Overlay `gsc/_t-c-2.scm:446-470` uses `frame-live` when flushing cached frame
values. Its return-map construction at `888-930` distinguishes live frame slots
and saved GVM registers. The `##c-code` emitter at `4201-4245` exposes all machine
resources but emits the supplied C body; it does not discover/register arbitrary
C locals as Scheme roots. Header `10394-10447` supplies CFUN state/RA handoff
macros, which are distinct from the inline `##c-code` contract.

A read-only inspection of existing generated artifacts found this concrete
pattern for `##lock-scheduler-object-with-sync-participation!`:

- `_thread.c:21706-21710` reloads R1/RA from the suspended frame;
  `21725-21734` saves R0/R1 before calling `##sync-op-interrupt!`.
- `_thread.c:42802-42808` contains the return descriptor with GC map `0x3`
  and the internal return/check-stack maps. Header `9301-9308` encodes/maps the
  descriptor fields. This shows the storage/map/reload components of that
  inspected artifact, not a blanket theorem for all future wrappers.
- `_kernel.c:12588-12600` saves RA, writes registers, services the collective,
  reloads registers and restores RA, matching `_kernel.scm:1467-1487`.

Observed full-file SHA-256: `_thread.c` =
`5dc1fdc7bc34a0142636f6963a059170a93c870a50cb3f7eba70a4c255b0fc7e`,
`_kernel.c` = `158d91ca00fc34d17c898d58da4b41f671d0d4faac6f2a7ce32df7192bf2d052`.
These generated files are observations, not versioned source authority: this
review did not establish their complete producer/toolchain/SCM lineage or build
them again. No model/native admission is inherited from their mere presence.
The generator inputs are reproducible through the locked overlay; an actual
new wrapper requires a producer-bound generated witness in the existing framework.

For capture/retry, input, capture buffer, callback and accumulator must each be
live at the actual safepoint and reload point. A C-local alias of a live Scheme
object remains a separate stale-cache risk. Pure noncollecting leaf segments
avoid introducing a safepoint inside this interval; they do not prove caller
ownership or permit arbitrary nested SFUN/service entry.

## Lock And Wait Dependencies

| Resource/edge | Current observation | Design consequence |
| --- | --- | --- |
| Permanent cursor/psection | `mem.c:1195-1306` does not take ALLOC/MISC locks. Psection linking and cursor reservation are process-wide. | Central leaf reservation is a separate resource; do not pretend an existing heap lock already covers it. |
| Still heap accounting | `mem.c:1857-1900` releases ALLOC lock before calling GC; reacquires later only for failed-allocation accounting. | Retain the demonstrated separation of allocation ownership from collective service. Do not make a new metadata leaf call this collecting path. |
| Registry to C segment preparation | `mem.c:1448-1470,5232-5255,5400-5428` holds `vm_list_mut` while preparing per-VM segments through raw C allocation. | Review as an actual registry-owned path, not a Scheme-GC allocation path. It does not establish a registry-to-permanent-arena edge. |
| Service to registry | Count change at `setup.c:804-815`; service can also resize/throw/retire. | A new metadata owner must not depend on collective service to release itself. |
| Registry close/drain | `mem.c:5400-5428` and lifecycle setup paths close registry admission before mutation. | Retain existing reader-lease/drain contracts and models; do not change their admission/retirement algorithm in a metadata patch. |
| Scheme scheduler object order | `_thread.scm:14-45` declares mutex -> condvar -> thread -> group -> processor -> VM, with try/retry for inversions. | This is not automatically an ordering of C metadata/arena/registry locks. |
| Internal nonallocating C visitor | TTY visitor has no reviewed Scheme/service call; traversal is O(table entries and name comparisons). | A protected leaf traversal is a candidate, but long critical-section/GC latency must be measured. No arbitrary callback may inherit its effect contract. |

For a noncollecting leaf interner, a possible acyclic resource order is topology
protection -> short permanent reservation, releasing reservation before any
registry operation. This is a **prospective** order, not an assertion that source
already implements it. Every owner must exit without waiting on a GC/callback
that needs a waiter. Finite/fair OS allocation and scheduling remain assumptions;
absence of a Scheme allocation is not a hard real-time bound.

If any required caller violates that leaf envelope, its wait must be split at
a valid rooted execution boundary. Do not add service inside the leaf, lock every
VM, or choose a new TLS lookup to paper over the dependency. The first patch
must list the admitted caller effects rather than silently support fewer calls.

## Reader And Publication Ledger

| Payload / consumer | Existing publication/read protocol | Remaining closure |
| --- | --- | --- |
| Intern table head, bucket and NEXT links | Plain table/bucket stores and in-place NEXT relink (`mem.c:2133-2228`); exact find and C iteration follow them. | Writers alone are insufficient. Include exact lookup, TTY, reverse scans and allocating Scheme consumers in one compatible topology protocol. |
| Allocating Scheme fold | `_kernel.scm:3847-3862`, public `apropos`. | Prepare/root/capture outside protected user delivery as already modeled. |
| Escaped raw table | `##symbol-table` / `##keyword-table` expose a table object. `_geiser/_geiser.scm:123-149` follows symbol field 2 directly and calls `##make-global-var` while enumerating. | Migrating only the kernel fold misses this allocating/mutating consumer. Migrate known internal clients or retain an explicit unsupported-concurrency contract; acquiring/releasing around the getter alone does not protect escaped links. |
| Disabled kernel reverse scan | `_kernel.scm:426-450` is under `#if 0`. | Not a live reader or a native failure cause in this branch. |
| Debug/optional readers | `mem.c:2944-2977` debug naming and `1650-1680` optional legacy lookup. | Profile-scoped obligations, not default-profile proof or permission to ignore them in supported configurations. |
| Per-VM global segments | `ensure_glo_segment` initializes slots, release-publishes table/segment; `___glo_list_add` release-publishes count only after preparation. Multi-VM GC acquire-loads count/table/segments (`7307-7331`). | This protects the corresponding slot-readiness history; retain constructor catch-up/root coverage models. |
| Full global record and symbol binding | `___make_global_var` calls list registration, then initializes `prm`, then stores the symbol binding (`1611-1644`). Reverse-list readers may inspect `prm`; symbol/global macros use plain fields. | Count publication precedes these later writes and is not their readiness certificate. Record discovery and binding publication need their own compatible synchronization/read contract. No native failure is attributed from this ordering alone. |
| Stable generated module globals | `setup.c` fixes `glotbl` before module execution; header `6798-6807` accesses stable records/per-VM cells. Dynamic `##global-var-ref` emits `GLOBALVARREF` (`gsc/_t-c-2.scm:4136-4139`). | Preserve the distinction between an already published module record and dynamic symbol discovery. Do not put a metadata guard around every generated global-value load/store. Concurrent mutation of user values is not solved here. |

Single-VM GC traverses the global list; multi-VM GC consumes the initialized
VM-cell range. A stop-the-world boundary in one VM is not automatically exclusion
against another VM changing process-global metadata. Collector readers must be
audited for the concrete fields they access; neither permanent object addresses
nor a VM-local barrier is a process-wide publication theorem.

## Chez And OCaml Correspondence

Chez `c/intern.c:155-304` supplies an operation-level boundary, but oblist resize
and collector participation remain separate premises. Its internal oblist reader
does not prove arbitrary escaped raw views stable. Use that limitation when
reviewing Gambit's raw getter and TTY/Geiser consumers, not an assumption that
every reference runtime reader has an internal guard.

OCaml `runtime/callback.c:387-431` makes named-table lookup/update share a table
boundary and registers/updates global roots. Its returned stable slot is not
frozen payload; root classification/value updates in `globroots.c` are a
different operation. `roots.c:49-66` explicitly enumerates local-root records
and the runtime stack: a root declaration has an actual scanner counterpart.
Transfer these distinctions, not the C ABI or OCaml effect/exception semantics.

## Existing Model Additions And Limits

- `runtime_metadata_allocation.qnt` retains reservation and rehash-reader
  profiles, adding a separate slot-count/full-record publication profile.
  One control treats count as full-record readiness; another exposes a binding
  without the required record-visibility edge. A correct slot reader remains
  safe in both. This is not an axiomatic C11 memory model or a combined GC proof.
- `ffi_gc_frame_protocol.qnt` adds a nested-frame control where a stored outer
  root is omitted from the scan map. Storage alone cannot meet relocation
  ownership. Existing slot-overwrite, stale backup and caught-exit controls stay.
- Reuse `vm_constructor_root_publication`, `module_fixup_publication`,
  `global_linker_generation`, retry-rooting and unwind models for their own
  source-bound obligations. Do not duplicate them or reinterpret their passing
  abstractions as new attachment/loading capability.
- Lean records a counterexample to conflating slot readiness with later record
  readiness. Existing frame/rank lemmas remain conditional on actual source
  enumeration and acquisition edges. No model selects a lock or emits an action.

## Small Refactor Packages And Real Acceptance

**Candidate A: leaf arena/interner plus reader closure.** Centralize disjoint
permanent reservation without changing the exported allocator ABI; define the
complete interner lookup/create/rehash history for all private C/startup/Scheme
callers; include TTY and known raw-table clients. Reuse Scheme-owned capture for
allocating/reentrant enumeration. A leaf C path need not acquire arbitrary new
root slots or call the broad synchronous service. Startup initialization and
live caller ownership still require explicit source contracts.

**Conditional companion B: global record registration/publication.** Preserve
VM cell initialization/count release while closing full-record publication,
dynamic/reverse readers and registry ordering. Include supported low-level fixup
cell-address consumers. This is not complete merely because Candidate A passes.

The smallest honest whole-package claim requires A and every enabled relevant
part of B; a symbol-only patch must not be called complete shared-metadata or
SMP repair. General parallel/reentrant module fixup, arbitrary host attachment,
generation replacement and unknown external raw views remain Stage-Two/API
milestones, not silently added guarantees.

Acceptance must bind the actual candidate/flags/compiler: same-name identity,
colliding names/rehash readers, raw-client migration, TTY completion, Scheme
allocating/nested/error/continuation folds, per-VM value isolation, constructor
catch-up and full-record readers, supported fixup/ABI behavior and original
stress/performance gates. At any new safepoint, require generated storage,
frame-map and reload evidence from that producer. Measure arena/table contention and O(n)
capture/traversal cost; no throughput improvement is predicted from these checks.
Use the existing source-bound native checkpoint for affected stages only. This
review does not rebuild, resume, invalidate or rewrite the other lane's native
candidate, source lock, tests, failures or numerical progress.
