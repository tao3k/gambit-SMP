# Staged FFI generation and stack-preserving callback repark

This source-bound handoff changes research evidence and Quint only. It does not change runtime/generator code, regenerate runtime C, alter qualification/Recipes/history, or launch a native campaign. Grok implementation steps are dependencies for its authorized production work, not a prohibition on that work. Source authority is the same lock-main revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus cumulative foreign-release-claim patch, reproduced in [the source identity record](checked-park-source-protocol.json). Vendor HEAD equality is not required. Recorded qualification remains 8/12.

## Correction to the previous abstract repark transition

Initial park and callback-return park cannot use the same outward native escape. Initially the host body has not started: a controlled landing can hand off its journal and escape to its owning ___call dispatcher. During callback return the host body and callback wrapper are live C activations above that dispatcher. Jumping to the outer ___call would discard them, not suspend them. A valid live marker does not preserve C frames crossed by longjmp or C++ unwinding.

Use **stack-preserving synchronous repark** on callback return. The helper completes preparation/commit while the wrapper and host frames remain on their original OS stack, then returns the native callback value into the same host activation. If repark cannot complete safely, retain the wrapper/job and service the active cohort or invoke the reviewed terminal fault policy; do not return into a potentially blocking host body while still an active member. The prior checked_park model treated repark atomically and did not prove this native-stack distinction. Its receipts remain unchanged.

## Exact generator and existing generated-C correspondence

| Locked source | Current emitted ordering | Staged change |
| --- | --- | --- |
| `_ptree2.scm:2902 c-make-function`, `2910..2930 convert-param-list` | Declares/converts Scheme-object parameters first, then other parameters; lexical nested converters surround make-body. `cleanup?` depends on parameter types. | Add a distinct admitted staged emitter, not a global rewrite of legacy c-make-function. Open a persistent job/journal and register Scheme roots before any loan-producing prefix; preserve conversion ordering and release only successfully acquired units on failure. |
| `c-declare-argument`, `c-convert-representation`, `c-convert-argument` at2775..2870 | Generates paired BEGIN/END macros with locals such as arg1 and optional voidstar/indirect representations. | Split temporary lexical names from persistent typed job fields. A transferred unit must be removed from lexical cleanup ownership; emitting both old END cleanup and later job cleanup doubles the release. Record the owner and acquisition state at each successful conversion. |
| `type-needs-cleanup?`,2502 | String/function/aggregate/custom types may need cleanup; pointer forms do not automatically qualify. | Keep resource policy separate from this boolean: no-cleanup does not imply no loan, no alias, no Scheme access or safe blocking. Require an explicit supported ABI/alias/escape descriptor. |
| `build-c-lambda`,3227 and its make-body | For a valid function id, emits a call with converted parameters. Otherwise expands arbitrary C text and defines ___return as assignment/goto. Then emits set-result-code and END_CFUN_BODY. | First support classified named-function adapters. Do not hoist arbitrary inline C text: it can refer to ___ps, ARG/result macros, labels, ___return or custom AT_END. Refuse that staged mode before accepting/executing the job unless separately compiled against an explicit staged ABI. Legacy behavior remains its own contract. |
| `c-set-result`,2873..2900; `c-function`,3144..3189; `build-c-define`,3221; `fn-param-converter`,3189 | Result conversion is emitted into the body; callback function wrappers share c-make-function and SFUN macros. Function-pointer converters can create another callback wrapper. | Emit separate active completion and checked callback wrappers, including recursively generated function converters. Do not cover only top-level c-define and leave nested function pointers on the unchecked legacy SFUN path. |
| Header10395..10446 | CFUN context saves RA and executes W_ALL; OOL function takes ps, END_CFUN_DEF writes ps->temp1; BODY_CLEANUP installs TRY only around the body, then AT_END, END_TRY and R_ALL_INL. | Prepared native job body must not use these wrappers or receive ps. Its return while parked cannot fall through an OOL temp1 store/R_ALL. Prefix and completion use the active wrapper; native body accepts only the stable typed job/native payload. |
| `_kernel.scm:2295` and archived `_kernel.c:6005..6024` | set-gambitdir c-lambda: UCS2 conversion → BODY_CLEANUP → native code → SET_RESULT_VOID → END_BODY_CLEANUP → string release → CFUN_ERROR_CLEANUP_VOID → END_CFUN_VOID. | This exact source/C pair is an existing lexical-lifetime example, not a regenerated staged candidate. The string must survive the body, and the existing close macro owns its one release until explicitly transferred to the staged job. |
| Header10575..10576 | END_CFUN_SCMOBJ_TO_UCS_2STRING calls release_string. | A staged prepare cannot publish the same pointer to the job and then execute this release. Transfer ownership or produce an independent native copy with separately recorded ownership. |
| Header10210..10213 versus10327..10328 | SFUN SCMOBJ-to-CHARSTRING END is empty; native-to-Scheme CHARSTRING prefix END releases the produced Scheme object. | Do not infer that every callback-returned string is a temporary job borrow. Honor existing ownership/export semantics. New job-scoped callback loans require an explicit descriptor; pointers escaping beyond the host call require a separate tracked export contract or refusal. |

