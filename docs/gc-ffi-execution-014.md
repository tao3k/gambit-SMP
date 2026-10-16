# Actual FFI Execution Attempt 014

The paper/source audit is in `gc-paper-source-refinement-014.md`. This file
records later execution without editing that already SHA-bound source note.

## Causal Change

After 005's source-custody DENY, Working added hash-bound historical workspace
inspection and explicit planned producer selection. The FFI Recipe now names
`scope-reviewed-completed-producer.json`, whose original bootstrap receipts and
runtime identity are unchanged and whose input archive is separately bound.
The new framework seal is
`8171d293f08905970a3d29cf307dec2f254712ea81189ae0fb8b5f27d28429ec`.
This is not a new Gambit collector or a new Library build.

## Actual Result

`.data/experimental-scheme-ffi-006` is DENY: parent exit -9, timeout true,
20.389 seconds including termination, original execution ceiling 20 seconds,
parent reaped and process group quiescent. No child terminal receipt exists.

The individually retained step receipts report:

| Stage | Outcome | Actual stage seconds |
| --- | --- | --- |
| Locked source reuse | PASS, partial observation | 10.485798 |
| Completed producer binding | PASS, partial observation | 7.653520 |
| Scheme/C FFI | Not completed | Only compiler identity probes exist |

No compilation, loaded module, GC loop or final fixture answer is claimed.
The partial steps do not confer whole-run admission or final input stability.
The unexecuted phases are not invented as failures of the runtime itself.
Old 001-005 identities, failures and logs remain unchanged. Every earlier
attempt's cost remains recorded; a new attempt is not a claim to fit all retries
inside the first 30-second campaign.

## Budget And Custody Boundary

The source/producer setup consumed 18.139 seconds before the pending fixture.
`completed()` calls inspection and runtime identity checks more than once;
the source reuse lease is acquired after its first completion inspection.
Request-local leased tree reuse cannot legitimately cache files outside the
lease or eliminate historical receipt/archive/engine checks. These observed
timings identify preflight cost, not a measured collector slowdown or a proven
single hot function. No per-stage timing from a profile is fabricated.

Further optimization must demonstrate the same full identities and final SHA
checks under the same caps. No direct-binary bypass, altered old receipt,
unbound archived input or silent fallback is acceptable. The existing route
must not be rerun until a real input/tool change justifies it.

## Current Consumer Observation

After adding fixed-source reasons and the 005 denial to the Evidence view,
five real Library/Action/source-withdrawal regression tests passed with no skips
in 8.731/15 seconds, exit 0, no timeout, quiescent. Raw logs are in
`.data/gc-design-source-audit-014`. That inventory is not full consumer, current
graph, three-flag lifecycle, GC/FFI correctness or performance acceptance.
