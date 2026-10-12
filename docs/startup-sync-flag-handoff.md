# Startup SYNC notification handoff

## Source-bound cause and repair

The `startup-sync-flag-observation` diagnostic recorded P0 leaving the resize
loop with its SYNC interrupt flag still set, then entering `service_sync_op`
alone. All newly started processors had returned from READY, reacquired their
scheduler lock and enabled interrupts. The process timed out; this is retained
negative evidence, not a successful startup.

`on_all_processors` raises SYNC on every member. Old resize members have already
consumed the original notification in their first loop iteration. Later READY
requests rearm those members, but the original first-iteration-only reset does
not consume the new notification. The clean `startup-sync-flag-handoff` overlay
resets the flag after receiving a collective READY operation as well as on the
first iteration. It adds no diagnostic logging and does not disable SMP flags.

Authority is the pinned submodule plus
`evidence/fixtures/startup-sync-flag-handoff/source.lock.json` and
`patches/fixtures/startup-sync-flag-handoff.patch`, not a cached build directory.
The parent is `collective-startup-outcome-commit`.

## Actual native checks

The runtime uses GNU GCC with SMP, multiple VMs and multiple threaded VMs.
Processor capacity is detected for each execution. This host returned 12;
that value is an observation, not a configured concurrency limit. Native
fixtures derive their population from the actual VM processor count.

| Check | Mode | Seconds | Result |
| --- | --- | ---: | --- |
| Processor population | interpreted | 1.246232 | observed population matches host selection |
| Repeated grow/shrink/forced-GC slot reuse | interpreted | 0.643688 | PASS |
| Repeated grow/shrink/forced-GC slot reuse | compiled | 1.368661 | PASS |
| Still-object survival | interpreted | 0.060627 | PASS |
| Mixed-key table GC | interpreted | 0.981912 | PASS |
| Still-object survival | compiled | 0.708145 | PASS |
| RC ownership transfer and survival | compiled | 0.623877 | PASS |
| Mixed-key table GC | compiled | 1.034372 | PASS |

The compiled controls took 7.478490, 17.408439 and 8.476545 seconds to compile,
respectively. Compilation and execution are separate measurements. Their exit
codes were zero, no timeout occurred, and all captured process groups were
quiescent. Source, fixture and runtime identities were checked around execution.
The core component build passed in 15.977750 seconds; it is not a fresh complete
two-pass bootstrap or a Gerbil performance result.

The additional compiled reuse control compiled in 6.714091 seconds and passed
unchanged in 1.368661 seconds. Its independent receipt is `compiled-reuse.json`.

Durable receipts are in `evidence/source-results/fixtures/startup-sync-flag-handoff`.

## Model boundary and remaining requirements

`resize_startup_sync_flag_handoff.qnt` reproduces the old stranded-notification
failure in five distinct TLC states. The fixed bounded protocol passes safety
and temporal completion over 13 distinct states. The published model receipt is
registered in `evidence/protocol-bundles.json` for source-bound Datalog admission.
Both old and fixed results are retained.

This model has old/new cohort representatives and a request arriving after exit.
It does not yet refine independent barrier participation and notification reset
windows. In particular, READY, GC and ERROR arriving before reset, between local
reset and operation commit, and during uneven cohort exit need explicit request
slot ownership, priority, generation and quorum reasoning. Pending nonwinning
requests must survive a reset; asynchronous sources must not be assumed away.

Other open requirements include startup failure rollback and quarantine, retired
requester continuation handoff, arbitrary cohort/physical tree-barrier refinement,
full upstream native coverage, complete bootstrap and Gerbil build/test. These
component passes do not admit the runtime or release as fully green.

## Request-window source audit

The source audit must distinguish notification bits from owned operation slots.
`barrier_sync_op` first gathers proposals through the tree, chooses the smallest
operation code, and publishes that operation to children. `execute_sync_op_loop`
then resets its local interrupt flag and executes the selected operation.
Only a winning originating slot (or a combining operation) is changed to NOOP;
a nonwinning local `sop_ptr` survives into the next iteration. ERROR has code 0,
GC code 14 and READY code 24, so represented pending ERROR/GC proposals outrank
READY rather than being erased by a READY notification reset.

This source ordering is not yet an interleaving proof. Different members return
from the tree at different times, and a processor that exits can begin a later
request while another is still completing its previous local phase. A stronger
model must represent per-member proposal publication, reply receipt, flag reset,
operation-slot commit and exit independently. Same-thread operation-slot
ownership may constrain which arrival windows are possible; that constraint
needs source binding, not an atomic global-round assumption. The pinned source
search finds the SYNC notification raised by `on_all_processors`; the exported
generic interrupt API still prevents treating arbitrary foreign notification
producers as impossible without a caller contract.
