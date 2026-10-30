import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem splitNativeFailureInvariant (q : State) (h : Safe q) (g : splitNativeFailureGuard q) : Invariant (splitNativeFailureNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (splitNativeFailureNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
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
   dsimp only [SplitterFacts,splitNativeFailureNext]
   simp only [splitNativeFailureGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem splitLegacyFailureInvariant (q : State) (h : Safe q) (g : splitLegacyFailureGuard q) : Invariant (splitLegacyFailureNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (splitLegacyFailureNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
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
   dsimp only [SplitterFacts,splitLegacyFailureNext]
   simp only [splitLegacyFailureGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
theorem deliverSplitterInvariant (q : State) (h : Safe q) (g : deliverSplitterGuard q) : Invariant (deliverSplitterNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (deliverSplitterNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
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
   dsimp only [SplitterFacts,deliverSplitterNext]
   simp only [deliverSplitterGuard] at g
   simp_all
   all_goals omega
 · exact dChild
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
   clear h hparent hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
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
end AtomicOwner
