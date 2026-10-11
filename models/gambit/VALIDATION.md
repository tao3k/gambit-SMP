# Initial Model Validation

## Per-Read And Serializer Feedback 2026-10-11

The per-read deadline model freezes an actual stale-deadline control; positive
TLC exhausts 77 distinct / 110 generated states. The model-bound test variant
preserves every original loop and assertion. The generic runner now reserves
its own processor from host-auto capacity in both modes. Runtime022 passes
the revised pipe fixture in 31.404 s interpreted / 49.264 s compiled, under the
unchanged 60-second whole-mode budget. Original and intermediate denied
receipts remain frozen; this is not a runtime speedup or full-suite green.

Native concurrent-GC text roundtrip then fails a key query in 2.642 seconds,
without timeout or source drift. Source `##explode-gc-hash-table` still allocates
cons cells while walking live slots. The serializer model freezes a rehash
counterexample and exhausts 37 distinct / 146 generated positive states.
The exact snapshot-cursor candidate passes real GNU GCC core rebuild in
29.894 seconds and the same regression in both modes (3.347 / 8.564 seconds).
It is not release-admitted. Inventory: 40 models, 26 native observations,
19 local failures. Framework tests pass 115/115. The later full interpreter
campaign passes all 375 original files plus four regressions (379/379) in
240.252 seconds, under the unchanged 300-second whole-mode budget. This adds
the 27th native observation, not complete compiled/bootstrap admission.

## Shared Pipe Residual 2026-10-11

That initial checkpoint contained 38 models, 22 native observations and 17 local failures.
PR1037's exact shared endpoint mutex was absent from runtime021 and is applied
in runtime022 after both predicate and close/wait proofs. The close/wait model
exhausts 27 distinct / 39 generated states and freezes two negative controls.
Actual GNU GCC core rebuild passes in 52.718 seconds; neighboring original I/O
files pass both modes. The exact upstream pipe fixture passes interpreted mode
in 26.408 seconds but compiled mode is DENY at 60.050 seconds.

Retained-module diagnosis observes EOF and timeout, not a proven lost wakeup.
Source converts the fixture's once-set relative timeout into one absolute
deadline. The timeout-contract model distinguishes valid expiry from the
incorrect no-EOF-on-open-port expectation. No runtime or full-suite repair is
claimed by that diagnostic model. See `docs/shared-pipe-predicate-lock.md`.
Framework tests pass 110/110. Complete native/bootstrap admission remains open.

## Scan Input / Model Closure 2026-10-11

Native diagnostics 012 and 013 reject movable to-space inputs before a second
copy. In 013, the field snapshot at scan entry already contains the rejected
reference; the bounded visit table was saturated, so duplicate scanning is
not established. Both failed configurations remain denied, not rerun unchanged.
See `docs/gc-old-space-input-contract.md` for the actual source/input boundary.

The expanded `gc_forward_publication` model freezes four independent controls:
publication, producer accounting, repeated slot input and relocated payload
input. Actual TLC attempt 006 found all four counterexamples. The positive
input/publication protocol exhausted 39 distinct states, 71 generated, zero
queue in 14.730 seconds. Attempt 005 was an infrastructure denial: sandbox
blocked the local Apalache socket; it is retained and not called a model pass.

The unchanged extracted `mark_array` source unit passes five mechanism controls,
including the new relocated reference in a distinct slot. Mocked allocation,
representation and CAS are not native ABI acceptance. Python framework tests
pass 72/72; current native correctness and complete bootstrap remain open.

## Diagnostic 010 / Extent And Layout

An exact, reversible diagnostic-only C delta rebuilt core with GNU GCC 16.2.0.
The first p4 decoder run passed interpreter/compiler/compiled fixture; repeat 1
failed compiler SIGBUS and stopped further retries. The new incident binds
both image UUID and the actual compiler child receipt: `mark_array +96` called
by `scan +204`. It did not trigger the special-table header probes. This is
DENY, not stability, a source repair, bootstrap or performance acceptance.

The expanded `gc_table_header_lifetime` freezes four independent controls:
forwarded header, early retirement, normal-looking wrong extent and wrong
payload layout. Positive TLC exhausts 9 distinct / 13 generated / 0 queued
states in 15.703 s. These latter controls are hypotheses, not native causality.
Attempt 003 was denied by the sandbox's local Apalache socket restriction;
attempt 004 ran the actual checker with local binding allowed. No failed
receipt is rewritten as success.

