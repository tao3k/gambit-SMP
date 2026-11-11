import AtomicOwnerMaps
namespace AtomicOwner
open AtomicOwnerAst
theorem activateA0Invariant (q : State) (h : Safe q) (g : activateA0Guard q) : Invariant (activateA0Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (activateA0Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q ∧ A0Facts q := ⟨dPublished,dA0⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [PublishedFacts,A0Facts] at use
   dsimp only [PublishedFacts,activateA0Next]
   simp only [activateA0Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · have use : W0Facts q ∧ PublishedFacts q := ⟨dW0,dPublished⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [W0Facts,PublishedFacts] at use
   dsimp only [W0Facts,activateA0Next]
   simp only [activateA0Guard] at g
   simp_all
   all_goals omega
 · have use : W1Facts q ∧ PublishedFacts q := ⟨dW1,dPublished⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [W1Facts,PublishedFacts] at use
   dsimp only [W1Facts,activateA0Next]
   simp only [activateA0Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · exact dR1
theorem activateA1Invariant (q : State) (h : Safe q) (g : activateA1Guard q) : Invariant (activateA1Next q) := by
 have hc := ((safeEquivalent q).mp h).2
 obtain ⟨dLog,dPublished,dSplitter,dChild,dA0,dA1,dW0,dW1,dR0,dR1⟩ := (domainsEquivalent q).mp hc
 refine (domainsEquivalent (activateA1Next q)).mpr ⟨?_,?_,?_,?_,?_,?_,?_,?_,?_,?_⟩
 · exact dLog
 · have use : PublishedFacts q ∧ A1Facts q := ⟨dPublished,dA1⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [PublishedFacts,A1Facts] at use
   dsimp only [PublishedFacts,activateA1Next]
   simp only [activateA1Guard] at g
   simp_all
   all_goals omega
 · exact dSplitter
 · exact dChild
 · exact dA0
 · exact dA1
 · have use : W0Facts q ∧ PublishedFacts q := ⟨dW0,dPublished⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [W0Facts,PublishedFacts] at use
   dsimp only [W0Facts,activateA1Next]
   simp only [activateA1Guard] at g
   simp_all
   all_goals omega
 · have use : W1Facts q ∧ PublishedFacts q := ⟨dW1,dPublished⟩
   clear h hc dLog dPublished dSplitter dChild dA0 dA1 dW0 dW1 dR0 dR1
   dsimp only [W1Facts,PublishedFacts] at use
   dsimp only [W1Facts,activateA1Next]
   simp only [activateA1Guard] at g
   simp_all
   all_goals omega
 · exact dR0
 · exact dR1
end AtomicOwner
