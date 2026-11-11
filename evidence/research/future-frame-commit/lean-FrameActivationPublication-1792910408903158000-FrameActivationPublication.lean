import FrameActivationMaps
namespace FrameActivation
open FrameActivationAst
theorem prepareAligned (q : State) (h : Safe q) (g : prepareGuard q) : Aligned (prepareNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,prepareNext]
 simp only [prepareGuard] at g
 simp_all
 all_goals omega
theorem sendPublicationAligned (q : State) (h : Safe q) (g : sendPublicationGuard q) : Aligned (sendPublicationNext q) := by
 have copied := phaseTwoCopied q h
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,sendPublicationNext]
 simp only [sendPublicationGuard] at g
 simp_all
 all_goals omega
theorem publicationUnknownAligned (q : State) (h : Safe q) (g : publicationUnknownGuard q) : Aligned (publicationUnknownNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,publicationUnknownNext]
 simp only [publicationUnknownGuard] at g
 simp_all
 all_goals omega
theorem acceptPublicationAligned (q : State) (h : Safe q) (g : acceptPublicationGuard q) : Aligned (acceptPublicationNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,acceptPublicationNext]
 simp only [acceptPublicationGuard] at g
 simp_all
 all_goals omega
theorem rejectPublicationAligned (q : State) (h : Safe q) (g : rejectPublicationGuard q) : Aligned (rejectPublicationNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,rejectPublicationNext]
 simp only [rejectPublicationGuard] at g
 simp_all
 all_goals omega
theorem commitAligned (q : State) (h : Safe q) (g : commitGuard q) : Aligned (commitNext q) := by
 have hc := ((safeEquivalent q).mp h).2.2
 have empty := contextOutsideRestore q h
 simp only [Aligned,and_assoc] at hc
 rcases hc with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 dsimp only [Aligned,commitNext]
 simp only [commitGuard] at g
 simp_all
 all_goals omega
end FrameActivation
