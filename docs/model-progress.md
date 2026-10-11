# Explicit Model Progress

## Preserve Safety Evidence

`model_progress.py` checks declared progress obligations on unchanged QNT
models. `evidence/progress-obligations.json` declares each terminal predicate,
state-variable set, initializer and a synthetic blocked-state control.
The adapter snapshots the original module, preserving every original state
transition byte, then adds a verification-only step wrapper and properties.
The normal wrapper is equivalent to the original step. The fault wrapper
freezes one reachable nonterminal state. This is a verifier negative control,
not a reported Gambit failure or a proposed source patch.

The model's original safety receipt is not replaced or silently upgraded.
Explicit progress observations have their own schema, generated-snapshot
hashes, raw/redacted log hashes and a frozen control trace. An invariant-only
log, missing fault control, altered source context or rehashed changed snapshot
does not qualify. The publisher validates both raw and portable evidence.

## Resource User Result

The unchanged `sync_resource_users` model completes its success and partial
setup-failure branches under the following checks:

| Check | Actual result |
| --- | --- |
| Freeze after retirement with sender still published-and-locked | Nonterminal action-availability invariant rejected; control accepted |
| Normal protocol: every nonterminal state enables a step | Passed |
| Weak fairness of the complete step relation implies eventual terminal state | Passed; temporal checking completion recorded |

The positive graph contains 35 distinct / 56 generated states, depth 11,
two initial states and zero queued states. The control check takes 21.098
seconds and the positive check 16.750 seconds; these are verifier times, not
Gambit runtime or build benchmarks. Worker capacity is detected from the host.
Evidence is in `evidence/model-results/model-progress/sync_resource_users/`.

The terminal predicate is `s.phase == 4`, meaning destruction after drainage
or rollback. This finite model allows an optional waiter and one external
sender. Its global weak-fairness assumption is not a claim of fair OS or
Scheme scheduling. Mutex exclusion, atomic condition wait and the predicate
loop are modeled contracts, not proven C implementations. No unbounded
liveness, full VM lifecycle, source refinement or runtime green follows.

## Datalog Boundary

`model_progress_obligation` names declared progress checks.
`model_progress_checked` requires current source context, exact generated
snapshots, negative control and complete temporal evidence. Missing/stale
receipts leave `progress_needs_check` open. Neither a safety receipt nor a
native fixture can supply this fact.

The same main export now binds protocol-extension evidence through
`protocol_evidence.py`. It keeps `protocol_model`, `protocol_composes` and
`protocol_checked` separate from the original cases registry and native
admission. The four checked extensions cover GC epoch/work closure, scan claim
transfer, resource generations/reservations and VM switch configurations.
Their separate source/context-bound receipts are not claims of repaired C.
See `protocol-extension-validation.md` for their bounded results and source
audit obligations. Do not register them as invariant-only cases in an adapter
that would omit their required temporal checks.

No Gambit runtime edit or known failed native campaign was run in this step.
