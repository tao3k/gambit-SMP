import SizeGuardAst
import SizeHoldAst
open SizeGuardAst
namespace SizeGuardBridge
-- Boundary/effect bridge only; no native C or full state-machine simulation.
def parentReady (q : State) : SizeHoldAst.State :=
 {SizeHoldAst.initial with phase:=3,direction:=q.direction,created:=q.created,hold:=q.hold,effects:=q.effects,root:=q.lang,captured:=q.captured,gc:=q.gc,exited:=1}
theorem normalDropBoundary (q : State) (h : Safe q) (g : claimDropGuard q) (normal : q.outcome=1) : SizeHoldAst.Safe (parentReady q) ∧ SizeHoldAst.enterDropGuard (parentReady q) := by
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28,h29,h30,h31,h32,h33,h34,h35,h36,h37,h38,h39,h40,h41,h42,h43,h44,h45,h46,h47,h48,h49,h50,h51,h52,h53,h54,h55,h56,h57,h58,h59,h60,h61,h62,h63,h64,h65,h66,h67,h68,h69,h70,h71,h72,h73,h74⟩
 simp only [claimDropGuard] at g
 dsimp only [SizeHoldAst.Safe,SizeHoldAst.enterDropGuard,parentReady,SizeHoldAst.initial]
 repeat' apply And.intro
 all_goals first | assumption | decide | (simp_all; omega) | grind
theorem dropEffectAgreement (q : State) :
 (SizeHoldAst.physicalDropNext (SizeHoldAst.enterDropNext (parentReady q))).hold = (physicalDropNext (claimDropNext q)).hold ∧
 (SizeHoldAst.physicalDropNext (SizeHoldAst.enterDropNext (parentReady q))).effects = (physicalDropNext (claimDropNext q)).effects := by
 exact ⟨rfl,rfl⟩
theorem abortedCfunNeedsNoFakeReturn : ∃ q : State,
 Safe q ∧ claimDropGuard q ∧ q.outcome=2 ∧ q.direction=1 ∧ q.lang=0 ∧ ¬ SizeHoldAst.enterDropGuard (parentReady q) := by
 let q : State := {initial with phase:=4,direction:=1,created:=1,hold:=1,carrier:=1,guard:=1,attempt:=1,exited:=1,outcome:=2}
 refine ⟨q, ?_, ?_, rfl,rfl,rfl, ?_⟩
 · simp [q,Safe,initial]
 · simp [q,claimDropGuard,initial]
 · simp [q,parentReady,initial,SizeHoldAst.initial,SizeHoldAst.enterDropGuard]
end SizeGuardBridge
