# Experimental Transfer Applicability

## Scope And Meaning Of Cost

This 2026-10-19 review follows the five chains in
[Experimental SMP Design Foundations](experimental-smp-design-foundations.md).
It narrows reference-source prerequisites and existing model gaps; it does not
repair Gambit, select a collector, or take over the native owner's qualification.
The source revisions remain those in the Chez/OCaml inventories and the pinned
Gambit baseline. Current repaired overlays require their own correspondence.

"Bounded adaptation" below means a possible change at existing entry/exit,
wait, publication or cleanup boundaries, without a new scheduler, collector,
root representation or public ABI. It is an engineering scope estimate, not a
measured speedup, implementation approval or assertion that the current
candidate lacks that mechanism. A change must first show a mismatch in the
selected overlay; an already-correct path needs no duplicate helper.

"Experimental milestone" means the mechanism changes an execution, ownership
or reclamation contract. Such changes require a separately discussed proposal,
source/model correspondence, failure policy and matched native qualification.
They are not required next actions or new gates for the native owner.

## Blocking Service Ownership

Reference facts now established by reading the pinned source:

- OCaml `domain.c:1158-1278` uses a message-state protocol plus the domain lock.
  `terminate_backup_thread` requests termination; the backup loop later writes
  `BT_INIT`. Request and acknowledgement are distinct events.
- `domain.c:1372-1446,1470-1536` separates participant startup handshake from
  backup installation and user callback completion. A parent services STW
  while awaiting child startup. Child initialization failure is reported as
  exceptional completion; a startup handshake is not user-task success.
- Systhreads replace default hooks (`st_stubs.c:630-642`). Their blocking path
  saves/restores a per-thread runtime descriptor (`295-326`) and uses the master
  lock. `st_pthreads.h:123-147` passes `waiters == 0` to `st_bt_lock_release`;
  the callee parameter's name is not a reliable description of that predicate.

An unresolved reference failure branch matters: installation publishes
`BT_ENTERING_OCAML` before thread creation, and its error return does not
visibly reset that message in the function. `backup_thread_running` tests the
message, not an OS-thread acknowledgement. The POSIX wrapper directly returns
`pthread_create` status (`runtime/caml/platform.h:230-236`). This identifies a
creation-error/recovery proof obligation, not a reproduced upstream bug. Do not
use this path as evidence of reliable rollback or import it unchanged.

Existing models to reuse: `scheduler_gc_root_cohort_composition.qnt` for
serviceable waits and moving roots; `resize_startup_serviceability.qnt` for
readiness versus actual service; `resize_startup_generation_failure.qnt` for
generation-bound terminal outcomes; the existing constructor rollback models
for owned initialization. These do not yet compose a main thread, backup thread,
alternate hook, creation failure and acknowledged shutdown into one source
protocol. Do not rename a generic `joined` flag into that missing proof.

Bounded adaptation: reconcile the existing Gambit wait/startup service contract,
root publication and terminal-result observation. Keep its existing fast path;
no helper thread or new mutator-wide mutex is implied. Preconditions are a known
wait kind, held-lock set, root owner and permitted sync/error effects.

Experimental boundary: adding a backup OS thread requires exclusive ownership
of processor state, signal policy, foreign-stack roots, cancellation, creation
failure and shutdown acknowledgement. Extra threads, wakeups, stack memory and
oversubscription are real costs; the reference does not quantify them for Gambit.

## Inactive Roots And Wait Eligibility

The earlier "inactive root enumeration" gap can now be narrowed:

- Chez `thread.c:540-598` deactivates a condition waiter only when it is a
  collector wait or interrupts are enabled. An ordinary interrupt-disabled
  waiter remains active. The collector-wait exception is not a general licence
  to collect inside any lock-protected region.
- `gc.c:1235-1282` traverses the thread list for root/sweep dispatch without an
  `ACTIVE` filter. Deactivation does not remove the context's root obligation.
- `s/mkgc.ss:588-600,963-1035` maps thread objects to TC tracing and includes the
  Scheme stack, return address, C chain and virtual registers. This establishes
  the reviewed generator mechanism, not every generated instruction or the
  completeness of arbitrary foreign C locals.

The existing shared-root/cohort model already distinguishes root publication,
participation, relocation and reload. Reuse it. Still absent are the actual
inactive-membership transition, interrupt-disable eligibility, all root shapes
and a refinement from generated frame metadata to physical roots.

Bounded adaptation: make the eligibility of existing participation sites
explicit and retain publish-before-participate/reload-after-return behavior.
This adds no per-object read barrier and must not add a poll indiscriminately.
Actual costs depend on which publication/checks already exist in the overlay.