Framework tests: 62/62 passed; Datalog coverage passes. The runner now stops
after the first unadmitted model and leaves native execution not-run. Existing
coverage gaps remain 19 report links, 23 native adapters and 13 source reviews.
See `docs/native-pr793-and-gc-incident.md`. Older counts below are historical.

## Candidate 009 / Special Reader

The PR793 cleanup condition passes 24 extracted-source control outcomes and
incremental GNU GCC core rebuild. Actual p4 decoder/forced-GC interpreter,
compiler and compiled fixture pass once; the repeated compiler exits SIGBUS.
Candidate-wide acceptance is DENY, and no further unchanged compiler retry ran.
An uninstrumented incident matches the candidate binary UUID and points to
`gc_hash_table_rehash_in_situ +48`, an indexed key read. Child PID attribution
was absent from the original receipt and is not retroactively claimed.

Native feedback adds `gc_table_header_lifetime`: two independent hypothetical
controls, positive 9 distinct / 13 generated / 0 queue, 17.686 seconds. Source
causality, actual object extent, special-reader ownership and generated-source
parity remain open. See `docs/native-pr793-and-gc-incident.md`.

At this historical checkpoint: 58/58 tests passed. Coverage: 29 models, 19 reports without
model links, 23 models without native adapters, 13 adjacent-source reviews.
All earlier counts below are historical.

## Shutdown Lifecycle

`shutdown_error_handoff` binds issue 792 / PR793 to the current unguarded
processor-0 error dispatch during cleanup. It independently distinguishes the
source-ordered failure from an unproved pre-cleanup dispatch hypothesis and an
injected catcher-only error-loss control. Positive design: 22 distinct / 31
generated / 0 queue, 22.090 seconds. Native/source repair acceptance remains
open. See `docs/shutdown-error-handoff.md`.

Current framework: 50/50 tests passed. Coverage now has 28 models, 33 PR
snapshots and one linked issue snapshot, 19 reports without model links and
22 models without native adapters. Older counts below are historical snapshots.

## FFI / GC Composition

`ffi_gc_frame_protocol` links the historical PR783 report to publication,
waiting participation, relocation and generated-host reload obligations.
Three controls are frozen; positive TLC exhausts 22 distinct / 25 generated /
0 queued states. Extracted current C passes all 12 expected source-unit cases,
using mocked macros/GC. Native mock feedback added zero-GC root-clobber safety;
failed/mixed-version attempts remain DENY. See `docs/ffi-gc-frame-protocol.md`.
No runtime repair or compiler/bootstrap success is inferred from these checks.

## Expanded Bounty Evidence

The latest coverage extension inventories 127 bounty-era PRs, binds 33 report
snapshots, and adds mailbox, promise and overflow-undo models with seven frozen
negative traces. Framework tests: 43/43 passed. The native five-operation macro
fixture passed; full compiler/bootstrap acceptance remains open. See
`docs/bounty-evidence-coverage.md` for bounds, exhaustive state counts, source
classification and the remaining 20 model/20 adapter/13 adjacent-review gaps.
Earlier test counts below are historical receipts, not the current suite size.

## Forwarding, Publication And Participation

`gc_forward_publication` characterizes CAS forwarding identity before payload
copy, private destination ownership, ordered completed-chunk publication and
counted producer lifetime. It independently freezes early-publication and
uncounted-producer controls (4 and 6 states respectively); these are injected
faults, not new Gambit defect attributions. The positive protocol exhausts
39 distinct states, 71 generated, zero queue, 17.709 s.

Attempts 001/002 failed Quint conversion/parsing and remain DENY. Attempt 003
produced the expected actual TLC counterexamples and positive check, but its
aggregate admission was DENY because the original scalar decoder did not
support record values. A strict integer/Boolean/tuple/record decoder now
rejects unsupported, duplicate, truncated, trailing and structurally drifting
values. The unchanged 003 logs were redecoded without rerunning the checker;
original receipt/log digests are retained in
`evidence/model-results/gc-forward-publication.json`. The initial DENY receipt
is not overwritten. Framework unit suite: 36/36 passed.

This is bounded characterization only, not a GC patch or performance result.
Special readers, local tail scans, full graphs, C weak memory and liveness
remain outside this model. `docs/paper-source-obligations.md` describes the
source mapping. Primary papers now reside in a bounded ignored local cache;
manifest/script/tests are tracked, PDF/full-text files are not committed.

