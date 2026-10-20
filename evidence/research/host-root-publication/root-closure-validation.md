# Root Closure Formal Validation

## Scope And Source Identity

This is research for the unchanged mutex-return source profile. It does not
advance native 9/12, admit runtime behavior or establish the cause of a native
failure. The Recipe is `docs/saved-stack-root-closure-recipe.md`; older arena,
candidate and isolated-model receipts are unchanged and remain partial.

| Input | SHA-256 |
| --- | --- |
| New QNT composition | `4c77c864581ae5e5f1317e3a3d210c5fd074db722e217c6462588a213197f5d4` |
| Imported arena model | `f460922d3e41fd850c39bcbc9f4ee994b69851edb866ca98500e5588c3b8fb74` |
| Imported isolated stack model | `38dbe1b570efda86a261922781c3ee4de0ba9da379fbbd8d0697a177290c989c` |
| Lean companion | `1f64064b7476adad0d1aedee5266e8ad882018443c95717b5676057f8c1c156f` |
| Recipe | `fdddf2e2bb4f561c0fec6272690d9a46f8d8d71d99b132a26a67c53e5a93be95` |
| Manifest | `18ad46a7ff814fc41add13262b22eb7dff864212f299827671420c7f6ea7fbfd` |
| Candidate source lock | `df9277dff351209ad7b33d12589d07821089262f7cdac40b358988aea2fc0466` |
| Candidate cumulative patch | `49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55` |

Candidate source was only read at the retained path and compared against the
versioned source lock; that path is not reproduction authority. No new source
tree, runtime build or native pressure test was created. The manifest binds
the original submodule sources and the patch/lock, not disposable source copies.

## QNT Results

Existing host-adaptive verifier, campaign `host-root-research`, run
`91b8f8bc4d00495e9e2400704d8eb6e7`: **6/6 accepted**, context stable,
59.814 seconds, native `not-run`, runtime/release not admitted. Receipt SHA-256:
`2dc6dc0656b7d88d642da98d1c12f8ff3bfac98cbebd1b5a2a52d9ace901fc23`.
Cached raw receipt is under that campaign run's
`outputs/host-root-publication/root-closure/receipt.json`.

| Check | Meaning | Seconds |
| --- | --- | --- |
| `rootCoverage` | Counterexample: collection starts with no admitted survivor payload scan, even though raw backing and the imported component remain valid | 13.938 |
| `chainCoverage` | Counterexample: copied head permits reuse while tail/escaped origins remain raw | 18.422 |
| `phaseCoverage` | Counterexample: all declared raw origins are retargeted, but target scan work remains when later-cycle reuse is incorrectly admitted | 15.796 |
| `noRetainedAliasesAfterHeadReturn` | Constructive witness: non-GC head return retains old backing and both other raw origins | 15.492 |
| `noClosedChainReuse` | Constructive witness: fixed cohort retargets every declared origin, drains work, closes cycle, reuses old backing and returns | 11.605 |
| `closureSafe` and `closureCompletion` | Corrected immutable cohort safety, no stuck nonterminal state, and conditional weak-fair completion | 13.525 |

TLC enumerated 228 distinct states / 368 generated, depth 16. The initializer
selects one immutable scenario; negative properties select their deliberate
omission, while safety/liveness concern the corrected cohort. This is not a
machine CPU configuration. Every nonterminal action changes `g` or the imported
arena state `a`, so fairness does not hide an imported-state-only transition.

The phase counterexample is not a claim that pending target work still reads
the original raw frame. It demonstrates that root redirection and raw-read
closure do not authorize ending the collector cycle. Reuse in this projection
is a *later-cycle* boundary; no early-reclamation optimization is proposed.

The model does not enumerate all source queues, frame aliases, C weak-memory
histories, actual semispace bounds or native catchers. Its root anchor and
declared consumer set still need source refinement.

## Lean Results

Guarded focused test: exit 0, 3.398 seconds, no timeout, process group quiescent.
Receipt `lean-f0joxokn/receipt.json` SHA-256:
`c585ed749c237f7077367014aab8ad25164a1ec11508963ef238ef63ad9f0c51`.
It binds the companion, unchanged WorkAccounting and the preceding arena
manifest. The final regression uses the new root-closure manifest as well.
Existing 15-second process guard, 200000 heartbeats and recursion limit 512
were not increased. All five checked declarations are axiom-free:

- `explicitEdgesPreserveReachability`
- `pointerToPermanentIsNotPayloadScan`
- `declaredClosureCoversActualConsumers`
- `headClosureDoesNotCloseTail`
- `twoCyclesDoNotRestoreIdentity`

Completeness is conditional and scoped; a legitimately empty actual consumer
set is allowed. The proof does not equate a nonempty declaration with a complete
physical graph, and does not impose OCaml one-shot continuation behavior.

## Preserved Failed Attempts

The first new typecheck failed because set `isEmpty` was not available and a
nested namespace was not exported. The set comparison and accessible-state
fairness projection were corrected. An initial Lean parse failed on reserved
identifier `from`; that failed elaboration was not admitted. It was renamed,
then the guarded proof passed without `sorryAx`.

The first formal launcher failed to bind localhost within the sandbox. Its
research execution was explicitly reconciled using the existing workspace
resume command; no native task or framework code was modified. After allowing
local formal-backend IPC, two further failed formal receipts were retained:

| Run | Result and receipt SHA-256 |
| --- | --- |
| `63fd8912c4164227aca2a409616a43ca` | DENY: `QNT409` shared imported initializer used by multiple entry actions; `62ac828401961a18ba69926e8b5fabb210cf3b6d21ee6b9c1db5b0e643f9192a` |
| `d29fbf0f0f7247f9a69f4acd3cf91406` | DENY: nested namespace conversion generated an extra uninitialized `R_A_R_retirementState`; `6047b6cf58bfeeace6cfdfba3df01fd0e5b886e7774baf9c604666467c9b03d3` |

The corrected composition uses one initialization site and the existing flat
import surface. It did not modify either imported model or the framework,
discard failed receipts, treat compiler errors as counterexamples, or relax a
timeout/invariant to manufacture acceptance. Both failed raw logs/receipts stay
in their original campaign outputs.

## Reproduction

Use the existing task, verifier, pinned TLC artifact and test framework:

```sh
quint typecheck models/gambit/saved_stack_root_closure.qnt
.venv/bin/gambit-smp --task host-root-research verify \
  --manifest evidence/research/host-root-publication/root-closure.manifest.json \
  --out .cache/host-root-publication/root-closure --timeout 30 \
  --tlc-liveness final --tlc-jar "$TLC_JAR"
.venv/bin/python -m unittest tests.test_saved_stack_root_closure \
  tests.test_saved_stack_arena_evidence tests.test_host_root_candidate_evidence \
  tests.test_host_root_publication_evidence tests.test_repair_redesign_evidence -v
```

No native flag, compiler build, debugger, full graph CI or performance acceptance
is implied by these commands or their local results.
