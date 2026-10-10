# Initial Model Validation

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

Next source-backed lifecycle obligation: in the pinned source's
`___vm_resize_pstate`, the failed-setup cleanup loop decrements `i` but repeatedly
uses the failed processor's `ps`, and does not reset the target count. This is
a source audit finding, not yet a frozen model counterexample or native fault
injection result. No runtime change is promoted from it yet.

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
