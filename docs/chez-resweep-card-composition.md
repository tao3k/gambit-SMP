# Chez Resweep, Shape And Card Interaction

## Fixed Source And Actual Composition

Chez is pinned at `41d5ffca7a07cbfc8807e719dedcc70ed74811cd`.
`models/chez/resweep-source-map.json` binds source and model SHA values.
This is an explicit interaction profile, not a mechanically proved product or
refinement of `GenerationCards`, `RemoteWorkAccounting` and `HybridCollection`.
It uses the reusable pure `library/gc/ScanCoverage.qnt` predicates. No Python
producer or inference branch was added.

One old record, one remote pointer-mask owner and one remote young-target owner
pass a scan obligation through outbound, inbound, return and resweep stages.
Two rounds exercise retained generation/card obligations. Direct and buffered
remembered writes, copy/mark selection and one/two-segment profiles are included.
Mutators stop before collection. The active count is a sequential abstraction;
the standalone remote-accounting model retains the separate queue/wake controls.

## Source Reading Ledger

- `s/mkgc.ss:850-894`: a remote bignum pointer mask routes the referencing record
  for resweep. The temporary zero-length mask does not establish complete field
  coverage. Forwarding of the pointer mask is distinct from scanning the record.
- `s/mkgc.ss:2218-2288`: span metadata is shape-specific. One-bit marking can use
  fully marked intermediate segments and a non-NULL tail mask without setting a
  tail bit. Other configurations mark the relevant word ranges. The model's span
  set denotes this required metadata, not an all-one bitmap or byte-exact layout.
- `c/gc.c:2373-2415`: dirty record start recovery can cross a previous segment
  only with matching space/generation and the required bitmap boundary. The
  model excludes actual pointer arithmetic and arbitrary segment lengths.
- `c/gc.c:43-81`: bitmap presence and relocation-mode selection differ. A marked
  object spanning into a segment does not force a movable neighbor to be marked.
- `c/gc.c:137-182`: ordinary owner routing and remote metadata dependencies can
  require repeated resweeps. A universal at-most-worker-count bound is invalid;
  this model covers one mask handoff and one target handoff, not that full loop.

These sections were read against the pinned bytes. All generated object shapes,
weak-object fixed points, native fences and unbounded progress remain open.

## Counterexample Contract

Six independent mutations drop a resweep, complete a partial shape, omit trailing
span coverage, confuse bitmap presence with mode selection, clear a retained
card after promotion, or terminate with remote work in flight. Decoded traces
are finite model counterexamples, not reproduced Chez or Gambit native defects.
`NeverCompleted` is an intentionally false invariant used to obtain a concrete
mark-mode, spanning-object, two-round completion witness. It is not a liveness
proof, and does not prove every scheduler eventually completes.

## Gambit Design Questions, Not A Collector Transplant

The comparison binds the locked foreign-origin/public-cleanup candidate, whose
`lib/mem.c` SHA is `dc25c274c1f35a35f45f6f97bfe66c1c60a24536b33c48ed787a8d7589cd2f44`.
The Recipe materializes those exact bytes; it does not compile or run that GC.

| Boundary | Candidate source observation | Verifiable improvement obligation |
| --- | --- | --- |
| Identity versus readiness | `mem.c:3727-3765` publishes forwarding CAS before copying the body | Identify every forwarding consumer; preserve redirect-only use while scanning waits for the chunk publication contract. Do not add an unconditional payload wait without showing a real consumer requiring it. |
| Chunk publication | `mem.c:3414-3465` publishes links/content/tail with two barriers and matches wake registration | Retain ordering and prove the queue/termination-lock relationship across all producers and waiters; the Chez fixed-owner protocol is not interchangeable with chunk stealing. |
| Completion | `mem.c:7145-7195` rechecks all queues before decrementing active scanners | Account for private copy/scan work and transferred obligations at retirement; empty queues alone must not establish global completion. |
| Shape dependencies | Chez remote bignum masks trigger resweep | Audit Gambit's subtype, continuation and stack-map readers for actual cross-owner readiness dependencies. Do not assume Gambit has Chez's record-mask representation. |
| Generational boundaries | Chez retains cards after promotion | Preserve all younger-reference obligations where Gambit's generation/remembered-set design needs them; no automatic import of Chez card layout or marking thresholds. |

With SMP, multiple VMs and multiple threaded VMs enabled together, each proposed
change must bind its VM/processor ownership, source overlay, compiler, binary,
original failing receipt, teardown and test inventory. This study changes no C
runtime and establishes no such native acceptance.

## Performance Boundary

An owner-routing repair may trade contention for messages, bounce rescans and
load imbalance; extra readiness waits may harm uncontended copying. Measure
same-input/same-topology single- and multi-worker runs, GC pause/throughput,
copied bytes, rescans, queue traffic, retained memory and retirement costs.
Keep all failed and censored runs under the original budgets. Checker execution
time is not GC performance. No performance improvement is claimed here.

## Executed Qualification

The v2 Recipe is `evidence/research/chez-resweep-cards/control.recipe.json`.
`.data/chez-resweep-cards-002` passed in 47.365/60 seconds, parent exit 0,
no timeout, parent reaped and process group quiescent. All declared inputs were
stable. The finite safety exploration checked 104 distinct states, with zero
queued states. Six decoded fault traces have lengths 5/5/11/3/13/9 respectively
for dropped resweep, partial shape, tail coverage, bitmap mode, retained card
and premature completion. The independent completion witness has 25 states and
ends at round 2 with mark=true, spanning=true, both fields scanned, both segments
covered, no lost obligation and zero active owners. Terminal ASCENT evaluation
passed; runtime and source-refinement admission remain false.

`-001` remains a separate 52.670/60-second successful input version, whose
completion witness selected a nonspanning profile. The new `-002` invariant
specifically requires a marked spanning object to complete. The prior receipt
records both changed model/source-map hashes. These two runs cost 100.035 seconds
combined; they are not represented as one cumulative 60-second campaign.
Raw logs, step receipts, decoded traces and parent receipts remain under each
local `.data` directory; local observations are not Git-persistent admission.
