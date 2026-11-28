import Std.Tactic
namespace GambitSMP.StructurePollStillEnvelope
-- Source-layout premises are supplied separately; no native sizeof experiment.
theorem recursiveStack (r : Nat) (h : r≤8191) : 8*r≤65528 := by omega
theorem heapFrameExtent : 5+1+1=7 := by decide
theorem recursiveHeapFrames (r : Nat) (h : r≤8191) : 7*r≤57337 := by omega
theorem firstInternalFrameDefault : ((6+3+3)/4)*4=12 := by decide
theorem transferPostCheck (before last maxFrame : Nat)
    (pending : before<100) (frame : last≤maxFrame) : before+last≤99+maxFrame := by omega
theorem selectedTransfer (before : Nat) (h : before<100) : before+8≤107 := by omega
theorem smallThreshold (a : Nat) : a+1≤255 ↔ a≤254 := by omega
theorem stillCharge (a : Nat) : 8*(a+6)+15=8*a+63 := by omega
theorem stillRequestCap (a : Nat) (h : a≤8192) : 8*a+63≤65599 := by omega
theorem deferredSplit (a d : Nat) : a+6+d≤1024 ↔ a+d≤1018 := by omega
structure BackingLedger where
  sections : Nat
  sectionBytes : Nat
  stillBytes : Nat
  auxiliary : Nat
  pendingCharge : Nat
  reusableSlots : Nat
def acquiredBytes (s : BackingLedger) : Nat :=
  s.sections*s.sectionBytes+s.stillBytes+s.auxiliary
theorem accountingSettlementIsNotFree (s : BackingLedger) :
    acquiredBytes {s with pendingCharge:=0}=acquiredBytes s := rfl
theorem poolReturnKeepsBacking (s : BackingLedger) :
    acquiredBytes {s with reusableSlots:=s.reusableSlots+1}=acquiredBytes s := rfl
theorem netPhaseGain (base omitted extra : Nat) (fits : omitted≤base)
    (net : extra<omitted) : base-omitted+extra<base := by omega
theorem allPhasePeak (xs : List Nat) (ceiling : Nat) (nonzero : 0<ceiling)
    (each : ∀ x∈xs, x<ceiling) : xs.foldr max 0<ceiling := by
  induction xs with
  | nil => simpa using nonzero
  | cons x rest ih =>
    have hx := each x (by simp)
    have hr := ih (by intro y hy; exact each y (by simp [hy]))
    change max x (List.foldr max 0 rest)<ceiling
    omega
theorem unboundedHandler (proposedCap : Nat) : proposedCap<proposedCap+1 := by omega
theorem unchangedDominant (baseline other : Nat) : ¬max baseline other<baseline := by omega
theorem lateFreeKeepsPeak (oldPeak current refund : Nat) :
    oldPeak≤max oldPeak (current-refund) := Nat.le_max_left _ _
end GambitSMP.StructurePollStillEnvelope
