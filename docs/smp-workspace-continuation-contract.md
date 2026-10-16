# SMP Workspace And Continuation Contract

## Implemented In The Existing Framework

Recipes can select `workspacePolicy: in-place`. `gambit.materialize` can adopt
an explicitly named existing fixture workspace instead of creating another
source tree. It validates the fixed submodule revision, locked candidate files,
archive base bytes and every existing file before mutation. Unknown edits and
Git/symlink/path aliases fail closed. Only explicitly hash-bound generated
cache files absent from the upstream archive can be removed. The original
directory and inode are retained while missing upstream files are filled.

Managed workspace locations are typed metadata, not symlink aliases. The
existing configure/seed/bootstrap clone entry uses an exclusive nonblocking
lease in in-place recipes. Each published stage has a retained inventory and
bound Evidence inputs. Later legitimate states can supersede earlier live
bytes without destroying their recorded state. Final runtime drift still
rejects completed-producer reuse. Retained inventories are not binary backups
or native admission and do not restore missing historical files.

Continuation requests bind the actual original outer receipts, source lock,
recipe bytes and requested cap. Failed attempts and outer teardown stay charged.
Each attempt cap and the new recipe cap must fit the remaining original budget.
The executor revalidates the request before each capability. Accounting does
not replace the existing native ASCENT known-failure preflight; Python does not
select retry eligibility. `executionAuthorized` remains false in transport.

Related workspace, continuation, artifact, recipe, producer and sealed-engine
tests passed: **176 tests, 3.460 seconds**. These tests
include actual file adoption and executor clone calls without copying/moving
the workspace. They are framework tests, not a Gambit bootstrap or SMP result.

## Durable Budget And Provider Custody

The existing `checkpoint_budget_ledger.qnt` models concurrent reservations,
interruption, failed-consumer charging and settlement order. The framework now
reserves before dispatch under an exclusive lock, retains immutable event
parents, and charges quiescent outer receipts before releasing reservations.
An interrupted reservation remains held. Observed overruns stop further
execution. Requests bind original expenditure; the same persistent ledger
additionally accounts for every later settlement. It is not a new budget.

`research --seal --provider-sources <engine>` can reuse exact provider build
inputs from a validated immutable engine archive when the live SDK changes.
Every reused byte must match both the new build receipt and the old engine
inventory. The library receipt is unchanged; the mutable SDK is not restored
or overwritten. Unknown cache directory children still reject workspace
adoption before any mutation. Only ancestors of declared hash-bound cache
files can be removed, and only when empty.

`workspaceState` instead checks an exact retained directory inventory and all
its durable input bindings, including the current source lock. It rejects
mixing that mode with disposable-cache declarations. This is storage reuse,
not reconstruction of an interrupted campaign receipt or runtime admission.

## Not Yet Closed

The candidate has a fresh exact-implementation seal and a persistent original
expenditure chain. Actual in-place source/configure/seed/bootstrap qualification
is still required.
Native preflight must evaluate the Scheme DSL against the exact resulting
producer. No old binary, partial model receipt or retained inventory may fill
that role. Current native milestone completion remains **3/12**.

## Actual Continuation Result

The same candidate directory was adopted and configured with GNU GCC, the
Bazel build profile, SMP, multiple VMs and multiple threaded VMs. The detected
host capacity selected 12 make jobs for these runs; that value is not a fixed
framework default. Source, configure, seed and native ASCENT causal review
passed in the final continuation. The actual two-pass command was launched,
but only 22.890 seconds remained for it. The outer 106-second cap terminated
the attempt; complete bootstrap did not pass.

All four new DENY observations remain charged. The original 600-second ledger
records 599.403 seconds spent, no pending reservation, and an observed
0.249-second final-attempt overrun including outer termination. Its breach
guard rejects another reservation even though arithmetic leaves 0.597 seconds.
No budget reset, repeated unchanged attempt, reconstructed missing child
receipt, or new native/performance acceptance is authorized by this result.
Portable receipt identities and exact observations are retained in
`evidence/research/continuation-retained-seed-bootstrap/observation.json`.

## Model Catalog Boundary

The private-chunk and wake-budget manifests explicitly declare empty imports
and paper edges because their QNT modules contain no imports and make
source-directed claims. The older cleanup endpoint model is explicitly
`registrationOnly`: catalog facts are available, but executable protocol
verification and protocol-receipt admission reject it. Its standalone safety
recipe remains distinct from a temporal progress proof. No old receipt was
rewritten and no constant progress property was introduced.
