/* Model-owned source-sites/foreign-entry declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpForeignEntrySources {
 private import GambitSharedHeapSmp::*;

 part nativeEntry:SourceSite {
  attribute :>> id="nativeEntry";
  attribute :>> artifact="vendor/gambit/lib/c_intf.c";
  attribute :>> anchor="___HIDDEN ___SCMOBJ make_sfun_stack_marker";
  attribute :>> role="foreign-boundary";
  attribute :>> observed="Marker constructor allocates before reloading the borrowed root; wrappers use TRY and return/release RC custody";
  attribute :>> required="Root protected before marker allocation; nested callback/exception closes writes and drains activation debt without GC-owner cycle";
  attribute :>> gap="Marker wrappers have source-visible error cleanup; full generator/catcher/callback inventory and thread-affine effect audit remain required";
  ref part :>> question=boundarySource;
 }
 part packetGeneratedEntryOrder:SourceSite {
  attribute :>> id="packetGeneratedEntryOrder";
  attribute :>> artifact="vendor/gambit/include/_gambit/foreign_conversion.h.in";
  attribute :>> anchor="#define ___BEGIN_SFUN_VOID(proc,roots)";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="VOID/SCMOBJ/general SFUN variants call begin_sfun, then generated ROOT_ARG stores, then sfun_marker; END variants call end_sfun after END_TRY and before propagate_error. _ptree2 root-arguments emits direct scheme-object stores; converted arguments use SFUN_ARG.";
  attribute :>> required="Qualify the entire pre-registration prefix as noncollecting/nonreentrant and excluded from concurrent freeze, or hold a parent/source root loan before first fallible/collecting access. Target initialized membership plus payload commit precedes parent ACK; every conversion/error/result variant reloads after admitted GC.";
  attribute :>> gap="Macro order is observed, not a proof that every selected producer, source borrower, callback and exception variant obeys this protocol. A native malloc that does not call Scheme does not alone prove parallel moving-cut exclusion.";
  ref part :>> question=cutSource;
 }

 part foreignRootEmitter:SourceSite {
  attribute :>> id="foreignRootEmitter";
  attribute :>> artifact="vendor/gambit/gsc/_ptree2.scm";
  attribute :>> anchor="(define (c-make-function sfun? name param-typs result-typ make-body)";
  attribute :>> role="generator";
  attribute :>> observed="SFUN root-arguments are emitted before collecting conversions; argument conversion order puts Scheme-object types first";
  attribute :>> required="Prove emitted registration/reload/cleanup for every parameter/result/error variant and actual generated consumer";
  attribute :>> gap="Emitter spelling or macro presence does not establish producer-to-binary or exceptional-path coverage";
  ref part :>> question=cutSource;
 }
 part foreignRootMacros:SourceSite {
  attribute :>> id="foreignRootMacros";
  attribute :>> artifact="vendor/gambit/include/_gambit/foreign_conversion.h.in";
  attribute :>> anchor="#define ___SFUN_ROOT_ARG";
  attribute :>> role="native-entry";
  attribute :>> observed="Current macros use begin_sfun and sfun_arg to install activation-owned argument roots; call_sfun reloads the span into Scheme stack, and end_sfun releases the activation";
  attribute :>> required="Register before first collecting conversion/marker allocation; hold root and write authority until final reload/store";
  attribute :>> gap="All SFUN result/void/error and CFUN variants, C aliases and nonlocal escapes require full producer-consumer audit";
  ref part :>> question=cutSource;
 }
 part foreignExitMacros:SourceSite {
  attribute :>> id="foreignExitMacros";
  attribute :>> artifact="vendor/gambit/include/_gambit/foreign_conversion.h.in";
  attribute :>> anchor="#define ___END_SFUN_VOID";
  attribute :>> role="exit";
  attribute :>> observed="End macros run TRY recovery, marker kill, RC release and error propagation";
  attribute :>> required="Every exit must retain source/result ownership until final semantic use and discharge exactly one borrow/entry";
  attribute :>> gap="Macro expansion alone does not prove cleanup after continuation escape, nested callback or unknown native completion";
  ref part :>> question=cutSource;
 }
 part externalClientData:SourceSite {
  attribute :>> id="externalClientData";
  attribute :>> artifact="vendor/gambit/examples/tcltk/command.h";
  attribute :>> anchor="___HIDDEN void scheme_delete_cmd";
  attribute :>> role="native-client";
  attribute :>> observed="Call/create/delete use RC ClientData; callback pins identity while Scheme reloads payload, delete reads snapshot before release";
  attribute :>> required="Native ownership, payload access, deletion and owner-affine cleanup must all enter the admitted source protocol";
  attribute :>> gap="Bundled callers are inspectable; arbitrary embedding/plugin/native code is outside this finite source inventory and must be declared or denied access";
  ref part :>> question=cutSource;
 }
 part bulkTryOwnershipBoundary:SourceSite {
  attribute :>> id="bulkTryOwnershipBoundary";
  attribute :>> artifact="vendor/gambit/include/_gambit/foreign_conversion.h.in";
  attribute :>> anchor="#define ___BEGIN_TRY";
  attribute :>> role="actual-catcher-without-resource-rollback";
  attribute :>> observed="SETJMP branch installs catcher and restores it at END_TRY; THROW supplies longjmp_err. No allocation/list/loan rollback is encoded in these macros";
  attribute :>> required="Known ownership/commit records outside fallible C extent drive settlement; do not infer resource closure or rollback from catcher restoration";
  attribute :>> gap="Provider-specific nonlocal/native interruption is not proved safe by presence of TRY";
  ref part :>> question=cutSource;
 }
 part bulkSfunNormalHandoff:SourceSite {
  attribute :>> id="bulkSfunNormalHandoff";
  attribute :>> artifact="vendor/gambit/lib/_c_intf/sfun-entry.inc";
  attribute :>> anchor="if (record->roots && ___try_set_data_rc(ps,record->roots,source ? *source : proc) &&";
  attribute :>> role="actual-normal-parent-to-bank-handoff";
  attribute :>> observed="BEGIN_SFUN VOID, SCMOBJ and general forms consume local scope output. PERM hands off without a bank; moving scope stores procedure and acquires bank before returning self loan. END_SFUN uses the accepted scope after catcher restoration";
  attribute :>> required="Use actual ownership facts to extend common allocation/commit adoption and bulk install ACK without changing normal SFUN order";
  attribute :>> gap="No asynchronous commit witness or target intent query is provided by this normal synchronous path";
  ref part :>> question=cutSource;
 }
 part bulkPhysicalEndConsumer:SourceSite {
  attribute :>> id="bulkPhysicalEndConsumer";
  attribute :>> artifact="vendor/gambit/lib/_c_intf/sfun-entry.inc";
  attribute :>> anchor="___EXP_FUNC(void,___end_sfun)";
  attribute :>> role="actual-physical-extent-end";
  attribute :>> observed="END_SFUN consumer clears a still-live marker then aborts activation; revoked marker is not cleared twice";
  attribute :>> required="Unify known allocation/loan/root and lifecycle discharge while retaining physical end and pending-result guards";
  attribute :>> gap="Generic abort has no prepared allocation/unknown registration branch today";
  ref part :>> question=cutSource;
 }
 part bulkSfunPrepareCaller:SourceSite {
  attribute :>> id="bulkSfunPrepareCaller";
  attribute :>> artifact="vendor/gambit/lib/_c_intf/sfun-entry.inc";
  attribute :>> anchor="record->roots=___alloc_rc_roots(ps,___CAST(___SIZE_T,nargs));";
  attribute :>> role="actual-existing-root-array-consumer";
  attribute :>> observed="begin_sfun assigns allocator return to owned roots, registers primary root/borrow and cleans failure before marker abort";
  attribute :>> required="Preserve SFUN allocation/borrow/error behavior when adding bulk result adoption; no fake purpose or hidden parallel allocator";
  attribute :>> gap="No current bulk prepare/install/query/ACK caller exists";
  ref part :>> question=cutSource;
 }
 part bulkLegacySlotResult:SourceSite {
  attribute :>> id="bulkLegacySlotResult";
  attribute :>> artifact="vendor/gambit/include/_gambit/foreign_conversion.h.in";
  attribute :>> anchor="#define ___SFUN_ARG(i,arg)";
  attribute :>> role="actual-legacy-slot-error-consumer";
  attribute :>> observed="Generated SFUN paths expect sfun_arg Scheme error code rather than bulk result enum";
  attribute :>> required="Keep exact legacy result projection and root-before-marker/late-argument ordering; unknown bulk outcome stays in held operation";
  attribute :>> gap="No raw bulk status integer may be substituted for existing Scheme error code";
  ref part :>> question=cutSource;
 }
 part bulkForeignInvocation:SourceSite {
  attribute :>> id="bulkForeignInvocation";
  attribute :>> artifact="vendor/gambit/lib/c_intf.c";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___release_foreign)";
  attribute :>> role="clear-before-native-effect";
  attribute :>> observed="Release callback and opaque payload are cleared from FOREIGN before the native callback is invoked; returned error remains effect result";
  attribute :>> required="Use saved in-flight identity/outcome; do not infer completion from cleared fields or replay unknown callbacks";
  attribute :>> gap="No general native side-effect recovery/at-most-once completion proof follows from clearing fields";
  ref part :>> question=cutSource;
 }
 part nativeFunctionBranch:SourceSite {
  attribute :>> id="nativeFunctionBranch";
  attribute :>> artifact="vendor/gambit/lib/c_intf.c";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___SCMOBJ_to_FUNCTION)";
  attribute :>> role="static-host-versus-dynamic-native-alias";
  attribute :>> observed="Inspects c-define intro host; otherwise asks make_c_closure; unsupported conversion fails";
  attribute :>> required="Separate static code/VM lifetime from dynamic RC payload lifetime and actual selected ABI";
  attribute :>> gap="Source availability is not native arm64 support or a qualified callback lifetime";
  ref part :>> question=cutSource;
 }
 part tclRegistrationCaller:SourceSite {
  attribute :>> id="tclRegistrationCaller";
  attribute :>> artifact="vendor/gambit/examples/tcltk/tcltk.scm";
  attribute :>> anchor="(define ##tcltk-define-procedure";
  attribute :>> role="actual-scheme-native-register-caller";
  attribute :>> observed="c-lambda takes char-string and scheme-object proc and calls scheme_create_cmd with current ps";
  attribute :>> required="Parent roots survive conversion and constructor before accepted RC ownership; callback/delete retain unique last-use debt";
  attribute :>> gap="Generated callback object/ABI and exceptional cross-library cleanup still require native acceptance";
  ref part :>> question=cutSource;
 }
 part foreignCleanupBoundary:SourceSite {
  attribute :>> id="foreignCleanupBoundary";
  attribute :>> artifact="vendor/gambit/include/_gambit/foreign_conversion.h.in";
  attribute :>> anchor="#define ___BEGIN_CFUN_BODY_CLEANUP";
  attribute :>> role="generated-native-cleanup-boundary";
  attribute :>> observed="CFUN cleanup variants combine TRY and register write/reload macros; SFUN END closes activation and propagates errors";
  attribute :>> required="Audit selected generated variant and every escaping path, not only syntactic cleanup availability";
  attribute :>> gap="Raw pin release after callback and arbitrary nonlocal exit are not proven by existence of TRY macros";
  ref part :>> question=cutSource;
 }
 part nativePointerConversion:SourceSite {
  attribute :>> id="nativePointerConversion";
  attribute :>> artifact="vendor/gambit/lib/c_intf.c";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___SCMOBJ_to_POINTER)";
  attribute :>> role="foreign-external-address-conversion";
  attribute :>> observed="Checks FOREIGN subtype/tags then extracts FOREIGN_PTR_FIELD; this is not a heap-body borrow";
  attribute :>> required="Declare whether native payload contains Scheme references, its access lifetime, callback effects and release ownership";
  attribute :>> gap="C pointer type/tag alone cannot identify embedded references or repair arbitrary aliases";
  ref part :>> question=cutSource;
 }
 part nativeStringCopy:SourceSite {
  attribute :>> id="nativeStringCopy";
  attribute :>> artifact="vendor/gambit/lib/c_intf.c";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___SCMOBJ_to_NONNULLSTRING)";
  attribute :>> role="copied-native-bytes";
  attribute :>> observed="Conversion allocates RC storage and writes encoded bytes rather than exporting a Scheme string body";
  attribute :>> required="Account byte-buffer allocation, error release and native last use separately from boxed barriers";
  attribute :>> gap="Nested callbacks and ownership transfer still require real caller qualification";
  ref part :>> question=cutSource;
 }
 part foreignWrapperInitialization:SourceSite {
  attribute :>> id="foreignWrapperInitialization";
  attribute :>> artifact="vendor/gambit/lib/c_intf.c";
  attribute :>> anchor="___EXP_FUNC(___SCMOBJ,___POINTER_to_SCMOBJ)";
  attribute :>> role="foreign-wrapper-construction";
  attribute :>> observed="Allocates FOREIGN then writes tags, release callback and native address before returning wrapper";
  attribute :>> required="Keep tags rooted over allocation and define initial scan shape/publication; distinguish Scheme tag from opaque native address";
  attribute :>> gap="A FOREIGN shell does not cause its arbitrary native payload to be traced automatically";
  ref part :>> question=cutSource;
 }
 part tclCommandOwner:SourceSite {
  attribute :>> id="tclCommandOwner";
  attribute :>> artifact="vendor/gambit/examples/tcltk/command.h";
  attribute :>> anchor="___HIDDEN ___BOOL scheme_create_cmd";
  attribute :>> role="real-native-constructor-callback-delete-owner";
  attribute :>> observed="Create roots proc in RC, allocates vector, directly writes vector element and installs it; call pins RC identity; delete releases Scheme payload and RC ownership";
  attribute :>> required="One callback/delete/construction protocol covers parent roots, pin-before-load, canonical reload and nonlocal cleanup";
  attribute :>> gap="Normal C return reaches release but arbitrary continuation escape or concurrent delete needs stop/last-user evidence";
  ref part :>> question=cutSource;
 }
 part tclPayloadReload:SourceSite {
  attribute :>> id="tclPayloadReload";
  attribute :>> artifact="vendor/gambit/examples/tcltk/tcltk.scm";
  attribute :>> anchor="(define ##tcltk-command-payload";
  attribute :>> role="real-generated-callback-payload-reader";
  attribute :>> observed="C-defined callback accepts RC pointer and reads its current payload after Scheme entry";
  attribute :>> required="Reload canonical payload after allocating conversions and every admitted reentry";
  attribute :>> gap="Snapshot data_rc result cannot remain an unrooted physical identity across a later GC";
  ref part :>> question=cutSource;
 }
 part markerTargetInstall:SourceSite {
  attribute :>> id="markerTargetInstall";
  attribute :>> artifact="vendor/gambit/lib/c_intf.c";
  attribute :>> anchor="___SCMOBJ ___make_sfun_stack_marker_root";
  attribute :>> role="handoff-call-boundary";
  attribute :>> observed="Rooted marker wrapper enters lifecycle, allocates/reloads and installs record->marker on success";
  attribute :>> required="Marker payload and activation root protection are established before callers acknowledge source release";
  attribute :>> gap="Every marker variant and raw caller input needs the same pre-root and exceptional cleanup premises";
  ref part :>> question=cutSource;
 }
}
