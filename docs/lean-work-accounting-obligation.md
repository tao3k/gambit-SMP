# Parameterized Work Accounting Obligation

## Status

`models/gambit/lean/WorkAccounting.lean` is an unqualified proof asset. It has
not been run through the required ASCENT Python driver: that driver currently
has QNT capabilities but no Lean capability. Do not register this file as a
passed model, proof, runtime repair or GC termination result.

## QNT Correspondence

The proof imports `LeanPoo.Functional.TransformationResources` from immutable
commit `9fbdf863e5d4a4544267e84bc6bdad284d45c29c`, confirmed available on GitHub.
The Lake dependency declaration and Lean4.34.0 toolchain are versioned beside
the proof. This fixes dependency identity, not proof qualification; a generated
Lake manifest and import closure still need admission through the shared driver.
The unrelated dirty local lean-poo checkout is not a dependency input.

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

The shared driver must check exact proof/tool/import identities and the four
named theorem axiom inventories, reject incomplete proofs and false theorem
controls, and feed the results into existing ASCENT evidence evaluation. Until
then this obligation stays open. No independent Lean runner is introduced.

Two unqualified driver-control assets are retained under `lean/controls`:
`OmittedLifetime.lean` must fail elaboration of a false concrete conclusion;
`SorryWitness.lean` may elaborate but must fail admission because its named
theorem depends on `sorryAx`. Controls are separate from the positive library
target. Their intended outcomes are not yet observed results.
