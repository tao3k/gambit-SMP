# SMP And Multiple Threaded VM Milestone

## Current Milestone Checkpoint

### 2026-10-19 Registry Lifetime Continuation

Cumulative completion is **8/12**, within the declared source-bound registry
qualification scope, not whole current-source SMP/release admission.
The current collective-wait source already contains reader admission, leased
replay, grace-before-resource-cleanup and changed-count publication repairs.
No duplicate C patch is introduced. Its original host-derived topology fixture
passes all selected 2-5 VM populations on this observed host: 1.481442 seconds
to compile, **1.262543 seconds to execute**, exit zero, no timeout. Native stage
3.522341 seconds; whole campaign 12.885300 seconds. All four successful build
stages are consumed without launching them; no bootstrap is repeated.

The existing multi-writer QNT model is strengthened in place: replay owns a
reader lease, with explicit prepared/live/visible/captured resource incarnations
and per-owner retirement. Another writer must drain captured readers before
publication; later readers referencing only new resources do not prevent old
resource retirement. The final protocol exhausts 1944 distinct states. Both
model positives and six negative controls pass within unchanged 15-second
limits; all eight explicit trajectory tests pass. This is conditional finite
protocol evidence, not a whole C weak-memory or unbounded signal-fairness proof.
See the [source/native/model record](../evidence/research/processor-interrupt-collective-wait/registry-lifetime-native-observation.md).

The five items open at 7/12 now have these actual states:

| Obligation | Actual state |
| --- | --- |
| Shared-registry lifetime | Closed for the current declared happy-path topology, source and conditional model contract; failed joins and arbitrary externally unjoined users are not admitted. |
| Lifecycle failure/rollback | Open. Earlier models and retained failure evidence do not supply complete current-source native fault/rollback qualification. |
| Complete GC/FFI | Open. Original stress and forced GC in this fixture are supporting coverage, not the whole GC/FFI inventory. |
| Gerbil correctness | Open. No complete Gerbil build/test receipt on this exact current producer. |
| Release performance | Open. No accepted full VM latency populations or matched downstream build/test qualification; this correctness execution is not a speedup measurement. |

Current-source full GSI/GSC and PR requalification remain additional release
requirements. Failed historical aggregates and stale whole-input bindings are
not upgraded by these new scoped observations or by cache availability.

### 2026-10-19 Original Interpreted Stress Completed

At this preceding checkpoint cumulative completion was **7/12**. The existing collective-wait
candidate completes the unchanged original interpreted stress inventory:
**4/4 files, exit zero, no timeout**, in **1828.146 seconds** (1844.205 seconds
including supervision). Source, configure, seed and core checkpoints were
reused without launching those stages; no bootstrap was repeated.

The source lock is `7a031c22c980c1314464f55208470d12ff56b95c4d4da3066698ba7eb3940e7b`.
The declared observer uses a separately loaded nonblocking datagram callback,
not interleaved human GC reports or Scheme-port forwarding. Its source/control
checks address allocation and report-framing interference; this is not proof
of universal scheduling noninterference. The 300-second genuine-witness
inactivity window is unchanged. GC progress alone grants neither mutator
completion nor runtime admission; the original assertions and natural exit
establish this stress result. See the
[source-bound observation](../evidence/research/processor-interrupt-collective-wait/gc-datagram-native-observation.md)
and [model/source audit](../evidence/research/processor-interrupt-collective-wait/gc-datagram-source-review.md).

The five gates cumulatively open at that checkpoint were:

1. Shared-registry lifetime, resize, reuse and retirement.
2. Lifecycle initialization failure, rollback and retry.
3. Complete GC/FFI qualification.
4. Gerbil build and test correctness.
5. Release performance, including complete concurrent-VM latency populations.

Current-source full GSI/GSC and PR requalification remain additional release
obligations; historical completion of those gates is not inherited by a changed
producer. The separate observer control does not close the GC/FFI gate. Earlier
timeouts and rejected observation contracts remain historical evidence below.

### 2026-10-18 Stack-Entry Contract Candidate

At this historical checkpoint cumulative completion was **6/12**; no gate is reset by cache
retirement. Complete compiled stress is newly closed on this candidate. The
historical five completed requirements remain recorded; because the compiler
changed, same-producer full GSI/GSC inventory and PR regression requalification
is still required before a current-source release claim.
The new frozen source is
`evidence/fixtures/darwin-stack-entry-contract/source.lock.json`
(`f0507df35d87eea34634047edc98e0cb9130bad77f24a63ca7bd131135c81dc4`).
It combines the parent call-boundary repair with stable partitioning of
compiler-private continuation labels and exact poll-combine dominance. Stack
checks are preserved, including ordinary warning-disabled calls. The rejected
warning-policy proposal remains counterevidence, not an integrated fix.

The label-partition model exhausts all 256 four-label kind sequences and checks
the measured kernel and dynamic-env return ordinals. Its old negative control
and replacement pass their expected exits; the separate nine-pair poll model
also passes. These finite checks do not establish source refinement or native
correctness. Full generated kernel/manual-entry alignment and both original
stress inventories remain required.

The stale construction source has been retired through the existing two-slot
storage policy, retaining small evidence. The new candidate is rematerialized
from the pinned vendor revision and complete overlay in the same construction
path, without stale generated C or binaries. All eight two-pass bootstrap phases
complete: native make 452.279 seconds, bootstrap stage 466.235 seconds, exit zero.
The original owner-only shutdown DENY is retained; the existing independent
final evaluation uses the original 10-second window and exports the exact
completed producer without recovering failed native stages or widening budgets.
The failed native records and small generated-C evidence are retained. Its old
verification source cache has since been retired through the guarded cleanup
API, freeing that same slot for the debug-projection successor. The completed
stack-entry producer remains in the other fixed slot; no third source role is
created. Retired cache availability is not a reversal of historical evidence.

The final generated kernel source matches the completed producer identity. All
14 handwritten kernel ordinals align with actual label definitions, while
dynamic-env-bind uses ordinary return 1 and internal stack-check continuation 2.
Its metadata table also preserves ordinary-before-internal return classes. See
`evidence/research/stack-entry-contract/abi-observation.json`. This is actual
generated-code evidence, not a captured historical fault PC.

Processor discovery now exits zero in 0.812 seconds. Complete original compiled
stress passes **4/4 files**, zero skips, failures or timeouts: 147.711 native-stage
seconds, 180.493 whole-run seconds, natural exit zero. Host-auto execution uses
three workers, each with three tested processors on this 12-CPU host. The same
producer's complete interpreted stress ends with one passed file, TFIB and
interrupt2 inactivity timeouts, and terminate not executed after the first file
in its shard times out. The original 300-second windows remain unchanged and
all process groups are reaped. Buffered child output does not establish either
internal useful progress or GC deadlock. These are correctness runs, not package
cold-build or release-performance measurements.

Same-producer full GSI/PR requalification exposes additional SIGSEGV failures;
the historical five gates are not represented as current-source passes. Two
system-generated crash reports match the exact current binary UUID and fault
offset. Static annotated assembly has identical text bytes to the built object
and maps the fault to `##local->value`, taking CDR of the empty-list value.
The partition allocator changes actual label ids, but debug-info generation
still uses identity ids from emission order. Runtime continuation/environment
lookup uses actual subprocedure ids, exposing a missing metadata projection.
See `evidence/research/stack-entry-contract/interpreter-crash.json`. The source
inconsistency is established; causality for every test failure and native repair
still require validation. No unchanged full-inventory retry is authorized.

The six cumulatively unclosed milestone gates are complete interpreted stress, registry
lifetime, lifecycle faults/rollback, GC/FFI, Gerbil correctness and release
performance. Additionally, current-source full GSI/GSC and PR requalification
must pass; the current candidate cannot inherit those four historical passes.
No model/framework pass closes any native gate.

### 2026-10-18 Call-Boundary Candidate

Historical completion remains **5/12**. The call-boundary source lock is
`evidence/fixtures/darwin-stack-call-boundary-reserve/source.lock.json`.
It adds stack-only checks at completed calls in interrupt-disabled code and
handler-frame reserve; it is an unqualified repair candidate, not a release patch.

All eight two-pass bootstrap phases complete with stable inputs: native make
733.909 seconds, bootstrap stage 753.268 seconds. An owner-only shutdown DENY
is retained, and the existing export independently revalidates its final review
within the original window. No failed native stage is recovered.

The original compiled stress attempt fails at processor discovery: **SIGSEGV,
0.726 seconds, zero stress files executed**. This is not four failed test files
or a complete stress result. The bootstrap identity binds generated `_kernel.c`:
inserted checks move the stack-handler body to label 4 while `setup.c` still
selects label 2. This establishes an ABI mismatch, not a captured fault PC or
proof that it causes this SIGSEGV. The native and source observations are retained
in `evidence/research/stack-call-boundary-reserve/native-observation.json`.

