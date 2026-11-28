/- Conditional exit gates and debt accounting; no generated C or ABI simulation. -/
namespace GambitSMP.FfiExitCatcherClosure
structure Exit where
  effectsSettled : Bool
  conversionClosed : Bool
  markerRetired : Bool
  catcherRestored : Bool
  registersRestored : Bool
  resultRooted : Bool
  receiverNeeded : Bool
  receiverRegistered : Bool
def Ready (x : Exit) := x.effectsSettled=true ∧ x.conversionClosed=true ∧ x.markerRetired=true ∧
  x.catcherRestored=true ∧ x.registersRestored=true ∧ x.resultRooted=true ∧
  (x.receiverNeeded=true → x.receiverRegistered=true)
theorem catcherRequired (x : Exit) (h : Ready x) : x.catcherRestored=true := h.2.2.2.1
theorem registersRequired (x : Exit) (h : Ready x) : x.registersRestored=true := h.2.2.2.2.1
theorem propagationReceiverRequired (x : Exit) (h : Ready x) (n : x.receiverNeeded=true) : x.receiverRegistered=true := h.2.2.2.2.2.2 n
theorem conversionPendingRejects (x : Exit) (c : x.conversionClosed=false) : ¬ Ready x := by simp [Ready,c]
theorem markerPendingRejects (x : Exit) (c : x.markerRetired=false) : ¬ Ready x := by simp [Ready,c]
theorem missingResultRootRejects (x : Exit) (c : x.resultRooted=false) : ¬ Ready x := by simp [Ready,c]
structure Debt where
  source : Nat
  receiver : Nat
  callback : Nat
  independent : Nat
  owed : Nat
  vm : Bool
  admissionClosed : Bool
  deriving DecidableEq
def Accounted (s : Debt) := s.owed=s.source+s.receiver+s.callback+s.independent
def sourcePins (s : Debt) := s.source+s.receiver+s.callback
def transferReceiver (s : Debt) := {s with source:=s.source-1,receiver:=s.receiver+1}
def reserveCallback (s : Debt) := {s with callback:=s.callback+1,owed:=s.owed+1}
def moveCallback (s : Debt) := {s with callback:=s.callback-1,independent:=s.independent+1}
def finishSource (s : Debt) := {s with source:=s.source-1,owed:=s.owed-1}
def finishReceiver (s : Debt) := {s with receiver:=s.receiver-1,owed:=s.owed-1}
def finishIndependent (s : Debt) := {s with independent:=s.independent-1,owed:=s.owed-1}
def closeAdmission (s : Debt) := {s with admissionClosed:=true}
theorem receiverTransferPreserves (s : Debt) (h : Accounted s) (a : 0<s.source) : Accounted (transferReceiver s) := by
  simp_all [Accounted,transferReceiver]; omega
theorem receiverTransferKeepsBorrowCount (s : Debt) (a : 0<s.source) : sourcePins (transferReceiver s)=sourcePins s := by
  simp [sourcePins,transferReceiver]; omega
theorem receiverTransferNeverZero (s : Debt) (a : 0<s.source) : 0<sourcePins (transferReceiver s) := by
  rw [receiverTransferKeepsBorrowCount s a]; simp [sourcePins]; omega
theorem callbackReservePreserves (s : Debt) (h : Accounted s) : Accounted (reserveCallback s) := by
  simp_all [Accounted,reserveCallback]; omega
theorem callbackReserveAddsDebt (s : Debt) : (reserveCallback s).owed=s.owed+1 := rfl
theorem callbackMovePreserves (s : Debt) (h : Accounted s) (a : 0<s.callback) : Accounted (moveCallback s) := by
  simp_all [Accounted,moveCallback]; omega
theorem callbackMoveDoesNotDischarge (s : Debt) : (moveCallback s).owed=s.owed := rfl
theorem sourceFinishPreserves (s : Debt) (h : Accounted s) (a : 0<s.source) : Accounted (finishSource s) := by
  simp_all [Accounted,finishSource]; omega
theorem receiverFinishPreserves (s : Debt) (h : Accounted s) (a : 0<s.receiver) : Accounted (finishReceiver s) := by
  simp_all [Accounted,finishReceiver]; omega
