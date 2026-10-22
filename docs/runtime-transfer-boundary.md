# Runtime Transfer Boundary

## Meaning And Reuse

This 2026-10-19 qualification adds a finite interface-observation model and
conditional Lean obligations to the five existing Chez/OCaml transfer chains.
It does not replace their transition models, model a second collector, or
establish source refinement. Reference mechanisms and experimental milestones
remain in [Transfer Applicability](experimental/transfer-applicability.md).

`runtime_transfer_boundary.qnt` observes an initially ready boundary, permits
an adversarial change, then tests the commit policy. Its work predicate imports
the existing `WorkObligations` library. One work token and two epoch roles are a finite
abstraction, not a host CPU limit. Weak fairness establishes completion of
this observation/commit protocol only, not eventual GC, mutator or join
completion. Native reachability of the observations remains a separate task.

The original producer-lifetime and resource-composition Lean obligations are
reused. New theorems intentionally expose premises instead of claiming the
runtime maintains them. Nested-exit balance is arithmetic composition of
per-entry balance and preserved errors, not an exact-once ownership proof.

## Five Correspondences

| Chain | Boundary property and false policy | Lean theorem | Existing transition model to retain; still open |
| --- | --- | --- | --- |
| Service ownership | Announcement without acknowledgement cannot admit service. | `announcementWithoutAcknowledgementIsNotReady` | `resize_startup_serviceability` and `scheduler_gc_root_cohort_composition`; exclusive main/helper ownership, hook composition and failed creation acknowledgement. |
| Inactive roots | Published roots do not authorize concurrent mutation. | `rootsDoNotPermitConcurrentMutation` | `scheduler_gc_root_cohort_composition`; real caller eligibility, retained physical frame maps, withdrawal and synchronized reentry. |
| Retirement work | Private, outbound, inbound or scanning work revokes cached readiness. | `reopenedWorkRevokesZeroCount` | `gc_sync_membership`, `gc_recursive_queue_wait`, `WorkObligations`; phase/membership composition, weak/ephemeron fixed point and memory ordering. |
| Descriptor reuse | A captured generation cannot validate its successor. | `reuseRevokesOldIdentity` | `public_vm_retirement_composition`, `idle_processor_retirement_reuse`, `resize_queue_epoch_reuse`; all borrowed users, physical reuse and actual source identity protocol. |
| Foreign exit | Release only acquired participation and preserve the delivered error. | `balancedNestedExitsCompose` | `callback_retirement_composition`, `foreign_call_admission`, `nested_foreign_unwind`; ownership transitions, nonlocal C-frame lifetime, generated wrappers and signals. |

Names in the last column refer to existing QNT files in `models/gambit`, except
the shared `models/library/gc/WorkObligations.qnt`. Their old results and partial
scope are unchanged. In particular, generation equality is an abstract identity
contract, not a prescription to add an epoch field to every native object.

## Current Candidate Correspondence

The reviewed input is not the baseline submodule. It is the 26-file overlay
declared by
`evidence/research/processor-interrupt-collective-wait/source.lock.json`
(SHA-256 `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`),
with cumulative patch
`patches/fixtures/processor-interrupt-collective-wait-cumulative.patch`
(SHA-256 `8e6d68b028264cc9ae8225008af1ad3f09a6dfebe6d35268296c85e53fd0d23d`).
All 26 materialized target digests matched this lock during this audit. A cache
location is not a source identity or a tracked reproduction prerequisite.

| Candidate source anchor | Already present; do not duplicate | Remaining correspondence |
| --- | --- | --- |
| `lib/setup.c:930-981,1280-1457` | Returned startup workers keep servicing; terminal results check generation and acquired status; collective drain precedes error delivery. | All startup/failure outcomes and service-owner transitions. |
| `lib/_kernel.scm:1468-1488`; `lib/_thread.scm:690-703` | RA/register save-service-reload and common lock-wait sync participation; not arbitrary callback execution under held locks. | Every actual wait caller, held-lock set, physical root map and permitted effects. |
| `lib/mem.c:7350-7482` | Local scanning precedes idle; termination mutex plus per-queue locks recheck work before scanner-count withdrawal. | Every private producer, late request, weak phase and weak-memory publication edge. |
| `lib/setup.c:1045-1075,5295-5394` | Failed joins retain ownership/error; cleanup rejects outstanding cohorts/joins and requires admission closure before reclamation. | Failed initialization/join rollback, cross-VM users and reclamation paths beyond the reviewed happy path. |
| `include/gambit.h.in:10112-10128,14723-14777`; `lib/setup.c:1518-1588`; `lib/c_intf.c:6511-6570` | Admission rollback, owned frame/marker cleanup and resize reopening are implemented; ordinary run markers are not foreign leases. | Complete generated-wrapper and nested-unwind correspondence; no missing marker-allocation root patch is inferred. |

