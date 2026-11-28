import SizeHoldAst
open SizeHoldAst
namespace SizeHold
theorem beginGcPreserves (q : State) (h : Safe q) (g : beginGcGuard q) : Safe (beginGcNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [beginGcGuard] at g
 dsimp only [Safe,beginGcNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem finishGcPreserves (q : State) (h : Safe q) (g : finishGcGuard q) : Safe (finishGcNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [finishGcGuard] at g
 dsimp only [Safe,finishGcNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end SizeHold