The macro order matters on error: body completion precedes result conversion; AT_END follows the attempted result conversion; acquired parameter cleanup follows the body wrapper. The checked staged emitter must preserve accepted observable ordering while moving physical storage into the job. AT_END may be empty or an explicitly classified hook; arbitrary hook code cannot be replayed or moved into an unclassified parked phase. A callback status error is not a host-body completion.

## Required generated C shape

These are proposed emitter contracts, **not compiler-generated output or compilable runtime fixtures**. Actual candidate generation, configured header expansion, return labels and root maps remain required native-generation evidence. New names below do not exist in the locked runtime.

```c
/* Active PREPARE: emit before the first conversion. */
job = checked_job_begin(owner_ticket, abi_descriptor, rooted_arguments);
status = convert_prefix_into_job(job); /* record each successful unit */
if (status != OK) return active_prefix_error_after_job_cleanup(job);
return_scheme_rooted_job_handle(job);  /* lexical owners relinquished */

/* Parked BODY: different native function, no ps, ARG or SCMOBJ locals. */
static native_status job_body(native_job *job) {
    return invoke_named_function_once(job->native_arguments,
                                      &job->native_result);
}

/* Active COMPLETE, after checked final rejoin. */
status = convert_result_into_actual_scheme_root(job);
run_classified_at_end_once(job, status);
release_acquired_prefix_and_job_scoped_loans_once(job);
copy_status_and_result_to_surviving_owner(job);
drop_job_native_tail_last(job); /* no following read through job */
return_or_raise_via_the_active_scheme_path();
```

Scheme code connecting PREPARE to BODY uses the previous `##checked-park-landing!` and completed old-cohort materialization/commit protocol. The job root handle must occupy an actual traced Scheme slot or registered root cell until the new owner is installed. A native job pointer or W_ALL declaration is not that root. Result conversion may allocate/GC, so native result storage and Scheme result/error carrier remain owned through that conversion and its error path. Read relocated storage after GC; do not restore saved scalar SCMOBJ values.

## Owning ___call dispatcher and native catcher lifetime

In `setup.c:3951 ___call`, trampoline/host invocation occurs inside BEGIN_TRY/END_TRY. Header10051..10075 restores the previous catcher at END_TRY. For an initial park event, add a validated internal handler **before** the existing generic UNWIND_C_STACK/marker-match rethrow at4058. Validate full VM/native-owner/activation/depth ticket, committed park state, payload initialization and that no user host frame has yet begun. Transfer/drain only the controlled landing suffix; ordinary trampoline retry must keep all surviving journals.

Install a resident native-dispatch catcher before invoking job_body. Merely adding a call after the existing END_TRY leaves ps->catcher referring to an outer scope, not that just-finished ___call TRY. Never store or restore the address of its expired jbuf. The dispatch catcher must live through host invocation and callbacks on the same OS stack; C++ dispatch must have the corresponding explicit exception containment. Keep run marker, call context, job root/domain and native-tail tokens through initial park, native invocation, final rejoin and last ps access. A staged internal event must not pass through ___run's ordinary outward finalizer.

Refactor ___call into an outer event loop with explicit `ENTER_SCHEME / ENTER_NATIVE_ONCE / RESUME_SCHEME / OUTWARD_ERROR / RETAINED` states stored in stable native context. Each iteration installs its own live TRY around the selected execution, then classifies the caught event after END_TRY. The current trampoline-only do/while for UNWIND_C_STACK_TO_TRAMPOLINE remains a Scheme retry, not permission to reinvoke the native body. The initial park event selects ENTER_NATIVE_ONCE only before a host frame exists; native completion selects final rejoin and RESUME_SCHEME at the completion landing. Use an immutable pre-TRY context handle and heap/registered mutable journal state, not modified nonvolatile automatic cleanup progress. Callback in-place repark neither sends an outer PARK event nor changes the host invocation state back to not-started.

The representative native nesting is:

```
___run (live return marker)
  ___call resident dispatcher / catcher
    prepared named host body            [must survive callback return]
      checked SFUN wrapper / native tail
        nested ___call -> Scheme callback
      convert callback result -> prepare -> close child TRY/marker
      synchronous repark helper         [preserves all caller C frames]
      native callback return
    original host body continues once
  final host return -> final rejoin -> Scheme COMPLETE
```

