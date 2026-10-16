# Foreign-Origin Retirement Admission

## Scope And Authority

This is a proposed protocol, not a runtime fix or performance result. It follows
the official-FFI failure in [the native counterexample](callback-retirement-native-counterexample.md).
The original failing roundtrip and its budget remain unchanged; do not rerun it
against unchanged source or turn rejection into success in that historical test.

The human declined the constructor-fault fixture: no `RTLD_NEXT` interposition,
no private cleanup entry point, and no equivalent injection workaround. Native
qualification must use official loader/FFI paths. Constructor fault branches
which lack permitted native coverage remain OPEN, regardless of model results.

## Protocol

An SFUN call acquires a lease for its exact processor origin and incarnation,
before any allocating conversion or Scheme execution. A brief atomic gate covers
incarnation validation and lease publication. The gate is released before Scheme
execution or GC; the origin lease survives until the native C frame returns.

Retirement closes publication before inspecting only the origins it removes.
A live lease on a removed origin returns busy. A live lease on a retained origin
does not prohibit retirement. Retirement does not wait inside the processor
collective for callbacks which require that same collective to finish.

Allocation failure and unwind release the lease exactly once. A stale lookup
cannot publish after processor reuse. Runtime entry markers created by `___run`
are not automatically foreign-call leases: source refinement must distinguish
runtime entry from generated SFUN wrappers.

## Framework Receipt

Recipe: `foreign-origin-retirement-admission-model`, under
`evidence/research/vm-registry-reader-lease/foreign-origin-retirement-admission.recipe.json`.
Model: `models/gambit/foreign_origin_retirement_admission.qnt`.
Local run: `.data/fixtures/foreign-origin-retirement-admission/model-admission-run`.

- PASS, ten steps; whole execution 48.375055875 seconds, original 300-second budget.
- Safety: 9,593 distinct / 19,865 generated states, zero queued.
- No-stall invariant: same complete finite-state inventory. This is a deadlock
  check, not fair-scheduling temporal liveness or bounded latency.
- Six trajectory tests passed, none failed or ignored.
- Split publication, global callback ban, and unchecked incarnation each produced
  an actual negative-control counterexample. Their remaining queued states are
  not claimed as exhaustive exploration.
- Available processors were detected as 12. The model's two tokens and two
  semantic origins are finite abstractions, not hardcoded native CPU limits.
- Existing completed source was reused; no configure/bootstrap capability ran.
- `runtimeAdmitted`, `sourceRefinementAdmitted`, `releaseAdmitted`: all false.

Identity:

- Engine: `30b196894b2dea5928b8165bf5e40e6012253b20677457790daa93aa4e62f03d`
- Outer receipt: `bfab581debbfbdd4b876137dc5fa92f6c9026b3d00a64c8f43c53e6a845ab430`
- Child receipt: `861d04955bf6708c6410d30ede2620c4a55f953000315d587013439d1d0aec36`
- Source lock: `69d4ed5a544b029d5719bd363dd170f516b9bb56334d362c7290c1e7c48e7590`
- Submodule revision: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`

## Unclosed Refinement Requirements

1. Map gate reservation/publication to portable Gambit atomic operations and
   establish ordering on each supported memory model. The model uses atomic,
   sequentially consistent actions; it does not prove a weak-memory C program.
2. Bound gate and lease counters, reject saturation, and prevent incarnation wrap
   from admitting stale handles. Finite two-token exploration does not prove this.
3. Bind processor/VM lifetime before dereferencing origin state. Processor reuse
   is an atomic assumption here, not a constructor or registry-lifetime proof.
4. Cover all three generated SFUN wrapper families, conversion errors, allocation
   errors and nonlocal unwind, with exact-once release after native-frame cleanup.
5. Close publication before the retirement collective, and reopen it on every
   failure path. Preserve retained-origin callbacks and independent VM progress.
6. Use new source-bound acceptance tests for a changed rejection protocol while
   retaining the original roundtrip failure as historical evidence. Test retry
   after the C frame returns through official FFI, without private hooks.
7. Complete native correctness and performance gates. Short atomic publication
   and per-origin accounting are design intentions, not measured speed claims.

Milestone remains 3/12; this local model pass closes none of the nine full gates.
