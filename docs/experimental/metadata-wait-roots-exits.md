# Metadata Wait, Root Ownership And Exit Boundaries

## Decision Boundary

This refines the [Stage-One transaction proposal](metadata-transaction-recipe.md)
without changing runtime C/SCM, locks, TLS, generated ABI or the native lane.
The three prerequisites are connected: a wait can collect **and** execute other
collective effects; nested entry can replace temporary roots; a nonlocal exit
can bypass a C return-site cleanup. A generic lock wrapper does not close them.

The recommended first implementation shape to discuss is **Scheme-owned
preparation/wait/delivery surrounding a bounded C metadata operation**. Keep
movable objects in existing traced activations; finish/drop owned native
temporaries before entering the generic synchronous service. Once topology
protection is obtained, do not allocate through a collecting path, service
synchronous operations, call Scheme, or take an unresolved registry lock.
No specific lock, new public API, root-stack ABI or runtime patch is selected.

Gambit authority is baseline `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`
plus the [locked overlay](../../evidence/research/processor-interrupt-collective-wait/source.lock.json)
(SHA-256 `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`).
All Gambit line references below refer to that overlay. It includes `lib/mem.h`;
the candidate digest is `9bc0e1c5be068e94b1f4b73df74b9c434a02c176f4a3b9eecf2beb7f58f59c84`,
not the baseline header digest. Chez and OCaml retain the pinned revisions in
the preceding proposal. Materialized cache directories are not source authority.

## Real Wait And Collective Effects

| Source observation | Existing guarantee | What it does not guarantee |
| --- | --- | --- |
| `_thread.scm:689-703`, scheduler-object retry | Uses trylock; on failure checks the sync flag and invokes `##sync-op-interrupt!`, without ordinary interrupt dispatch at this helper. | This is a Scheme scheduler helper, not a generic C mutex wait. Its comment is not a proof that every collective is GC-only. |
| `_kernel.scm:1467-1487` | Saves RA, writes all generated registers, calls `service_sync_op`, reloads registers and RA. | Does not publish arbitrary C local variables, own someone else's `saved[]`, or clean an arbitrary C resource on escape. Generated caller liveness/frame maps still matter. |
| `setup.c:1461-1472,1350-1457` | Service starts with NOOP but participates in selecting and executing pending operations. | NOOP is the proposal, not a filter on the winning operation. The loop can resize, collect, process errors and other sync work. |
| `setup.c:804-815` | Processor-count change takes `vm_list_mut` after old-cohort arrival. | Calling service while already owning this mutex can introduce a self-dependency. This is a source-derived unsafe proposed composition, not a reproduced deadlock. |
| `setup.c:1140-1176` | A retired processor cleans its OS/interrupt state then calls `___thread_exit`, without returning. | A C catcher or code after service cannot be assumed to run on this path. |
| `setup.c:1453-1457` | Processor zero can propagate a recorded error with `___throw_error`. | Service is not generally a normal-return-only operation. |
| `setup.c:643-686` | Sync message wait uses an acquire load/predicate loop and an atomic condition wait with `sync_mut`. | This is already inside the collective tree. Calling `___sync_wait` directly is not GC participation or permission to detach a mutator. |

The existing allocation and global-list locks are not one hierarchy. In
`mem.c:1430-1500`, global registration holds `vm_list_mut` while preparing VM
segments and publishing count. A new metadata guard around that operation would
introduce a metadata-to-registry edge. Calling service while holding it adds
metadata-to-service-to-registry effects; an inverse edge elsewhere would form
a cycle. **Do not invent ranks from lock names** or claim every prospective
edge already exists in current Gambit. Actual acquisition/release locations and
GC service effects determine the graph.

Header `10981-10984` initializes the POSIX mutex with NULL attributes, not an
explicit recursive contract. The Windows branch at `11004-11007` uses Critical
Section instead. The model's registry self-wait assumes non-reentrant blocking;
it is not a cross-platform theorem that all mutex implementations behave the
same way. Never rely on unspecified/default recursion to justify this wait.

### Foreign-Frame Admission Matters

`setup.c:1518-1585` already closes SFUN admission and rejects shrinking across
a processor with a nonzero `sfun_frame_count`; exceptions reopen admission.
This is an existing compatibility guarantee, not a reason to remove it.
It does not turn service into GC-only, and arbitrary C locals/CFUNs are not
automatically leased SFUN frames. Header `14762-14775` explicitly distinguishes
ordinary `___run` markers from leases. General host entry, attachment or
cross-VM switching remains outside this repair.

