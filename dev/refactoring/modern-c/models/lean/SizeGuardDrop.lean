import SizeGuardAst
open SizeGuardAst
namespace SizeGuard
theorem claimDropPreserves (q : State) (h : Safe q) (g : claimDropGuard q) : Safe (claimDropNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [claimDropGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4⟩
 dsimp only [Safe,claimDropNext]
 simp_all
 all_goals first | omega | grind
theorem fuseCfunHandoffPreserves (q : State) (h : Safe q) (g : fuseCfunHandoffGuard q) : Safe (fuseCfunHandoffNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [fuseCfunHandoffGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
 dsimp only [Safe,fuseCfunHandoffNext]
 simp_all
 all_goals first | omega | grind
theorem physicalDropPreserves (q : State) (h : Safe q) (g : physicalDropGuard q) : Safe (physicalDropNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [physicalDropGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4⟩
 dsimp only [Safe,physicalDropNext]
 simp_all
 all_goals first | omega | grind
theorem recordDropPreserves (q : State) (h : Safe q) (g : recordDropGuard q) : Safe (recordDropNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [recordDropGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4⟩
 dsimp only [Safe,recordDropNext]
 simp_all
 all_goals first | omega | grind
end SizeGuard
