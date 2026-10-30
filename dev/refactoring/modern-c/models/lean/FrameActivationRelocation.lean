import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem forwardNoCopyAligned (q : State) (h : Safe q) (g : forwardNoCopyGuard q) : Aligned (forwardNoCopyNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,forwardNoCopyNext]
 simp only [forwardNoCopyGuard] at g
 simp_all
 all_goals omega
theorem forwardWithCopyAligned (q : State) (h : Safe q) (g : forwardWithCopyGuard q) : Aligned (forwardWithCopyNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,forwardWithCopyNext]
 simp only [forwardWithCopyGuard] at g
 simp_all
 all_goals omega
theorem gcEndAligned (q : State) (h : Safe q) (g : gcEndGuard q) : Aligned (gcEndNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,gcEndNext]
 simp only [gcEndGuard] at g
 simp_all
 all_goals omega
theorem gcLeaveAligned (q : State) (h : Safe q) (g : gcLeaveGuard q) : Aligned (gcLeaveNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,gcLeaveNext]
 simp only [gcLeaveGuard] at g
 simp_all
 all_goals omega
theorem closeDomainAligned (q : State) (h : Safe q) (g : closeDomainGuard q) : Aligned (closeDomainNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,closeDomainNext]
 simp only [closeDomainGuard] at g
 simp_all
 all_goals omega
theorem resetDomainAligned (q : State) (h : Safe q) (g : resetDomainGuard q) : Aligned (resetDomainNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,resetDomainNext]
 simp only [resetDomainGuard] at g
 simp_all
 all_goals omega
end FrameActivation