Grok's source audit also finds that conditional jump folding treats `'stack`
as a full interrupt poll. Its separate minimal delta and finite nine-pair model
are retained; the old counterexample and replacement characterization both meet
their expected exits. That delta is not yet integrated or natively qualified.
The handler-entry repair must precede another qualification attempt.

The seven open gates remain interpreted stress, compiled stress, registry
lifetime, lifecycle faults/rollback, GC/FFI, Gerbil correctness and release
performance. Candidate bootstrap completion and framework/model tests do not
close any of these gates.

### 2026-10-18 Preparation-Origin Producer

The `darwin-stack-prepare-origin` diagnostic now has a retained, source-bound
two-pass bootstrap producer. All eight native phases pass (each phase twice),
in 638.384 bootstrap-stage seconds. Configure takes 64.126 seconds and seed-core
101.375 seconds. These are toolchain-bootstrap observations, not MCP timings.

The original campaign remains **DENY**, with stable inputs and all stages PASS:
the evaluation owner was forcibly terminated during shutdown. A separate final
review under the original sealed implementation and original 10-second review
window exits zero naturally in 1.297 seconds, with its process group quiescent.
It retains the original failed owner receipt and does not rerun or recover a
failed native stage. The completed producer and revalidation hashes are bound by
`evidence/research/current-source-full-bootstrap/darwin-stack-prepare-origin-completed-producer.json`.

Framework corrections distinguish cache receipts from fixture-only source
leases, resolve the checkout through Git rather than the disposable `.data`
directory, and use the renewed stage deadline for owner shutdown admission.
The old input-drift and shutdown failures remain history, not current claims
that a producer is unavailable. Producer qualification alone grants no stress,
runtime-repair or release acceptance.
The unchanged four-file compiled stress then completes **2 PASS, TFIB SIGABRT,
interrupt2 TIMEOUT**. The 300-second inactivity watchdog remains unchanged;
all child groups are reaped. TFIB records `prepare_line=8078`, the return-zero
merge in `___stack_limit`, which does not distinguish a section switch from
the branch that reuses the section. The printed `ra` is write-time `___R0`,
not a captured preparation caller. Its allocation generation, effective poll
coverage and first administrative-header writer remain unknown. Reviewed
results and small original stdout/stderr files are retained by
`evidence/fixtures/darwin-stack-prepare-origin/native-observation-20261018.json`.
No unchanged native retry is admitted. Historical completion remains **5/12**,
with the same seven open gates below.

### 2026-10-16 Stack Write State

The current diagnostic source is `darwin-stack-prepare-origin`, locked by
`evidence/fixtures/darwin-stack-prepare-origin/source.lock.json`. Its native
qualification is blocked by input drift. It adds the last preparation call site and return
label to the existing pre-store observer; it does not implement a runtime repair.

Its `from-scratch` command exits zero in 209.533 seconds and records each of
the eight phases. Concurrent work changes `suite-review-rules.ss` while that
run is active; publication therefore rejects the workspace state and the
terminal review is STALE. No completed producer is exported and no origin
stress is launched. The original receipt is retained in
`evidence/fixtures/darwin-stack-prepare-origin/bootstrap-input-drift-20261016.json`.
An observed successful make command does not close that failed producer gate.

Its parent `darwin-stack-write-boundary` completes both bootstrap passes and
the final ASCENT review: phase1 through phase4 each execute twice; native make
takes 230.872 seconds, the bootstrap stage 240.465 seconds, and the complete
seed-consuming child 258.887 seconds. The completed producer is retained in
`evidence/research/current-source-full-bootstrap/darwin-stack-write-boundary-completed-producer.json`.
Original configure/seed and the denied reviews remain retained separately.

That parent's complete original compiled stress is **DENY**: two files pass,
TFIB aborts at the pre-store diagnostic, and interrupt2 reaches its unchanged
300-second timeout. At `_thread.c:11361`, `SET_STK(9)` has `fp=floor+32` bytes,
target `floor-40`, saved fp `floor+192`, owner limit `floor+65552`, and trip
equal to the section top. Both poll thresholds exceed the recorded fp. This
does not establish the last preparation path, an intervening effective poll,
live allocation generation, or a store to the administrative header.
The exact source, producer, process/log hashes and arithmetic are retained in
`evidence/fixtures/darwin-stack-write-boundary/native-observation-20261016.json`.
No unchanged native retry is admitted.

The poll-coverage refinement now passes all three checks and native ASCENT
review after an equivalent pure initial-state constructor fixes Quint QNT409.
The original conversion failure remains DENY. Covered polling exhausts 172
states, absent polling yields the required negative trace, and the abort-only
observer exhausts 406 states. This is finite-model evidence, independently of
the native failure. See `model-observation-20261016.json` in the same fixture.

Historical completion remains **5/12**. A new diagnostic source does not inherit
native acceptance. The seven open gates remain both complete stress modes,
registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness and release
performance. The already reviewed whole-wall producer denial below stays
retired; neither the new abort nor the new timeout is retired by that decision.

### Earlier Causal Checkpoint (Retained)

The current unqualified source is `darwin-shared-stack-reservation`, locked by
`evidence/fixtures/darwin-shared-stack-reservation/source.lock.json`. It changes
only `lib/mem.c` from the parent below, with Darwin/GNU-only pending GC-frame
reservation, relocation destination and shared undo bound restoration.

The composed partition model exhausts 486 legal states and admits both original
boundary-loss controls. Two-pass bootstrap and final ASCENT review pass:
130.873 native make / 138.396 stage / 150.220 child whole seconds. The successful
seed prefix is reused in 3.582 seconds; its original failed review and inputs
are retained, not rewritten.

Original compiled stress completes **3/4 PASS, TFIB SIGABRT, zero timeout** in
55.765 native-stage / 67.913 child whole seconds. Interrupt2 passes this round,
but stability and its relation to the old timeout are not established. The
candidate remains DENY and completion remains **5/12**. A completed bootstrap
is not a completed stress or release gate.

The new TFIB pre-store record again finds a damaged catalog-member header:
member 1495, index -1368899887, position 9, stored next equal to the invalid
selected result. Position is in range but does not match the catalog slot.
First writing access and live allocation generation remain open. See
`shared-stack-reservation-native-result.md`; no unchanged stress retry is
admitted. Existing ticket acquire repairs are already present in the parent
header and are not a new unchecked barrier route.

### Parent Native Observation History

The parent unqualified source is `darwin-shared-successor-snapshot`, locked by
`evidence/fixtures/darwin-shared-successor-snapshot/source.lock.json`. It inherits
the selection-origin/heap-frame identity chain, not either rejected allocator
layout below. Only `lib/mem.c` changes from the selection-origin parent, and
Linux retains the original loop. Completion remains **5/12**;
cache presence and model-only results do not change that count.

The pre-store successor discriminator now observes actual member header damage:
selected equals independently loaded stored next, predecessor remains catalog
member 1053, but index=-44 and pos=-1. Both bootstrap passes and final review
pass; unchanged compiled stress remains two pass / TFIB abort / interrupt2
timeout. Header damage is imported into the composed QNT; first writer and live
allocation generation remain open. See `shared-msection-header-damage.md`.

That parent candidate's native two-pass make takes **170.915 seconds**;
bootstrap stage **175.786 seconds**, whole child recipe **299.996 seconds**.
All six stages pass. These are not the parent candidate's timings and are not
a performance acceptance result.

The current unresolved gates are interpreted stress, compiled stress,
registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness and release
performance. A historical accepted gate does not reset when its cache is
cleaned; a new unqualified candidate does not inherit native acceptance.

### Superseded Observation History

The parent `darwin-gc-complete-probe-round` completed bootstrap (117.700 native make /
122.212 stage / 190.056 child whole seconds). Its complete unchanged compiled
stress remains DENY: two pass, TFIB SIGABRT, interrupt2 timeout. The TFIB record
now identifies `fresh-allocation`, an unaligned selected/post-update cursor,
zero private pool, zero custom allocator and zero to-space offset. This retires
the private-pool attribution for this execution, not the historical failure.
The shared-cursor observation was imported into the composed QNT without inventing
a stored-next write. The successor above resolves the missing predecessor and
stored-next observation; those are no longer current gaps. First writer and
live allocation generation remain open. See `shared-msection-fresh-return.md`;
the parent candidate is not accepted.

### Current Decision Versus History

The old whole-wall owner-teardown denial is **retired, not an active blocker**.
Its original receipt remains immutable History. A checked completed-producer
decision binds the same receipt, completed stages, final ASCENT review and
normally reaped owner. The real compiled-stress review reports:

- `active_historical_producer_denial`: empty.
- `current_producer_admitted`: `producer`.
- `retired_producer_decision`: the historical producer receipt.
- `missing_step`: `stress-gsc`, independently of the retired accounting denial.

The executable relation lives in `evidence/research/producer-decision-rules.ss`;
the native answers are retained in the owned-undo compiled-stress run. Missing
supersession evidence leaves the historical denial active; a different receipt
cannot retire it. A new native failure cannot be retired by this accounting rule.
History is consulted for provenance, not used as a cumulative fresh-stage timer.

The historical selection-origin diagnostic and standalone full TFIB observation
both time out without a selection record. The sampler produced no valid stack
report, so these results do not establish the corrupting writer or a stall cause.
The existing core was reused in 4.534 seconds with zero copied source files;
the prior 481.238-second run remains History, not a consumed fresh-stage budget.
Neither reuse nor a diagnostic timeout closes another milestone gate.

Host-sized atomic TFIB now passes with 12, 96 and 384 concurrent roots on the
same core and 11 actual VM processors, taking 2.677, 27.094 and 94.144 native
seconds. The composed undo-cursor model admits a conditional stale-snapshot
counterexample, but source reachability while undo remains eligible is still
open. See `stack-selection-occupancy-and-undo-cursor.md`; these observations
do not replace the complete 5,000-root stress gate or establish a runtime fix.

The instrumented complete workload is now a separate native progress failure:
503/5,000 root results are correct, then the original no-root-completion window
expires (1,073.301 native seconds, exit -9, process group quiescent). It is not
an obsolete whole-wall denial and not an observed illegal selected section.
The failure and the missing internal-work/root-dependency liveness refinement
are bound in `native-progress-model-feedback.json` under the current fixture.
No unchanged retry, source-cause claim or sixth milestone gate is admitted.

### Rejected Candidate History

The pool-link layout predecessor below remains a native DENY. Its rejected
successor moved first-break raw undo state into section-owned metadata,
without inheriting that failed layout change. The existing QNT checks the
separate saved-pointer fault envelope and the 6,048-state ownership protocol;
all three checks and ASCENT pass in 35.336 child whole seconds. This does not
establish the native writer or qualify a repair. Both exact-source bootstrap
passes and final ASCENT review pass (254.307 native stage seconds).
The obsolete whole-wall owner-teardown DENY is retained as History and
superseded by a checked completed-producer decision; it is not an active gate.
Complete compiled stress finishes DENY without rebuilding: two pass, tfib
SIGSEGV, one timeout (306.829 native / 336.862 outer seconds). ASCENT retires
the old accounting verdict but independently rejects this native result.
The successor is not accepted; no unchanged stress retry is admitted.
The joined first-write PC alone does not establish pool versus fresh selection.
See `section-owned-undo.md` for scope,
clearing sites, Linux boundary and the seven remaining gates.

The earlier pool-link candidate changes only `include/gambit.h.in` and `lib/mem.c` from the
heap-frame diagnostic parent. On Darwin GNU, a raw `pool_next` field replaces
the pool link in `base[0]`: both stack/heap pop sites and the overflow-undo push
use the same field. Linux keeps the original layout and in-band link. Allocation
size follows `sizeof_msection`; all ABI consumers require a complete rebuild.
There is no added lock, list search, section discard or normal-path logging.

The existing allocator QNT now distinguishes metadata from payload and checks
an explicitly labeled escaped-payload-write envelope. Its 6,048-state legal
protocol check still passes; all five negative controls are admitted, including
the in-band alias, and the separated-metadata envelope passes. Whole framework
time is 76.915 seconds. The exact earlier model bytes are retained under
`models/gambit/history/stack_allocator_frame_lifetime.qnt`; earlier receipts
and native failures are not rewritten. This does not identify the native writer
or prove frame lifetime. Eight source/evidence boundary tests pass. Full
bootstrap and unchanged compiled stress are required before repair admission.
The native bootstrap stage now completes both passes in 225.830 seconds,
with exit zero and the exact eight-phase inventory. The original whole-run
DENY from an undispatched final review remains immutable. That review alone
was revalidated through the original sealed ASCENT runner, without rebuilding
or recovering any failed native stage. Its completed producer is recorded in
`evidence/research/current-source-full-bootstrap/darwin-section-pool-completed-producer.json`.
Complete compiled stress through the updated framework seal is DENY:
three of four files pass, tfib exits with signal 11, zero timeouts;
79.548 native-stage / 96.883 outer seconds. The matching image again faults
at `___stack_limit +140`, before frame transfer. Metadata separation is not
an accepted repair. No unchanged native retry is admitted.
The existing QNT imports this selected-section failure independently of payload
aliasing: the two-state entry-contract negative control is admitted and the
three-state separation-only positive remains conditional. Both pass through
the sealed framework and ASCENT in 54.460 child whole seconds. These checks
do not identify the missing native writer. The earlier model's exact bytes
remain archived and bound to the completed bootstrap producer.

The source audit found exactly one pool push and two pool pops. No extra pool
reset or continuation invalidation repair is reapplied. This hypothesis tests
the architectural metadata alias exposed by the native entry requirement;
if stress still fails, retain the result rather than claim a full repair.

The heap-frame diagnostic's immediate parent `darwin-frame-ra-boundary` retains the public BTQ
diagnostic, changing only the Darwin GNU
descriptor entry boundary in `include/gambit.h.in`. All seven RETN/RETI
descriptor macros check the necessary RETURN tag before metadata access.
Incorrect tags report the generated call site and value, then abort. Valid
tags still do not prove address, extent, descriptor or lifetime validity.
This is one diagnostic over the existing capture/scan/return chain, not a
new independent model or a release fix. Its review contract records relevance,
prior exploration and the expected diagnostic benefit without a speed claim.

The heap-frame diagnostic successor retains that parent and changes only the Darwin GNU
heap-return branch in `lib/_kernel.scm`. It checks the actual object's FRAME
subtype and minimum extent before loading RA, then reports header/type/length
context if the RA tag fails. This distinguishes wrong-object consumption from
an invalid RA in a FRAME-typed object; neither consistent headers nor tag checks
prove allocation generation or lifetime. Exact-source two-pass bootstrap now
passes (145.425 stage / 227.140 child whole seconds). Complete compiled stress
is still DENY: three pass, tfib SIGBUS, zero timeouts; 68.218 native-stage /
78.961 outer seconds. No new heap-identity or RA diagnostic fires.

The exact-image failure is mapped to `___stack_limit +140`, mem.c:7720, the
new first-break NULL store following section reuse. Production and debug text
and named text relocations match. The computed stack start is not word aligned;
the original corrupting writer is unknown. This is retained in the current
fixture's `stack-allocation-symbolization.json`, not attributed to a prior
incident or to a child PID that has not been bound.

The linked-pool/captured-root/semispace model now exhausts 6,048 distinct states
with safety and weak-fair finite-prefix completion. Three protocol-omission
controls and one separately labeled invalid-entry observation import produce
decoded counterexamples (41.528 whole seconds). It does not establish a legal
source transition producing the native corruption. Earlier type/vacuity/trace
rejections remain retained, not promoted to proof. The existing Evidence view
keeps the native DENYs and four source gaps when both model contexts are
withdrawn. See `captured-heap-frame-operations.md` for bounds and assumptions.

**No sixth gate or validated source repair has been established.** The seven
remaining gates are interpreted stress, compiled stress, Registry lifetime,
lifecycle faults, GC/FFI, Gerbil correctness and release performance. Proceed
from the metadata writer/alias requirement; do not run the same diagnostic
again, widen a watchdog, or call model PASS native closure.

The initial bootstrap attempt compiled the core but was denied before bootstrap
because the inherited ticket review's current header hash no longer matched.
The next attempt was denied before compilation because its retained workspace
state predated the successful configure/seed mutation. Both failures remain
immutable. The corrected attempt binds actual current source bytes and the
seeded tree through the existing source lease and review mechanisms. `--prior`
retains failures and requires an input delta; it is not automatic prefix resume.

The corrected candidate completes both bootstrap passes in 177.213 stage
seconds (259.962 child whole seconds). Complete compiled stress remains DENY:
three files pass, tfib aborts with one shared-decoder observation at the heap
return consumer, `_kernel.c:12002`, RA `0x12800`, tag 0; zero timeouts.
Native-stage time is 57.412 seconds, child whole time 66.275 seconds, outer
time 67.949 seconds. This distinguishes a concrete necessary-tag violation
from a silent SIGSEGV, not the corrupting writer. Wrong frame identity and
later RA overwrite remain unseparated; no sixth gate closes. See
`captured-heap-frame-operations.md` for the retained observation and next
discriminator.

The immediate workstream is one causal chain:
**saved-frame ownership -> frame construction/copy -> publication/scan ->
heap-return consumption**. The exact-image incident establishes an invalid RA
load at the consumer. It does not yet establish the corrupting writer, a
particular test's child PID, or a common cause with the older BTQ incident.

| Boundary | Established | Required before a runtime repair |
| --- | --- | --- |
| Thread initialization | Active SMP `macro-make-thread-cont` creates an END-marked continuation, not `##make-frame` | Establish the failing frame's actual producer; do not attribute it to the generic constructor from name similarity |
| Generic heap-frame construction | `##make-frame` saves/restores `ret` across allocation and initializes the allocated frame from it | Establish a relevant caller and invalid input or allocation transition before changing this constructor |
| Captured-frame copy | RA is copied first; a shared MISC lock protects capture; the next stack RA is restored before traversal | Bind the actual input frame, descriptor, stack ownership and allocation generation; these are assumptions in the finite coordinate model |
| Publication and scan | Private chain publication and the root-phase barrier are already in the candidate | Identify a violated transition before adding another fence or serializing GC |
| Stack section reuse | Free-list state is per processor; overflow undo has explicit invalidation paths | Establish an escaping reference to a reused section before proposing a lifetime repair |
| Heap return | Object code maps the failing RA load and metadata decode | Connect that value to its producer; a consumer guard alone is diagnosis, not a repair |

