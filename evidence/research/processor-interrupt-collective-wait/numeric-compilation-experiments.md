# Current numerical compiler investigation

This dossier belongs to the current 9–12 repair. `dev/` supplies reusable
modeling vocabulary; it does not own this case, its progress or its results.
The concrete declaration is [numeric-compilation-investigation.sysml](numeric-compilation-investigation.sysml).
The original numerical workload and the other worker's checkpoint are unchanged.

## Discrimination 1: absent compiler pass or invalid probe?

The [retained feedback](../../source-results/model-first-followthrough/collector-and-alias-review-04/alias-diagnostic-feedback.json)
records a failed prerequisite: the old probe had global initializers and no
functions. Its successful compile produced no function alias dump. Those original
failures remain evidence; no historical result is relabeled.

The new authored fixture is
[`models/gambit/native/numeric-alias/probe.c`](../../../models/gambit/native/numeric-alias/probe.c).
It supplies a visible, non-inlined function that selects a pointer, stores
through it and reads the global values. Defining `FUNCTIONLESS` removes just the
function. The selected GNU GCC and base flags come from the retained small
Grok compiler command; source and compiler hashes are recorded before execution.
The dump flags use the accepted separate `-dumpdir` argument. Every compile has
a ten-second bound. This is a small prerequisite experiment, not a replay of
the original numerical compile or a matched performance campaign.

| Controlled input | Actual exit | Alias/ealias dumps | Interpretation |
|---|---:|---:|---|
| Functionless, O1 | 0 | 0 | Compile success cannot show that a function pass ran. |
| Observable function, O0 | 0 | 0 | Phase scheduling matters; no dump is compatible with a successful compiler. |
| Same observable function, O1 | 0 | 2 | Both requested passes emitted the named function and real constraint sections. |

The three observed supervisor wall times were 0.856, 0.497 and 0.796 seconds.
They include framework/launch overhead and are **not** compiler-only CPU timings,
a speedup, or evidence that the original numerical workload is now fast.
Both O1 dumps contain actual `Constraints:` sections with `scalar_slots`,
`chosen_6`, stores and global loads. These are real compiler outputs, not
constraints inferred from CFG edge counts or PHI lexical arity.

This distinguishes compiler capability from a functionless or inactive-pass
probe. It does not distinguish the remaining whole-file hypotheses: contextual
alias expansion, dispatcher/SSA representation, and resource/observer effects.
The small function is deliberately not claimed to preserve the original
numerical program's semantics or reproduce its compiler cost.

## Actual implementation and model correspondence

`compiler_cost.alias_pass_discrimination` uses the existing task/process adapter,
workspace lease, source delta and checkpoint operations. It has no additional
public launcher. It fixes the prerequisite fixture and uses
`compiler_phase_primitives.alias_passes_exercised` to require **each requested
pass's own** dump with the named function and constraint section. A dump of a
different pass, a warning, a missing function or a successful object alone
cannot satisfy that check.

The current [`native_compiler_probe_correspondence.qnt`](../../../models/gambit/native_compiler_probe_correspondence.qnt)
supplies `passExercised`. The final audit generated an observation projection
that imports this exact source and checks all three real results. The function
witness maps to the model's nonzero function count; it is not a whole-program
function census. Seven QNT tests passed, including existing requested-pass and
cost-unit negative controls.

[`NumericCompilerExperiment.lean`](../../../models/gambit/lean/NumericCompilerExperiment.lean)
proves the no-function rejection, missing-requested-pass rejection and existence
of a successful compile that did not exercise the requested pass. The real
compiler exits/dumps remain host observations; Lean does not authenticate them
or prove a compiler/source repair. The earlier generic ResearchFunnel
non-promotion rule still applies.

## Custody, reuse and retained failures

The first execution's plan and original results:
`.cache/tasks/repair-9-12/processes/audit/runs/3f9ace938c804aa29ee124268c93f059/outputs/current-numeric-alias-discrimination/receipt.json`.

The stable incremental workspace is:
`.cache/tasks/repair-9-12/processes/audit/build/gambit-core/fddb83dda5d3a6796814b3a4039e03e056922d9cf4cf9dc4326114b8f30d3f12`.
This is the audit owner's existing registered product namespace; no new task,
Gambit source clone or native bootstrap was created. Rechecks authenticate its
source, compiler, historical command and all object/log/dump bytes, then reuse
the same three complete observations. A reused result is labeled `reused` and
does not count as a fresh timing.

