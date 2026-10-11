# Shared Pipe Predicate Lock

The cached PR1037 head is `80ba5a23c684f94a1a0259cde24cac47c943f7a9`.
Its four-line constructor repair was absent from runtime021. Runtime022 applies
that exact delta: both endpoints share one predicate mutex. Existing #988/#1038
and subsequent admitted local candidate changes are retained, not redesigned.

`pipe_wait` covers one message. `pipe_close_wait` composes two writes, a
one-item buffer, EOF, predicate checking and atomic wait registration. Two
independent old controls demonstrate missed data and missed close wakeups.
The fixed protocol exhausts 27 distinct / 39 generated states, with zero queue.
The source registers the waiter before releasing the predicate mutex.
These are atomic mutex/condition-variable assumptions, not a C weak-memory,
fairness or full scheduler proof. Timeout callbacks, repeated EOF/reopening,
unbounded FIFO chunks, simultaneous bidirectional schedules and GC are excluded.
The source builder requires both current model receipts and checks their input
hashes again after the build; a one-message proof alone cannot admit this patch.

Actual GNU GCC core rebuild: PASS, 52.718 seconds. `_io.c` was removed before
regeneration; all three core artifacts changed. This is not two-pass bootstrap.
The original `vect_port` and `write_shared` files pass unchanged in interpreter
mode (4.876 seconds) and compile/execute mode (30.368 seconds), two files each.

The exact upstream regression has Git blob
`eb54421075f30c44f043f692071a5c0672215c11`. Interpreter mode passes in 26.408
seconds. Compile/execute mode is DENY at the unchanged 60-second whole-mode
budget. A generated `_test.o1` exists. A diagnostic execution of that retained
module, not another suite admission, is DENY at 60.038 seconds and reports
unexpected EOF at client iteration 9864 and server iteration 9865.

Source audit distinguishes this observation from a lost-wakeup claim:
`##input-port-timeout-set!` converts the supplied relative value **once** through
`##absrel-timeout->timeout`. The pipe stores the resulting absolute deadline.
The upstream regression sets 10 seconds once before its 10,000-message loop;
it does not establish a fresh ten-second deadline for each read. An expired
deadline is therefore permitted even with correct predicate synchronization.
This is a source-established API contract, not a measured attribution of every
delay. No timeout is widened, assertion deleted, or original failure promoted.
`pipe_timeout_contract` now freezes the incorrect expectation that an open
port cannot return EOF after a once-set deadline. Its positive specification
recognizes expiration; this corrects diagnosis, not runtime execution or the
original fixture. `##read-u8` explicitly maps timeout EAGAIN to EOF. Deadline
rearming, timeout callback side effects and clock implementation remain open;
the two lock models cannot prove the original timed fixture green.

The first timeout-model verifier attempt was denied by sandbox localhost
binding. It is retained as infrastructure DENY, not a counterexample.
The second attempt uses the same model and budget with localhost permitted:
the old expectation produces a counterexample and the positive specification
exhausts 22 distinct / 43 generated states, with zero queue. Neither changes
the original timed fixture or admits a faster runtime.

Complete compiled-suite, bootstrap, Linux, Gerbil and performance admission
remain open. Do not rerun this unchanged denied fixture to seek a lucky pass.

## Per-Read Test Repair And Topology

`pipe_read_deadline` separately proves a test-policy obligation: rearming before
each read prevents expiration from a deadline set before earlier reads. True
per-read timeouts remain possible; no fairness or successful conversation is
assumed. The old control produces a stale-deadline counterexample. Positive
TLC exhausts 77 distinct / 110 generated states, with zero queue.

`test-pipe-read-deadline.patch` is test-only. It resets the same ten-second
relative interval before each endpoint read, retaining all 10,000-message loops,
three pipe types, pinning, joins and assertions. The cached upstream fixture
is unchanged; the runner records both its original and tested derived hashes.
The unchanged 60-second whole-mode budget is not raised.

The first rearmed run passes interpretation in 35.927 seconds but compiled mode
is DENY at 60.029 seconds. Its module exists about nine seconds into that mode;
this is not solely an incomplete compilation. The receipt also reveals 24
configured Scheme processors on a 12-CPU host (runner12 plus child12).
The generic adapter now uses a one-processor runner in both modes and reserves
that processor from the host-auto child capacity. It rejects explicit plans
exceeding this topology bound. A one-CPU host records necessary time-sharing of
runner1 and child1. External GCC processes are outside this Scheme-VM bound.

The changed topology (runner1, child11) passes interpreter mode in 31.404 seconds
and compile/execute mode in 49.264 seconds. Both modes exit zero with the exact
upstream completion marker, no failed assertions and stable source/proof hashes.
This is a model-bound fixture plus topology repair, not a runtime acceleration,
matched unchanged control or admission of the original timed fixture.
The previous denied results remain frozen. Full toolchain green remains open.
