# Callback Return Ownership

## Source-Backed Route Review

This is a new concrete failure boundary, not an attempt to fix global setup
reentry. The existing callback diagnostic reports generation-zero encoded exit
71. A bounded LLDB observation of its identified binary instead exposed
`Can't convert result to C int`. At the return-position converter breakpoint,
the Scheme result argument was `0xffffffffffffffdc`, the configured tagged void
value, not the expected processor count. The debugger deliberately killed the
stopped process: its exit zero is not a passing native test. Historical binary
provenance was not rebuilt in this diagnostic.

Pinned `_kernel.scm` return-to-C handler overwrites R1 with the origin processor
ID before calling `##c-return-on-other-processor`. That primitive invokes the
one-argument migration hook; `_thread.scm` installs `##thread-migrate-to!`, whose
resume action returns void. No original result is retained in this path.
`___SFUN_RESULT` subsequently reads R1 for C conversion. This explains a
source-shaped route to the observed void; it does not yet prove that the
historical exit 71 took that exact route.

This route is worth repairing for return-value correctness, not estimated
performance. It has not previously been represented by the linker-generation
or cleanup-disposition models. Expected speedup is unknown. The unconditional
software-exit breakpoint did not capture exit 71 and remains a failed diagnostic,
not a source repair.

## Model Before Source Repair

`callback_return_owned_result.qnt` retains the result as an explicit owned root
while routing back to the C frame's processor. The model varies both processor
identities, three opaque value identities and local/migrated returns. Its
lost-result control characterizes the destructive R1 path. Its unrooted control
rejects merely saving a raw address across a modeled moving collection.

The fixed policy proposes passing the value as a Scheme
argument, preserve it through the migration hook and return that value on the
owner processor. Existing one-argument hook behavior should remain unchanged.
Lexical retention is not itself a native GC-root proof: generated stack maps,
continuation save/restore, relocation and exception unwinding must be checked.
The model abstracts C-stack liveness, hook errors, arbitrary nesting, multiple
values, processor retirement and real C memory; these remain open requirements.

The QNT campaign completed both required counterexamples (5.150 and 5.139
seconds) and positive safety/fair completion (3.889 seconds). The canonical
receipt is `evidence/model-results/fixtures/callback-return-owned-result/ownership/receipt.json`.
This is a bounded ownership model, not native GC acceptance.

The new baseline fixture forces migration before returning integer 42. Both
local-return controls, with and without forced GC, pass. Both forced-migration
controls return encoded71 and native exit4. Four simultaneous processes share
host-derived CPU capacity (three processors each on the observed 12-CPU host).
GNU compilation took 0.669 seconds; each observation took about 0.524 seconds.
The old source/toolchain and fixture identities remained stable. These are
fresh source-shaped failures, not a replay claim about the old binary.

The candidate now implements R2 preservation before the cross-processor call,
passes `(id result)` as two Scheme arguments, and returns `result` after the
existing one-argument hook. Only `_kernel.scm` differs from the cumulative
checked-cleanup parent. The semantic source lock and patch are under
`evidence/fixtures/callback-return-owned-result/` and `patches/fixtures/`;
fresh source-core regeneration passes in 165.848 seconds and sealed inspection
reports PASS/CURRENT. All four unchanged integer-return controls now pass,
including both previously denied migrated returns.

The extended fixture also returns a 4096-character heap string through C string
conversion. Its migration hook performs another `##gc` after migrating to the
C-frame owner, while the wrapper's saved result remains live. All four mode
combinations pass with exact length/content and integer 42 (0.524-0.528 seconds);
GNU fixture compilation takes 0.659 seconds. Each process is reaped with a
quiescent group; source, compiler, driver and fixture identities remain stable.
Physical relocation was not recorded, so this is heap-object survival under
requested GC, not a proof that this particular string moved.

Portable producer summary and separate baseline, integer and hook-GC receipts
are under `evidence/source-results/fixtures/callback-return-owned-result/`.
All remain non-admitted observations. Native suites, complete embedding error
paths, nested/multiple-value callbacks, retirement and full bootstrap/Gerbil
are still open. This threaded return path is platform-independent source logic;
the repair is not a Darwin performance workaround.

Native evidence must force migration before returning a known value, rather
than rely on observed timing. Bind fixture, generated C, compiler, driver,
source lock and new binary. Keep local-return, migration and forced-GC controls;
none may silently substitute a fixed result, void signature or pinned single
processor. Full SMP/VM/bootstrap/Gerbil gates remain open.
