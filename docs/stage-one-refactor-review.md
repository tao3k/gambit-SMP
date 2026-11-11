# Stage-One Refactor Review

## Decision And Ownership

This 2026-10-19 review specializes stage one of the
[three-part architecture](experimental/smp-design-foundations.md). It neither
changes the frozen native candidate nor starts bootstrap, stress or fault
campaigns. Cumulative 8/12 and current-producer release conditions remain owned
by the [native milestone](smp-threaded-vm-milestone.md#current-milestone-checkpoint).
The twelve gates are obligations, not a sequential Agent program.

| Proposal | Review decision | Benefit actually supported | Not established |
| --- | --- | --- | --- |
| Shared SFUN exit suffix | Keep as a compatibility-preserving maintenance reserve; not a fix for an identified remaining failure. | Three identical suffixes could have one definition, reducing cleanup drift. | Runtime acceleration, a GC/FFI gate closure or a current ownership bug. |
| Shared drained-cohort predicate | Defer as a standalone change. Reconsider only with a related lifecycle repair that needs a common checked predicate. | Two whole predicates and a distinct owned-recovery path can be compared explicitly. | Enough benefit to justify a rebuild merely to remove a small expression. |
| Existing-helper wait-site reconciliation | Evidence-selected investigation, not yet an implementation proposal. | Current SMP and non-SMP paths are distinguished; several already-repaired paths are excluded. | An uncovered eligible current-SMP caller or a causal link to an open native failure. |

No new QNT or Lean extension is selected by this review. The previous
composition experiments remain unadopted drafts. A model change needs a
specific source proposal or observed interaction absent from an existing model,
not simply an opportunity to produce more passing states or theorems.

## Reproducible Inputs

The exact overlay is described by
`evidence/research/processor-interrupt-collective-wait/source.lock.json`, SHA-256
`7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`,
on baseline `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Its cumulative patch is
`patches/fixtures/processor-interrupt-collective-wait-cumulative.patch`, SHA-256
`8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`.
All 26 materialized target hashes matched the lock during this read-only audit.
Source paths below are overlay-relative, not pointers into the baseline vendor
tree or a required cache directory.

| Reviewed target | Candidate SHA-256 |
| --- | --- |
| `include/gambit.h.in` | `ce419aeabb76835c5b7e69a225106b16016f4930bbc05ca66a450160d31f617a` |
| `lib/setup.c` | `9e1d3b608f8b089435a5999e74a10ffea89e83a76318a8bc8b9a9b77a2a0cce3` |
| `lib/_thread.scm` | `a63de286005ddc6660d776c7c7a3a3e62914ddf54e817a6be72d4613e4867db5` |
| `lib/_thread#.scm` | `c101ffba2a793b772ebdd8561320dc46956ef3d459e998624702e3bb2a8b3107` |
| `lib/_kernel.scm` | `dede9ab818a272de32ec4984be72fdc35ac1a442365f71603ef4bee684093bc8` |

These anchors do not authorize adopting a materialized tree after its digest
changes. The lock/patch and target bytes govern reproduction. A later candidate
needs a new applicability review rather than silently inheriting this one.

## Causal Account And Its Limits

Single-threaded execution can supply implicit ordering and exclusive access.
Parallel execution must establish them across actual participants. This is an
explanation to test against source, not evidence that all single-thread tuning
is harmful or that historical development has one cause.

| Observed coupling | Current source evidence | What it explains | What it does not prove |
| --- | --- | --- | --- |
| A waiting lock owner can require the waiter's GC participation. | `_thread.scm:690-703` provides sync-only participation; `941-1015` handles multi-thread acquisition; `_thread#.scm:1680-1734` drops a mutex ticket before waiting for a distinct thread ticket, then rereads ownership. | A generic OS wait/spin is not automatically a compatible scheduler boundary. | That every raw lock is wrong, that every wait permits callbacks, or that another helper thread is necessary. |
| GC can invalidate live Scheme locations without moving a native C activation. | `_kernel.scm:1468-1488` saves/reloads roots and RA; SFUN markers and frame admission are distinct in the candidate header. | Compiler/root metadata, participation and return-owner lifetime must agree. | That continuations intrinsically corrupt TLS or that copying a Scheme stack relocates a live C stack. |
| Empty work queues and safe retirement are different observations. | `mem.c:7350-7482` rechecks queues under protected termination; `setup.c:1045-1075` retains failed joins; `5295-5394` checks cohort, foreign admission and registry lifetime. | Local completion needs separate work, membership and lifetime contracts. | That queue checks solve weak phases or foreign users, or that current source lacks the checks it already contains. |
| Existing interfaces expose different failure policies. | Public void cleanup calls a fatal path on misuse; owned cleanup returns errors and attempts pending-join recovery; global cleanup performs child preflight before closing admission. | A single generic cleanup helper can erase ownership or rollback distinctions. | That changing the public ABI or serializing all VM operations is required. |

These are concrete design pressures behind the historical-integration
hypothesis. The open gates may still be missing acceptance evidence rather
than known runtime defects. A proposed cause must identify a failing current
path and a discriminating observation. A successful repair of one path does
not explain macOS/Linux timing differences or every SMP failure.

Reference constraints remain in the pinned Chez/OCaml inventories and the
[five-chain applicability audit](experimental/transfer-applicability.md).
Borrow the ownership/acknowledgement distinction, not a foreign heap layout.

## Recipe: Shared SFUN Exit Suffix

**Evidence and scope.** `___END_SFUN_VOID`, `___END_SFUN_SCMOBJ` and
`___END_SFUN` at header lines 10112-10128 have the same replacement sequence:
end the conversion-error loop, end the protected region, kill the marker,
leave the frame, close the successful-entry branch, then propagate the error.
The entry/marker helper at 14723-14777 separately rolls back failed admission
or marker allocation. Ordinary runtime entries are not foreign leases.

**Possible change.** Give only that identical suffix one internal macro
definition. Keep the three generated entry forms, argument/result conversion,
preprocessor nesting and source-visible macro names unchanged. Do not replace
it with a C function: the sequence closes lexical scopes and uses local names.
Do not add locks, counters, polls, atomic operations or public symbols.

**Benefit and cost.** The supported benefit is less future drift across three
forms, not lower execution cost. A token-identical expansion should introduce
no runtime operation, but that must be checked rather than assumed. A public
runtime header has broad regeneration/recompilation exposure. Validation cost
can exceed the value of this isolated maintenance edit; no duration or speedup
estimate is claimed without an actual changed candidate.

**Acceptance conditions.** Compare expanded tokens and lexical structure for
VOID, SCMOBJ and converted returns in the actual GNU GCC profile and supported
single/multiple-VM/thread combinations. Exercise normal return, conversion
error, marker allocation failure, nested callbacks and nonlocal unwind. Confirm
owner-specific frame release, marker lifetime and preserved error/result, not
just a balanced global counter. Use existing affected native campaigns and
exact-producer dependency checks; full GC/FFI is not closed by macro equality.
Any behavioral/expansion difference rejects this equivalence proposal.

**Model decision.** Reuse `foreign_call_admission.qnt`,
`nested_foreign_unwind.qnt`, `callback_retirement_composition.qnt` and
`WorkAccounting.lean`. Existing scalar `balancedNestedExitsCompose` does not
prove per-owner exact-once cleanup. If expansion is identical, a new transition
system adds no implementation evidence: generated-source/native correspondence
is the obligation. Extend an existing model only if a specific newly affected
owner/error interleaving is absent. Do not activate the draft composition merely
because this macro can be factored.

## Recipe: Drained-Cohort Predicate

**Evidence and scope.** Public VM cleanup at `setup.c:5303-5320` and global
child preflight at `5568-5582` both check processor count against one and load
`pending_join_count` with acquire semantics. Owned cleanup at `5351-5365` first
rejects anchor/non-P0 topology, attempts recovery, preserves its error, then
checks pending joins. Those paths share a condition, not an operation.

**Possible change.** A private, side-effect-free predicate in `setup.c` could
express the exact drained-cohort condition. Its callers must retain their
preconditions, recovery order, memory ordering, locking context and error
codes. Do not move join recovery into the predicate or under closed admission.
Do not combine fatal public cleanup with recoverable owned cleanup. Do not
cache a predicate result across a release, participation or registry operation.

**Benefit and cost.** Expression reuse is small; there is no measured failure
or speed benefit. This touches one translation unit instead of a public header,
but still changes a native producer and requires relink/qualification. It is
not currently worth an independent patch or a new proof campaign. Revisit it
only if a lifecycle repair otherwise duplicates or contradicts this condition.

**Acceptance conditions.** Preserve anchor/child handling, the acquire load,
the exclusive-host-owner premise and each error policy. Recovery success and
failure, pending joins, foreign-frame rejection and admission rollback must
retain their original outcomes/resources. A predicate cannot replace joining,
closing foreign admission or draining registry readers. Reuse unchanged build
stages only when existing checkpoint dependencies permit it.

**Model decision.** Existing `public_vm_retirement_composition.qnt`,
`vm_constructor_rollback_composition.qnt`, `foreign_call_admission.qnt` and
cleanup/recovery models remain the authorities for their recorded profiles.
No additional QNT/Lean is justified for an equivalent predicate extraction.
The other task's global-cleanup model/Lean/fault fixture is active work, not an
asset to edit or count as closed in this review.

## Recipe: Evidence-Selected Wait Boundary

**Current implementation.** The SMP wrappers at `_thread#.scm:1053-1093`
preserve the uncontended trylock path and use existing sync-participation
helpers on contention. Mutex transfer at `1680-1734` and `_thread.scm:4140-4160`
already drops the conflicting mutex ticket before a helper wait and rereads
ownership. These are reuse evidence, not proposals to implement the same fix.

**Excluded false lead.** `_thread.scm` starts with `(cond-expand (enable-smp`;
its `else` branch begins at 5577, before the raw `##btq-abandon!` lock at 6200
and device/mutex paths at 6453/7362. `_thread#.scm` switches to its non-SMP
branch at 2273, before the raw mutex forms at 3763-3810. Their textual presence
does not establish a missing current-SMP participation site. No change to those
forms is selected. This classification is not a proof that all SMP callers or
all build branches are covered.

**Selection condition.** A repair becomes reviewable only for an actual active
SMP wait whose owner needs its participation, with an identified held-lock set,
published/reloaded roots, permitted synchronized effects, and a stale-state
reread/error policy. Match the path to an existing failure or distinguish it
from an explicit unsupported embedding precondition. A raw lock match or a
timeout without target progress evidence is insufficient.

**Cost and compatibility.** Reuse the helper rather than introducing another
poll/lock mechanism. Preserve argument evaluation, interrupt eligibility and
the uncontended generated path. A Scheme source edit can require regeneration
and bootstrap; a call-site edit is not automatically a cheap test. Arbitrary
callbacks under held locks, blanket polling and stronger serialization are
outside the proposal.

**Acceptance and model decision.** First use
`scheduler_gc_root_cohort_composition.qnt` and the selected existing
handshake/abandonment model. Root publication, relocation and reload, ticket
ownership, normal/error exit and enabled progress must share the selected
scope. If the proposed path adds a missing failure or late-owner transition,
extend that model and its negative controls; use Lean only for a parameterized
invariant not already proved. Then validate actual generated roots and the
unchanged affected interpreted/compiled regressions/stress with the existing
genuine-progress watchdog. No specific source repair is selected yet.

## Review Checklist And Stage Boundary

This is a review checklist, not a deterministic Agent route or a new framework
gate. A proposal should expose:

- A current problem and alternatives, including leaving already-correct code alone.
- The exact branch/profile/source and whether the mechanism is already implemented.
- Supported benefit, unmeasured hypothesis, source scope and validation cost.
- Unchanged ABI, Scheme/FFI behavior, root/owner/error and concurrency contracts.
- Existing model coverage, the precise missing interaction, or why no model change is needed.
- Real acceptance obligations, source-dependent checkpoint reuse and retained failures.

New backup threads, inactive GC membership, a nursery/collector change,
per-object barriers, enduring metadata indirection or new embedding semantics
belong to the second-stage Experimental discussion. Small diff size does not
decide stage membership. Model states, passing unit tests and documentation
neither close a native gate nor explain an unresolved failure by themselves.