## PR 988 Additional Obligations

The complete 36-file diff is downloaded and inventory-validated; see
`docs/pr988-complete-source-audit.md`. Generated C completeness is not semantic
parity or permission to apply historical generated artifacts.

`exec_gc_polling` freezes independent blocking-read and failed-configuration
counterexamples. The checked abstract protocol exhausts 6 distinct states,
8 generated, zero queue, 15.389 s. Receipt:
`.data/pr988-exec-gc-polling-002/receipt.json`. The first attempt was a model
expression error and remains DENY, not a source counterexample.

`lazy_vm_startup` freezes the early-ready-flag/failed-resize counterexample.
The repaired sequential abstract protocol exhausts 6 distinct states,
8 generated, zero queue, 23.226 s. Receipt:
`.data/pr988-lazy-startup-001/receipt.json`. Recursive startup callbacks,
concurrent callers and resize rollback are not covered; no Scheme flag patch
is justified solely by this result. Both models have no native adapter yet.
All 20 original framework unit tests pass, including trace/digest and full-file
inventory negative controls.

## Repository Migration

The standalone `gambit-SMP` repository adds four Datalog/index tests: 24 tests
pass in total. Facts are derived from source manifests, reports and model-bound
frozen negatives. Datalog queries reveal missing evidence, not runtime safety.
An initial circular dependency query stalled; it was terminated and is DENY.
The exporter now rejects dependency cycles before entering the engine, with an
explicit negative test. This bounds the supported query domain to acyclic PR
dependencies; it does not claim cycle handling by the Datalog engine.

Three imported model receipts are under `evidence/model-results/`. They are
historical producer records with referenced raw logs retained in the originating
local investigation, not new exhaustive runs or whole-toolchain acceptance.
The complete PR988 inventory is retained under `evidence/upstream/`.

A clean-environment LLDB attempt with the unchanged release candidate compiled
the fixture successfully (10.877 s under debugger), without a fatal stop.
Failure-capture admission is DENY because there was no failure to capture.
This diagnostic changes scheduling and does not resolve the uninstrumented
SIGBUS, verify the compiled executable or justify bootstrap acceptance.

Source-backed lifecycle obligation: in the pinned source's
`___vm_resize_pstate`, the failed-setup cleanup loop decrements `i` but repeatedly
uses the failed processor's `ps`, and does not reset the target count. This is
a source audit finding subsequently checked below. No formal runtime patch
is promoted from it.

## VM Resize Failure Rollback

`vm_resize_rollback` has independent `cleanupSafe` and `targetSafe` negative
controls. The latter first fixes cleanup to isolate target restoration. Both
actual TLC traces are frozen. The combined protocol exhausts 14 distinct
states, 18 generated, zero queued, 25.353 s. Scope is grow 1 to 4, sequential
processor preparation under the synchronized operation; partial setup cleanup,
thread-create failure, shrinking, collector semantics and weak memory remain
outside the model.

`source_unit.py` extracts the unchanged `___vm_resize_pstate` body and compiles
it with GNU GCC 16.2.0 against deterministic mocked dependencies. Initial
inherited-environment linker failure is DENY, not a source counterexample.
With isolated environment, the success path passed, but failures at processor
1/2/3 retained target=4. Failures at 2/3 also invoked cleanup on the failed
processor 1/2 times and retained prior prepared states. Receipt:
`.data/vm-resize-source-old-002/receipt.json`.

The local candidate uses the decremented ID for cleanup and restores the
initial target before the barrier. All four source-unit paths pass:
`.data/vm-resize-source-fixed-001/receipt.json`. Patch is explicitly under
`patches/candidates/`, not an official toolchain patch chain. Reverse application
check confirms correspondence to the local corrected source.

Incremental GNU GCC `make -j12 core` succeeded. Candidate 008 identity is in
`.data/gc-native-candidate-008.json`. The actual interpreter's grow 1/2/4
regression passed with current source/binary identity, processor-count
assertions and lexical rollback binding, 1.091 s. Compiled test is not run:
`.data/vm-resize-real-smoke-008/receipt.json`. This does not resolve compiler
SIGBUS or qualify complete bootstrap. Framework unit suite: 27/27 passed.

## Scan Termination Composition

