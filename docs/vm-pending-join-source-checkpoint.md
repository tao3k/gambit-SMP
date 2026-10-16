# Pending Join Source Candidate

## Exact Candidate

The pinned submodule plus `evidence/fixtures/vm-pending-join-retention/source.lock.json`
reproduces the cumulative candidate in `patches/fixtures/vm-pending-join-retention.patch`.
Compared with resize-grace, only `include/gambit.h.in` and `lib/setup.c` changed.
The patch SHA-256 is
`35c12643db42372f116fdff1d1b72899c334b9527f2aa2752d98dbd39b8bd7e9`.
Previous locked sources, default-profile producer and passing receipts are not
modified or replaced.

Each retired processor has an owner-only pending-join flag. A VM summary count
is published before reduced active membership. Successful joins transfer and
clean memory before clearing ownership; failures preserve both flag and count.
New collective resize calls reject pending ownership before entering their
normal protocol, preventing reuse of those slots. Under exclusive lifecycle
ownership, owned cleanup retries departed joins before closing registry
admission. Failure returns without freeing the VM. Normal cleanup checks the
summary count and avoids an all-slot recovery scan when it is zero.

This is not a complete global cleanup repair. Root cleanup, legacy void cleanup,
creation-failure rollback, all embedding callers, ordering assumptions and actual
injected failure behavior remain open. The existing root checked-cleanup path
retains resize errors; a successful root cleanup also visits other VMs, which
still needs a pending-ownership audit. The published count guard's collective
agreement requires source/native verification, not just the finite model.

## Actual Qualification

Existing framework recipe: `vm-pending-join-retention-bazel-objects`.
Run: `.data/fixtures/vm-pending-join-retention/bazel-objects-run`.
Engine: `03ebd972aaabc622edb2ab899f17ed2f6b336bc23ddaceb4c5249bc37a1918a3`.
The unchanged Bazel GNU profile, inherited registry/retirement model controls,
new failed-join controls and real object compilation passed under the original
300-second whole budget and 90-second object caps. Whole time: 145.293469
seconds; setup.c compilation: 2.892403 seconds; mem.c: 4.023446 seconds.
All processes exited zero without timeout. Source-lock and recipe contract tests
also passed. Patch reverse applicability was checked against the isolated source.

Objects are not linked runtime acceptance, bootstrap, fault injection, complete
SMP green or performance evidence. Do not import the passing resize-grace
binary as this candidate's runtime. Next validation must complete source review,
bootstrap and exact-artifact fault injection through the same framework.