The initial experiment used an invalid descriptive checkpoint phase. The next
sync correctly rejected it. After verifying the original run had returned,
actual child quiescence, exact source inputs and every artifact, the existing
`checkpoint_build_source` API restored its recognized `ready` phase. The
descriptive outcome is separate metadata. That recovery is retained in audit
run `e7ee880e702846bfb21ab19b6cf4511e`; no status or hash was hand-edited.
The first QNT projection also rejected an unsupported absolute module import;
that failure is retained in audit run `b5245e8a2cd8452ab022b42baf108669`.
The corrected projection uses the real repository source through a relative
import; no duplicate QNT source was copied into Evidence.

Final stable receipt, original logs, verified reuse and model/prover checks:
`.cache/tasks/repair-9-12/processes/audit/runs/5ae744f8573540b18b70d295578ebba9/outputs/current-numeric-discrimination-recheck/receipt.json`.
All four checks passed: actual-observation QNT tests, Lean compilation, strict
current SysML validation, and separation-aware development view derivation.
Five compiler adapter tests passed. The bound source identities stayed stable.

No original numerical compile was started, no original budget changed, no
production runtime/compiler-source repair was claimed, and no other 9–12 process
was stopped, sampled or debugged. Full GC/FFI, Gerbil and release gates remain
separate. The qualified dump path can support a future owner-selected experiment
on the original retained source; the present result does not authorize its
unchanged failed replay.

## Discrimination 2: the full original CFG/SSA, rather than another small probe

Audit `68927371a0074e1c948307a5ad04c257` executed
`compiler_cost.retained_numeric_analysis` through the existing `repair-9-12`
audit process. Its receipt is
`.cache/tasks/repair-9-12/processes/audit/runs/68927371a0074e1c948307a5ad04c257/outputs/current-numeric-original-discrimination/receipt.json`.
The three qualified alias controls were authenticated and reused in the same
incremental workspace; there was no new GCC invocation. This analysis consumes
the **full original** retained CFG (32,077,992 bytes, SHA256
`cef7105de2f7825ce1f33270bb2015e5920c3c488bc9f4e8bdb0356ef2276733`)
and SSA (46,929,840 bytes, SHA256
`167b9bf14f47ce77479672067830b75c9c1511b8816a96bef9cf55806d7dd8f1`)
under `evidence/source-results/model-first-followthrough/real-graph-cold-r8-03/numeric/retained-full-graph/`.
It is not a scaled synthetic fixture or a measurement of compilation time.

The six function identities agree. The host `___H___test` has 105,311 CFG body
blocks, 161,691 edges and maximum fanout 7,975. All 16,639 SSA PHIs were parsed;
their 223,240 operand occurrences use 51,927 distinct `(predecessor, target)`
edges. Every such edge occurs in the earlier CFG. The two largest joins have
identical predecessor support across all eight PHIs, checked as sets rather
than inferred from equal cardinalities:

| Original SSA block | Actual construct | Shared incoming edges | PHIs | Operand occurrences |
|---|---|---:|---:|---:|
| 105311 | `___jumpext`, processor-state writeback and required external tail call | 15,539 | 8 | 124,312 |
| 6 | Expression-target computed goto | 7,371 | 8 | 58,968 |

Together these joins hold 183,280 / 223,240 operands (82.10%). The former
merges `pc`, `hp`, `fp` and `r0`–`r4`; the latter merges `hp`, `fp`, `r0`–`r4`
and `gotovar`. This is actual SSA representation concentration. It neither
establishes a dense per-site CFG clique nor measures points-to sets, bitmap
universe size, solver work, or CPU time.

The source correspondence is concrete: SSA lines 450692–450701 contain the
dispatcher PHIs and indirect goto; lines 1498760–1498788 contain the external
join, register writeback and `[must tail call]`. The retained header
`.cache/current-mutex-return-incremental-02/candidate-runtime/include/gambit.h`
still hashes to `bb224f027872315cac11d516cdca45b28446bdc626013a366f4839c1e7a8a41b`.
Its `___END_COD` (line 6846) emits `ps->pc`, `___W_ALL`, and `___EXIT_HOST`;
its jump macros (lines 6945–6983) select the internal/external jump route.
The single/multiple-host choice and limit are explicit at lines 1231–1253.
These are candidate configuration/source boundaries for experiments, not
permission to delete writeback, roots, or the external tail-call protocol.

