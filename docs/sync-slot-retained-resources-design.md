# Retained Slot Synchronization Resources

## Source Finding

The semantic Fixture `pstate-scan-lock-owned-lifecycle` already checks POSIX
mutex/condition initialization failure, but `setup_sync_op_pstate` still
initializes the pair every time `___setup_pstate` reuses a slot.
`___cleanup_pstate` does not destroy the pair. Initializing an already live
POSIX synchronization object is not valid resource ownership, even if the
previous receiver has exited. This differs from the repaired init-error path.

`SYNC_SEND_MSG` publishes before unlock and condition signal. `SYNC_GET_MSG`
can finish through its spin path immediately after observing publication.
Joining that receiver does not drain a different processor's send tail.
Destroying in child cleanup would therefore introduce a second lifetime bug.
These source facts come from the locked `lib/setup.c`, not an unpinned cache.

## Checked Design

`sync_slot_retained_resources.qnt` explores two slot incarnations sharing one
mutex/condition pair. Reuse resets messages but preserves the resource identity.
An old sender can unlock/signal after receiver exit and slot reuse. A late
signal carries no message epoch and cannot substitute for new publication.
Only VM-wide admission closure and complete sender drain permit destruction.

The complete repaired safety/progress search has 41 distinct states, 73
generated states and zero queued states. Three separate controls produce
ordinary exit-1 counterexamples: repeated initialization, child destruction,
and VM destruction without draining the old/new senders. The four-check
campaign took 16.481 seconds, under 90 seconds per check; controls use the
framework's automatic capacity and the positive temporal check stays serial.

Receipt and exact model snapshots are under
`evidence/model-results/fixtures/pstate-scan-lock-owned-lifecycle/retained-sync-design-contract/`.
The manifest binds the parent source lock/overlay. It describes a proposed
repair, not an implemented C guarantee. Its round-closure dependency records a
needed interface, not a joint proof of both models.

## Source Repair Obligations

The proposed implementation needs fresh-VM initialization of ownership metadata
for every possible slot, once-only successful resource setup, message-only
reset on reuse, rollback of a newly owned partial pair, and owned destruction
at a proven VM-quiescent boundary. Publication failure must still release the
private P0 prefix. Failed joins must not grant reclamation permission.

The model assumes sequentially coherent messages, closed external admission,
returning primitives and complete sender drain before VM destruction. It does
not establish those assumptions in C, OS initialization failures, arbitrary
generation/population, real wait/sleep semantics or full GC/bootstrap/Gerbil
acceptance. Do not mark the existing source repair obligation closed from this
design receipt. No candidate C bytes were changed in this design campaign.

## Reproduction

```sh
gambit-smp verify \
  --manifest evidence/fixtures/pstate-scan-lock-owned-lifecycle/retained-sync-design-contract.json \
  --out "$FRESH_MODEL_RUN" --timeout 90
```

Use a fresh output directory. The source context comes from the pinned
submodule plus the semantic Fixture overlay; local build caches are not inputs.

## Integration Validation Boundary

The four Quint/TLC checks and portable evidence publication passed. The
69-test integration run had five native ASCENT query errors; a fresh-process
single-query reproduction failed at `Engine.open` as well. These are not model
counterexamples or Gambit runtime regressions, and the whole suite is not green.

Source inspection identified the current retained wrapper's query shape:
45 catalog source relations plus 24 selected derived relations produce 69
relations. The needed dependency slice has only 51. The loaded native library
with SHA-256 `5c564e05a708d1e297985483c238086daf030e431a4747bca352e56e2da30672`
accepted an exact-schema 64-relation open/close control and rejected 65.
The actual 51-relation dependency slice opened, completed and closed natively,
returning all 20 requested relations. This diagnostic does not qualify the
production retained wrapper or replace the rejected full audit.

An earlier synthetic boundary probe incorrectly included a `name` field in
column descriptors, so both sizes were rejected. Correcting only the wire
shape produced the 64/65 boundary above. Retain that observer error separately
from the real bound; do not count either rejected probe as a GC counterexample.

The native 64-relation bound must stay intact. The generic query owner needs
identity-bound source-dependency slicing while preserving source authority,
reuse, invalidation and teardown. No production transport/provider edits or
inference fallback were made in this model campaign. Provider identity differs
from sealed engine006; its diagnostic result does not rewrite that seal or
admit a Gambit candidate.