Do not start an unchanged full stress run or create another isolated protocol
component to substitute for that missing source connection. A new candidate
must name the violated transition, the corresponding model counterexample,
the exact source change and the native observation that can refute it.
Existing negative observations remain attached to their original identities.

Execute an admitted repair as one source-locked qualification cycle: checked
counterexample/control, source correspondence, complete bootstrap, all four
unchanged compiled stress files, then the remaining grid. Native failure feeds
back into the same causal chain; a local PASS does not trigger a separate
milestone or a new full source cache. Keep host-selected concurrency, all SMP
and multi-VM flags, and the existing progress watchdog semantics.

### Explicit Twelve-Gate Count

Captured-frame operation modeling now covers physical RA/link coordinates,
two-alias MISC capture ownership, private chain publication, raw/typed link
scanning and heap return consumption. Safety and weak-fair completion exhaust
1,080 states; all six controls fail as required (47.012 whole checker seconds).
The actual configured GNU header passes 18,496 coordinate shape pairs (14.558
whole seconds). The native heap-frame incident and two source gaps remain;
valid input identity/extent/descriptor/RA provenance are still assumptions, not
a runtime fix. See `captured-heap-frame-operations.md`.

The current reused workspace now contains the diagnostic-only
`darwin-btq-public-provenance` successor. Both bootstrap passes pass (160.784
bootstrap seconds, 271.966 whole seconds). Complete compiled stress remains
DENY: 2 pass, 1 SIGSEGV, 1 original 300-second inactivity timeout; 318.154 whole
seconds. No BTQ/FFI probe fires. A new exact-image/object-bound incident is at
kernel heap-frame RA metadata decode, generated line 12002; no child PID or
common-cause claim is admitted. Its heap-frame source requirement now has the
conditional coordinate model above, but no established source repair.
Earlier compiler-failed diagnostic/source locks and all
native denials are retained. This does not add a sixth gate or replace the
release baseline. See `btq-edge-provenance-diagnostic.md`.

Source audit corrected a physical-model gap: black is a queue reference, not
a boolean, and mutex/condvar queues can move. The movable-queue/color/container
successor exhausts 40,567 states with safety and weak-fair completion. Seven
fault controls yield decoded counterexamples, including missing color and
container scans (72.356 whole checker seconds). It remains model-only; the
retry review still denies unchanged stress. Prior timeout/identity-invalid runs
are retained. See `btq-queue-relocation.md`.

The exact configured-header BTQ word classification passes (12.705 whole
seconds): the captured child has tag 7, not STRUCTURE tag 1, and valid aligned
forwarding of a structure reference preserves tag 1. Wrong destination alone
is insufficient under those premises; payload provenance, layout and header
lifetime remain open. This is not crash causality or another native gate.
See `btq-incident-word-provenance.md`.

Failure-premise review now runs through the existing Scheme DSL/ASCENT and
read-only action discovery. The current diagnostic's checked model does not
justify retry: relevant source change, source review and source correspondence
are absent. Missing premise classification also denies review eligibility.
Focused contract/action tests pass 7/7; the preceding combined Evidence suite
passes 37/37. This is not an execution veto or native gate closure. See
`failure-premise-review.md`.

The BTQ/copy-epoch composition now exhausts 22,961 states with safety and
weak-fair completion; all five faulty-protocol controls yield decoded
counterexamples. Its registered Evidence view preserves the native DENY and
open source-refinement requirements when model context is withdrawn. This is
model/evidence progress, not another native gate; see `btq-copy-epochs.md`.

**Cumulative milestone completion: 5/12 (41.7%). Complete GSC and its
declared PR regression coverage now have checked current-source execution
evidence. This count is not an estimate of engineering
effort or a claim that the latest candidate is fully green.**

Historical repair successor: **`darwin-ticket-ownership-acquire`**. It retains the
23-file ALLOC predecessor, changing only production ticket ownership polling
under Darwin/GNU. The composed ticket/BTQ model exposes the allocator-only
policy's stale-selection counterexample; the acquire policy exhausts 13
states safely. Actual configured-header pthread handoff and object codegen
pass. Complete two-pass bootstrap passes (138.169 seconds bootstrap stage,
212.747 seconds whole run, host-selected 12 make jobs / compiler p1).
The unchanged compiled `tfib_stress.scm` passes 1/1 (14.728 seconds stage,
23.661 seconds whole run); the ALLOC-only native failure remains retained.
This targeted pass does not close full stress or establish crash causality.
The subsequent complete compiled stress remains DENY: tfib failed, terminate
and interrupt passed, interrupt2 reached its 300-second inactivity window.
The exact-image kernel return-site mapping is retained separately; no unchanged
retry or sixth gate is admitted from the local lock repair.
The new binary has not yet requalified every previously completed gate.
See `ticket-ownership-acquire.md` and the source-locked
`bootstrap-tfib-observation.json` in its fixture Evidence directory.

The currently reused workspace subsequently built the diagnostic-only
`darwin-ffi-return-premise` overlay (not a replacement repair/release baseline).
Both bootstrap passes completed; complete compiled stress remains DENY,
3/4 accepted, zero timeout, 66.564 whole seconds. Neither ABSENT boundary
probe fired. A newly image/object-bound incident returns to BTQ remove L9,
generated thread line 11553; this does not discharge either the BTQ or earlier
FFI return obligation. No unchanged diagnostic retry is admitted. See
`ffi-return-premise-diagnostic.md`.

The native kernel return observation now has a separate FFI refinement view,
rather than being attributed to BTQ deletion. The composed caller/physical
frame/C-relock model exhausts 40 states with safety and weak-fair completion;
three incomplete-protocol controls yield counterexamples. Its actual queue/sync
reachability, C-local root mechanism and native invalid-value origin remain
explicitly unproved. The Evidence view keeps all three requirements open;
model PASS does not permit an unchanged stress retry. See
`ffi-select-relock-frame.md`.

Completion is grounded in repository source/patch identities and the retained
exact-source evidence of completed gates, not the existence of disposable
fixture directories. Cache pruning, `make clean`, a restart or an unavailable
historical executable cannot by themselves revoke completed work. A withdrawal
requires a demonstrated regression, invalid original evidence or an explicit
changed requirement; retain the reason and affected source identity. Missing
reproduction inputs require restoration/requalification, not a zero counter.

The earlier source successor `fdset-abort-owned-rollback` retained the SFUN
explicit-context and pipe-descriptor fixes. Model checks, source reapplication
and GNU GCC syntax checks were followed by a successful complete two-pass
bootstrap and 380/380 interpreted/PR validation on this 23-file successor.
See `fdset-frozen-source-qualification.md`. A separate 600-second build scope
was explicitly approved; the old ledger and failures remain unchanged.
These results requalify the existing 3/12 gates, not additional gates.

The active dynamic-profile candidate retains that exact 23-file SMP code and
adds only a Darwin/GNU dynamic-module modulo-scheduling override. Its scoped
QNT/source matrix is checked, complete two-pass bootstrap passed in 204.522
outer seconds, and interpreted/PR validation passed 380/380 in 57.074 outer
seconds. The earlier complete GSC attempt accepted 379/380 and remains DENY.
The subsequent original-loader, real-phase-observed run passed 380/380,
12/12 groups, zero timeouts: 510.373 native seconds, 587.987 outer seconds.
Each numerical-file phase retained its 90-second inactivity window; the
original generated C, loader and assertion exit protocol were preserved.
Checked ASCENT file coverage closes complete GSC and the six declared PR/GSC
fixtures, not stress, all possible PR failures or performance. Portable
receipt: `evidence/source-results/compiled-suite-coverage/receipt.json`.
The candidate is not adopted as a release optimization. See
`darwin-dynamic-modulo-candidate.md`.

The subsequent compiled stress failure remains open. The source-directed BTQ
operation model now checks insertion, rotation, successor transplant, deletion
fixup and two rounds of cleared-node reuse, with distinct/all-equal priorities:
6,356 distinct states, safety and weak-fair completion PASS; both omitted-write
controls fail as required. This is model-only progress, **not a sixth native
gate**. Physical GC copying/scan identity and native caller lock handoffs remain
uncomposed; see `btq-operational-model.md` and
`evidence/source-results/compiled-stress-failure/operations-model.json`.

The next source-operation component executes one arena's local cursor/FIFO
handoff, recursive copy and captured-frame private publication together:
1,029 distinct states, safety and weak-fair drain PASS, four omitted/reordered
operation controls rejected. Evidence-view regressions passed 18/18 without
skips. Msection/address generations, multiple allocating arenas, full raw
copying and the actual native scan origins remain open. No native gate closes
from this result; see `gc-chunk-cursor-operations.md`.

That component now includes one msection rollover, own-stack gap sharing and
two allocating roles' shared free-list request: 16,239 states, six mutation
controls, without a native gate increment. The separately locked
`darwin-allocator-acquire` successor changes only ALLOC post-ticket acquire for
Darwin/GNU. Its projected full `mem.c` object compiled, the post-wait `dmb ish`
was inspected, and four branch-scope controls passed in 19.405 child seconds.
At that object-only checkpoint it was not a linked runtime or bootstrap pass.
Its subsequent two-pass bootstrap passed, but compiled tfib failed with LO=11;
the separately bound native failure does not locate or explain that crash.
The old qualified runtime remains untouched; see `allocator-ticket-acquire.md`.

The earlier GNU queue-endpoint successor's four bootstrap phases ran twice;
`from-scratch` took 131.042 seconds and the full interpreted/PR inventory
passed 380/380 in 65.385 outer seconds. The original complete public latency
grid passed all 4,002 samples in 12.880 native execution seconds. These are
current-source requalification and scoped lifetime observations, not a fourth
completed gate. Full registry/fault/GC-FFI qualification remains open. See
`gc-queue-endpoint-source-successor.md`.

The earlier wake-budget source requalification had a completed two-pass bootstrap and a
complete interpreted run: 380/380 standard/PR files passed in a 71.610-second
whole run. Bootstrap execution took 135.935 seconds; its historical false-stale
verdict remains immutable and is bound by independent journal revalidation.
The official public VM-table diagnostic also passed at five VMs, two processors
per VM and twelve GC rounds per processor on the observed twelve-CPU host;
population and rounds are selected from capacity, not fixed CPU constants.
Executable compilation took 3.370 seconds and execution 0.517 seconds. This is
not the full lifetime/fault grid. Interpreted stress hit the original 300-second
gate; no complete stress pass or performance acceptance is claimed.

The earlier retained-producer readback returned stored PASS but
`identityStatus: STALE`, `runtimeAdmitted: false` and
`sourceRefinementAdmitted: false`. The three completed gates therefore need
current-source requalification before authorizing execution on the new patches.
This readback is not evidence of a runtime regression and does not change 3/12.
Model checks and source export/reapplication do not add a fourth completed gate.

| Gate | Cumulative completion | Latest successor qualification |
| --- | --- | --- |
| Complete bootstrap | Completed | PASS; all four phases twice on ticket-ownership successor |
| Complete GSI inventory | Completed | PASS; 380/380 on dynamic-profile successor |
| PR regressions GSI | Completed | PASS; complete interpreted inventory on dynamic-profile successor |
| Complete GSC inventory | Completed | PASS; 380/380, original loader and assertions |
| PR regressions GSC | Completed | PASS; checked actual coverage of six declared fixture hashes |
| Stress GSI | OPEN | OPEN |
| Stress GSC | OPEN | OPEN |
| Registry lifetime | OPEN | Prior public-table diagnostic only; full grid OPEN |
| Lifecycle faults | OPEN | OPEN |
| GC/FFI | OPEN | Prior multi-VM forced-GC diagnostic only; full chain OPEN |
| Gerbil correctness | OPEN | OPEN |
| Release performance | OPEN | OPEN |

Older checkpoints below retain their original counts as historical records;
this table governs current progress reporting. See
`current-smp-qualification-audit.md` for evidence and admission conditions.

Framework readback now separates recorded outcome, evidence hash binding and
output availability. Source/patch/log drift still rejects binding; removed
cache retains the recorded outcome but cannot authorize producer reuse. See
`evidence-cache-qualification-architecture.md` for the implemented contract
and remaining durable-native-archive/dependency obligations.

### Official Cleanup Resource Ownership Audit

The protocol now has a pinned source successor: public PSTATE reader draining,
an already-locked internal cleanup path, OS readiness ownership, guarded abort
dispatch and child P0 OS cleanup. Exactly three files changed from the parent;
all 22 selected files were mechanically reapplied/checked without a new retained
source tree. It remains uncompiled/unbootstrapped: **cumulative progress 3/12;
new source requalification pending**. See `public-cleanup-resource-ownership.md` for the
call-context table and exact source/patch identities.

The same public lifecycle audit found that global cleanup clears root P0 but
does not call child P0 OS cleanup before removing child VMs. VM-level I/O
cleanup is empty. A new source-bound model characterizes the omitted resource
release and rejects an unconditional-close repair proposal when an owner has
already cleaned its P0. A readiness-owned, reader-drained protocol passes
safety and weak-fair progress at 28 distinct states; framework execution took
18.149 seconds with host-auto concurrency and unchanged check caps. This is
a model checkpoint preceding the source successor, not a native gate. See
`public-cleanup-resource-ownership.md` for source facts, missing requirements
and the required non-private-interface path.

### Source-Directed Population Publication Repair

