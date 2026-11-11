import RcReaderGraceAst
import RcRootReleaseAst
namespace RcReaderGrace
open RcReaderGraceAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem enterLookupPreserves (q : State) (h : Safe q) (g : enterLookupGuard q) : Safe (enterLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [enterLookupGuard,enterLookupNext,Safe] <;> omega
theorem claimLookupPreserves (q : State) (h : Safe q) (g : claimLookupGuard q) : Safe (claimLookupNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [claimLookupGuard,claimLookupNext,Safe] <;> omega
theorem failClaimPreserves (q : State) (h : Safe q) (g : failClaimGuard q) : Safe (failClaimNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [failClaimGuard,failClaimNext,Safe] <;> omega
theorem completeClaimPreserves (q : State) (h : Safe q) (g : completeClaimGuard q) : Safe (completeClaimNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [completeClaimGuard,completeClaimNext,Safe] <;> omega
theorem closeAdmissionPreserves (q : State) (h : Safe q) (g : closeAdmissionGuard q) : Safe (closeAdmissionNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [closeAdmissionGuard,closeAdmissionNext,Safe] <;> omega
theorem rejectLatePreserves (q : State) (h : Safe q) (g : rejectLateGuard q) : Safe (rejectLateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [rejectLateGuard,rejectLateNext,Safe] <;> omega
theorem beginScanPreserves (q : State) (h : Safe q) (g : beginScanGuard q) : Safe (beginScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [beginScanGuard,beginScanNext,Safe] <;> omega
theorem endScanPreserves (q : State) (h : Safe q) (g : endScanGuard q) : Safe (endScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [endScanGuard,endScanNext,Safe] <;> omega
theorem saveDiagnosticPreserves (q : State) (h : Safe q) (g : saveDiagnosticGuard q) : Safe (saveDiagnosticNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [saveDiagnosticGuard,saveDiagnosticNext,Safe] <;> omega
theorem borrowDiagnosticPreserves (q : State) (h : Safe q) (g : borrowDiagnosticGuard q) : Safe (borrowDiagnosticNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [borrowDiagnosticGuard,borrowDiagnosticNext,Safe] <;> omega
theorem returnDiagnosticPreserves (q : State) (h : Safe q) (g : returnDiagnosticGuard q) : Safe (returnDiagnosticNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [returnDiagnosticGuard,returnDiagnosticNext,Safe] <;> omega
theorem closeDiagnosticPreserves (q : State) (h : Safe q) (g : closeDiagnosticGuard q) : Safe (closeDiagnosticNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [closeDiagnosticGuard,closeDiagnosticNext,Safe] <;> omega
theorem unlinkNodePreserves (q : State) (h : Safe q) (g : unlinkNodeGuard q) : Safe (unlinkNodeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [unlinkNodeGuard,unlinkNodeNext,Safe] <;> omega
theorem retireDomainPreserves (q : State) (h : Safe q) (g : retireDomainGuard q) : Safe (retireDomainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 simp_all [retireDomainGuard,retireDomainNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14
 · rcases h0 with ⟨g,rfl⟩
   exact enterLookupPreserves q h g
 · rcases h1 with ⟨g,rfl⟩
   exact claimLookupPreserves q h g
 · rcases h2 with ⟨g,rfl⟩
   exact failClaimPreserves q h g
 · rcases h3 with ⟨g,rfl⟩
   exact completeClaimPreserves q h g
 · rcases h4 with ⟨g,rfl⟩
   exact closeAdmissionPreserves q h g
 · rcases h5 with ⟨g,rfl⟩
   exact rejectLatePreserves q h g
 · rcases h6 with ⟨g,rfl⟩
   exact beginScanPreserves q h g
 · rcases h7 with ⟨g,rfl⟩
   exact endScanPreserves q h g
 · rcases h8 with ⟨g,rfl⟩
   exact saveDiagnosticPreserves q h g
 · rcases h9 with ⟨g,rfl⟩
   exact borrowDiagnosticPreserves q h g
 · rcases h10 with ⟨g,rfl⟩
   exact returnDiagnosticPreserves q h g
 · rcases h11 with ⟨g,rfl⟩
   exact closeDiagnosticPreserves q h g
 · rcases h12 with ⟨g,rfl⟩
   exact unlinkNodePreserves q h g
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
theorem faultRetainsDomain (q : State) (h : Safe q) (hf : q.fault=1) : q.scan=1 ∧ q.claimed=1 ∧ q.domainLive=1 ∧ q.escrow=1 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38⟩
 omega
theorem nodeUnlinkDoesNotDrainLookup (q : State) : (unlinkNodeNext q).lookup=q.lookup := by rfl
def MetadataGrace (q : State) : Prop := q.admission=0 ∧ q.lookup=0 ∧ q.claimed=0 ∧ q.done=1 ∧ q.scan=0 ∧ q.fault=0 ∧ q.diagLease=0 ∧ q.diagGate=0
def ReaderMirror (q : State) (r : RcRootReleaseAst.State) : Prop := r.reader=0 ↔ q.lookup=0 ∧ q.claimed=0
def OtherRetirement (r : RcRootReleaseAst.State) : Prop := r.admission=0 ∧ r.registered=0 ∧ r.owner=0 ∧ r.borrow=0 ∧ r.scanner=0 ∧ r.alias=0 ∧ r.phase=3 ∧ r.domainLive=1
theorem graceSuppliesPriorGuard (q : State) (r : RcRootReleaseAst.State) (hg : MetadataGrace q) (hm : ReaderMirror q r) (ho : OtherRetirement r) : RcRootReleaseAst.retireDomainGuard r := by
 simp only [MetadataGrace] at hg
 simp only [ReaderMirror] at hm
 simp only [OtherRetirement] at ho
 simp only [RcRootReleaseAst.retireDomainGuard]
 omega
theorem guardedPriorRetirement (q : State) (r : RcRootReleaseAst.State) (hg : MetadataGrace q) (hm : ReaderMirror q r) (ho : OtherRetirement r) : RcRootReleaseAst.Step r (RcRootReleaseAst.retireDomainNext r) := by
 have g := graceSuppliesPriorGuard q r hg hm ho
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩)))))))))))))))
end RcReaderGrace
