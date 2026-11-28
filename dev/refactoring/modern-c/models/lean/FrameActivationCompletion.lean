import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem doneSplitAligned (q : State) (h : Safe q) (g : doneSplitGuard q) : Aligned (doneSplitNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,doneSplitNext]
 simp only [doneSplitGuard] at g
 simp_all
 all_goals omega
theorem closeLocalAligned (q : State) (h : Safe q) (g : closeLocalGuard q) : Aligned (closeLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,closeLocalNext]
 simp only [closeLocalGuard] at g
 simp_all
 all_goals omega
theorem abortAligned (q : State) (h : Safe q) (g : abortGuard q) : Aligned (abortNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,abortNext]
 simp only [abortGuard] at g
 simp_all
 all_goals omega
theorem finishAbortedAligned (q : State) (h : Safe q) (g : finishAbortedGuard q) : Aligned (finishAbortedNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,finishAbortedNext]
 simp only [finishAbortedGuard] at g
 simp_all
 all_goals omega
theorem publishResultAligned (q : State) (h : Safe q) (g : publishResultGuard q) : Aligned (publishResultNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,publishResultNext]
 simp only [publishResultGuard] at g
 simp_all
 all_goals omega
theorem runPrefixAligned (q : State) (h : Safe q) (g : runPrefixGuard q) : Aligned (runPrefixNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,runPrefixNext]
 simp only [runPrefixGuard] at g
 simp_all
 all_goals omega
end FrameActivation
