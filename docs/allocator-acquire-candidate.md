# Scoped Allocator Acquire Candidate

## Pre-Code Decision

The current-source audit identified six ALLOC call sites: still-object accounting,
failed-accounting rollback, stack and heap msection allocation, and stack/heap
limit admission. They protect VM-shared counters/cursors. The source releases
ALLOC before invoking or requesting GC; the candidate changes neither that
ordering nor failure cleanup. The custom msection callback and any allocator
reentrancy remain separate obligations, not silently proved by this review.

The candidate follows the already checked `ticket_queue_handoff` ordering
obligation. No new copy of that abstract model was made, and no denied native
compile/bootstrap route was rerun. A ticket reservation barrier can precede
the prior holder's writes; acquisition after the serving-ticket wait is the
relevant boundary. Cached GHC section 3.2 motivates valid shared block handoff,
but does not prove this C implementation or explain a prior native crash.

Expected benefit is correctness of shared-state handoff, not a quantified
speedup. A barrier can cost time. The missing ordering is not established as
Darwin-only: observed Darwin/AArch64 assembly is not proof that another target
is unaffected. This is a correctness candidate, separate from platform-only
performance patches.

## Narrow Implementation

`patches/candidates/allocator-post-ticket-acquire.patch` changes only the threaded
`ALLOC_MEM_LOCK()` macro to a statement-safe do/while sequence: take the existing
spinlock, then issue the existing shared-memory barrier. All six ALLOC sites
inherit it. Single-threaded definitions, unlocks, MISC and the shared ticket
primitive remain unchanged. Do not apply it globally or label it production
accepted. Frozen candidate027 source and installed binaries remain untouched.

The framework `allocator-acquire` adapter verifies exact source/header audit
hashes, original handoff model receipt/logs, current model identity and the GNU
compiler selected in the source makefile. It generates an isolated mem.c/patch
and extracts the actual macro conditional for an actual-header assembly fixture.
Source, header, logs, checker, compiler and generated artifacts are digest-bound.

## Actual Checks And Limitations

Campaign001 compiled the isolated macros but initially reused a model summary
without checking its original logs. That is insufficient model provenance and
is not current admission after the adapter was strengthened. Campaign002 then
stopped before compilation because the public summary's relative logs were not
present alongside it. The original logs were recovered from
`.data/ticket-queue-handoff-001/`; no model was rerun. Campaign003 explicitly
binds that original receipt and validates both log verdicts before compilation.

Campaign003 uses the configured GNU GCC 16.2.0 and generated header. Both baseline
and candidate fixture compilations succeeded, with stable inputs. Inspection
shows the baseline ticket wait (`ldr/cmp/bne`) followed by the protected cursor
load. The candidate inserts `dmb ish` between those operations. The adapter's
status is `compiled-inspection-required`; manual assembly inspection is separate
from compilation, not an automatic runtime PASS.

Receipt SHA-256:
`136e9b10b211779ee58a1b85787de0b3a2cc3f23a139ee10c3f012a9b41757d5`.
Candidate mem.c SHA-256:
`5d09cfb0e93e74b4ee8bad9a0bc4ba370e713d037a7de0237f57ab3d246a7f7d`.
Baseline assembly SHA-256:
`754609315b4d1a5440680ca983863fd9f3319b8d4fcbb49ee2632d3f463fef17`.
Candidate assembly SHA-256:
`00a5d4c6907ccd179d613a1af49bb93584542e4012c3e0be4f2e5d2442bd88a3`.
Raw evidence stays under `.data/allocator-acquire-candidate-003/`.

18 focused allocator/binding/CLI tests passed, including exact narrow-change
checks, preservation of the single-thread conditional, duplicate/prepatched
definition rejection and call-site inventory drift. This fixture is not the
complete mem.c at its production optimization/LTO settings; no concurrent
allocation, full runtime, GC, bootstrap or Gerbil test has qualified the candidate.
Initialization, lifetime, callback contracts and MISC handoff remain open. Native
and release admission are false; a compiling candidate is not SMP/threads green.

## Full Runtime Object Check

The `allocator-object` framework adapter validates the codegen candidate inputs
and the exact narrow source transformation, then asks the configured makefile
for its `mem.o` recipe. Only input and output filenames are redirected to the
isolated candidate. It executes that compiler argv directly, with no shell and
no alternate optimization preset. Local library/include headers, compiler,
candidate, makefile and verifier are bound before/after compilation. A new
setup task, multiple recipe lines, unexpected compiler or output path is denied.

Initial manual exploration used `make -n -B`, which caused GNU make to run its
makefile regeneration recipe despite dry-run mode. The configured makefile's
digest remained exactly unchanged. The adapter instead uses `-o makefile -W
mem.c`: it forbids makefile regeneration while requesting the one object recipe.
No source/installed binary was overwritten. Do not use broad forced make for
future dry-run inspection of this frozen checkout.

Campaign `allocator-acquire-object-001` compiled the complete candidate `mem.c`
using the actual configured GNU GCC 16.2.0 rule, including `-O3`, the runtime
optimization flags, `HAVE_CONFIG_H`, `___PRIMAL` and `___LIBRARY`. Exit was zero,
no timeout, inputs stable, duration 1.603 seconds. The object SHA-256 is
`f3876eacd79261bc9e0504d252a81b3a54a74423f72db3f13dec6df3347b0633`;
receipt SHA-256 is
`2e7c25333a30a047717789c5c92270cb8adeac7f5003d1c9f7aa17b73f26f0aa`.
30 related object-recipe/allocator/source-binding/model/CLI tests passed.

The original handoff snapshot was also checked against the current QNT:
both hash to `e471a1bcf5f31d8e2670b55606aa7bb3c3b33e9ae14e040968aa8ac5d32a5947`.
Original negative and positive logs respectively contain the expected invariant
counterexample and completed safety result (13 positive distinct states, zero
queued). This is safety-only evidence, not a progress or C-source proof. The
public legacy summary is still insufficient on its own; ASCENT must not upgrade
it until original logs/snapshot are persistently attached and revalidated.

No link, new executable, concurrent allocator run, GC test, bootstrap, Gerbil
build/test or performance run happened in this campaign. The compile observation
does not explain the historical compiler crash or authorize unchanged denied
routes. Scoped native allocation/lifetime validation remains the next missing
boundary, with global correctness and performance gates still open.
