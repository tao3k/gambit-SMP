import CohortRetirementAst
import RcReaderGraceAst
namespace CohortRetirement
open CohortRetirementAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem enterLookupPreserves (q : State) (h : Safe q) (g : enterLookupGuard q) : Safe (enterLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [enterLookupGuard,enterLookupNext,Safe] <;> omega
theorem exitLookupPreserves (q : State) (h : Safe q) (g : exitLookupGuard q) : Safe (exitLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [exitLookupGuard,exitLookupNext,Safe] <;> omega
theorem acquireExternalPreserves (q : State) (h : Safe q) (g : acquireExternalGuard q) : Safe (acquireExternalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [acquireExternalGuard,acquireExternalNext,Safe] <;> omega
theorem returnExternalPreserves (q : State) (h : Safe q) (g : returnExternalGuard q) : Safe (returnExternalNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [returnExternalGuard,returnExternalNext,Safe] <;> omega
theorem closeRosterPreserves (q : State) (h : Safe q) (g : closeRosterGuard q) : Safe (closeRosterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [closeRosterGuard,closeRosterNext,Safe] <;> omega
theorem escapeScannerPreserves (q : State) (h : Safe q) (g : escapeScannerGuard q) : Safe (escapeScannerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [escapeScannerGuard,escapeScannerNext,Safe] <;> omega
theorem collectiveDrainPreserves (q : State) (h : Safe q) (g : collectiveDrainGuard q) : Safe (collectiveDrainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [collectiveDrainGuard,collectiveDrainNext,Safe] <;> omega
theorem exitWorkerPreserves (q : State) (h : Safe q) (g : exitWorkerGuard q) : Safe (exitWorkerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [exitWorkerGuard,exitWorkerNext,Safe] <;> omega
theorem joinUnknownPreserves (q : State) (h : Safe q) (g : joinUnknownGuard q) : Safe (joinUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [joinUnknownGuard,joinUnknownNext,Safe] <;> omega
theorem joinKnownPreserves (q : State) (h : Safe q) (g : joinKnownGuard q) : Safe (joinKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [joinKnownGuard,joinKnownNext,Safe] <;> omega
theorem retireDomainPreserves (q : State) (h : Safe q) (g : retireDomainGuard q) : Safe (retireDomainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 simp_all [retireDomainGuard,retireDomainNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11
 · rcases h0 with ⟨g,rfl⟩
   exact enterLookupPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact exitLookupPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact acquireExternalPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact returnExternalPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact closeRosterPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact escapeScannerPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact collectiveDrainPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact exitWorkerPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact joinUnknownPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact joinKnownPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact retireDomainPreserves q h g
 · simpa [h11] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem joinDoesNotDrainExternal (q : State) : (joinKnownNext q).external=q.external := by rfl
theorem unknownForbidsRetirement (q : State) (h : Safe q) (hu : q.unknown=1) : q.retired=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27⟩
 omega
def GraceMirror (q : State) (r : RcReaderGraceAst.State) : Prop := q.admission=r.admission ∧ q.lookup=r.lookup ∧ q.external=r.diagLease ∧ q.fault=r.fault ∧ q.drained=r.cohortDrained ∧ (q.drained=1 → r.claimed=0 ∧ r.descendant=0 ∧ r.done=1 ∧ r.scan=0)
def Remaining (r : RcReaderGraceAst.State) : Prop := r.registered=0 ∧ r.diagGate=0 ∧ r.domainLive=1
theorem suppliesPriorGuard (q : State) (r : RcReaderGraceAst.State) (g : retireDomainGuard q) (hm : GraceMirror q r) (hr : Remaining r) : RcReaderGraceAst.retireDomainGuard r := by
 simp only [retireDomainGuard] at g
 simp only [GraceMirror] at hm
 simp only [Remaining] at hr
 simp only [RcReaderGraceAst.retireDomainGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : RcReaderGraceAst.State) (g : retireDomainGuard q) (hm : GraceMirror q r) (hr : Remaining r) : RcReaderGraceAst.Step r (RcReaderGraceAst.retireDomainNext r) := by
 have h := suppliesPriorGuard q r g hm hr
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩))))))))))))))))
end CohortRetirement
