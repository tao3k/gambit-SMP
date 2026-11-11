import SizeHoldAst
open SizeHoldAst
namespace SizeHold
theorem loseReplyPreserves (q : State) (h : Safe q) (g : loseReplyGuard q) : Safe (loseReplyNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [loseReplyGuard] at g
 dsimp only [Safe,loseReplyNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem recoverReplyPreserves (q : State) (h : Safe q) (g : recoverReplyGuard q) : Safe (recoverReplyNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [recoverReplyGuard] at g
 dsimp only [Safe,recoverReplyNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem dropCapturePreserves (q : State) (h : Safe q) (g : dropCaptureGuard q) : Safe (dropCaptureNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [dropCaptureGuard] at g
 dsimp only [Safe,dropCaptureNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem dropRootPreserves (q : State) (h : Safe q) (g : dropRootGuard q) : Safe (dropRootNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [dropRootGuard] at g
 dsimp only [Safe,dropRootNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end SizeHold
