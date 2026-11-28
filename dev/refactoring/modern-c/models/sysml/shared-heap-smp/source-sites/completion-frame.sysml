/* Static resume is control representation, not ambient-thread authority. */
package GambitSharedHeapSmpCompletionFrames {
 private import GambitSharedHeapSmp::*;
 part completionSharedAlias:SourceSite {
  attribute :>> id="completionSharedAlias";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##continuation-copy cont)";
  attribute :>> role="request-service-design";
  attribute :>> observed="copy shares frame/denv; next! changes one wrapper; continuation-set! writes heap or stack cells directly. A closure's captured completion value is distinct from the caller's later-reflectively-mutable completion slot. Logical semantic mutation is not a GC address change.";
  attribute :>> required="Snapshot lexical operands into a precise private wait frame rather than reread mutable caller slots as a free environment. Preserve shared mutations for aliases to the same cell; restored active copies and new physical registrations are distinct incarnations, not independent rewrites of all shared data.";
  attribute :>> gap="Current reflection lacks an optimized-frame/callable projection protocol. No immutable snapshot or alias-law proof follows from shallow wrapper copy; generic representation remains for unqualified exposure.";
  ref part :>> question=aliasSource;
 }
 part completionSaveCorridor:SourceSite {
  attribute :>> id="completionSaveCorridor";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___THREAD_SAVE";
  attribute :>> role="request-service-design";
  attribute :>> observed="SAVE uses current frame and creates a break when R0 differs from handler_break; otherwise it reuses break.next without adding a break. SAVE2 passes current Thread plus an explicit operand to a static registration procedure. RESTORE transfers saved frame into break.next and clears Thread.cont.frame.";
  attribute :>> required="Proposed private wait frame S is structurally rooted by existing Thread.cont/break/captured ancestry. Static retry requires FP==stack_break, R0==handler_break and next-frame descriptor S; decode its captured completion without collecting, then reuse the SAVE fast corridor. Preserve original register/outcome producers.";
  attribute :>> gap="No existing generated S landing/decoder/admission exists. Ambient Thread lookup, retaining a raw frame pointer or unconditional SAVE after restoring S can change semantics or grow breaks; no zero-copy claim without this corridor.";
  ref part :>> question=cutSource;
 }
 part completionBreakRestore:SourceSite {
  attribute :>> id="completionBreakRestore";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="___COVER_BREAK_HANDLER_HEAP_RETN;";
  attribute :>> role="request-service-design";
  attribute :>> observed="Break handling can copy heap frame payload to active stack, patch its structural return to handler_break and advance break.next to the parent. Stack overflow-undo and stack-copy paths differ. A restored active frame is not the same physical cell as the retained heap source.";
  attribute :>> required="Static service retry reads S while it is still the next structural frame, before break handling consumes that edge. Fixed grant/abandon or ordinary return follows its original protocol; final landing restoration and extra S copies remain costs. Captured dispatcher ancestry must carry the correct S across repeated restoration.";
  attribute :>> gap="Actual multi-shot, nested dispatch and cross-context corridor traces are absent. Reject an optimization admission that cannot preserve the structural S association; do not reject the Scheme program or invent a current-thread environment.";
  ref part :>> question=cutSource;
 }
 part completionCallableExposure:SourceSite {
  attribute :>> id="completionCallableExposure";
  attribute :>> artifact="vendor/gambit/include/_gambit/module_generation.h.in";
  attribute :>> anchor="#define ___CLOSUREREF";
  attribute :>> role="request-service-design";
  attribute :>> observed="CLOSUREREF/SET directly access free fields; kernel also exposes closure length/code and procedure->continuation uses a free-field convention. Thread.resume-thunk and dispatcher's saved thunk can expose captured callable identity/operands. No current interception implements lazy reification.";
  attribute :>> required="Use static resume only for a proven supported use set or after all exposure adapters preserve callable identity, sharing, field mutation and invocation. Otherwise retain the original closure, including future possible exposure not just already-observed reads. No generic stateless proc substituted for an extracted closure.";
  attribute :>> gap="Whole open-world escape proof and all exposure adapters are unavailable; eligible count may be zero. A hypothetical lazy constructor is not a completed compatibility mechanism or allocation saving.";
  ref part :>> question=aliasSource;
 }
 part completionStructuralRoots:SourceSite {
  attribute :>> id="completionStructuralRoots";
  attribute :>> artifact="vendor/gambit/lib/_mem/continuation-roots.inc";
  attribute :>> anchor="___BOOL ___root_task_scan_stack";
  attribute :>> role="request-service-design";
  attribute :>> observed="ROOT_STACK scans task.origin.source.stack, then active and captured break ancestry; captured stack references use dedicated frame handling, not ordinary fixnum tracing. Census dispatch, frame forwarding and ordinary/structural slots already have separate paths.";
  attribute :>> required="S must always lie in a qualified existing structural root path before publication and while dispatch is exposed. No untyped extra fixnum root or side registry. Stack S becomes heap FRAME and canonical incoming links are repaired; decode afresh after each legal GC. W<R uses source context, never carrier identity.";
  attribute :>> gap="Generated complete-frame reserve/publication, all ingress/egress structural paths and source exit remain native premises. Collector frame_gate does not itself freeze mutator/reflective writers.";
  ref part :>> question=cutSource;
 }
 part completionLandingSpec:SourceSite {
  attribute :>> id="completionLandingSpec";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-3.scm";
  attribute :>> anchor="(define (targ-make-frame-spec kind fs link gc-map)";
  attribute :>> role="request-service-design";
  attribute :>> observed="FrameSpec validates kind, stored/actual size, link and bitmap after semantic liveness; normal/internal frame sizes differ. Existing caller operands need not have the same alias lifetime as a lexical resume environment.";
  attribute :>> required="Scheme owns a private wait-frame snapshot completion cell, structural caller link, retry/return PointIds and live result/checkpoint maps; C owns physical size/reserve and decode. No hardcoded slot reuse, new fixed pool, one-shot conversion or zero extra frame-size assumption.";
  attribute :>> gap="S FrameSpec/HostGraph lowering is proposed, not emitted. Extra frame footprint/restoration and retained user graphs can outweigh saved closure/capture work; preserve census and original budgets.";
  ref part :>> question=cutSource;
 }
 part completionDebugExposure:SourceSite {
  attribute :>> id="completionDebugExposure";
  attribute :>> artifact="vendor/gambit/lib/_repl.scm";
  attribute :>> anchor="(define-prim (##hidden-continuation? cont)";
  attribute :>> role="request-service-design";
  attribute :>> observed="REPL hidden-continuation? returns false when show-all is enabled; variable lookup reads continuation-ref by debug slot descriptors. Hidden-frame filtering is not root invisibility or a closed callable/slot use set.";
  attribute :>> required="Adapt logical debug slots/parents or retain generic frames for supported exposure. Debug settings cannot be a covert performance admission toggle or a reason to erase live Scheme values.";
  attribute :>> gap="No S logical-debug projection exists. Suppressing display or naming a frame private does not preserve inspection/mutation semantics.";
  ref part :>> question=aliasSource;
 }
 part completionSerializedExposure:SourceSite {
  attribute :>> id="completionSerializedExposure";
  attribute :>> artifact="vendor/gambit/lib/_io.scm";
  attribute :>> anchor="(define-prim (##implode-frame re fields)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Frame explode consults fs/live slots; implode makes a frame and writes cells. Closure explode reads free fields/code; implode recreates a closure and resolves field fixups. sys.scm's serializer also follows continuation descriptors/structural links and shares object identities.";
  attribute :>> required="Preserve graph sharing, module/PointId metadata and logical captured payload through serialization/rebuild, or leave affected cohorts generic. Never serialize ephemeral scheduler membership/query pins as authority; validate rebuilt frames before execution.";
  attribute :>> gap="No serializer/debugger round-trip or callable projection is supplied by existing frame construction. Rebuilt metadata/aliases and all failure paths need native validation.";
  ref part :>> question=aliasSource;
 }
 part completionFrameFlow0:Flow { ref part :>> producer=control; ref part :>> consumer=roots; attribute :>> contract="Repair9: proposed private snapshot frame S keeps closure-value aliasing distinct from mutable caller slots"; }
 part completionFrameFlow1:Flow { ref part :>> producer=execution; ref part :>> consumer=control; attribute :>> contract="Repair9: static retry validates structural next S before break restore; fixed outcome and user return keep their own paths"; }
 part completionFrameFlow2:Flow { ref part :>> producer=collector; ref part :>> consumer=execution; attribute :>> contract="Repair9: S forwarding/ancestry repair and fresh decode preserve the same logical payload across GC, not raw addresses"; }
 part completionFrameFlow3:Flow { ref part :>> producer=control; ref part :>> consumer=qualification; attribute :>> contract="Repair9: proven callable exposure and extra S restoration cost gate closure/capture removal; generic fallback remains counted"; }
}
