# Current checkpoint native qualification audit

This is an observed, manually reviewed execution chain. It does not convert the
retained legacy suite preflight DENY into a pass or claim release admission.
No Gambit bootstrap was repeated.

## Frozen trace repair

Five unchanged frozen counterexamples now bind to verified predecessor model
snapshots in `evidence/frozen-trace-history.json`: three FFI frame traces and two
GC table iteration traces. The FFI predecessor SHA is
`f0a453a1ad8e46a2f557169e09ce1732fa4fb319fbcba28396bd121269186bfa`;
the GC table predecessor SHA is
`9c5a8c76cd136f9cfb49a6e065d874a31f568778efdaef8474cc45e05156d802`.
Both predecessor models were recovered from Git HEAD and independently hashed.
All five trace files are byte-identical to Git HEAD. Current model extensions
were preserved. Old traces contribute `historical_frozen_negative`, never a
current negative-control credit. Removing the new FFI historical binding makes
the actual index reject `ffi_gc_frame_protocol-reloadSafe.json` again.
The original stale-index failure remains retained.

## Actual source successor

The observed-retirement checkpoint is unchanged. Its first complete original
GSI campaign ran 374 files: 373 passed, and `mutex_unlock_plain.scm` failed
because the new no-waiter helper returned its mutex instead of `(void)`.
Grok authored `patches/candidates/mutex-unlock-void.patch`. Its two terminating
branches now explicitly return `##void` after releasing their locks. The
original failed Grok write, original malformed diff hunk, and auditor supervisor
exit-code mistake are retained; only hunk counts were normalized.

An APFS clone reused the checkpoint. The existing compiler regenerated only
`lib/_thread.c`; only `_thread.o`, the archive and GSI/GSC links were rebuilt.
This took 16.614 seconds. Exactly `_thread.scm` and `_thread.c` changed in the
source identity. The identical failing original fixture then passed. The new
source lock is `runtime-mutex-return-source.lock.json`; its cumulative patch
reapplies with zero fuzz to all 26 pinned source files and reproduces every
candidate digest. Generated-C and artifact identities are recorded separately
in the incremental receipt. This is not a new two-pass bootstrap claim.

## Completed native executions

Portable evidence lives in `evidence/source-results/current-checkpoint-qualification/`.

| Execution | Actual result | Evidence boundary |
| --- | --- | --- |
| Original GSI before return repair | 373/374, DENY, 20.201s | Original failing assertion retained |
| Original GSI after repair | 374/374, COVERAGE-PASS, 19.074s | Same original file inventory; no full-mode timing claim |
| Original GSC after repair | All 374 launched, 373 passed, DENY, 1797.7s | `_num.scm` exceeded its unchanged 90s file cap |
| Official GC/FFI Make test7/test8/test9 | PASS, 9.728s | Memory/C interface, Scheme server and dynamic loading; not whole SMP collector qualification |
| Current lifecycle fixture regressions | PASS, 10.741s | Root SIGINT; same-storage constructor retry; external producers; actual runtime normal/pending/sticky joins; observed terminal drain |
| Gerbil 1cfb032c7a1612637da6205f5f8a15683eba3ba0 | stage0/stage1 PASS; stdlib exit139 | Later libgerbil/lang/tools/test did not execute |

The original inventory has 374 files; historical 380-file campaigns also added
six PR fixtures. Do not label 374 as 380 or claim those supplemental files were
part of this campaign. GSI/GSC observations use the original runner through GSI,
with parent p1 and child p2, retain per-file markers, logs, exit/timeout and
process quiescence. Test sources, included helpers, runner, native sources and
binary/archive identities are checked. Output directories are immutable;
failed campaigns are not resumed or overwritten. The accepted source checkpoint
is reused rather than rebuilding Gambit.

The old CLI's preflight rejected historic summary/environment records and the
aggregate/file budget mismatch before executing a unit test. It remains DENY.
The independent complete-file observer is explicitly source/environment reviewed
and confers no sealed runtime or release admission. A fresh exact-producer
control observed UDP, process-pipe sorting and user lookup successfully.

## Numerical compiler failure

The unchanged original numerical file also hit 90s with no competing C compiler
at launch. Scheme-to-C alone completed in 23.371s and produced 5,541,691 bytes;
a later original-command run produced C about 14.909s after launch, without a
module before its deadline. A passive sample of this task's GCC descendant at
about eight seconds was inside the C parser. This observation does not identify
the complete 60/90-second cost distribution.