### Feasible Wait Boundary

A private try/retry boundary can be reviewed for existing Scheme-facing paths:
on contention, return without a held metadata/registry resource; keep inputs in
the caller's traced activation, service only at a valid Scheme boundary, then
retry lookup/capacity/bucket predicates from current state. A retry status must
not be disguised as heap overflow or change public error/return conventions.

This does **not** solve all C callers automatically. `setup.c:1910-1915,2087,2107`
also invokes interning/global helpers during fixup; `mem.h:196-223,269` has
private entry declarations without an execution-context argument. Startup
exclusive callers and live runtime callers need distinct adapters/premises.
Before adopting a Scheme-side retry, account for every competing arena/table
entry; do not let an unadapted C path fall back to an indefinite raw wait while
another owner requires its collective participation. General reentrant/parallel
module initialization is not established by this audit.

## Fixed Slots And Nested Ownership

Header `8090-8115` writes the same three processor `saved[]` slots; restore
reads and clears them. `mem.c:7196-7207` scans these slots during GC. Thus:

- A correctly owned slot is a real GC root, not just a cached reference.
- A nested SAVE1 replaces the outer slot; nested RESTORE1 does not restore its
  prior owner. A mutex or TLS distinction cannot repair this within one pstate.
- Saving the old slot in an ordinary C local and restoring it later is also
  insufficient: that backup is not a registered moving-GC root.
- `c_intf.c:6524-6532` uses SAVE1 around marker allocation; header
  `14762-14775` clears it on allocation unwind. These are short scoped uses,
  not a nestable root-frame API to lease around arbitrary service/callbacks.

The lowest-cost first-stage candidate is to **avoid extending that slot lease**:
keep input, capture, callback and accumulator in existing Scheme activations;
audit generated liveness and RA publication at the actual service/allocation
boundary. Preserve existing non-reentrant marker allocation uses. For a C-only
helper, fixed-slot use is conditional on exclusive ownership plus audited
callee effects and no nested reuse. This audit does not establish a reusable
new C metadata wait with those guarantees.

A general explicit C root-frame chain is a separate design decision if C-only
nesting proves necessary. It would need GC enumeration, ownership, migration
and unwinder integration; a raw C-local push/pop wrapper is not enough. Do not
quietly introduce it as a small lock fix or rewrite every generated call.

## Exceptions And Continuations

Header `10034-10075` has materially different cleanup mechanisms: C++ cleanup
may use a destructor, while the ordinary C `BEGIN/END_CLEANUP` expansion only
executes cleanup at its normal end. SETJMP throws jump to the current catcher;
`ON_THROW_AUX` explicitly installs a catcher, restores it, then handles the
error. Do not assume C lexical scope supplies portable unwinding.

Generated SFUN wrappers at `10112-10128` drain their own marker/lease before
propagating error. `c_intf.c:6552-6563` invalidates the returned C activation's
marker and releases its still reference. `setup.c:3696-3815` explains and checks
return routing: a captured continuation must not return to an expired C frame.
These existing rules must be preserved, not bypassed by a generic continuation
or cleanup helper. There is no new valid-caller defect attributed here.

For enumeration, the protection and any manually owned C buffer must end
**before** Scheme delivery. Normal return, raising, nonlocal escape and later
continuation reinvocation then operate on Scheme-owned state, not a held native
guard. Explicit continuation reinvocation may legitimately repeat user effects;
the framework must neither forbid it nor manufacture an automatic replay.
Native callback compatibility tests remain necessary.

## Chez And OCaml: Exact Transfer Limits