The production analysis code now handles abnormal SSA names such as
`___hp_417376(ab)`, checks complete PHI operand syntax, rejects duplicate
predecessors, separates successor metadata by function, and verifies common
predecessor support before applying multiplication. The previous retained
report's `other:16638` classification hid the actual register families. Its
30,462 "indirect gotos" included 30,461 `// goto predictor` comments; this
analysis finds one expression-target indirect goto in the SSA. Also, that old
report's statement that 21.936 is below 10 is arithmetically false. The old
report remains unchanged; neither that comparison nor the separate N=48
synthetic threshold justifies a full-program density or PTA claim.

### Configuration evidence already available; do not repeat it

The historical `.cache/current-numeric-no-pta-postparse-01/receipt.json` records
`-fno-tree-pta` on the original numeric path: exit -9, timeout true,
60.032706834 seconds, no module, parent reaped and process group quiescent.
The retained `cc1-35.sample` line 36 is in `pass_dominator::execute`, with
range propagation below it. `cc1-50.sample` line 36 is in
`pass_combine::execute`; later branches also show register initialization.
The actual sample elapsed times are 36.296 and 51.412 seconds. These are
historical stack observations, not new samples, inclusive CPU totals or a
matched speedup estimate. They establish that the no-PTA route reached
non-alias optimization/RTL work and still missed its budget. Thus "the whole
stall is alias" and "disable PTA repairs the gate" are unsupported. They do
not exclude substantial alias cost in the original PTA-enabled configuration.

### Executable correspondence and next discriminating inputs

The current QNT `sharedJoinOperandUnits` and Lean
`sharedJoinOperandUnits`/`eightLiveValuesRepeatEdges` model representation
multiplicity only after identical support is established. This audit generated
a relative-import QNT projection from the two **actual** join rows and a Lean
projection importing the compiled current model. Both checked `8*15539=124312`
and `8*7371=58968`; eight QNT tests, five Lean statements, two observed-row
Lean examples, strict current-case SysML validation and six Python tests passed.
No `sorryAx` occurs. Source hashes stayed stable; dirty analysis/model bytes
were retained through existing task checkpoints, without Evidence source or
patch copies. The tests include abnormal annotations, comment rejection,
different support with missing CFG edges, function boundaries and malformed
PHIs. An earlier census-only audit `45aeb5d852a34d8484bf448b6d7aa976` is retained
separately and is not a compiler result.

The original generated test C is currently missing at
`.cache/current-numeric-isolated-original-control-03/runtime/tests/unit-tests/03-number/_num.c`.
Its retained identity is 5,541,691 bytes, SHA256
`35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158`.
A targeted lookup of that SHA's source-identity checkpoints under this task's
run/role stores found none. The two registered build products' `lib/_num.c`
are 4,266,056-byte library modules with a different SHA; substituting one would
invalidate the experiment. The original graph-producing compiler exit remains
**unknown** after its historical cancellation failure, as its unchanged status
records. Closed dumps and this successful parser run do not reconstruct it.

The next original-source experiments have distinct, falsifiable predictions:

1. Restore/authenticate that exact C through an existing source checkpoint or
   its original producer identity, and bind the retained header, compiler and
   command. Use the already-qualified separate `-dumpdir` syntax and actual
   named-function alias/ealias details. Extract real variable/constraint and
   points-to membership counts, keeping them separate from the PHI census. If
   the dump never reaches a constraint/solution section within the existing
   bound, retain that outcome as unknown, not zero expansion or a pass.
2. On the same authenticated C/header/compiler in the existing leased
   incremental product, replace only `-D___SINGLE_HOST` with
   `-D___MULTIPLE_HOSTS` in the configuration. Collect the same CFG/SSA and
   requested-pass observations. The representation hypothesis predicts smaller
   per-function shared joins and more host functions; alias-only attribution
   requires independently measured points-to changes. Total work or speed need
   not improve. This is an input-changing experiment, not a renamed replay.