Separate 60s command controls disabling late scheduling or setting the existing
single-host label fallback to 4096 both timed out. The source has 8008 labels,
including one procedure with 7613 labels. No compiler repair or performance
improvement is admitted. The original GSC aggregate stays DENY; no limit was
raised and no test expectation was changed.

## Gerbil failure and controls

Gerbil was cloned with its dirty source inputs preserved and hashed. Existing
current GSI/GSC/headers/static archives were installed into its isolated build
prefix; the Gambit build target was skipped. Actual Gerbil stages: prepare,
boot-gxi, stage0 (424.709s), stage1 (419.473s), then stdlib SIGSEGV (61.175s).
The process group was quiescent after failure.

The macOS crash report and disassembly place the fault in `##wr-structure`,
`_io.c:86248`, reading TYPEID after STRUCTURETYPE, called by `##wr-pair` at
`_io.c:82020`. A diagnostic `_io.o` built with `-g` has exactly the same 1,009,692
text bytes and SHA as the installed original, so the source mapping is checked.
A bad type-field word was dereferenced; heap corruption, malformed internal
structure, and a secondary error-printing fault remain distinct hypotheses.
No guard hiding the invalid object was installed.

A built-core port/forced-GC probe passed. VM count was measured separately from
build jobs. A cold stdlib VM1/jobs6 script-mode control progressed farther but
hit its 120s diagnostic cap. A failed interactive probe of the cold prefix is
retained separately: `-e` needs the not-yet-built `std/interactive`. The same
original core's p1 startup probe passed. These controls are not SMP acceptance.

Grok authored a message-only existing-exception-hook driver. The auditor corrected
its hook arity and absolute include, and disabled the existing stack-printing
parameter in that diagnostic only. A cold VM6/jobs6 run still died at the same
`##wr-structure` offset, this time SIGBUS after 90.781s, without a first-exception
message. Both crash reports are retained. No supported source fix is established.

## Remaining four gates

| Gate | Concrete advancement | Still required |
| --- | --- | --- |
| Lifecycle failure/rollback | Same-storage retry and actual runtime pending/sticky/drain requalified on the final successor; conditional recovery/cross-generation model and Scheme revocation tests executed | Real still-joinable error followed by runtime-owned successful recovery; old unadmitted OS-handler quiescence before reopening; remaining fault inventory |
| Complete GC/FFI | Original GSI complete, 373 compiled files passed, official GC/FFI targets passed, generation counterexample published | Numerical compiled case within its contract; complete current producer GC/FFI and stress/PR obligations |
| Gerbil correctness | Current native products consumed; actual stage0/stage1 built; real stdlib crash localized and distinct controls executed | Source-causal crash repair, stdlib/libgerbil/lang/tools completion and actual complete tests |
| Release performance | Detailed correctness work and compiler samples retained | Matched accepted full producer latency/build/test campaigns; no speed or release claim follows from these observations |

The historical aggregate count remains 8/12 because the four gate contracts have
not been fully satisfied. This audit records execution and repair beyond the old
checkpoint; it does not increment that count on models or partial native passes.

## 2026-10-20 model-first follow-through (native gates still open)

Grok authored independent object/type root, epoch and refresh controls in
`structure_type_lifetime.qnt`. Twelve directed tests pass. TLC exhausts the
`initRooted`/`safeStep` positive protocol: 20 distinct states, queue empty.
This is a finite protocol check, not a native GC theorem. Source mapping now
accounts for field-zero tail marking during copy and the later scan that skips
that already-handled field. A separate explicit type root is not a universal
native requirement. Actual crash producer identity remains unknown.

The real Scheme engine checks conditional support and revocation for every
model/map/proof binding; old identities and DENY outcomes cannot authenticate
current support. Native cause/fix remain unclosed. The first copied contract
count (five instead of three bindings) failed and is retained, as are prior
model errors. New view registration adds no native admission.

The final unchanged source checkpoint compiled and executed Grok's dynamic-type
probe with six processors, six completed workers, 120 explicit `##gc` calls,
field checks and pair printing, natural exit zero. The probe does not observe
movement or reproduce Gerbil. The first fixture failure was an auditor's
incorrect `gensym` prefix change; its original type exception is retained.

For the exact retained numerical C, preprocessing took 3.646s and syntax-only
compilation 24.812s (including preprocessing/frontend work). Own-descendant
samples at 35/50s in the default full C compile show pointer-analysis constraint
solving and 2.6/4.5GB footprints. Grok's isolated global-cell noinline header
control still timed out at 60s with no artifact. Disabling PTA diagnostically
also timed out; its follow-up samples need a separate phase interpretation.
No control changed the original 90s numerical acceptance cap. No compiler fix
or speed claim is admitted from these observations.

