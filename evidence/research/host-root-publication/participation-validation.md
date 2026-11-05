# Final Root-State Handoff Validation

Research track: current supported-entry composition. Native tests not run;
runtime/release admission remains false. This supplement does not change the
other thread's cumulative 9/12 progress or its source-bound qualification.

## Source Identity And Reproduction

The manifest is `participation.manifest.json`, SHA-256
`9ef169f5e75ac42387e407a1cfef2a59c9b5f733fda925bddbc4c3d306f93230`.
It binds all source sections, new proof and unchanged model imports. Model SHA:
`e24c2ce90f6264d5bcba6d4c72da46ccc56c11405d6b1b7725fa6bd6b6b2730e`.
The pinned source revisions and full transfer limits are in
`docs/host-root-participation-source-map.md`.

Use the existing verifier, Quint 0.33.0 and the installed Apalache 0.62.1 bundle
as `TLC_JAR`. An unmodified standalone TLC jar lacks the `Apalache` standard
module required by Quint output. This is a tool dependency, not fixture source.

```sh
gambit-smp workspace start host-root-research --adopt
gambit-smp --task host-root-research verify \
  --manifest evidence/research/host-root-publication/participation.manifest.json \
  --out .cache/host-root-publication/participation --timeout 30 \
  --tlc-liveness final --tlc-jar "$TLC_JAR"
gambit-smp workspace run --provider codex host-root-research -- \
  .venv/bin/python -m unittest tests.test_host_root_publication_evidence \
  tests.test_repair_redesign_evidence -v
```

The framework routes new CLI outputs beneath the campaign's run directory.
The task adopts the existing checkout, creates no source copy and does not
acquire the active native campaign's lease. Cache removal does not change this
source-bound summary; rerunning regenerates the disposable formal artifacts.

## QNT Results

Final campaign: **4/4 accepted**, 44.210 seconds, `contextStable=true`, no
timeout. Corrected safety and conditional weak-fair progress: 136 distinct
states, 172 generated, depth 18. Scenario tags partition the corrected cohort
and deliberate omissions; they are not processor counts. Cleanup witness is
explicitly restricted to the corrected cohort.

| Check | Result | Seconds |
| --- | --- | --- |
| Published record mistaken for host readiness | Expected counterexample | 16.749 |
| Missing final-state acquire | Expected counterexample | 13.521 |
| Changed root observed, then record reclaimed | Positive reachability witness | 12.379 |
| Corrected cohort safety and weak-fair completion | Pass | 14.651 |

Retained first counterexample: the registered record has both declared root
roles, valid initial publication/acquisition, and a completed admitted scanner.
The host is still executing: `h.phase=1`, `p.policy=1`, `parked=false`.
The scanner observed `0`, the host then wrote `1` and froze `handed=1`.
`badCensus=false`, `badHostUse=false`; imported publication has no payload race.
Thus correct record publication and scanner lifetime do not supply final root
state or execution handoff. This is an abstract omission, not a native failure.

Second counterexample: `policy=2`, `frozen=true`, `parked=true`; the original
record was acquired correctly, but the final-state handoff has
`acquiredInit=false`, `payloadRace=true`. Equal record initialization cannot
replace this independent observation obligation.

Cleanup witness: `policy=0`, `payload=handed=observed=1`, `h.phase=3`,
`lastUse=true`; both publication readers are done, the lifetime reader/writer
are done, `alive=false`, `linked=false`, no invalid read. Safety was not bought
by retaining all records forever. The arbitrary physical census, actual source
ordering and native scheduling are not proved by these finite checks.

Local accepted receipt:
`.cache/tasks/host-root-research/runs/664cef8e81cc4869b052d2844be923f6/outputs/host-root-publication/participation/receipt.json`,
SHA-256 `884af24c2006fb70f66685ffc61f9f465aa49b6547907789e51553d1d4d025a6`.
The host-auto scheduler observed 12 processors, chose two parallel controls
with six TLC workers each, and twelve for the positive check. No CPU count was
hardcoded in this model or manifest.

## Lean Results

Five declarations in `HostRootParticipation.lean` passed in 5.808 seconds,
exit 0, no timeout and process group quiescent. Guard: 15 seconds, 200000
heartbeats, recursion depth 512, pinned toolchain and unchanged input hashes.
Proof SHA-256:
`e5ce61239be5d9012b899f22b1f4e744886a78e08c63035bf60451ab564f1193`.
Declarations use no `sorryAx`; only `propext` appears in the three reused
propositional consequences; two elementary statements are axiom-free.

The universal slot/relocation theorem requires the supplied live-slot census,
frozen handoff and scanner observation equalities. It does not establish these
for generated C or refine the QNT transition relation. Local guarded receipt:
`.cache/host-root-publication/lean-3axgu8f7/receipt.json`, SHA-256
`a388708b93ba92295d626ca08a29d01d5d97038f72e1886b2073a3f91e0ca3ed`.
The current test adapter SHA-256 is
`61bfc398436af1f49f6bf470859c9263c9c4d0789fbeac278f2ef62e8856095c`.

## Preserved Failures And Corrections

- Initial typecheck rejected transitive `V::s`/`L::s` references. No old model
  was changed to expose implementation-private aliases.
- The shared initializer initially failed Quint-to-TLA conversion (`QNT409`).
  A subsequent typed helper had the same restriction. One initializer now
  chooses an immutable scenario; the checks explicitly retain their scope.
  First verifier failure receipt SHA-256:
  `e0c71e1f20a45286cc2b6bf7979d4bc58adea57a5c6a31e76d82b27503c93e96`.
- The default native task lease was busy; no lease was stolen. An independent
  adopted research campaign was used. Its first attempt found that the former
  disposable tool path had been removed. Public resume reconciled only this
  research task after the setup error; no native action was replayed.
- Standalone TLC could parse neither check because `Apalache.tla` was absent.
  Receipt SHA-256:
  `def75cac994279fb4a71c69ec0179b595fb247f5fae020ace8b1fa78b33b09a1`.
  The already installed pinned Apalache bundle supplies that dependency.
- The next run passed all three controls but failed progress: after unlink,
  `L.writer=reclaim`, `alive=true`, the old fairness projection allowed infinite
  stuttering because this imported metadata-only move changed none of its
  projected variables. Receipt SHA-256:
  `e7b59dd02fcaf72601795dbf477ef980dbe672beaf1631fb4393089a7e1f14f9`.
  A ghost transition rank now changes on every real nonterminal move. It adds
  no transition, native heartbeat or runtime field, and does not move an
  acceptance deadline. Terminal stuttering leaves it unchanged. All four final
  checks were rerun against the changed model; old controls were not relabeled
  as current evidence.

Previous lifetime/source-map models, manifests and receipts remain unchanged;
their unchanged TLC cohorts were not rerun. Native acceptance, performance and
any causal claim about the active candidate remain outside this supplement.
