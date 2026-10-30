import ExitDomainDrainRegistration
import ExitDomainDrainDispatch
import ExitDomainDrainRetirement
import RuntimeTlsReadyAst
namespace ExitDomainDrain
open ExitDomainDrainAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | ⟨g,hr⟩ | hr
 · subst r; exact seedRegistrationAPreserves q h g
 · subst r; exact chooseDuplicatePairPreserves q h g
 · subst r; exact reserveExternalBPreserves q h g
 · subst r; exact beginDrainPreserves q h g
 · subst r; exact reserveChildBPreserves q h g
 · subst r; exact reserveTailBPreserves q h g
 · subst r; exact publishBKnownPreserves q h g
 · subst r; exact publishBUnknownPreserves q h g
 · subst r; exact publicationAbsentUnknownPreserves q h g
 · subst r; exact reconcileAcceptedBPreserves q h g
 · subst r; exact reconcileAbsentAndRolledBackBPreserves q h g
 · subst r; exact popAPreserves q h g
 · subst r; exact popBPreserves q h g
 · subst r; exact returnAPreserves q h g
 · subst r; exact returnBPreserves q h g
 · subst r; exact callbackUnknownAPreserves q h g
 · subst r; exact freeNodeAKnownPreserves q h g
 · subst r; exact freeNodeBKnownPreserves q h g
 · subst r; exact freeNodeAUnknownPreserves q h g
 · subst r; exact freeNodeBUnknownPreserves q h g
 · subst r; exact cancelNewestDuplicateBPreserves q h g
 · subst r; exact cancelQueuedAPreserves q h g
 · subst r; exact reentrantFinalizeJoinPreserves q h g
 · subst r; exact beginSubsystemTailPreserves q h g
 · subst r; exact finishSubsystemTailPreserves q h g
 · subst r; exact closeProducersPreserves q h g
 · subst r; exact attestNoTsdDependenciesPreserves q h g
 · subst r; exact acquireLookupPreserves q h g
 · subst r; exact lookupAbsentPreserves q h g
 · subst r; exact releaseLookupPreserves q h g
 · subst r; exact detachTableSlotPreserves q h g
 · subst r; exact freeTsdDataPreserves q h g
 · subst r; exact issueDataDrainReceiptPreserves q h g
 · subst r; exact cancelAbsentFromReceiptPreserves q h g
 · subst r; exact attestCacheAndOwnerRosterPreserves q h g
 · subst r; exact deleteGenericKeyPreserves q h g
 · subst r; exact h
inductive Reachable : State → Prop where
 | initial : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (hr : Reachable q) : Safe q := by
 induction hr with
 | initial => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem drainedHasNoInFlight (q : State) (h : Safe q) (hp : q.phase>=3) : q.slot=0 ∧ q.lookupPin=0 ∧ q.deps=1 ∧ (q.a=0 ∨ q.a=5) ∧ (q.b=0 ∨ q.b=5) ∧ q.ack≠2 := by
 simp only [Safe] at h
 have h23 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have h24 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have hc := h23 (show q.phase>=2 by omega)
 have hd := h24 hp
 exact ⟨hd.1,hd.2.1,hd.2.2,hc.2.1,hc.2.2.1,hc.2.2.2.1⟩
theorem unknownRetainsCustody (q : State) (h : Safe q) (hu : q.a=7 ∨ q.a=8 ∨ q.ack=2) : q.phase<=1 := by
 simp only [Safe] at h
 have h23 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 by_contra hn
 have hc := h23 (show q.phase>=2 by omega)
 have ha := hc.2.1
 have hk := hc.2.2.2.1
 omega
theorem liveLookupRetainsKey (q : State) (h : Safe q) (hl : q.lookupPin=1) : q.key=1 ∧ q.phase<=2 := by
 simp only [Safe] at h
 have h28 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have hc := h28 hl
 exact ⟨hc.2,hc.1⟩
theorem dataReceiptIsLocal (q : State) (h : Safe q) (hp : q.phase=5) : q.data=0 ∧ q.slot=0 ∧ q.key=1 := by
 simp only [Safe] at h
 have h24 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have h25 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have h26 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have hd := h25 (show q.phase>=4 by omega)
 have hs := h24 (show q.phase>=3 by omega)
 have hk := h26 (show q.phase<=5 by omega)
 exact ⟨hd,hs.1,hk⟩
theorem keyRetiredRequiresRoster (q : State) (h : Safe q) (hp : q.key=0) : q.phase=6 ∧ q.cacheDone=1 ∧ q.allOwners=1 ∧ q.lookupPin=0 := by
 simp only [Safe] at h
 have h0 := h.1
 have h24 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have h26 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have h27 := h.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 have hp : q.phase=6 := by
  have hb := h0
  by_contra hn
  have hk := h26 (show q.phase<=5 by omega)
  omega
 have hc := h27 hp
 have hs := h24 (show q.phase>=3 by omega)
 exact ⟨hp,hc.2.1,hc.2.2.1,hs.2.1⟩
theorem absentLookupDoesNotAllocate (q : State) : (lookupAbsentNext q).data=q.data ∧ (lookupAbsentNext q).cache=q.cache := by simp [lookupAbsentNext]
theorem duplicateCancelDoesNotFinishActive (q : State) : (cancelNewestDuplicateBNext q).a=q.a ∧ (cancelNewestDuplicateBNext q).b=6 := by simp [cancelNewestDuplicateBNext]
theorem callbackReturnIsNotNodeFree (q : State) : (returnANext q).a=4 := by rfl
def FinishMirror (q : State) (r : RuntimeTlsReadyAst.State) : Prop :=
 q.phase=4 → r.g=3 ∧ r.finalizer=1 ∧ r.late=0
theorem suppliesPriorFinish (q : State) (r : RuntimeTlsReadyAst.State) (g : issueDataDrainReceiptGuard q) (hm : FinishMirror q r) : RuntimeTlsReadyAst.finishFinalizerGuard r := by
 simp only [issueDataDrainReceiptGuard] at g
 rcases hm g with ⟨hg,hf,hl⟩
 exact ⟨⟨hg,hf⟩,hl⟩
theorem guardedPriorFinish (q : State) (r : RuntimeTlsReadyAst.State) (g : issueDataDrainReceiptGuard q) (hm : FinishMirror q r) : RuntimeTlsReadyAst.Step r (RuntimeTlsReadyAst.finishFinalizerNext r) := by
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨suppliesPriorFinish q r g hm,rfl⟩)))))))))))))))))))))))))))
end ExitDomainDrain