Do not dispatch the body a second time after callback repark, and do not report a parent Scheme result merely because the nested callback finished.

## Checked callback return: exact order

1. Native callback entry validates the stable parent-job ticket before SFUN marker/conversions or ps access. Request checked rejoin if parked. The old BEGIN_SFUN* macro is not a sufficient guard because it already evaluates PSTATE and calls ___sfun_frame_marker.
2. Admit the child activation on the original native owner, root its Scheme arguments/results, execute nested ___call and catch supported Scheme/conversion errors locally. Transfer any declared job-scoped native callback-result loan into the still-live host job before disposing the child. Default legacy pointer/string export semantics are not silently shortened.
3. While still active and the child marker/catcher are valid, prepare the callback-return freeze certificate through a controlled Scheme landing if materialization is required. Return while active; do not commit park inside a Scheme helper and then require it to execute ordinary active RETURN/R_ALL on a detached ps. After any competing GC, validate/update the certificate against actual current rooted storage; a stale certificate is not a successful commit.
4. Finish child Scheme/conversion cleanup and record native return value/status in stable native storage. END_TRY restores the resident dispatcher catcher; invalidate the child marker and leave the child SFUN count once. Retain the callback's native-tail/job token, which covers remaining helper/metadata access. Zero SFUN count is not no native consumer.
5. Call new `___park_repark_callback_in_place(job, cb_frame, certificate)` synchronously. It contains/returns status; it must not THROW to an outer catcher or unwind the host body. It participates in the common cohort commit while active, performs no arbitrary Scheme allocation/callback after final freeze, and returns only once detached or in a controlled retained/terminal fault disposition. GC election losses retain service debt; no local membership decrement or timeout-based exclusion.
6. On successful park, copy the native callback value to the C return local, finish the callback tail release without subsequent descriptor/ps access, then return to the original host body. Parent-job result loans remain owned until the declared host completion/export release.

Legacy END_SFUN* ends TRY, kills marker, decrements sfun_frame_count, then calls ___propagate_error. `setup.c:1088` propagates every non-NO_ERR by ___throw_error. A staged callback cannot blindly reuse that path: a Scheme callback failure can unwind the live host body. The first contract requires an ABI-declared native error/status mapping that the host understands; absent such a contract, refuse this callback-capable staged adapter or use the reviewed terminal containment. Never encode a repark hard failure as callback success and return to a body that may block while B remains active.

## Failure cleanup and remaining guarantees

| Point | Required ownership/cleanup |
| --- | --- |
| Prefix conversion fails after earlier conversions succeeded | Native job journal exists first. Clean only acquired prefix units once, before active CFUN error jump/OOL return. Body/AT_END never ran; do not execute them. |
| Initial preparation/commit refuses | Active cohort/root ownership remains or is reconciled under the existing commit protocol. Release known acquired prefix via its journal; no duplicate lexical END release. Unknown commit outcome stays retained. |
| Supported callback error/result-conversion failure | Keep the host frame and parent job alive; map native status under the accepted ABI. Child cleanup and in-place repark precede callback return. Child error does not restore the parent's saved Scheme continuation. |
| Callback repark cannot complete | Keep callback tail, parent host activation, root domain and job. If still active, service the common sync/fault loop; otherwise retain the frozen domain. Do not let a missing participant block the cohort silently. Terminal/retained disposition remains an implementation policy, not an arbitrary longjmp recovery claim. |
| Host native exception or unknown effects | Catch only at an actually live admitted boundary. Do not replay host invocation. Unknown resource effects retain ownership or use terminal containment; no assumed rollback of arbitrary host code. |
| Final native-result conversion fails | Rejoin first, keep the native result and error roots through conversion, execute the accepted AT_END ordering once, release known acquired units once, then take the active Scheme error path. |
| Last release | Copy native status/result/cursor beforehand. Finish helper accesses before publishing the last token dropped. No read through the job/child/ps after its final reference. |

P0 refusal, active-rank/frozen-domain GC, scanner grace, admitted internal rejoin after external close and full generated frame maps remain dependencies from [checked park](checked-park-source-protocol.md) and [collective ACK service](ack-collective-service.md). This new slice does not prove their C implementation or compose all earlier models into one executable proof.

## Grok implementation sequence and native evidence

