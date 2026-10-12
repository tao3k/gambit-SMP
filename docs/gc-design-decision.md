# GC Design Decision Before Runtime Edits

## Evidence, Not A Transplanted Collector

The [GHC sections 3.1-3.5](papers/ghc-parallel-gc-2008.md) and
[HotSpot sections 3.1-3.3](papers/hotspot-parallel-gc-2001.md) motivate the
separation of private copy work, exported scan work and global termination.
They do not specify Gambit's condition variables, linker, VM lifetime or C
memory ordering. The pinned source and semantic source locks remain the
implementation authority.

The existing source audit identifies an unprotected interval between an empty
queue probe and wait registration. Existing controls reject signal-only,
recheck-only and inverted lock ordering. This is a protocol repair question;
it is not evidence that every reported SMP crash has this cause.

## Four Questions Before Choosing A Candidate

| Question | Current answer |
| --- | --- |
| Is the route supported? | Yes for auditing publication/wait composition: source sites and independent controls are recorded in [source obligations](gc-recursive-progress-source-obligations.md). Native attribution of the remaining compiler/forced-GC failures is still open. |
| Has it been explored? | The combined notification/recheck design, recursive safety, rank and wakeup counterexamples already exist. Reuse their exact receipts; do not repeat full explicit exploration or assume aggregate fairness solves worker starvation. |
| Is it worth changing? | A source-shaped fix can close a concrete notification protocol gap. A broader redesign is justified only if the smaller contract cannot satisfy ownership, termination and lifecycle requirements. |
| What is the expected benefit? | Correctness discrimination is established; runtime speedup is unknown. No paper throughput, model-state reduction or passing proof fragment predicts Gambit build/test time. |

## Competing Designs And Admission Conditions

| Candidate | Required contract | What it does not solve |
| --- | --- | --- |
| Preserve queues; close the Q/M wait handshake | Release Q before acquiring M to notify; recheck actual queues under M before idle registration; preserve producer accounting and nonzero count restoration. | Scheduler starvation, failed joins, partial module initialization, GC phase/resize composition and arbitrary weak memory. |
| Explicit work generation and participant ownership | Every private/exported work unit belongs to a phase; a persistent work-generation predicate changes before notification; registration observes it without a lost-wakeup interval; phase retirement waits for producers and borrowers. | An epoch counter alone does not account for unfinished copies, prevent premature zero count, establish memory ordering or guarantee a scheduled worker. |

The second row is a **design hypothesis**, not an implemented repair or checked
QNT model. It would change more state and needs a refinement map to the existing
queue/scan algorithm, initialization and shutdown. Do not select it solely
because it resembles another collector. Keep the first row as the current
minimal source candidate until the composition evidence justifies an alternative.

Both alternatives must retain recursive discovery, payload readiness, unique
scan ownership, repeated publication, actual registration/reacquisition, phase
closure and failure rollback. Unbounded spurious returns and per-worker fairness
must be represented separately. Adding fairness to make a counterexample pass
is not a runtime repair; the [wakeup audit](gc-wakeup-fairness.md) preserves this
distinction.

## Current Proof Boundary

The archived safety matrix covers initial inclusion and all 22 original action
branches. The ranking matrix covers all 22 branches and component bounds.
The new `gc_rank_actual_initial.qnt` connects both unchanged actual policy starts
to the candidate invariant and rank bounds. Its length-zero pass is not a
transition, enabledness, temporal or native proof. Necessary guard coverage,
conservative expression definedness and primitive controls remain separate
evidence, not a verified IR-to-action theorem.

Before C changes are admitted, close generator coverage and transition
correspondence, explicitly state the finite-model termination premises, and
prove or reject the divergence-sensitive mapping to real retries and wakes.
Then validate exact-source atomic schedules, full SMP/multi-VM lifecycle,
two-pass bootstrap and complete Gerbil tests with all three requested flags.
Only correct candidates reach the retained startup/build/test performance gates.

Rejection evidence stays in Git. A new name, new fixture directory or a passing
component does not authorize replay of an unchanged failed route.
