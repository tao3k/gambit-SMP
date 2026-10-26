import ContinuationRestore
import CapacityCollective
namespace RestoreAdmissionComposition
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
-- Source-span theorem is conditional on real provenance, checked arithmetic and frozen pointers.
theorem sourceSpanBound (lo fp br top B H : Int)
 (size : top-lo=H) (first : 0≤B) (order : lo≤fp ∧ fp≤br ∧ br+B≤top) :
 B≤br+B-fp ∧ br+B-fp≤H := by omega
-- Source stack-limit uses 2/3 only on one path: it cannot imply the quarter fit.
theorem thresholdDoesNotImplyQuarter :
 (65536: Int)=4*12287+2*8194+0 ∧ (24576: Int)%4=0 ∧
 24576-4≤(65536-8194)*2/3 ∧ 24576>12287+8194 := by decide
-- Copy footprint includes first-break metadata; this is not permission to resume mutators.
theorem actualWriteSeparation (H K R E B : Int)
 (bounds : 3≤B ∧ B≤R ∧ R≤K ∧ K≤H ∧ E≤H-K) :
 E≤H-R ∧ H-R+2<H ∧ 0≤H-R := by omega
theorem resumeHeadroom (H K R F : Int) (h : R+F≤K ∧ K≤H) :
 F≤K-R ∧ 0≤H-R-F := by omega
theorem restrictFallbackCount (P F S N eligible : Int)
 (h : 0≤P ∧ F≤N-2*P ∧ S≤eligible ∧ eligible≤P) : P+F+S≤N := by omega
-- No native allocation is invented here: dedicated means the already-assigned stack section.
def Coupled (p : ContinuationRestoreAst.State) (c : CapacityCollectiveAst.State) : Prop :=
 ContinuationRestoreAst.Safe p ∧ CapacityCollectiveAst.Safe c ∧
 (c.published=true → p.outcome>0) ∧
 (c.poolReady=true → p.outcome=1) ∧
 (c.published=true → c.poolReady=false → p.outcome=2)
def PublicationGate (p : ContinuationRestoreAst.State) (c d : CapacityCollectiveAst.State) : Prop :=
 (c.published=false ∧ d.published=true) →
 ((d.poolReady=true → p.outcome=1) ∧ (d.poolReady=false → p.outcome=2))
theorem initialCoupled : Coupled ContinuationRestoreAst.initial CapacityCollectiveAst.initial := by
 simp [Coupled,ContinuationRestoreAst.Safe,CapacityCollectiveAst.Safe,
 ContinuationRestoreAst.initial,CapacityCollectiveAst.initial]
theorem planPreserves (p r : ContinuationRestoreAst.State) (c : CapacityCollectiveAst.State)
 (h : Coupled p c) (st : ContinuationRestoreAst.Step p r) : Coupled r c := by
 rcases h with ⟨ps,cs,pub,ready,rejected⟩
 have rs := ContinuationRestore.stepPreserves p r ps st
 have stable : p.outcome>0 → r.outcome=p.outcome := fun pos => ContinuationRestore.sealedOutcomeStable p r ps pos st
 refine ⟨rs,cs,?_,?_,?_⟩
 · intro cp; rw [stable (pub cp)]; exact pub cp
 · intro cp; have po := ready cp; have pos : p.outcome>0 := by omega
   rw [stable pos]; exact po
 · intro cp cf; have po := rejected cp cf; have pos : p.outcome>0 := by omega
   rw [stable pos]; exact po
theorem collectivePreserves (p : ContinuationRestoreAst.State) (c d : CapacityCollectiveAst.State)
 (h : Coupled p c) (st : CapacityCollectiveAst.Step c d) (gate : PublicationGate p c d) : Coupled p d := by
 have ds := CapacityCollective.stepPreserves c d h.2.1 st
 rcases h with ⟨ps,cs,pub,ready,rejected⟩
 refine ⟨ps,ds,?_,?_,?_⟩ <;>
  (rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18)
 all_goals first
 | rcases a0 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishReadyGuard,CapacityCollectiveAst.publishReadyNext] <;> omega
 | rcases a1 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishFailureGuard,CapacityCollectiveAst.publishFailureNext] <;> omega
 | rcases a2 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept0Guard,CapacityCollectiveAst.accept0Next] <;> omega
 | rcases a3 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept1Guard,CapacityCollectiveAst.accept1Next] <;> omega
 | rcases a4 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject0Guard,CapacityCollectiveAst.reject0Next] <;> omega
 | rcases a5 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject1Guard,CapacityCollectiveAst.reject1Next] <;> omega
 | rcases a6 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideAcceptGuard,CapacityCollectiveAst.decideAcceptNext] <;> omega
 | rcases a7 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideRejectGuard,CapacityCollectiveAst.decideRejectNext] <;> omega
 | rcases a8 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge0Guard,CapacityCollectiveAst.acknowledge0Next] <;> omega
 | rcases a9 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge1Guard,CapacityCollectiveAst.acknowledge1Next] <;> omega
 | rcases a10 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.releaseGuard,CapacityCollectiveAst.releaseNext] <;> omega
 | rcases a11 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip0Guard,CapacityCollectiveAst.flip0Next] <;> omega
 | rcases a12 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip1Guard,CapacityCollectiveAst.flip1Next] <;> omega
 | rcases a13 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver0Guard,CapacityCollectiveAst.deliver0Next] <;> omega
 | rcases a14 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver1Guard,CapacityCollectiveAst.deliver1Next] <;> omega
 | rcases a15 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainUnknownGuard,CapacityCollectiveAst.retainUnknownNext] <;> omega
 | rcases a16 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainSetupUnknownGuard,CapacityCollectiveAst.retainSetupUnknownNext] <;> omega
 | rcases a17 with ⟨g,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.freeRejectedGuard,CapacityCollectiveAst.freeRejectedNext] <;> omega
 | rw [a18]; assumption