1. Add staged ABI/type/ownership metadata and a separate emitter beside c-make-function/build-c-lambda. Include c-function/build-c-define and fn-param-converter checked callback paths. Initially admit named native functions, classified cleanup/hook and native error mapping; reject unclassified inline bodies and escaping aliases before job acceptance.
2. Emit typed PREPARE/BODY/COMPLETE and checked callback wrappers. Record prefix acquire/ownership handoff, native result, callback loan owner and one-shot cleanup/hook claims. Keep OOL ps/temp1/R_ALL and Scheme conversions out of BODY. Verify inline/OOL error exits after prefix cleanup, including result failure.
3. Add the initial internal-event branch and resident native catcher in ___call. Distinguish initial controlled transfer from callback in-place repark, ordinary UNWIND_C_STACK, internal trampoline retry and outward failure. Keep marker/activation/root/token lifetimes explicit.
4. Implement the synchronous callback-return helper with parent host frame retained. Reprepare/revalidate after GC without discarding user C frames; keep child tail after marker/SFUN leave until native callback return. Treat unsupported error propagation/unknown escape as refusal or terminal containment.
5. Regenerate with the exact locked compiler/configuration; retain configured header, generated Scheme/C, objects and link identity. Audit frame-label maps, executed W_ALL/R_ALL, real root cells, string ownership and native activation identity. Source snippets and the prospective C shape above are not this receipt.
6. On that one producer inject first/second prefix failure, callback error/GC, result-conversion failure, GC between child SFUN leave and repark, repark refusal, and native-body failure. Assert one host entry, same live host activation before/after callback, one child cleanup, parent-owned declared loan, unchanged native stack owner, correct AT_END/result order, and no post-final-release access. Keep original deadlines; do not substitute a full-suite rerun or change qualification.

Independent conclusion: the prior abstract repark is insufficient without this C-stack-preserving distinction. The revised protocol is implementable in principle for the admitted staged ABI, with explicit cleanup and failure containment. Sufficiency still depends on actual emission/root maps, collector/cohort implementation, callback error contract and same-producer native evidence. It does not make arbitrary legacy raw c-lambda, untracked host longjmp or unclassified pointer export safe.

## Bound existing generated-C control

Candidate snapshot `lib/_kernel.c:6005..6024`, SHA256 `7435cfa1507f91de9fae77a6c5b4cf928ae764a73c1a91fb9349d53d1a9e5076`. This archived lexical-wrapper control is not newly generated staged C and is not a claim about any current linked gsi.

```c
___BEGIN_CFUN_VOID(_____kernel_23_1)
#define ___ARG1 ___CFUN_ARG(1)
___BEGIN_CFUN_ARG(1,___UCS_2STRING ___arg1)
___BEGIN_CFUN_SCMOBJ_TO_UCS_2STRING(___ARG1,___arg1,1)
___BEGIN_CFUN_BODY_CLEANUP
#undef ___AT_END
#define ___return goto ___return___kernel_23_1
___set_gambitdir (___arg1);
___return___kernel_23_1:;
#undef ___return
#ifndef ___AT_END
#define ___AT_END
#endif
___CFUN_SET_RESULT_VOID
___END_CFUN_BODY_CLEANUP
___END_CFUN_SCMOBJ_TO_UCS_2STRING(___ARG1,___arg1,1)
___END_CFUN_ARG(1)
#undef ___ARG1
___CFUN_ERROR_CLEANUP_VOID
___END_CFUN_VOID
```

## Recorded model validation

Quint 0.33.0 / TLC: 32 expected controls, comprising 10 safety and weak-fairness conditional-progress scenarios, 17 decoded safety negatives and 5 distinct reachability witnesses. All matched expectations; maximum case 15.019s under the unchanged 30s per-case cap. Receipt: `.cache/tasks/repair-9-12/processes/audit/runs/28bb4ac486ef4d33939a670ccbeae804/outputs/staged-ffi-stack/receipt.json`. Checker projections were reconstructed byte-for-byte and witnesses independently checked in Python. Source snapshot: 33 files reverified; 20 protected inputs unchanged. Native executions: 0.

The model includes recurrent GC, one nested callback, a parent-owned explicitly job-scoped callback loan, separate child marker/native-tail lifetimes, resident versus returned catchers and final Scheme-result scanning. It does not model arbitrary recursion, C11 ordering, real stack maps, active-cohort transitions or scanner grace. Positive progress assumes fair enabled protocol steps and supported callback/native return or a declared retained disposition; retention is not proof that a stuck active participant can be safely excluded. Earlier atomic checked-park controls remain predecessors and do not prove host-stack preservation.

## Subsequent collective and root refinement

[Synchronous repark protocol](synchronous-repark-protocol.md) supplies the proposed common service/old-cohort departure ACK, actual RC-cell versus native-payload distinction, retained-active service obligation and23-control QNT slice. The prior native-stack slice did not establish those collective/root implementation conditions; its immutable receipts remain unchanged.
