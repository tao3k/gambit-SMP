import TclRefusalAst
open TclRefusalAst
namespace TclRefusal
theorem deliverOrdinaryNativeErrorPreserves (q : State) (h : Safe q) (g : deliverOrdinaryNativeErrorGuard q) : Safe (deliverOrdinaryNativeErrorNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [deliverOrdinaryNativeErrorGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4⟩
 dsimp only [Safe,deliverOrdinaryNativeErrorNext]
 simp_all
 all_goals first | omega | grind
theorem translateOrdinaryErrorPreserves (q : State) (h : Safe q) (g : translateOrdinaryErrorGuard q) : Safe (translateOrdinaryErrorNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [translateOrdinaryErrorGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4,g5⟩
 dsimp only [Safe,translateOrdinaryErrorNext]
 simp_all
 all_goals first | omega | grind
theorem deliverSuccessPreserves (q : State) (h : Safe q) (g : deliverSuccessGuard q) : Safe (deliverSuccessNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [deliverSuccessGuard,and_assoc] at g
 rcases g with ⟨g0,g1,g2,g3,g4⟩
 dsimp only [Safe,deliverSuccessNext]
 simp_all
 all_goals first | omega | grind
theorem closeVmPreserves (q : State) (h : Safe q) (g : closeVmGuard q) : Safe (closeVmNext q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33⟩
 simp only [closeVmGuard,and_assoc] at g
 rcases g with ⟨g0,g1⟩
 dsimp only [Safe,closeVmNext]
 simp_all
 all_goals first | omega | grind
end TclRefusal
