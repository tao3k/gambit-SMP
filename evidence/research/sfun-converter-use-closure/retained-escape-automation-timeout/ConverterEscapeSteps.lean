import ConverterUseAst
namespace ConverterUse
open ConverterUseAst
set_option maxRecDepth 10000
theorem escapeOwnerPreserves (q : State) (h : Safe q) (g : escapeOwnerGuard q) : Safe (escapeOwnerNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp only [escapeOwnerGuard] at g
 have phaseBound : 3 ≤ q.phase ∧ q.phase ≤ 7 := by omega
 dsimp only [Safe,escapeOwnerNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | omega
theorem drainInputFromGuardPreserves (q : State) (h : Safe q) (g : drainInputFromGuardGuard q) : Safe (drainInputFromGuardNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp only [drainInputFromGuardGuard] at g
 dsimp only [Safe,drainInputFromGuardNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem ackExitedOwnerPreserves (q : State) (h : Safe q) (g : ackExitedOwnerGuard q) : Safe (ackExitedOwnerNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp only [ackExitedOwnerGuard] at g
 dsimp only [Safe,ackExitedOwnerNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem signEscapedUsePreserves (q : State) (h : Safe q) (g : signEscapedUseGuard q) : Safe (signEscapedUseNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74,h75,h76,h77,h78⟩
 simp only [signEscapedUseGuard] at g
 dsimp only [Safe,signEscapedUseNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end ConverterUse