theorem callbackFinishPreserves (s : Debt) (h : Accounted s) (a : 0<s.independent) : Accounted (finishIndependent s) := by
  simp_all [Accounted,finishIndependent]; omega
inductive Step : Debt → Debt → Prop
  | transfer (s : Debt) (a : 0<s.source) : Step s (transferReceiver s)
  | reserve (s : Debt) (a : s.admissionClosed=false) (parent : 0<s.source) : Step s (reserveCallback s)
  | move (s : Debt) (a : 0<s.callback) (v : s.vm=true) : Step s (moveCallback s)
  | sourceEnd (s : Debt) (a : 0<s.source) (x : Exit) (r : Ready x) : Step s (finishSource s)
  | receiverEnd (s : Debt) (a : 0<s.receiver) : Step s (finishReceiver s)
  | callbackEnd (s : Debt) (a : 0<s.independent) : Step s (finishIndependent s)
  | close (s : Debt) : Step s (closeAdmission s)
  | query (s : Debt) : Step s s
theorem stepPreserves {a b : Debt} (h : Step a b) (s : Accounted a) : Accounted b := by
  cases h with
  | transfer a => exact receiverTransferPreserves _ s a
  | reserve _ _ => exact callbackReservePreserves _ s
  | move a _ => exact callbackMovePreserves _ s a
  | sourceEnd a _ _ => exact sourceFinishPreserves _ s a
  | receiverEnd a => exact receiverFinishPreserves _ s a
  | callbackEnd a => exact callbackFinishPreserves _ s a
  | close => exact s
  | query => exact s
inductive Trace : Debt → Debt → Prop
  | nil (s : Debt) : Trace s s
  | cons {a b c : Debt} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : Debt} (h : Trace a b) (s : Accounted a) : Accounted b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
def CleanupAllowed (s : Debt) := sourcePins s=0 ∧ s.vm=true
def DataClosed (s : Debt) := s.owed=0 ∧ s.admissionClosed=true ∧ s.vm=true
theorem pendingReceiverBlocksCleanup (s : Debt) (a : 0<s.receiver) : ¬ CleanupAllowed s := by
  simp [CleanupAllowed,sourcePins]; omega
theorem independentDebtBlocksSeal (s : Debt) (h : Accounted s) (a : 0<s.independent) : ¬ DataClosed s := by
  simp_all [Accounted,DataClosed]; omega
def transferredCallback : Debt := ⟨0,0,0,1,1,true,true⟩
theorem zeroSourcePinsNotDataClosed : CleanupAllowed transferredCallback ∧ ¬ DataClosed transferredCallback := by
  simp [CleanupAllowed,DataClosed,sourcePins,transferredCallback]
theorem dataClosedHasNoDebts (s : Debt) (h : Accounted s) (c : DataClosed s) :
    s.source=0 ∧ s.receiver=0 ∧ s.callback=0 ∧ s.independent=0 := by
  simp_all [Accounted,DataClosed]
theorem admissionCloseDoesNotDrain (s : Debt) : (closeAdmission s).owed=s.owed := rfl
/- Deferred work is admitted only with a separately refined nonexecution gate. -/
def DeferredSeal (s : Debt) (future : Nat) (gate : Bool) :=
  s.owed=future ∧ future≤s.independent ∧ s.admissionClosed=true ∧ s.vm=true ∧ gate=true
theorem futureTaskStillOwed : DeferredSeal transferredCallback 1 true ∧ transferredCallback.owed=1 := by
  simp [DeferredSeal,transferredCallback]
theorem futureSealNeedsExecutionGate (s : Debt) (n : Nat) : ¬ DeferredSeal s n false := by
  simp [DeferredSeal]
theorem deferredSealHasNoCurrentBorrowers (s : Debt) (n : Nat) (g : Bool)
    (h : Accounted s) (c : DeferredSeal s n g) : sourcePins s=0 := by
  simp_all [Accounted,DeferredSeal,sourcePins]; omega
end GambitSMP.FfiExitCatcherClosure

