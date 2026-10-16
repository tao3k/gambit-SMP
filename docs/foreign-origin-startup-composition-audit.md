# Foreign-Origin Startup Composition Audit

## Source Boundary

This audit concerns Gambit SMP, processor growth and official FFI callbacks.
It does not change Python, History, ASCENT loading, budgets or runtime admission.

The source authority is submodule revision
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus
`patches/fixtures/foreign-origin-lease-admission.patch`, locked by
`evidence/fixtures/foreign-origin-lease-admission/source.lock.json`.
This is not a claim that the pin is today's latest upstream revision.

## Confirmed Source Sequence

1. The candidate's `___current_vm_resize` calls `sfun_vm_try_close` before
   `current_vm_resize_admitted` and reopens only after the collective returns
   or throws. Closure applies to growth as well as shrinkage.
2. `___sfun_frame_enter` rejects a closed admission gate before publishing the
   per-origin frame count. Consequently, a fresh SFUN entry during this interval
   is rejected even on a retained processor.
3. `start_processor_execution` in pinned `lib/setup.c` establishes TLS, joins
   the startup collective and executes its Scheme thunk through `___run`.
   Ordinary runtime-entry markers are intentionally not SFUN leases.
4. The candidate keeps the old cohort participating until new processors have
   published their startup status. Its `_thread.scm` changes publish readiness
   after queue initialization and before enabling interrupts and scheduling.

These observations establish an admission window, not a native deadlock or a
demonstrated public API regression. In particular, an SFUN rejection is not
equivalent to blocking, and an internal startup thunk is not evidence that a
public caller can install arbitrary startup callbacks.

## Model Coverage Gap

`foreign_origin_retirement_admission.qnt` represents shrinkage followed by
atomic reuse. Its retained-origin trajectory acquires a callback lease *before*
closing admission. It does not compose processor growth, readiness publication,
fresh SFUN entry and collective completion.

`resize_startup_serviceability.qnt` distinguishes initialized queues from actual
serviceability, but contains no foreign-frame admission state. Passing these
models separately therefore does not qualify this interaction.

## Required Mainline Verification

Follow-up source inspection found no SFUN call in the standard startup thunk
before readiness publication. The window described above is not, by itself, a
justification for changing growth admission. See
[the owner-retirement composition](foreign-origin-owner-retirement.md) for the
actual source-directed verification completed next.

- Resolve the supported callback contract during an active resize: explicit
  busy/retry may be valid; unconditional successful entry must not be assumed.
- Compose the existing readiness and foreign-origin protocols. Cover retained
  origin, new origin, callback rejection/unwind, readiness failure and retry
  after reopen. Preserve GC participation and exact-once lease release.
- Distinguish short publication exclusion from holding an admission gate across
  a collective. If narrowing closure is proposed, prove that it cannot admit a
  callback onto an origin being retired or reused, nor expose unready queues.
- Bind any native acceptance to the completed producer of these exact source
  bytes. An older seed runtime does not qualify the changed Scheme startup code.
- Use official loader/FFI only; retain the existing failed roundtrip unchanged.

No source fix, new model pass, native pass or performance benefit is claimed by
this audit. The retained accepted producer remains 3/12; this audit closes no
full gate. Framework blockers do not authorize bypassing causal review.
