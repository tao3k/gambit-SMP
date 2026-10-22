# Root-Map Lifetime Research Validation

The [source contract](root-map-lifetime-contract.md) supplements the existing
Stage-One handoff. These are finite/conditional research results, not runtime
implementation, native fault attribution, performance or release admission.

## Predecessor Bound Inputs And Inspected Traces

The following results bind the predecessor inputs, not the extended live-slot
model documented below. Their hashes and rejected observations are retained.

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
This is the earlier observation, retained as history; the completed framework
result is recorded below rather than being replaced by a passing local result.

Stage One retains generated C/descriptor/module lifetime and supported global
cleanup. It does not add hot unload, a root registry, descriptor hash ABI,
per-call metadata counters or a new universal wait helper. Native owners still
need actual map completeness/RA identity, initialized live-root and VM selector
correspondence, full consumer/lifecycle census and valid error/continuation/FFI
exits on one rebuilt revision/configuration. Original correctness/performance
gates stay unchanged. Research does not advance or reset native progress.

## Live-Slot And Publication Composition

The follow-up audits the pinned Gambit return-kind/liveness -> slot/bit/chunk ->
label/RA -> `mark_frame` chain and the Chez protected-root scanner. OCaml's
root-list mutex is not held over the final generational root-value assignment;
its dynamic-root scanner traverses a head snapshot outside that mutex. Chez's
parallel sweeper explicitly excludes `tc_mutex` and current Scheme-thread
context assumptions. These observations constrain transfer premises; they are
not new faults attributed to the reference runtimes or the current Gambit run.

| Extended input | SHA-256 |
| --- | --- |
| Source contract | `4f76145099ae17211d454fd4aff2c7f017588fd69160e485b4c481c53f80e9ce` |
| Existing FFI QNT | `0fee27339553c0ad7b6e1d2046701b9e063eb3cc91fdbb7f692b9848c82db0e3` |
| Existing Lean module | `4c97099c303800d1b582393c7b28d7cbf6ccdd704609294ee8839c95fd754881` |
| False controls | `caef40a14ed5abb01f2715fe20b452a40616ee6efc70c987dbf88aab5da5d79b` |
| Descriptor manifest | `21e6ec652e6a9b132b141dd1444d83182b7df9c4e1d54f7d2535239e9cdeefe2` |

The descriptor projection now has **five expected controls**, with positive
safety/weak-fair completion still **84 distinct / 150 generated states**.
The inspected new three-state trace starts valid, publishes an incomplete map,
then enters the inner frame: live abstract roots are `{0,1}`, mapped roots are
`{0}`, while `producer=1`, `ready=true`, `alive=true`, `published=true`.
Thus producer/readiness/lifetime do not establish map completeness. This is an
enumeration-contract counterexample, not physical scanning or a compiler bug
reproduction; concrete offsets, liveness, encodings and moving GC remain open.

The unchanged nested projection passes four expected controls and positive
**22 distinct / 28 generated states**. The original FFI projection passes three
expected controls and positive **22 distinct / 25 generated states**. No new
liveness theorem is assigned to the original projection.

| Receipt beneath `.cache/` | SHA-256 |
| --- | --- |
| `runtime-entry-models/root-map-live-slot-composition-permitted/receipt.json` | `4d0c9ffeb2e1837bcba47e2866d504c33346afd48e3d5c923be0e162d5ecf3bc` |
| `runtime-entry-models/root-map-live-slot-nested-regression/receipt.json` | `00b32e92bd8392e1ffe31252939ef811d7ec6ac7f51a375a07361aa0c8865ffa` |
| `runtime-entry-models/root-map-live-slot-original-regression/receipt.json` | `67ade19ceb7bbd556d1a275f0c9ed7cf93b0f25331601528b4502a5f0065ceea` |

All model checks completed without timeout. Extended verifier contexts stayed
stable, runtime/release admission remains false and native status is `not-run`.
The first sandboxed launch at `root-map-live-slot-composition/` failed to bind
the verifier's loopback socket before a model result; it is not a model failure
or pass. The permitted launch above used the same inputs and existing checker.
Host-auto scheduling shared available cores among controls; these model
campaigns ran sequentially. This thread launched no native build.

