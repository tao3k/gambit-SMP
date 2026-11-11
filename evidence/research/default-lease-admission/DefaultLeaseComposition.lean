import SectionLeases
import CapacityCollective
import CapacityCharge
namespace DefaultLeaseComposition
abbrev L := SectionLeasesAst.State
abbrev C := CapacityCollectiveAst.State
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
-- General symbolic count argument, separate from the two-worker identity slice.
theorem leaseCountBound (n p fresh shared : Int) (hn : 2*p<=n)
 (hf : 0<=fresh ∧ fresh<=n-2*p) (hs : 0<=shared ∧ shared<=p) : p+fresh+shared<=n := by omega
-- Half-open offset intervals; native pointer provenance and container bounds remain obligations.
theorem sharedPartition (h f q r : Int) (hh : h=4*q+2*f+r) (hq : 0<=q) (hf : 0<=f) (hr : 0<=r ∧ r<4) :
 3*q+f <= h-(q+f) ∧ h-(q+f)-(3*q+f)=r := by omega
theorem markersStayBelowStack (h f q r limit heapPast : Int)
 (hh : h=4*q+2*f+r) (hr : 0<=r) (hl : limit=3*q+f-2)
 (hm : heapPast<=limit+2) : heapPast<=h-(q+f) := by omega
theorem restoredStackSeparate (h f q r restore heapPast : Int)
 (hh : h=4*q+2*f+r) (hr : 0<=r) (hm : heapPast<=3*q+f)
 (hs : 0<=restore ∧ restore<=q+f) : heapPast<=h-restore := by omega
theorem restoreMetadataInBounds (h restore : Int) (hs : 3<=restore) : h-restore+2<h := by omega
theorem distinctContainersPreserveSubranges (endA startB heapPastA stackLowB : Int)
 (hc : endA<=startB) (ha : heapPastA<=endA) (hb : startB<=stackLowB) : heapPastA<=stackLowB := by omega
-- Arithmetic counterexample only; no legal Scheme path / actual race asserted.
theorem uncheckedRestoreCanOverlap :
 let h:Int:=65536; let f:Int:=8194; let q:Int:=12287; let restore:Int:=20482;
 h=4*q+2*f ∧ h-(q+f)=3*q+f ∧ h-restore<3*q+f := by decide
-- Bridge to the exact preceding charge AST: the visit budget is backed by the section census.
theorem priorChargeCeiling (leases : L) (q : CapacityChargeAst.State)
 (hl : SectionLeasesAst.Safe leases) (hq : CapacityChargeAst.Safe q)
 (hb : q.visitBudget<=leases.n) : q.starts<=q.limitWords/255+leases.n := by
 have h := CapacityCharge.tightCeiling q hq
 omega
-- A lease event must be authorized before the old source-charge advance consumes a visit.
theorem priorAdvanceGuard (before after : L) (q : CapacityChargeAst.State)
 (ha : SectionLeasesAst.Safe after) (delta : after.visits=before.visits+1)
 (covered : q.visits<=before.visits) (budget : q.visitBudget=after.n)
 (phase : q.phase<2) (closed : q.openCount=0) : CapacityChargeAst.advanceVisitGuard q := by
 have hn := SectionLeases.visitsBound after ha
 simp only [CapacityChargeAst.advanceVisitGuard]
 omega