This is source-reading evidence, not proof that these implementations satisfy
all five contracts. No C/SCM patch, bootstrap or native stress run belongs to
this qualification. It does not change the other task's native milestone count.

## Small Refactor Recipe: Shared SFUN Exit Sequence

This is a review-only Recipe, not an executable research-kernel Recipe or an
approved native patch. The demonstrated issue is duplicated code, not a proven
runtime failure or speedup.

- Input: the source lock and cumulative patch above; header target SHA-256
  `ce419aeabb76835c5b7e69a225106b16016f4930bbc05ca66a450160d31f617a`.
- Scope: only the identical cleanup suffix of the three SFUN END forms at
  `include/gambit.h.in:10112-10128`.
- Possible transformation: share `END_TRY`, marker kill, frame leave and error
  propagation without changing order, expansion or ownership. No new atomic,
  lock, field, ABI, entry protocol or blanket FFI serialization.
- Invariants: allocation-failure rollback, ordinary-run exemption, nested owner
  routing, error/result behavior and all generated wrapper forms stay intact.
- Model correspondence: the foreign-exit boundary plus existing admission and
  nested-unwind transitions; conditional arithmetic alone is insufficient.
- Before adoption: compare preprocessor expansions for all affected forms and
  supported GNU GCC flag profiles; run atomic generated-wrapper/FFI regressions,
  then the affected native qualification against the exact changed candidate.
- Cost: a small header edit can invalidate many generated objects. It is not a
  cheap validation claim. Do not modify the native owner's frozen candidate.
- Reject the transformation if expansion, owner routing, failure behavior or
  a native acceptance result differs. Keep that failure as new evidence.

Helper service threads, dynamic inactive membership, enduring descriptor
indirection and orphan-work protocols remain separate Experimental milestones.

## Observed Qualification

Command: `env PYTHONPATH=src .venv/bin/python -m unittest tests.test_runtime_transfer_formal`.
The guarded consumer uses existing process/checker libraries, hashes inputs
before/after and sizes parallel checker jobs from available host processors.

| Check | Observed result |
| --- | --- |
| Quint/TLC positive | 119 generated, 39 distinct states, queue exhausted; `safe` and fair finite `completion` accepted. |
| Quint false policies | All five accepted as expected decoded counterexamples: announcement-only, roots-only, cached-ready, address-only and unconditional exit release. |
| Lean positive | Nine named theorems elaborate; their inventories contain only `propext` and, where used, `Quot.sound`, with no `sorryAx`. |
| Lean false propositions | Six controls reject the actual false conclusion, not an import or missing-instance error. |
| Incomplete proof | `SorryWitness` elaborates but exposes `sorryAx`; it is not accepted as proof evidence. |
| Focused consumer | Two formal tests and three dependency-contract checks pass in 14.857 seconds. This duration is not a runtime optimization result. |

Qualified inputs (SHA-256):

- QNT: `3ca8b5b26a49229bf433059ee7b836f3692aa5b960bd821532ce925fb1b18077`.
- Shared work library: `db071876688cb73bca81be61c71fae4f70847358ec54a374d88bd5e3754e71cd`.
- Lean: `7d6a00be12e01ad2283469df505f4e728468356db927c6df0c2b1eecfc113f0e`.
- Consumer: `b5fb46e5a47067ed5eb5d7473114e434eb444dbc8210b869b8166e3a880c6406`.

Lean uses the pinned LeanPoo dependency and toolchain described in
[Work Accounting](lean-work-accounting-obligation.md). Raw checker logs, decoded
traces and process receipts are retained in the existing cache archive; this
portable summary does not replace those records or constitute sealed admission.
The final run also includes `tests.test_lean_dependency_contract`. Quint is
0.33.0; the TLC jar SHA-256 is
`880c0b2b72354816f12e9a9755829f2907071e9a181ffea1937954c23d54739d`.

Earlier failed checks remain recorded: an existing unchecked Bool-case proof
did not elaborate; initial added proof syntax was invalid; initial negative
controls lacked explicit reducible definitions and failed for the wrong reason;
the sandbox initially denied TLC's local listener. Those runs were not accepted.
The corrected controls require a false-proposition diagnostic and exclude a
missing-instance diagnostic. Dependency resolution failures were likewise not
proof passes. No old receipt was overwritten or native failure erased.

A broader design-reasons regression initially rejected the updated Chez source
inventory against a retired view's old digest. The original inventory from
commit `7da20ce` is now a test-only snapshot selected through the existing
historical pointer mechanism. Its digest remains
`0140b8eb6a24c5133f3826bcc716990fd8773ebc67f00453fbddb9c3bd1431a5`;
neither the historical view's digest nor its assertions are changed. Historical
reading remains unavailable to current action admission.
