import CleanupIngressAst
import CohortRetirementAst
namespace CleanupIngress
open CleanupIngressAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem reserveChildPreserves (q : State) (h : Safe q) (g : reserveChildGuard q) : Safe (reserveChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [reserveChildGuard,reserveChildNext,Safe] <;> omega
theorem enterChildPreserves (q : State) (h : Safe q) (g : enterChildGuard q) : Safe (enterChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [enterChildGuard,enterChildNext,Safe] <;> omega
theorem returnChildPreserves (q : State) (h : Safe q) (g : returnChildGuard q) : Safe (returnChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [returnChildGuard,returnChildNext,Safe] <;> omega
theorem cancelPermitPreserves (q : State) (h : Safe q) (g : cancelPermitGuard q) : Safe (cancelPermitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [cancelPermitGuard,cancelPermitNext,Safe] <;> omega
theorem requestClosePreserves (q : State) (h : Safe q) (g : requestCloseGuard q) : Safe (requestCloseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [requestCloseGuard,requestCloseNext,Safe] <;> omega
theorem loseBoundaryPreserves (q : State) (h : Safe q) (g : loseBoundaryGuard q) : Safe (loseBoundaryNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [loseBoundaryGuard,loseBoundaryNext,Safe] <;> omega
theorem recoverLandingPreserves (q : State) (h : Safe q) (g : recoverLandingGuard q) : Safe (recoverLandingNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [recoverLandingGuard,recoverLandingNext,Safe] <;> omega
theorem exportResultPreserves (q : State) (h : Safe q) (g : exportResultGuard q) : Safe (exportResultNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [exportResultGuard,exportResultNext,Safe] <;> omega
theorem releaseResultPreserves (q : State) (h : Safe q) (g : releaseResultGuard q) : Safe (releaseResultNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [releaseResultGuard,releaseResultNext,Safe] <;> omega
theorem finishOuterPreserves (q : State) (h : Safe q) (g : finishOuterGuard q) : Safe (finishOuterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [finishOuterGuard,finishOuterNext,Safe] <;> omega
theorem drainCollectivePreserves (q : State) (h : Safe q) (g : drainCollectiveGuard q) : Safe (drainCollectiveNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [drainCollectiveGuard,drainCollectiveNext,Safe] <;> omega
theorem joinUnknownPreserves (q : State) (h : Safe q) (g : joinUnknownGuard q) : Safe (joinUnknownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [joinUnknownGuard,joinUnknownNext,Safe] <;> omega
theorem joinKnownPreserves (q : State) (h : Safe q) (g : joinKnownGuard q) : Safe (joinKnownNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [joinKnownGuard,joinKnownNext,Safe] <;> omega
theorem retireDomainPreserves (q : State) (h : Safe q) (g : retireDomainGuard q) : Safe (retireDomainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [retireDomainGuard,retireDomainNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14
 · rcases h0 with ⟨g,rfl⟩
   exact reserveChildPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact enterChildPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact returnChildPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact cancelPermitPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact requestClosePreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact loseBoundaryPreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact recoverLandingPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact exportResultPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact releaseResultPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact finishOuterPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact drainCollectivePreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact joinUnknownPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact joinKnownPreserves q h g
 · rcases h13 with ⟨g,rfl⟩
   exact retireDomainPreserves q h g
 · simpa [h14] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem requestPreservesRequester (q : State) : (requestCloseNext q).outer=q.outer ∧ (requestCloseNext q).child=q.child ∧ (requestCloseNext q).roots=q.roots ∧ (requestCloseNext q).guard=q.guard := by simp [requestCloseNext]
theorem joinDoesNotSettleResults (q : State) : (joinKnownNext q).resultDebt=q.resultDebt := by rfl
def CohortMirror (q : State) (r : CohortRetirementAst.State) : Prop := q.closed=r.closed ∧ q.collective=r.drained ∧ q.joined=r.joined ∧ q.resultDebt=r.external ∧ (q.outer=0 ∧ q.child=0 ∧ q.permit=0 ↔ r.lookup=0) ∧ (q.unknown=0 → r.unknown=0 ∧ r.fault=0) ∧ r.retired=0
theorem suppliesPriorGuard (q : State) (r : CohortRetirementAst.State) (g : retireDomainGuard q) (hm : CohortMirror q r) : CohortRetirementAst.retireDomainGuard r := by
 simp only [retireDomainGuard] at g
 simp only [CohortMirror] at hm
 simp only [CohortRetirementAst.retireDomainGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : CohortRetirementAst.State) (g : retireDomainGuard q) (hm : CohortMirror q r) : CohortRetirementAst.Step r (CohortRetirementAst.retireDomainNext r) := by
 have h := suppliesPriorGuard q r g hm
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨h,rfl⟩))))))))))
end CleanupIngress
