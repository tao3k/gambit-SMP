# Recursive Copy And Explicit Wait Composition

This new model combines scanner-discovered copy work with explicit publication,
queue claims, wait registration, one-waiter signalling and activity restoration.
Four worker roles, two cyclic two-object graphs, two original producers and
one optional spurious wake per worker remain explicit finite bounds. Identity
discovery is distinct from the two copy units, visibility and scan eligibility.
Root eager heads remain counted until complete; helpers can become producers.
Current/proposed signalling policies retain separate positive initializers.

## Results And Denial

Typechecking passed. Four independent injected controls found the intended
counterexamples: early payload publication, duplicate scan claim, premature
producer idleness and omitted nonzero restoration. These are model controls,
not observed bugs in Gambit C.

The first positive source-policy check timed out at 90.014 seconds; the combined
policy was not launched. Intermediate temporal/state-space output is not an
exhausted proof. The unchanged timeout and DENY are preserved in
`evidence/model-results/gc-recursive-queue-wait-deny/`. No complete positive
receipt exists, and Datalog exports this model as pending, not checked.

## Campaign 001 Source Refinements

Source review identified two differences, independently of the timeout:

- The original model assigned queues by source-object group. Candidate027's
  queue fields are processor-owned (`mem.c:294-299`); `end_heap_chunk:3402-3457`
  publishes into the executing copier's queue. A helper discovering a child
  needs its own queue identity, not its parent's object-group identity.
- That model forced all scan work through export/pop. Actual local scanning
  (`mem.c:4450-4536`) can consume an incomplete allocation chunk's completed
  region without exporting it. Local/shared scan-frontier ownership must be
  represented together, preserving the unfinished producer-owned head.

Both obligations are explicitly exported in the manifest. The next model
revision must resolve them before source correspondence is claimed. Changing
execution parallelism does not close either gap or justify repeating the
timed-out positive unchanged. Arbitrary graphs, C weak memory, strong/weak phase
composition, resize, OS failures and full native correctness also remain open.

Independent control batching was tested separately as a framework diagnostic;
it grants no runtime or full-model admission. The new tracked-context manifest
uses reproducible source locks/overlay and Markdown notes. Earlier archived
campaigns retain their original cache-bound context instead of silently being
presented as checks of the migrated manifest.

## Processor-Local And Eager-Field Revisions

Campaign 002 represented all four processor-owned queues and local scanning of
unexported regions. Six controls found their intended counterexamples, including
incorrect origin-queue publication and re-export of a locally scanning region.
Its positive source-policy check timed out at 90.012 seconds; the complete
attempt is retained in `gc-recursive-queue-wait-processor-local-deny/` under
`evidence/model-results/`.

Campaign 003 then corrected the root-only eager-head abstraction. Every copied
object now has a copier-owned first field and scanner-owned disjoint tail.
Either field can win canonical discovery of its child; tail discovery, recursive
copy work and return from the original scan are separate transitions. Helpers
remain counted for their own incomplete eager heads, and an earlier tail return
does not erase the original copier's identity. Both fields point to the same
child in each finite two-object cycle, not arbitrary object graphs.

Seven controls found intended counterexamples. The added control makes a tail
scanner write the copier-owned first field. Typechecking passed, but the positive
source-policy check still timed out at 90.012 seconds. Its DENY is retained in
`evidence/model-results/gc-recursive-queue-wait-eager-fields-deny/`.

The following final-scheduling attempt reused those seven controls, retained the
same model and still reached its total watchdog at 90.141 seconds. See
[the checker audit](tlc-final-scheduling-audit.md). This is not positive admission.

## Sequential Probe Revision

Campaign 005 replaced the initial global-empty predicate with explicit local
drain and sequential unlocked negative queue hints. Completing one probe pass
does not require all queues to be empty atomically. Completed copy-owner history
is retired only after eager head, tail and notification settlement. Nine controls
found their intended counterexamples; the positive source-policy check still
reached 90.187 seconds with 404,195 queued states. Its DENY is archived in
`gc-recursive-queue-wait-sequential-probes-deny/`. The combined policy was not run.

The compact probe order retains only first visits from the real np=4 steal loop;
exact repeated-loop, stuttering and fairness correspondence remains open. See
[the induction audit](induction-safety-audit.md) for a separate proof strategy
and actual missing-premise counterexamples, not a replacement positive receipt.

## Remaining Source Interfaces

The eager pending-work set also does not yet refine the ordered C `goto again`
copy stack or the spatial scan frontier of a multi-object allocation chunk.
Existing per-object field-partition and chain models remain component premises,
not proof that these new composed interfaces satisfy the source implementation.
Neither the seven controls nor checker scheduling justifies another unchanged
failed bootstrap/native campaign.
