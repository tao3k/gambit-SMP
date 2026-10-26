import ExitDomainDrainRegistration
import ExitDomainDrainDispatch
import ExitDomainDrainRetirement
import RuntimeTlsReadyAst
namespace ExitDomainDrain
open ExitDomainDrainAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by decide
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
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 omega
theorem unknownRetainsCustody (q : State) (h : Safe q) (hu : q.a=7 ∨ q.a=8 ∨ q.ack=2) : q.phase<=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 omega
theorem liveLookupRetainsKey (q : State) (h : Safe q) (hl : q.lookupPin=1) : q.key=1 ∧ q.phase<=2 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 omega
theorem dataReceiptIsLocal (q : State) (h : Safe q) (hp : q.phase=5) : q.data=0 ∧ q.slot=0 ∧ q.key=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 omega
theorem keyRetiredRequiresRoster (q : State) (h : Safe q) (hp : q.key=0) : q.phase=6 ∧ q.cacheDone=1 ∧ q.allOwners=1 ∧ q.lookupPin=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44⟩
 rcases h0 with ⟨hl0,hu0⟩
 rcases h1 with ⟨hl1,hu1⟩
 rcases h2 with ⟨hl2,hu2⟩
 rcases h3 with ⟨hl3,hu3⟩
 rcases h4 with ⟨hl4,hu4⟩
 rcases h5 with ⟨hl5,hu5⟩
 rcases h6 with ⟨hl6,hu6⟩
 rcases h7 with ⟨hl7,hu7⟩
 rcases h8 with ⟨hl8,hu8⟩
 rcases h9 with ⟨hl9,hu9⟩
 rcases h10 with ⟨hl10,hu10⟩
 rcases h11 with ⟨hl11,hu11⟩
 rcases h12 with ⟨hl12,hu12⟩
 rcases h13 with ⟨hl13,hu13⟩
 rcases h14 with ⟨hl14,hu14⟩
 rcases h15 with ⟨hl15,hu15⟩
 rcases h16 with ⟨hl16,hu16⟩
 rcases h17 with ⟨hl17,hu17⟩
 rcases h18 with ⟨hl18,hu18⟩
 rcases h19 with ⟨hl19,hu19⟩
 omega
theorem absentLookupDoesNotAllocate (q : State) : (lookupAbsentNext q).data=q.data ∧ (lookupAbsentNext q).cache=q.cache := by simp [lookupAbsentNext]
theorem duplicateCancelDoesNotFinishActive (q : State) : (cancelNewestDuplicateBNext q).a=q.a ∧ (cancelNewestDuplicateBNext q).b=6 := by simp [cancelNewestDuplicateBNext]
theorem callbackReturnIsNotNodeFree (q : State) : (returnANext q).a=4 := by rfl
def FinishMirror (q : State) (r : RuntimeTlsReadyAst.State) : Prop :=
 q.phase=4 → r.g=3 ∧ r.finalizer=1 ∧ r.late=0
theorem suppliesPriorFinish (q : State) (r : RuntimeTlsReadyAst.State) (g : issueDataDrainReceiptGuard q) (hm : FinishMirror q r) : RuntimeTlsReadyAst.finishFinalizerGuard r := by
 simp only [issueDataDrainReceiptGuard] at g
 exact hm g
theorem guardedPriorFinish (q : State) (r : RuntimeTlsReadyAst.State) (g : issueDataDrainReceiptGuard q) (hm : FinishMirror q r) : RuntimeTlsReadyAst.Step r (RuntimeTlsReadyAst.finishFinalizerNext r) := by
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨suppliesPriorFinish q r g hm,rfl⟩)))))))))))))))))))))))))))
end ExitDomainDrain
