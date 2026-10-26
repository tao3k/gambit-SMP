import CapacityChargeAst
namespace CapacityCharge
open CapacityChargeAst
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem reserveOnePreserves (q : State) (h : Safe q) (g : reserveOneGuard q) : Safe (reserveOneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,reserveOneGuard,reserveOneNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveNearPreserves (q : State) (h : Safe q) (g : reserveNearGuard q) : Safe (reserveNearNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,reserveNearGuard,reserveNearNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveOvershootPreserves (q : State) (h : Safe q) (g : reserveOvershootGuard q) : Safe (reserveOvershootNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,reserveOvershootGuard,reserveOvershootNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem publishForwardPreserves (q : State) (h : Safe q) (g : publishForwardGuard q) : Safe (publishForwardNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,publishForwardGuard,publishForwardNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem commitPreserves (q : State) (h : Safe q) (g : commitGuard q) : Safe (commitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,commitGuard,commitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem cancelPreserves (q : State) (h : Safe q) (g : cancelGuard q) : Safe (cancelNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,cancelGuard,cancelNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeThresholdPreserves (q : State) (h : Safe q) (g : closeThresholdGuard q) : Safe (closeThresholdNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,closeThresholdGuard,closeThresholdNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem observeNoFitPreserves (q : State) (h : Safe q) (g : observeNoFitGuard q) : Safe (observeNoFitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,observeNoFitGuard,observeNoFitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeEarlyPreserves (q : State) (h : Safe q) (g : closeEarlyGuard q) : Safe (closeEarlyNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,closeEarlyGuard,closeEarlyNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem advanceVisitPreserves (q : State) (h : Safe q) (g : advanceVisitGuard q) : Safe (advanceVisitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,advanceVisitGuard,advanceVisitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem cutToWeakPreserves (q : State) (h : Safe q) (g : cutToWeakGuard q) : Safe (cutToWeakNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,cutToWeakGuard,cutToWeakNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeCapacityPreserves (q : State) (h : Safe q) (g : closeCapacityGuard q) : Safe (closeCapacityNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [Safe,closeCapacityGuard,closeCapacityNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12
 · rcases a0 with ⟨g,rfl⟩; exact reserveOnePreserves q h g
 · rcases a1 with ⟨g,rfl⟩; exact reserveNearPreserves q h g
 · rcases a2 with ⟨g,rfl⟩; exact reserveOvershootPreserves q h g
 · rcases a3 with ⟨g,rfl⟩; exact publishForwardPreserves q h g
 · rcases a4 with ⟨g,rfl⟩; exact commitPreserves q h g
 · rcases a5 with ⟨g,rfl⟩; exact cancelPreserves q h g
 · rcases a6 with ⟨g,rfl⟩; exact closeThresholdPreserves q h g
 · rcases a7 with ⟨g,rfl⟩; exact observeNoFitPreserves q h g
 · rcases a8 with ⟨g,rfl⟩; exact closeEarlyPreserves q h g
 · rcases a9 with ⟨g,rfl⟩; exact advanceVisitPreserves q h g
 · rcases a10 with ⟨g,rfl⟩; exact cutToWeakPreserves q h g
 · rcases a11 with ⟨g,rfl⟩; exact closeCapacityPreserves q h g
 · rw [a12]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem thresholdHasSpace (q : State) (h : Safe q) (g : closeThresholdGuard q) : q.starts<q.capacity := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [closeThresholdGuard] <;> omega
theorem visitHasSpace (q : State) (h : Safe q) (g : advanceVisitGuard q) : q.starts<q.capacity := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all [advanceVisitGuard] <;> omega
theorem exactBirthCount (q : State) (h : Safe q) : q.starts=q.thresholds+q.visits := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 omega
theorem tightCeiling (q : State) (h : Safe q) : q.starts<=q.limitWords/255+q.visitBudget := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 omega
theorem cutCarriesState (q : State) : let r:=cutToWeakNext q;
 r.starts=q.starts ∧ r.visits=q.visits ∧ r.span=q.span ∧ r.committed=q.committed ∧ r.closedSpan=q.closedSpan ∧ r.thresholds=q.thresholds ∧ r.markers=q.markers := by simp [cutToWeakNext]
theorem cancellationKeepsTopology (q : State) : let r:=cancelNext q;
 r.starts=q.starts ∧ r.visits=q.visits ∧ r.markers=q.markers ∧ r.span=q.span ∧ r.committed=q.committed := by simp [cancelNext]
theorem partialCloseKeepsNode (q : State) : (closeEarlyNext q).starts=q.starts ∧ (closeEarlyNext q).markers=q.markers+1 := by simp [closeEarlyNext]
theorem forwardingNeedsGrant (q : State) (h : Safe q) (f : q.forwarded=true) : q.grant>0 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all
theorem retainedStrongOccupancy (q : State) (h : Safe q) (hp : q.phase>=1) : q.cutStarts<=q.starts ∧ q.cutWords<=q.committed ∧ q.cutVisits<=q.visits := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30⟩
 simp_all
theorem separatelyRoundedPhasesLoseCarry : (254:Int)/255+1/255 < (254+1)/255 := by decide
structure LeaseCharge where
  words : Int
  thresholds : Int
def totalThresholds : List LeaseCharge → Int
  | [] => 0
  | x::xs => x.thresholds+totalThresholds xs
def totalCeilings : List LeaseCharge → Int
  | [] => 0
  | x::xs => x.words/255+1+totalCeilings xs
theorem leaseSumBound (ls : List LeaseCharge)
 (h : ∀ x, x∈ls → 0<=x.words ∧ 0<=x.thresholds ∧ 255*x.thresholds<=x.words) :
 totalThresholds ls + Int.ofNat ls.length <= totalCeilings ls := by
 induction ls with
 | nil => simp [totalThresholds,totalCeilings]
 | cons x xs ih =>
  have hx := h x (by simp)
  have ht := ih (by intro y hy; exact h y (by simp [hy]))
  simp only [Int.ofNat_eq_natCast] at ht
  simp only [totalThresholds,totalCeilings,List.length_cons,Int.ofNat_eq_natCast,Int.natCast_add,Int.natCast_one]
  omega
end CapacityCharge

