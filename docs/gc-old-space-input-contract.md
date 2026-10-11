# GC Old-Space Input Contract

## Source Fact And Model Boundary

At Gambit revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`,
`lib/mem.c:validate_old_obj` explicitly rejects an unforwarded movable object
inside current to-space. `mark_array` calls this validator only when GC
consistency checking and its runtime verbosity gate are enabled. Normal marking
does not first establish from-space membership before copying `MOVABLE0`.

The extracted-function duplicate-slot control demonstrates that a relocated
input can forward its canonical destination again. Distinct old-space slots
aliasing the same object and a legitimate tail-marked self-cycle do not have
that outcome. This does not establish native reachability or explain either
previous compiler SIGBUS incident.

The existing `gc_forward_publication` destination counterexample captures this
injected input schedule. Its positive model assumes valid old-space inputs;
it does not prove that all native roots and scan producers preserve that
precondition. A copied relocated reference in a fresh slot would have the same
input-contract issue; unique physical slot ownership alone is insufficient.

## Diagnostic Candidate 012

`diagnostic-old-space-input.patch` adds a Darwin-only fail-stop observer before
copying a movable header. It uses the existing section lookup and the current
processor's to-space offset. It reports the offending cell, object/header and
active scan context, then aborts rather than suppressing a second copy.

The observer is diagnostic, not an accepted repair. It does not validate every
object extent or detect every malformed reference. The previous high-address
and table-header probes remain active. Instrumentation can change scheduling.

The incremental GNU GCC core build exited zero. The p4 decoder's interpreter,
compiler and compiled test exited zero in 2.103, 9.937 and 1.037 seconds, without
probe denial. The fresh fixture snapshot stayed unchanged. This is one scoped
pass, not complete native stability or bootstrap acceptance.

The larger native control used 12 processors, matching the host CPU count;
the runner now selects host capacity automatically unless an explicit control
is requested. Its interpreter passed, but the compiler aborted in 0.198 seconds
with `GC-OLD-SPACE-DENY`. The rejected cell was 14 words into an active
22-word vector scan; its referenced movable header was `0x1070`.
This establishes a native invalid to-space input in that diagnostic run.
It does not distinguish duplicate scanning from an already-relocated payload
or prove that the previous SIGBUS incidents have the same cause.

The failed receipt and diagnostic log are bound to the model context in
Datalog as `native_observation`, not as a passing native adapter or a repair.
Do not repeat this unchanged failed configuration before auditing its producer.

## Scan-Entry Observation 013

The next diagnostic stores the first 64 payload words at scan entry and keeps
a bounded cross-worker visit table keyed by VM, completed GC count and body.
Table saturation returns unknown (`-1`); it never invents a first visit or
proves uniqueness. This diagnostic also changes scheduling and is not a repair.

Using automatic host capacity, interpretation passed in 2.254 seconds. The
compiler aborted in 15.178 seconds during strong scanning in cycle 147.
The containing object was a 7-word structure; field 5 already had the rejected
to-space reference at entry (`inputBefore` equals `object`). Visit count was
unknown. The bad input was already present at the snapshot; this does not
exclude concurrent or ABA writes, or distinguish an earlier scan from a
relocated payload producer. No unchanged retry is admitted.

The source unit now has five controls. A fresh slot assigned an already
relocated reference reproduces canonical-destination forwarding just as the
revisited-slot control does. Distinct old-space aliases, CAS loser rollback
and the self-cycle remain separate passing controls. The QNT payload-input
control is injected; neither it nor the diagnostic proves the actual producer.

## Body Visit Observation 014

Increasing the diagnostic table to 65,536 entries with 64 probes and mixed
pointer bits recovered a concrete visit count. The compiler aborted in 4.366
seconds: a 22-word vector body was visited twice in the same VM and cycle 50,
with a relocated input already present at the second entry. The active phase
was strong marking and processor selection was automatic host capacity.

This establishes repeated scanning of the same body address in that scope.
It does not yet distinguish queue re-claim, local cursor re-scan or illegal
allocation/address reuse. Source audit has not found the precise violating
transition; no masking skip or accepted repair is claimed. Bind the first and
second scan origins before changing queue/cursor ownership.

The segmented global-root table uses separately allocated C memory, not a
movable vector payload. Its direct root marking is not evidence of double
vector scanning. Setup flips all processors' spaces and initializes cursors
before a barrier; strong root processing also precedes a barrier. Do not
repeat the already-present root barrier proposal without contrary evidence.

Do not add a to-space skip as a repair merely because the injected source unit
passes. Establish which producer violates the contract, or explicitly model
and audit an idempotent collector architecture including publication, scanning
and termination before changing that contract.