inductive Reachable : ContinuationRestoreAst.State → CapacityCollectiveAst.State → Prop where
 | start : Reachable ContinuationRestoreAst.initial CapacityCollectiveAst.initial
 | plan {p r c} : Reachable p c → ContinuationRestoreAst.Step p r → Reachable r c
 | collective {p c d} : Reachable p c → CapacityCollectiveAst.Step c d → PublicationGate p c d → Reachable p d
theorem reachableCoupled (p c) (h : Reachable p c) : Coupled p c := by
 induction h with
 | start => exact initialCoupled
 | plan _ st ih => exact planPreserves _ _ _ ih st
 | collective _ st gate ih => exact collectivePreserves _ _ _ ih st gate
theorem setupRequiresValidBounds (p c) (h : Coupled p c) (flip : c.flip0=true ∨ c.flip1=true) :
 p.r0+8≤p.cap0 ∧ p.r1+8≤p.cap1 ∧ c.ack0=true ∧ c.ack1=true := by
 have cut := CapacityCollective.flipRequiresAllAcknowledged c h.2.1 flip
 have ready : c.poolReady=true := by
  have cs := h.2.1
  simp only [CapacityCollectiveAst.Safe] at cs
  rcases cs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
  simp_all <;> omega
 have bounds := ContinuationRestore.acceptedBounds p h.1 (h.2.2.2.1 ready)
 exact ⟨bounds.2.2.1,bounds.2.2.2,cut.2.2.1,cut.2.2.2.1⟩
theorem rejectedPlanCannotSetup (p c) (h : Coupled p c) (rej : p.outcome=2) :
 c.flip0=false ∧ c.flip1=false := by
 have notReady : c.poolReady≠true := by intro r; have := h.2.2.2.1 r; omega
 have cs := h.2.1
 simp only [CapacityCollectiveAst.Safe] at cs
 rcases cs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
 simp_all <;> omega
-- Non-vacuity: actual large-R plan reaches both setup slot effects through the original actions.
theorem largeDedicatedSetupReachable : ∃ p c, Reachable p c ∧ p.r1=24 ∧ p.mode1=2 ∧ c.flip0=true ∧ c.flip1=true := by
 let p0 := ContinuationRestoreAst.initial
 let p1 := ContinuationRestoreAst.freezeLargeNext p0
 let p2 := ContinuationRestoreAst.share0Next p1
 let p3 := ContinuationRestoreAst.dedicate1Next p2
 let p4 := ContinuationRestoreAst.sealAcceptNext p3
 let c0 := CapacityCollectiveAst.initial
 let c1 := CapacityCollectiveAst.publishReadyNext c0
 let c2 := CapacityCollectiveAst.accept0Next c1
 let c3 := CapacityCollectiveAst.accept1Next c2
 let c4 := CapacityCollectiveAst.decideAcceptNext c3
 let c5 := CapacityCollectiveAst.acknowledge0Next c4
 let c6 := CapacityCollectiveAst.acknowledge1Next c5
 let c7 := CapacityCollectiveAst.releaseNext c6
 let c8 := CapacityCollectiveAst.flip0Next c7
 let c9 := CapacityCollectiveAst.flip1Next c8
 have h0 : Reachable p0 c0 := Reachable.start
 have h1 : Reachable p1 c0 := Reachable.plan h0 (by exact Or.inr (Or.inl ⟨by simp [p0,p1,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.freezeLargeGuard],rfl⟩))
 have h2 : Reachable p2 c0 := Reachable.plan h1 (by exact Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [p0,p1,p2,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.share0Guard],rfl⟩))))
 have h3 : Reachable p3 c0 := Reachable.plan h2 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [p0,p1,p2,p3,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.dedicate1Guard],rfl⟩)))))))
 have h4 : Reachable p4 c0 := Reachable.plan h3 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,ContinuationRestoreAst.sealAcceptGuard],rfl⟩))))))))))
 have h5 : Reachable p4 c1 := Reachable.collective h4 (by exact Or.inl ⟨by simp [c0,c1,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.publishReadyGuard],rfl⟩) (by simp [PublicationGate,c0,c1,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.publishReadyGuard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h6 : Reachable p4 c2 := Reachable.collective h5 (by exact Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept0Guard],rfl⟩))) (by simp [PublicationGate,c0,c1,c2,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept0Guard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h7 : Reachable p4 c3 := Reachable.collective h6 (by exact Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.accept1Guard],rfl⟩)))) (by simp [PublicationGate,c0,c1,c2,c3,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.accept1Guard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h8 : Reachable p4 c4 := Reachable.collective h7 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.decideAcceptGuard],rfl⟩))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.decideAcceptGuard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h9 : Reachable p4 c5 := Reachable.collective h8 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge0Guard],rfl⟩))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge0Guard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h10 : Reachable p4 c6 := Reachable.collective h9 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.acknowledge1Guard],rfl⟩)))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.acknowledge1Guard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h11 : Reachable p4 c7 := Reachable.collective h10 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,c7,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.releaseGuard],rfl⟩))))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,c7,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.releaseGuard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h12 : Reachable p4 c8 := Reachable.collective h11 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,c7,c8,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip0Guard],rfl⟩)))))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,c7,c8,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip0Guard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 have h13 : Reachable p4 c9 := Reachable.collective h12 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip1Next,CapacityCollectiveAst.flip1Guard],rfl⟩))))))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip1Next,CapacityCollectiveAst.flip1Guard,p0,p1,p2,p3,p4,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.share0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext])
 refine ⟨p4,c9,h13,?_,?_,?_,?_⟩ <;> rfl
end RestoreAdmissionComposition
