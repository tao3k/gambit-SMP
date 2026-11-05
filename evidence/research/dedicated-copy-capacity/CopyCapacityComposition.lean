import DedicatedCopy
import ContinuationRestore
import CapacityCollective
namespace CopyCapacityComposition
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
-- Charges must be an injection into validated source footprints; this does not construct that injection.
theorem destinationEnvelope (Q heap frames padding U : Int)
 (h : 0≤Q ∧ 0≤padding ∧ heap+frames≤Q ∧ U≤heap+frames+padding) : U≤Q+padding := by omega
theorem word32Envelope (Q padding U : Int) (h : 0≤padding ∧ padding≤Q ∧ U≤Q+padding) : U≤2*Q := by omega
theorem word64Envelope (Q U : Int) (h : U≤Q+0) : U≤Q := by omega
-- Every no-fit closed interval must consume distinct committed words/threshold markers.
theorem enoughHeapSections (B C G P K closed : Int)
 (positive : 0<C-G+1) (spent : closed*(C-G+1)≤B)
 (budget : B<(K-P+1)*(C-G+1)) : closed+P≤K := by
 by_cases ok : closed+P≤K
 · exact ok
 have order : K-P+1≤closed := by omega
 have m := Int.mul_le_mul_of_nonneg_right order (Int.le_of_lt positive)
 omega
theorem totalPhysicalBudget (N P K E closed : Int)
 (h : 0≤E ∧ P+K+E≤N ∧ closed+P≤K) :
 P+(closed+P)+E≤N := by omega
-- Two bins of 13 words cannot hold three non-splittable requests of 8, despite total 24<=26.
theorem fragmentationCounterexample : (24:Int)≤26 ∧ 8+8>13 ∧ 3>2 := by decide
-- Default constants with a QUALIFIED G cap, not an observed default maximum.
theorem illustrativePlan :
 (65536:Int)-3-8194+1=57340 ∧
 (2097152:Int)+2097152/255=2105376 ∧
 (2105376:Int)<(37:Int)*57340 ∧ (2105376:Int)/57340=36 := by decide
-- Generic supported reserve_copy cap degenerates to a one-word utilization guarantee.
theorem genericGrantBoundDegenerates (H : Int) : (H-3)-(H-3)+1=1 := by omega
def RestoreReady (r : ContinuationRestoreAst.State) : Prop :=
 r.outcome=1 ∧ r.mode0=2 ∧ r.mode1=2
def Coupled (g : DedicatedCopyAst.State) (r : ContinuationRestoreAst.State) (c : CapacityCollectiveAst.State) : Prop :=
 DedicatedCopyAst.Safe g ∧ ContinuationRestoreAst.Safe r ∧ CapacityCollectiveAst.Safe c ∧
 (c.poolReady=true → g.sealed=true ∧ RestoreReady r) ∧
 (c.published=true → c.poolReady=false → g.outcome=2) ∧
 (g.collecting=true → c.flip0=true ∧ c.flip1=true)
def PublicationGate (g : DedicatedCopyAst.State) (r : ContinuationRestoreAst.State) (c d : CapacityCollectiveAst.State) : Prop :=
 (c.published=false ∧ d.published=true) →
 ((d.poolReady=true → g.sealed=true ∧ RestoreReady r) ∧ (d.poolReady=false → g.outcome=2))
def WorkGate (g h : DedicatedCopyAst.State) (c : CapacityCollectiveAst.State) : Prop :=
 (c.published=true → h.outcome=g.outcome) ∧
 (g.collecting=false → h.collecting=true → c.flip0=true ∧ c.flip1=true)
theorem initialCoupled (r : ContinuationRestoreAst.State) (rs : ContinuationRestoreAst.Safe r) :
 Coupled DedicatedCopyAst.initial r CapacityCollectiveAst.initial := by
 simp [Coupled,DedicatedCopyAst.Safe,DedicatedCopyAst.initial,CapacityCollectiveAst.Safe,CapacityCollectiveAst.initial,rs]
theorem planPreserves (g h : DedicatedCopyAst.State) (r : ContinuationRestoreAst.State) (c : CapacityCollectiveAst.State)
 (prior : Coupled g r c) (st : DedicatedCopyAst.Step g h) (gate : WorkGate g h c) : Coupled h r c := by
 rcases prior with ⟨gs,rs,cs,ready,reject,started⟩
 have hs := DedicatedCopy.stepPreserves g h gs st
 refine ⟨hs,rs,cs,?_,?_,?_⟩
 · intro cp; have hr := ready cp
   have stable := DedicatedCopy.sealedStable g h gs hr.1 st
   exact ⟨stable.1,hr.2⟩
 · intro pub pool; rw [gate.1 pub]; exact reject pub pool
 · intro running
   by_cases old : g.collecting=true
   · exact started old
   · have off : g.collecting=false := by cases flag : g.collecting <;> simp_all
     exact gate.2 off running
