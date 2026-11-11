import CapacityCharge
import NodePool
namespace CapacityChargeComposition
abbrev C := CapacityChargeAst.State
abbrev P := NodePoolAst.State
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
def Bound (q : C) (p : P) : Prop := p.capacity=q.capacity ∧ p.budget=q.capacity ∧ p.issued=q.starts
def Good (q : C) (p : P) : Prop := CapacityChargeAst.Safe q ∧ NodePoolAst.Safe p ∧ Bound q p ∧ (q.phase<2 → p.phase=1)
def poolInitial : P := {NodePoolAst.initial with capacity:=7,budget:=7,phase:=1,admitted:=true,issued:=1,privateNodes:=1,debt:=1,receipts:=1,kind:=4}
theorem initialGood : Good CapacityChargeAst.initial poolInitial := by simp [Good,Bound,poolInitial,CapacityChargeAst.Safe,CapacityChargeAst.initial,NodePoolAst.Safe,NodePoolAst.initial]
theorem thresholdRoom (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.closeThresholdGuard q) : p.issued<p.budget := by
 have room := CapacityCharge.thresholdHasSpace q h.1 g
 rcases h with ⟨hc,hp,hb,hl⟩
 simp only [Bound] at hb
 omega
theorem visitRoom (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.advanceVisitGuard q) : p.issued<p.budget := by
 have room := CapacityCharge.visitHasSpace q h.1 g
 rcases h with ⟨hc,hp,hb,hl⟩
 simp only [Bound] at hb
 omega
theorem thresholdRoot (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.closeThresholdGuard q) (hp : p.phase=1) (pr : ¬p.rootsClosed=true) : Good (CapacityChargeAst.closeThresholdNext q) (NodePoolAst.reserveNext p) := by
 have room := thresholdRoom q p h g
 have pg : NodePoolAst.reserveGuard p := by simp_all [NodePoolAst.reserveGuard]
 have cs := CapacityCharge.closeThresholdPreserves q h.1 g
 have ps := NodePool.reservePreserves p h.2.1 pg
 rcases h with ⟨hc,hs,hb,hl⟩
 refine ⟨cs,ps,?_,?_⟩
 · simp_all [Bound,CapacityChargeAst.closeThresholdNext,NodePoolAst.reserveNext]
 · simp [NodePoolAst.reserveNext,hp]
theorem thresholdChild (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.closeThresholdGuard q) (hp : p.phase=1) (pr : p.debt>0) : Good (CapacityChargeAst.closeThresholdNext q) (NodePoolAst.deriveNext p) := by
 have room := thresholdRoom q p h g
 have pg : NodePoolAst.deriveGuard p := by simp_all [NodePoolAst.deriveGuard]
 have cs := CapacityCharge.closeThresholdPreserves q h.1 g
 have ps := NodePool.derivePreserves p h.2.1 pg
 rcases h with ⟨hc,hs,hb,hl⟩
 refine ⟨cs,ps,?_,?_⟩
 · simp_all [Bound,CapacityChargeAst.closeThresholdNext,NodePoolAst.deriveNext]
 · simp [NodePoolAst.deriveNext,hp]
theorem visitRoot (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.advanceVisitGuard q) (hp : p.phase=1) (pr : ¬p.rootsClosed=true) : Good (CapacityChargeAst.advanceVisitNext q) (NodePoolAst.reserveNext p) := by
 have room := visitRoom q p h g
 have pg : NodePoolAst.reserveGuard p := by simp_all [NodePoolAst.reserveGuard]
 have cs := CapacityCharge.advanceVisitPreserves q h.1 g
 have ps := NodePool.reservePreserves p h.2.1 pg
 rcases h with ⟨hc,hs,hb,hl⟩
 refine ⟨cs,ps,?_,?_⟩
 · simp_all [Bound,CapacityChargeAst.advanceVisitNext,NodePoolAst.reserveNext]
 · simp [NodePoolAst.reserveNext,hp]
theorem visitChild (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.advanceVisitGuard q) (hp : p.phase=1) (pr : p.debt>0) : Good (CapacityChargeAst.advanceVisitNext q) (NodePoolAst.deriveNext p) := by
 have room := visitRoom q p h g
 have pg : NodePoolAst.deriveGuard p := by simp_all [NodePoolAst.deriveGuard]
 have cs := CapacityCharge.advanceVisitPreserves q h.1 g
 have ps := NodePool.derivePreserves p h.2.1 pg
 rcases h with ⟨hc,hs,hb,hl⟩
 refine ⟨cs,ps,?_,?_⟩
 · simp_all [Bound,CapacityChargeAst.advanceVisitNext,NodePoolAst.deriveNext]
 · simp [NodePoolAst.deriveNext,hp]
