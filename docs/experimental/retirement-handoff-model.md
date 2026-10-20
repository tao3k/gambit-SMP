# Retirement Handoff Composition

## Classification And Reuse

This is an **Experimental future protocol**, not a repair or qualification of
the current native candidate. Its root handoff and pre-admission handler-quiet
conditions are not yet established as one implemented Gambit protocol. Current
failure models and native manifests stay unchanged; the owner's reported 9/12
is neither increased nor re-certified here. No runtime source, native producer,
checkpoint, build profile or acceptance budget is changed.

The [QNT model](../../models/experimental/retirement_root_handler_composition.qnt)
imports the existing
[public retirement composition](../../models/gambit/public_vm_retirement_composition.qnt).
It starts **after valid exclusive-owner and joined-cohort preflight**, with no
active, pending or foreign direct users. The imported actions retain registry
admission, reader leases, resource release and memory reclamation. This is not
a reachable failed-join recovery model. It adds logical borrower, publisher,
payload-root and old-handler obligations without copying the base state machine.

The [Lean companion](../../models/experimental/lean/RetirementHandoff.lean)
reuses [WorkAccounting](../../models/gambit/lean/WorkAccounting.lean). Its root
predicates are logical availability contracts, not moving-GC root registration,
cross-VM transfer, generated frame maps or a C memory-model refinement proof.

## Combined Obligations

| Obligation | Modeled distinction | Still required from an implementation |
| --- | --- | --- |
| Exceptional exit | A borrower can leave normally or nonlocally; a still-live payload needs a destination root before its source root disappears. | Actual traced slots, unwind/continuation cleanup and source-instance correspondence. |
| Borrower drain | A completed payload does not imply all borrowers have returned. | Complete borrower census and an actual return/retirement handshake. |
| Root transfer | A destination can retain the live payload after its original owner exits. Resources and memory remain live until the payload is discharged. | Collector-visible publication; a root in the same VM cannot outlive that VM. |
| Old handler quiet | An OS handler may have been delivered before registry admission. Uninstall cancels undelivered work, not already delivered work; a lease census can be empty while that handler remains. | Actual OS delivery identity, completion/quiet mechanism, generation and module lifetime. |
| Release | Borrower, publisher, payload and handler obligations must all be discharged before resource release and reclamation. | Complete inventory, C ordering and all real entry/exit paths. |

The finite model uses sequentially consistent atomic actions and one abstract
member per owner class. Its progress property assumes weak fairness and a finite
environment in which a delivered handler can finish. It does not establish OS
fairness, unbounded populations, performance, physical GC or native correctness.
The Lean facts similarly assume the declared inventory is complete; they cannot
discover an omitted owner. Logical root availability is weaker than the QNT
resource-lifetime invariant and is not an implementation refinement theorem.

## Reference Source Correspondence