Two stdlib LLDB captures timed out at the unchanged 120s diagnostic cap without
an object scene. Grok's separate exact-core VM6 startup smoke passed in 3.63s,
so debugger startup itself is demonstrated. Grok now owns fresh scene collection
and raw-scene analysis in an isolated directory; the auditor reviews submitted
reports and changes. No invalid object was manufactured and no printer guard
was installed as a repair. The two recorded processes from the second capture
were independently confirmed absent after cleanup.

A real OS two-thread join cycle followed by exclusive ownership handoff passed
with system Clang: owner A observed EDEADLK, worker W joined A, then B joined W.
This is platform feasibility only. The original GCC direct-link failure remains
retained. No runtime worker recovery is admitted; child-VM startup, foreign-frame
exit and ownership-transfer contracts still need a real runtime witness. Root
sticky failure is a different contract and does not become retryable.

Portable receipts, raw failures, samples and the exact preprocessed numerical C
are retained in `evidence/source-results/model-first-followthrough/`. The accepted
checkpoint was not modified and no Gambit bootstrap was repeated. Full original
GSI/GSC and Gerbil build/test remain required after a source-causal repair.
All four remaining gate contracts stay OPEN; the aggregate remains 8/12.

## 2026-10-20 Grok-led scene audit and external execution blockers

Grok's public report is retained under
`evidence/source-results/model-first-followthrough/grok-scene-audit-02/`.
The auditor reviewed collector source, hash metadata, public reports and source
installation provenance; no fresh raw object/header scene was opened by the
auditor. The first Grok collector did reach the original native fault, but its
stop hook raised an unsupported `SBFrame.GetFunctionOffset` call before reading
memory. Subsequent attempts reused generated stdlib state and cannot serve as
matched cold controls. A resolved breakpoint with zero hits and SIGSTOP command
configuration are not an observed invalid object.

A concrete diagnostic source mismatch is now identified. Installed Gerbil native
assets were copied from the accepted checkpoint. Its generated `lib/_io.c` has
SHA-256 `1207494ff79eb810d314d1be81a66776a189ccad5e577411af28a81d6c8f3459`
and line 86248 reads TYPEID. The Gerbil source clone's unbuilt
`src/gambit/lib/_io.c` instead has SHA-256
`cb30268f0444af3c61bedde903edaa6505407eb144cad0d780a9137d1019c0f4`;
its same line number is a stack store in another procedure. The failed Grok trap
compile used this second source. It exited 1; object existence is not acceptance.
The previous exact-text debug-object correspondence remains the valid consumer
mapping, and neither mapping identifies the producer of the bad type field.

All seven historical Grok log text digests were reconciled without editing their
receipt fields. They use newline-normalized UTF-8; separate raw byte hashes are
retained. The second attempt's old receipt references the first attempt's path;
its retained `lldb-r2.log` matches the original text digest. This is an explicit
path/encoding annotation, not a changed hash or promoted result.

The GSC census transcription is corrected from 6614 combined declaration and
assignment matches to 3307 declarations. The old document is retained. Default,
noinline and no-PTA timeouts remain failures. Grok's no-PTA analysis identifies a
shift into dominator copy propagation and combine; this does not establish a
complete source-causal repair.

A fresh Gerbil cold-checkpoint collection was assigned to Grok with corrected
source provenance, immutable output, unchanged VM6/jobs6 and 120 s bounds. Before
it executed, the external service returned HTTP 402: Grok Build usage balance
exhausted. The public service error is retained. A separate bounded runtime
pending-join source investigation was refused by automatic approval review; a
scope-specific authorization question is pending. Neither barrier was bypassed.
The accepted native checkpoint was independently rechecked unchanged.

| Open gate | Actual advancement in this follow-through | Still missing |
| --- | --- | --- |
| Lifecycle failure/rollback | Existing real pending/sticky/drain controls retained; recoverable error mechanism and handler-quiescence premises remain explicit | Supported real runtime-owned error-to-success recovery and old unadmitted OS-handler quiescence; Grok runtime-source dispatch awaiting approval |
| Complete GC/FFI | Independent object/type root/refresh model, Scheme evidence positive/negative/revocation controls and source-map audit retained; numeric post-parse phase discrimination sharpened | Source-causal numeric repair and complete original native acceptance; no new full run after an unestablished repair |
| Gerbil correctness | Actual fault-stop collector failure, cold-state drift and wrong generated-C source diagnosed; failures and exact log bindings retained | Genuine header/type scene, producer identity, source repair, complete stdlib/libgerbil/lang/tools build and tests |
| Release performance | No unsupported performance or release claim added | Matched complete accepted producer campaigns after correctness closure |