`gc_scan_termination` composes a producer's unfinished local work, a shared
chunk, counted active/waiting participation, termination declaration and
acknowledged strong/weak phase transition. Detached publication after an
idle declaration is fault injection, not a source defect attribution.
The source-characterization protocol exhausts 22 distinct states, 35 generated,
zero queue, 21.502 s. An actual negative trace is frozen. Receipt:
`.data/gc-scan-termination-001/receipt.json`. No GC patch follows from this
characterization. Weak memory, graph forwarding and fairness/liveness proofs
remain open. `docs/paper-source-obligations.md` maps the external publications
to current source and these exclusions. Framework unit suite: 28/28 passed.

Compiler diagnostic `.data/gc-compiler-failure-007/receipt.json` is DENY:
the private O1 symbol build exited with a missing-linker environment error,
without an observed fatal stop. This does not resolve the release compiler's
SIGBUS and is not native acceptance. Debug launches now explicitly use the
clean toolchain PATH and remove SDKROOT, LIBRARY_PATH and CPATH.

2026-10-10, Quint 0.33.0, TLC backend, macOS arm64, Java 25.0.2.
This is model evidence, not native toolchain acceptance or a performance claim.

| Model | Old mechanism | Repaired reachable states | Queue left | Repaired check wall time |
| --- | --- | --- | --- | --- |
| table_decode / 1038 | Counterexample, 3 transitions | 13 | 0 | 11.694 s |
| pipe_wait / 1037 | Counterexample, 4 transitions | 7 | 0 | 10.428 s |
| heap_floor / 1036 | Counterexample, 1 transition | 4 | 0 | 12.391 s |
| root_marker / 1010 | Counterexample, 4 transitions | 8 | 0 | 7.982 s |

All eight expected outcomes passed admission. Old mechanisms fail the safety
invariant; their counterexamples are preserved under `counterexamples/`.
These traces were decoded from actual TLC output, not manually invented.
Six Python gate tests passed, including frozen counterexample/model digest
binding, tool-error rejection, exhausted-queue admission, strict trace decoding,
timeout reaping, and binary-identity rejection.

The first gate invocation rejected genuine counterexamples because its parser
expected the source invariant name rather than TLC's generated `q_inv`, and
TLC did not export the requested ITF files. Neither rejection was counted as
model success. The decoder and its negative controls were fixed, then all
eight checks were rerun successfully.

## Candidate Native Checks

GNU GCC 16.2.0, pinned Gambit revision from `cases.json`, multiple VMs,
multiple-threaded VMs and SMP enabled. `make -j12 core` passed using the cached
WIP bootstrap compiler. This is NOT a successful threaded self-bootstrap.

Candidate 002 adds the Scheme hash-policy notification to the prior C root,
RC-root, root-scan barrier and mixed-key guard experiments. Its exact artifacts
and source digests are in `.data/gc-native-candidate-002.json`.

| Case | Processors | Interpreted | Compile | Compiled execution | Admission |
| --- | --- | --- | --- | --- | --- |
| Uniform symbol keys, 5 forced GCs | 1 | 0.919 s | 3.103 s | 0.639 s | focused pass |
| Mixed keys, forced GC | 1 | 0.018 s | 3.166 s | 0.767 s | focused pass |
| Uniform symbol keys, 5 forced GCs | 4 | 42.465 s, exit 70, Heap overflow | not run | not run | DENY |

Candidate 003 incorrectly applied a copied-stack marker edit to processor
setup. `write_shared` compilation exited with signal 11 in 0.906 s; debugger
stopped in `___setup_mem_pstate` at a null write. This is a LOCAL EDIT DEFECT,
not evidence of the upstream reported compiler crash. It was corrected and
must remain excluded from acceptance. A source-binding negative test now
rejects that exact wrong-function change before any native invocation.

Nine Python gate tests pass, including source-binding negative controls and
stale/failed model-receipt rejection. The root-marker C/FFI adapter remains
pending. No candidate is promoted to the official patch chain or release.

`gc_stack_lifecycle` TLC verification passed: old produced a two-transition
null-write counterexample; fixed exhausted all 10 reachable states with zero
queued states (13.282 s). Both earlier parser/effect-check failures were denied,
not classified as counterexamples. The counterexample is frozen and digest-bound.

