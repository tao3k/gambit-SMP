# Repair Trajectory Closure: Local Qualification

Date: 2026-10-20. Scope: the source-bound framework patch in a concurrently dirty
checkout, not a published revision, full framework CI or Gambit qualification.
No external Grok, bootstrap, debugger or native stress campaign was launched.
The provider controls use local fake executables, but execute the real CLI and
installed native ASCENT Scheme/Datalog inference. Neither a fake provider nor
real inference establishes model reasoning quality or a native runtime repair.

## Frozen-Source Results

The following focused suite completed **97/97**, exit 0, in **263.969 seconds**:

```sh
.venv/bin/python -m unittest \
  tests.test_cli tests.test_grok_session tests.test_current_repair_trajectory \
  tests.test_view_availability tests.test_api_observation_scope \
  tests.test_ascent_program tests.test_step_checkpoint \
  tests.test_checkpoint_recovery tests.test_stage_checkpoint_pipeline \
  tests.test_checkpoint_evidence_exchange tests.test_modeling_guidance \
  tests.test_evidence_views -fv
```

Three additional real repository/CLI controls completed **3/3**, exit 0, in
**49.402 seconds**, keeping the original **30-second child-process limit**:

```sh
.venv/bin/python -m unittest \
  tests.test_progressive_clues.TrajectoryCliTests.test_cli_anchor_uses_registered_dsl \
  tests.test_progressive_clues.TrajectoryCliTests.test_explicit_selector_replaces_registered_policy \
  tests.test_progressive_clues.TrajectoryCliTests.test_checkpoint_token_resumes_in_another_python_process -fv
```

These are 100 distinct focused controls, not the entire repository suite. The
two runs overlapped; their durations must not be summed as one wall-clock run.
The API-boundary controls verify outer entry/exit hashing, rejection of mutation,
exception unwinding, fresh independent requests and process/thread isolation.
Existing custody, alias, historical-view, dependency, quiescence and source-drift
controls remain enabled. `git diff --check` passed for the tracked touched scope.

The same host-omission control passes through actual host facts, Scheme
`enumeration_gap`, Clue refresh and a new Python process. A further unchanged
read does not replay family bodies. This preserves the distinction between
missing declaration, explicitly empty inventory and native completion.

## Actual Registered-Repository Reads

These three calls ran in distinct Python processes through the existing
`repository_clues` entry, with display capacity 16384 and the returned token
passed unchanged. The final source identity is
`9c8f2a38d984236a5bc9e93a32d72a8946648341c0dec59d6f1f1439e0db9209`.

| Relational binding | Newly displayed families | Delta: added / removed / retained |
| --- | --- | --- |
| `repair-contract=lifecycle` | `repair-handler-quiet`, `repair-join-identity`, `repair-lifecycle`, `repair-retirement-census` | 48 / 0 / 0 |
| `repair-contract=gc-ffi`, continued | `repair-gc-ffi`, `repair-native-inventory`, `repair-numeric-completion` | 32 / 0 / 13 |
| Same GC/FFI binding, continued | None | 0 / 0 / 45 |

All three report four counter-observations, zero support, complete presentation
and `runtimeAdmitted=false`. Delta items are Library evidence units, not tests
or native progress. The shared retirement census is not replayed on scope change.

Tokens, in order:

- `clue-read:0017c649e121bd0af5561d724624c4dfbcb2ece3712a489b445fe02342083554`
- `clue-read:234f7c793ebe2d580d2fafccbed0c12603f44200c7e32e9c2db3081c2a4afee3`
- The same second token is returned by the repeated read.

Tokens are disposable read hints, not durable evidence or executable
checkpoints. Their later absence permits honest replay.

An instrumented first lifecycle read observed exactly **two** installed-identity
hash passes across all nested component loads, taking **17.576 seconds** in this
concurrent host state. This is an actual work-count observation, not a matched
speedup benchmark. No bootstrap, build, test or release timing follows from it.

Coverage reports 22 available registered Clue views and one unavailable view.
The unavailable view's domain facts do not participate; its provenance counters
are accessible through the configured Scheme projection. Strict evaluation
still rejects it. The full registry graph is therefore **not** declared qualified.
No other owner's changing reference hashes were automatically accepted.

