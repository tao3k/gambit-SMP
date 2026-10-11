# Tree Retirement Source Contract

## Concrete Reclamation Point

Candidate026 `barrier_sync_op` captures the old processor population. Every
parent sends to child1 and then child2, and each send publishes, unlocks and
signals before returning. The child can observe publication through the fast
receive path while the sender still owns the mutex or has not signaled yet.

During shrink, retired processors leave after the old barrier. Processor zero
joins retired threads. This does not join retained parents. In the checked
4-to-3 counterexample, processor 3 has exited and been joined while retained
processor 1 is still inside its final send to processor 3. Destroying processor
3's resources at that point is unsafe.

A narrower implementation candidate is a common retained-processor barrier
before the successful shrink returns: root enters after joining all retired
threads; every retained processor enters after finishing its old downward sends.
The barrier uses the new population, so it must not wait for retired processors.
Root may then reclaim retired synchronization objects. This is a source repair
obligation, not code already accepted. Failed-grow rollback, processor-zero
cleanup, VM teardown and external interrupt resources need their own ownership
paths; none is silently covered by this extra barrier.

## Model And Evidence

`sync_tree_retirement.qnt` models the actual binary-tree child relation and
retained-prefix rule for populations 2..5, with every valid shrink target. These
are verification bounds, not a runtime core limit. Downward publication,
unlock, signal, fast receive, exit, join and next-round admission are separate
actions. Destruction safety derives from the sender stage, not a policy-specific
PASS flag. Upward reduction is already complete in the modeled starting state;
full source refinement remains open.

Both unsafe policies have recorded counterexamples:

- Child destruction: 49 distinct states examined before violation.
- Join-only destruction: 1,741 distinct states examined before violation.

Join plus next-round admission passes safety and explicit progress over
**3,570 distinct / 10,935 generated states**, zero queued, **23.706 seconds**.
This is finite-model evidence, not native pthread, GC or bootstrap acceptance.

The campaign uses `verify_protocols.py` and the shared `quint_backend.py`, with
case metadata in `evidence/sync-tree-retirement-model.json`. There is no dedicated
Python runner. Portable results are in
`evidence/model-results/sync-tree-retirement-model/receipt.json`.

Attempts 001 and 002 remain DENY: shared-initializer conversion and a partial-map
lookup were modeling/tooling errors, not protocol counterexamples. Attempt 003
found the child counterexample but string decoding failed; attempt 004 recovered
that log and found the join-only counterexample, whose interval decoding failed.
Attempt 005 reparsed both original negative logs and ran only the unexecuted
positive check. Receipt/log hashes retain that history; neither original denial
was edited and no repeated native failure route ran.
