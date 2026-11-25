/* Model-owned refinements/continuation-and-domain declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpContinuationDomainRefinement {
 private import GambitSharedHeapSmp::*;

 part sharedGraphIdentity:SourceCase {
  attribute :>> id="sharedGraphIdentity";
  attribute :>> precondition="Same admitted sharing domain and complete authoritative root/field locations; identity mapping injective on live objects; semantic stores distinguished from physical relocation";
  attribute :>> argument="kernel continuation-copy reads frame and denv into a new wrapper rather than cloning their graph. Frame/continuation/denv setters and restores can observe shared cells. Region movement must preserve this graph observation while updating every actual reference, not merely retaining referent liveness.";
  attribute :>> conclusion="Sharing semantics and physical placement are separate modeled roles. Existing Lean alias/forwarding laws supply conditional data obligations; they do not prove actual source-slot coverage or a new regional collector.";
  attribute :>> missing="Classify all captured/active/native aliases and mature-to-young stores; bind physical maps to FrameSpec and source writers. No per-region privacy or cross-VM identity equivalence follows from placement or wrapper copy.";
  attribute :>> acceptance="One whole map/closure/shared-cell case captures, mutates and restores multiple shots across collection, including frame reflection and FFI roots; explicit domain-transfer policy preserves or deliberately specifies different identity semantics before transfer.";
  attribute :>> formalBoundary="Reuse existing RelocationSlots data laws and SH-ALIAS-S source ownership; do not add QNT graph/isomorphism lemmas or another Lean control protocol.";
  attribute :>> counterexample="Copying a mutable environment on each shot changes shared state; finding a live object without every actual reference permits a stale address after movement.";
  ref part :>> clause=aliasReentry;
  ref part :>> entrySite=copyAlias;
  ref part :>> exitSite=frameConsumer;
 }
 part crossDomainControlCustody:SourceCase {
  attribute :>> id="crossDomainControlCustody";
  attribute :>> precondition="Sharing-domain identity, collection epoch and native/resource dependencies remain live; source protection precedes target installation; each shot has valid execution and root grants";
  attribute :>> argument="_thread continuation-graft-aux and continuation-return-aux compare current/captured dynwind and call continuation-unwind-wind before their no-winding successor when required; both conditional source implementations must retain this behavior. setup ___call and ___run enter lifecycle, establish catcher/marker state and leave after TRY cleanup; generated SFUN END variants end their scope before propagate_error. run_startup_root and the initial setup ___run path are distinct inputs. RC borrow checks PSTATE/source domain and yields a canonical cell, not foreign-domain or concurrent-relocation authority. Each retained map shot reloads roots and reacquires execution without consuming the logical continuation or rolling back shared effects.";
  attribute :>> conclusion="Same-domain scheduling movement, region relocation and cross-VM control transfer are separate operations. A future transfer needs target installation before source ACK plus independent raw-access parking/reload and resource affinity; no new generic token table or one-shot restriction is introduced.";
  attribute :>> missing="Actual per-captured-control collection/resource dependencies, all FFI/raw-pointer writers, nested callback/exception exits and every per-shot reentry consumer need source closure. Cross-VM data copy/immutable sharing/handles must be explicit; arbitrary closure/native activation transfer remains unsupported.";
  attribute :>> acceptance="Qualify admitted same-VM multi-shot restore and nested native callbacks with wind order, zero/one/two/three/extra values, conversion failure, caught and propagated error, expired C return marker and source owner exit. A completed request cannot release captured frame/denv or native last users. Trace both startup entry routes and all selected SFUN result variants. Cross-VM raw closure/continuation transfer stays outside this packet; any future transfer needs an explicit copy/share/handle/resource policy before effects.";
  attribute :>> formalBoundary="Consume existing QNT install/borrow/close/unknown-return slices and Lean slot identity laws; SH-BOUNDARY-S owns actual control/native semantics. No claim of a proved regional migration algorithm or duplicate temporal/data theorem.";
  attribute :>> counterexample="Freeing request-local objects while a multi-shot wrapper/native loan retains them causes stale access. A lifetime count alone permits a racing raw read during movement. A copied closure or replayed wind hook cannot silently replace the original shared/resource effect.";
  ref part :>> clause=domainReentry;
  ref part :>> entrySite=nativeEntry;
  ref part :>> exitSite=restoreWinding;
 }
 part canonicalSlotBatch:SourceCase {
  attribute :>> id="canonicalSlotBatch";
  attribute :>> precondition="Frozen admitted logical slot set, stable before-view and before/after location maps for moving containers; reserved live forwarding identities and injective committed destination intervals. Intermediate payload initialization debt remains owned; initialized payloads are required at observation, not assumed before the early cell repair; all root stores governed";
  attribute :>> argument="mark_rc calls mark_array(work,&h->data,1); bank/VM/global/symkey scanners pass actual canonical ranges; captured-frame forwarding updates orig_ptr and logical frame coordinates. A successful canonical cell repair must equal forward(before slot). Existing forwarding or destination revisits reuse that target without acquiring initialization/Tail debt. rewriteBatchAt and batchCoverageProducesRewrittenOn derive whole-view rewriting from per-store correctness plus complete slot coverage; existing equalityObservationPreserved then preserves aliases.";
  attribute :>> conclusion="The algebraic coverage implication and duplicate-slot idempotence are kernel-checkable in the existing Lean artifact; they do not prove that C enumerates every live root or writes the specified target";
  attribute :>> missing="Connect _t-c-3 targ-make-frame-spec and continuation-roots mark_frame/mark_continuation to the same stack/heap/internal-return coordinates. continuation-copy in _kernel copies the wrapper's frame and denv fields, so it does not detach their aliases; frame-set!, continuation-frame-set!, continuation-denv-set!, continuation-next! and _io implode-frame need the same logical-revision and freeze admission. Interrupt masking alone is not cross-core writer exclusion. C-to-logical coverage, weak/strong slot classification and live-target injectivity remain open; early forwarding is not initialized-payload proof.";
  attribute :>> acceptance="Retain the current precise FrameSpec root bitmap and root-task stack scanner. Audit every listed writer, reconstruct internal/normal-return frames and duplicate wrappers sharing a frame; compare two restores and shared mutations with wind/multiple-value observations. Use an independent rooted referent to expose a stale source slot even when the object survives. Reject a missed slot without accepting reachable-target-set equivalence. Keep all copy/Tail initialization debt until the actual repaired observation cut.";
  attribute :>> formalBoundary="Lean proves data updates and coverage only. Source must establish each C store denotes this update; QNT owns when aggregate work and raw readers permit observation. No second GC state machine is introduced.";
  attribute :>> counterexample="A set of reachable target objects can be complete while one source alias remains stale; two wrappers sharing one frame do not imply two independent frame objects. Reapplying forward to a destination address is not justified by logical idempotence unless C forwarding/destination tests implement the same canonical target.";
  ref part :>> clause=aliasPublish;
  ref part :>> entrySite=copyAlias;
  ref part :>> exitSite=frameConsumer;
 }
}
