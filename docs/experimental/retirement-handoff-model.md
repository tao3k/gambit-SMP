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

## Checked Controls

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
