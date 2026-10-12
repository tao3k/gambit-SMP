# Migration destination ownership

## Actual independent regression

The `startup-sync-flag-handoff` source/runtime passed startup and several GC
components. It does not thereby qualify thread migration or shrink requester
handoff. A new independent regression invokes `##thread-migrate-to!`, the
procedure installed as the C-return-on-other-processor hook, without pinning,
resize, sleeps or fixture-specific source branches.

An interpreted pilot reported target 1 and returned processor 9 in 0.123948
seconds, exit 70. Observation code can itself be interrupted in that mode, so
this pilot alone does not establish an incorrect immediate migration return.
Its exact original source is retained as `migration-interpreted-observation.scm`
alongside the non-admitted diagnostic receipt.

The improved fixture has a compiled `migrate-and-observe` function declared
`(not interrupts-enabled)`. It calls migration and reads the processor ID before
returning a value to the surrounding observable test code. Compilation passed
in 5.871301 seconds. Execution exited 70 in 1.100757 seconds: target 1, observed
processor 6. No timeout occurred and the process group was quiescent.

The runtime/fixture hashes were checked before and after execution. Host capacity
was detected automatically; the observed population on this machine was 12.
The recorded executable hash binds the compiled failing binary. No source repair
or global toolchain was changed for this regression.

## Generated observation path

Regenerating C from the staged fixture with the same identified gsc shows the
helper return label immediately tests the processor-ID primitive binding, then
executes `___SET_R1(___CURRENTPROCESSORID)` and returns. There is no `___POLL`
between migration's return label and that primitive read. This is regenerated
source inspection, not a claim that the deleted temporary C file from the
executable build was retained or that disassembly was checked.

The helper uses the primitive fast path when its binding is unchanged. The
fixture never rebinds it. Reproduction uses the selected runtime's gsc with
`-c` and the canonical fixture, rather than any personal absolute path.

## Source mechanism and design model

The scheduler's local queue extraction can select pinned entries. Remote
stealing rejects pinned entries, otherwise it can claim an entry after queue
publication. Existing migration publishes the unpinned entry, uses a busy wait,
clears the source current-thread field and calls the scheduler. A delay does
not establish that the requested target actually claimed the thread.

`thread_migration_destination_claim.qnt` represents donor, target and thief roles.
Its old control allows the thief to claim a published unpinned entry. The design
closes that claim window until the target acquires ownership, then restores the
prior user pin state before returning. Temporary pinning is one candidate gate,
not an implemented source repair or an instruction to permanently pin users.

Before implementation admission, the gate must be bound to scheduler/thread lock
order and actual target claim. Tests must cover initially pinned and unpinned
threads, consecutive migrations, cancellation/exception rollback and destination
retirement. Concurrent user pin changes must not be overwritten by a stale saved
pin value. Continuation storage and GC roots must compose with the saved-stack
retirement contract. The new failure is separate from the retained unpinned
shrink timeout, which must not be blindly retried.

Receipts are in `evidence/source-results/fixtures/startup-sync-flag-handoff`:
`thread-migration-target.json` and `compiled-migration-target.json`.
Full native, bootstrap, Gerbil and release correctness remain unqualified.

The old destination-claim counterexample has eight distinct states. The fixed
design passes safety and temporal completion over 14 distinct / 16 generated
states, including initially pinned and unpinned cases. The source/native-bound
receipt is `evidence/model-results/fixtures/startup-sync-flag-handoff/migration-destination-contract/receipt.json`.
It is registered in the Datalog bundle registry with five unresolved obligations.
No lock implementation or concurrent pin-mutation correctness follows from the
atomic model steps. The actual compiled failure is in `evidence/native-failures.json`
to prevent unchanged causal retry or accidental full-green admission.