Candidate 004 corrects the accidental edit and passes both lifecycle TLC and
source-binding admission. The four-processor hash-policy fixture nevertheless
reports Heap overflow, exit 70, after 59.563 s (not timeout). Compilation and
compiled execution are not run. Receipt:
`.data/gc-native-hash-policy-p4-004/receipt.json`. This rejects the combined
candidate; the bounded stack model does not explain the parallel failure.

## Failure-Guided Source Audit

`gc_rehash_protocol` combines GC/decode entry and C/Scheme hash consumers:
three separately checked old invariants produced actual counterexamples
(`safe`, `decodeSafe`, `uniformSafe`). The repaired composite check exhausted
25 reachable states with zero queued states, 8.788 s. Each counterexample is
frozen with the current model digest. This supersedes the weaker first version
which assumed that the decoder invoked repair. Ten Python gate tests pass.
No native run was used to discover or validate these abstract counterexamples.

The same artifact's debugger-only receipt is
`.data/gc-native-fatal-stack-004/receipt.json`. A breakpoint in the actual
`___fatal_error` symbol captured a secondary processor at
`mark_array -> scan -> mark_reachable_from_marked -> ___garbage_collect_pstate`.
Other processors were scanning or waiting for scan termination. This narrows
the phase, not the root cause. The first attempt at `fatal_heap_overflow` had
zero breakpoint locations (inlined/optimized); it is not a captured stack.

Rejected hypothesis: unprotected concurrent stack-frame copying.
`mark_captured_continuation` already holds `MISC_MEM_LOCK` around the copying
loop. Do not model the actual source as lacking that lock or add a duplicate
lock based only on the failure stack. The existing root-phase barrier model
does not prove the entire transitive scan or heap-section capacity protocol.

Upstream PR 1014 scales the default startup minimum heap; PR 1036 enforces the
section-count floor during resize. They are different obligations. The pinned
source uses half of cache size for default minimum, whereas 1014's diff context
uses three quarters. Do not apply that historical context blindly or claim the
startup sizing change repairs this mark/scan failure without causal evidence.

The `_system.scm` pre-edit MCP balance baseline was rejected at lines
1432/1437 in an existing embedded-C region. The user authorized replacing this
scanner with Gambit's native reader plus the actual WIP full-module compiler.
Both unedited baseline and the PR1038 decoder changes passed: 144 reader forms,
full module generation in 20.244 s / 47.114 s respectively. No inherited C block
was altered to satisfy the scanner. Candidate 005's incremental `make -j12 core`
completed with GNU GCC 16.2.0; self-bootstrap remains unaccepted.

## Synchronized Decoder and GC Models

`gc_rehash_protocol` now distinguishes decoder repair from GC repair, and
explores up to two subsequent moving GCs. Four old/fault-specific invariants
produce digest-bound TLC counterexamples. `gcSafe` uses `initDecodedOld`:
decoding and the first access succeed, then the first GC corrupts the mixed key.
The repaired composite check exhausted 61 distinct states, 79 generated,
zero queued states, 21.720 s. Prior 25-state evidence covers the weaker model
only and is not reusable for this new model digest.

Candidate 005 includes both decoder calls and the same-table C entry repair.
The actual fixture includes text/binary serialization, eq?/eqv?/equal?, plain
decode and decode followed by five forced GCs.

| Processors | Interpreted | Compile | Compiled execution | Admission |
| --- | --- | --- | --- | --- |
| 1 | 0.555 s | 7.157 s | 0.532 s | focused pass |
| 2 | 0.703 s | 3.808 s | 1.298 s | focused pass |
| 4 | 27.124 s, exit 70, expected 104 but got missing | not run | not run | DENY |

The four-processor failure is a real key lookup mismatch, not a timeout or
Heap overflow. The layout model assumes key references are already correctly
forwarded; it does not explain this failure. `gc_key_reference` adds a separate
conditional obligation for updating the table slot even when another root
retains the object. Its negative control injects a missing scan; this flag value
has NOT been observed in the failing native run. `##table-get-gcht` normally sets
MEM_ALLOC_KEYS, so no runtime flag/scan change is justified by this model alone.
The key-reference positive control exhausted 6 distinct states, 8 generated,
zero queued states, 22.748 s; the missing-scan counterexample is frozen.
Ten gate unit tests pass, including all four rehash counterexamples and rejection
of receipts from the wrong fault-specific initializer.

