import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem reserveAligned (q : State) (h : Safe q) (g : reserveGuard q) : Aligned (reserveNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,reserveNext]
 simp only [reserveGuard] at g
 simp_all
 all_goals omega
theorem allocateAligned (q : State) (h : Safe q) (g : allocateGuard q) : Aligned (allocateNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,allocateNext]
 simp only [allocateGuard] at g
 simp_all
 all_goals omega
theorem enterAligned (q : State) (h : Safe q) (g : enterGuard q) : Aligned (enterNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,enterNext]
 simp only [enterGuard] at g
 simp_all
 all_goals omega
theorem resolveAligned (q : State) (h : Safe q) (g : resolveGuard q) : Aligned (resolveNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,resolveNext]
 simp only [resolveGuard] at g
 simp_all
 all_goals omega
theorem initializeAligned (q : State) (h : Safe q) (g : initializeGuard q) : Aligned (initializeNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,initializeNext]
 simp only [initializeGuard] at g
 simp_all
 all_goals omega
theorem validateAligned (q : State) (h : Safe q) (g : validateGuard q) : Aligned (validateNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,validateNext]
 simp only [validateGuard] at g
 simp_all
 all_goals omega
end FrameActivation
