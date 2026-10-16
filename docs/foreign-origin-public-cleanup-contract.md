# Public VM Cleanup Contract

## Concrete Source Defect

The foreign-origin candidate makes public `___cleanup_vmstate` return normally
when `sfun_vm_try_close` rejects a live foreign frame. It has a void ABI, so a
caller cannot distinguish this rejection from completed cleanup. In contrast,
legacy global `___cleanup` invokes `___fatal_error` when checked cleanup fails.
The existing `cleanup_endpoint_ownership.qnt` already rejects the
`legacy-returns` policy. No unchanged negative-control run was repeated.

This is a source/API contract defect in our candidate, not a newly observed
upstream crash. It is also distinct from constructor fault injection, which
the human declined. No interposition or private cleanup test is introduced.

## Source Correction

The successor changes only `lib/setup.c` relative to the locked lifecycle
ownership candidate: rejected public VM cleanup now reports a fatal error
before returning, matching the existing legacy global endpoint policy.
The normal cleanup path, public signature and exported table layout are
unchanged. This is not a checked-error-return API; recoverable host cleanup
still requires a separately qualified ownership/API contract.

Pinned `lib/os_base.c:___fatal_error` invokes the configured diagnostic hook
or reports the error, then exits with `___EXIT_CODE_SOFTWARE`. A hook that
escapes nonlocally is a separate host contract, not a normal successful return.

- Source lock: `evidence/fixtures/foreign-origin-public-cleanup-contract/source.lock.json`.
- Lock SHA: `5d1d167f81ab6947336abdc86caf7cbe93de6c0316d0e54dd79cec65cecb517b`.
- Patch: `patches/fixtures/foreign-origin-public-cleanup-contract.patch`.
- Patch SHA: `fea80c02766c3f911520a8bf40f51534517eb6a99d3d859bd15b68747ba6b865`.
- All 22 parent source files were hash-checked; only setup differs.
- Existing framework export reconstructed the overlay from the pinned Git
  submodule and reapplied it to verify every candidate byte before publishing.
- No binary or build cache was copied. Old locks, source patches and failures
  remain unchanged. No C object, bootstrap or native execution is claimed.

## One Qualification Chain

This correction is a source successor, not an independently accepted alternative
or an excuse for another bootstrap budget. Its complete producer must qualify
the public FFI, full GSI/GSC, PR regressions, stress, lifecycle/registry, GC/FFI,
Gerbil and performance stages on the same source identity. An older C seed or
accepted runtime does not qualify these changed bytes.

The current whole-review DENY and original source-stage charge
417.0321317510097/600 remain blockers to a new integrated launch. Do not reset
the campaign, silently substitute this lock in old receipts, enlarge budgets,
or rerun known failures without admitted causal changes. Further independent
model expansion is not the critical path. Retained acceptance remains 3/12.