## Failures And Corrections Retained

1. Sandbox-local Unix socket handoff was denied. The narrow local fixture run
   was rerun with the required IPC permission; no provider/network permission
   or native execution was added.
2. The first fake-project control omitted its registered view and then its
   storage DSL. Both failed explicitly. The fixture now supplies real minimal
   assets, rather than bypassing the existing registry or persistence layer.
3. A pre-existing one-second post-init provider test could expire before init.
   Its fixture now observes controlled initialization before starting that
   existing deadline. A separate pre-init interruption test rejects an invented
   resumable session. Production and native timeouts were not extended.
4. Strict source binding rejected changed references, including this patch's
   reader source. The earlier explicit source review in this directory binds
   only its predecessor delta. It is not a current blanket rebinding after
   subsequent reader changes. The new read-only availability contract exposes
   the gap without reusing stale facts or weakening strict evaluation.
5. An exploratory broad run was interrupted with exit 130. It reported an
   anchor assertion failure and a selector error before interruption; it is
   not green and did not provide a complete diagnostic report for that selector
   error. Both exact tests subsequently pass on the frozen implementation.
   The anchor failure showed correctly folded evidence, not a no-hit result.
   The targeted anchor test now names its actual source-integration stage;
   its expected claim and the presentation capacity are unchanged.
6. A later three-control run failed the original 30-second cross-process child
   limit (3 tests, 164.181 seconds, one error). Repeated nested installation
   hashing was observed in the loading stack. After request-scoped observation
   reuse, the unchanged 30-second control passes. Another exploratory suite
   was interrupted to implement this fix; it is not counted as qualification.
   The timing difference is not a controlled general performance ratio.
7. Initial availability controls failed host attestation matching because a
   synthetic digest was used as the source digest. They now bind the actual
   declaration bytes, with reference observations kept as factors. Fixture
   setup and response-shape errors were also corrected, without changing
   production admission. All five final availability controls pass.
8. One manually transcribed read token had extra characters and was rejected
   as malformed. The exact retained token subsequently resumed. No missing
   token was treated as proof of empty evidence or native completion.

## Bound Implementation Bytes

These eight identities matched before and after final qualification. They do
not describe all concurrent changes in the checkout and are not a commit seal.

| Path | SHA-256 |
| --- | --- |
| `src/gambit_smp/ascent_program.py` | `a1c69f75f6a0726ad3dd41c5cee6128bea2650559a61d15300818d5f8c24aa6c` |
| `src/gambit_smp/evidence_views.py` | `fe4bbcf0b6526153093928a34b15dad0a0809a6b7c0e704797bb0efa31a12e31` |
| `src/gambit_smp/trajectory_exploration.py` | `1551dd3ec0f136b0eec8d895b21b14a18fb4a6874b6fdb5815b57e068ef3a8be` |
| `src/gambit_smp/grok_session.py` | `65db511d3fd6f73656b692a4ae533cadc20854b0396a28475796268fdaf25e37` |
| `src/gambit_smp/cli.py` | `165feeccc0d6e7a20ab045d23c5becd71d134d79914fe3d219393718970847db` |
| `evidence/scenarios/stack-header/clues.ss` | `c07ea8da3b3e444104500332d31b31c78c1ad798fb22bd2b7724994cffbfcf28` |
| `evidence/views.json` | `1fbf8432863d3da1a547b391f30c337668cb169152ae46f849cd5f75e4935776` |
| `evidence/scenarios/runtime-lifecycle/current-repair.view.json` | `67a835be9214752567640dc37b29769a9338b1a1fe33ba6cb391d5d11897a455` |

## Remaining Acceptance Boundary

No new QNT/Lean result or source-refinement proof is asserted. Existing upstream
checkpoint/query properties are reused as abstract obligations, not copied into
a second downstream framework. Per-evidence read retention across unrelated
source revisions is not implemented; current source identity remains global.

The retained native audit still reports eight historically complete contracts,
with lifecycle failure/rollback, complete GC/FFI, Gerbil correctness and release
performance open. The new bundles expose specific unsupported clauses for all
four. This framework result closes neither item 9 nor the entire 9-through-12
campaign. Runtime implementation and original native acceptance remain with
the separate implementation lane.
