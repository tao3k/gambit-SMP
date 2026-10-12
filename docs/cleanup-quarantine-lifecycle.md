# Cleanup Quarantine Lifecycle

## Path Review

- Correct direction: a shrink result must control destruction, and retained
  resources must remain protected against embedding operations.
- Prior work: `cleanup_resize_error_contract` already establishes conditional
  quarantine. This extension imports its actual transitions; it does not
  replace the failed-join witness with a population count.
- Worth repairing: the current `___setup` writes setup parameters and resets
  VM population without distinguishing a retained failed cleanup. A checked
  return value alone would leave this ownership boundary unprotected.
- Expected benefit: correctness under failure, not a measured speedup. No
  performance claim or successful-cleanup claim follows from quarantine.

## Source Boundary

The pinned submodule plus `scheduler-retry-sync-participation/source.lock.json`
is the source authority. In that candidate, `lib/setup.c:___cleanup` ignores
the result of `___current_vm_resize`, then calls destructive cleanup helpers.
The preceding source-unit reproduces this exact caller decision with a mocked
failed result; it does not inject a real OS join failure.

`___setup` checks the parameter version, copies setup parameters, sets
`setup_state = 2`, and resets population. There is no retained-state admission
guard at this boundary. Existing `___cleanup` already returns when setup state
is not 1: the repeated-cleanup negative control below is an incomplete proposed
retry policy, not a claim that this existing branch retries cleanup.

## Executable Composition

`models/gambit/cleanup_quarantine_lifecycle.qnt` directly imports the cleanup
model. Embedding attempts interleave with its publication, shrink, join,
reclaim and quarantine actions. The positive policy rejects setup and unload
while resources remain live and makes repeated cleanup non-destructive.

The published receipt is
`evidence/model-results/fixtures/scheduler-retry-sync-participation/cleanup-lifecycle/receipt.json`.
TLC explored 33 distinct states / 64 generated states; safety and weak-fair
completion passed in 3.945 seconds. Three deliberate unguarded policies produce
the expected counterexamples (19, 17 and 33 distinct states). Worker counts were
selected by the framework from available capacity, not fixed in the model.

Completion means an explicit success or retained-resource error with handled
embedding attempts. It does not promise eventual successful release. The model
has one cleanup and one attempt of each embedding operation; it does not prove
arbitrary concurrent host calls or successful repeated setup generations.

Type and imported-initializer translation denials are retained in the sibling
`cleanup-lifecycle-type-denial` and `cleanup-lifecycle-init-denial` archives.
The accepted model uses a homogeneous product state for fairness and explicit
initial state assignments. The imported transition definitions are unchanged.

## Remaining Requirements

Checked cleanup needs an explicit result and lifecycle state distinct from
ordinary cleaned state. The legacy void caller must not pretend success or
reclaim after failure. The exact ABI and fatal compatibility policy are not
implemented here.

Still required: composition with admitted error/catcher drain, GC borrowers and
publication tails; concrete source implementation; real native failure
injection; embedding unload enforcement; complete bootstrap and Gerbil
correctness/performance acceptance. None is admitted by this bounded model.