inductive Step : C → P → C → P → Prop where
 | chargeOnly {q r p} : CapacityChargeAst.Step q r → r.starts=q.starts → r.capacity=q.capacity → p.phase=1 → Step q p r p
 | rootThreshold {q p} : CapacityChargeAst.closeThresholdGuard q → p.phase=1 → (¬p.rootsClosed=true) → Step q p (CapacityChargeAst.closeThresholdNext q) (NodePoolAst.reserveNext p)
 | childThreshold {q p} : CapacityChargeAst.closeThresholdGuard q → p.phase=1 → p.debt>0 → Step q p (CapacityChargeAst.closeThresholdNext q) (NodePoolAst.deriveNext p)
 | rootVisit {q p} : CapacityChargeAst.advanceVisitGuard q → p.phase=1 → (¬p.rootsClosed=true) → Step q p (CapacityChargeAst.advanceVisitNext q) (NodePoolAst.reserveNext p)
 | childVisit {q p} : CapacityChargeAst.advanceVisitGuard q → p.phase=1 → p.debt>0 → Step q p (CapacityChargeAst.advanceVisitNext q) (NodePoolAst.deriveNext p)
 | poolOnly {q p r} : NodePoolAst.Step p r → r.issued=p.issued → r.capacity=p.capacity → r.budget=p.budget → (q.phase<2 → r.phase=1) → Step q p q r

theorem stepPreserves (q r : C) (p t : P) (h : Good q p) (st : Step q p r t) : Good r t := by
 cases st with
 | chargeOnly cs count cap live =>
  rcases h with ⟨hc,hp,hb,hl⟩
  exact ⟨CapacityCharge.stepPreserves _ _ hc cs,hp,by simpa [Bound,count,cap] using hb,by intro _; exact live⟩
 | rootThreshold g hp pr => exact thresholdRoot _ _ h g hp pr
 | childThreshold g hp pr => exact thresholdChild _ _ h g hp pr
 | rootVisit g hp pr => exact visitRoot _ _ h g hp pr
 | childVisit g hp pr => exact visitChild _ _ h g hp pr
 | poolOnly ps count cap budget live =>
  rcases h with ⟨hc,hp,hb,hl⟩
  exact ⟨hc,NodePool.stepPreserves _ _ hp ps,by simpa [Bound,count,cap,budget] using hb,live⟩
inductive Reachable : C → P → Prop where
 | start : Reachable CapacityChargeAst.initial poolInitial
 | next {q p r t} : Reachable q p → Step q p r t → Reachable r t
theorem reachableGood (q : C) (p : P) (h : Reachable q p) : Good q p := by
 induction h with
 | start => exact initialGood
 | next _ st ih => exact stepPreserves _ _ _ _ ih st

theorem oldPoolPublicationDoesNotChangeCharge (q : C) (p : P) (h : Bound q p) : Bound q (NodePoolAst.publishNext p) := by simpa [Bound,NodePoolAst.publishNext] using h
theorem weakCutPreservesPoolRelation (q : C) (p : P) (h : Bound q p) : Bound (CapacityChargeAst.cutToWeakNext q) p := by simpa [Bound,CapacityChargeAst.cutToWeakNext] using h
-- Native allocation closure must precede old pool work completion / retirement.
theorem lifetimeCutNecessary : let q:=CapacityChargeAst.initial;
 let p:={poolInitial with phase:=2,privateNodes:=0,done:=1,debt:=0,rootsClosed:=true};
 NodePoolAst.Safe p ∧ Bound q p ∧ ¬Good q p := by simp [Good,Bound,poolInitial,CapacityChargeAst.initial,NodePoolAst.Safe,NodePoolAst.initial]
theorem reserveOneCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.reserveOneGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.reserveOneNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inl ⟨g,rfl⟩) rfl rfl hp)
theorem reserveNearCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.reserveNearGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.reserveNearNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inl ⟨g,rfl⟩)) rfl rfl hp)
theorem reserveOvershootCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.reserveOvershootGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.reserveOvershootNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩))) rfl rfl hp)
theorem publishForwardCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.publishForwardGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.publishForwardNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩)))) rfl rfl hp)
theorem commitCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.commitGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.commitNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩))))) rfl rfl hp)
theorem cancelCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.cancelGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.cancelNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩)))))) rfl rfl hp)
theorem observeNoFitCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.observeNoFitGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.observeNoFitNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩)))))))) rfl rfl hp)
theorem closeEarlyCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.closeEarlyGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.closeEarlyNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩))))))))) rfl rfl hp)
theorem cutToWeakCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.cutToWeakGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.cutToWeakNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩))))))))))) rfl rfl hp)
theorem closeCapacityCouples (q : C) (p : P) (h : Good q p) (g : CapacityChargeAst.closeCapacityGuard q) (hp : p.phase=1) : Good (CapacityChargeAst.closeCapacityNext q) p := by
 exact stepPreserves _ _ _ _ h (Step.chargeOnly (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨g,rfl⟩)))))))))))) rfl rfl hp)
end CapacityChargeComposition
