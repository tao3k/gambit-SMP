import NrInflightHandoffAst
import NrAnchorRetirementAst
namespace NrInflightHandoff
open NrInflightHandoffAst
set_option maxRecDepth 10000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem prepareEscrowPreserves (q : State) (h : Safe q) (g : prepareEscrowGuard q) : Safe (prepareEscrowNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [prepareEscrowGuard] at g
 simp only [prepareEscrowNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | omega
theorem popNodePreserves (q : State) (h : Safe q) (g : popNodeGuard q) : Safe (popNodeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, h14, h15, h16, h17, h18, h19, h20, h21, h22, h23, h24, h25, h26, h27, h28, h29, h30, h31, h32, h33, h34, h35, h36, h37, h38, h39, h40, h41, h42, h43, h44, h45, h46, h47, h48, h49, h50⟩
 simp only [popNodeGuard] at g
 simp only [popNodeNext,Safe]
 repeat' apply And.intro
 all_goals first | assumption | omega

end NrInflightHandoff
