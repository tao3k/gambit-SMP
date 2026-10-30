import WillCutAst
namespace WillCut
open WillCutAst
set_option maxHeartbeats 4000000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem strongReachablePreserves (q : State) (h : Safe q) (g : strongReachableGuard q) : Safe (strongReachableNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,strongReachableGuard,strongReachableNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,strongReachableGuard,strongReachableNext]
theorem decideAPreserves (q : State) (h : Safe q) (g : decideAGuard q) : Safe (decideANext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,decideAGuard,decideANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,decideAGuard,decideANext]
theorem decideBPreserves (q : State) (h : Safe q) (g : decideBGuard q) : Safe (decideBNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,decideBGuard,decideBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,decideBGuard,decideBNext]
theorem legacyDecideAPreserves (q : State) (h : Safe q) (g : legacyDecideAGuard q) : Safe (legacyDecideANext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,legacyDecideAGuard,legacyDecideANext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,legacyDecideAGuard,legacyDecideANext]
theorem legacyDecideBPreserves (q : State) (h : Safe q) (g : legacyDecideBGuard q) : Safe (legacyDecideBNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,legacyDecideBGuard,legacyDecideBNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,legacyDecideBGuard,legacyDecideBNext]
theorem classifyCutPreserves (q : State) (h : Safe q) (g : classifyCutGuard q) : Safe (classifyCutNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,classifyCutGuard,classifyCutNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,classifyCutGuard,classifyCutNext]
theorem weakMarkPreserves (q : State) (h : Safe q) (g : weakMarkGuard q) : Safe (weakMarkNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,weakMarkGuard,weakMarkNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,weakMarkGuard,weakMarkNext]
theorem finishPreserves (q : State) (h : Safe q) (g : finishGuard q) : Safe (finishNext q) := by
 by_cases hm:q.managed=true
 · have hs := h hm
   rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
   simp_all [Safe,finishGuard,finishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 · simp_all [Safe,finishGuard,finishNext]
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8
 · rcases a0 with ⟨g,rfl⟩; exact strongReachablePreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact decideAPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact decideBPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact legacyDecideAPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact legacyDecideBPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact classifyCutPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact weakMarkPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact finishPreserves q h g
 · rw [a8]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem sharedDecision (q : State) (h : Safe q) (hm : q.managed=true) (ha : q.da=true) (hb : q.db=true) : q.ea=q.eb := by
 have hs := h hm; rcases hs with ⟨h0,h1,h2,h3,h4,h5⟩
 have := h5 ⟨ha,hb⟩
 cases he:q.ea <;> cases hf:q.eb <;> simp_all
theorem legacyDisagreement :
 (legacyDecideBNext (weakMarkNext (legacyDecideANext {initial with managed:=false}))).ea=true ∧
 (legacyDecideBNext (weakMarkNext (legacyDecideANext {initial with managed:=false}))).eb=false := by
 simp [legacyDecideBNext,weakMarkNext,legacyDecideANext,initial]
end WillCut