3. A candidate that reduces compile representation must still preserve
   processor-state writeback, GC roots, cross-host control and actual numeric
   execution. Complete native/Gerbil acceptance is a subsequent independent
   gate. Neither the model arithmetic nor a cheaper configuration admits it.

These experiments are specified but **not executed on substitute source**.
The old no-PTA timeout was not repeated, no timeout was enlarged, and the other
worker's 9–12 execution/checkpoint was not acquired, signaled, sampled or changed.

## Original C recovered; bounded full-input controls (2026-10-21)

The missing-source prerequisite above is now resolved. The retired-record
index preserves the original test receipt at
`.state/storage/retired-records/a2e7343834a951c5481cafd4faeb998515300f9f71d8cb5b4b241f0db109721c.json`.
Its Scheme fixture SHA
`b757a18805a38f48e55055907a983d53f0e50d1acb627c462fe6d34924bd0d9d`
matches the retained producer's `tests/unit-tests/03-number/_num.scm`.
The cleanup inventory confirms that the old generated C was deleted; the
targeted original-SHA checkpoint search initially found no source record.
The retained `gsc/gsc` hashes to
`80e933283df4e3dcf811c7b94e741772909d1fd35f0aa9386105b5e71309c828`,
matching the retained runtime's current identity. That identity is recorded;
the old candidate receipt hash is not silently replaced by its newer successor.

The existing compiler-cost adapter rebuilt only Scheme-to-C with original
`(module-ref _test)` and `(linker-name "_test.o1")`, the same relative fixture
path and its two `#.scm` includes. No Gambit bootstrap, package installation,
library-module substitution or production source-tree copy was performed.
The new original-input experiment uses one stable registered audit product:

`.cache/tasks/repair-9-12/processes/audit/build/gambit-core/923af547b5e2526673b48db269fec79a3350697b5e634e15ad5244123a9df520`.

Its `source/tests/unit-tests/03-number/_num.c` is exactly **5,541,691 bytes**,
SHA256 **`35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158`**.
This is the original numeric test C, not either `lib/_num.c`. It is retained
through the existing source checkpoint at
`.cache/tasks/repair-9-12/processes/audit/runs/0624078d62b543749acd9a13b61ae093/outputs/source-identities/35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158`
with prefix identity
`3ca3631c7d7db1ebf0ce0fd9811924fba3dc47e281fdf438935a7a1a494e4a32`.
Subsequent checks decode and authenticate these exact bytes and reuse the
leased workspace. A missing generated file can be rehydrated from that source
checkpoint; an existing file with different bytes is rejected rather than
overwritten. No source or patch copy was added under Evidence.

### A real reconstruction failure exposed file-I/O configuration cost

Audit `b0a107538a574a55a66c2d3174ca4b18` first ran the original unbuffered port
settings with a 60-second cap. It timed out at 60.083 seconds, leaving a
2,123,896-byte partial C (SHA `609daf635a3e629da541177e93ca884b0771b8cd345c6ba241f8c21e7fecdbdf`).
The process was reaped and its group absent. The incomplete source was retained
in the existing task checkpoint before its workspace replacement; neither
the failure nor its SHA was rewritten.

The retained Gambit manual (`doc/gambit.txi`, lines 2329–2390) specifies that
`io-settings=lu` applies LF and **unbuffered** I/O to all ports, and
`file-settings=lf` overrides file ports with full buffering. Audit
`0624078d62b543749acd9a13b61ae093` changed only this file-port setting, kept
the same generator and 60-second cap, and exited zero in 36.534 seconds with
the exact original C SHA. Console settings remained unchanged; no processor
restriction was added. This establishes a usable byte-identical recovery
control, not a compiler-only CPU speedup or a native numeric repair.
`numeric_generation_runtime_options` now makes that verified file-port policy
the reconstruction default; checkpoint recovery is preferred thereafter.

### Full-source host and jump controls: retained failures, no empty-set inference

All controls use the recovered original C, identical authenticated header,
GCC 16.2.0 binary, optimization flag family, proper separate `-dumpdir ./`,
alias/ealias-details plus CFG/SSA instrumentation and the same **60 seconds**
per compiler. They execute sequentially under the audit workspace lease.
The single/multiple argv comparison has exactly one differing token; the
shared-jump comparison also has exactly one differing token. They share input
bytes and do not clone or rebuild a runtime.