All source locations use existing pinned submodules, not mutable cache copies:
Gambit `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, Chez
`41d5ffca7a07cbfc8807e719dedcc70ed74811cd`, OCaml
`46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`.

| Source | Established fact and transfer limit |
| --- | --- |
| [Gambit mem.c](../../vendor/gambit/lib/mem.c):4928-4964 | Pstate cleanup frees still objects/RC state; VM cleanup destroys allocation and scan synchronization, cleans processor zero and frees msections. The baseline has an explicit other-processors TODO. This does not prove current-overlay quiescence or root handoff. |
| [Chez thread.c](../../vendor/chez/c/thread.c):261-341 | Thread destruction processes remembered data, closes local allocation and transfers guardians before freeing the thread context. `thread_gc` is retained/recycled because segment metadata may still name it. This supports separating context lifetime from outstanding ownership; it is not a Gambit transfer implementation. |
| [OCaml domain.c](../../vendor/ocaml/runtime/domain.c):1346-1390 | Termination publishes a rooted result, signals joiners and holds the termination mutex until domain teardown finishes. The retained mutex can then be unlocked without accessing the destroyed domain. This is a source-specific publication/retirement contract, not a proof of Gambit's join-error recovery or arbitrary OS callback quiet. |

These references motivate obligations, not replacing Gambit's C backend, FFI,
proper tail calls or continuations. No new lock, TLS policy, collector ABI or
shared-nothing requirement is selected by the model.

## Initial Checked Controls At 16d0fb7

The executable campaign is
[test_retirement_handoff.py](../../models/experimental/test_retirement_handoff.py).
It uses existing checker/process libraries and a host-derived control schedule.
There is no separate production Python inference or current native admission.

| Initializer | Actual result | Decoded distinguishing state |
| --- | --- | --- |
| `initFixed` | Safety and conditional completion pass; 2,323 generated / 588 distinct states, zero queued, 8.846 s. | Complete finite state-space check, not merely a successful sample trace. |
| `initDroppedRoot` | Expected counterexample, 9.786 s. | Nonlocal exit drops the source root with a live payload and no destination; storage is still live. |
| `initPayloadForgotten` | Expected counterexample, 10.164 s. | Borrower/publisher have left, destination root exists, but resources are released while the payload is live. |
| `initHandlerForgotten` | Expected counterexample, 11.095 s. | Registry lease is absent and handler uninstalled, yet an already delivered handler remains at resource release. |
| `initBorrowerForgotten` | Expected counterexample, 8.190 s. | Payload is consumed and handler quiet, but resource release occurs while the borrower remains. |

Seven guarded Lean theorems pass: traced handoff permits owner exit; missing
handoff loses a root; same-VM rooting cannot survive destruction; borrower drain
does not discharge payload; registry drain does not imply handler quiet;
complete discharge eliminates every declared obligation; balanced exceptional
entries compose. Printed axioms contain only `propext` and `Quot.sound` where
needed, with no `sorryAx`. This proves the stated conditional contracts, not
the completeness of native roots or exception paths.

Receipts remain in the framework cache under
`experimental-retirement-handoff/run-1odlfpm0/` (QNT) and
`experimental-retirement-handoff/run-gwkp6jq4/lean.json` (Lean). The QNT receipt
binds model SHA-256
`d1b9b663e872770b9fd8a180faff49b3793e07a9cedaf18f7db6ffa7fbf77235`
and Lean source
`5fe5c6a0c4771f9c48f4a9917988fa60597144fb36598d1d2cde6b9a4f9cb91a`.
Cache availability is not proof authority: the source, proof and explicit
campaign are versioned so the check can be reproduced. Later assertion changes
must not be presented as if those historical campaign inputs had changed.

## Retained Rejections And Open Work

The first composition attempted to reference the private nested state of
`cleanup_error_gc_drain_composition`; Quint rejected it with `QNT404`. The
existing model was not modified to expose private state. This composition uses
the public retirement interface instead and explicitly narrows its scope to
post-preflight; cleanup/join error composition remains open.

The first checker launch was rejected by the sandbox at the local socket bind,
before TLC ran. Guarded Lean completed in that attempt. The QNT retry with local
endpoint permission completed successfully in 29.805 s overall. Neither the
construction rejection nor the socket failure is a native failure or an erased
semantic counterexample.

Before an implementation Recipe can be qualified, map every actual borrower,
publisher, generated root and old handler to these obligations, establish C
publication/order and abnormal-exit behavior, and bind the applicable executable
and configuration. Use current failure models for concrete source repairs; do
not promote this speculative composition merely because its finite controls
pass. The [existing handoff](native-failure-producer-handoff.md) retains the
current failure distinctions and alternatives. No bootstrap or native stress
test was run for this research campaign.

## Independent Synchronization Keepalive

The source audit now follows the OCaml result handshake to its last root owner,
not just to publication. `domain.c`:1132-1146 registers both `callback` and
`term_sync` as generational global roots. At 1372-1388, the terminating domain
extracts `mut`, tears down the domain, then unlocks that retained synchronization
object. At 1450-1455 it explicitly delays `free_domain_ml_values` until **after
that unlock**: otherwise removing the last root can allow a finalizer to destroy
the mutex while it remains locked. This is an independent root owner surviving
the domain; it is not a root inside freed domain memory.

The other side is explicit too: [domain.ml](../../vendor/ocaml/stdlib/domain.ml):291-303
loops on the result under `Mutex.protect`, with `Condition.wait` releasing and
reacquiring the mutex. Result publication or a broadcast does not alone release
the joining consumer. [sync.c](../../vendor/ocaml/runtime/sync.c):64-67 destroys
the mutex in its finalizer; 103-111 stores a separately allocated synchronization
handle in the GC-managed wrapper. Retaining a raw C handle is therefore not the
same as keeping its finalizer-owning wrapper reachable. Conversely, a moving
wrapper does not mean that its separately allocated C handle moves. These are
distinct storage/interpretation and lifetime obligations.

The existing Experimental composition now retains `syncRoot`, `syncLive` and
`syncLocked` separately from VM memory and the payload's same-VM roots. Teardown
must precede unlocking the joiner, and the synchronization root must outlive the
locked use. A finalizer may run after the last modeled root is dropped; normal
completion does **not** require that it actually run. The model starts with an
already-owned synchronization lock; lock acquisition/failure and other potential
owners are not proved by this finite abstraction.

Two controls distinguish the omitted edges:

- `initSyncRootForgotten`: VM teardown completes, the last synchronization root
  is dropped before unlocking, and possible finalization destroys the locked
  resource. This is an allowed counterexample schedule, not a promise that a
  native GC will finalize immediately.
- `initJoinReleasedEarly`: the synchronization object remains rooted/live, but
  unlocking releases a joiner before VM teardown. Root liveness alone does not
  establish the termination ordering.

Four additional Lean contracts reuse `Rooted` and express retained synchronization
storage, loss of last-root protection, the fact that a held mutex need not
release the joiner, and the violation caused by early release. They are
conditional logical contracts, not a proof of native finalizer scheduling.

## Waiting Participation Is A Different Obligation

Chez `thread.c`:553-595 registers collector waiters separately, deactivates only
under `is_collect || DISABLECOUNT(tc) == 0`, restores the mutex owner/count after
the OS wait, then reactivates and removes the waiter registration. `types.h`:
371-400 retains current code with `Slock_object` while changing the active count
under the tc mutex. [gc.c](../../vendor/chez/c/gc.c):3004-3025 uses the waiting
contexts to assign parallel sweepers and also maps remaining threads. The waiter
list is therefore not by itself the complete root graph or universal permission
to deactivate any lock waiter.

OCaml `domain.c`:115-150,1162-1220 supplies a different mechanism: a backup thread
handles incoming STW work while the main thread blocks, but only with the domain
lock; it uses a try-lock on that path so entry can signal it without blocking.
The state transitions at 2191-2226 are distinct from the systhread save/release/
acquire/restore hooks in `st_stubs.c`:295-324. Copying either mechanism into Gambit
requires the actual collective participant and root/lock ownership contract,
not a TLS substitution or an unconditional OS wait.

For current repair, the existing `predicate_lock_retry_rooting` model already
separates a collecting owner, a parked-participation premise and stale derived
indices. The existing retirement/recovery models already distinguish terminal
retention from a reachable successful join. This research does not modify their
active source-bound inputs or pretend that these reference mechanisms supply
the missing Gambit source events. The synchronization-keepalive composition
remains Experimental until an actual candidate's root/resource ownership is
mapped. No new current-native gate or progress increment follows.

## Gambit-Specific Handoff And Refutation

The pinned Gambit POSIX-thread layout differs from OCaml's wrapper/handle design:
`gambit.h.in`:10893-10914 declares inline `pthread_mutex_t`/`pthread_cond_t`
storage; 11518-11527 embeds allocation/scan synchronization in
`___vmstate_mem`; 11947-11979 embeds that memory state inside the VM. `mem.c`:
6738-6767 decrements the scan-worker count, signals peers at zero, and then lets
those peers wake, inspect the predicate and unlock independently. Thus zero
scan work is **not** a complete wait-return census. Cleanup at 4959-4964 destroys
that synchronization and frees VM memory resources. These are baseline source
facts, not a demonstration that the current repaired overlay violates ordering.

The existing `scan_barrier_quiescence` model and the handoff's normal collective
return bridge already distinguish callback return, upward aggregation and
population change. Reuse those current executable obligations; do not infer a
missing final barrier just from the zero work counter. The new Experimental
`syncRoot` is not a request to add an OCaml global root around Gambit's embedded
mutex. A real candidate must keep the containing storage alive through its last
waiter/user, or establish a separately reviewed owner for extracted storage.
A GC root for a Scheme value is not automatically a lease on an enclosing C VM.

| Concrete ownership case | Low-cost handoff condition | What would refute transfer of this mechanism |
| --- | --- | --- |
| Current callback/cohort protocol already drains every user | Preserve its normal callback-return/tree-gather closure and inspect only exceptional or uncounted users. | A counter at zero without the relevant callback/return census; missing participant; unmatched source incarnation. |
| C-owned synchronization embedded in the VM | Retain the actual container until all OS waits, holders and delayed users finish; use the current retirement owner contract. | Retaining only Scheme payload roots; assuming broadcast joins waiters; freeing the container while a raw pointer escapes. |
| GC-managed wrapper owns a separate C handle | Keep an independent traced wrapper owner through last use/unlock and preserve the wrapper-to-handle relation. | Only a raw handle remains; last root is removed while a finalizer may destroy a locked resource. |
| Runtime generation has already become terminal | Treat physical quiet, module freshness and successful public recovery as separate obligations. | Assuming the reference root lifetime proves old-handler quiet or creates a source-reachable retry. |

No newly inspected observation identifies a current 9/12 failure caused by the
wrapper-finalization case. Consequently that mechanism stays Experimental; the
current failure models and their manifests are not modified merely to show a
larger model count. A larger refactor, generalized foreign attachment, new root
ABI or backup-thread topology still requires a separate design milestone.

## Follow-Through Validation

The extended campaign completed in 74.618 s using the existing 30-second
per-check guards and host-derived control plan, with no timeout or skip. The
QNT positive checked 2,367 generated / **612 distinct states**, zero queued,
safety and conditional completion, in 18.308 s. All six decoded controls matched
their specific expected causes. In the two new traces:

- Root omission reaches `memory=false`, `syncLocked=true`, `syncRoot=false`,
  `syncLive=false`, with no early joiner release: possible finalization after
  VM retirement destroys a still-used synchronization object (14.448 s).
- Early unlock reaches `memory=true`, `syncRoot=true`, `syncLive=true`,
  `syncLocked=false`, `badJoinRelease=true`: independent keepalive does not
  establish teardown-before-consumer release (14.710 s).

Eleven guarded Lean theorems print no `sorryAx`; printed axiom dependencies are
limited to `propext` and `Quot.sound`. Existing Scheme relations check all source
hashes, expose three transfer conditions/six partial model scopes and keep all
four native obligations missing with `satisfies=[]`. Source withdrawal/restoration
and repeated query reuse remain checked by the same campaign. The receipt family
is `experimental-retirement-handoff/run-8409bwp5/`; model SHA-256 is
`a61dbdd039260f2d1faaac920904c84e936beb74e37be78d2637e6b4143af9fb`,
Lean source SHA-256
`ae5ec5c924c584b1c73bfb97e514a71c8a61c323b9661f4121e3815bafeeb5c7`.
The earlier four-control results and rejected attempts above remain historical,
not relabeled as this extended campaign. Subsequent documentation/provenance
additions and source-withdrawal assertions are checked separately with the Scheme
consumer; the QNT and Lean source identities remain unchanged. The formal
campaign receipt is not relabeled with these later context input identities.

Separately, published research HEAD
`16d0fb7fbfa099c0a06e4b388a616fefed1c0545` has successful
[framework CI 39352626804](https://github.com/tao3k/gambit-SMP/actions/runs/39352626804):
1,809 tests, zero failures/errors/skips, complete inventory and unchanged inputs,
400.999872718 s, `frameworkValidated=true`, `runtimeAdmitted=false`. Artifact
`12234321031`, `test-result.json` SHA-256
`83835f2cc2463dce5f7f351de3e46e00614abb63d00e6d25b79e5cf0e4f28f79`.
That remote pass covers its exact published head, not this later local extension.
No native build, bootstrap, stress test, debugger or runtime source edit was
performed for this follow-through.
