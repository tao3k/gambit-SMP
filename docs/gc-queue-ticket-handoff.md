# Completing Existing Repairs

The repair basis remains the useful mechanisms in PR988 and PR1038, not a
collector redesign. Their reported passes are evidence for those tested
configurations, not complete native, bootstrap or release admission.

## Queue Handoff Obligation

The active GNU GCC ticket-lock expansion reserves a ticket using a full-fence
atomic operation, then waits with a volatile load of the current ticket. It has
no acquire after that wait. The earlier reservation cannot acquire writes made
by the previous holder later. PR988's 36-file footprint and PR1038's three-file
footprint do not modify this header macro.

The candidate adds a shared-memory barrier immediately after each of three GC
queue consumer lock acquisitions in `lib/mem.c`. It does not change object
layout, forwarding, the Scheme table implementation or the global lock macro.
This is a portable correctness obligation, not a Darwin-only speed claim.

The bounded `ticket_queue_handoff.qnt` model distinguishes reservation,
prefetch, release, ticket observation and dequeue. The old control has a
duplicate-claim counterexample; the acquire control explores 13 distinct
states without violating its invariant. This is not a C/ARM refinement proof,
nor proof that the handoff is the sole native crash cause.

## Native Evidence And Diagnostic Cost

Candidate 015 records an owner-queue scan and a stealing scan of the same chunk
and body address in one VM/GC cycle. The old-space refusal occurs with
`scanActive=0`: the recorded previous vector is not proven to be the offending
parent. Address reuse and other producers remain open.

Candidate 016 retains the diagnostics and adds the three barriers. Interpretation
passes, but executable compilation hits the unchanged 20-second budget. Its
native receipt remains DENY. A valid same-binary 15-second LLDB observation finds
many workers at `scan + 260`; matching `mem.o` disassembly locates that offset at
the diagnostic visit-table atomic-lock retry. Other workers wait in GC condition
variables. This observes diagnostic contention, not proof of runtime deadlock
or of a broken queue repair. The first LLDB launch failed despite exit zero and
is explicitly invalidated; the framework now rejects such hidden failures.

Candidate 017 reverses every diagnostic patch, reapplies only the queue acquire
candidate, and requires exact recovery of candidate 009's source inventory when
that candidate is reversed. Incremental GNU GCC core rebuilding succeeds.
Native validation uses automatically detected host processors and unchanged
budgets. A passing atomic regression alone cannot close bootstrap, multi-VM,
complete native suites, Gerbil/package correctness or performance gates.

Candidate 017's interpretation passes in 1.727 seconds, while compilation still
times out at 20.007 seconds. Its portable receipt is
`evidence/model-results/native-queue-acquire-clean-host-timeout.json`; status
remains DENY. A valid same-binary 15-second observation places 11 workers in
`mark_reachable_from_marked` condition-variable waits and the remaining worker
in `barrier_sync_op`. This is distinct from the diagnostic-lock contention in
016. No worker count, GC epoch or barrier mailbox values are recovered from
these optimized frames, so a lost wake, phase mismatch or sole causal repair
is not established.

The next obligation is the interaction of scan termination and synchronized
GC phase entry. The current `gc_scan_termination` model assumes coherent queues
and acknowledged barriers; its success does not close this observed mixed-wait
state. Preserve the queue handoff counterexample, do not rerun the unchanged
017 native acceptance, and recover the missing state before extending that
model or changing the termination protocol.

The shared Python framework has 75 passing unit tests. Datalog verifies exact
model/evidence inputs but still reports 24 models without native adapters;
neither result is a complete SMP green claim.

## Follow-Up: Progress, Not Established Deadlock

The initial mixed-wait snapshot does not establish a stalled protocol.
Same-process observations with original optimization flags and isolated DWARF
show completed GC cycles increasing from 97 to 169 across two six-second
intervals. The first snapshot is in strong marking, the second in a barrier;
both are normal progress states. The O1 debug build observes another state and
cannot substitute for the admitted optimized artifact. These observations do
not justify a condition-variable or barrier repair.

The next source-bound candidate instead targets post-copy allocation admission;
see `gc-postcopy-headroom.md`. The queue-only timeout remains DENY, but is not
renamed a proven deadlock. Model validation does not justify changing a protocol
that has no diagnosed failure.