Growth and unchanged-count publication bypassed the registry reader grace
period used for shrink. The bounded QNT reproduces both access-order gaps;
the positive safety and weak-fair progress checks exhaust 90 distinct states
in a 14.059-second framework run. The source successor guards every changed
multi-VM population commit and avoids the unchanged shared write, preserving
the single-VM path. Its 22-file overlay was exported and reapplied in the same
thin workspace. Portable evidence is registered; no native or performance
gate is closed. See `vm-registry-population-publication.md`.

### Source-Directed Public Resize Boundary Repair

The foreign-origin scanner accepted a negative starting processor index;
the public resize entry had no lower-bound rejection. Two source-directed
counterexamples and positive safety/progress checks passed through the shared
framework in 13.453 seconds. Only the entry's nonpositive-input guard was added
to the reused current workspace; a pinned 22-file overlay was exported/reapplied.
Portable model evidence is registered in the existing Datalog pipeline. The
official-public-FFI regression is prepared but unexecuted, and no native gate,
bootstrap permission or budget is transferred. See `foreign-origin-resize-domain.md`.

### Current Producer Readback Is Stale

Post-pruning framework readback of the retained bootstrap returned stored PASS
but current STALE, with no runtime/source-refinement admission. The retained
runtime alone does not satisfy all predecessor-tree and current-input checks.
The earlier 3/12 is historical coverage, not current producer permission.
Ten research fixtures also use an owned-cleanup symbol outside the pinned
official public interface. See `current-smp-qualification-audit.md` for the
actual command, interface inventory, original budget and full remaining gates.
No failed suite or bootstrap was replayed and no source copy was recreated.

### Public VM Cleanup Source Correction, Not Acceptance

The source audit found that public void `___cleanup_vmstate` silently returned
when foreign admission was busy, unlike the legacy global cleanup endpoint.
The public-cleanup source successor changes only that rejection branch to the
existing fatal-error policy, preserving the signature and normal path. The
existing framework exported and reapplied its 22-file pinned overlay to verify
every byte. Old sources/receipts are unchanged; no new model-only campaign or
native launch was performed. See `foreign-origin-public-cleanup-contract.md`.
Full sealed review remains DENY and the original source-stage budget remains
charged; the successor is unqualified. **Historical coverage is 3/12; current
producer admission is stale.**

### Mainline Owned-TLS And Retirement Composition

Source inspection and the new owner-retirement QNT compose TLS capture before
lease publication with callback GC roots, collective retirement, thread exit,
join and retained storage on join failure. Two injected negative controls and
two safety/weak-fair completion checks passed through the existing framework in
15.323 seconds, with host-auto concurrency and unchanged 15-second check caps.
The positive inventory is exhausted at 41 distinct states. Portable evidence is
registered in the existing protocol bundle pipeline; full ASCENT graph execution
has not been rerun. No Python/History or C implementation changed. See
`foreign-origin-owner-retirement.md` for exact owner, VM-lifetime and FFI limits.
This conditional model evidence does not close a native gate: **3/12 remains**.

### Actual Checked Seed Transfer, Full Bootstrap Still Blocked

The fixed provider-027 snapshot passed its nine dual API/ABI DAG checks with
no skips in 2.842 seconds. It was paired with its own Python binding in engine
`7b25b83f48216fff065a1839c2186671fd77daf66002757eb7fca3f29ad1ba27`.
This does not qualify the concurrently changing live Library or complete graph.

The six-step checked-seed bootstrap campaign actually executed: source PASS,
seed transfer PASS, review TIMEOUT, bootstrap/arity BLOCKED, verdict TIMEOUT.
Whole execution was 43.87196195899742 seconds under its 226-second cap,
DENY, with parent reaped and process group quiescent. It reused 2,243 files
through copy-on-write, zero byte copies and zero hardlinks; the old parent
remains DENY and the output is still only a seed. No complete producer export
or native qualification follows. See
`evidence/research/vm-registry-reader-lease/checked-seed-bootstrap-consumption.json`
for exact receipt bindings and all original failure expenditure.

The source-stage cumulative charge is now 417.0321317510097 of the original
600 seconds, leaving 182.9678682489903. The currently declared 226-second
recipe must not be launched again. A discovered framework gap means the
different-recipe consumer is not automatically in the original linear prior
chain; manual accounting is not sufficient for concurrent or restart-safe
admission. `checkpoint_budget_ledger.qnt` and its declared recipe are prepared,
not verified: they specify short atomic reservations, failure settlement,
quiescence-bound recovery, and omission/duplicate/release-first controls.
Durable registry and journal integration remain OPEN before another launch.

The handoff model's fixed-027 retry also remained DENY, 32.47392295800091
seconds, with all QNT checks passing but terminal native evaluation timing
out under the unchanged 10-second cap. Its two attempts cumulatively spent
65.93645237499731 of their separate 300-second model scope. The framework
owner is investigating the actual native loader path, not changing budgets.
**Retained acceptance remains 3/12; all nine full gates remain OPEN.**

### Integrated Execution Blocker, Not Additional Acceptance

The retained accepted producer is still **3/12**, with all nine open gates
listed below. The checked-seed capability, allowlist entry, shared ancestry
validator and duplicate-build guard are now integrated. Focused transport and
recipe and declaration-preservation regressions passed 95/95. The prepared six-step bootstrap campaign
retains both failed attempts and their 373.1601697920123-second expenditure;
its 226-second cap is below the original remaining 226.8398302079877 seconds.
It does not replay source configuration, the seed or the 32 preceding model
steps, and does not admit an expired continuation.

The new handoff QNT positive invariant, two negative controls and six
trajectories passed under the fixed old model framework, but its final native
ASCENT evaluation timed out: whole campaign DENY, 33.463 seconds. No full
model or runtime gate is counted from those local passes. Current Python
requires the new evidence-plan API; the matching fixed provider is not yet
available. Full bootstrap is therefore prepared but unexecuted. Do not mix
new Python with old native API, alter immutable seals, replay this unchanged
failure or widen its budget. `recipe-continuation-contract.md` records the
exact next integrated execution and evidence boundaries.

### Source-Directed Cleanup Ownership Successor

The integrated source audit corrected a single-VM global-cleanup admission
reacquisition that skipped storage destruction, and rejected the prepared
legacy-cleanup fixture's impossible normal-return assumption. The old fixture
and all actual failures remain retained. A frame-only official-FFI successor
is prepared but unexecuted; it does not qualify the separate cleanup contract.
The combined endpoint/ownership QNT model, two faulty-policy controls and five
trajectories passed in 42.793 seconds, CURRENT. GNU GCC setup/c_intf/mem objects
and a supplemental single-VM branch object passed in 63.824 seconds whole,
CURRENT. See `foreign-origin-lifecycle-ownership.md` for source and receipt
hashes, exact boundaries and outstanding real execution. No acceptance gate
is transferred from the retained producer: **3/12 remains unchanged**.

### Integrated Foreign-Origin Candidate, Review Blocked

The retained accepted vector-arity producer remains **3/12**, not full SMP
green. The new foreign-origin candidate is a different locked producer;
object compilation and a C seed do not transfer those three gates to it.
Its setup/header causal bindings now match the new source lock, with the
historical failures and their baseline identities unchanged. A binding
regression checks both candidate bytes and every declared review reference.

The first sealed attempt stopped at review, before bootstrap, after
156.5627377500059 seconds including outer execution. The formal corrected
retry has a 443-second whole cap, so the combined expenditure is at most
599.5627377500059 seconds, below the original 600-second budget. This is
revalidation, not qualified prefix reuse: the framework has no admitted
prefix-continuation capability. No seed is exported as a completed runtime.
That retry ended DENY after 216.5974320420064 seconds of outer execution:
configuration and seed passed, but the original 15-second review step timed
out in native ASCENT loading, with no log output. Its 10-second final rule
evaluation also timed out. Bootstrap did not execute; all processes were
reaped and quiescent. The combined expenditure is 373.1601697920123 seconds,
leaving 226.8398302079877 seconds; no further fresh prefix replay is authorized
by this checkpoint. The accounting regression includes both failed attempts
and does not count its own PASS as runtime admission. See
`recipe-continuation-contract.md` for the still-open checked-prefix interface.

The next actual acceptance path is full two-pass bootstrap, the official
foreign-frame roundtrip, and the unchanged complete native inventories.
There is no private cleanup invocation or loader interposition fixture.

Nine retained-producer gates remain OPEN: complete GSC, PR/GSC, stress/GSI,
stress/GSC, registry lifetime, lifecycle faults, GC/FFI, Gerbil correctness,
and release performance. Model and object passes do not close these gates.

### Root Cohort And Resize Transcript Closure

The current vector-arity producer passed the composed QNT, actual ASCENT
event review and unchanged moving-root/resize-GC controls in 74.703/300 seconds
whole, PASS/CURRENT. Native execution was 0.689 and 0.549 seconds under the
unchanged 30-second caps, on eleven host-derived processors. See
`host-managed-gc-topology-contract.md` for hashes, retained initial DENY and
strict transport controls. No bootstrap was repeated and no fixture assertion
was removed. This closes two scoped controls, not full GC/FFI or lifecycle
fault qualification; current acceptance remains 3/12 with nine open gates.

### Current Scope-Preserving Native Coverage

The vector-arity producer now has a dedicated full-scope PR/GSI campaign
PASS/CURRENT: 380/380 files, including all seven declared PR regressions and
the unchanged GC diagnostic, 66.339/300 seconds whole. The independently
threaded VM fixture also passed on this exact producer in 42.812 seconds whole
and 1.072 seconds native, with host-derived two five-processor cohorts.
Both reuse the completed bootstrap; neither repeats it. See
`vector-arity-current-native-coverage.md` for exact receipt bindings and limits.

Acceptance is **3/12**: bootstrap, complete GSI and declared PR/GSI coverage.
Nine gates remain open: complete GSC, PR/GSC, stress/GSI, stress/GSC, registry
lifetime, lifecycle faults, GC/FFI, Gerbil correctness and release performance.
The historical checkpoints below retain their original counts and boundaries;
they are not the current ledger. No full runtime or source refinement is admitted.

### Vector Arity Successor Checkpoint

The current vector-increment arity successor has a fresh full two-pass
bootstrap plus corrected atomic interpreted regression PASS in 404.745/600
seconds. Its complete unchanged 379-file interpreted inventory subsequently
passed 379/379 in 83.548/300 seconds and reads CURRENT. The same completed
producer was reused; the consumer transfer reports 2243 copy-on-write files,
zero ordinary byte copies and no hardlinks. See
`vector-increment-arity-parity.md` and `artifact-storage-reuse.md`.

Current acceptance is **2/12**. Ten gates remain open: complete gsc, dedicated
PR gsi/gsc, stress gsi/gsc, registry lifetime, lifecycle faults, GC/FFI, Gerbil
correctness and release performance. Older topology or native passes are not
silently transferred to this new source identity.

The original single-file `018-gc-table-iteration` interpreted counterexample
now has CURRENT/PASS QNT positive and two negative controls, ASCENT review and
unchanged native assertions on this exact producer, 48.252 seconds whole and
0.055908 native under its original 20-second native cap. This closes a specific
GC diagnostic binding gap, not full GC/FFI or the PR gate. The old failure is
retained; see `table-iteration-current-producer.md`.

The unchanged four-file interpreted stress campaign remains DENY at its
original 300-second whole budget (300.297 seconds including teardown). One
file, `thread_interrupt_stress.scm`, passed in 51.214 seconds; the other three
have no completed acceptance result. The parent was reaped and its process
group was quiescent. No timeout was widened and no incomplete file is counted
as passed. Do not repeat this identical campaign without a causal change.

### BTQ Retry Candidate Checkpoint

The BTQ retry successor has its own fresh full two-pass bootstrap PASS
(301.573 seconds) and complete gsi 379/379 PASS (78.098 seconds whole, sealed
CURRENT). Its unchanged long native topology also completed every CPU-derived
2-5 VM population, 4002 samples total, in 12.980 seconds native / 40.596 whole.
The previously sampled mutex/condition-variable retry now checks pending sync
after releasing its thread lock. Exact evidence, retained pre-execution
rejections and complete P55/P99 observations are in
`btq-retry-sync-participation.md`. The older baseline below remains retained.

Current successor acceptance remains **2/12**, not full SMP green. The ten open
gates are complete gsc, PR gsi/gsc, stress gsi/gsc, registry lifetime, lifecycle
faults, GC/FFI, current Gerbil and release performance. A single complete
topology does not discharge full lifetime or stability requirements. No result
from a different producer is inherited, and no budget was widened.

### Open-Gate Progress Ledger

Every update must name the remaining gates and separate diagnosis from
acceptance. The current count is 2/12 closed (16.7% of gates, not engineering
effort); the ten open gates listed above remain open.

The explicitly selected four-file interpreted stress campaign is DENY at its
original 300-second whole-run limit. `thread_interrupt2_stress.scm` failed;
the other three files have no completed acceptance result. Do not rerun the
unchanged campaign or count incomplete files as passes.

The subsequent `smp-vector-increment-arity-diagnostic` recipe is DENY without
timeout. QNT parsing, type checking, positive specification, old-contract
counterexample and trajectories passed, but the actual interpreter rejected
`(##vector-inc! value 0)` with a wrong-number-of-arguments error. The current
compiler inventory accepts two or three arguments while the runtime primitive
declares three. This is a confirmed contract discrepancy, not yet proof that
it uniquely explains the nested stress exception.

The diagnostic fixture also incorrectly expected the incremented return value:
the actual primitive returns the old value (0 then 1). Preserve that failed
receipt and correct the successor fixture's contract before qualification.
Neither the model result nor this diagnosis closes a native stress gate.
The next causal step is to audit primitive generation and align interpreted
and compiled arity without weakening atomicity, assertions or budgets.

