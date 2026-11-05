import SizeHoldAst
open SizeHoldAst
namespace SizeHold
theorem finishNativePreserves (q : State) (h : Safe q) (g : finishNativeGuard q) : Safe (finishNativeNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [finishNativeGuard] at g
 dsimp only [Safe,finishNativeNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem enterDropPreserves (q : State) (h : Safe q) (g : enterDropGuard q) : Safe (enterDropNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [enterDropGuard] at g
 dsimp only [Safe,enterDropNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem physicalDropPreserves (q : State) (h : Safe q) (g : physicalDropGuard q) : Safe (physicalDropNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [physicalDropGuard] at g
 dsimp only [Safe,physicalDropNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
theorem commitDropPreserves (q : State) (h : Safe q) (g : commitDropGuard q) : Safe (commitDropNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35⟩
 simp only [commitDropGuard] at g
 dsimp only [Safe,commitDropNext]
 repeat' apply And.intro
 all_goals first | assumption | decide | grind
end SizeHold
