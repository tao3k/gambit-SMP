# Recursive GC Induction Audit

## Proof Boundary

Quint 0.33.0 implements three Apalache queries for `--inductive-invariant`:
initial-state inclusion (length zero), invariant preservation from arbitrary
invariant states (length one), and implication of the requested safety goal
(length zero). The second query starts from the invariant, not the program's
initial state. This differs from merely finding no error in a short execution.
See the [Quint CLI](https://quint.sh/docs/quint) and
[Apalache induction documentation](https://apalache-mc.org/docs/apalache/running.html).

The installed `dist/src/verify.js` implementation was inspected directly:
SHA-256 `f36be4c7ab6439c1fbce5f64624b768f481dd5bc462dd22309b7139565331fef`.
Its compilation adapter `dist/src/cliCommands.js` has SHA-256
`574ff57f2d2c601b778d337fcbb64b74912c89c78738ca9f06060c965d5ad9bf`.

Safety induction alone does not establish termination, fair progress or native
Gambit correctness. The existing temporal requirement remains open. A future
ranking proof must establish a nonnegative well-founded rank, strict decrease
on every nonterminal protocol step, nonterminal enabledness and the stated
fairness assumptions. No rank proof exists yet.

## Real Checker Controls

The portable archive `evidence/model-results/quint-induction-phase-audit/`
contains the exact fixture, raw-log hashes, redacted logs and diagnostic receipt.
The updated five-control campaign completed in 22.119 seconds:

| Control | Seconds | Result |
| --- | ---: | --- |
| Correct invariant | 4.234 | All three obligations pass |
| Wrong initial-state inclusion | 4.224 | Rejected at phase 1 |
| Non-preserved invariant | 4.509 | Rejected at phase 2 |
| Insufficient safety implication | 4.391 | Rejected at phase 3 |
| Step leaving the generated domain | 4.567 | Rejected at phase 2 |

The last control prevents a finite symbolic domain from silently filtering a
real successor. A valid proof must establish `Init => D /\ I` and
`D /\ I /\ Next => D' /\ I'`, not merely preserve `I` inside a filtered domain.
The original `Next` must remain unchanged.

## GC Candidate Findings

`gc_recursive_queue_induction.qnt` imports the original protocol. Its arbitrary
symbolic initial states include unreachable states; counterexamples therefore
identify missing induction premises, not necessarily reachable/native bugs.
The original protocol transitions are not guarded by these new premises.
Reusable pure state predicates allow the symbolic initializer and the original
invariant to share the same safety definitions without copied formulas.

Three actual closure counterexamples were obtained:

| Archive under `evidence/model-results/` | Seconds | Missing relationship |
| --- | ---: | --- |
| `gc-induction-discovery-premises-deny` | 12.145 | Private copy can have invalid owner in the broad domain |
| `gc-induction-publication-premises-deny` | 15.664 | Pre-publication queue can differ from copier's queue |
| `gc-induction-lock-premises-deny` | 71.725 | Completed parent fields do not imply discovered child |

In the third trace, object 2 has completed eager head and tail while its child,
object 3, is still undiscovered. The last counted worker sets termination. This
prefix cannot follow the model's actual `finishHead`/`markTail` discovery rule;
the induction candidate omitted that relationship. It is not evidence of a
native termination defect. Add the relationship, then prove both initial
inclusion and preservation rather than assuming it.

Earlier tool failures are distinct: inequality-only initializers failed variable
generation, action composition failed preprocessing, and quantified sets of
functions failed expansion. They were not counterexamples or passes. The current
initializer generates typed maps and applies a pure predicate before assignment;
the closure target also checks the full generated domain after the original step.

## Reproduction

### Complete Transition Matrix, Still No Admission

The `gc-induction-all-actions/` archive records 24 passing symbolic obligations:
initial inclusion (15.663 seconds), all 22 original transitions (17.338-22.474
seconds each), and safety implication (16.080 seconds). Aggregate checker work
was 442.445 seconds; this sum is **not wall-clock time** because preservation
checks ran in pairs selected from host CPU and memory capacity.

Before this campaign, `resume` exposed a missing zero-count/termination relation
and `signalWork` exposed a completed region retaining its old queue ID. Both
counterexamples are archived separately and added to the observation catalog.
Neither is a native Gambit failure report. The resulting phase and queue
premises are checked after the unchanged original transitions.

All actions were extracted from the original protocol's public Quint parse IR;
none were skipped. Nevertheless `generatorCoverageProved=false`,
`inductiveSafetyAdmitted=false` and `temporalProved=false`. A manually defined
symbolic generator must cover the entire candidate domain before these checks
can establish induction. Direct checker-generated invariant states are being
audited with function-domain and record-field controls to eliminate this gap.
The historical countOrRetry receipt belongs to its older invariant snapshot,
not to the strengthened candidate automatically.

### Generator Contract And Tool Limit

Direct function-variable induction passed all three phases in 4.778 seconds.
An out-of-range successor and a missing map key were both rejected in phase 2
(4.579 and 4.519 seconds). The archive is
`quint-function-domain-induction/`. The corresponding record-field experiment
failed in 4.390 seconds: Apalache cannot generate the record variable from its
field constraints and reports "s is used before it is assigned". This is a
tool-generation failure, not a protocol counterexample. It is archived in
`quint-record-domain-generation-deny/` and must not be repeated unchanged.

`generator_contract.py` audits public parse IR for a deliberately narrow rule:

1. Every state field is assigned exactly once, from an independent finite
   `oneOf(D_i)` choice or a literal; the state record type is closed.
2. The invariant domain is exactly the conjunction of those component
   memberships and literal equalities.
3. The initializer applies exactly the same pure state predicates as the
   invariant, then assigns the whole record. No extra filter is allowed.

For any state satisfying that domain, choosing its field values in each `D_i`
constructs that state; identical pure filters preserve this correspondence.
The trusted rule is Cartesian nondeterministic-choice semantics. The audit
rejects unsupported syntax rather than approximating it, including dependent
domains, hidden filters, narrowed choices, ambiguous names, incomplete fields
and non-bijective assignments. Six mutation/control tests cover these failure
boundaries. It is a source/IR conformance certificate, not a solver proof of
the audit implementation itself: `solverCoverageProved=false`, and no whole
model/runtime/temporal admission is derived automatically.

The GC proof layer now writes its domains as explicit set memberships so this
correspondence is mechanically checkable. Original protocol actions remain
unchanged. New receipts bind the contract implementation, typecheck, proof IR
and exact model snapshots; older receipts retain their old proof-layer bytes.

The new domain-membership matrix completed all 24 obligations with stable
inputs: 22 transition checks each took 15.634-20.434 seconds, with aggregate
checker work of 426.906 seconds (not wall time). Its complete portable archive
is `gc-induction-cartesian-contract-ir/`, including public protocol/proof IR,
both model snapshots, raw-log attestations and the explicit contract boundary.
An offline regression replays the contract over that archived real GC IR;
the artifact is not required to be recovered from `.data/`.

The full local regression profile subsequently passed 367 tests in 10.850
seconds, with no failures, errors, skips or input drift. The following ASCENT
graph export failed because check-row `kind` collides with the node constructor's
`kind` parameter. This integration failure is separate from the passing tests
and blocks a complete evidence-graph PASS; it is not silently ignored. No source
repair, rebuilt runtime, bootstrap, Gerbil or performance acceptance follows.

Quint 0.33.0, Apalache 0.62.1 and Java are required. All model inputs and the
integration test live in the repository; ASCENT and prior caches are not needed.
Output directories must be new.

```sh
PYTHONPATH=src GAMBIT_SMP_INDUCTION_OUT=.data/induction-controls-new \
  python3 tests/integration_quint_induction.py \
  QuintInductionIntegration.test_initial_preservation_and_implication_are_distinct
PYTHONPATH=src GAMBIT_SMP_INDUCTION_OUT=.data/gc-closure-new \
  python3 tests/integration_quint_induction.py \
  QuintInductionIntegration.test_gc_candidate_obligation
```

The closure test currently expects an actual counterexample from a deliberately
incomplete candidate; a successful diagnostic test is not a successful GC proof.
Every receipt retains `accepted=false`, `runtimeAdmitted=false` and
`temporalProved=false`. No old timeout is reclassified as checked.

After adding the child-discovery premise and completed-region normalization,
both actual initial policies satisfied the full generated domain and candidate
invariant in 14.798 seconds. The snapshot and result are preserved in
`evidence/model-results/gc-induction-initial-membership/`. This establishes
initial inclusion only, not arbitrary-step preservation or temporal progress.
Use `GAMBIT_SMP_GC_OBLIGATION=initial` for this query. The original protocol's
action bodies are checked byte-for-byte against the sequential-probe archive;
the pure predicate extraction changed none of them. All nine actual TLC fault
controls were rerun and found their intended counterexamples (4.860-6.637 seconds
per check); see `gc-recursive-pure-predicate-controls/`. They are still controls,
not a positive whole-model proof.

The unchanged `countOrRetry` transition then preserved the entire domain and
strengthened invariant from arbitrary candidate states in 17.157 checker seconds
(17.160 seconds for the supervised test). Its portable snapshot and raw-log
attestation are in `evidence/model-results/gc-induction-termination-step/`.
This is one transition's induction obligation only. Preservation for the other
transitions, complete implication, enabledness, ranking/fairness and source/native
refinement remain open. Use `GAMBIT_SMP_GC_OBLIGATION=termination-step` to reproduce
this exact query rather than replay an unchanged timed-out full exploration.

The complete local framework profile passed 349 tests, with zero failures,
errors or skips, in 11.137 runner seconds. The local embedded ASCENT evidence
context retained eleven reusable component receipts and explicitly denied
execution/runtime admission because the recursive finite-model premise and
source/native premises remain open. This local full profile still includes
historical cache-bound inputs; it is not clean-checkout or native acceptance.
Context snapshot: `90ab34ae45082b48dbe2aed9973e9808d60658f2f99b79aca1c5676f5296e403`.

`evidence/induction-observations.json` now provides durable catalog pointers and
receipt hashes for the three counterexamples, initial inclusion and one-transition
preservation. Each observation records its exact partial scope. These records
are not yet exported into the ASCENT graph: the framework PASS above must not be
described as a graph containing or admitting these new induction observations.

After the catalog regression tests were added, the full profile was refreshed:
351 tests passed, zero failures/errors/skips, 11.313 runner seconds, no changed
inputs. Both new catalog tests are present in the expected and completed test
inventory. The evidence graph still does not export the new partial observations;
execution and runtime admission remain false.
