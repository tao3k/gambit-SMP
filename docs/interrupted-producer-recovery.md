# Interrupted Producer Recovery

## Evidence Gap

A machine reboot or controller interruption can leave logs and output files
without a final producer receipt. Neither missing output nor absence of a live
process establishes a compiler failure, success, or permission to reuse an
artifact. The incomplete current-producer native chain is a concrete instance
of this gap, not a passed recovery test.

## Protocol Model

`models/gambit/interrupted_producer_recovery.qnt` separates process completion,
durable evidence commit, interruption, recovery, and downstream consumption.
The composed handoff obligations are:

1. A committed successful producer observation and complete output bindings.
2. Revalidated source, tool, engine, fixture, policy and artifact identities.
3. Verified process teardown before admitting downstream work.
4. The original remaining budget, including downtime; recovery never resets it.
5. The same checks repeated at downstream consumption, not only at recovery.

Hashes are abstract equality tokens; atomic durable commit, trusted clock,
identity validation and process teardown are external obligations. The model
does not prove filesystem durability, hash security, clock integrity, or SMP
correctness. Reboot invalidates host-monotonic clock comparisons: an actual
implementation must validate a durable deadline/clock-epoch contract or deny
continuation, not reinterpret an old monotonic number on a new boot.

Completed evidence can remain readable after expiration. Executing unfinished
work then requires a new explicitly reviewed campaign preserving the old
failure/interruption and original limits; it is not continuation of the expired
run. Running, failed, missing, or stale steps cannot become PASS checkpoints.

## Controls And Remaining Implementation

The positive trajectory resumes a committed, unchanged producer within its
remaining budget. Negative controls expose missing receipt reuse, identity
drift, live-process reuse and deadline reset. Another trajectory records an
interrupted running step without admitting it. These are finite protocol
controls, not real reboot tests. Exhaustive verification and framework recovery
integration remain required. No new continuation CLI, runtime patch, or admission
is established by adding the model.

## Actual Qualification

The initial recipe declaration was rejected before execution because it lacked
the mandatory locked-source producer. The recipe now materializes the pinned
thread-completion source lock and patch; it does not bypass that requirement.
The first source-bound run passed in 31.248 seconds. Source review then corrected
the start transition to retain elapsed time and added post-recovery drift and
expired-checkpoint trajectories. The revised run passed in 29.614 seconds within
the same 90-second whole limit, with eight trajectories, four decoded faulty
policy counterexamples, and terminal native ASCENT evaluation. Positive TLC
checking visited 63 distinct states (165 generated, zero queued). Host capacity
was detected, not specified as a fixed processor count.

The existing `ExecutionContext.run` now writes `recipe-process-observation.v1`
sidecars. `STARTED` has no exit code or completion claim. A returned observation
records the actual exit, timeout, log digest and available teardown metadata;
`OBSERVED` is not PASS or runtime admission. A temporary file is flushed and
atomically replaces the initial observation, leaving interrupted/missing data
unqualified. Existing subcommand identities cannot be overwritten on restart.

Three focused controls cover missing final recipe receipt, interruption before
completion, and retained timeout. The combined focused framework run passed
50 tests. A fresh seal containing this recorder
(`749da0103072477987f76904cec6b710f379d354e9113c7a063d5ad3bde0b765`)
ran the same model/ASCENT graph in 30.990 seconds without increasing any limit.
Actual TLC process records report parent reaping and process-group quiescence.

These sidecars retain observations, not authorized executable checkpoints.
Power-loss/directory durability, complete step/output commit, cross-boot clock
identity, recovery-time current-source validation, and actual reboot/interrupted
producer recovery tests remain open. In particular, the recorder cannot turn
the old incomplete `_std.c` producer into a successful current producer.

## Dependency Composition And Native Policy

`evidence/dsl/recovery.ss` keeps disposition in native ASCENT. Checked receipt,
producer success, artifact/input bindings, process quiescence, clock, remaining
budget and causal review are separate supplied facts. Missing obligations block
the checkpoint and descendants. Unknown prerequisites and dependency cycles
also block recovery. Expired evidence may remain readable without becoming
resumable. Five actual native policy tests passed in 6.500 seconds, including
all eight missing-obligation controls. An earlier invocation failed before
inference because the native CFFI provider was absent from its import path;
the corrected invocation selected the receipt-bound installed native provider,
not a Python substitute.

`checkpoint_dependency_recovery.qnt` imports the interruption model and adds
parent validity, presence, cycle exclusion and invalidation after recovery.
The composition's initial run was DENY in 7.617 seconds: all thirteen trajectories
passed, but the framework compared only the five main-module declarations and
omitted eight qualified imported tests. The generic inventory contract now
resolves parsed imports/instances and qualified names, including nested aliases;
exact passed/failed/ignored checks remain unchanged. A declaration preflight
also exposed the old unqualified-only name restriction, which now validates
every qualified identifier segment. No imported trajectory was removed.