| Control | Only macro change from single host | Actual outcome | Retained observation |
|---|---|---|---|
| Single host | Baseline configuration plus newly qualified dump instrumentation | -9 / timeout, 60.026 s; no module | Four small-function CFG sections; no alias/ealias file |
| Multiple hosts | `___SINGLE_HOST` → `___MULTIPLE_HOSTS` | -9 / timeout, 60.022 s; no module | 38 CFG function sections; incomplete SSA coverage; no alias/ealias file |
| Single host, shared jump | `___INLINE_JUMPS` → `___DONT_INLINE_JUMPS` | -9 / timeout, 60.012 s; no module | No CFG/SSA or alias/ealias file retained |

The corresponding audit receipts are `854aa59b137f4977b6d0f5a898e114be`
(`outputs/original-single-host-alias`), `d7cc23e2483f44b9a7f1996eef2e4776`
(`outputs/original-multiple-host-alias`), and
`c36dcee8eb8c47fd8bc1853044ea3f41` (`outputs/original-shared-jump-alias`).
Raw dump/log artifacts and their hashes remain under the product's
`experiments/{single,multiple,single-shared-jump}` directories. Every compiler
parent was reaped and its own group was observed absent. These new
instrumented/input-changing controls are not a replay of the historical
unchanged no-PTA or original 90-second acceptance failure. Their failed
receipts are now reusable observations; the adapter refuses an automatic
rerun or an unreceipted partial workspace.

The multiple-host CFG retains a dominant **`___H___test_23_`** procedure:
101,223 observed body blocks, 155,452 observed edges and maximum fanout
7,613. The earlier single-host full CFG had 105,311 blocks and fanout 7,975.
Thus generic procedure-level host splitting leaves the main test body large;
it does not fulfill the simple prediction that the largest shared control-flow
scope would collapse. Counts from a partial observation are explicitly labeled
observed; the incomplete SSA was rejected as a full CFG/SSA correspondence.
The shared-jump timeout supplies no retained IR with which to assess its
representation prediction. Comparisons of these watchdog durations are not
performance comparisons or proof of which pass consumed the interval.

**There is still no measured original alias/ealias solution.** A missing dump
does not prove that the pass never ran, and it is not a zero-sized points-to
set. The parser now separates actual constraints, equivalence-node/class IDs,
named target unions and repeated points-to memberships, and requires the
function's closing alias-information marker before treating a solution as
closed. It retains partial observations and malformed rows explicitly. Its
completed-solution parser is calibrated against the already-retained real
functionful probe dumps without recompilation; that calibration is not
reclassified as an original numeric result.

The current QNT adds exact source/size/outcome recovery and unknown-versus-empty
solution controls; Lean rejects wrong-source recovery and an unclosed solution.
The actual source checkpoint, compiler outcomes, argv deltas, raw artifacts,
partial CFG census and model projections are connected in the current case.
Full original PTA membership measurements, a causal source repair and native /
Gerbil acceptance remain open. These three configurations must not be retried
unchanged or given larger caps; another run requires a concrete new input or
observation design. The other 9–12 worker was not stopped, restarted, signaled,
sampled, debugged or assigned a different checkpoint.


Validation and checkpoint closeout: audit ead4e017f9c44522b35529f4419b851e retains outputs/original-numeric-recovery-validation/receipt.json. Nine QNT tests, seven Lean statements, two observed-data Lean examples, strict current SysML validation and nine Python tests passed with stable source identities. Successful Lean logs contain no sorryAx. Initial Lean keyword/projection failures remain in audits 5183be855c0d4940962b2adf4575612b and 7a5af56eb9eb496aa4cc7e55fc3dcdeb; they are not rewritten. All compiler receipts were authenticated and reused during validation.

Audit 6676f6d5168f45b08403cd6b03ffaec8 additionally tested actual source-checkpoint rehydration under the existing workspace lease: it removed only the owned audit generated C after authenticating the retained bytes, observed the file missing, then used recover_original_numeric to restore the original 5,541,691 bytes and exact SHA through the normal checkpoint API. This controlled audit-cache loss test is not a production interruption or a native runtime recovery. Its outputs/original-numeric-checkpoint-closeout/restoration.json records both real observations. No generator or compiler rebuild was required.

