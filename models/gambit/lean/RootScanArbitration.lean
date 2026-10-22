namespace GambitSMP.RootScanArbitration
structure Ledger where
 pending : Nat
 claimed : Nat
 ready : Nat
 quarantined : Nat
 acknowledged : Nat
def total (s : Ledger) := s.pending+s.claimed+s.ready+s.quarantined+s.acknowledged
def claim (s : Ledger) : Ledger := {s with pending:=s.pending-1,claimed:=s.claimed+1}
def publish (s : Ledger) : Ledger := {s with claimed:=s.claimed-1,ready:=s.ready+1}
def ack (s : Ledger) : Ledger := {s with ready:=s.ready-1,acknowledged:=s.acknowledged+1}
def quarantine (s : Ledger) : Ledger := {s with claimed:=s.claimed-1,quarantined:=s.quarantined+1}
def requeue (s : Ledger) : Ledger := {s with claimed:=s.claimed-1,pending:=s.pending+1}
theorem claimConserves (s : Ledger) (h : 0<s.pending) : total (claim s)=total s := by simp [total,claim]; omega
theorem publishConserves (s : Ledger) (h : 0<s.claimed) : total (publish s)=total s := by simp [total,publish]; omega
theorem ackConserves (s : Ledger) (h : 0<s.ready) : total (ack s)=total s := by simp [total,ack]; omega
theorem quarantineConserves (s : Ledger) (h : 0<s.claimed) : total (quarantine s)=total s := by simp [total,quarantine]; omega
theorem requeueConserves (s : Ledger) (h : 0<s.claimed) : total (requeue s)=total s := by simp [total,requeue]; omega
inductive Step : Ledger → Ledger → Prop
 | claim (s : Ledger) (h : 0<s.pending) : Step s (RootScanArbitration.claim s)
 | publish (s : Ledger) (h : 0<s.claimed) : Step s (RootScanArbitration.publish s)
 | ack (s : Ledger) (h : 0<s.ready) : Step s (RootScanArbitration.ack s)
 | quarantine (s : Ledger) (h : 0<s.claimed) : Step s (RootScanArbitration.quarantine s)
 | requeue (s : Ledger) (h : 0<s.claimed) : Step s (RootScanArbitration.requeue s)
 | stay (s : Ledger) : Step s s
theorem stepConserves {a b : Ledger} (h : Step a b) : total a=total b := by
 cases h with
 | claim p => exact (claimConserves _ p).symm
 | publish p => exact (publishConserves _ p).symm
 | ack p => exact (ackConserves _ p).symm
 | quarantine p => exact (quarantineConserves _ p).symm
 | requeue p => exact (requeueConserves _ p).symm
 | stay => rfl
inductive Trace : Ledger → Ledger → Prop
 | nil (s : Ledger) : Trace s s
 | cons {a b c : Ledger} : Step a b → Trace b c → Trace a c
theorem traceConserves {a b : Ledger} (h : Trace a b) : total a=total b := by
 induction h with
 | nil => rfl
 | cons h _ ih => exact (stepConserves h).trans ih
def Outstanding (s : Ledger) := s.pending+s.claimed+s.ready+s.quarantined
theorem emptyQueueNotComplete (s : Ledger) (h : 0<s.claimed) : Outstanding s≠0 := by simp [Outstanding]; omega
theorem unknownDebtBlocksClose (s : Ledger) (h : 0<s.quarantined) : Outstanding s≠0 := by simp [Outstanding]; omega
structure ReturnGate where
 rootAck : Bool
 descendantClosed : Bool
 wholeRoundSeal : Bool
 writersClosed : Bool
 bindingValid : Bool
def CanReturn (s : ReturnGate) := s.rootAck=true ∧ s.descendantClosed=true ∧ s.wholeRoundSeal=true ∧ s.writersClosed=true ∧ s.bindingValid=true
theorem rootAckInsufficient (s : ReturnGate) (h : s.wholeRoundSeal=false) : ¬ CanReturn s := by simp [CanReturn,h]
theorem childDebtBlocksReturn (s : ReturnGate) (h : s.descendantClosed=false) : ¬ CanReturn s := by simp [CanReturn,h]
theorem unknownWriterBlocksReturn (s : ReturnGate) (h : s.writersClosed=false) : ¬ CanReturn s := by simp [CanReturn,h]
def Claimable (admitted requested : Bool) := admitted=true
theorem returnRequestPreservesDebt (a r : Bool) : Claimable a r ↔ Claimable a false := by rfl
structure Transfer where
 stopped : Bool
 checkpointComplete : Bool
 sourcePinsHeld : Bool
 targetAccepted : Bool
 resultUnknown : Bool
def CanRequeue (s : Transfer) := s.stopped=true ∧ s.checkpointComplete=true ∧ s.sourcePinsHeld=true ∧ s.targetAccepted=true ∧ s.resultUnknown=false
theorem stopWithoutCheckpointRejected (s : Transfer) (h : s.checkpointComplete=false) : ¬ CanRequeue s := by simp [CanRequeue,h]
theorem unknownTransferRetainsCustody (s : Transfer) (h : s.resultUnknown=true) : ¬ CanRequeue s := by simp [CanRequeue,h]
theorem sourcePinRequired (s : Transfer) (h : s.sourcePinsHeld=false) : ¬ CanRequeue s := by simp [CanRequeue,h]
theorem staleGenerationRejected (expected actual : Nat) (h : expected≠actual) : ¬ expected=actual := h
theorem cursorRestoreNoRepeatedPrefix (written remaining : Nat) : written+remaining-written=remaining := by omega
def WaitEdge (waiter producer : Nat) := producer<waiter
inductive WaitPath : Nat → Nat → Prop
 | edge {a b : Nat} : WaitEdge a b → WaitPath a b
 | cons {a b c : Nat} : WaitEdge a b → WaitPath b c → WaitPath a c
theorem waitPathDecreases {a b : Nat} (h : WaitPath a b) : b<a := by
 induction h with
 | edge h => exact h
 | cons h _ ih => exact Nat.lt_trans ih h
theorem rankedWaitsHaveNoCycle (a : Nat) : ¬ WaitPath a a := by
 intro h; have q:=waitPathDecreases h; omega
theorem workerCannotWaitForReturn (worker returner : Nat) (h : worker<returner) : ¬ WaitEdge worker returner := by simp [WaitEdge]; omega
theorem generationAdvanceRejectsOld (g : Nat) : g≠g+1 := by omega
end GambitSMP.RootScanArbitration