theorem collectivePreserves (g : DedicatedCopyAst.State) (r : ContinuationRestoreAst.State) (c d : CapacityCollectiveAst.State)
 (prior : Coupled g r c) (st : CapacityCollectiveAst.Step c d) (gate : PublicationGate g r c d) : Coupled g r d := by
 have ds := CapacityCollective.stepPreserves c d prior.2.2.1 st
 rcases prior with ⟨gs,rs,cs,ready,reject,started⟩
 refine ⟨gs,rs,ds,?_,?_,?_⟩
 · rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
   · rcases a0 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishReadyGuard,CapacityCollectiveAst.publishReadyNext]
   · rcases a1 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishFailureGuard,CapacityCollectiveAst.publishFailureNext]
   · rcases a2 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept0Guard,CapacityCollectiveAst.accept0Next]
   · rcases a3 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept1Guard,CapacityCollectiveAst.accept1Next]
   · rcases a4 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject0Guard,CapacityCollectiveAst.reject0Next]
   · rcases a5 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject1Guard,CapacityCollectiveAst.reject1Next]
   · rcases a6 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideAcceptGuard,CapacityCollectiveAst.decideAcceptNext]
   · rcases a7 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideRejectGuard,CapacityCollectiveAst.decideRejectNext]
   · rcases a8 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge0Guard,CapacityCollectiveAst.acknowledge0Next]
   · rcases a9 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge1Guard,CapacityCollectiveAst.acknowledge1Next]
   · rcases a10 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.releaseGuard,CapacityCollectiveAst.releaseNext]
   · rcases a11 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip0Guard,CapacityCollectiveAst.flip0Next]
   · rcases a12 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip1Guard,CapacityCollectiveAst.flip1Next]
   · rcases a13 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver0Guard,CapacityCollectiveAst.deliver0Next]
   · rcases a14 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver1Guard,CapacityCollectiveAst.deliver1Next]
   · rcases a15 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainUnknownGuard,CapacityCollectiveAst.retainUnknownNext]
   · rcases a16 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainSetupUnknownGuard,CapacityCollectiveAst.retainSetupUnknownNext]
   · rcases a17 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.freeRejectedGuard,CapacityCollectiveAst.freeRejectedNext]
   · rw [a18]; assumption
 · rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
   · rcases a0 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishReadyGuard,CapacityCollectiveAst.publishReadyNext]
   · rcases a1 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishFailureGuard,CapacityCollectiveAst.publishFailureNext]
   · rcases a2 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept0Guard,CapacityCollectiveAst.accept0Next]
   · rcases a3 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept1Guard,CapacityCollectiveAst.accept1Next]
   · rcases a4 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject0Guard,CapacityCollectiveAst.reject0Next]
   · rcases a5 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject1Guard,CapacityCollectiveAst.reject1Next]
   · rcases a6 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideAcceptGuard,CapacityCollectiveAst.decideAcceptNext]
   · rcases a7 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideRejectGuard,CapacityCollectiveAst.decideRejectNext]
   · rcases a8 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge0Guard,CapacityCollectiveAst.acknowledge0Next]
   · rcases a9 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge1Guard,CapacityCollectiveAst.acknowledge1Next]
   · rcases a10 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.releaseGuard,CapacityCollectiveAst.releaseNext]
   · rcases a11 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip0Guard,CapacityCollectiveAst.flip0Next]
   · rcases a12 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip1Guard,CapacityCollectiveAst.flip1Next]
   · rcases a13 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver0Guard,CapacityCollectiveAst.deliver0Next]
   · rcases a14 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver1Guard,CapacityCollectiveAst.deliver1Next]
   · rcases a15 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainUnknownGuard,CapacityCollectiveAst.retainUnknownNext]
   · rcases a16 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainSetupUnknownGuard,CapacityCollectiveAst.retainSetupUnknownNext]
   · rcases a17 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.freeRejectedGuard,CapacityCollectiveAst.freeRejectedNext]
   · rw [a18]; assumption
 · rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
   · rcases a0 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishReadyGuard,CapacityCollectiveAst.publishReadyNext]
   · rcases a1 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.publishFailureGuard,CapacityCollectiveAst.publishFailureNext]
   · rcases a2 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept0Guard,CapacityCollectiveAst.accept0Next]
   · rcases a3 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.accept1Guard,CapacityCollectiveAst.accept1Next]
   · rcases a4 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject0Guard,CapacityCollectiveAst.reject0Next]
   · rcases a5 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.reject1Guard,CapacityCollectiveAst.reject1Next]
   · rcases a6 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideAcceptGuard,CapacityCollectiveAst.decideAcceptNext]
   · rcases a7 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.decideRejectGuard,CapacityCollectiveAst.decideRejectNext]
   · rcases a8 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge0Guard,CapacityCollectiveAst.acknowledge0Next]
   · rcases a9 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.acknowledge1Guard,CapacityCollectiveAst.acknowledge1Next]
   · rcases a10 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.releaseGuard,CapacityCollectiveAst.releaseNext]
   · rcases a11 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip0Guard,CapacityCollectiveAst.flip0Next]
   · rcases a12 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.flip1Guard,CapacityCollectiveAst.flip1Next]
   · rcases a13 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver0Guard,CapacityCollectiveAst.deliver0Next]
   · rcases a14 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.deliver1Guard,CapacityCollectiveAst.deliver1Next]
   · rcases a15 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainUnknownGuard,CapacityCollectiveAst.retainUnknownNext]
   · rcases a16 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.retainSetupUnknownGuard,CapacityCollectiveAst.retainSetupUnknownNext]
   · rcases a17 with ⟨guard,rfl⟩; simp_all [PublicationGate,CapacityCollectiveAst.freeRejectedGuard,CapacityCollectiveAst.freeRejectedNext]
   · rw [a18]; assumption