Gambit's pinned `lib/_kernel.scm:1429-1450` already saves the return address,
uses `W_ALL` before `service_sync_op`, and restores `R_ALL` and the return
address afterwards. This is a concrete reuse point, not a missing save/reload
implementation. Caller coverage, physical frame maps and permitted effects
remain separate questions.

Experimental boundary: dropping a blocked Gambit processor from the collective
requires a collector-visible root snapshot, exclusion/reentry protocol and
epoch-correct membership. Chez's active-count decrement cannot be copied into
Gambit's fixed-participant barriers as a local optimization.

## Retirement Work And Phase Readiness

OCaml `major_gc.c:56-81` distinguishes sweep debt, which decreases within its
stated cycle, from mark debt, which can increase. `caml_darken` can reopen
marking after local completion (`1550-1640`). Orphaning is not one cheap list
splice: `544-665` contains phase-dependent ephemeron work, possible major-cycle
completion and once-per-cycle finalizer counter updates.

Consequently, the non-last-domain loop in `domain.c:2262-2423` checks again
after orphaning and after pending participation requests. The last-domain
branch is different. Process-shutdown cancellation (`2432-2466`) explicitly
does not establish ordinary resource cleanup and must not qualify a reusable
VM's teardown.

Reuse `gc_sync_membership.qnt` for old/new population and startup boundaries,
`WorkObligations.qnt` for conserved private/inflight/scanning obligations, and
existing cleanup/quarantine models for failed reclamation. Membership's
intermediate-resize GC exclusion remains a premise, not a proof of an
orphaning/late-request loop. Work predicates alone prove neither enabledness
nor the weak/ephemeron fixed point.

Bounded adaptation: where the selected Gambit overlay already tracks the
necessary phase/generation/requests, revalidate the existing readiness predicate
at its actual commit boundary and preserve failure outcomes. An unversioned
cached `done` flag is not enough. This is conditional on an identified source
mismatch; no new global counter or retirement loop is prescribed here.

Experimental boundary: overlapping collection with departure, moving work
between owners or adding generational orphan queues changes the collection
protocol. It requires composition of roots, work, weak phases, membership and
failure rollback, not a wholesale port of OCaml's mark/sweep phases.

## Retained Metadata And Reuse Identity

Chez `thread.c:321-329` retains `thread_gc` because segments still reference
it, redirects its sweeper and clears the execution context. But `70-110` later
reuses that descriptor and installs a new TC. `gc.c:1015-1052,2980-3044` shows
reassignment/fallback to available scan ownership. Thus descriptor storage,
current scan owner and original thread identity are not the same thing.
Treating `creator` as an immutable original-thread identity would misread the
reference design. Complete safety of all recycled segment classes is still
unproved in this repository.

Gambit already embeds processor state in VM-owned storage
(`include/gambit.h.in:11945-11987`). An extra stable allocation layer is not
justified by pointer stability alone. VM reclamation and slot reuse still need
their real user/drain/generation contracts.

Reuse `public_vm_retirement_composition.qnt`,
`idle_processor_retirement_reuse.qnt` and `resize_queue_epoch_reuse.qnt`.
They distinguish retained users, detached idle links and delayed publication;
the latter's epochs are proposed protocol, not automatically existing source
fields. None establishes Chez descriptor recycling, every borrowed pstate or
arbitrary cross-VM reclamation.

Bounded adaptation: use existing VM storage, detach/drain operations and actual
generation/lease checks consistently. Separate logical identity from an address
used for storage/scan ownership. Do not add an epoch merely to match a model's
field name, or keep resources indefinitely to avoid a reclamation decision.

Experimental boundary: a new enduring metadata descriptor, allocator-owner
indirection or owner-routed collector requires representation/ABI, reuse,
cross-owner traffic and retention analysis. It is a distinct architecture
proposal, not a mechanical copy of Chez's `thread_gc` layout.

## Foreign Reentry And Observable Effects

Chez `thread.c:191-244` records destroy/deactivate/no-op cleanup modes in its
normal activation branch. The `WRITE_XOR_EXECUTE_CODE` alternative is not the
same protocol. OCaml's default entry/leave hooks preserve `errno` and arrange
pending-signal examination; systhreads instead save/restore the appropriate
thread descriptor under runtime ownership. Preserving one error variable does
not establish complete reentry or foreign-thread registration correctness.

Gambit's pinned SFUN macros already pair stack markers, result conversion and
error propagation; CFUN macros are a different entry mechanism
(`include/gambit.h.in:10040-10059,10338-10351`). A second activation wrapper
would risk duplicating or contradicting that ownership.

