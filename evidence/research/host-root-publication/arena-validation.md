# Saved Stack Arena Ownership Validation

## Source And Model Scope

This is current supported-entry research, not a new runtime or collector.
The mutex-return source lock remains
`df9277dff351209ad7b33d12589d07821089262f7cdac40b358988aea2fc0466` and
its patch remains `49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55`.
All 26 locked files matched the observed candidate before the audit. The
reproduction inputs are the pinned submodule plus that versioned patch/lock,
never the disposable observation directory.

The source map is `docs/saved-stack-arena-recipe.md`, SHA-256
`2f4eb6f8e6d5d488ccd3f0cbf02acfbb152c07f4a89dd512c06ac876dc9c4fea`.
Its key correction is that the old isolated model's eager-copy retirement
guard cannot be assigned directly to pstate cleanup: the actual backing arena
is VM-owned. No claim that the earlier conditional-GC observation demonstrated
a native bug is retained. No forced-GC runtime fix is selected.

The unchanged isolated model remains
`38dbe1b570efda86a261922781c3ee4de0ba9da379fbbd8d0697a177290c989c`.
The extension reuses its save/detach/publish/scan/copy actions and safety
predicates, but **does not refine its copy-before-retire transition guard**.
It explicitly adds executor retirement with live old-half backing. Its
`donorStorage` interpretation is readable backing, not a live pstate.

## QNT Results

The existing verifier accepted **6/6 checks in 62.848 seconds**;
`contextStable=true`, no check timeout. Corrected safety and weak-fair progress
visited 23 distinct states (31 generated). Host-derived scheduling selected two
parallel controls and worker counts from the observed machine; no CPU setting
was added to model or manifest. The 30-second per-check guard was unchanged.

| Check | Result | Seconds |
| --- | --- | --- |
| Slot cleanup mistaken for backing release | Expected counterexample | 13.655 |
| Cleared continuation slot mistaken for last raw use | Expected counterexample | 13.707 |
| Same address mistaken for same frame incarnation | Expected counterexample | 15.569 |
| Return after donor slot reuse without GC/heapification | Positive reachability witness | 16.012 |
| Later GC copy followed by old-half reuse | Positive reachability witness | 16.025 |
| Corrected safety and conditional weak-fair completion | Pass | 16.146 |

The no-GC witness ends with `slotCleaned=true`, `slotReused=true`,
`vmAlive=true`, `copied=false`, `recycled=false`, `epoch=0`, `badRead=false`.
The imported state has `retired=true`, `heapFrame=false`,
`donorStorage=true`, `returned=true`. This is not zero copying: the break
handler consumes the one modeled frame into the receiver stack. It does not
require eager heapification or permanent retention of the executor slot.

The GC witness instead has `copied=true`, `recycled=true`, `heapFrame=true`,
`donorStorage=false`, `returned=true`, `badRead=false`; the old-half lifetime
can end after the supplied borrower is retargeted. Neither witness proves
actual root completeness, C ordering or a native performance change.

The cleared-slot omission ends with `badRead=true`, despite imported
`saved=false`, `executing=false`, `published=true`, `scanning=false` and
`returned=true`. The imported safety predicates still hold: its saved-root
obligation was incorrectly discharged when the thread slot cleared. The
extension keeps the root's move to the break link visible and detects the later
read of released/reused backing. This is a deliberate model omission, not a
report that the candidate actually releases backing there.

The full fairness tuple includes both arena and imported state. Mutator break
consumption is not enabled during the modeled collection phase. A single
reachable frame/current root is modeled; aliases, multiple remaining frames,
native C origins, descriptor lifetime, allocator invariants and complete GC
phase refinement remain source premises.

Model SHA-256: `f460922d3e41fd850c39bcbc9f4ee994b69851edb866ca98500e5588c3b8fb74`.
Manifest SHA-256: `f86f261edbeda4f33e169bce20769f77adc9831cecae9972561eb3290186eee5`.
Local receipt:
`.cache/tasks/host-root-research/runs/6efc94e1b6a14fcc90d9353637939499/outputs/host-root-publication/arena/receipt.json`,
SHA-256 `c6de3d4980d1b69be463b4e4b5d4a76ced0ddc2e4f0451aed7e0d59bda56ec20`.

## Lean Results

Five declarations in `SavedStackArenaLifetime.lean` passed the existing guarded
Lean check in **5.104 seconds**, exit 0, no timeout, process group quiescent.
Limits remain 15 seconds, 200000 heartbeats, recursion depth 512, pinned
toolchain and unchanged proof/manifest/dependency hashes. Four declarations
are axiom-free; the reused epoch theorem depends only on `propext`/`Quot.sound`.
No `sorryAx` is present.

The proofs distinguish slot retirement from backing lifetime, a moved borrower
from a cleared slot, and frame identity from address reuse. The reuse proof
quantifies over a **supplied complete borrower census** with each borrower
copied or consumed. It does not discover omitted aliases or prove the QNT/C
refinement. `WorkAccounting` and its generation contract are reused unchanged.

Proof SHA-256: `49f242f2471dbb698d08b41123a1bf3e0429aad6146b521d0b866bb57a397926`.
Local guarded receipt `.cache/host-root-publication/lean-q2tyrr36/receipt.json`,
SHA-256 `f25499ffa0bf26cd4bb368963e0133de34e7d299ad8bd9a232965c854ae8f27a`.

## Reproduction And Promotion Boundary

```sh
gambit-smp --task host-root-research verify \
  --manifest evidence/research/host-root-publication/arena.manifest.json \
  --out .cache/host-root-publication/arena --timeout 30 \
  --tlc-liveness final --tlc-jar "$TLC_JAR"
gambit-smp workspace run --provider codex host-root-research -- \
  .venv/bin/python -m unittest tests.test_saved_stack_arena_evidence \
  tests.test_host_root_candidate_evidence tests.test_host_root_publication_evidence \
  tests.test_repair_redesign_evidence -v
```

Use the existing adopted research campaign and installed Apalache 0.62.1 bundle.
No original native failure route, bootstrap or pressure test is repeated.
Native/release admission remains false and the other thread's progress is not
recounted. The older models/manifests/receipts are unchanged; a future generalized
stack carrier, attachment ABI or collector redesign remains Experimental.
