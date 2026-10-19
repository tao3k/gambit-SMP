# Parameterized Work Accounting Obligation

## Status

`models/gambit/lean/WorkAccounting.lean` now has a local, guarded conditional
proof qualification through the existing Python process/checker libraries.
The nine named theorem inventories exclude `sorryAx`; six false propositions
are rejected and the incomplete-proof control is detected. See the exact
scope, input identities and observed results in
[Runtime Transfer Boundary](runtime-transfer-boundary.md).

This is not sealed research-kernel admission: that interface still has QNT
capabilities but no Lean capability. No capability, native status or historical
receipt is relabeled by these tests. The proofs establish conditional algebra
and interface obligations, not a runtime repair or GC termination result.

## QNT Correspondence

The proof imports `LeanPoo.Functional.TransformationResources` from immutable
commit `d8adf138948c854e7564234bc046387b4a5ee63b` with Lean4.34.0. The previous
`9fbdf863e5d4a4544267e84bc6bdad284d45c29c` remains fetchable, but a fresh Lake
clone did not contain that detached revision. The replacement is reachable in
the public clone; the imported `TransformationResources.lean`,
`Transformation.lean` and toolchain are byte-identical between these revisions.
The package version changes from 0.1.0 to 0.1.1. Lake owns its generated
manifest/cache; neither a second lock implementation nor the unrelated dirty
local lean-poo checkout is an input.

`stageCostsStayWithinComposedBudget` reuses LeanPoo's resource composition
theorem. Actual stage bounds remain premises to establish from source and
observations; neither this algebra nor the dependency pin proves acceleration.

The existing `gc_recursive_queue_wait.qnt` remains authoritative for its
transitions. The proposed projection uses a list enumerating each worker once:

| Lean projection | Existing QNT predicate |
| --- | --- |
| `Worker.counted` | `activeModes.contains(st.mode.get(w))` |
| `Worker.privateWork` | `privateWorkOf(st, w)`, including marking/publication work |
| `Worker.queued` | A queued object has `queueOf == w` |
| `activeCount` | Cardinality used by `countSafeOf` |
| `ProducerLifetimeSafe` | `producerLifetimeSafeOf` |

The proposed theorem is independent of the list length. Under exact active
count, producer lifetime accounting and empty queues, no enumerated worker can
retain private work. A concrete uncounted private producer demonstrates why
the lifetime premise cannot be dropped.

The list-to-worker bijection and equivalence of these projections have not
been proved. Predicate correspondence is not transition preservation. QNT
still has to establish invariant preservation and produce adversarial
schedules; Lean does not assume that a chosen runtime maintains these premises.

## Exclusions And Next Checks

The statement does not prove discovery closure, completed scanning, forwarding,
strong/weak phase completion, native memory ordering or scheduler progress.
It does not bound repeated steal probes, condition wakeups or elapsed time.
In particular, empty queues plus zero count alone do not establish complete GC.

`tests.test_runtime_transfer_formal` uses existing `process_observation.capture`
and `quint_backend.check`, with process-group cleanup, Lean heartbeat/recursion
guards, exact input hashes and host-adaptive checker concurrency. No independent
Lean runner or Python semantic model is introduced. Scheme's existing
`transfer_premise_evidence` exposes the proof scope and remaining obligations;
it does not derive `satisfies`. Sealed admission and source refinement remain
open, including a list-to-worker bijection and preservation of the premises.

The original driver-control assets are retained under `lean/controls`:
`OmittedLifetime.lean` must fail elaboration of a false concrete conclusion;
`SorryWitness.lean` may elaborate but must fail admission because its named
theorem depends on `sorryAx`. Controls are separate from the positive library
target. Both intended outcomes have now been observed through the guarded
consumer. Five additional false controls cover unacknowledged service,
mutation of inactive roots, reopened work, reused identity and an unowned exit.
The first elaboration also exposed an existing Bool-case proof mismatch; it
was corrected rather than treating the old unchecked asset as a passed proof.
