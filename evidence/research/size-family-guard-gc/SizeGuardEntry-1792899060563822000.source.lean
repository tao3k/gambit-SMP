import SizeGuardAst
open SizeGuardAst
namespace SizeGuard
theorem reserveSfunPreserves (q : State) (h : Safe q) (g : reserveSfunGuard q) : Safe (reserveSfunNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [reserveSfunGuard] at g
 dsimp only [Safe,reserveSfunNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | (simp_all; omega) | grind
theorem reserveCfunPreserves (q : State) (h : Safe q) (g : reserveCfunGuard q) : Safe (reserveCfunNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [reserveCfunGuard] at g
 dsimp only [Safe,reserveCfunNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | (simp_all; omega) | grind
theorem beginConversionPreserves (q : State) (h : Safe q) (g : beginConversionGuard q) : Safe (beginConversionNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [beginConversionGuard] at g
 dsimp only [Safe,beginConversionNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | (simp_all; omega) | grind
theorem completeBoxedPreserves (q : State) (h : Safe q) (g : completeBoxedGuard q) : Safe (completeBoxedNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [completeBoxedGuard] at g
 dsimp only [Safe,completeBoxedNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | (simp_all; omega) | grind
end SizeGuard
