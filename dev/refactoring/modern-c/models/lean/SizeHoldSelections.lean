import SizeHoldAst
open SizeHoldAst
namespace SizeHold
theorem selectSizeMaxPreserves (q : State) (h : Safe q) (g : selectSizeMaxGuard q) : Safe (selectSizeMaxNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [selectSizeMaxGuard] at g
 dsimp only [Safe,selectSizeMaxNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem selectSignedMinPreserves (q : State) (h : Safe q) (g : selectSignedMinGuard q) : Safe (selectSignedMinNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [selectSignedMinGuard] at g
 dsimp only [Safe,selectSignedMinNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem selectSignedMaxPreserves (q : State) (h : Safe q) (g : selectSignedMaxGuard q) : Safe (selectSignedMaxNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [selectSignedMaxGuard] at g
 dsimp only [Safe,selectSignedMaxNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem selectAboveFixPreserves (q : State) (h : Safe q) (g : selectAboveFixGuard q) : Safe (selectAboveFixNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [selectAboveFixGuard] at g
 dsimp only [Safe,selectAboveFixNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end SizeHold
