import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem activationFailedAligned (q : State) (h : Safe q) (g : activationFailedGuard q) : Aligned (activationFailedNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,activationFailedNext]
 simp only [activationFailedGuard] at g
 simp_all
 all_goals omega
theorem activateAligned (q : State) (h : Safe q) (g : activateGuard q) : Aligned (activateNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,activateNext]
 simp only [activateGuard] at g
 simp_all
 all_goals omega
theorem wakeFailedAligned (q : State) (h : Safe q) (g : wakeFailedGuard q) : Aligned (wakeFailedNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,wakeFailedNext]
 simp only [wakeFailedGuard] at g
 simp_all
 all_goals omega
theorem dequeueAligned (q : State) (h : Safe q) (g : dequeueGuard q) : Aligned (dequeueNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,dequeueNext]
 simp only [dequeueGuard] at g
 simp_all
 all_goals omega
theorem restoreAligned (q : State) (h : Safe q) (g : restoreGuard q) : Aligned (restoreNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,restoreNext]
 simp only [restoreGuard] at g
 simp_all
 all_goals omega
theorem doneLocalAligned (q : State) (h : Safe q) (g : doneLocalGuard q) : Aligned (doneLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,doneLocalNext]
 simp only [doneLocalGuard] at g
 simp_all
 all_goals omega
end FrameActivation
