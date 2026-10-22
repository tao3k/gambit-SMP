# Candidate Root Source Profile Validation

## Identity And Boundary

This is research for the current supported-entry repair, not native acceptance.
The inspected source matches all 26 entries of the retained mutex-return lock,
before and after the audit. The lock SHA-256 is
`df9277dff351209ad7b33d12589d07821089262f7cdac40b358988aea2fc0466`;
its patch is `49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55`.
`git -C vendor/gambit apply --check` accepted that patch without applying it.
No source tree was created. Unchanged generator files and `setup.h` matched the
submodule. Candidate line anchors are reproducible from that revision plus
patch, not from retained cache availability.

The separate, changing handler-quiet candidate is not incorporated by name or
inferred to have this qualification. The source lock is not an effective build
configuration or binary identity. All actual runtime qualification, final C
memory-model correspondence, generated module selection and native performance
remain with the implementation owner. No 9/12 increment is awarded.

## Existing QNT Protocols

The new `candidate.manifest.json` binds the candidate Recipe, versioned source
lock/patch, primary reference sources and the **unchanged** protocols. It does
not introduce another state machine or rewrite the older formal receipts.
Quint 0.33.0 with the installed Apalache 0.62.1/TLC bundle accepted **9/9 checks
in 114.499 seconds**. `contextStable=true`, no check timeout;
`runtimeAdmitted=false`, native `not-run`.

| Existing protocol | Positive safety/progress | Omission controls | Positive distinct states |
| --- | --- | --- | --- |
| `resize_saved_stack_retirement_isolated` | Pass, 23.566 s | Queue publication without copying: 19.329 s; publish before execution relinquish: 19.797 s | 13 |
| `scan_barrier_quiescence` | Pass, 13.249 s | Local callback return mistaken for cohort closure: 18.366 s; early next-GC admission: 18.522 s | 696 |
| `sync_slot_retained_resources` | Pass, 21.057 s | Child destruction before sender tail: 17.662 s; reinitializing a retained channel: 15.680 s | 41 |

These controls are abstract known omissions under a new source-context profile,
not reruns of a failed native route or demonstrations that the candidate takes
those transitions. In particular, this candidate already retains sync objects;
the child-destruction control is counterevidence against removing that guarantee.
The continuation model's `copyFrames` remains unbound at a shrink that does not
trigger collection. Old-cohort closure, root tracing and remote sender tail
have separate premises; the three passes do not constitute their full C-level
composition.

Scheduling was host-derived: 12 available processors, two control checks with
six TLC workers each, positive checks with twelve. These numbers were not added
to source/model configuration. Each check retained the 30-second formal guard.
The native campaign lease, watchdog and checkpoint were untouched.

Local formal receipt:
`.cache/tasks/host-root-research/runs/3ba583fe19db4dcfac0895e001006fa2/outputs/host-root-publication/candidate/receipt.json`,
SHA-256 `9296b428839d3c3c123fd114940264effb6d910b888744b90da1033cc790777a`.
Manifest SHA-256:
`c01b72cc6966df7422a8a3409f24fdd54bc723d04e7db1f3ae5a2b214765ac80`.

## Conditional Lean Census Contracts

`HostRootSourceCensus.lean` adds four declarations, reusing `WorkAccounting`:

- Partitioned transfer coverage requires a traced receiver for transferred live
  slots and a live retained owner for every other live slot.
- RC/still list membership does not include an activation class.
- A restricted transfer is sufficient when omitted classes have actual absence
  witnesses. No blanket prohibition on empty/non-live classes is introduced.
- The existing hidden-producer counterexample remains applicable: empty public
  queues do not supply producer lifetime.

The guard passed in **2.543 seconds**, exit 0, no timeout, group quiescent.
There is no `sorryAx`; only `propext`, `Classical.choice`, `Quot.sound` occur.
Limits remain 15 seconds, 200000 heartbeats and recursion depth 512. These are
conditional source-class contracts, not a C/layout or QNT refinement proof.

Proof SHA-256: `31535ef19da7184e45d54221e5a25597628513ce904838a0fe01b8bdb1618c18`.
Guard receipt `.cache/host-root-publication/lean-krnq_zon/receipt.json`:
`6716046ccfb580e8e4b42bc8738f2fd0d6723eb402de44d2aafc1d510666a286`.

## Preserved Test-Adapter Failure

The first new Lean test failed its output adapter, despite Lean exit 0 in
7.465 seconds: Lean printed an allowed axiom list on multiple lines, and the
old line-based parser treated the trailing comma as an empty axiom. Receipt
`.cache/host-root-publication/lean-6_m3uebs/receipt.json`, SHA-256
`22b0038fe3cd19245e95c5f694070b30d8942768605f53b192770ea9b6f1a4e2`.

Only the existing research test helper was corrected to parse complete bracketed
lists across lines. It also checks that every axiom-list prefix has a complete
match; an unterminated list cannot bypass the allowlist. The allowlist and
`sorryAx` rejection are unchanged. Production Python/Scheme, proof limits,
runtime source, source locks and old receipts were not modified. The helper
SHA-256 for this guarded run is
`1f551602bce861f005423976a49be293ef7f6685cf1db57da3b82698b87179ed`.

## Reproduction

```sh
gambit-smp --task host-root-research verify \
  --manifest evidence/research/host-root-publication/candidate.manifest.json \
  --out .cache/host-root-publication/candidate --timeout 30 \
  --tlc-liveness final --tlc-jar "$TLC_JAR"
gambit-smp workspace run --provider codex host-root-research -- \
  .venv/bin/python -m unittest tests.test_host_root_candidate_evidence \
  tests.test_host_root_publication_evidence tests.test_repair_redesign_evidence -v
```

Use the existing adopted research campaign and installed Apalache 0.62.1 bundle;
do not adopt or resume the other thread's native task. Generated checker files
are disposable and the source identities above survive cache cleanup. No
bootstrap or original pressure test is part of these commands.
