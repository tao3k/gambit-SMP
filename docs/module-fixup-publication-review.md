# Module Fixup Publication Review

## Review Before Implementation

1. Direction: distinguish ownership of an in-progress fixup from publication of
   a complete, usable module. This addresses initialization correctness rather
   than changing the cleanup API to conceal another failure.
2. Prior coverage: linker-generation and cleanup-drain models did not represent
   failed module initialization. A bounded search of current models, fixture
   evidence and the inherited scheduler patch found no fixup-state repair.
   This is not a claim that every upstream discussion was searched.
3. Value: prevent invalid or partially fixed modules from being reported ready.
   A deterministic source-unit demonstrates a rejected-input retry defect.
   Concurrent reachability still requires auditing the loader callers.
4. Expected gain: correctness; no runtime speedup estimate. No production patch
   is selected until ownership, failure and wait protocols are verified.

## Source Facts

The checked-cleanup source lock binds the pinned submodule and cumulative patch.
`setup_module_fixup` first reads the flags, returns success if DONE is set, then
sets DONE before version/layout checks. Subsequent global, symbol and keyword
creation can also return errors after partial mutation. Label, pair, object and
frame tables are rewritten in place. A single DONE bit cannot encode cold,
owned/in-progress, fully ready and failed-with-retained-state outcomes.

`setup_modules` returns immediately on a fixup error. The dynamic object-load
caller additionally sets the linkfile version marker after `setup_modules`
without requiring a successful result. That marker may deliberately prevent
unsafe reload; its error semantics must be audited rather than simply removed.
The C source itself contains a multiple-VM atomicity TODO. The inspected Scheme
load callsites do not establish whole cross-VM serialization; absence of a lock
in those excerpts alone is not proof of concurrent reachability.

## Actual Source Diagnostic

`models/gambit/native/module_fixup_error_publication.c` includes the complete
locked `setup.c` and calls its real static fixup function. It compiles through
the selected GNU GCC build driver with the runtime's PRIMAL configuration.
A local archive copy excludes the original `setup.o` to avoid two definitions;
all other library members come from the identified source-core producer. The
original runtime's identity remains unchanged. This is a source-unit executable,
not a replacement runtime or full native VM test.

The old-version, new-version and incompatible-layout cases all return their
expected first error, leave DONE set, then return zero on the second call.
All three exit 4 as contract DENYs. They execute concurrently with worker count
derived from available processors and three independent cases. No VM setup,
GC or allocation is performed, and the five-second observation caps remain.
The earlier non-PRIMAL duplicate-symbol link denial is preserved separately;
it is not counted as a runtime failure or passing check.

Receipts: `evidence/source-results/fixtures/checked-cleanup-retained-error/`
directories `exact-setup-rejection` and `duplicate-setup-link-denial`.

## QNT Design Alternatives

`module_fixup_publication.qnt` models owner claim, metadata validation, fallible
payload preparation, completion publication and a second observer. The observed
failed-retry policy yields a four-state counterexample. Premature publication
also yields a seven-state partial-read counterexample; the latter is conditional
on an overlapping observer and is not a native-observed race.

The abstract proposal separates owner claim from READY publication and preserves
typed failure. It passes safety and weak-fair completion over 28 distinct / 41
generated states in 3.796 seconds. The owner claim is assumed atomic. Waiters
can resume after the owner completes; actual sync/GC participation and failure
rollback are not implemented by this model. Receipt and counterexamples are in
`evidence/model-results/fixtures/checked-cleanup-retained-error/fixup-publication/`.

The reviewed GHC and HotSpot notes distinguish forwarding claims, readable
payload and termination. They motivate examining these separate milestones,
but neither specifies Gambit's loader, a module-lock algorithm or this repair.

## Source Redesign Obligations

Evaluate an explicit initialization state machine with ownership, original error
identity and completion-only publication. Define whether failed partial state is
retained or rolled back; clearing DONE alone does not make rewritten references
safe for another attempt. A waiting processor must service required sync/GC
operations without holding a lock needed by the owner. Complete root visibility,
release/acquire publication and cross-VM metadata ownership require refinement.

For global reinitialization, reusable original metadata and runtime-generation
state must be separated if the API supports it; copying a descriptor alone is
insufficient because its referenced tables are mutated too. The manual documents
one setup-before-use and cleanup-before-exit sequence, not a repeated-generation
guarantee. Audit that contract before making reentry a release requirement.

This C failure path is not Darwin-specific. It was observed on Darwin with GNU
GCC, but no platform conditional controls its early DONE assignment. Do not
classify general SMP correctness as a macOS-only performance repair. Full GC,
multi-VM, bootstrap and Gerbil qualification remains open.
