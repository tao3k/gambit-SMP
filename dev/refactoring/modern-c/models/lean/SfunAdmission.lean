import SfunAdmissionEntry
import SfunAdmissionMarker
import SfunAdmissionConversion
import SfunAdmissionRecovery
import SfunAdmissionCleanup
import SfunAdmissionDomain
import SfunAdmissionLegacy
open SfunAdmissionAst
namespace SfunAdmission
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27
 · rcases h0 with ⟨g,rfl⟩
   exact refuseBeforeEntryPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact exhaustPoolPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact refuseNoRecordPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact reserveGuardPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact ackHandoffPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact cancelBeforeAckPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact allocateMarkerPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact markerFailurePreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact beginBodyPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact conversionFailurePreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact opaqueConversionFailurePreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact finishSuccessPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact callRefusedPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact handlerRefusedPreserves q h g
 · rcases h14 with ⟨g,rfl⟩
   exact recoverGoodPreserves q h g
 · rcases h15 with ⟨g,rfl⟩
   exact recoverBadPreserves q h g
 · rcases h16 with ⟨g,rfl⟩
   exact outerThrowPreserves q h g
 · rcases h17 with ⟨g,rfl⟩
   exact releaseMarkerPreserves q h g
 · rcases h18 with ⟨g,rfl⟩
   exact closeGuardPreserves q h g
 · rcases h19 with ⟨g,rfl⟩
   exact dropRefusedSourcePreserves q h g
 · rcases h20 with ⟨g,rfl⟩
   exact deliverPreserves q h g
 · rcases h21 with ⟨g,rfl⟩
   exact closeDomainPreserves q h g
 · rcases h22 with ⟨g,rfl⟩
   exact resumeDomainPreserves q h g
 · rcases h23 with ⟨g,rfl⟩
   exact legacyMarkerSuccessPreserves q h g
 · rcases h24 with ⟨g,rfl⟩
   exact legacyRejectCallPreserves q h g
 · rcases h25 with ⟨g,rfl⟩
   exact legacyErrorRetryPreserves q h g
 · rcases h26 with ⟨g,rfl⟩
   exact legacyMarkerFailurePreserves q h g
 · rcases h27 with rfl
   exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | advance {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | advance h step ih => exact stepPreserves _ _ ih step
theorem modePreserved (q r : State) (hs : Step q r) : r.managed=q.managed := by
 unfold Step at hs
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16 | h17 | h18 | h19 | h20 | h21 | h22 | h23 | h24 | h25 | h26 | h27
 · rcases h0 with ⟨_,rfl⟩
   rfl
 · rcases h1 with ⟨_,rfl⟩
   rfl
 · rcases h2 with ⟨_,rfl⟩
   rfl
 · rcases h3 with ⟨_,rfl⟩
   rfl
 · rcases h4 with ⟨_,rfl⟩
   rfl
 · rcases h5 with ⟨_,rfl⟩
   rfl
 · rcases h6 with ⟨_,rfl⟩
   rfl
 · rcases h7 with ⟨_,rfl⟩
   rfl
 · rcases h8 with ⟨_,rfl⟩
   rfl
 · rcases h9 with ⟨_,rfl⟩
   rfl
 · rcases h10 with ⟨_,rfl⟩
   rfl
 · rcases h11 with ⟨_,rfl⟩
   rfl
 · rcases h12 with ⟨_,rfl⟩
   rfl
 · rcases h13 with ⟨_,rfl⟩
   rfl
 · rcases h14 with ⟨_,rfl⟩
   rfl
 · rcases h15 with ⟨_,rfl⟩
   rfl
 · rcases h16 with ⟨_,rfl⟩
   rfl
 · rcases h17 with ⟨_,rfl⟩
   rfl
 · rcases h18 with ⟨_,rfl⟩
   rfl
 · rcases h19 with ⟨_,rfl⟩
   rfl
 · rcases h20 with ⟨_,rfl⟩
   rfl
 · rcases h21 with ⟨_,rfl⟩
   rfl
 · rcases h22 with ⟨_,rfl⟩
   rfl
 · rcases h23 with ⟨_,rfl⟩
   rfl
 · rcases h24 with ⟨_,rfl⟩
   rfl
 · rcases h25 with ⟨_,rfl⟩
   rfl
 · rcases h26 with ⟨_,rfl⟩
   rfl
 · rcases h27 with rfl
   rfl
theorem reachableManaged (q : State) (h : Reachable q) : q.managed=1 := by
 induction h with
 | start => rfl
 | advance h step ih => exact (modePreserved _ _ step).trans ih
theorem preRefusalNoAllocation (q : State) (h : Safe q) (m : q.managed=1) (p : q.preRefused=1) : q.allocs=0 ∧ q.markerCreates=0 ∧ q.guardCreates=0 ∧ q.bodyEntries=0 ∧ q.handlerEntries=0 := by
 unfold Safe at h
 grind
theorem markerHasProtectedRoots (q : State) (h : Safe q) (m : q.managed=1) (p : q.marker=1) : q.root=1 ∧ q.guard=1 := by
 unfold Safe at h
 grind
theorem sourceHoldConserved (q : State) (h : Safe q) : q.sourcePin+q.sourceDrops=1 := by
 unfold Safe at h
 grind
theorem markerHoldConserved (q : State) (h : Safe q) : q.marker+q.markerDrops=q.markerCreates := by
 unfold Safe at h
 grind
theorem refusalCannotRecover (q : State) (r : q.refused=1) : ¬ recoverGoodGuard q ∧ ¬ recoverBadGuard q := by
 simp [recoverGoodGuard,recoverBadGuard,r]
theorem unknownConversionCanRecover (q : State) (m : q.managed=1) (p : q.phase=5) (o : q.origin=2) (d : q.domainOpen=1) (r : q.refused=0) (_code : q.code=1) : recoverGoodGuard q ∧ recoverBadGuard q := by
 simp [recoverGoodGuard,recoverBadGuard,m,p,o,d,r]
theorem deliveryHasNoNativeResources (q : State) (h : Safe q) (m : q.managed=1) (f : q.final=1) : q.sourcePin=0 ∧ q.marker=0 ∧ q.guard=0 ∧ q.root=0 := by
 unfold Safe at h
 grind
-- Actual projected legacy recurrence; excluded by managed=1 guard, not hidden.
def legacyRepeat : Nat → State → State
 | 0,q => q
 | n+1,q => legacyErrorRetryNext (legacyRepeat n q)
theorem legacyPersistentLoop (q : State) (g : legacyErrorRetryGuard q) (n : Nat) :
 legacyErrorRetryGuard (legacyRepeat n q) ∧ (legacyRepeat n q).phase=q.phase ∧ (legacyRepeat n q).code=q.code ∧ (legacyRepeat n q).final=q.final ∧ (legacyRepeat n q).legacyRetries=q.legacyRetries+Int.ofNat n := by
 induction n with
 | zero => simp [legacyRepeat]; exact g
 | succ n ih =>
   rcases ih with ⟨hg,hp,hc,hf,hr⟩
   simp only [legacyRepeat,legacyErrorRetryNext]
   refine ⟨?_,hp,hc,hf,?_⟩
   · simpa [legacyErrorRetryGuard] using hg
   · change (legacyRepeat n q).legacyRetries+1 = q.legacyRetries+(Int.ofNat n+1)
     omega
end SfunAdmission