### Phase attribution and an executed global-host source refinement (2026-10-21)

The preceding unknown-alias observations remain historical results. New controls
below use the same registered audit build product
`923af547b5e2526673b48db269fec79a3350697b5e634e15ad5244123a9df520`.
Original C SHA `35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158`
and the four original Scheme/include/header checkpoint inputs remain intact.
Candidate generated C is retained by the existing task source-identity API,
not copied into Evidence. No producer/bootstrap, task or public launcher was
created. Native compilation retains its 60-second cap. Preprocessing is a new
separate 20-second phase, not an enlarged native deadline.

| Changed input or observation | Real result | Discrimination |
| --- | --- | --- |
| Original C, preprocessing only | Exit -9 at 20.024s; partial 22,761,472-byte input.i | This cutoff is before CFG/SSA/alias compilation; it cannot establish an alias stall |
| Only disable comparator primitive inlining | Generation 13.254s; CPP 13.075s; native 60.043s timeout | Main eqv static calls 2,020 to 1,010; own cc1 samples at 15s parse, at 40s gimplify |
| Local no-inline assertion procedures | Generation 38.044s; native 60.061s timeout | Main generated body grows to 119,029 lines: local procedures did not split GVM/C host |
| True global groups, detailed dumps | Generation 9.177s; CPP 5.890s; native 60.027s timeout | Main CFG 7,943 blocks, 12,543 edges, fanout 789; 32 ealias function solutions close; dump/fflush dominates owned stacks |
| Exact grouped input.i, remove only tree-dump flags | Native exit 0, 53.259s; O1 retained | Separates intrusive IR output from real compiler work without changing the preprocessed program or cap |
| Same compiled module, corrected explicit linker | Exit 0, 2.776s, unique assertions-passed witness | Executes all original numeric forms in the refined module; independent unchanged interpreted reference also passes |

These observations are wall-clock samples and retained outcomes, not a clean
matched performance benchmark. In particular, the grouped candidate's GCC
wall report (TOTAL 45.05s) measures parsing 10.99s, optimization/generation
34.02s, tree gimplify 0.98s, tree PTA 1.06s, alias analysis 0.33s, SSA rewrite
0.14s and SSA incremental 0.39s. Detail rows are nested and must not be added
to their parent rows. GGC 1,915M describes cumulative allocation, not peak RSS.
No claim about original whole-function alias time follows from this candidate.

Source-chain mapping, against the retained candidate-runtime Git/checkpoint
identity: `tests/unit-tests/#.scm:134` expands the relation assertion;
`gsc/_ptree2.scm:220` generates runtime-binding specialization and fallback;
`gsc/_prims.scm:1837` specializes eqv; `gsc/_front.scm:1094` creates a fresh
basic-block collection for a global procedure; `gsc/_t-c-2.scm:117` scans each
procedure; `gsc/_t-c-1.scm:2066` emits C hosts. Original generated main
`___H___test_23_` contains 7,613 private host labels and 2,020 static eqv calls.
Multiple-host configuration therefore leaves one huge source-level procedure.
The comparator control exposes duplicated specialization cost, but reducing
those paths alone did not remove the front-end bottleneck.

The maintained source driver is
`models/gambit/native/numeric-alias/outline-assertions.scm`, SHA
`4bf384b92bd647fdec9641444702198b5b0f9ceaa2f40b5ae6bf43e677c46604`.
It uses Gambit's actual source reader, retains the original source object for
each expression and creates private global groups of at most 32 contiguous
`test-eqv`, `test-eq`, `test-equal`, `test-assert` or `test-approximate` forms.
Every other form is a barrier; definitions, conditionals and all 146 original
top-level `test-error-tail` forms retain their original positions. No arithmetic
expression, expected value, root/writeback or ABI code was rewritten. Private
names use a fixture-specific prefix independently checked absent from all
original input bytes. Failed local outlining, gensym string usage and rejected
uninterned globals remain source-checkpointed negative results; no compatibility
layer or source patch replay is used.