| Reference | Transferable design lesson | Boundary to preserve |
| --- | --- | --- |
| Chez `c/types.h:363-432`, `c/thread.c:535-600` | Participation is coordinated with active-thread count, code retention, collect conditions and interrupt eligibility; allocation lock is ordered after tc mutex. | The lock-order assertion is disabled by the reviewed `#if 0`; declaration is not runtime enforcement. Condition deactivation is conditional, not an unconditional safe wait. |
| Chez `c/thread.c:209-244` | Normal activation records destroy/deactivate/noop and reverses only the effect acquired. | The alternate W/X branch differs. No generic callback attachment policy follows. |
| Chez `c/alloc.c:97-103` | Root registration has a defined collector-visible storage owner. | `S_protect` records process-global slots and initializes them; it is not a nestable local-root stack to copy for temporaries. |
| OCaml `runtime/signals.c:147-218`, `unix.c:649-657` | Default blocking hooks release/reacquire the domain lock; no-pending entry avoids dispatching pending signals there, and leave schedules later inspection. | Hooks are extensible; this is not Gambit's collective service, which can resize/exit. Do not substitute a generic pending-action dispatcher. |
| OCaml `runtime/caml/memory.h:290-330,439-454` | Root blocks link to the current root chain; returning restores the prior frame. | Copying the old pointer/value into an untraced C local is not the same mechanism. A frame chain must be enumerated and unwound by the runtime. |
| OCaml `runtime/fail_nat.c:60-90`, `fail_byt.c:40-55` | Both raise paths explicitly restore/pop local roots to the exception boundary. | A mutex is not a local-root block. These paths do not supply automatic release of arbitrary user locks; the previously noted named-table OOM unwind proof remains unresolved. |
| OCaml `runtime/callback.c:180-209` | Native callback roots inputs only for allocation and separately roots the saved stack parent around the callback. | It explicitly warns against retaining those input roots past that allocation. Root lifetime follows the activation/collector contract, not "root everything forever". OCaml effects are not Scheme's multi-shot continuation semantics. |

## Existing Models, Not A New Runtime Simulator

The additional `effectsStep` projection of
[predicate_lock_retry_rooting](../../models/gambit/predicate_lock_retry_rooting.qnt)
distinguishes collect/resize/error/retire effects. Its controls expose retained
registry self-dependency, metadata protection across service, a manual temporary
left across nonreturning exit and an erased error. The positive boundary drops
owned native temporaries before service; this is a prospective contract, not
the claim that every current caller already does so. Existing collector
participation/root/retry behavior remains in the original projection.

The `nestedStep` projection of
[ffi_gc_frame_protocol](../../models/gambit/ffi_gc_frame_protocol.qnt) adds two
logical root owners and up to two relocations. It distinguishes traced suspended
frames from slot overwrite and restoration of a stale raw backup, and checks
owned cleanup on a caught inner exception. It does not implement a new C root
stack or model multi-shot continuations, OS exits or arbitrary nesting depth.

The existing [nested unwind model](../../models/gambit/nested_foreign_unwind.qnt)
retains origin-routing, marker, exact-once cleanup and error obligations; it is
not duplicated here. Its abstract cross-processor scenario is **not** evidence
that arbitrary foreign-thread migration is supported. Existing capture/delivery
and moving-lock models remain separate dependencies, not silently composed into
a full GC proof. Lean adds an arbitrary-list traced-suffix lemma and a strict
rank cycle contradiction, both conditional on the stated abstract operations.

## First-Stage Feasibility Checklist

| Question | Current conclusion | Before C implementation / adoption |
| --- | --- | --- |
| Can service execute under a new metadata/registry guard? | No general safe contract; real resize/throw/retire effects are established. | Put service outside the owned resource boundary; verify every actual caller and lock edge. |
| Can fixed saved slots hold arbitrary nested metadata inputs? | No; overwriting and clearing are established, scanner coverage alone is insufficient. | Use existing traced Scheme activations where possible; establish liveness/RA/root ownership, not a TLS workaround. |
| Can ordinary C scope guarantee cleanup? | No in the SETJMP/C case; processor retirement may not return at all. | No native guard/manual buffer spanning Scheme callback or generic service; any unavoidable C-only ownership requires explicit exit coverage. |
| Is a small Scheme/C boundary refactor plausible? | Yes, conditionally: preparation/retry/delivery in existing Scheme paths, bounded protected C work. | Close private C/startup adapters and all shared arena readers/writers; do not expand evaluator/loader support by implication. |
| Is new-global creation in the same small scope? | Conditional follow-up; it currently combines registry ownership and per-VM preparation. | Close registry/collector ordering and reverse/generated reader publication first. |
| Is the model boundary native qualification? | No. | Exact-source forced contention/GC, rehash, errors, continuation callback, cross-VM isolation and existing performance/stress gates remain required. |

Thus Stage One can preserve the C backend and avoid a global root/TLS redesign,
but only by keeping the leaf transaction effect envelope explicit. If the
required supported C entry cannot satisfy this envelope, that entry is a
milestone decision rather than permission to hide a blocking helper inside it.
No native bootstrap, stress run or numerical progress update is produced here.