One additional diagnostic attempt adds case/format/predicate/GC context only;
it does not change the candidate binary. It produced no first-case output and
was killed/reaped at 45.009 s, exit -9. Receipt:
`.data/gc-native-decode-context-p4-005/receipt.json`. This is a timeout DENY,
not evidence of the previous key mismatch's cause and not a completed test.
Do not rerun this unchanged diagnostic as an acceptance route.

## Transaction Boundary Audit

`##object->serial-number` uses two shared tables and a shared counter under
`not interrupts-enabled`, not a cross-processor transaction guard. PR989's
individual C table locks do not serialize this entire compound operation.
`serial_number_transaction` deliberately assumes an atomic counter and atomic
individual accesses, a stronger control than the current source. TLC still
finds two same-object calls returning 1 and 2. The serialized abstract protocol
exhausts 23 distinct states, 27 generated, zero queue, 13.745 s.

One actual two-processor public-API diagnostic passed in 0.035 s on candidate
005, 2,048 shared keys. This does NOT reproduce the abstract interleaving,
prove transaction safety, or explain the earlier decoder mismatch. No lock
patch is promoted from this evidence. Fixture and binary identity are bound in
`.data/serial-number-native-diagnostic-005/receipt.json`.

An isolated build with ENABLE_CONSISTENCY_CHECKS alone fails compilation:
debug fields/constants depend on DEBUG_GARBAGE_COLLECT, which changes state
layout. It is not a native counterexample. `debug_runtime.py` instead rebuilds
only mem.c with DWARF and unchanged ABI, replaces that archive member in a
private copy, and links a private interpreter; candidate artifacts are untouched.
No consistency-check acceptance is claimed from the resulting symbol build.

## Barrier Message Publication Candidate

Source audit identifies that SYNC_SEND_MSG's existing fence is after its flag
store, and SYNC_GET_MSG's spin exit lacks a receive fence. Candidate 005's
GNU GCC ARM64 disassembly has ordinary LDR polling followed directly by payload
LDP/LDR, without a DMB on that fast path. Slow-path mutex acquisition is a
different synchronization path; it cannot justify the unguarded spin path.

`sync_message_acquire` separately freezes old, release-only and acquire-only
counterexamples. The paired protocol exhausts 6 distinct states, 9 generated,
zero queued states, 17.522 s. This finite weak-visibility abstraction does not
prove C data-race freedom, barrier generations, or native failure causality.
The first receive-only model is superseded; its weaker receipt is stale.

Candidate 006 adds only sender pre-flag and receiver post-poll fences to
setup.c. Incremental GNU GCC core build and source binding passed. ARM64
disassembly confirms the corresponding DMBs, retained under
`.data/sync-fence-codegen-006/`. Original candidate 005 binaries/archive/source
are preserved separately. No formal patch or release was promoted.

Actual four-processor decode/GC regression times out at 45.006 s, exit -9,
without a first-case line; compilation and compiled execution are not run.
Receipt: `.data/gc-native-decode-p4-006/receipt.json`. Candidate 006 is DENIED;
the fences do not resolve the observed stall. Do not repeat this unchanged
native route or full bootstrap. Next source/model obligation is barrier rounds
and VM/GC lifecycle, not another one-message acceptance claim.

Two debugger attempts are diagnostic failures, not root-cause captures:
005 stops on Gambit's normal SIGALRM; 006 races the asynchronous launch stop
and captures dyld before useful execution. Both inferior processes were killed.
Their stacks do not prove runtime deadlock. Twelve gate unit tests pass,
including one-sided/misordered fence and frozen fault-control rejections.

Unresolved: forced GC after decoding, compiled write_shared signal 11, and
the locally observed later parallel mark/scan heap overflow. These remain
release blockers and are not closed by the bounded model checks.

## Synchronous Protocol Model Refinement

Candidate 006's bounded runtime/load probe prints `RUNTIME-READY`, then times
out while loading the decoder fixture: 10.015 s, exit -9. This narrows the
observed boundary; it does not prove that initialization or all later GC
phases are correct. Receipt: `.data/gc-runtime-load-boundary-006/receipt.json`.

Source-symbol captures 007/008 inspect running GC rather than dyld startup.
Capture 008 observes the post-strong-phase barrier, scan-worker counts [0, 4],
and processor 1 waiting for child 3 despite its ready mailbox. This SINGLE
debugger snapshot is not a lost-wake proof: arrival before rescheduling is
legal. Debugger SIGSTOP is intentional; normal SIGALRM is not a crash.
Private debug binaries and observation time are not release performance data.