### Selected Producer And Open Acceptance Gates

The current reporter-preservation candidate has a 21-file immutable source
lock. Its fresh default Bazel-profile two-pass bootstrap passed in 298.077
seconds; its complete interpreted inventory passed 379/379 files in 58.832
seconds for the containing recipe. See `reporter-preservation-source.md` for
exact receipts. Neither result admits release performance or full SMP.

Acceptance is **2/12 gates (16.7%)**, not an estimate of engineering effort.
Every progress report must retain the following open-gate inventory. Results
from other producers cannot silently discharge a current-producer gate.

| Gate | Current status | Remaining condition |
| --- | --- | --- |
| Complete bootstrap | PASS | Both full passes, current producer bound |
| Complete gsi inventory | PASS | 379/379, zero failed files |
| Complete gsc inventory | OPEN | Full current-producer inventory within original budgets |
| PR regressions gsi | OPEN | Dedicated declared campaign and bound receipt |
| PR regressions gsc | OPEN | Dedicated declared campaign and bound receipt |
| Stress gsi | OPEN | Sustained complete declared campaign |
| Stress gsc | OPEN | Sustained complete declared campaign |
| Registry lifetime | OPEN | Repeated concurrent resize/reuse, ownership and progress |
| Lifecycle faults | OPEN | Complete fault campaign, including sticky root failures |
| GC/FFI | OPEN | Full root/transfer/publication/foreign interaction coverage |
| Gerbil correctness | OPEN | Current staging bootstrap and complete real package tests |
| Release performance | OPEN | Current-producer cold build/test and complete P55/P99 populations |

The nine named additional obligations come from
`evidence/research/smp-threaded-vm-native-grid/milestone-rules.ss`. Interpreted
inventory inclusion does not replace their separately declared campaigns.

### Bound Stack Observation: Failure Retained

The optional Darwin sampling-tool transport is now covered by focused framework
tests. Engine `1527596bc9dea1a70cef9461de0b0cbe3c5aa7e88640cac97e0e5a48b8866a73`
obtained an actual owned-child sample on the resize-grace baseline. The run at
`.data/fixtures/vm-registry-reader-lease/tool-bound-stack-observation-run`
remains DENY: native execution timed out after 117.551 seconds within its
original step budget; the child was reaped and the process group was quiescent.

The one-second sample exited zero without timeout. Report SHA-256 is
`0852be8b89dc6f40d9f606295de0c6a5f2a5bb2d2b8e672feca5244e2715b1ed`.
At that sampling instant, the host main thread waited in `pthread_join`, four
processor threads waited in `barrier_sync_op`, and another thread executed
`___H___thread`. This is a captured wait-state combination, not proof of a
specific deadlock or unique cause. The next source/model audit must connect
those paths, barrier cohort ownership and retirement ordering before a repair.
This diagnostic uses a different producer from the selected candidate above;
it closes neither current correctness nor performance gates.

### Tail-Latency Monitoring And Retained Failures

The existing native framework now validates raw per-population trajectories and
can report P55/P99 only with complete planned coverage. The 12-CPU monitor plans
at least 1,000 samples for each CPU-derived 2-5 VM population. Its current
successor run timed out with 624/1,000 samples in the first population; no full
P55/P99 is admitted. The timing-admission QNT controls passed CURRENT/PASS.
The instrumented short topology passed without a source change, which does not
resolve the earlier timeout. Complete interpreted regression on this successor
also failed: 378/379 files passed, `prim_port.scm` did not. Same-input qualified
baseline timing control and exact boundaries are tracked in
`vm-topology-latency-monitor.md`. No performance limits were widened, and the
qualified baseline remains separate from this unadmitted successor.

### Global Cleanup And Native Join Recovery

The explicitly selected global-cleanup-preflight successor completed its default
Bazel-profile two-pass bootstrap in 311.672 seconds. It now has a CURRENT/PASS
QNT/ASCENT/native fault campaign: five CPU-derived concurrent two-processor VMs
on the observed 12-CPU host, exact injected errno, resource retention, global
precommit rejection, failed owner join and successful retry. Whole time was
85.916 seconds; native compilation/execution were 2.302/0.507 seconds. Original
budgets are unchanged. Fixture failures and compiler rejection are retained.

The unchanged repeated host-topology campaign on this successor timed out and
is DENY. No unchanged retry or candidate admission is justified. Root sticky
failure, full lifecycle/GC/FFI, compiled inventory and Gerbil/performance remain
open; acceptance stays 2/12. Exact producer binding and limits are in
`vm-global-cleanup-native-checkpoint.md`. This successor does not replace the
qualified resize-grace baseline below.

### Failed Join Ownership Obligation

Current-source audit distinguishes reduced active processor count from ownership
of departed OS threads whose join failed. A source-bound model now preserves the
count-only cleanup counterexample and a proposed reject/retain/retry protocol:
9 safe states, four trajectories, CURRENT/PASS in 31.588 seconds through the
existing QNT/ASCENT framework. See `vm-failed-join-retention.md` for exact source,
caller-precondition and non-native boundaries. The successor above implements
pending ownership and bounded native recovery; slot reuse after a retained
failure and complete fault/lifecycle qualification remain open. No final
acceptance gate is discharged by the model alone.

### Default Bazel Build Profile

The current default-profile producer now also passed the complete PR-inclusive
interpreted inventory: 379/379 files, nine groups, all exits zero without timeout.
The containing QNT/ASCENT/native recipe took 61.458 seconds under the unchanged
300-second cap, with CURRENT/PASS readback. Historical source-binding and
missing-PR-review denials are retained. See
`bazel-profile-grid-review-checkpoint.md`. Complete compiled, stress, lifecycle,
GC/FFI, Gerbil and performance gates remain open; runtime admission is false.

Default qualification now uses the versioned, byte-bound Bazel Darwin build
profile data, not the simplified optimization experiments. The exact source
passed full two-pass bootstrap in 408.068 seconds under the original 600-second
cap, with CURRENT/PASS readback and all three concurrency switches. The profile
resolves to C O1 and RTS O3 on GNU GCC and retains the additional Bazel flags.
See `bazel-build-profile-checkpoint.md` for source provenance, actual commands,
retained framework failures and the non-admission boundary. Full Grid and
performance acceptance remain open; O0 retry reviews are not inherited.

### Optimized Configuration Qualification

The same source passed a fresh O1 C/RTS two-pass bootstrap in 227.385 seconds
under the original 600-second cap, and the unchanged CPU-derived topology
fixture passed in 1.372 seconds (59.339 seconds whole recipe). Both sealed
readbacks are CURRENT/PASS. This is configuration qualification, not complete
SMP green or proven acceleration: the earlier O0 topology observation was
0.823 seconds. The optimized producer is separately bound and does not replace
the O0 full Grid or inherit its compiler-cost causal review. Exact boundaries
and the remaining retry gate are in
`optimized-runtime-qualification-checkpoint.md`.

### Host-Derived VM Topology Successor

The same resize-grace producer now passed all feasible two-to-five-VM
topologies on the observed twelve-CPU host, not only two large VMs. Processor
allocations were 5+5, 4+3+3, 3+3+2+2 and 2+2+2+2+2, with two reserved execution
positions. Every topology retained at least sixteen grow/GC/join/shrink cycles.
Whole recipe: 56.038 seconds; native execution: 0.823 seconds; sealed CURRENT.
See `registry-host-topology-grid.md` for exact bindings, reproduction, retained
framework failures and the explicit non-admission boundary. This does not close
the complete inventories, faults, GC/FFI or source-refinement requirements below.

The exact 379-file compiled preflight now has twelve eligible routes and no
missing causal premises. Actual native execution then hit the original
300-second whole cap (300.297 seconds, DENY). Eight of eleven process records
have observed completed zero exits; three have no observed result. This is not
complete file acceptance or full SMP green. The typed interrupted observation
is retained in the semantic evidence tree; see `smp-grid-causal-checkpoint.md`.
Earlier whole compiled timeouts ended in numeric-file compilation;
they did not reach `thread_start`, so its fixture repair is not asserted as their
cause. The original parallel observation now has a verified semantic archive at
`evidence/source-results/fixtures/thread-completion-contract/parallel-compiled-suite-history`.
The exact environment, resource-plan and compiler-options model/native-policy checks and remaining
route boundaries are recorded in `smp-grid-causal-checkpoint.md`.

### Resize Grace Successor

The resize-grace successor closes a separate processor-retirement obligation:
drain old-count global readers after collective barrier arrival, before lowering
the processor count and releasing workers. Its source-derived counterexamples,
assumptions and exact publication point are described in
`vm-registry-resize-grace.md`. The count-only and early-close orders remain
negative controls, not native crash claims.

| Bound Stage | Successor Result | Acceptance Boundary |
| --- | --- | --- |
| QNT safety and progress | 48 distinct / 73 generated states; empty queue; two retained negative controls and four trajectories | Finite protocol, not C memory-model refinement |
| Native Scheme causal review and full bootstrap | PASS, 263.366 seconds under original 600-second cap; both complete passes | GNU GCC, all three switches; no release claim |
| Exact completed producer | Exported `resize-grace-completed-producer.json`; source lock SHA-256 `50fb5e388b87806aa733ee3f1e16609880a74f41fabda2c0bab791ad1c3bb2e6` | Not an interchangeable historical binary |
| Concurrent resize / GC / interrupt campaign | PASS, 54.169 seconds whole under original 300-second cap; compilation 2.223 seconds, execution 0.658 seconds | Two adaptive five-processor cohorts, 16 grow/GC/shrink cycles per VM, concurrent global heartbeat reader; bounded campaign only |
| Sealed native readback | CURRENT, PASS; child exit zero, no timeout, reaped and group quiescent | `runtimeAdmitted=false`, `sourceRefinementAdmitted=false`, `nativeGcPassed=false` |

The new native fixture derives capacity from the framework's observed available
CPUs and reserves capacity for the root and interrupt driver. It checks pinned
worker execution, owner-tagged GC roots, joins and P0 shrink on each cycle, and
uses the combined owned cleanup helper before freeing each VM. The receipt is
not a complete GC/FFI or fault-injection result.

The successor recipe, model, fixture and cumulative patch are versioned semantic
inputs. Original owned-retirement locks and receipts below are retained. The
full gsi/gsc inventories, PR regressions, upstream stress, lifecycle faults,
GC/FFI, current Gerbil and release-performance obligations remain open; none is
discharged by this passing campaign. The compiler-probe policy checkpoint is
recorded in `native-compiler-probe-correspondence.md`: 85/85 review tests passed
in 50.098 seconds, without authorizing missing full-Grid causal claims.

The next full-Grid policy checkpoint is documented in
`native-whole-budget-dominance.md`. Its 75-test sealed native review domain
passed with zero skips in 45.655 seconds under the original 60-second cap.
It transports complete file memberships to Scheme DSL and permits a stronger
containing deadline only with nonempty original coverage and unchanged caps.
The 379-file PR-inclusive inventory and complete route review still have to be
bound before either complete native mode executes. No native suite was rerun
merely to rediscover those missing reviews.

### Retained Owned-Retirement Checkpoint

Source and linked outputs in this earlier checkpoint are unchanged. A historical input archive now
binds the completed bootstrap's original policy bytes, so the new engine can
verify and consume that exact producer without another bootstrap. This does not
silently turn the old policy review into current policy admission.

The retained owned-retirement candidate is the pinned submodule plus
`evidence/fixtures/vm-registry-reader-lease/owned-retirement-source.lock.json`
(`1abb090493f418ab4c5456a1c527e75472505f4632f3eb98354d624d3fa91f64`).
Sections below are retained historical checkpoints, not interchangeable runtime
qualification. Successor stages must consume the resize-grace completed producer
above; this earlier producer must not be substituted for it.

| Stage | Current Candidate Result | Remaining Requirement |
| --- | --- | --- |
| Registry protocol | Repeated retirement, terminal seal, capacity/replay and composed processor retirement bounded controls passed | Physical ordering, arbitrary signal progress and source refinement |
| Native GNU objects | PASS, 82.121 seconds, stable source inputs | Not linked runtime acceptance |
| Complete bootstrap | PASS, 246.472 seconds; sealed read CURRENT | O0 correctness investigation, not release performance |
| Completed producer handoff | Exported typed, hashed reference under `evidence/research/vm-registry-reader-lease/owned-retirement-completed-producer.json` | Grid consumer must verify the exact reference, flags and source closure |
| Native Grid | Not yet qualified for this producer | Both complete inventories, PR regressions, stress, registry lifetime, fault handling and GC/FFI |
| Independent threaded VMs | Current same-producer fixture PASS, 40.321 seconds whole / 0.483 seconds execution | Fault injection, repeated retirement, direct user admission and full GC/FFI/stress coverage |
| Gerbil and performance | Not yet qualified for this producer | Current staging, complete correctness, existing cold build/test gates and sustained stress |

The reviewed bootstrap preserved all three concurrency switches and the original
600-second containing deadline. The containing and child receipts report PASS
and unchanged inputs. Bootstrap remains `runtimeAdmitted=false` and
`sourceRefinementAdmitted=false`; its producer reference enables downstream
verification, not a shortcut around it. The earlier stale-source causal review
DENY in 55.662 seconds remains separate and unchanged.

### Resource Lifetime Requirement

The earlier `independent_threaded_vms.scm` calls `___cleanup_pstate` before
`___cleanup_vmstate`. Registry admission closes only in the latter. The earlier
operation frees processor OS/memory resources, whereas a registry interrupt can
still reach `___raise_interrupt_pstate` and `___device_select_abort`. This is an
unclosed resource-lifetime obligation, not a reproduced native crash. A passing
bootstrap or smoke cannot discharge it.

