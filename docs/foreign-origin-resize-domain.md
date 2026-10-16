# Foreign-Origin Resize Domain

## Path Review

This is a correctness boundary, not an expected throughput improvement. Existing
resize/foreign-frame models select legal target populations; the new boundary
model adds negative, zero, legal and above-maximum input classes. A bounded
search of the existing source audits found no matching lower-bound repair.
No previously failed bootstrap or stress route is retried.

The pinned upstream public `___current_vm_resize` clamps its upper bound but
does not reject nonpositive input. Our foreign-origin candidate adds
`sfun_vm_try_close(vm, target)`, whose loop starts at `target` and accesses
`___PSTATE_FROM_PROCESSOR_ID(i, vm)`. Negative input therefore reaches a negative
slot before the collective. Zero can proceed toward a zero population. These
are source-derived observations, not reproduced crashes or attributed PR988
reports. Ordinary startup calls resize only when its computed count exceeds one;
this finding does not explain the historical valid-input stress timeouts.

## Model And Candidate

`foreign_origin_resize_boundary.qnt` models two semantic slots, not a host CPU
limit. The old negative-index and zero-population controls both produce
counterexamples. The positive checks safety and weak-fair terminal completion
for rejection, busy and successful resize. Upper-bound clamping is preserved.
It abstracts the actual collective, OS scheduling and physical memory ordering.

The existing framework accepted all four checks in 13.453 seconds, with stable
context, 15-second per-check limits and host-auto worker allocation. Portable
evidence is published and registered in `evidence/protocol-bundles.json`.
Native/refinement/full-SMP obligations remain open in that bundle.

The current source workspace was reused in place. All 22 parent files were
hash-checked before editing; only `lib/setup.c` changed. The entry rejects
`target_processor_count < 1` with `___INVALID_OP_ERR` before VM lookup,
foreign gate mutation, slot scanning or collective work. TLS acquisition from
`___PSGET` still precedes validation and retains its valid-caller precondition.
The framework exported a pinned overlay and reapplied every byte:

- `evidence/fixtures/foreign-origin-resize-domain/source.lock.json`
- `patches/fixtures/foreign-origin-resize-domain.patch`

No source lock or historical receipt was overwritten. This is a successor in
the same original qualification chain, not a fresh bootstrap budget or an
admitted runtime. No C object compilation or native execution is claimed.

## Public Native Regression

`models/gambit/native/foreign_origin_resize_boundary.scm` uses the declared
public `___current_vm_resize` through normal generated FFI. It asserts rejection
of -1 and 0, unchanged population, and a subsequent valid same-population resize.
It requires the default multiple threaded VM profile and does not invoke the
research cleanup helper or use loader interposition. Do not run its invalid
requests on an unfixed historical runtime. It is prepared, not executed.

This guard does not resolve VM/root lifetime, join recovery, complete GC,
the STALE retained producer or the nine remaining full native gates. The
original cumulative source-stage budget is unchanged.