Two QNT refinements now constrain interpretation of that native evidence:

| Model | Actual exhaustive result | Evidence boundary |
| --- | --- | --- |
| `sync_tree_rounds` | Both invariants pass; each 724 distinct / 1,961 generated / zero queued states | Four processors, two rounds, coherent atomic mailboxes, fixed population |
| `sync_wait_handshake` | Split-wait fault control produces a frozen lost-wake counterexample; source-order atomic protocol passes, 21 distinct / 29 generated / zero queued states | One slow-path message, same mutex, atomic POSIX wait, unlock before signal; no fairness or C weak-memory proof |

Tree receipt: `.data/sync-tree-rounds-002/receipt.json`. Initial 001 is a
model evaluation error (missing-child map access), DENIED, not a native
counterexample. Wait receipt: `.data/sync-wait-handshake-002/receipt.json`;
001 modeled a different signal order and is superseded. The current wait
receipt binds setup.c SHA-256 and verifies predicate/mutex/statement order.
That lexical binding is not C semantic verification.

The gate supports explicit characterization checks without manufacturing
old/fixed repair claims, and requires all declared invariants on evidence
reuse. Fifteen unit tests pass, including frozen fault controls, source
ordering and incomplete/duplicate characterization-receipt rejection.
No native candidate or formal patch is promoted. Remaining obligations include
VM population changes, GC phase participation and C mailbox memory semantics;
unchanged failed native routes remain denied.

## Native Capacity Evidence And Candidate 007

Same-process observations are retained in `.data/gc-same-process-009/` and
`.data/gc-capacity-snapshots-010/`. The latter captures completed GC counts
317 and 569, with unchanged 9-section heap, 8 assigned sections, 4 stacks,
131,072 words per section and 204,808-word overflow reserve. The allocation
admission expression is therefore -73,736 words, below the 131,072-word
next-section requirement. This is frequent GC with observed phase progress,
not proof of a fixed tree-barrier deadlock. Debugger wall time is not a
performance benchmark or measurement of uninstrumented GC throughput.

`heap_allocation_headroom` freezes this insufficient-floor counterexample;
the proposed reserve-plus-next-section floor passes (4 distinct / 7 generated /
zero queued states). Receipt: `.data/heap-allocation-headroom-001/receipt.json`.
Source binding checks both initialization and post-GC floor addition and
retention of the existing max-heap clamp. The finite model does NOT prove
max-heap admission, allocation failure or every large-live-heap layout.

Candidate 007 changes only mem.c over 006, preserving earlier binaries in
`.data/gc-retained-006/`. GNU GCC `make -j12 core` exits 0. Its actual p4 decoder
fixture (text/binary, eq?/eqv?/equal?, mutation, five forced GCs after decode)
passes in 1.539 s. The subsequent gsc compilation fails with SIGBUS (exit -10)
at 4.846 s; compiled execution is not run. Full receipt:
`.data/gc-native-decode-p4-007/receipt.json`. Overall status remains DENIED;
this isolated interpreted pass does not close PR1038 or bootstrap correctness.
No formal patch or release is promoted.

The modular `debug_capture.py` requires exact successful capture markers,
source-symbol mailbox observations and distinct stop IDs, rejects traceback
and incomplete captures, and kills its inferior. Private gsc debug symbols
for 007 are built in `.data/gc-compiler-debug-007/`, without changing candidate
ABI or binaries; compiler crash capture remains pending.

## PR988 Ownership Obligations

Exact head `be71ec38aaff06d4c310f5b23d916e3a31e31ca7` was queried on
2026-10-10: closed, unmerged, retracted body, zero check runs and zero legacy
statuses. Focused historical success reports are not full-green CI evidence.
PR988 overlaps already modeled root-scan, hash-policy and stack-marker fixes;
those are not counted as independent new repairs.

`rehash_lock_ownership.qnt` adds two separate frozen counterexamples:
source/destination stripe alias with nested non-reentrant locks, and a
conditional completed writer lost across copying/publication when source
exclusivity is absent. The latter is NOT a reproduced upstream native defect.
The protocol with source ownership through private destination publication
passes: 23 distinct states, 27 generated, zero queued, 12.958 s. Receipt:
`.data/pr988-rehash-ownership-002/receipt.json`. Initial 001 is a Quint shared
initializer conversion error, DENIED and superseded, not a source counterexample.

