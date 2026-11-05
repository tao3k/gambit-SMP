import RcRootReleaseAst
import TargetLeaseAst
namespace RcRootRelease
open RcRootReleaseAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem acquireBorrowPreserves (q : State) (h : Safe q) (g : acquireBorrowGuard q) : Safe (acquireBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [acquireBorrowGuard,acquireBorrowNext,Safe] <;> omega
theorem exportAliasPreserves (q : State) (h : Safe q) (g : exportAliasGuard q) : Safe (exportAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [exportAliasGuard,exportAliasNext,Safe] <;> omega
theorem closeSourcePreserves (q : State) (h : Safe q) (g : closeSourceGuard q) : Safe (closeSourceNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [closeSourceGuard,closeSourceNext,Safe] <;> omega
theorem dropOwnerPreserves (q : State) (h : Safe q) (g : dropOwnerGuard q) : Safe (dropOwnerNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [dropOwnerGuard,dropOwnerNext,Safe] <;> omega
theorem returnBorrowPreserves (q : State) (h : Safe q) (g : returnBorrowGuard q) : Safe (returnBorrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [returnBorrowGuard,returnBorrowNext,Safe] <;> omega
theorem returnAliasPreserves (q : State) (h : Safe q) (g : returnAliasGuard q) : Safe (returnAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [returnAliasGuard,returnAliasNext,Safe] <;> omega
theorem beginScanPreserves (q : State) (h : Safe q) (g : beginScanGuard q) : Safe (beginScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [beginScanGuard,beginScanNext,Safe] <;> omega
theorem endScanPreserves (q : State) (h : Safe q) (g : endScanGuard q) : Safe (endScanNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [endScanGuard,endScanNext,Safe] <;> omega
theorem enterReaderPreserves (q : State) (h : Safe q) (g : enterReaderGuard q) : Safe (enterReaderNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [enterReaderGuard,enterReaderNext,Safe] <;> omega
theorem exitReaderPreserves (q : State) (h : Safe q) (g : exitReaderGuard q) : Safe (exitReaderNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [exitReaderGuard,exitReaderNext,Safe] <;> omega
theorem unlinkAndPermitPreserves (q : State) (h : Safe q) (g : unlinkAndPermitGuard q) : Safe (unlinkAndPermitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [unlinkAndPermitGuard,unlinkAndPermitNext,Safe] <;> omega
theorem beginFreePreserves (q : State) (h : Safe q) (g : beginFreeGuard q) : Safe (beginFreeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [beginFreeGuard,beginFreeNext,Safe] <;> omega
theorem loseFreeResultPreserves (q : State) (h : Safe q) (g : loseFreeResultGuard q) : Safe (loseFreeResultNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [loseFreeResultGuard,loseFreeResultNext,Safe] <;> omega
theorem backendReceiptPreserves (q : State) (h : Safe q) (g : backendReceiptGuard q) : Safe (backendReceiptNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [backendReceiptGuard,backendReceiptNext,Safe] <;> omega
theorem settleFreePreserves (q : State) (h : Safe q) (g : settleFreeGuard q) : Safe (settleFreeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [settleFreeGuard,settleFreeNext,Safe] <;> omega
theorem retireDomainPreserves (q : State) (h : Safe q) (g : retireDomainGuard q) : Safe (retireDomainNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 simp_all [retireDomainGuard,retireDomainNext,Safe] <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (hs : Step q r) : Safe r := by
 rcases hs with h0 | h1 | h2 | h3 | h4 | h5 | h6 | h7 | h8 | h9 | h10 | h11 | h12 | h13 | h14 | h15 | h16
 · rcases h0 with ⟨g, rfl⟩
   exact acquireBorrowPreserves q h g
 · rcases h1 with ⟨g, rfl⟩
   exact exportAliasPreserves q h g
 · rcases h2 with ⟨g, rfl⟩
   exact closeSourcePreserves q h g
 · rcases h3 with ⟨g, rfl⟩
   exact dropOwnerPreserves q h g
 · rcases h4 with ⟨g, rfl⟩
   exact returnBorrowPreserves q h g
 · rcases h5 with ⟨g, rfl⟩
   exact returnAliasPreserves q h g
 · rcases h6 with ⟨g, rfl⟩
   exact beginScanPreserves q h g
 · rcases h7 with ⟨g, rfl⟩
   exact endScanPreserves q h g
 · rcases h8 with ⟨g, rfl⟩
   exact enterReaderPreserves q h g
 · rcases h9 with ⟨g, rfl⟩
   exact exitReaderPreserves q h g
 · rcases h10 with ⟨g, rfl⟩
   exact unlinkAndPermitPreserves q h g
 · rcases h11 with ⟨g, rfl⟩
   exact beginFreePreserves q h g
 · rcases h12 with ⟨g, rfl⟩
   exact loseFreeResultPreserves q h g
 · rcases h13 with ⟨g, rfl⟩
   exact backendReceiptPreserves q h g
 · rcases h14 with ⟨g, rfl⟩
   exact settleFreePreserves q h g
 · rcases h15 with ⟨g, rfl⟩
   exact retireDomainPreserves q h g
 · simpa [h16] using h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r : State} : Reachable q → Step q r → Reachable r
theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ hs ih => exact stepPreserves _ _ ih hs
theorem permitExcludesUsers (q : State) (h : Safe q) (hp : q.permit=1) : q.registered=0 ∧ q.owner=0 ∧ q.borrow=0 ∧ q.scanner=0 ∧ q.alias=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 omega
theorem unknownKeepsOrigin (q : State) (h : Safe q) (hu : q.phase=2) : q.origin=1 ∧ q.registered=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35⟩
 omega
-- Actual previous-provider transition, additionally gated by the new storage receipt.
-- This is a guarded join, not a full product simulation or native free proof.
def FreeAdmission (r : State) (t : TargetLeaseAst.State) : Prop :=
 r.permit=1 ∧ TargetLeaseAst.beginOriginFreeGuard t
theorem originHandoff (r : State) (t : TargetLeaseAst.State) (h : Safe r)
 (g : FreeAdmission r t) :
 r.registered=0 ∧ r.owner=0 ∧ r.borrow=0 ∧ r.scanner=0 ∧ r.alias=0 ∧
 TargetLeaseAst.Step t (TargetLeaseAst.beginOriginFreeNext t) := by
 have hn := permitExcludesUsers r h g.1
 rcases hn with ⟨hr,ho,hb,hs,ha⟩
 refine ⟨hr,ho,hb,hs,ha,?_⟩
 simp only [TargetLeaseAst.Step]
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g.2,rfl⟩)))))))))))))))
end RcRootRelease
