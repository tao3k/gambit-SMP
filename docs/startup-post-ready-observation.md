# Startup After READY

## Same-Run Evidence

The `startup-collective-round-observation` fixture inherits the outcome-commit
repair and adds bounded C stage logging only. Its incremental core build passes
in 29.050 seconds. Host-auto native startup times out at 30.140 seconds.

All expected new members enter the initial loop, enter their Scheme startup
thunk, submit READY, and return from the READY collective call in this same run.
The observed population is 12 and the new IDs are 1 through 11; these are
runtime observations, not configured limits. The event summary derives the
expected IDs from the detected population.

No instrumented `___garbage_collect` request appears in that run. This does not
exclude direct pre-startup collector calls. It does contradict attributing this
particular wait to a missing READY publication or a logged startup GC request.
The remaining wait is after READY returns; the exact physical lock/wait location
is not established by these events.

Portable native observations, identity, build record and event summary are in
`evidence/source-results/fixtures/startup-collective-round-observation/`.

## Diagnostic Failures Remain DENY

Read-only sampling of a separately launched own child timed out inside the
sampling tool after ten seconds. No usable stack was obtained. Its own process
group was identity-checked, killed, and subsequently confirmed absent. The
sampling denial is retained; it must not be cited as stack evidence.

The next semantic fixture, `startup-scheduler-boundary-observation`, adds Scheme
markers around processor lock reacquisition and interrupt enablement. Actual
Scheme-to-C regeneration produced all three markers, but the incremental core
build timed out at 180.068 seconds. It has no admitted runtime and was not
executed. Its generated C is not a manually edited authority or a completed
bootstrap. Preserve its interrupted objects as denied cache, never valid inputs.

Each fixture is reproducible from the pinned submodule and its cumulative
overlay/source lock. The C diagnostic cap of 32 log rounds bounds output only;
it neither caps processors nor changes protocol iteration count.

## Model Requirement

`resize_startup_serviceability.qnt` separates initialized queues and a completed
READY round from a processor being able to service subsequent synchronous work.
The current C publication protocol does not establish that stronger state.
The old queue-only control permits caller return before serviceability. The
fixed-design action is an explicit source-refinement obligation, not a claim
that interrupt enablement alone implements it. Physical lock waits, GC polling,
scheduler entry and old-member participation must refine that action together.
Type checking passes. Bounded Rust simulation reproduces the queue-only
counterexample and finds no violation in the fixed-design control (80 samples,
20 steps, seed 1). These receipts do not establish exhaustive temporal or C
source correctness and are not registered as `protocol_checked`.

This model requirement supplements the outcome-publication contract; it does
not retract its finite ordering result or upgrade it to full startup correctness.
Native scheduler boundaries, full GC composition, failure rollback, bootstrap,
upstream and Gerbil acceptance remain open.
