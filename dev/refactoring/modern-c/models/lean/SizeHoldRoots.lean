import SizeHoldAst
open SizeHoldAst
namespace SizeHold
theorem convertImmediatePreserves (q : State) (h : Safe q) (g : convertImmediateGuard q) : Safe (convertImmediateNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [convertImmediateGuard] at g
 dsimp only [Safe,convertImmediateNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem conversionFailurePreserves (q : State) (h : Safe q) (g : conversionFailureGuard q) : Safe (conversionFailureNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [conversionFailureGuard] at g
 dsimp only [Safe,conversionFailureNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem publishRootPreserves (q : State) (h : Safe q) (g : publishRootGuard q) : Safe (publishRootNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [publishRootGuard] at g
 dsimp only [Safe,publishRootNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem captureArgumentPreserves (q : State) (h : Safe q) (g : captureArgumentGuard q) : Safe (captureArgumentNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [captureArgumentGuard] at g
 dsimp only [Safe,captureArgumentNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end SizeHold
