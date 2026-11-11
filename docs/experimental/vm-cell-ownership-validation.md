# VM Cell Ownership: Research Validation And Handoff

This qualifies the [ownership contract](vm-cell-ownership-contract.md), not
runtime code, a reproduced native corruption or a performance improvement.
The existing shared-metadata/constructor composition is extended in place.

## Bound Inputs And Inspected Controls

| Input | SHA-256 |
| --- | --- |
| Ownership contract | `e59ec8cee2203c1f56f8bd7e6a8a486e23e907467a0a04bf1e48596741f78341` |
| `runtime_metadata_vm_publication.qnt` | `3d66a48d7451e65f510d07f15bae010a7e9cfb71e3d0d30cefca7b5d622f7266` |
| `RuntimeEntryContracts.lean` | `f5e710994fc7bd4d5ddec12380394eeb576fc3db6465f8f346d28753976a3a9f` |
| False-claim controls | `22c288e49243d84d4865444032e23ac183645b239e7876995d2fd7830c2040f1` |
| Cells manifest | `f2fb227e8a9f92411b9af2effc4c77b251d5b7364a41c7b9cd04222593c25633` |

- An 11-state aliasing control writes VM 1's token 2 into cell 0 while its
  intended cell 1 remains unbound. Correct binding/constructor publication does
  not imply payload isolation.
- A 12-state root-source control has correctly isolated cells `{0:1,1:2}` but
  scans cell 0 for VM 1. Correct payload storage does not imply the collector's
  selected VM is correct.

Fixed safety/weak-fair completion passed over **300 distinct / 863 generated
states**, retaining actual imported catchup failure. The original projection
was rechecked at the new digest: **two expected controls**, fixed safety /
completion **168 distinct / 387 generated states**. These finite histories do
not establish moving-root enumeration, C memory order, same-VM payload race
semantics or complete lifecycle composition.

| Receipt beneath `.cache/` | SHA-256 |
| --- | --- |
| `runtime-entry-models/vm-cell-admission-obligations/receipt.json` | `dfa63750d222896a540c15073807f883304d3a3c0b6f5b47284cddfc1d6a3303` |
| `runtime-entry-models/vm-cell-existing-publication/receipt.json` | `b16295f3e659b340d8a91cfca7e210ffb7af031b40a381c416d7827f5af3b86d` |

Both have stable context, no timeout, native `not-run` and runtime/release
admission false. Existing host-auto scheduling used 12 available processors,
paired controls with six TLC workers each and 12 for positives. Finite VM
identities are not CPU counts or native concurrency limits.

## Retained Specification Failure

The first candidate passed controls but failed completion: actual construction
could enter `phase=error`, while `cellsTerminal` required both scans. The trace
ended with `catchupFailed=true`, count zero, no roots, no payload writes/scans,
and no incorrect cell/root observation. Requiring a non-admitted VM to execute
was a wrong obligation, not evidence of native deadlock. The corrected endpoint
requires scans on success and no child execution/scans on error. It does not
disable failure or strengthen fairness; writer-precommit abort remains in the
original projection.

Receipt `runtime-entry-models/vm-cell-selector-composition/receipt.json` retains
SHA-256 `66ca729d2c2814ea8df55160fe2b9f6331e80f11eb02265e0f916123dc46b578`.
Its model snapshot is `51af8acac7c982d85f17cf030ee071399fe17b9df9ad768bd91a399f96ac965a`.
Reinstating the exact rejected definition
`cellsTerminal = terminal and j.scanned == Set(0, 1)` reproduces that obligation.
No old result is rewritten as a pass. Raw checker/source snapshots remain in
cache, not source dependencies or current native evidence.

## Lean And Existing Scheme Relations

Guarded Lean passed **25 theorem inventories**, standard axioms only and no
`sorryAx`; all **15 false controls** were rejected. The arbitrary-VM/value frame
rule still requires the real compiler/runtime to establish its selector premise.
Observations under `.cache/runtime-entry-formal/run-8c_ffn2t/`:

| Observation | SHA-256 |
| --- | --- |
| `build.json` | `6cc0e92aba1dd47a6f8f46dbdfcd9e4a7abd84134b66262b5f8fef7381ee945f` |
| `axioms.json` | `46613ad7df025c93b493fe85792fb3834e1e1bf996c396b82d8e94feedf97d52` |
| `false-claims.json` | `b5338d245b2cdbb0282e70f791e6f85b7290534be894c13c5831e677cf17196a` |

None timed out or left an active process group. The focused suite passed
**3 tests (8.162 s)** including source withdrawal/restoration and Session reuse;
the unchanged parallel-GC scenario passed **1 test (0.415 s)**. These are check
times, not speedups. Existing Scheme relations bind new premises; Python adds
no production inference, parser, workflow or endpoint. Six model scopes remain
partial, the same three native obligations remain open and `satisfies=[]`.
Earlier canonical/wait/replay receipts retain their original input identities;
additive Lean changes do not make them current extended-proof qualification.

## Exact Parent CI And Remaining Admission

Parent `004610b3af9d58a3160e9ff674415e2d28d3bcd1` completed with build,
patch-contracts, gc-ffi, compile-execute, interrupt-stress, interrupt2-stress and
terminate-stress passing. Threads, tfib-stress and upstream-check failed.
Framework failed during Lean 4.34.1 download with TLS error 35, before framework
tests. It neither validates nor disproves the earlier Reflection repair. Job
labels alone do not identify native causes; none is attributed to this research.
No CI job was rerun here.

The handoff still needs actual current-source accessor/processor/VM identity,
initialized ranges, collector maps/relocation and primitive payload eligibility.
Retain canonical metadata, host entry and init/retirement as separate
dependencies. No extra per-value mutex, shared-payload representation or OCaml
barrier/root-registry ABI is selected. Native owners qualify the unified rebuilt
revision/configuration and original correctness/performance gates. This thread
changed no runtime source, native fixture, bootstrap/stress, installation,
source lock or native checkpoint.
