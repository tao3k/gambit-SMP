import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem loadReserveInvariant (q : State) (h : Safe q) (g : loadReserveGuard q) : Invariant (loadReserveNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem loadCommitInvariant (q : State) (h : Safe q) (g : loadCommitGuard q) : Invariant (loadCommitNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem loadAbortInvariant (q : State) (h : Safe q) (g : loadAbortGuard q) : Invariant (loadAbortNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 exact hc
theorem casReserveInvariant (q : State) (h : Safe q) (g : casReserveGuard q) : Invariant (casReserveNext q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (casReserveNext q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
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
   dsimp only [SplitterFacts,casReserveNext]
   simp only [casReserveGuard] at g
   simp_all
   all_goals omega
 · exact dChild
 · exact dA0
 · exact dA1
 · exact dW0
 · exact dW1
 · exact dR0
 · exact dR1
end AtomicOwner
