import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem grantLocalAligned (q : State) (h : Safe q) (g : grantLocalGuard q) : Aligned (grantLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,grantLocalNext]
 simp only [grantLocalGuard] at g
 simp_all
 all_goals omega
theorem grantRemoteAligned (q : State) (h : Safe q) (g : grantRemoteGuard q) : Aligned (grantRemoteNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,grantRemoteNext]
 simp only [grantRemoteGuard] at g
 simp_all
 all_goals omega
theorem leaveAligned (q : State) (h : Safe q) (g : leaveGuard q) : Aligned (leaveNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,leaveNext]
 simp only [leaveGuard] at g
 simp_all
 all_goals omega
theorem gcEnterAligned (q : State) (h : Safe q) (g : gcEnterGuard q) : Aligned (gcEnterNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,gcEnterNext]
 simp only [gcEnterGuard] at g
 simp_all
 all_goals omega
theorem gcFreezeAligned (q : State) (h : Safe q) (g : gcFreezeGuard q) : Aligned (gcFreezeNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,gcFreezeNext]
 simp only [gcFreezeGuard] at g
 simp_all
 all_goals omega
theorem gcBeginAligned (q : State) (h : Safe q) (g : gcBeginGuard q) : Aligned (gcBeginNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,gcBeginNext]
 simp only [gcBeginGuard] at g
 simp_all
 all_goals omega
end FrameActivation
