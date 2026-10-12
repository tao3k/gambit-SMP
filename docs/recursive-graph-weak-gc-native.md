# Recursive Graph And Weak-Key Native Control

## Route Review

The checked recursive GC protocol includes private work, cyclic discovery,
queue transfer and count restoration, but abstract objects are not native roots.
The historical mixed-key table fixture does not establish large recursive graph
closure. This distinct regression covers that missing physical observation;
it does not retry `_num.scm`, bootstrap or the held-lock observer failure.
Expected benefit is correctness evidence, not measured speedup.

## Fixture Contract

Every host-selected processor population has the same number of Scheme workers.
Each worker constructs 1024 vector nodes with a successor cycle, converging
cross edges, a repeated successor alias and a separately allocated list payload.
After construction, only node zero and a weak-key table are retained. The strong
construction index is not returned. The successor cycle must keep every table
key live; a vector retaining all nodes cannot substitute for that chain.

Each worker validates the graph before collection and after three explicit GC
calls, with yields permitting overlapping workers. Seven per-node conditions
plus the final cycle-root identity are checked at every validation. Joins check
the exact worker/result inventory. A successful run reports population, node,
forced-call and assertion counts, not an inferred number of collector epochs
or overlapping copy workers. Concurrent requests may coalesce; work stealing,
particular notification schedules and physical address relocation are not
claimed without instrumentation.

Compilation uses the exact GNU-backed source-regenerated candidate with p1 for
the compiler child. Execution selects the available host population, not a fixed
machine core count. Existing 60-second compile and 30-second process budgets are
retained. Failure stops the campaign; no timeout expansion or weakened assertion
is permitted. Source, runtime, driver, fixture and artifact identities must be
bound before and after observations.

The current QNT recursive model is audit context, not a proved simulation of
this fixture. Passing cycles and retained weak keys do not establish weak-key
reclamation, wills, all root kinds, forwarding races, arbitrary graph cardinality,
phase/retirement composition, full native suites, two-pass bootstrap or Gerbil
correctness/performance. Runtime and release admission remain false.
