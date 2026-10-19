# Root-Map Lifetime Research Validation

The [source contract](root-map-lifetime-contract.md) supplements the existing
Stage-One handoff. These are finite/conditional research results, not runtime
implementation, native fault attribution, performance or release admission.

## Current Bound Inputs And Inspected Traces

| Input | SHA-256 |
| --- | --- |
| Source contract | `f246cec9d94ec34647fc9ce7d1c9c3a2b3d6cad0f0b8602a979beb87bbd0c515` |
| Existing FFI QNT with descriptor projection | `0215dd4b9a55c66af140dd879185c362853f688e345c13ed3531c5a488c0e9b9` |
| Existing Lean module | `16c2d9ce6b5e7346f34997d08da6009d3ceca95c03a344b8abc96b99f601d527` |
| False controls | `1de67a814ac6bef9a7436fc753c7e4aed3f030fcf294deca043dcc0cf2c6baec` |
| Descriptor manifest | `ecac9fcd735c07ceb9a0fe6bebcb25b19c5ab4b8fee283c89c4c220cc7bc0f0e` |

Four expected controls distinguish availability, producer and consumer closure:

- Native-drain-only reclamation reaches empty native frames while a captured
  Scheme interpretation consumer remains live. The nine-state inspected trace
  has `retained=true`, `closed=true`, `alive=false` and no active scanner. No
  moving-GC or late-reader race is required to exhibit the missing lifetime edge.
- Ignoring an admitted scanner reaches empty native frames and a discharged
  continuation, but `scan=1` while metadata is reclaimed. The eleven-state
  inspected trace shows that closing admission and dropping Scheme reachability
  do not retroactively complete an already-admitted reader.
- Publishing unready interpretation and publishing another producer's map
  each fail after one publication transition, from a valid initial state.

The corrected safety/weak-fair completion check passed **84 distinct / 150
generated states**. Original nested-root/caught-exit/reload actions are reused,
not recreated. Explicit finite discharge and completing actions remain premises;
unrestricted retained continuations or arbitrary user callbacks need not finish.
Consumer completeness and actual map contents are not proved by this model.

The impacted nested projection was rechecked at the extended model digest:
**four expected controls**, positive safety/completion **22 distinct / 28
generated states**. The original FFI publication/RA/reload projection passed
**three expected controls**, positive safety **22 distinct / 25 generated
states**. Its original contract has no newly added liveness theorem.

| Receipt beneath `.cache/` | SHA-256 |
| --- | --- |
| `runtime-entry-models/root-map-final-source-context/receipt.json` | `c833e5f9ed5fa209aec1bb42ca227b52263ad35fde7a39f2ab2f4b1dd3122502` |
| `runtime-entry-models/root-map-preserved-nested-frame/receipt.json` | `6ee6b79a4a57d91941d0e4cb2edb91d3463e54beac75db159c38c01eea7f3125` |
| `runtime-entry-models/root-map-preserved-original-ffi/receipt.json` | `549e0aaa400881fe6562da2374e1141e50c62c04e3c1bc56af92e6dc96052f3b` |

All checks completed without timeout; native status is `not-run`. Extended
verifier receipts retain stable context and runtime/release admission false.
Host-auto scheduling selected this host's available 12 processors, not a fixed
VM/CPU/model policy. No native or bootstrap campaign was launched.

## Rejected Initial Controls And Provenance Correction

The first model (`fde1474d581c0bef55afb9da378d094a3ed717922549a3603c1d83696b308a7b`)
started the readiness/producer controls in already-invalid states. TLC reported
initial violations, but the existing receipt checker did not admit them as
stateful control evidence. It skipped the positive check. Receipt
`root-map-lifetime-consumers/receipt.json` retains
`ddc403a57590b0507e2a068c68edde3ca965b93701820b197ae2b757f9dd1f06`.
This is not a passing campaign or a native counterexample.

The final model starts valid and explicitly publishes the selected map view.
Invariant conditions and the verification framework were not weakened. The
intermediate accepted receipt `root-map-publication-and-drain/receipt.json`
retains `a5446779db553b360982830f1e48378ba3cbd0e9d03bb7a27c6311520e077c76`.
Its source locator incorrectly named `scan_object`; actual pinned Gambit uses
`scan`. The final manifest corrects that locator and was rechecked for the final
receipt above. Raw snapshots/logs stay in cache, not source dependencies.

## Guarded Proof And Existing DSL

Guarded Lean passed **26 theorem inventories**, standard axioms only, no
`sorryAx`; all **16 false controls** were rejected. Its new theorem is conditional
on complete live-consumer/dependency coverage and true interpretation availability,
not a theorem that source has established those premises.

Observations under `.cache/runtime-entry-formal/run-zefevice/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `2ce4f561a167ba5ca1444e7b01ccbbce1cfc1ddb5fda11a2eeef811f0a8847c2` |
| `axioms.json` | `7168e53ee27f90544601cd89b607c0b8df58efe1de493f5cac1907b46fd24e85` |
| `false-claims.json` | `aa86b4613b63799ed071d937984171d32b96b8e4057029577c1f42d9a5102b68` |

No guarded observation timed out or left an active process group. Focused
research checks passed **3 tests (5.793 s)**; the unchanged parallel-GC scenario
passed **1 test (0.242 s)**. These are checker observations, not speedups. Source
withdrawal/restoration and Session reuse remain in existing Scheme relations.
Six model scopes remain partial, the same three native obligations stay open,
and `satisfies=[]`. No production Python parser/inference/workflow was added.

## CI And Native Boundary

PR head `5ed74e95d8268190747b9a8622bbccef7d658b08` remained queued for framework,
patch-contracts and build when checked during this research. No result is inferred
and no rerun was triggered. A local research commit need not trigger another
redundant remote build while that run is pending.

Stage One retains generated C/descriptor/module lifetime and supported global
cleanup. It does not add hot unload, a root registry, descriptor hash ABI,
per-call metadata counters or a new universal wait helper. Native owners still
need actual map completeness/RA identity, initialized live-root and VM selector
correspondence, full consumer/lifecycle census and valid error/continuation/FFI
exits on one rebuilt revision/configuration. Original correctness/performance
gates stay unchanged. Research does not advance or reset native progress.
