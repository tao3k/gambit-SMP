# Off-path serving-ticket witness

## Bound source

Source lock `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`,
revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, reader patch
`patches/fixtures/abandonment-gc-publication-reader-cumulative.patch`.
Candidate `include/gambit.h.in` is `ce419aeabb76835c5b7e69a225106b16016f4930bbc05ca66a450160d31f617a`.
Candidate `lib/setup.c` is `9e1d3b608f8b089435a5999e74a10ffea89e83a76318a8bc8b9a9b77a2a0cce3`.
This proposal does not modify those files, the ticket macros, or a build.

The retained failure is the uninstrumented compiled `thread_interrupt2_stress`
DENY. One OS sample placed 809/814 main-thread samples in
`___raise_high_level_interrupt_pstate`, on the processor-object ticket acquire
loop, with peers in `barrier_sync_op` / `_pthread_cond_wait`. That sample does
not name the lock owner or the elected operation.

## What changed the failure

`processor-ticket-observer.patch` (`852f43813b0f400d4b6321cbe499bbf026616bf9d34b8a28768eb28ee4875868`)
inserts a spin counter, `___ticket_holder_report`, and `___ticket_holder_note`
into `___TICKETLOCK_LOCK2`, plus a global `___ticket_obs_next` fetch-add.
Both diagnostic campaigns completed all four original files and never emitted
`TICKET-HOLDER-DISCRIMINATOR`. Those runs are a different program. They are
not observations of the retained failure.

On this candidate the uninstrumented macro still reserves with fetch-add, spins
in `___CPU_RELAX` until `___TICKETLOCK_READ_CURRENT` equals that local, and
then ends. The local `___ticket` is not in scope after the macro. Apple GCC
uses an acquire load for that read. There is no owner field.

## Proposal

Witness reads stay off the reservation, the acquire load, the spin, the unlock,
and any global counter. They do not call `pthread`, allocate, or write either
ticket word.

Owner. Read the serving word with the same acquire load the macro uses. Compare
it with residual slots inside each same-VM processor thread's current stack
bounds, without stopping the thread. Accept one owner only when exactly one
live range contains that word, the processor generation matches, the slot
sequence is even, and a second serving-word load closes the same value.
Several matches, no match, a generation change, an odd sequence, or an open
interval are inconclusive. A missing match does not show that the lock is free
and does not disprove ownership: the macro local may have lived only in a
register.

Barrier. `barrier_sync_op` still gathers child `sync_op1` / `sync_op2`, keeps
the smaller `sop.op`, and publishes the winner through `sync_op0` before
`SYNC_SEND_MSG`. The candidate send stores that payload, then a release store
of the message flag; the matching receive acquires the payload only after the
flag is observed. Accept an operation only from that published winner. Child
messages and the local entry `sop` are proposals. A sample inside the parent
wait, before `sop = sync_op0`, has not yet observed the winner.

Record. Each witness slot uses a monotonic sequence: odd is torn and is not a
record. A record expires when the serving word advances, the generation
changes, or the interval does not close. An epoch number alone is not expiry.

## What this does not establish

`models/gambit/ticket_offpath_witness.qnt` checks only the finite acceptance
rule. Its positive initializer assumes a residual spill. The model has no
release/acquire handshake, no compiler spilling, and no native scheduler.
`ticket_observer_snapshot.qnt` remains the checked snapshot and still does not
represent this proposal. No scope review is recorded. No native run, debugger
stop, or C edit is admitted. An off-path sampler can still change scheduling;
preserving the retained hang is a separate native question.
