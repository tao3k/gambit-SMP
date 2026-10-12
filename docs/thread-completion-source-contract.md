# Thread Completion Source Contract

## Scope And Authority

`evidence/fixtures/thread-completion-contract/source.lock.json` extends the
current `abandoned-result-state` lock with exactly two tracked test files.
All 18 runtime/build source identities remain identical to the parent lock.
Only `thread_start.scm` and `thread_interrupt.scm` change. This is not a new
runtime repair, source optimization or package-specific workaround.

The pinned submodule and 20-file cumulative overlay reproduced successfully
in a fresh source tree. Independently replaying the existing
`test-thread-start-join.patch` and `test-thread-interrupt-completion.patch`
onto the pinned original test blobs produced the exact same two candidate
hashes. All original assertions remain. The changes add completion join and
a mutex gate, matching the existing `thread_start_completion.qnt` and
`thread_interrupt_test_protocol.qnt` obligations. They do not replace native
join/visibility verification or establish source refinement by themselves.

## Original Failure Recovery

The exact original baseline identities were recovered from retained diagnostic
files and copied byte-for-byte into durable semantic evidence paths:

- Start baseline SHA:
  `52ca6e02277910aef2ae30f31bf3c214d9b06d0ef40aff2675f3b7bb03b7b702`.
- Interrupt baseline SHA:
  `db1c998fb0c99b4528714cb89409ae05cc77f8a987f959e8aa90764c10467c4b`.

The original full interpreted interrupt campaign receipt was also recovered,
including actual `results`, failed exit/timeout and the original 300-second
whole-mode budget. It is not reconstructed from a later passing run or inferred
from its historical summary. The start failure retains its original compiled
result and 120-second budget. Their original raw logs are retained.

Portable recovery evidence is in
`evidence/source-results/fixtures/thread-completion-contract/history`.
Identity snapshots are unredacted and match the failure-named hashes exactly.
Only personal paths in receipt/log display text were redacted; both raw and
archived hashes are recorded. Historical summary/failed receipt bytes and
canonical failure IDs have not been replaced or deleted.

## Pending Native Admission

The current historical interrupt summary lacks fields required by the sealed
typed review contract. Recovering the actual full original receipt makes a
versioned, auditable failure observation possible; it does not itself change
the canonical failure inventory or authorize execution. That update must bind
the retained original summary, full receipt, raw hashes, baseline identity,
model-bound fixture changes and causal premises without weakening the gate.

This source lock has not been configured, compiled or bootstrapped. No
23/25 result is promoted to 25/25. The next actual experiment must use the
sealed source/runtime producer and typed `gambit.suite` review, preserve all
three concurrency flags and original budgets, and retain every failed result.
Complete native/stress, GC composition, retirement/cancellation, Gerbil and
production performance remain open.
