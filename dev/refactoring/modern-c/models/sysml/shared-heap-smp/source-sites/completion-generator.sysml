/* Generator refinement uses the existing freeze adapter, not another owner. */
package GambitSharedHeapSmpCompletionGenerator {
 private import GambitSharedHeapSmp::*;
 part completionFrontProducer:SourceSite {
  attribute :>> id="completionFrontProducer";
  attribute :>> artifact="vendor/gambit/gsc/_front.scm";
  attribute :>> anchor="(define (gen-return-label node return-lbl dead-end-lbl live result-var)";
  attribute :>> role="request-service-design";
  attribute :>> observed="current-frame/context->frame freeze current slots/regs/closed with supplied live set. gen-call chooses specialized/inlinable procedure handling; gen-return-label adjoins result-var and attaches that frame to generated return labels/jumps.";
  attribute :>> required="Recognize only admitted completion semantics in gen-call/role lowering, preserve argument evaluation/reason/tail/result behavior, and make future static decode/exposure real semantic uses before current-frame is attached. A hidden runtime use or metadata annotation alone cannot keep M0 live.";
  attribute :>> gap="No S frontend role/effect lowering exists. Generic helper fallback, ordinary Scheme return values and proper tail behavior cannot be inferred from a backend bitmap edit.";
  ref part :>> question=cutSource;
 }
 part completionGvmLiveness:SourceSite {
  attribute :>> id="completionGvmLiveness";
  attribute :>> artifact="vendor/gambit/gsc/_gvm.scm";
  attribute :>> anchor="(define (make-frame size slots regs closed live)";
  attribute :>> role="request-service-design";
  attribute :>> observed="GVM frame stores size/slots/regs/closed/live. frame-live? keeps closure-env-var when any closed variable is live. Target instruction scanning takes entry/exit frames from attached GVM metadata; merely deleting a C closure allocation does not recompute that semantic state.";
  attribute :>> required="Introduce S lexical snapshot, caller link, return/retry roles and all snapshot temporaries before semantic liveness freezes; propagate them through actual GVM frames and then physical FrameSpec. Preserve alias semantics and control behavior, not old numeric slots.";
  attribute :>> gap="No S semantic lowering exists; inherited closure-env liveness, saved-register maps and raw exposure may still require original roots. No register-deadness claim follows from a minimal frame bitmap.";
  ref part :>> question=cutSource;
 }
 part completionReturnDescriptors:SourceSite {
  attribute :>> id="completionReturnDescriptors";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(define (targ-gen-label-return* lbl kind)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Normal return derives fs, ret-var link and live-slot map. Internal check return extends aligned slots with saved GVM registers and marks all saved registers live. Debug-info-add! has a separate queued side effect later consumed by debug-info-generate; its ignored helper parameter does not prove debug data lost.";
  attribute :>> required="Separate S saved layout, check RETI extension and final return/result maps. Maintain exact slot/ret-var/debug-label correspondence for every generated point; no constant fs guess or bitmap-only root proof.";
  attribute :>> gap="Proposed S/check/final-return frames and debug logical projection are not generated or round-trip-qualified; declaration validation is not liveness completeness.";
  ref part :>> question=cutSource;
 }
 part completionSaveEmission:SourceSite {
  attribute :>> id="completionSaveEmission";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(targ-jump-inline \"##thread-save!\"";
  attribute :>> role="request-service-design";
  attribute :>> observed="SAVE inlining performs end-of-block checks, stack adjustment and resource effects before the macro. A normal Scheme helper or extra check can invalidate FP=break/R0=handler assumptions. POLL/HEAP checks produce internal-return control and may enter runtime handlers.";
  attribute :>> required="Typed generator corridor must preserve selected operand evaluation order: immutable S permits check then decode; mutable supported capture needs value selection into mapped roots before check and repaired reload after. Revalidate structural S after checks; no new poll/adjust/call after final decode and before SAVE fast prefix unless its state transform is proven.";
  attribute :>> gap="There is no emitted typed decode/corridor today. Do not silently disable required polling or hide effects in opaque C to make an invariant appear true.";
  ref part :>> question=cutSource;
 }
 part completionHostPlacement:SourceSite {
  attribute :>> id="completionHostPlacement";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-1.scm";
  attribute :>> anchor="(define (targ-plan-procedure-hosts obj)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Compilation-unit host placement follows semantic scanning; opaque C prevents the procedure planner. Return/CFG splitting are constrained prototypes, not a default optimization guarantee. Physical host/slot feeds DEF_LBL_RET_AT while logical label cells are numbered separately.";
  attribute :>> required="Preserve all local edges/fallthroughs and keep no-GC decode/save corridor intact; attach complete read/write/control effects. Proposed PointId is module-artifact/procedure/logical-point identity, not a current host slot or an already-implemented cross-build stable ID.";
  attribute :>> gap="No S HostGraph effect node, metadata association or placement validation is implemented. No experimental host-layout switch is enabled by this design.";
  ref part :>> question=cutSource;
 }
 part completionPhysicalSpec:SourceSite {
  attribute :>> id="completionPhysicalSpec";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-3.scm";
  attribute :>> anchor="(define (targ-make-frame-spec kind fs link gc-map)";
  attribute :>> role="request-service-design";
  attribute :>> observed="FrameSpec validates kind, stored/actual fs, link and bitmap bounds; internal size expansion differs from normal. Inline versus out-of-line metadata and gcmap chunks are emitted from this one spec.";
  attribute :>> required="Compute S reserve, ordinary/structural slots and every checkpoint from one semantic plan. Size validity, code/module lifetime, field schema and stale native-module admission are distinct requirements. No minimal two-slot or zero reserve overhead assumption.";
  attribute :>> gap="S descriptors, admission record and old-metadata rejection are proposed; source byte equality does not supply a regenerated GCC/C23 producer.";
  ref part :>> question=cutSource;
 }
 part completionRuntimeRepair:SourceSite {
  attribute :>> id="completionRuntimeRepair";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="/* Every source view is complete before the coordinator captures the roster.";
  attribute :>> role="request-service-design";
  attribute :>> observed="Current round barriers precede roster begin/freeze/publish; RootTask/worker assignment then publishes. Frame scanners use source context, rewrite canonical links/slots and separate census/materialization. Ordinary emitter labels/checks are not this synchronization edge.";
  attribute :>> required="S and operand temporaries must be complete before source freeze, remain owned through planning/refusal/unknown scan and reload only after actual repair/restore authorization. Decode fresh stack/heap coordinates and keep all non-frame homes/native aliases accounted for.";
  attribute :>> gap="Selected atomic backend, every emitter ingress/egress, W<R source repair and source exit need native evidence; RootTask DONE alone is not whole-round or resource closure.";
  ref part :>> question=cutSource;
 }
 part completionGeneratorCoverage:AdapterClause {
  attribute :>> id="completionGeneratorCoverage";
  attribute :>> kind="coverage";
  attribute :>> rule="GVM snapshot/link/return liveness and debug roles produce all S/caller/checkpoint roots before C emission; no C-only deletion as semantic lowering";
  attribute :>> missing="S semantic lowering and complete supported ingress/exposure inventory are absent";
  attribute :>> acceptance="Inspect generated positive and generic paths; independent operand/slot oracle catches stale closure-env and omitted register homes";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionFrontProducer;
 }
 part completionGeneratorExclude:AdapterClause {
  attribute :>> id="completionGeneratorExclude";
  attribute :>> kind="exclusion";
  attribute :>> rule="No blocking, allocation, opaque semantic effect or unplanned poll/adjust crosses final frame decode to SAVE; mutable operand evaluation order is preserved";
  attribute :>> missing="No typed effect/corridor emitter or complete writer exclusion is implemented";
  attribute :>> acceptance="Inject legal precheck GC/reflective mutation and overflow; prove no new unchecked raw pointer or changed snapshot value";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionSaveEmission;
 }
 part completionGeneratorPublish:AdapterClause {
  attribute :>> id="completionGeneratorPublish";
  attribute :>> kind="publication";
  attribute :>> rule="Complete generated S/temporaries precede actual source freeze and task publication; post-GC repair/round authorization precedes resume";
  attribute :>> missing="No current-source end-to-end generator/round/repair simulation is qualified";
  attribute :>> acceptance="Trace same-source prefreeze and repaired slots at W<R; known refusal keeps caller roots, unknown work retains the same owned source";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionRuntimeRepair;
 }
 part completionGeneratorReenter:AdapterClause {
  attribute :>> id="completionGeneratorReenter";
  attribute :>> kind="reentry";
  attribute :>> rule="Label/host remapping and fixed grant/user-return routes preserve S ancestry and operand snapshot after check/restore; decode no stale code/data address";
  attribute :>> missing="Nested/multi-shot/overflow/exception and physical-host effects lack a complete emitted adapter";
  attribute :>> acceptance="Restore twice across GC, vary logical sharing, and preserve ordinary user result versus scheduler grant; no N-fold restart assumption";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionHostPlacement;
 }
 part completionGeneratorFailure:AdapterClause {
  attribute :>> id="completionGeneratorFailure";
  attribute :>> kind="failure";
  attribute :>> rule="Choose generic before publication when admission/physical reserve is unqualified; late partial/unknown work needs rooted qualified settlement, never second registration";
  attribute :>> missing="No generated slow/deoptimization landing covers all post-publication cases";
  attribute :>> acceptance="Fail reserve/check/module binding and lose commit returns; keep roots/ancestry and original budgets; no retry of opaque hooks or user request";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionPhysicalSpec;
 }
 part completionGeneratorValidate:AdapterClause {
  attribute :>> id="completionGeneratorValidate";
  attribute :>> kind="validation";
  attribute :>> rule="Same-cohort GVM, FrameSpec, debug/serializer maps, C descriptors and native slot/cost observations agree; named points alone never sign admission";
  attribute :>> missing="No regenerated S emitter or native original-load performance/capacity campaign exists";
  attribute :>> acceptance="Existing map/PBT and original360-million-request populations compare useful completions, exclusive work, new frame/check/lookup overhead and peak under unchanged limits";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionReturnDescriptors;
 }
 part completionGeneratorRefinement:SourceCase {
  attribute :>> id="completionGeneratorRefinement";
  attribute :>> precondition="One bound generator/runtime artifact cohort; admitted alias/exposure contracts; complete GVM operands/frames and selected synchronization/backend/physical budget; all unsupported paths generic before publication";
  attribute :>> argument="Scheme produces S lexical snapshot and return/retry roles before liveness. Normal/check frames and debug queues feed one physical spec; checks preserve selected values in canonical roots. After checks a typed no-GC decode/save corridor preserves actual source S, while host placement preserves effects/edges. Actual roster publication and source-based scanning rewrite every canonical root; repaired reload, ordinary return and existing grant/exit ownership preserve the source relation. Every step either refines that relation, performs declared Scheme control, or retains an explicit unqualified/unknown obligation.";
  attribute :>> conclusion="A complete generator-to-consumer refinement/admission plan is specified without a second semantic emitter, parallel root namespace or a native pass claim";
  attribute :>> missing="S producer, typed corridor, logical debug/serialization/exposure adapters, all slow exits and full same-cohort native observations remain absent";
  attribute :>> acceptance="The one five-gate campaign validates generated and fallback paths, snapshot order, GC repair, multi-shot/control effects, old metadata rejection and original workload/cost/peak; preserve counterexamples and historical PR failure separately";
  attribute :>> formalBoundary="Source case only: existing QNT owns interleavings/unknown histories and Lean owns slot/representation/interval laws; this is not a second temporal/algebra proof or mechanized C refinement";
  attribute :>> counterexample="Compiler inserts check/stack adjust after raw decode, mutable snapshot changes across poll, RETI register root omitted, host split loses local edge, stale logical point accepted or task DONE used as exit permit";
  ref part :>> clause=completionGeneratorPublish;
  ref part :>> entrySite=completionFrontProducer;
  ref part :>> exitSite=completionRuntimeRepair;
 }
 part completionGeneratorFlow0:Flow { ref part :>> producer=control; ref part :>> consumer=execution; attribute :>> contract="Repair9: GVM semantic S/checkpoint plan precedes physical FrameSpec and host placement; no C-only closure deletion"; }
 part completionGeneratorFlow1:Flow { ref part :>> producer=execution; ref part :>> consumer=roots; attribute :>> contract="Repair9: operand snapshot/check/reload and typed no-GC corridor preserve complete canonical sources"; }
 part completionGeneratorFlow2:Flow { ref part :>> producer=roots; ref part :>> consumer=collector; attribute :>> contract="Repair9: actual roster barriers publish S to source-based GC; labels and emitter checks do not synchronize workers"; }
 part completionGenericRegistration:SourceSite {
  attribute :>> id="completionGenericRegistration";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##mutex-wait! mutex timeout new-owner)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Capture and self-resume closure precede thread-park and registration; registration uses physical current Thread but captured logical owner remains independent.";
  attribute :>> required="Generic selection before publication or settled same-registration representation transfer; no restarting mutex-wait after committed registration.";
  attribute :>> gap="No S-to-generic conversion or same-registration late exposure settlement is implemented.";
  ref part :>> question=cutSource;
 }
 part completionGenericPark:SourceSite {
  attribute :>> id="completionGenericPark";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim ##thread-park!";
  attribute :>> role="request-service-design";
  attribute :>> observed="Portable fallback copies wait, sets current denv, grafts without winding, saves and applies registration callback.";
  attribute :>> required="Preserve same selected logical wait and denv; complete root publication before any collecting call and reload repaired operands.";
  attribute :>> gap="Existing portable fallback is not an adapter from S; old helper invocation can duplicate registration/control work.";
  ref part :>> question=cutSource;
 }
 part completionReflectiveMutation:SourceSite {
  attribute :>> id="completionReflectiveMutation";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##frame-set! frame i val)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Raw heap frame store uses decoded return metadata and fs-i+1; no S revocation or logical cell conversion is performed.";
  attribute :>> required="Preserve captured-cell alias and selected-value order through typed projection/write admission or use generic before unsupported exposure.";
  attribute :>> gap="Raw frame and closure access bypasses proposed logical S projection; collector gate alone is not mutator exclusion.";
  ref part :>> question=cutSource;
 }
 part completionSerializeGraph:SourceSite {
  attribute :>> id="completionSerializeGraph";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="(serialize! (closure-ref obj i))";
  attribute :>> role="request-service-design";
  attribute :>> observed="Closure/frame/continuation serialization uses subprocedure metadata, live slots, denv, links and alloc/share graph identity; Thread/tgroup/mutex/condvar structures are rejected. Preserve existing cannot-serialize outcomes as well as successful graphs.";
  attribute :>> required="Qualified logical projection preserves code/cell/graph identity; no live registration is serialized as a reusable queue claim.";
  attribute :>> gap="No S logical graph and late conversion encoding exists; alpha cannot be inferred from benchmark absence of serialization.";
  ref part :>> question=cutSource;
 }
 part completionRebuildGraph:SourceSite {
  attribute :>> id="completionRebuildGraph";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="((fx= x (frame-tag))";
  attribute :>> role="request-service-design";
  attribute :>> observed="Deserialization allocates frame by subprocedure, registers identity, then fills live slots with decoded values and dead slots with zero.";
  attribute :>> required="Publish executable state only after full reconstruction, root repair and descriptor validation; restored shot must not recreate an old registration.";
  attribute :>> gap="Partial graph fixups and S reconstruction admission are unqualified; current frame reconstruction has disabled validation checks. New S validation is not inherited, and malformed metadata is not repaired by generic fallback.";
  ref part :>> question=cutSource;
 }
 part completionExplodeGraph:SourceSite {
  attribute :>> id="completionExplodeGraph";
  attribute :>> artifact="vendor/gambit/lib/_io.scm";
  attribute :>> anchor="(define-prim (##implode-frame re fields)";
  attribute :>> role="request-service-design";
  attribute :>> observed="Explode/implode expose frame return point and physical slots; implode uses make-frame and frame-set; closure explode exposes code/environment.";
  attribute :>> required="Integrate both IO and system graph consumers into one alias/code/slot contract; generic before unsupported exposure or qualified conversion.";
  attribute :>> gap="Neither physical consumer implements S logical projection or escaped alias redirection.";
  ref part :>> question=cutSource;
 }
 part completionFallbackCoverage:AdapterClause {
  attribute :>> id="completionFallbackCoverage";
  attribute :>> kind="coverage";
  attribute :>> rule="One semantic operation emits qualified static and complete generic branches with exact operands/frame maps and all exposure exits";
  attribute :>> missing="S admission producer, both lowerings and full use coverage absent";
  attribute :>> acceptance="Inspect actual emitted roots/effects and independent slot oracle, not macro-name absence";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionGenericRegistration;
 }
 part completionFallbackExclude:AdapterClause {
  attribute :>> id="completionFallbackExclude";
  attribute :>> kind="exclusion";
  attribute :>> rule="Unsupported late writes/exposure must be excluded by real capability/alias coverage or converted, not assumed absent";
  attribute :>> missing="No complete logical writer projection or closed-scope admission";
  attribute :>> acceptance="Mutate captured cell across poll and retain independent aliases; no source pointer across GC";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionReflectiveMutation;
 }
 part completionFallbackPublish:AdapterClause {
  attribute :>> id="completionFallbackPublish";
  attribute :>> kind="publication";
  attribute :>> rule="Destination GC visibility precedes execution/registration authority; transfer then ACK preserves same registration";
  attribute :>> missing="No partial-conversion publication and query/ACK implementation";
  attribute :>> acceptance="Inject collecting allocation, lost commit result and concurrent freeze; source stays rooted until known successor";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionGenericPark;
 }
 part completionFallbackReenter:AdapterClause {
  attribute :>> id="completionFallbackReenter";
  attribute :>> kind="reentry";
  attribute :>> rule="Restore/rebuild preserves logical sharing, fresh physical coordinates and shot-local registration authority";
  attribute :>> missing="Multi-shot S/round-trip/slow landing adapters absent";
  attribute :>> acceptance="Two shots across GC plus graph-sharing round-trip; no one-shot or duplicate registration";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionRebuildGraph;
 }
 part completionFallbackFailure:AdapterClause {
  attribute :>> id="completionFallbackFailure";
  attribute :>> kind="failure";
  attribute :>> rule="Unknown conversion/registration retains both roots and query-settles same operation; no helper replay";
  attribute :>> missing="Settlement and last-reader/exit custody unqualified";
  attribute :>> acceptance="Precommit refusal, late return, exception and partial transfer preserve one outcome and original budgets";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionGenericRegistration;
 }
 part completionFallbackValidate:AdapterClause {
  attribute :>> id="completionFallbackValidate";
  attribute :>> kind="validation";
  attribute :>> rule="Count entry alpha separately from complete closure elimination; debit S, roots, late conversion and peak";
  attribute :>> missing="No alpha/cost or full native campaign";
  attribute :>> acceptance="Report E=G+A, Q<=A, L,F,M,U,Kq and signed matched total cost, malformed metadata and generic controls";
  ref part :>> adapter=freezeAdapter; ref part :>> site=completionSerializeGraph;
 }
 part completionFallbackRefinement:SourceCase {
  attribute :>> id="completionFallbackRefinement";
  attribute :>> precondition="Complete semantic operands, bound module cohort and qualification over all supported alias/exposure/shot/exit paths; actual source/registration authority and physical reserve";
  attribute :>> argument="Before publication absent qualification chooses generic. Complete rooted S may transfer to a fully rooted non-executable destination, then settle the same registration/shot and publish authority before ACK. GC repair reloads canonical homes. Late exposure preserves cell/graph identity through qualified projection or settled conversion; lost result retains source/destination for query, never helper replay. Each physical restore decodes fresh coordinates without changing logical sharing. Entry and eliminated populations remain distinct and all replacement costs are debited.";
  attribute :>> conclusion="One source-refined admission/fallback and signed-cost implementation boundary, not a native correctness or performance pass";
  attribute :>> missing="Static/generic joint lowering, late conversion/query, exposure/rebuild adapters and original-load implementation observations absent";
  attribute :>> acceptance="One five-gate map/PBT/original-load campaign covers pre/postcommit, aliases, two restores, serializer sharing, UNKNOWN exits and signed costs under unchanged budgets";
  attribute :>> formalBoundary="Existing QNT exclusively owns partial/unknown/retirement histories; existing Lean exclusively owns slot/alias/representation/interval laws; no duplicate proof";
  attribute :>> counterexample="Restart mutex-wait after commit duplicates enqueue; deserialize reuses live queue claim; late facade breaks alias identity; alpha_enter credited as closure removal despite later allocation; half-filled destination becomes executable";
  ref part :>> clause=completionFallbackPublish; ref part :>> entrySite=completionFrontProducer; ref part :>> exitSite=completionRebuildGraph;
 }
 part completionFallbackFlow0:Flow { ref part :>> producer=control; ref part :>> consumer=execution; attribute :>> contract="Repair9: choose complete generic/static semantic lowering before S publication; no unsupported late helper replay"; }
 part completionFallbackFlow1:Flow { ref part :>> producer=execution; ref part :>> consumer=roots; attribute :>> contract="Repair9: root destination before same-registration authority transfer and ACK; UNKNOWN retains both graphs"; }
 part completionFallbackFlow2:Flow { ref part :>> producer=roots; ref part :>> consumer=collector; attribute :>> contract="Repair9: conversion and rebuilt multi-shot graphs preserve canonical roots, fresh repair and graph identity"; }
 part completionFallbackFlow3:Flow { ref part :>> producer=control; ref part :>> consumer=retirement; attribute :>> contract="Repair9: query settles one conversion/registration; entry alpha is not eliminated-closure or exit credit"; }
}