An independent plain GSI reader confirms 1,592 original top-level forms and
the exact manifest order. The driver produces 79 groups and 112 C procedures.
The largest other host has 3,522 observed CFG blocks. The detailed observation
contains 32 closed function ealias solutions with maximum observed named set
size four. Representative groups have 39,060 constraints, maximum equivalence
node ID 23,276, 5,820 pointer classes, six location classes, 33,143 repeated
memberships and six named targets. These are distinct units; ANYTHING/NONLOCAL
can summarize many runtime locations. This is not a concrete allocation bound,
a zero-cost alias result, or a complete translation-unit alias solution. The
later alias dump is absent. Partial/absent functions remain unknown.

The no-tree-dump control reuses the exact grouped preprocessed SHA
`0db8fea9aa38b2b7b393bc5ece3279922edf0b9d34e82d750aaf6a966ecdc47a`
(25,363,697 bytes). The resulting module SHA is
`ec941bbca0c46338d282e7af8c15b4cb3e10ad69f2b03779250666b99b46b7e6`.
Its first load incorrectly requested linker `_test`; exit 70 happened before
assertions. Actual C/nm identity requires `_test.o1`. The source adapter now
uses that name, and only execution of the retained module was repeated. The
corrected run verifies the module unchanged and receives exactly one
`NUMERIC-ORIGINAL:module-initialized,assertions-passed` witness, exit 0. The
complete unchanged interpreted original receives its separate reference
witness, exit 0 in 3.204s. Neither a boolean nor a model result substitutes
for these real executions.

Audit ownership and retained receipts:

- Original phase cutoff: `e227ee73d46c4b6fa9f5a6ab5e15012f`, raw
  product `experiments/profile-original-multiple/preprocess.json`; the initial
  adapter exited before a canonical receipt. This unreceipted directory is
  explicitly refused for retries; raw plan, partial output and outcome remain.
- Comparator control: `193cdcef8cde4a1da10cd8937a7cbe1c` /
  `outputs/numeric-comparator-call-profile/receipt.json`.
- Negative local host control: `481c0bd46e3849e9b064b3b9ed1b7b6e`;
  rejected uninterned global: `db44e527bf4a4867a8e6dd29b1fa18d3`.
- Global grouping: `d050d061cb084120b04bfdd953fa4f60` /
  `outputs/numeric-global-groups-profile/receipt.json`.
- Successful low-output compile and independent reference:
  `c57e6e05bcb145d88fe2b4bbaf09dd4e` /
  `outputs/numeric-grouped-low-output/receipt.json` (also retains initial failed load).
- Corrected real module execution: `d9a2672a74f64165990ec4e44cea9f87` /
  `outputs/numeric-grouped-module-execution/receipt.json`.

QNT `orderedFormPartition` and Lean `partitionPreservesFormCount` /
`partitionPreservesFormMembership` make the ordered source-index premise
explicit; negative controls drop, duplicate and reorder forms. The observed
projection uses the real 1,592-form manifest and per-function alias closure
flags. These proofs do not establish general contextual/continuation
equivalence. Runtime reference and native assertion executions are separate
evidence. Current case SysML binds these symbols to the executed refinement;
`dev/` remains generic methodology.

The source refinement is executed in the audit's incremental workspace. It is
not silently installed into the peer's leased production recipe. Full native,
Gerbil, GC/FFI and lifecycle acceptance remain open, as does full original
workload alias attribution. All samples belong to audit-owned PID/birth/PPID/
PGID/UID-verified cc1 children; no other 9–12 process was stopped, signaled,
restarted, sampled or debugged. Unchanged failed routes are not rerun.

Validation closeout: audit `4ab13782241e4416959bee5bdfa71aee` retains
`outputs/numeric-global-group-validation/receipt.json`: QNT source tests and
the exact actual ordered-form/per-function-alias projection, pinned Lean
4.34.1 source/observed compilation without sorryAx, strict current SysML with
all imported dev models, and 13 focused Python tests pass. Source identities
are stable before/after. The validation authenticates/reuses compiler and
module artifacts; it does not compile the native workload again. The original
literal-heavy QNT observed projection timed out at 45 seconds in audit
`011d854042364748877a8a165f87e45d`; exact contiguous ranges encode the same
independently verified indices and pass under the unchanged cap. The earlier
pre-spawn sandbox boot-identity failure was reconciled by the existing audit
process-resume API, not by writing state. Historical failures are retained.