-- Concrete successful collective prefix from the actual typed AST.
def admittedCollective : C := CapacityCollectiveAst.flip1Next (CapacityCollectiveAst.flip0Next (CapacityCollectiveAst.releaseNext (CapacityCollectiveAst.acknowledge1Next (CapacityCollectiveAst.acknowledge0Next (CapacityCollectiveAst.decideAcceptNext (CapacityCollectiveAst.accept1Next (CapacityCollectiveAst.accept0Next (CapacityCollectiveAst.publishReadyNext (CapacityCollectiveAst.initial)))))))))
theorem admittedCollectiveReachable : CapacityCollective.Reachable admittedCollective := by
 let q0 := CapacityCollectiveAst.initial
 have r0 : CapacityCollective.Reachable q0 := CapacityCollective.Reachable.start
 let q1 := CapacityCollectiveAst.publishReadyNext q0
 have r1 : CapacityCollective.Reachable q1 := CapacityCollective.Reachable.next r0 (Or.inl ⟨by simp [CapacityCollectiveAst.publishReadyGuard,q0,CapacityCollectiveAst.initial],rfl⟩)
 let q2 := CapacityCollectiveAst.accept0Next q1
 have r2 : CapacityCollective.Reachable q2 := CapacityCollective.Reachable.next r1 (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.accept0Guard,q0,q1,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.initial],rfl⟩)))
 let q3 := CapacityCollectiveAst.accept1Next q2
 have r3 : CapacityCollective.Reachable q3 := CapacityCollective.Reachable.next r2 (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.accept1Guard,q0,q1,q2,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.initial],rfl⟩))))
 let q4 := CapacityCollectiveAst.decideAcceptNext q3
 have r4 : CapacityCollective.Reachable q4 := CapacityCollective.Reachable.next r3 (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.decideAcceptGuard,q0,q1,q2,q3,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.initial],rfl⟩)))))))
 let q5 := CapacityCollectiveAst.acknowledge0Next q4
 have r5 : CapacityCollective.Reachable q5 := CapacityCollective.Reachable.next r4 (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.acknowledge0Guard,q0,q1,q2,q3,q4,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.initial],rfl⟩)))))))))
 let q6 := CapacityCollectiveAst.acknowledge1Next q5
 have r6 : CapacityCollective.Reachable q6 := CapacityCollective.Reachable.next r5 (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.acknowledge1Guard,q0,q1,q2,q3,q4,q5,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.initial],rfl⟩))))))))))
 let q7 := CapacityCollectiveAst.releaseNext q6
 have r7 : CapacityCollective.Reachable q7 := CapacityCollective.Reachable.next r6 (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.releaseGuard,q0,q1,q2,q3,q4,q5,q6,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.initial],rfl⟩)))))))))))
 let q8 := CapacityCollectiveAst.flip0Next q7
 have r8 : CapacityCollective.Reachable q8 := CapacityCollective.Reachable.next r7 (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.flip0Guard,q0,q1,q2,q3,q4,q5,q6,q7,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.initial],rfl⟩))))))))))))
 let q9 := CapacityCollectiveAst.flip1Next q8
 have r9 : CapacityCollective.Reachable q9 := CapacityCollective.Reachable.next r8 (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [CapacityCollectiveAst.flip1Guard,q0,q1,q2,q3,q4,q5,q6,q7,q8,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.initial],rfl⟩)))))))))))))
 exact r9
def Ready (c : C) : Prop := c.released=true ∧ c.decision=1 ∧ c.flip0=true ∧ c.flip1=true ∧ c.freed=false
def Good (l : L) (c : C) : Prop := SectionLeasesAst.Safe l ∧ CapacityCollectiveAst.Safe c ∧ (l.certified=true → Ready c)
theorem initialGood : Good SectionLeasesAst.initial admittedCollective := by
 refine ⟨SectionLeases.initialSafe,CapacityCollective.reachableSafe _ admittedCollectiveReachable,?_⟩
 simp [Ready,admittedCollective,CapacityCollectiveAst.flip1Next,CapacityCollectiveAst.flip0Next,CapacityCollectiveAst.releaseNext,CapacityCollectiveAst.acknowledge1Next,CapacityCollectiveAst.acknowledge0Next,CapacityCollectiveAst.decideAcceptNext,CapacityCollectiveAst.accept1Next,CapacityCollectiveAst.accept0Next,CapacityCollectiveAst.publishReadyNext,CapacityCollectiveAst.initial]
inductive Step : L → C → L → C → Prop where
 | leases {l r c} : SectionLeasesAst.Step l r → Ready c → Step l c r c
 | collective {l c r} : CapacityCollectiveAst.Step c r → (l.certified=true → Ready r) → Step l c l r
theorem stepPreserves (l r : L) (c t : C) (h : Good l c) (st : Step l c r t) : Good r t := by
 rcases h with ⟨hl,hc,ready⟩
 cases st with
 | leases ls rc => exact ⟨SectionLeases.stepPreserves _ _ hl ls,hc,by intro _; exact rc⟩
 | collective cs guard => exact ⟨hl,CapacityCollective.stepPreserves _ _ hc cs,guard⟩
inductive Reachable : L → C → Prop where
 | start : Reachable SectionLeasesAst.initial admittedCollective
 | next {l c r t} : Reachable l c → Step l c r t → Reachable r t
theorem reachableGood (l : L) (c : C) (h : Reachable l c) : Good l c := by
 induction h with
 | start => exact initialGood
 | next _ st ih => exact stepPreserves _ _ _ _ ih st
theorem certifiedLeaseRequiresCollective (l : L) (c : C) (h : Good l c) (hc : l.certified=true) : c.decision=1 ∧ c.flip0=true ∧ c.flip1=true := by
 have r := h.2.2 hc
 exact ⟨r.2.1,r.2.2.1,r.2.2.2.1⟩
theorem falseIndependentAdmission : SectionLeasesAst.Safe SectionLeasesAst.initial ∧
 CapacityCollectiveAst.Safe CapacityCollectiveAst.initial ∧ ¬Good SectionLeasesAst.initial CapacityCollectiveAst.initial := by
 refine ⟨SectionLeases.initialSafe,CapacityCollective.initialSafe,?_⟩
 simp [Good,Ready,SectionLeasesAst.initial,CapacityCollectiveAst.initial]
end DefaultLeaseComposition
