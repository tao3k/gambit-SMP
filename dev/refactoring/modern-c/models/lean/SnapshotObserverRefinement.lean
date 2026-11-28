import DerivationReceiptEnvironment
namespace SnapshotObserverRefinement
structure PinFlat where
 head : Int
 loaded : Bool
 hazard : Bool
 validated : Bool
 removed : Bool
 scanClear : Bool
 snapshotFreed : Bool
 reading : Bool
 observerOpen : Bool
 observer : Bool
 pending : Bool
 unknown : Bool
 exec : Int
 producerClosed : Bool
 detached : Bool
 codeFreed : Bool
 receiptFreed : Bool
 deriving DecidableEq
def qPinGuard (q : PinFlat) : Prop := q.loaded=true ∧ ¬q.validated=true
def qPinNext (q : PinFlat) := {q with hazard:=true}
def qValidateGuard (q : PinFlat) : Prop := q.loaded=true ∧ q.hazard=true ∧ q.head=0 ∧ ¬q.snapshotFreed=true
def qValidateNext (q : PinFlat) := {q with validated:=true}
def qReceiptGuard (q : PinFlat) : Prop := ¬q.observerOpen=true ∧ ¬q.observer=true ∧ ¬q.pending=true ∧ ¬q.unknown=true
def qReceiptNext (q : PinFlat) := {q with receiptFreed:=true}
-- SC event ordering plus no intervening pin clear and no generation reuse are premises.
theorem pinOrderCannotMiss (publish validate remove scan : Nat)
 (p : publish<validate) (v : validate<remove) (r : remove<scan) (m : scan<publish) : False := by omega
theorem pendingBlocksReceipt (q : PinFlat) (h : q.pending=true) : ¬qReceiptGuard q := by simp [qReceiptGuard,h]
theorem observerBlocksReceipt (q : PinFlat) (h : q.observer=true) : ¬qReceiptGuard q := by simp [qReceiptGuard,h]
def codePermission (q : PinFlat) : Prop := q.producerClosed=true ∧ q.exec=0 ∧ q.pending=false ∧ q.unknown=false ∧
 (q.detached=true ∨ (q.observerOpen=false ∧ q.observer=false))
theorem detachedObserverPermission :
 ∃ q : PinFlat, codePermission q ∧ q.observer=true ∧ q.receiptFreed=false := by
 exact ⟨⟨1,false,false,false,true,true,true,false,true,true,false,false,0,true,true,false,false⟩,by simp [codePermission], rfl,rfl⟩
-- A detached certificate is semantic authority; exec=0 alone cannot issue it.
theorem activeUndetachedBlocks (q : PinFlat) (a : q.observer=true) (d : q.detached=false) : ¬codePermission q := by
 simp [codePermission,a,d]
structure Work where
 a : Int
 b : Int
 total : Int
 deriving DecidableEq
def reserveA (w : Work) := {w with a:=w.a+1,total:=w.total+1}
def reserveB (w : Work) := {w with b:=w.b+1,total:=w.total+1}
def batch (w : Work) := {w with a:=w.a+1,b:=w.b+1,total:=w.total+2}
theorem disjointCommute (w : Work) : reserveA (reserveB w)=reserveB (reserveA w) := rfl
theorem batchRefinesTwoSteps (w : Work) : batch w=reserveB (reserveA w) := by
 simp [batch,reserveA,reserveB,Int.add_assoc]
structure Transfer where
 a : Int
 b : Int
 overlap : Bool
 deriving DecidableEq
def logical (s : Transfer) := s.a+s.b-(if s.overlap then 1 else 0)
def reserveTarget (s : Transfer) := {s with b:=s.b+1,overlap:=true}
def releaseSource (s : Transfer) := {s with a:=s.a-1,overlap:=false}
theorem targetReservationPreserves (s : Transfer) (h : s.overlap=false) : logical (reserveTarget s)=logical s := by
 simp [logical,reserveTarget,h]; omega
theorem overlapTransferPreserves (s : Transfer) (h : s.overlap=false) :
 logical (releaseSource (reserveTarget s))=logical s := by simp [logical,releaseSource,reserveTarget,h]; omega
-- Lookup equality has no values outside the finite witness domain.
open DerivationReceiptEnvironment
theorem environmentNoFabrication (rows : List (Nat × Nat)) (k d : Nat)
 (h : buildEnv rows k=some d) : (k,d)∈rows := by
 induction rows with
 | nil => simp [buildEnv] at h
 | cons p ps ih =>
   rcases p with ⟨a,b⟩
   simp only [buildEnv] at h
   split at h
   next eq => simp_all
   next => exact List.mem_cons_of_mem (a,b) (ih h)
theorem environmentExactDomain (rows : List (Nat × Nat)) (valid : tableCheck rows=true) (k d : Nat) :
 buildEnv rows k=some d ↔ (k,d)∈rows := ⟨environmentNoFabrication rows k d,lookupFromWitness rows valid k d⟩
end SnapshotObserverRefinement