inductive Reachable (r : ContinuationRestoreAst.State) : DedicatedCopyAst.State → CapacityCollectiveAst.State → Prop where
 | start : Reachable r DedicatedCopyAst.initial CapacityCollectiveAst.initial
 | plan {g h c} : Reachable r g c → DedicatedCopyAst.Step g h → WorkGate g h c → Reachable r h c
 | collective {g c d} : Reachable r g c → CapacityCollectiveAst.Step c d → PublicationGate g r c d → Reachable r g d
theorem reachableCoupled (r g c) (rs : ContinuationRestoreAst.Safe r) (h : Reachable r g c) : Coupled g r c := by
 induction h with
 | start => exact initialCoupled r rs
 | plan _ st gate ih => exact planPreserves _ _ _ _ ih st gate
 | collective _ st gate ih => exact collectivePreserves _ _ _ _ ih st gate
theorem setupHasCapacityAndRestore (g r c) (h : Coupled g r c) (flip : c.flip0=true ∨ c.flip1=true) :
 g.actual-2-1≥g.retired+2 ∧ r.r0+8≤r.cap0 ∧ r.r1+8≤r.cap1 := by
 have cut := CapacityCollective.flipRequiresAllAcknowledged c h.2.2.1 flip
 have ready : c.poolReady=true := by
  have cs := h.2.2.1
  simp only [CapacityCollectiveAst.Safe] at cs
  rcases cs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27,h28⟩
  simp_all <;> omega
 have cert := h.2.2.2.1 ready
 have capacity := DedicatedCopy.acceptedPhysicalCapacity g h.1 cert.1
 have bounds := ContinuationRestore.acceptedBounds r h.2.1 cert.2.1
 exact ⟨capacity,bounds.2.2.1,bounds.2.2.2⟩
theorem unknownCannotCopy (g r c) (h : Coupled g r c) (u : g.unknown=true) : g.collecting=false := by
 have gs := h.1
 simp only [DedicatedCopyAst.Safe] at gs
 rcases gs with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19⟩
 simp_all <;> omega