All four gate contracts remain open. No bootstrap, relaxed acceptance timeout,
reduced acceptance concurrency, wrapper self-join substitute or production
printer guard was introduced. There is no new full native/Gerbil pass to report.

## 2026-10-20 executed numeric structural controls

Grok executed 19 owned C mechanism compiles under the existing GCC flag family,
with time-report/CFG instrumentation and bounded process groups. All compile
exits were zero and objects were produced. These are synthetic compiler controls,
not Gambit native correctness tests or full numerical acceptance. The predictions
were independently frozen before execution and still match the decision digest.
N=48 per-site CFG has 242 edges, below the pre-registered dense threshold of 480;
the tested clique hypothesis is not supported. The 1024-store diagnostic probe
compiled in 7.108 s, while the 3307-store probe compiled in 2.586 s. The latter is
a real-size standalone negative result, not evidence of monotone growth.

The auditor found that the original time parser expected three columns whereas
GCC16 emitted wall/GGC columns. All 19 full logs and source bytes were verified
and reparsed without recompilation or changes to the original receipts. The
1024-store diagnostic reports tree PTA 0.01 s, dominator 3.34 s and IPA summary
3.24 s; the 3307-store probe reports tree PTA 0.08 s, dominator 0.33 s and IPA
summary 0.17 s. Thus these isolated controls do not reproduce the original
PTA-bound whole-file wall. Missing timer rows are unknown, not zero. Lexical
global-table bracket counts include an array declaration, so 173 bracket values
must not be called 173 runtime globals; the module declares 172.

The auditor retained 93 source/log/dump/audit artifacts in
`evidence/source-results/model-first-followthrough/grok-numeric-audit-02/`.
The independent parser also records corrected indented CFG block counts and a
fail-open process-observer limitation in the Grok harness. No native quiescence
claim is admitted by that reparse. Full original CFG/SSA and contextual alias
interactions remain the next discrimination target. No source repair, timeout
relaxation, compiler-flag workaround or new native pass follows from these probes.

## 2026-10-20 actual graph, cold failure, and collector audit

The retained original numerical host CFG has 105311 blocks, 161691 edges,
and one dispatcher with maximum fanout 7975. The corrected GIMPLE parser
finds one expression-target goto; 30461 occurrences of `goto predictor` were
comments, not indirect branches. Register/heap/frame PHIs reach lexical arity
15539. These are real CFG/SSA facts, not extracted PTA constraints. The dump
controller failed during cancellation; compiler completion is unknown. No
repair follows from the old dense-per-site clique prediction, which the small
compiled controls did not support. Both parser mistakes and corrected reports
remain retained in `real-graph-cold-r8-03/`.

Grok's fresh cold r8 stdlib capture retained matching core/archive/header
identities and VM6/jobs6, but reached its 120s diagnostic cap with no object
scene. It is FAULT-STATE-ABSENT, not a successful crash capture. It was not
repeated. A redesigned small attach control subsequently proved a stopped
SBProcess on the pinned Gerbil image with exact PID/image and natural child
exit after detach. That capability is distinct from obtaining bad object
header/type words. The freeze collector still requires an actual qualified
diagnostic image, reliable publication/freeze semantics and a retained relink
recipe before another stdlib execution. The auditor reads collector sources
and structured reports; raw LLDB memory/register scenes remain Grok-owned.

The first alias-kind model execution failed: the canonical counterexample
confused merged-class storage with total-universe storage. Its proposed oracle
reused candidate union/projection logic and was returned for independent
reachability/set-closure controls. Two actual small dump-probe campaigns kept
the original numerical compile unstarted: first an unsupported `-dumpdir=`
spelling, then a functionless probe that triggers no function alias pass.
Compile exit zero was not accepted as dump/phase evidence. Original source,
flags, failed scripts and results remain preserved.

A Grok-authored public-embedding handler fixture compiled, then failed with
SIGSEGV before its first setup marker. Its manually assembled kernel-only
linker is unqualified against the retained generated complete library linker.
This is a failed prerequisite control, not a native handler counterexample.
Grok is correcting the embedding and thread-communication premises before
collecting an actual pre-admission OS handler trajectory.

`collector-and-alias-review-04/` binds the small collector capability, model
failure and dump-probe DENYs. No new source-causal runtime/compiler repair,
complete native admission or release-performance claim is made. The accepted
checkpoint is reused, no Gambit bootstrap was repeated, and all four aggregate
gates remain open.