`vm_registry_processor_retirement.qnt` composes VM membership, reader leases,
processor-resource lifetime and cohort completion. It distinguishes closing and
draining admission before resource release from freeing resources first. The
proposed order joins direct VM users/cohorts before closing admission; it does
not hold the registry gate closed while waiting for workers that need interrupts.
The new candidate implements `___cleanup_owned_vmstate` without changing the old
embedding cleanup entry points. The fixture consumes this combined helper. See
`vm-owned-retirement-contract.md` for its ownership assumptions, rejection and
failure-retention contract. Its source-bound objects and complete bootstrap have
passed; native execution, fault injection and general embedding qualification
remain separate requirements. VM execution and parallel GC remain concurrent.

The previous release/replay-only candidate completed bootstrap in 244.866
seconds and GNU objects in 72.938 seconds. Those receipts and source lock are
retained as earlier checkpoints, not attributed to the new cleanup helper.
Thirty-one focused framework tests passed in 12.265 seconds with no skips.
Compiled ASCENT admits the new finite model evidence while keeping source,
native GC/lifecycle and Gerbil qualification open.

### Current Native Entry Receipt

`smp-owned-retirement-threaded-vm-entry` passed under its original 300-second
whole / 120-second executable budget. Its typed completed-producer consumer,
entry protocol controls, new resource-retirement positive/negative controls,
real GNU executable compilation and execution all passed with stable inputs.
Sealed readback reports CURRENT. The executable printed exactly
`INDEPENDENT-THREADED-VMS:PASS` and exited zero without a timeout.

Observed host capacity was 12, supplied by the framework rather than a recipe
constant. The fixture computed two five-processor cohorts from that capacity;
the root retains its own processor. Every pinned Scheme worker verifies its
actual processor, retains owner-tagged roots across forced GC, joins, then
shrinks its VM to P0 before combined cleanup. Executable compilation took
2.257 seconds and execution 0.483 seconds. This is simultaneous independent-VM
entry and bounded GC-root smoke, not a complete parallel-GC/FFI/fault campaign.
The adapter correctly retains `nativeGcPassed=false`, `runtimeAdmitted=false`
and claim `same-producer-standalone-fixture-only`.

Reproduce through the existing framework, in order:

```sh
gambit-smp research --run vm-registry-owned-retirement-objects --engine ENGINE --out OBJECT_RUN
gambit-smp research --run vm-registry-owned-retirement-bootstrap --engine ENGINE --out BOOTSTRAP_RUN
gambit-smp research --export-producer BOOTSTRAP_RUN --step bootstrap --out PRODUCER_REFERENCE
gambit-smp research --run smp-owned-retirement-threaded-vm-entry --engine ENGINE --out NATIVE_RUN
gambit-smp research --read NATIVE_RUN
```

Seal ENGINE with explicit GNU GCC, Quint, Node and the existing compiled ASCENT
API. Runs and producer exports are fresh immutable outputs; an existing export
must not be overwritten. Before the native run, bind its recipe's declared
producer input and `gambit.completed-runtime` argument to PRODUCER_REFERENCE,
a fresh JSON path under `evidence/research`. This is data configuration through
the existing consumer contract, not permission to reuse an old binary. The
checked-in producer reference verifies this exact
local completed run and fails closed if it is absent, stale or altered. It is
not a substitute for reproducing bootstrap in a clean checkout. Source authority
remains the pinned submodule and source lock, not the local artifact directory.

## Single Acceptance Chain

The milestone is one source-bound chain, not the sum of unrelated model or
fixture passes. Its candidate is the pinned Gambit submodule plus the cumulative
`evidence/fixtures/thread-completion-contract/source.lock.json` overlay. Every
runtime and downstream result must bind the exact current producer. GNU GCC,
SMP, multiple VMs and multiple threaded VMs remain enabled. Available host CPU
capacity determines build and test topology; neither serial execution nor a
fixed processor count can substitute for the required concurrency.

| Gate | Required Evidence | Current Boundary |
| --- | --- | --- |
| Composed protocols | Bound QNT safety, negative controls, explicit progress assumptions and source correspondence across lifecycle, synchronization, roots and copying GC | Local models exist; complete source refinement and cross-protocol discharge remain open |
| Current source producer | Fresh GNU configuration, all three flags, regenerated Scheme/C, linked artifact hashes, actual exit and teardown | Source producer and native entry passed in the run below |
| Complete bootstrap | Both complete phase1-4 passes, regenerated sources, immutable source closure, no hidden recursive failure and linked identities | Fresh O0 GNU bootstrap passed: both complete passes, exit zero, no timeout; release-configuration qualification remains open |
| Complete native correctness | Exact complete gsi and gsc inventories, real multiprocessing and multi-VM coverage, GC/FFI/lifecycle tests and stress, zero failed or skipped requirements | Same-bootstrap default plus Darwin regression: gsi 375/375 passed; compiled inventory, four additional PR regressions, stress and independent threaded VMs remain open |
| Gerbil correctness | Current staging built using that accepted runtime; complete standard-library and representative package build/test | Pending; historical package results are not current SMP qualification |
| Performance and stability | Matching release configuration, retained failures, repeated cold build/test and sustained threaded/GC stress under existing gates | Pending; source-bootstrap seconds are not package build/test timings |

## Actual Current Producer Entry

The first journal-bound run retained DENY in 169.527 seconds under the original
420-second whole budget. Source, protocol, configuration, seed, source core and
causal review passed. Source regeneration took 90.459 seconds. The native child
exited successfully, but transport copied only the unit-test directory and
runner while its final integrity check covered all upstream test resources.
The missing `tests/test4.ok` therefore blocked acceptance.

The framework now copies the complete upstream test resource tree into each
isolated shard. Full fixture hashing, original budgets, SMP flags and adaptive
CPU topology remain unchanged. Regression also verifies independent golden
transcripts and input resources in every shard.

The new engine
`eabe9f40a2081212da05970b7b31eb3b1afcd443fe86c50d7962ea2fc6605408`
completed the exact source-producer entry in 175.282 seconds under 420 seconds:
outer and child PASS, exit zero, no timeout, parent reaped and group quiescent.
Source regeneration took 90.443 seconds. The selected file was exactly
`01-fixnum/fxadd.scm`, with one worker and eleven processors derived from the
available host capacity, not hard-coded. A subsequent sealed read reported
CURRENT. The run is retained in
`.data/fixtures/current-producer-native-chain/full-fixture-run`; the prior DENY
is retained separately. This proves the first real source-to-native interface,
not complete SMP, multiple threaded VM or Gerbil acceptance.

## Remaining Whole-Chain Work

`gambit.review` now supports a matching same-producer downstream bootstrap as
well as a suite. Bootstrap phase checks require exactly two occurrences of each
upstream phase marker; one pass, missing phases or duplicate passes fail closed.
Bootstrap also uses the same host-derived shared CPU plan as source core:
recursive make remains parallel, and each compiler invocation receives its
share rather than independently claiming the host. All three runtime switches
remain enabled; native SMP/multi-VM tests are not reduced to that compiler
population. CPU capacity drift after review is rejected. This removes an
interface inconsistency, not a proven explanation of the old bootstrap timeouts.
The 85 focused regressions passed in 1.008 seconds. These are framework checks,
not an actual two-pass bootstrap result. Existing bootstrap failures retain
their original 600-second cap and require complete typed causal review before
another native attempt. Their raw logs were located; missing metadata must be
bound to those original observations, never replaced with a later success.

Recovery/clock modelling remains supporting work, not the current milestone's
critical path. Its new clock-composition parse failure is retained in
`.data/fixtures/checkpoint-clock-recovery/composed-controls`. It does not change
the runtime source candidate or grant execution. Do not spend another iteration
extending that side path while bootstrap/full native/Gerbil gates remain open.

## Bootstrap Failure Provenance

Three original failed runs and their exact seed identities were recovered using
the existing archive framework. Portable data-only archives are retained under
`thread-completion-contract/bootstrap-second-core-history`,
`bootstrap-gc-iteration-history` and `bootstrap-serialization-history`.
Each has the complete original receipt, exact seed identity, display-redacted
log and original/archive hashes. Parent exit remains unknown; none of the old
receipts originally recorded a raw-log digest, and this absence is explicit.
No source bytes, old receipt hashes or original 600-second limits were changed.
The 95 archive/framework regressions passed in 1.097 seconds.

The latter two original receipts exactly match their canonical failure receipts.
The first canonical receipt is a denial summary, not the recovered full receipt:
its original hash remains unchanged, and it lacks the seed identity and step
inventory required by typed native review. A general version-bound historical
observation bridge is therefore required before complete bootstrap/full suites;
replacing that summary hash or omitting the failed route is not acceptable.
The current candidate has respectively 13, 13 and 11 runtime source changes
relative to the original seeds. These are actual byte differences, not a proof
that the prior timeouts were caused by or resolved by any particular change.

## Complete Bootstrap Gate Closed

The source-bound recipe
`evidence/research/smp-threaded-vm-bootstrap/bootstrap.recipe.json` completed
on engine `1a36e0a25873fa95098aae8c1e0f8840c78194f9512f36c149d13265feedff89`:

| Measurement | Actual Observation |
| --- | --- |
| Whole sealed child invocation | 276.621 seconds, under the original 600-second cap |
| Whole caller including preparation | 278.031 seconds |
| Actual `make from-scratch` command | 186.376 seconds, exit 0, no timeout |
| Phase inventory | phase1, phase2, phase3, phase4: exactly two occurrences each |
| Parent and process group | Parent reaped, process group quiescent |
| Subsequent sealed read | PASS / CURRENT; no runtime or source-refinement admission |

GNU GCC and all three concurrency switches were verified in configuration.
The host supplied twelve available processors for this run. Make used twelve
jobs and each concurrently launched compiler received its one-processor share;
these values were derived from capacity, not recipe constants. Native SMP and
independent multi-VM concurrency are separate required gates, not established
by this compiler resource plan. C and RTS optimization were zero: this closes
the correctness-bootstrap prerequisite, not release performance.

The canonical three bootstrap denials remain unchanged. Native ASCENT admitted
only conditional investigation of the changed candidate, with three original
and requested budgets equal to 600,000 milliseconds. The recovered summary's
status, exit, timeout, duration and budget must match their actual JSON-pointer
roles. A wrong pointer, unknown schema, missing mapping, missing association
review or expanded budget is rejected. Six actual native DSL controls passed
in 7.955 seconds; 79 focused framework tests and 21 suite-framework tests passed
separately. These are not additional native runtime cases.

Before/after source identities contain no missing inputs and differ only in
seventeen generated C files. Every locked C/SCM/header input represented in the
linked identity still matches its candidate hash. The actual linked identities
are gsi `a786635939c043cdee51b4824b988a350f397e475296e3c8069971296ed195cf`,
gsc `6c0fbc0b19ef5ee26fa89166fdfb1b5cd05fd7661d09b2511b916d021a204c23`,
and library `5b06cfe0977fa5b271afa03e1d1607705730a3468606bfb13d9f2661af885bc7`.
The outer receipt hash is
`2e4d111e598009fe5d88f58bb86f5b42d76110497c44f25288e483c5f99ef7fc`;
the child receipt hash is
`3e8148b72f6470920feb66e9dcce7b24a3dd33ab2abafd5e8a306185630fd33f`.
These are historical observations, not promises of byte-identical timing.

Two prelaunch integration rejections were retained in the work record: importing
historical suite producers through archive validation, and declaring archived
observations as new build inputs. Archive validation now uses the existing pure
suite primitives, with 21 suite-framework regressions. Historical bytes enter
only the typed review transport, where exact hashes and field mappings are
checked; they cannot supply a runtime artifact. No unchanged native timeout was
repeated by either rejected launch.

## Remaining Acceptance Grid

The next acceptance target is the full same-candidate native grid. It must carry
the just-produced artifact identity, preserve failed-route review and original
budgets, and avoid rebuilding merely to move between framework stages.

| Requirement | Completion Condition | Current Gap |
| --- | --- | --- |
| Full interpreted inventory | Every upstream gsi test file and assertion, exact fixture hashes, zero skips, real requested processor population | Default upstream inventory plus Darwin process fixture passed 375/375 on the complete bootstrap artifact; additional regression and stress requirements remain open |
| Full compiled inventory | Every gsc test, including numeric compiler and thread regressions, exact file inventory, no censored compilation | Not run; historical compiler/budget cases still require scoped causal review |
| Parallel copying GC | Recursive moving roots, strong/weak phases, queue/count/wait convergence, FFI roots and real forced GC | Local models and projected schedules do not establish the whole native collector |
| Independent threaded VMs | Multiple simultaneously live VM instances, each with real processor cohorts, GC and isolated roots; resize/shrink/reuse/cleanup | One real simultaneous-cohort, private-root, forced-GC and drain/cleanup fixture passed on the complete bootstrap artifact; repeated reuse, injected lifecycle failures and sustained stress remain open |
| Lifecycle reliability | Startup failures, failed joins, admission drain, retained ownership and cleanup under concurrency | Complete linked-runtime coverage remains open |
| Gerbil and performance | Current staging, complete standard-library and MCP/ASCENT tests, repeated cold measurements and sustained stress | No new Gerbil or package timing follows from this bootstrap |

Source correspondence must use the current locked overlay, not silently reuse
line-number claims about an older candidate. The recursive-GC source obligations
and existing failed-route records remain references, not blanket proof that
their remaining assumptions have been discharged. Only the entire grid can
support SMP / multiple-threaded-VM acceptance.

