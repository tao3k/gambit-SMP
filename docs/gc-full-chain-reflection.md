# GC Full-Chain Reflection

The structured Reflection is attached to
`notification-component-source-refinement` in
[`research-audit.json`](../evidence/research-audit.json).
It records unclosed requirements, acceptance conditions, gaps and contextual
References. It is not a prescribed execution order or a full-GC pass claim.

| Requirement | Status | Missing acceptance boundary |
| --- | --- | --- |
| Candidate identity | Partial | Whole source/configuration/linked artifact identity |
| Source refinement | Partial | Exact C recheck/return semantics and composed safety/progress |
| Payload ownership | Partial | Real tracing, forwarding, copying and publication visibility |
| Work closure | Partial | Native quiescence without fixture-forced termination |
| Phase composition | Open | Roots, strong/weak phases, tables, epochs and resize composition |
| VM lifetime | Partial | Rollback, failed joins, retirement and concurrent lifecycle |
| Native correctness | Partial | Four source031 regressions pass in both modes; full native/GC/lifecycle and remaining compiler acceptance remain open |
| Toolchain acceptance | Open | Bootstrap, Gerbil full build/tests, then performance |

`Partial` means related local evidence exists, not that a proportion of the
requirement has been proved. Acceptance conditions are unverified at this
boundary. They must not be marked complete merely because a Reference exists.

## References

Each Reference has an ID, kind, durable repository-relative artifact, locator
and scope. Source locations point through the pinned submodule/candidate lock,
not disposable `.data/` build trees. Papers provide design context; PR snapshots
provide reports; models provide abstraction contracts; receipts provide bounded
observations. These roles are not interchangeable.

The audit loader hashes all reference artifacts into its current input binding.
The graph exports `has-reflection`, `has-open-requirement`,
`requires-condition`, `context-reference` and `reference-artifact` edges.
These are traceability edges, not `supports-in-snapshot` proof edges, runtime
admission or release approval. Artifact binding checks freshness, not the truth
of a reference's prose or a theorem-to-source refinement.

The native ASCENT audit also exposes `unclosed_requirements`,
`pending_acceptance_conditions` and `requirement_reference_paths`. References
are joined by both issue ID and reference ID; an unrelated issue's similarly
named reference cannot supply the missing link. Having all References present
does not remove a pending condition. There is deliberately no rule deriving
runtime correctness from these contextual relations.

A complete chain needs independently checked acceptance evidence for every
condition and its composition with the others. The current schema deliberately
only permits `open` and `partial`; closure requires a separate admission
contract rather than changing a status string.

## Local Validation

The source031 eleven-file composition now has a durable scoped native archive
at `evidence/source-results/source031-native-gc-fixtures/archive.json`.
Its exact final identity passed serialization with concurrent forced GC,
table iteration with forced GC, pipe concurrency and ended-thread interrupts
in interpreted and compiled modes: four files per mode, respectively 0.660
and 5.086 seconds. Host-derived shared capacity selected three workers and
three child VM processors per worker, plus one processor per runner.
The assertion summaries and processor probe were checked. Runtime, full-GC,
release and production-performance admission remain false.

The explicit aggregate retry scope review retained historical 019/020/023
whole-suite compilation budget failures. It permits only this changed,
smaller diagnostic campaign under a non-expanded budget; it neither asserts
that each selected file previously failed nor closes those whole-suite gates.
Reflection retains eight unclosed requirements and fifteen pending conditions.
The source031-native Reference adds direct observation evidence, not a proof
edge. This is separate from the earlier six-file source029 diagnostic below.

After refreshing the source-retirement observation against the unchanged
source026 lock and current materializer, the actual native Datalog audit
returned `AUDIT-CHECKED`: eight unclosed requirements, fifteen pending
conditions and thirty-two requirement-reference links. It still reports two
source repair obligations, one unresolved source origin and five native
acceptance obligations. The focused archive, retry, native suite, identity,
Reflection, source-correspondence and graph suite passed 88 tests in 12.800
seconds. Its intentional DENY controls remain rejection tests, not runtime
test failures being relabeled green. The eight source-retirement fixture
schedules are local protocol observations, not native resource quiescence.

After adding the predicate-visibility model, the actual native audit retained
8 unclosed requirements and 15 pending conditions, with 29 requirement-reference
links. The focused Reflection/graph/audit suite passed 35 tests in 4.750 seconds;
the generic recipe framework passed 11 tests. The new recipe's five local Quint
controls passed and its retained receipt rechecked as `CURRENT`. These controls
do not discharge the payload-ownership condition or any native GC requirement.

The preceding local regression passed 63 tests in 7.256 seconds, including native
ASCENT audit/history queries, induction reuse, Reflection and graph tests.
The actual audit entrypoint reported 8 unclosed requirements, 15 pending
conditions and 28 requirement-reference links. This does not close any GC
condition. Reference validation also rejects repository aliases whose resolved
target is a disposable cache, for both References and nested artifacts.

The actual native ASCENT review for `gc_recursive_queue_wait` also exported
703 nodes and 1,257 edges. It retained 23 open native obligations and one open
finite-model claim. The command exited 2, with all six admission gates open:
component premises, finite-model receipt, source correspondence, native GC and
lifecycle, full bootstrap, and Gerbil build/full tests. Graph generation is not
an admission pass; no framework-validation receipt was supplied for this run.

The open source obligations include copy-queue memory ordering, snapshot
visibility during recheck, the repeated steal-loop abstraction, unbounded
spurious-return fairness, synchronization initialization/error handling, and
composition with recursive copying, general queue graphs, resize and phases.
These are concrete remaining boundaries, not reasons to repeat an unchanged
failed search or promote a component schedule into a full native GC result.

### Earlier Observation

On 2026-10-11, the focused suite passed 39 tests covering the audit loader,
native ASCENT review integration, Reflection validation and graph export.
The real `python -m gambit_smp.research_audit --check` entrypoint returned
`AUDIT-CHECKED` with these scoped results:

| Query | Rows |
| --- | --- |
| `unclosed_requirements` | 8 |
| `pending_acceptance_conditions` | 15 |
| `requirement_reference_paths` | 25 |
| `native_acceptance_pending` | 5 |

`AUDIT-CHECKED` qualifies the audit observation, not GC or runtime correctness.
This invocation did not run bootstrap, a native GC suite, or Gerbil acceptance.
The adapter binds `reflection.py` together with reference bytes so changes to
validation semantics invalidate earlier snapshots. These are local working-tree
results, not exact-head CI or a claim that all inputs are committed at HEAD.
