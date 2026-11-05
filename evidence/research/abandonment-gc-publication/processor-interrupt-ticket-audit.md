# Processor interrupt ticket, owner unidentified

Source lock `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
The text below is the materialized candidate
`.cache/fixtures/abandonment-gc-publication-reader-repaired/run/source/source`,
not unmodified `vendor/gambit`. No Gambit source file was changed.
`abandonment_gc_publication` is unchanged and still does not include this
C primitive-lock path.

## What the retained sample does not contain

The one-second sample places the main thread in
`___raise_high_level_interrupt_pstate` at the acquire loop (candidate
`lib/setup.c:375`, instruction offsets +32/+36) and two peers in
`barrier_sync_op` / `_pthread_cond_wait`. These values are absent, and without
them the owner and the barrier operation kind are not identified:

- The processor object's next ticket and current ticket. The sampled frame has
  reserved a ticket and is waiting for `current` to match. It is the waiter.
  The owner is the reservation whose ticket equals `current` and which has not
  executed the matching unlock.
- A stack for that owner. The sample does not show one.
- `sop.op` (and the winner id) of the peers inside `barrier_sync_op`. That
  function is shared by every collective operation.

The branch ambiguity in the rejected draft is resolved, not still open.
The native reader found exactly one definition in each of the two clauses.
Line 6426 belongs to non-SMP `else`, not the active SMP clause. See
`ticket-investigation-supervision.md` and the native branch-scope fixture.

A selector that mentioned undeclared `lit-skip` raised
`ascent.EngineError: undeclared relation` and returned no evidence slice.
The last successful clue checkpoint before that call remains
`clue-read:a182f9fe2c993c3dccd435d7be6d93b2d4942a796178479f16bbe02190ad591e`.
That failure is not a source result. Native interrupt2 remains
`STOPPED_NOT_COMPLETE_STRESS` under receipt
`5efadddd60a3d042de3631df26aad9c376cb4b638e1b103ab8d000e32f9c6ad3`.
This note does not rerun it. 6/12 stays historical progress.

## Source-reachable alternatives

C acquire and release, `lib/setup.c:375-392`: `___PRIMLOCK`, queue splice,
`___PRIMUNLOCK`, then `___raise_interrupt_pstate` of `___INTR_OTHER`.
`___PRIMLOCK` is `___TICKETLOCK_LOCK2`: fetch-add reserves `next`, then the
thread spins until `current` equals that ticket. The spin does not read
`INTR_SYNC_OP`. `___TICKETLOCK_TRYLOCK2` is a compare-and-swap of `next` and
does not reserve when it fails. The participating helper
(`lib/_thread.scm:690-700`) polls only on that failed trylock, then retries.
The raise path does not use the helper.

`lib/_thread.scm:1479-1496` locks the target processor with the participating
helper, reads the current thread and id, unlocks, and only then calls
`##raise-high-level-interrupt`. The Scheme critical section is not the holder
of the C reservation that the sample caught.

Holders that can still own `current` while that C spin runs:

- `lib/_thread.scm:2752` assumes the caller already holds the processor ticket
  and calls `##wait!` (`lib/_thread.scm:2657`), which blocks in
  `##os-condvar-select!` without polling `INTR_SYNC_OP`.
  `lib/_thread.scm:3138` is that caller; the matching unlock is
  `lib/_thread.scm:3152`. The empty run queue with neither a sleeper nor a
  device unlocks first (`lib/_thread.scm:3124`) and is a different path.
- `lib/setup.c:575-582` leaves the processor ticket locked until Scheme
  startup unlocks it. `lib/_thread.scm:3276-3279` unlocks before
  `___processor_startup_complete`, so `OP_PROCESSOR_STARTUP_READY`
  (`lib/setup.c:1508-1512`) is entered without that ticket, then the
  processor locks again for scheduling.
- Other short processor critical sections (run-queue insert, migration
  insert at `lib/_thread.scm:3299-3307`) release before they block.

Collective operations that enter `barrier_sync_op` through
`on_all_processors`: `OP_PROCESSOR_0_THROW_ERROR` (`lib/setup.c:963`),
`OP_PROCESSOR_STARTUP_READY` (`lib/setup.c:1509`), `OP_VM_RESIZE`
(`lib/setup.c:1542`), `OP_GARBAGE_COLLECT` (`lib/setup.c:1597`),
`OP_FDSET_RESIZE` (`lib/setup.c:1626`), `OP_ACTLOG_START` (`lib/setup.c:1646`),
`OP_ACTLOG_STOP` (`lib/setup.c:1664`). Direct `barrier_sync_op` calls also
carry `OP_NOOP`, `OP_SET_PROCESSOR_COUNT`, and `OP_VM_RESIZE_RESULT`.
GC rooting of the interrupt object across the participating retry is not
established by this text.

## Hypothetical cycle, distinct from this run

A holder-in-collective cycle would be a processor that still owns the
processor ticket inside `barrier_sync_op`. It could not unlock, and the
collective could not finish. The retained sample does not show that. The
spinner is the raise acquire loop. The peers are in `barrier_sync_op`.
The owner's identity is not established by the available stacks. The raw
reservation model explores this conditional cycle, not this run's cause.

## Repair Review

Not applied, and not a claim that it is the observed owner or operation.
Do not bootstrap this candidate again for the same bytes.

The draft proposal to delete the line-6426 definition is rejected by native
branch counter-evidence. Dropping the processor ticket around device selection
is also not qualified: the device-queue protection obligation must first be
established. Neither change is applied.

The corrected finite protocol represents actual reserve, served-ticket acquire,
failed-trylock participation, collective completion, relocation, publication,
release and notification transitions. Its alternatives are conditional repair
strategies, not current source behavior. A participating retry must preserve a
reserved ticket without reserving it again, or use failed trylock without an
outstanding ticket. `setup_processor_scmobj_pstate` marks the processor object
`___PERM`, so its ticket address is stable. The interrupt payload still needs
tracing and a refreshed reference after relocation. Notification must follow
publication and release. Negative controls
reach deadlock, stale access, an orphaned ticket or premature notification from
initially valid states. The original deterministic phase draft is retained as
`processor-interrupt-ticket-rejected.qnt`; it is not a protocol qualification.

Calling GC from the existing C spin without establishing the root contract is
not an accepted implementation of this protocol. A source implementation and
native discriminator for the unidentified owner/operation remain open.

Falsifier: original compiled `thread_interrupt2_stress.scm` only, original
completed-progress inactivity window (compiled stress 300 seconds), same
source lock plus this contract, no widened budgets, no second full bootstrap
of unrelated objects. A pass would show the contract is compatible with
completion. A stop with the same acquire PC, still without next/current,
owner stack, and `sop.op`, would leave the owner and the operation kind
unidentified. A stop with those three values recorded would identify them.
`models/gambit/processor_interrupt_ticket.qnt` is the finite obligation, not an
implementation refinement or native acceptance.