## Same-Artifact Native Grid Handoff

The completed two-pass producer now enters the native grid through
`gambit.completed-runtime`, not a new build or an old seed binary. Its typed
reference binds the original outer/child/step receipts, source lock, GNU compiler
and complete materialized tree. Completion, teardown and currentness are checked
before and after transfer. The original producer expenditure remains in the
consumer receipt; copying is not admission or a reset of failed-job budgets.

The first transfer was rejected because copying expanded eight internal binary
symlinks. Preserving those links restored exact tree equality without weakening
hash checks. The subsequent grid preflight took 37.474 seconds under its original
300-second cap: materialization, model checks and same-artifact transfer passed;
both native reviews required additional premises. No native suite ran.

The first handoff selected 374 default upstream files per mode. Four
upstream stress files excluded by the default runner remain explicit additional
requirements; independent live VMs, forced GC, FFI and lifecycle coverage are not
implied by that default inventory. Current review exposes seven interpreted and
fifteen compiled failure routes. These are conservative preflight selections,
not new runtime failures: root-level interpreted summaries and compiler-only
diagnostics still need exact mode/phase correspondence. Unknown scope must remain
blocking. An individual original 20-second bound must remain enforced inside a
300-second campaign, rather than being enlarged by its containing budget.

The focused producer/native/archive/kernel regressions passed: 107 tests in
1.227 seconds. The atomic-publication historical helper was recovered directly
from Git with its original SHA-256, rather than replacing the historical receipt
with current helper bytes; all three fixture checks passed. Neither result closes
the complete native, Gerbil or performance gates above.

The source-bound `native-failure-scope-controls` campaign then passed in
16.702 seconds (17.520 including preparation), retaining its 90-second cap.
It checks finite mode overlap and nested-budget safety, including a negative
control in which an individual cap is exceeded while the whole cap still holds.
The initial Quint nondeterminism type error is retained separately. Transport
now projects explicitly recorded interpreted-summary and compiler-phase modes;
unknown or mixed unbound modes remain conservative. This does not discharge
causality, authorize retries or implement nested execution deadlines. The 115
focused regression checks passed in 1.188 seconds. Scoped deadline enforcement,
complete typed reviews and the actual native grid remain required next gates.

## Nested Native Execution Budgets

`gambit.suite` now accepts an exact `fileBudgetSeconds` mapping. Only listed
files from the declared inventory can receive finite positive caps. A capped
file is isolated from its existing shard; other files remain grouped, and the
same worker pool is retained. Its deadline starts before shard preparation and
is bounded by the containing batch and whole-step deadlines. A child timeout or
late completion remains rejected. The complete inventory is not reduced.

Typed review can bind an original single-file whole campaign to that exact
file's independently enforced cap within a larger whole campaign. Transport
requires the original receipt's `selectedFiles` to be exactly that one file,
matching both the failure route and current inventory. Native DSL accepts only
whole-to-whole regime correspondence for this scoped case; atomic-to-whole
waivers remain denied. Causal claims and topology assumptions are still required.
The native grid carries original 20-second caps for interpreted `prim_port` and
compiled `fxmul`; these are not new relaxed suite limits.

The 52 focused transport/executor checks passed in 0.427 seconds. Four actual
sealed native DSL controls passed in 14.624 seconds, including expanded-cap,
missing-cap and false-scope rejection. These controls use transport fixtures,
not live GC or independently running VMs.

The complete 30-test native review domain did **not** pass: the two-worker
60-second shared deadline ended at 60.013 seconds, one lane was censored and the
other returned an inference timeout. Its raw logs and original failure receipt
remain in `native-failure-scope/nested-budget-validation`. An earlier 26-test
sealed serial diagnostic passed in 75.298 seconds but is not budget admission.
Do not substitute the four focused controls for the complete domain gate.

The existing eight source retirement schedule controls were freshly compiled
and passed through the sealed source/evidence lane in 8.022 seconds under the
original 90-second cap. They use the historical locked026 source slice and
mocked schedules, not the current complete runtime. The original 069-006 receipt
is untouched; current correspondence still requires a separately archived and
bound observation, not rewriting its old hashes.

The full scoped-grid prelaunch attempt retained DENY in 7.485 seconds: TLC's
local loopback operation was denied before the protocol command could launch.
No artifact transfer, native review or native suite ran. A subsequent explicit
loopback-authorized attempt was rejected by the unchanged-route safeguard;
host authorization is not currently a typed causal delta in that contract.
These are transport/environment failures, not new GC failures. Do not omit the
prior record or alter a model merely to defeat that safeguard. The framework
needs an explicit source-bound environment/authorization observation before
this same route can proceed under changed host permission.

## Verified Environment Recovery And Historical Producer Binding

Host prerequisite observations now record a real IPv4 loopback bind, observed
errno and available boot identity. Unknown historical permission errors do not
qualify as environment repairs. Explicit prelaunch denials can be retried as
fresh attempts only with their original measured expenditure retained and
budgets unchanged. This is not resumption of a live job or old monotonic deadline;
an absent boot identity is not fabricated. Started children, unknown outcomes,
missing expenditure and expanded budgets remain blocking. Probe success is not
a port lease, tool success, causal review or native admission.

The revised source-bound recovery QNT controls passed in 20.389 seconds under
90 seconds. The real same-engine/recipe recovery retained the original EPERM
denial's 0.967 seconds and 300-second cap, then passed TLC in the authorized host
environment. That run retained DENY at the completed-producer input check.

Inspection found exactly one changed original input: the now-expanded suite
review policy. No original receipts or binaries were altered. Its original
`e4e49c2b...` bytes are archived in the versioned `bootstrap-inputs` fixture.
The generic historical-input inspector validates the exact original receipt,
input role and snapshot digest, never substitutes tools or runtime outputs,
and reports `HISTORICAL_BOUND` rather than `CURRENT`. The original bootstrap now
has that explicit historical status. Consumption separately rechecks current
locked source, GNU compiler and the complete linked runtime tree, while current
causal review still uses the new policy.

The subsequent complete-grid preflight on engine
`d5e22f34b148a013b2d40b5c440c5c9b37a15ccfbda03291f0ed0272b9b260db`
passed materialization, parsing, typechecking, TLC and same-artifact transfer.
It took 44.495 seconds in the sealed child (45.527 including preparation), below
300 seconds; parent reaped and group quiescent. This is **preflight duration**,
not package cold-build or complete-test timing. Native ASCENT selected six gsi
and ten gsc original failure routes, with both original 20-second file caps
bound. Both reviews returned `REVIEW_REQUIRED`, so no native suite ran.

The 114 focused framework checks passed in 1.229 seconds. The complete native
review domain's retained 60-second denial and full correctness-grid gaps above
remain open. Next work is immutable raw failure/identity/log correspondence and
complete causal review for these sixteen routes, not another unchanged failed
native run or a rebuild of the accepted bootstrap artifact.

## Complete Inventory And Historical Suite Binding

The original interpreted campaign selected 375 files. Comparison found exactly
one omission from the newer grid: `12-os/process_spawn.scm`, the retained Darwin
process-creation regression. Its original receipt-bound bytes are now the
versioned fixture `models/gambit/native/process_spawn.scm`, SHA-256
`eba139d1aa995cc78e53891d5bcf93fd7ce33eff08f6080f52efb78a8f5c98c7`.
Both current recipe modes select 375 files, with the same fixture in review and
execution. Extra fixtures cannot overwrite upstream inputs or drift from their
declared hashes. This scope restoration is not a completed 375-file run.

The original interpreted suite receipt, candidate identity, processor probe and
partial log are archived under `thread-completion-contract/interpreted-suite-history`.
The original DENY, 300-second budget and 300.094-second timed-out observation
remain unchanged. Parent exit and an original receipt-bound log digest were not
recorded; archival does not invent either. All five corresponding failure IDs
attach the same version-bound observation, retaining every original receipt
and all 37 canonical failure IDs.

Native Scheme policy requires eight exact field roles: status, exit, timeout,
duration, original budget, mode, file denominator and candidate identity.
Python transports matching values; it cannot infer retry permission. Log
association, actual changed inputs and causal review remain separately required.
Archive, inventory and real native-policy controls passed: 55 tests, 29.673
seconds. This is framework validation, not SMP native acceptance. The next grid
must consume the completed bootstrap artifact without rebuilding it, and must
not bypass the pending six interpreted and ten compiled route reviews.

The first restored-inventory attempt retained DENY in 15.173 seconds because
attaching the recovered suite observation changed an original bootstrap input:
the canonical failure inventory. Its exact original `de40dc66...` bytes are now
retained in `complete-inventory-bootstrap-inputs`, alongside an explicit binding
to the already archived original review policy. A new completed-producer proof
references this manifest; original receipts, artifacts and older proofs remain
unchanged. Historical inputs never replace current review policy or runtime
source checks.

The subsequent actual run used engine
`aecc4d9b387a5e8379a3eb06e2cfef168fb5518e41f525f041bb62429985af46`.
Source materialization, parse, typecheck, TLC and completed-artifact reuse passed.
Both modes bound exactly 375 files. Forty exact historical field roles were
observed for the five suite routes. The child took 40.106 seconds; the whole
caller took 41.730 seconds under 300, without timeout, with parent reaped and
group quiescent. A subsequent sealed read reported CURRENT / DENY. The outer
receipt SHA-256 is
`07284a759718ee3bd05c75253f49cb2442d48eda35a837ea3ed6aadbbad70844`.

Both native reviews remain REVIEW_REQUIRED: six interpreted routes require 23
claim premises, ten compiled routes require 30. These 53 premises are preflight
requirements, not new failed native tests. Neither native suite started.
Independent simultaneous threaded VMs, full moving-GC/FFI/lifecycle coverage,
Gerbil correctness and release performance remain open. This 41.730-second
measurement is not a package cold build or complete test duration.

## Current Whole-Chain Checkpoint

The later `unified-environment-grid` run used engine
`e806157957da47b0efcc3a7de5403a8f482b9fb995c42612ac6d7b0f634a3e20`.
The same completed bootstrap artifact passed all 375 declared interpreted
files, with no skips. Five executed groups covered 119, 1, 5, 125 and 125 files;
the host-derived plan used three workers with three processors each. These
observed counts are not constants in the recipe. The caller took 66.133 seconds
under the original 300-second cap, with stable inputs and quiescent teardown.
This is the framework campaign time, not a package build/test measurement or a
standalone interpreted-suite wall time. The overall result remains CURRENT /
DENY: compiled review selected ten routes with thirty missing premises, so the
compiled suite and terminal acceptance did not pass.

Historical atomic campaigns declared 379 files, not 375. Their four additional
files are `thread_interrupt_ended.scm`, `pipe_concurrent.scm`, `serialization.scm`
and `serialization_gc.scm`. They are PR regressions, **not** the four upstream
stress files. Both sets are mandatory distinct coverage. The pipe fixture's
tested digest is `760513881622cd51bbf258eebd8ac09562ef85e4f84330c33fbc1020df366f93`;
its per-read-deadline patch must be applied rather than silently substituting
the unpatched fixture. Restoring these files also restores their canonical
failed routes and original per-file limits; no new native retry is admitted by
this inventory audit alone.

Actual native ASCENT controls reproduced a policy defect: equal whole-suite
topology was accepted even without exact inventory correspondence. The Scheme
DSL now requires exact whole inventory or an already-bound original single-file
scope for same-topology campaigns, just as for changed topology. Build-step and
atomic-coverage contracts remain distinct; atomic-to-whole conversion is still
denied. The original counterexample is retained. The positive exact-scope,
same-regime omission, nested-cap expansion and bootstrap-budget transport
controls passed through the sealed implementation: four tests, 18.822 seconds,
zero skips. They are conditional review controls, not native SMP correctness.

The extended QNT scope controls passed through engine
`0c84bcd513a8d39b7b60e472f496843dcf5f65c3587fbaf1ef30a2149392da5e`
in 18.095 seconds under the original 90-second budget, including explicit
addition and omission counterexamples. No relaxed scope or cap is implied.
The mixed transport test invocation ran 75 tests but skipped 34 sealed-only
tests; it is **not** full-domain admission. A separate sealed four-test run
above covers only the named controls. The retained complete-domain 60-second
failure still requires a fresh matching qualification with the framework owner.

Five failed compiled-suite histories now have portable, hash-checked archives
under `evidence/source-results/fixtures/thread-completion-contract/`:

| Fixture | Original Boundary | Validated Evidence Files |
| --- | --- | --- |
| `checked-negation-suite-history` | Checked multiplication assertion; original single-file cap | 6 |
| `thread-completion-suite-history` | Six thread files; original group cap | 6 |
| `balanced-compiled-suite-history` | Complete 375-file compiled campaign timeout | 8 |
| `serialization-vector-atomic-history` | Original 379-file atomic plan, partial observed batch | 8 |
| `numeric-compiled-atomic-history` | Original 379-file atomic plan, partial observed batches | 101 |

Archives preserve the original receipt, candidate identity, probe and all
recorded shard logs. Unknown parent exit stays unknown; unexecuted files are not
counted as passes. Atomic budgets remain atomic budgets, not invented whole-run
caps. The generic archiver and suite transport passed 52 focused regressions in
0.404 seconds with zero skips. This makes evidence reproducible; it does not
infer causal repair or authorize another failed route.

The critical path is now compiled causal review and scope-preserving execution,
then simultaneous independent threaded VM/GC/FFI/lifecycle coverage using that
same producer. Gerbil staging, standard-library/package correctness and release
performance follow only after this native gate. Framework graph success, local
model success, separate OS processes and historical package timings cannot
replace any of these requirements.