Guarded Lean checks **27 theorem inventories**, standard axioms only and no
`sorryAx`; all **17 false controls** are rejected. `generatedMapRelocation`
specializes the existing coverage-composition proof for arbitrary slot/value
types. It requires both complete mapping and correct mapped-slot relocation;
neither is inferred from equal producer identity. Guarded observations beneath
`.cache/runtime-entry-formal/run-4pbq8lix/` have these hashes:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `e34c5ce2c5828eb962466ac173bfc4aa6282af54a8cf008d4e79fa149aaf22fa` |
| `axioms.json` | `28acfb6ecdd3df926599674ec53445dc45852f27125fc413159b8777763837b8` |
| `false-claims.json` | `9ff7ec7c1ecb9a8a5798b483bd92dfec83f5237875231c7a3f6695d35566629b` |

Focused research checks passed **3 tests (13.742 s)** and the unchanged
parallel-GC evidence scenario passed **1 test (0.940 s)**. These are observations,
not speed claims. Scheme source withdrawal/restoration and Session reuse cover
the added source premises, without adding Python inference or another DSL.
Six model scopes stay partial, the same three native obligations stay open,
and `satisfies=[]`. The implementation Recipe now requires all three witnesses
together: actual live-slot completeness, payload-specific publication and
consumer lifetime. Full C/compiler/native refinement remains the handoff.

## CI Research-Contract Corrections

The framework job for PR head `5ed74e95d8268190747b9a8622bbccef7d658b08`
(tested merge `49c16cb69ba26fdc0c3ed35a45ec91de5f21ecca`) completed **FAILURE**:
the receipt reports 1809 test outcomes, four failures, zero errors/skips and no
timeout. This is not the earlier Lean download failure. The job installed tools
and reached framework validation. Original evidence remains available as the
[job](https://github.com/tao3k/gambit-SMP/actions/runs/39279220786/job/118150235876)
and [artifact](https://github.com/tao3k/gambit-SMP/actions/runs/39279220786/artifacts/12200790732).
The downloaded ZIP stays in cache (`research-ci/framework-39279220786.zip`),
SHA-256 `d682e84d92ae33f42c46087a82c228f5f30f53538674957488c329c4bdfe06c3`;
no extraction of the 1688 cached files or commit of raw CI output is required.

| Failed test contract | Actual failure | Research-only correction |
| --- | --- | --- |
| FFI frozen control binding | Historical trace `f0a453...` was compared to the extended current model. | Reuse `evidence_index.export`'s verified historical binding, check the predecessor hash and preserve every state/predicate assertion. |
| FFI select composition observation | The observed import hash was compared to today's imported file. | Validate the historical import against the already registered predecessor snapshot; preserve the record, original hash, failed native observation and open requirements. No current imported-model pass is inferred. |
| Positive Lean libraries | An exact one-library assertion rejected the added research library. | Check that configured positive targets are declared libraries with source files and that control modules remain excluded; do not require the old fixed library count. |
| Cleanup admission proof startup | Fresh proof execution lacked the compiled LeanPoo module. | Build the existing `WorkAccounting` target through Lake under the existing guarded build envelope before the unchanged guarded proof/false-control elaboration. Let Lake resolve the pinned dependency; do not require a generated cache manifest as a pre-build source input. |

The same pre-build cache-manifest dependency was removed from the existing
runtime-entry proof harness. Versioned proof sources, toolchain and package
configuration remain bound. No production Python inference, runtime patch,
native Recipe or watchdog was changed. Proof elaboration still has its original
15-second, heartbeat and recursion guards; the dependency build uses the
existing research harness's separate 120-second build bound.

An initial local correction ran 11 tests and failed one assertion because it
compared a tuple returned by the existing relation export with a list. That
repair attempt is not a pass; the comparison was corrected without changing
any historical evidence or expected SHA. The subsequent focused runs passed
15 tests (7.618 s), then **16 tests (9.276 s)** after the added source premises.
The final set includes the four CI regressions, source withdrawal/restoration,
Session reuse, guarded Lean/false claims and unchanged parallel-GC evidence.
These local results do not change the completed remote FAILURE into success,
nor constitute a clean Linux/full-framework rerun.

The [handoff](stage-one-handoff-recipe.md#exposure-is-not-initialization-success)
now records actual Gambit/OCaml exposure cutpoints and Chez external callback
ownership. Existing early-publication, canonical-retention and descriptor-drain
models are reused; the actual cross-registry/host-capability census remains
open. No QNT/Lean model or prior model receipt changes in this follow-up. All
three native obligations and six partial model scopes remain unchanged.
