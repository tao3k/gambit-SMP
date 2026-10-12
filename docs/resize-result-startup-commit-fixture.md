# Resize Result Startup Commit Fixture

## Review Before Repair

The existing dispatcher returns each processor's local resize status. The outer
noncombining operation returns the winning requester's local result, so a non-P0
requester can receive success when P0 failed processor initialization. The prior
result distribution and membership models identify this failure; this fixture
refines the transport to the actual synchronous-operation tree and startup loop.
Expected performance benefit is zero; this repairs correctness, not build speed.

## Source Protocol

After local resize returns, P0 proposes a distinct noncombining
`OP_VM_RESIZE_RESULT`; other retained processors propose NOOP. Newly created
processors participate from the existing startup NOOP loop. The tree selects
P0's result proposal and broadcasts the status through the existing payload
channel. No unsynchronized VM-wide result field or combining thunk is added.

The old retained processors then continue the outer loop with their pending
requests. The new processor has consumed the commit operation without starting
its body and returns to its startup loop. An all-member NOOP round cannot finish
until every participant has passed the result round. The requester receives the
authoritative status, and startup can then proceed to its thunk.

Failed pre-publication growth keeps old membership. Successful shrink uses the
reduced membership after retiring processors exit and successful joins complete.
The existing ignored-join bug is deliberately not treated as repaired by status
transport: permanent join failure, safe resource retention, user drain and reuse
still require a separate complete ownership protocol.

## Model and Native Checks

`resize_commit_startup_round.qnt` checks result identity, startup ordering,
participation, and temporal progress for successful growth/shrink, failed growth
and a second status round. The barrier is modeled as coherent and atomic;
successful retirement is an explicit premise. Three negative controls cover
local result loss, a missing startup participant, and premature startup.

The native recipe projects complete locked `barrier_sync_op`, sync macros,
`execute_sync_op`, `execute_sync_op_loop`, and `start_processor_execution`.
Actual pthreads execute the projected tree and loops. Resize work is injected;
message flag fields use an atomic shim. This verifies source control flow, not
the original field layout's C weak-memory refinement or complete VM resizing.
The parent runs the same harness and assertions as an expected-failure control.

The first compilation projection selected the loop's forward declaration rather
than definition, pulling in unrelated functions. That DENY is retained; the
corrected recipe locks the exact complete definition. The initial model local
failure control used a shrink scenario; its correction uses source-reachable
pre-publication growth failure. Both records remain distinct, and only the
corrected model is authoritative for this fixture.

## Reproduce and Limits

Source authority is the pinned submodule plus
`evidence/fixtures/resize-result-startup-commit/source.lock.json` and its overlay.
All parent files are preserved except `lib/setup.c`. Generic recipes are
`resize-result-startup-commit-tree-loop` and
`resize-result-startup-commit-objects`. Portable observations bind model, source,
recipe and harness identities without depending on a numbered cache directory.

No full GC phase, foreign callback reentry, permanent join failure, linked
source-regenerated runtime, bootstrap, Gerbil or performance admission follows
from these checks. The parent retirement counterexample remains a blocker to
full SMP/multiple-threaded-VM acceptance.
