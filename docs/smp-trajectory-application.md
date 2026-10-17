# SMP Application of ASCENT Trajectory Evidence

This is the downstream Gambit SMP application of the generic design in
`gerbil-ascent/docs/features/trajectory-exploration.org`. The generic API and
finite protocol model live upstream; this document does not define them.
Neither document is a native correctness, performance, or agent-efficiency result.

The upstream finite composition model is
`gerbil-ascent/packages/proofs/quint/TrajectoryEvidenceChain.qnt`. Its
`Append -> Admit -> Check -> ObserveContext/Explore -> Invalidate -> Resume` chain checks that
SMP's retained attempt stays historical after source replacement, that only
independently reviewed current evidence is exposed as a current result, and
that the context neither grants execution nor closes alternative hypotheses. The
SMP adapter must bind each abstract generation to the exact source/fixture/
toolchain identities in the actual receipt. Model checking does not replace
the Scheme evidence review, sealed action authorization, bootstrap, or native
stress tests.

## Existing SMP Inputs

- `reasoning_history.py` retains every observation event, including repeated
  facts. `evidence/dsl/history.ss` derives added, removed, retained, and changed
  input facts without rewriting old observations.
- `evidence/dsl/actions.ss` provides `OpenPrediction` and `Discriminator` for
  competing hypotheses. Observation presence alone does not prove a cause.
- `evidence/dsl/modeling-guidance.ss` emits optional, source-bound investigation
  windows and explicitly grants no execution permission or mandatory order.
- Native receipts, QNT outcomes, source correspondence, bootstrap, and stress
  have different evidential scopes. A model result must not become a native
  pass through the exploration packet.

The SMP adapter should map stable focus, obligation, hypothesis, operation,
source, result, and verdict references to upstream opaque identities. It should
not copy Trajectory storage, infer hidden model reasoning, or implement relation
evaluation in Python. Missing bindings yield an unknown comparison, never an
assumed repeat.

`trajectory-review.ss` emits evidence relations, not a `next` or `actions`
recommendation. An action ID in the adapter identifies an already discovered or
observed request; it does not narrow the model's future hypotheses or choose
its next experiment.

The `context` operation does not take an action ID. It replays retained attempts
into upstream Trajectory and returns their source-bound identities, historical
status, open predictions and discriminators without exposing result references.
A model may form an entirely new hypothesis from this context. `inspect` remains
a separate comparison against an already identified action; neither operation
ranks ideas or authorizes execution.

## A Concrete Continuation

Suppose rounds 1-7 run the same native stress on the same source and observe
the same failure. Before round 8, the packet can show that exact result, its
source and failure reference, and the still-open first-corrupting-write
question. The investigator may inspect that write, propose a different header
ownership hypothesis, or re-run stress intentionally to assess nondeterminism.
The packet records prior evidence and the open question; it does not enumerate,
choose or prohibit possible directions.

If the source, compiler, fixture, topology, or hypothesis changes, the old
receipt remains history but is not silently a current answer. A new native
failure may supply a valuable counterexample even when no SMP milestone closes.
An untested, unconventional hypothesis remains welcome even when it has no
immediate predicted observation.

## Downstream Measurements

Measure separately:

- Exact-current repeated attempts and their observed tool/model cost.
- Distinct `repeatCandidates` (later attempts with an earlier matching current
  observation), separately from all `repeatedObservation` evidence pairs.
  Five identical attempts create ten pairs but only four later candidates;
  neither count proves avoidable reasoning or wasted work.
- Similar attempts with changed premises or intentional replication purpose.
- New source-bound observations, competing hypotheses and distinguishing
  experiments proposed in a continuation window.
- Independently closed SMP obligations, native correctness, and total cost.

The claimed pattern of seven redundant rounds in ten is a measurement target,
not an established SMP statistic. Unknown token usage, interruptions, and
failed continuations remain visible. Reduced repeat count with reduced
hypothesis diversity or weaker native completion is a regression.

## Qualification Boundary

First replay a retained SMP prefix using only evidence available at that
point. `inspect` accepts an exact retained attempt ID as `through`; it replays
only that inclusive prefix and rejects an unknown endpoint, so later attempt
events cannot enter the packet. Each new attempt retains the digest of its
recorded-only snapshot. Retrospective replay requires that exact snapshot
digest at the endpoint, even if a later snapshot has the same source identity.
Older attempts without a snapshot digest remain readable as history, but are
not qualified for retrospective shadow review. The digest binds caller input;
it does not independently certify the historical snapshot or the reviewer's
judgment. Audit every upstream `ComparableEarlier` and `RetainedResult` reference
against the exact source and verdict identities. Compare matched later
continuations with and without the packet, preserving all failures. Do not
declare an SMP improvement from a generic upstream unit test, or an upstream
feature from this downstream mapping. Existing sealed native execution review
and budgets remain unchanged; exploratory context cannot override them or
impose its own budget.

## Rule Feedback Boundary

If an exact-repeat notice is contradicted by a source-bound SMP observation,
retain both the notice and the contradiction. It becomes a counterexample to
the comparison rule, not an instruction to rerun or abandon a hypothesis.
The upstream `TrajectoryRuleEvolution` model requires a revised rule to pass
prefix-only shadow evaluation and an independent current-source review before
publication. Review must bind the full identity and content of retained
counterexamples; equal record counts do not make changed evidence equivalent.
This is a formal design contract, not a deployed automatic rule
updater; SMP native receipts remain the authority for native outcomes.