-- Actual typed action witness: dedicate both restore slots, reserve capacity, collectively flip, then copy.
theorem successfulRun : ∃ r g c, RestoreReady r ∧ Reachable r g c ∧ g.collecting=true ∧ c.flip1=true := by
 let r0 := ContinuationRestoreAst.initial
 let r1 := ContinuationRestoreAst.freezeLargeNext r0
 let r2 := ContinuationRestoreAst.dedicate0Next r1
 let r3 := ContinuationRestoreAst.dedicate1Next r2
 let r4 := ContinuationRestoreAst.sealAcceptNext r3
 let g0 := DedicatedCopyAst.initial
 let g1 := DedicatedCopyAst.freezeNext g0
 let g2 := DedicatedCopyAst.sharedUnsuitableNext g1
 let g3 := DedicatedCopyAst.growFullNext g2
 let g4 := DedicatedCopyAst.chooseDedicatedNext g3
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
 let g5 := DedicatedCopyAst.beginCopyNext g4
 have h0 : Reachable r4 g0 c0 := Reachable.start
 have h1 : Reachable r4 g1 c0 := Reachable.plan h0 (by exact Or.inl ⟨by simp [g0,g1,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.freezeGuard],rfl⟩) (by simp [WorkGate,c0,CapacityCollectiveAst.initial,g0,g1,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.freezeGuard])
 have h2 : Reachable r4 g2 c0 := Reachable.plan h1 (by exact Or.inr (Or.inl ⟨by simp [g0,g1,g2,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.sharedUnsuitableGuard],rfl⟩)) (by simp [WorkGate,c0,CapacityCollectiveAst.initial,g0,g1,g2,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.sharedUnsuitableGuard])
 have h3 : Reachable r4 g3 c0 := Reachable.plan h2 (by exact Or.inr (Or.inr (Or.inl ⟨by simp [g0,g1,g2,g3,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.growFullGuard],rfl⟩))) (by simp [WorkGate,c0,CapacityCollectiveAst.initial,g0,g1,g2,g3,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.growFullGuard])
 have h4 : Reachable r4 g4 c0 := Reachable.plan h3 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext,DedicatedCopyAst.chooseDedicatedGuard],rfl⟩))))))))) (by simp [WorkGate,c0,CapacityCollectiveAst.initial,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext,DedicatedCopyAst.chooseDedicatedGuard])
 have h5 : Reachable r4 g4 c1 := Reachable.collective h4 (by exact Or.inl ⟨by simp [c0,c1,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.publishReadyGuard],rfl⟩) (by simp [PublicationGate,c0,c1,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.publishReadyGuard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h6 : Reachable r4 g4 c2 := Reachable.collective h5 (by exact Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept0Guard],rfl⟩))) (by simp [PublicationGate,c0,c1,c2,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept0Guard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h7 : Reachable r4 g4 c3 := Reachable.collective h6 (by exact Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.accept1Guard],rfl⟩)))) (by simp [PublicationGate,c0,c1,c2,c3,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.accept1Guard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h8 : Reachable r4 g4 c4 := Reachable.collective h7 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.decideAcceptGuard],rfl⟩))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.decideAcceptGuard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h9 : Reachable r4 g4 c5 := Reachable.collective h8 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge0Guard],rfl⟩))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge0Guard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h10 : Reachable r4 g4 c6 := Reachable.collective h9 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.acknowledge1Guard],rfl⟩)))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.acknowledge1Guard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h11 : Reachable r4 g4 c7 := Reachable.collective h10 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,c7,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.releaseGuard],rfl⟩))))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,c7,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.releaseGuard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h12 : Reachable r4 g4 c8 := Reachable.collective h11 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,c7,c8,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip0Guard],rfl⟩)))))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,c7,c8,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip0Guard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h13 : Reachable r4 g4 c9 := Reachable.collective h12 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip1Next,CapacityCollectiveAst.flip1Guard],rfl⟩))))))))))))) (by simp [PublicationGate,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip1Next,CapacityCollectiveAst.flip1Guard,r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext,g0,g1,g2,g3,g4,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext])
 have h14 : Reachable r4 g5 c9 := Reachable.plan h13 (by exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [g0,g1,g2,g3,g4,g5,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext,DedicatedCopyAst.beginCopyNext,DedicatedCopyAst.beginCopyGuard],rfl⟩)))))))))))) (by simp [WorkGate,g0,g1,g2,g3,g4,g5,DedicatedCopyAst.initial,DedicatedCopyAst.freezeNext,DedicatedCopyAst.sharedUnsuitableNext,DedicatedCopyAst.growFullNext,DedicatedCopyAst.chooseDedicatedNext,DedicatedCopyAst.beginCopyNext,DedicatedCopyAst.beginCopyGuard,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,CapacityCollectiveAst.initial,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.flip1Next])
 refine ⟨r4,g5,c9,?_,h14,rfl,rfl⟩
 simp [r0,r1,r2,r3,r4,RestoreReady,ContinuationRestoreAst.initial,ContinuationRestoreAst.freezeLargeNext,ContinuationRestoreAst.dedicate0Next,ContinuationRestoreAst.dedicate1Next,ContinuationRestoreAst.sealAcceptNext]
end CopyCapacityComposition