The exact-head Scheme source's `##table-resize!` publishes before copying;
it does not implement this private-until-publish model. Consequently that
path is still a distinct proof obligation, and removing an outer source lock
is not approved solely from this model. No broad PR988 patch is applied.
Eighteen framework tests pass, including independent frozen alias/ownership
controls and headroom source guards. Native compiler SIGBUS and full bootstrap
remain blockers; the goal is not complete.

## Source Candidate 019 And Test Protocol

Preserve the useful PR988/1038 repairs rather than replacing collector design.
The new typed GC-table traversal snapshot candidate passes an isolated actual
GNU GCC core rebuild (28.642 s). Twelve related original/regression files pass
interpreter mode (5.435 s) and compiled mode (105.352 s), without runtime shims.
This is not two-pass bootstrap or full-suite admission.

The thread fixture protocol model freezes recipient-lifetime and premature
assertion failures. Mutex completion gate plus join exhausts 23 distinct states,
36 generated, zero queued. The corresponding assertion-preserving fixture
passes interpreter (4.165 s) and compile/execute (19.344 s) modes under their
20-second budgets. This is test synchronization, not a runtime correctness proof.

The original prim-port file separately times out at 20.014 s on candidate 019.
Its failure is retained without GC/deadlock attribution. Current Datalog has
That checkpoint had 33 models, 12 native observations and ten local failures;
coverage holes were reported, not silently admitted.

## Residual Repair Checkpoint

The inventory now has 36 models, 20 indexed native observations and 16 retained
local failures. Framework validation passes 106 tests. The complete upstream
interpreted suite passes 375/375 files in 177.070 seconds with the explicit
thread completion fixture patch. Complete compiled-suite admission remains open.

The new `checked_negate_return` model records a real compiled fxmul failure,
not an assumed PR988 defect. Its one-line header repair completes a GNU GCC
core rebuild and passes the original fxmul test in interpreter (0.070 s) and
compiled (10.368 s) modes. See `docs/checked-negate-return.md` for proof bounds.

The generic child-population fixture also passes both upstream-runner modes
on runtime020 (0.144 s / 2.194 s): the test child checks its actual processor
count against the host-auto selected population, 12 on this run. This checks
population inheritance, not a global bound on all compiler/runner threads.
None of these results admits complete bootstrap, Linux or Gerbil acceptance.

PR1047's ended-target propagation lock is now source-audited and modeled.
The old branch has a frozen counterexample; the fixed protocol exhausts 13
distinct / 16 generated states with zero queued. The native regression is
byte-exact to its cached upstream blob. Original runtime020 fails both trylock
assertions; the real GNU GCC runtime021 rebuild and both interpreted/compiled
regression modes pass. Full bootstrap/toolchain admission remains open.
See `docs/ended-interrupt-lock.md`.

The balanced compiled campaign still fails the original 300-second whole-mode
budget (300.316 s): shard progress is 42/125, 42/125 and 31/125, with no assertion
failure observed in the completed prefixes. This is a DENY, not 375-file
coverage or evidence that all reports are repaired. Do not rerun it unchanged
or enlarge its budget to obtain a green marker.

Runtime021's six neighboring thread tests pass interpretation but fail compiled
`thread_start.scm` with `var=0`, not a timeout. The source fixture uses relative
busy-work counts instead of completion. `thread_start_completion.qnt` freezes
that schedule and exhausts the explicit-join protocol; the test-only patch
adds one join, deletes nothing and preserves every assertion. The same six-file
campaign now passes both modes (20.856 s interpreter / 67.780 s compiled) within
the unchanged 120-second per-mode budget. This does not admit the complete
compiled suite or bootstrap. See `docs/thread-start-completion.md`.

The original numeric fixture phase probe is diagnostic DENY at 90.384 seconds:
Scheme-to-C takes 30.818 seconds, then C compilation exhausts the remaining
budget. No compiled execution or complete-suite coverage is claimed. New
driver-bound fxmul calibration passes both modes without object reuse, and
binds the generated driver plus helper hashes. See `docs/compiler-cost-boundaries.md`.

Candidate 019 two-pass bootstrap is DENY at its original 600-second budget
(600.039 s). It reaches second-core GNU GCC compilation, reports no recursive
build error, and preserves handwritten source identity. No final artifact set
is admitted. This is an incomplete build, not a diagnosed collector crash.