The next actual run retained a 12.189-second DENY for Quint QNT409: a shared
imported initialization action could not be converted in multiple initialization
contexts. The composition now uses the original pure state initializer directly,
matching existing repository composition conventions and preserving the state
and assertions. With that model delta, the prior-bound campaign passed in
45.463 seconds within its original 90-second budget. It checked thirteen
trajectories, three decoded faulty dependency policies, positive exhaustive
safety (297 generated / 103 distinct / zero queued states) and terminal native
ASCENT evaluation. The engine was
`a111c9963503afb8c0f0cbe707e12ab20495435233c5d7cc1b42c1185ea40a84`.
Focused framework regression passed 54 tests in 1.473 seconds.

The native policy tests supply controlled facts, not extracted production
checkpoint evidence. The models establish bounded safety under their assumptions,
not arbitrary dependency-graph progress. Binding real interrupted step receipts
to these facts, implementing checked continuation, and actual reboot tests
remain required before claiming the recovery interface is closed.

## Existing Journal Integration Contract

Use the public `reasoning_history.append_observation` and `read_journal` APIs,
not a second recovery database. A caller-owned run lineage retains the sealed
run header and step observations before analysis. Bind the actual recipe/input,
engine, tool, dependency and output hashes. Backend metadata remains reported
process transport, not a fabricated Library result. An unbound observation is
readable history and cannot be published as verified analysis or loaded as PASS.
The journal head is not a deadline, execution permission or checkpoint selection
authority. Native recovery DSL must review the individually bound observations.

The run header now retains the original clock epoch/deadline at launch, rather
than inferring them after interruption. A read-only check confirmed
Darwin exposes `kern.bootsessionuuid`; the restricted sandbox rejected that read,
and an authorized host read succeeded. Missing epoch identity must remain unknown
and deny continuation. Do not substitute PID, wall time or an invented boot ID.
No system change was made. Cross-boot continuation remains conditional on a
separately verified durable clock contract, not merely a new boot identifier.

## Actual Run Journal Transport

The sealed launcher writes an exclusive, file-and-directory-synced immutable
`research-run-header.v1` before starting its child. It records a unique run ID,
recipe/input and engine identities, original whole/step budgets, monotonic
deadline, exact launch request and boot identity (or null when unavailable).
The worker rechecks the header hash, exact launch request and original inputs.
Each completed capability records its actual disposition and artifact bindings
in `research-step-observation.v1`, with individual prerequisite observation
references. The existing `append_observation` API retains these records in the
existing journal. No new database, published analysis, verified head, budget
reset or runtime admission is introduced. An absent prerequisite is retained as
null, never replaced by a passing ancestor. Clock-null evidence is readable;
it does not qualify cross-restart execution.

Focused regression passed 62 tests in 1.659 seconds, including a real child
`os._exit(7)` after journal commit. A new process can read the committed STARTED
record after that exit, with no terminal PASS, analysis or head. This is process
interruption evidence, not a physical power-loss or full reboot test.

The new sealed engine `fb45aed4e7aea225420d3ef57db1f7795fb52c0191b80da6ae748aa84aea58be`
ran the existing dependency-composition Recipe under its unchanged 90-second
whole budget. The actual outer observation was DENY in 18.979 seconds, exit 2,
no outer timeout, with parent reaped and process group quiescent. Source,
parse, typecheck and all declared trajectories passed; four exhaustive-control
steps reported `Operation not permitted`, and the terminal native rule check
timed out under its existing cap. All failures remain in
`.data/fixtures/checkpoint-dependency-recovery/run-header-controls`; the route
was not retried unchanged or represented as model verification success.

Reading the actual journal found one header plus nine individually retained
step observations, all bound to the original header, including all five
non-PASS results. There were zero analyses and no head. The actual boot identity
was unknown. Production fact extraction into the recovery DSL, checked reuse
of individually bound successful checkpoints, durable cross-boot time and full
native producer continuation remain open. These transport results do not close
SMP/GC correctness, bootstrap or Gerbil performance admission.

The existing successful thread-completion source producer recorded 150.026
seconds for core regeneration under its 180-second core cap, with GNU GCC and
all three concurrency switches. The incomplete current native chain therefore
cannot be diagnosed as inevitably under-budget from its missing `_std.c` alone.
Its missing terminal observation is the reason to retain uncertainty and bind
new actual process evidence, not to enlarge the cap or claim a compiler fix.

## Historical Bootstrap Input Boundary

The retained two-pass bootstrap is a historical observation, not authority for
the current framework implementation. A full-framework test exposed that its
old seed `recipes.py` hash was being compared to the evolving current checkout.
The failure remains recorded; the original bootstrap receipt and archive were
not rewritten. Six exact matching seed inputs are now independently retained in
`evidence/source-results/fixtures/sfun-owned-unwind/historical-seed-inputs`.
Its manifest binds the original bootstrap receipt hash, preserves the complete
original input inventory and grants no runtime, release or source-refinement
admission. Tests verify those actual archived bytes, not replacement hashes.
The focused bootstrap/source/framework regression passed 58 tests in 1.562
seconds. This repairs historical evidence verification only: it does not run a
new bootstrap, discharge the current native chain, or establish SMP green.

The original candidate design document is also a historical model-contract
input. Recovery notes belong here instead of mutating that signed input and
rewriting its contract hash. The failed graph export remains evidence of the
stale-reference rejection; relocating the new notes restores the original
bytes without removing information or weakening the source-binding check.
