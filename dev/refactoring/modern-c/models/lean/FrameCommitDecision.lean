import FrameCommitAst
open FrameCommitAst
namespace FrameCommit
theorem prepareReturnPreserves (q : State) (h : Safe q) (g : prepareReturnGuard q) : Safe (prepareReturnNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [prepareReturnGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7,g8⟩
 dsimp only [Safe,prepareReturnNext]
 simp_all
 all_goals first | omega | grind
theorem commitSplitPreserves (q : State) (h : Safe q) (g : commitSplitGuard q) : Safe (commitSplitNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [commitSplitGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,g10,g11,g12⟩
 dsimp only [Safe,commitSplitNext]
 simp_all
 all_goals first | omega | grind
theorem abortSplitPreserves (q : State) (h : Safe q) (g : abortSplitGuard q) : Safe (abortSplitNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [abortSplitGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
 dsimp only [Safe,abortSplitNext]
 simp_all
 all_goals first | omega | grind
theorem grantLocalPreserves (q : State) (h : Safe q) (g : grantLocalGuard q) : Safe (grantLocalNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69⟩
 simp only [grantLocalGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5,g6,g7⟩
 dsimp only [Safe,grantLocalNext]
 simp_all
 all_goals first | omega | grind
end FrameCommit
