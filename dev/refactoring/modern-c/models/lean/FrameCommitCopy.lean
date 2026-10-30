import FrameCommitAst
open FrameCommitAst
namespace FrameCommit
theorem enterRuntimePreserves (q : State) (h : Safe q) (g : enterRuntimeGuard q) : Safe (enterRuntimeNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [enterRuntimeGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2⟩
 dsimp only [Safe,enterRuntimeNext]
 simp_all
 all_goals first | omega | grind
theorem resolveCanonicalPreserves (q : State) (h : Safe q) (g : resolveCanonicalGuard q) : Safe (resolveCanonicalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [resolveCanonicalGuard,and_assoc] at g
 rcases g with ⟨g0,g1⟩
 dsimp only [Safe,resolveCanonicalNext]
 simp_all
 all_goals first | omega | grind
theorem initializeCopyPreserves (q : State) (h : Safe q) (g : initializeCopyGuard q) : Safe (initializeCopyNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [initializeCopyGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7,g8⟩
 dsimp only [Safe,initializeCopyNext]
 simp_all
 all_goals first | omega | grind
theorem validateCopyPreserves (q : State) (h : Safe q) (g : validateCopyGuard q) : Safe (validateCopyNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [validateCopyGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7,g8⟩
 dsimp only [Safe,validateCopyNext]
 simp_all
 all_goals first | omega | grind
end FrameCommit
