import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem casCommitInvariant (q : State) (h : Safe q) (g : casCommitGuard q) : Invariant (casCommitNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casCommitNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · have use : LogFacts q := dLog
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [LogFacts] at use
   dsimp only [LogFacts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · exact dPublished
 · have use : SplitterFacts q := dSplitter
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [SplitterFacts] at use
   dsimp only [SplitterFacts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · have use : A0Facts q ∧ LogFacts q := ⟨dA0,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [A0Facts,LogFacts] at use
   dsimp only [A0Facts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · have use : A1Facts q ∧ LogFacts q := ⟨dA1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [A1Facts,LogFacts] at use
   dsimp only [A1Facts,casCommitNext]
   simp only [casCommitGuard] at g
   simp_all
   all_goals omega
 · exact dW0
 · exact dW1
 · have use : R0Facts q ∧ LogFacts q := ⟨dR0,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [R0Facts,LogFacts] at use
   dsimp only [R0Facts,casCommitNext]
   simp only [casCommitGuard] at g
   have noCommit : q.commitRelease=0 := by omega
   simp_all
   all_goals omega
 · have use : R1Facts q ∧ LogFacts q := ⟨dR1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [R1Facts,LogFacts] at use
   dsimp only [R1Facts,casCommitNext]
   simp only [casCommitGuard] at g
   have noCommit : q.commitRelease=0 := by omega
   simp_all
   all_goals omega
theorem casAbortInvariant (q : State) (h : Safe q) (g : casAbortGuard q) : Invariant (casAbortNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casAbortNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · have use : SplitterFacts q := dSplitter
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [SplitterFacts] at use
   dsimp only [SplitterFacts,casAbortNext]
   simp only [casAbortGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem loadChildInvariant (q : State) (h : Safe q) (g : loadChildGuard q) : Invariant (loadChildNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem loadLocalInvariant (q : State) (h : Safe q) (g : loadLocalGuard q) : Invariant (loadLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
end AtomicOwner
