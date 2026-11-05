import ConverterPrivateSteps
import ConverterArgumentSteps
import ConverterResultSteps
import ConverterEscapeSteps
import ConverterMarkerSteps
import ConverterPayloadSteps
import ConverterRetirementSteps
namespace ConverterUse
open ConverterUseAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by
 rcases g with g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g|g
 · exact g.2.symm ▸ reservePrivatePreserves q h g.1
 · exact g.2.symm ▸ beginWrapPreserves q h g.1
 · exact g.2.symm ▸ wrapSuccessPreserves q h g.1
 · exact g.2.symm ▸ wrapFailureReturnedPreserves q h g.1
 · exact g.2.symm ▸ wrapFailureUnknownPreserves q h g.1
 · exact g.2.symm ▸ auditPrivateDisposedPreserves q h g.1
 · exact g.2.symm ▸ bodyBadResultPreserves q h g.1
 · exact g.2.symm ▸ bodyGoodResultPreserves q h g.1
 · exact g.2.symm ▸ captureArgumentPreserves q h g.1
 · exact g.2.symm ▸ dropInputReferencePreserves q h g.1
 · exact g.2.symm ▸ handlerCallPreserves q h g.1
 · exact g.2.symm ▸ handlerBadResultPreserves q h g.1
 · exact g.2.symm ▸ handlerGoodResultPreserves q h g.1
 · exact g.2.symm ▸ finishResultPreserves q h g.1
 · exact g.2.symm ▸ signFinalUsePreserves q h g.1
 · exact g.2.symm ▸ escapeOwnerPreserves q h g.1
 · exact g.2.symm ▸ drainInputFromGuardPreserves q h g.1
 · exact g.2.symm ▸ ackExitedOwnerPreserves q h g.1
 · exact g.2.symm ▸ signEscapedUsePreserves q h g.1
 · exact g.2.symm ▸ beginMarkerReleasePreserves q h g.1
 · exact g.2.symm ▸ markerDropPreserves q h g.1
 · exact g.2.symm ▸ commitMarkerReleasePreserves q h g.1
 · exact g.2.symm ▸ loseReplyPreserves q h g.1
 · exact g.2.symm ▸ queryReplyPreserves q h g.1
 · exact g.2.symm ▸ dropCapturedPreserves q h g.1
 · exact g.2.symm ▸ beginDestructorPreserves q h g.1
 · exact g.2.symm ▸ destructorReturnedPreserves q h g.1
 · exact g.2.symm ▸ destructorUnknownPreserves q h g.1
 · exact g.2.symm ▸ beginGcPreserves q h g.1
 · exact g.2.symm ▸ finishGcPreserves q h g.1
 · exact g.2.symm ▸ retireRootsPreserves q h g.1
 · exact g.2.symm ▸ retireCodePreserves q h g.1
 · simpa [g] using h
inductive Reachable : State → Prop where
 | init : Reachable initial
 | next {q t : State} : Reachable q → Step q t → Reachable t
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | init => exact initialSafe
 | next _ step ih => exact stepPreserves _ _ ih step
theorem inputDropKeepsPayload (q : State) (h : Safe q) (g : q.phase=5 ∧ q.dtor=0) : q.inputRef=0 ∧ q.marker=1 ∧ q.valid=1 := by grind [Safe]
theorem closureDischargesNativeUse (q : State) (h : Safe q) (g : q.receipt=1) : q.inputRef=0 ∧ q.privateCopy=0 ∧ q.active=0 ∧ q.valid=0 ∧ q.gate=0 := by grind [Safe]
theorem unknownPrivateHasCustodian (q : State) (h : Safe q) (g : q.phase=9) : q.privateCopy=1 ∧ q.marker=1 ∧ q.roots=1 ∧ q.code=1 ∧ q.receipt=0 := by grind [Safe]
theorem unknownEscapeNoClosure (q : State) (h : Safe q) (g : q.phase=13) : q.marker=1 ∧ q.receipt=0 ∧ q.valid=1 := by grind [Safe]
theorem privateAndWrappedExclusive (q : State) (h : Safe q) (g : q.payload=1) : q.privateCopy=0 ∧ q.code=1 ∧ q.roots=1 := by grind [Safe]
theorem captureRetainsPayload (q : State) (h : Safe q) (g : q.captured=1) : q.payload=1 ∧ q.code=1 ∧ q.roots=1 := by grind [Safe]
theorem unknownDestructorKeepsCode (q : State) (h : Safe q) (g : q.dtor=2) : q.payload=1 ∧ q.code=1 ∧ q.roots=1 := by grind [Safe]
theorem markerEffectGap (q : State) (h : Safe q) (g : q.phase=10) : q.critical=1 ∧ q.gc=0 ∧ q.effects=1 ∧ q.settled=0 := by grind [Safe]
theorem noRepeatedMarkerDrop (q : State) (h : Safe q) (g : q.settled=1) : q.effects=1 ∧ q.marker=0 := by grind [Safe]
theorem codeRetirementCut (q : State) (h : Safe q) (g : q.code=0) : q.payload=0 ∧ q.privateCopy=0 ∧ q.captured=0 ∧ q.gc=0 ∧ q.settled=1 := by grind [Safe]
theorem argumentDropIsNotDestruction (q : State) : (dropInputReferenceNext q).payload=q.payload ∧ (dropInputReferenceNext q).dtor=q.dtor := by exact ⟨rfl,rfl⟩
theorem closureDoesNotDestroyPayload (q : State) : (signFinalUseNext q).payload=q.payload ∧ (signFinalUseNext q).code=q.code := by exact ⟨rfl,rfl⟩
theorem queryDoesNotRepeatDrop (q : State) : (queryReplyNext q).marker=q.marker ∧ (queryReplyNext q).effects=q.effects := by exact ⟨rfl,rfl⟩
end ConverterUse
