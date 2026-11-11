import SizeHoldAst
open SizeHoldAst
namespace SizeHold
theorem selectAtFixPreserves (q : State) (h : Safe q) (g : selectAtFixGuard q) : Safe (selectAtFixNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [selectAtFixGuard] at g
 dsimp only [Safe,selectAtFixNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem selectMinFixPreserves (q : State) (h : Safe q) (g : selectMinFixGuard q) : Safe (selectMinFixNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [selectMinFixGuard] at g
 dsimp only [Safe,selectMinFixNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem selectBelowFixPreserves (q : State) (h : Safe q) (g : selectBelowFixGuard q) : Safe (selectBelowFixNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [selectBelowFixGuard] at g
 dsimp only [Safe,selectBelowFixNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem convertBoxedPreserves (q : State) (h : Safe q) (g : convertBoxedGuard q) : Safe (convertBoxedNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [convertBoxedGuard] at g
 dsimp only [Safe,convertBoxedNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end SizeHold