Reuse `callback_retirement_composition.qnt`, `foreign_call_admission.qnt` and
`nested_foreign_unwind.qnt` for C-frame lifetime, exact-once cleanup, failed
marker allocation and nested nonlocal outcomes. These are existing bounded
contracts; they do not imply that their proposed SFUN admission has already
been implemented or that signals, hooks and foreign observable state compose.

Bounded adaptation: reconcile ownership-specific cleanup at existing boundaries
and preserve errors/results through permitted participation. Rooted results,
origin routing and runtime entry must remain distinct; an entry is not
automatically a foreign lease. No global lock around every FFI call is proposed.

Experimental boundary: automatic entry from arbitrary external OS threads,
new public embedding semantics, or migration of a live native C activation
requires a separate admission/lifetime/ABI proposal. A movable Scheme
continuation does not make the captured native C frame movable.

## Experimental Milestone Boundaries

The bounded implementation candidates have concrete existing boundaries:

| Existing Gambit boundary | Potential bounded adaptation, only if a mismatch is demonstrated | Why its scope can remain small |
| --- | --- | --- |
| `lib/setup.c`: `start_processor_execution`, `service_sync_op`, `execute_sync_op_loop` | Reconcile readiness/service and generation-bound terminal outcomes at existing startup/wait boundaries. | No new OS service thread or scheduler is required for that contract review. |
| `lib/_kernel.scm`: `##sync-op-interrupt!` and its actual callers | Retain existing save/service/reload and check caller eligibility. | The baseline already has publication; do not add a second root mechanism. |
| `lib/setup.c`: `___vm_resize_pstate` and collective completion | Revalidate existing phase/request/owner state at the commit point, if the overlay exposes an actual stale-readiness problem. | Can reuse a current phase/epoch rather than changing collection phases; no claim that a new counter is free. |
| `include/gambit.h.in`: VM-owned processor slots and their cleanup/join callers | Reuse lifetime/drain contracts and detach stale users before reuse. | Stable storage already exists; an extra descriptor allocation is not the default answer. |
| `include/gambit.h.in`: SFUN/CFUN wrappers and error cleanup | Reconcile exact-once owner-specific release and preserved outcomes in the existing entry forms. | No second activation layer or blanket FFI lock; generated-wrapper compatibility remains required. |

These are reviewable scopes, not five established bugs or an expected speedup.
Compatibility, correctness and measured cost still decide whether any change
is worthwhile. Native execution remains with the other task.

| Optional milestone | Contract change requiring separate discussion | Required closure before a Gambit runtime claim |
| --- | --- | --- |
| Execution-service handoff | New helper service or dynamic inactive GC membership. | Exclusive service ownership, root visibility, alternate entries, creation failure, shutdown acknowledgement, weak-memory refinement and native progress/cost. |
| Retirement ownership transfer | New orphan-work protocol, enduring descriptor or allocator/scan-owner indirection. | Conserved work, phase-aware completion, delayed users, safe reuse, rollback, memory retention and native scaling. |
| Foreign runtime entry | New embedding admission or native activation/return semantics. | Nested calls, exact-once cleanup, error propagation, origin C-frame lifetime, generated wrapper compatibility and real FFI tests. |

These are alternatives/extension boundaries, not a forced three-stage workflow.
The bounded adaptations above can first be reviewed against the current
candidate without selecting any of them. No change in this study requires
shared-nothing semantics, a new nursery or a replacement GC.

## Evidence And Validation Boundary

The existing [facts](../evidence/scenarios/parallel-gc/facts.json) now attach
supplementary source premises through `transfer_premise`; the same Scheme
component joins their source sections/digests into `transfer_premise_evidence`.
Each row carries a source finding and an explicitly unclosed condition.
Withdrawal produces `transfer_unbound`, even if the core comparison remains
available. Neither absence of an unbound input nor a readable reference
mechanism proves completeness or derives `satisfies`.

Source-reading coverage is not model closure. The inventories retain
`sourceRefinementEstablished=false` and `runtimeAdmitted=false`. No model
transition or old receipt is changed, no checker is rerun to relabel a new
source interpretation as a proof, and no native bootstrap/stress stage is
repeated. Actual low-cost source repairs and measured gains remain future,
source-selected qualification work with the native owner.

Local validation of this working revision passed the existing three-suite
consumer/source checks: 28 tests, including supplementary-source withdrawal
and Session restoration. All 14 files in the Chez/OCaml source inventories
matched their declared hashes. This is not model requalification, a native GC
benchmark, full framework CI or acceptance of a proposed runtime change.