## Original Multi-File Budgets Connected

The grid now preserves the original six-file thread campaign's 120-second cap
as `groupBudgetSeconds.thread-completion`, instead of comparing only its single
assertion file to a 300-second containing campaign. Typed transport checks exact
original group membership, current selected membership and the unchanged
original budget. Scheme DSL infers conditional whole-to-whole correspondence;
Python does not decide retry eligibility. The isolated group includes its
preparation and compilation in the shared deadline. Other groups use the same
host-capacity-derived worker pool; SMP and VM flags are not reduced.

The new QNT model's five trajectories and bounded exhaustive/negative controls
passed. The sealed invocation took 16.744 seconds under 90 seconds, exhausting
410 distinct / 1,861 generated states with an empty queue. Four actual sealed
native ASCENT review controls passed in 18.363 seconds, zero skips. Seventy-nine
focused archive/transport/executor tests passed in 0.637 seconds, zero skips,
including a preparation-expiry test that verifies no child launches. These are
framework and model results, not complete runtime acceptance.

Two compiled semantic routes now have immutable typed causal intents: checked
negation overflow and thread-start completion. The original logs bind the
exact original receipts/identities; header/fixture before and after digests
bind actual changed bytes. Finite model assumptions, original assertions,
20-second single-file and 120-second six-file limits remain explicit. Earlier
passes of these repairs do not qualify the current producer. The other compiled
cost/environment routes still need their own complete causal premises.

Both mode reviews now precede either complete suite. The previously successful
375-file interpreter campaign is not rerun merely to discover an already-known
missing compiled premise. Both suites remain mandatory in the eventual same-
candidate acceptance; this scheduling change neither omits tests nor grants a
compiled retry. All 63 research recipes load through the existing framework.

## Real Independent Threaded VM Entry

The same completed bootstrap candidate now passes a real executable fixture,
`models/gambit/native/independent_threaded_vms.scm`. Two OS threads construct
independent VM states, attach their own TLS/processor state, enter the permanent
kernel module, grow separate processor cohorts, retain private Scheme roots
through forced GC, join pinned Scheme workers, shrink and clean up. This is not
two interpreter processes or an injected constructor mock. Cohort sizes derive
from observed CPU capacity: this run observed 12 available CPUs and used five
processors in each worker VM plus the control processor. The numbers are not
recipe constants. All three SMP/VM flags remain enabled.

| Scoped Observation | Result |
| --- | --- |
| Current bootstrap receipt SHA-256 | `abd06552035ab378fc3fc2782c72b43a72dfc664253141658df8c80f11d1c1d7` |
| Fixture SHA-256 | `1cf91210290a303b0b01178a0be9a370d8a657832e50b1f5876491e1229b8ff3` |
| GNU executable compilation | 2.336 seconds, exit 0 |
| Real independent-VM execution | 0.533 seconds, exit 0, exact `INDEPENDENT-THREADED-VMS:PASS` output |
| Sealed child / complete invocation | 34.164 / 34.997 seconds under the original 300-second budget |
| Process completion | Parent reaped, process group quiescent, no timeout |

Reproduce through `evidence/research/vm-kernel-entry-lifecycle/native.recipe.json`
using the existing sealed research executor and a freshly bound completed
bootstrap producer. `gambit.executable-test` checks the current producer,
GNU compiler/driver, fixture and executable bytes before and after execution;
it does not grant full runtime, collector or release admission.

The first attempt was denied at compilation because the fixture caller omitted
the explicit processor argument required by the current `___run` function-table
ABI. No VM executed in that attempt. The caller now uses `___PSA(ps)`; the
runtime ABI was not changed to accommodate a bad caller. The initial DENY is
retained separately, not replaced by the successful run. This observation added
an explicit argument-owner condition and a wrong-processor negative trajectory
to `models/gambit/vm_kernel_entry_lifecycle.qnt`.

The updated model checks seven trajectories plus exhaustive positive and
negative controls; the positive exploration exhausted 100 distinct / 381
generated states with an empty queue. This finite model covers ownership across
construction, TLS/kernel entry, cohorts, GC, drain and failed-join quarantine.
It does not establish C weak-memory refinement, all collector phases or
unbounded progress. Eighty-three focused executor/transport/archive tests passed
in 0.635 seconds with zero skips.

The complete native grid now requires both mode reviews, the VM-entry model
controls and this real fixture before its terminal verdict. The entire grid has
not yet passed: compiled causal routes, additional PR/stress regressions,
collector/FFI coverage, lifecycle failure injection, Gerbil and performance
acceptance remain mandatory. None of these scoped times are MCP build or test
measurements. All 65 research recipes load through the existing framework.

Atomic-to-atomic review now also requires an exact, nonempty, duplicate-free
original/current selected-file inventory; matching regime names alone cannot
authorize a changed scope. The same QNT campaign model includes whole and
atomic initial states, with an explicit exact-atomic trajectory. Python only
projects the bound inventory fact; Scheme DSL decides correspondence. Original
batch caps and causal-review obligations remain mandatory. This guard is not a
proof that a new atomic partition or processor plan preserves every original
batch's work; those changes still require their own review premises.

Framework qualification remains separate: the latest complete 76-test domain
finished in 58.115 seconds under its unchanged 60-second budget, but was denied
because temporary request/reply originals had been cleaned before final raw
binding checks. No full graph followed that DENY. The framework owner is fixing
immutable evidence retention before a fresh seal and qualification; test-count
success is not domain or native acceptance.

## Current Numeric Compilation Boundary

The existing `compiler-cost` framework CLI ran the unchanged upstream
`03-number/_num.scm` on the completed bootstrap candidate above, without
rebuilding or increasing the original 90-second diagnostic budget. Its
continuous three-phase result passed in 29.629 seconds: Scheme-to-C 9.830,
GNU GCC dynamic-module compilation 18.702, and real compiled assertions 0.964.
Each child exited zero without a timeout and with a quiescent process group.
Source, runtime and GNU driver bindings remained stable. Processor population
was host-selected, not a fixed recipe constant. The correctness driver uses
`-O0` and disables GNU macro tracking; this is not a release performance result.

Portable facts and raw-evidence digests are recorded in
`evidence/source-results/fixtures/thread-completion-contract/current-bootstrap-numeric-phases/observation.json`.
That record explicitly does not contain the complete raw archive: the verbose
compiler log contains a personal include path and is kept local. It cannot
satisfy an immutable raw-evidence review or grant retry/native admission.
Reproduce from the pinned submodule and locked overlay through the completed
bootstrap, then invoke the existing CLI against that exact producer:

```sh
.venv/bin/gambit-smp compiler-cost \
  --runtime "$CURRENT_BOOTSTRAP_RUNTIME" \
  --toolchain-receipt "$CURRENT_BOOTSTRAP_IDENTITY" \
  --gcc "$GNU_GCC" --out "$NEW_DIAGNOSTIC_OUTPUT" \
  --timeout 90 03-number/_num.scm
```

This is stronger current-candidate evidence than the historical censored
numeric compilation, but not an isolated causal speedup measurement or a full
375/379-file compiled pass. The next complete native invocation still needs
scope-preserving causal review and its original containing/group/file budgets.
The unpinned shrinking requester, failed joins, moving-root/FFI compositions,
additional PR/stress regressions and full Gerbil gates remain requirements.

The later complete framework domain also timed out at its unchanged 60-second
limit (60.557 seconds observed including termination). Both lanes were reaped
and quiescent; no full graph launched. The framework owner is changing full
SHA verification traversal, not removing source checks or widening this budget.

## Registry Lifetime Reopened By Source Audit

The previous independent-VM fixture's successful execution is retained, but it
does **not** qualify concurrent VM registry cleanup. Source audit found that
`lib/mem.c:___cleanup_mem_vmstate` explicitly assumes `vm_list_mut` is held
while it changes both circular-list links. The fixture calls `cleanup_vmstate`
without that caller lock. Moreover, `lib/setup.c:___raise_interrupt` traverses
the same list with its reader mutex disabled under `#if 0`, citing recursive
deadlock. Therefore adding only a writer mutex cannot establish reader lifetime
safety. The existing `vm_list_reader_retirement` and `vm_list_c_memory_order`
models already explain why writer-only locking and one-sided/volatile pointer
publication are insufficient; their failure routes are not rerun.

`models/gambit/vm_registry_interrupt_admission.qnt` adds a **proposal**, not a
claim about implemented source: atomically couple reader admission and the
closed bit, drain admitted readers before unlink/reclaim, let signal-context
callers defer interrupt bits without blocking, and recheck reopening after
recording so a late mailbox publication cannot be stranded. One writer epoch,
two distinct coalesced bits and a live anchor are finite bounds, not CPU counts.
Repeated writers/epochs, physical C memory ordering, lock-free atomic support,
reader bounds/overflow, constructor publication, GC/FFI ownership and all native
failure paths still need source refinement and acceptance. VM execution and GC
must remain concurrent; only registry mutation is serialized.

Five trajectories passed, including the two unsafe-policy controls. The existing
framework `check` command then recorded both actual counterexamples and fully
exhausted the proposal's positive `safe` and `noStall` checks: each positive has
220 distinct / 575 generated states and an empty queue. Each check took
3.840--3.886 seconds under its unchanged 15-second cap. `noStall` is a finite
deadlock condition, not an unbounded fairness or throughput proof. An initial
trajectory called `enabled(step)` through the simulator, which does not support
that builtin; the trajectory now checks the concrete quiescent/pending witness,
while TLC still verifies the unchanged `noStall` condition. No control was
removed or converted to a pass.

Both this proposal and `vm_kernel_entry_lifecycle` are now registered in the
existing `models/gambit/cases.json` and raw-log attestation catalog. Canonical
framework receipts, redacted logs, counterexamples and exact model snapshots
are durable under `evidence/model-results/vm-registry-interrupt-admission*` and
`vm-kernel-entry-lifecycle*`. Recovery diagnostic files referring to local
working directories remain local, not Git evidence inputs. There is no new
framework or legacy single-interpreter native adapter for the executable
fixture. PR988 supplies context only; this proposal is not attributed to that PR.

The real compiled ASCENT catalog validation passed with the sealed API, and
the canonical fact export was refreshed. It records 13 finite model admissions,
not runtime admission, and preserves all reported/local failures and open
obligations. Thirteen focused recovery/projection/numeric-evidence tests passed
without skips in 0.520 seconds. Complete graph and SMP acceptance remain open.

## Integrated Framework Gate And Repeated Registry Mutation

The frozen complete framework gate passed 975 tests with zero failures,
errors or skips. Its complete 79-test native-review domain passed in 52.130
seconds under the original 60-second budget, with both owner archives complete
and both children exited zero without a timeout. The containing process exited
zero in 184.119 seconds under its original 300-second budget; the validation
itself took 174.158 seconds, with no changed inputs. Current-context readback
passed before the following edits. This is a historical exact-input framework
qualification, not current-source runtime admission. Later model/catalog edits
must make that snapshot stale; it must not be silently reused as current.

`vm_registry_repeated_retirement.qnt` extends the registry proposal to two
mutation epochs. Both direct requests and deferred interrupt replay must own a
reader lease. Checking an open gate and only later registering the reader is
unsafe; so is replaying after reopening without joining the reader population.
Both policies produced actual counterexamples through the existing `check`
framework. Three positive checks (safety, terminal delivery and finite deadlock)
fully explored 255 distinct / 627 generated states with empty queues. All five
checks completed in 3.791--4.885 seconds within their original 15-second caps;
three trajectory tests also passed. Typechecking passed. An initial direct
verifier invocation could not bind its local compiler service inside the
sandbox; this was an execution-environment error, not a model counterexample.

The canonical receipt, redacted raw logs, negative traces and exact model
snapshot are durable under `evidence/model-results/vm-registry-repeated-retirement*`.
The existing cases and raw-attestation catalogs register them; real compiled
ASCENT catalog validation passed with 14 finite admissions. No separate Python
framework or native adapter was introduced. Source implementation, physical C
memory ordering, arbitrary epochs, shutdown admission, reader overflow and
native stress/performance remain open.

GNU GCC's current Darwin target advertises word-sized CAS and always-lock-free
pointer/long atomics. This is a target prerequisite, not a complete signal-safety
proof. Gambit's portable atomic abstraction can instead select emulated
operations on other targets. GCC also documents possible external calls for
unsupported operations: [GNU atomic builtin documentation](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fsync-Builtins.html).
Any signal-path implementation must verify the exact backend and emitted code,
not merely the existence of an atomic macro. Registry mutation may serialize;
VM execution and parallel GC must not.

The native Grid verdict now also loads `milestone-rules.ss`. Its complete
coverage query keeps nine stages open: both modes of the additional PR
regressions, both modes of upstream stress, registry lifetime, lifecycle fault
handling, GC/FFI, Gerbil correctness and release performance. A passing default
suite and independent-VM smoke cannot discharge these stages. Wrong-capability
model passes and denied native runs cannot discharge a stage either. This
coverage gate is necessary, not sufficient source/runtime admission; the
capabilities must still bind exact producer, inventory, source and budgets.
No old receipt is changed, and no unchanged full native suite was rerun.

Eight real native-DSL/Grid and executable-adapter regressions passed in 2.871
seconds under 15 seconds. Twenty-three recovery/projection/catalog regressions
passed in 7.118 seconds under the same cap with the selected compiled ASCENT
API. The initial unconfigured invocation retained five missing-API errors;
supplying the existing sealed API resolved them without altering assertions.
