import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem casChildLocalInvariant (q : State) (h : Safe q) (g : casChildLocalGuard q) : Invariant (casChildLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casChildLocalNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · have use : LogFacts q := dLog
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [LogFacts] at use
   dsimp only [LogFacts,casChildLocalNext]
   simp only [casChildLocalGuard] at g
   simp_all
   all_goals omega
 · exact dPublished
 · exact dSplitter
 · have use : ChildFacts q := dChild
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [ChildFacts] at use
   dsimp only [ChildFacts,casChildLocalNext]
   simp only [casChildLocalGuard] at g
   simp_all
   all_goals omega
 · have use : A0Facts q ∧ LogFacts q := ⟨dA0,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [A0Facts,LogFacts] at use
   dsimp only [A0Facts,casChildLocalNext]
   simp only [casChildLocalGuard] at g
   simp_all
   all_goals omega
 · have use : A1Facts q ∧ LogFacts q := ⟨dA1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [A1Facts,LogFacts] at use
   dsimp only [A1Facts,casChildLocalNext]
   simp only [casChildLocalGuard] at g
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
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [R0Facts,LogFacts] at use
   dsimp only [R0Facts,casChildLocalNext]
   simp only [casChildLocalGuard] at g
   simp_all
   all_goals omega
 · have use : R1Facts q ∧ LogFacts q := ⟨dR1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [R1Facts,LogFacts] at use
   dsimp only [R1Facts,casChildLocalNext]
   simp only [casChildLocalGuard] at g
   simp_all
   all_goals omega
theorem casChildSplitInvariant (q : State) (h : Safe q) (g : casChildSplitGuard q) : Invariant (casChildSplitNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casChildSplitNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · have use : LogFacts q := dLog
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [LogFacts] at use
   dsimp only [LogFacts,casChildSplitNext]
   simp only [casChildSplitGuard] at g
   simp_all
   all_goals omega
 · exact dPublished
 · exact dSplitter
 · have use : ChildFacts q := dChild
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [ChildFacts] at use
   dsimp only [ChildFacts,casChildSplitNext]
   simp only [casChildSplitGuard] at g
   simp_all
   all_goals omega
 · have use : A0Facts q ∧ LogFacts q := ⟨dA0,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [A0Facts,LogFacts] at use
   dsimp only [A0Facts,casChildSplitNext]
   simp only [casChildSplitGuard] at g
   simp_all
   all_goals omega
 · have use : A1Facts q ∧ LogFacts q := ⟨dA1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [A1Facts,LogFacts] at use
   dsimp only [A1Facts,casChildSplitNext]
   simp only [casChildSplitGuard] at g
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
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [R0Facts,LogFacts] at use
   dsimp only [R0Facts,casChildSplitNext]
   simp only [casChildSplitGuard] at g
   simp_all
   all_goals omega
 · have use : R1Facts q ∧ LogFacts q := ⟨dR1,dLog⟩
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [R1Facts,LogFacts] at use
   dsimp only [R1Facts,casChildSplitNext]
   simp only [casChildSplitGuard] at g
   simp_all
   all_goals omega
theorem casCloseLocalInvariant (q : State) (h : Safe q) (g : casCloseLocalGuard q) : Invariant (casCloseLocalNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casCloseLocalNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · have use : ChildFacts q := dChild
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [ChildFacts] at use
   dsimp only [ChildFacts,casCloseLocalNext]
   simp only [casCloseLocalGuard] at g
   simp_all
   all_goals omega
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem childNativeFailureInvariant (q : State) (h : Safe q) (g : childNativeFailureGuard q) : Invariant (childNativeFailureNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (childNativeFailureNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · have use : ChildFacts q := dChild
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [ChildFacts] at use
   dsimp only [ChildFacts,childNativeFailureNext]
   simp only [childNativeFailureGuard] at g
   simp_all
   all_goals omega
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem childLegacyFailureInvariant (q : State) (h : Safe q) (g : childLegacyFailureGuard q) : Invariant (childLegacyFailureNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (childLegacyFailureNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · have use : ChildFacts q := dChild
   have hparent := ((safeEquivalent q).mp h).1
   have hb := ControlWord.nativeBounds (parent q) hparent
   dsimp only [parent] at hb
   have hp := ((ControlWord.safeEquivalent (parent q)).mp hparent).2
   dsimp only [ControlWord.Invariant,parent] at hp
   clear h hc hparent dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [ChildFacts] at use
   dsimp only [ChildFacts,childLegacyFailureNext]
   simp only [childLegacyFailureGuard] at g
   simp_all
   all_goals omega
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem deliverChildInvariant (q : State) (h : Safe q) (g : deliverChildGuard q) : Invariant (deliverChildNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (deliverChildNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · exact dPublished
 · exact dSplitter
 · have use : ChildFacts q := dChild
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [ChildFacts] at use
   dsimp only [ChildFacts,deliverChildNext]
   simp only [deliverChildGuard] at g
   simp_all
   all_goals omega
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
end AtomicOwner
