namespace GambitSMP.ConstructorDebtClosure
structure Cut where
 businessPending : Bool
 managedWritersStopped : Bool
 instanceRoots : Bool
 currentTrace : Bool
 profileKnown : Bool
 payloadCustodyKnown : Bool
 quotaHeld : Bool
 gateReleased : Bool
 callbackFrameCovered : Bool
 nativeOnlyIsolated : Bool
 capturedResult : Bool
 nativeOutcomeKnown : Bool
 gcWaitsOwner : Bool
def Coverage (s : Cut) := s.capturedResult=true ∨ s.nativeOnlyIsolated=true ∨ s.callbackFrameCovered=true
def CanClose (s : Cut) := s.managedWritersStopped=true ∧ s.instanceRoots=true ∧ s.currentTrace=true ∧ s.profileKnown=true ∧ s.payloadCustodyKnown=true ∧ s.quotaHeld=true ∧ s.gateReleased=true ∧ s.gcWaitsOwner=false ∧ Coverage s
theorem businessCompletionIndependent (s : Cut) (b : Bool) : CanClose {s with businessPending:=b} ↔ CanClose s := by rfl
theorem isolatedOutcomeIndependent (s : Cut) (b : Bool) : CanClose {s with nativeOutcomeKnown:=b} ↔ CanClose s := by rfl
-- Independence above is conditional on Coverage and exact custody; not every unknown is isolated.
theorem unknownCustodyRejects (s : Cut) (h : s.payloadCustodyKnown=false) : ¬ CanClose s := by simp [CanClose,h]
theorem liveManagedWriterRejects (s : Cut) (h : s.managedWritersStopped=false) : ¬ CanClose s := by simp [CanClose,h]
theorem missingTraceRejects (s : Cut) (h : s.currentTrace=false) : ¬ CanClose s := by simp [CanClose,h]
theorem gateHeldRejects (s : Cut) (h : s.gateReleased=false) : ¬ CanClose s := by simp [CanClose,h]
theorem reverseWaitRejects (s : Cut) (h : s.gcWaitsOwner=true) : ¬ CanClose s := by simp [CanClose,h]
theorem noCoverageRejects (s : Cut) (h1 : s.capturedResult=false) (h2 : s.nativeOnlyIsolated=false) (h3 : s.callbackFrameCovered=false) : ¬ CanClose s := by simp [CanClose,Coverage,h1,h2,h3]
structure Credit where
 source : Nat
 escrow : Nat
 wrapper : Nat
 retired : Nat
def total (s : Credit) := s.source+s.escrow+s.wrapper+s.retired
def freeze (s : Credit) := {s with source:=s.source-1,escrow:=s.escrow+1}
def wrap (s : Credit) := {s with escrow:=s.escrow-1,wrapper:=s.wrapper+1}
def dispose (s : Credit) := {s with escrow:=s.escrow-1,retired:=s.retired+1}
theorem freezeConserves (s : Credit) (h : 0<s.source) : total (freeze s)=total s := by simp [total,freeze]; omega
theorem wrapConserves (s : Credit) (h : 0<s.escrow) : total (wrap s)=total s := by simp [total,wrap]; omega
theorem disposeConserves (s : Credit) (h : 0<s.escrow) : total (dispose s)=total s := by simp [total,dispose]; omega
inductive Step : Credit → Credit → Prop
 | freeze (s : Credit) (h : 0<s.source) : Step s (ConstructorDebtClosure.freeze s)
 | wrap (s : Credit) (h : 0<s.escrow) : Step s (ConstructorDebtClosure.wrap s)
 | dispose (s : Credit) (h : 0<s.escrow) : Step s (ConstructorDebtClosure.dispose s)
 | unknown (s : Credit) : Step s s
theorem stepConserves {a b : Credit} (h : Step a b) : total a=total b := by
 cases h with
 | freeze p => exact (freezeConserves _ p).symm
 | wrap p => exact (wrapConserves _ p).symm
 | dispose p => exact (disposeConserves _ p).symm
 | unknown => rfl
inductive Trace : Credit → Credit → Prop
 | nil (s : Credit) : Trace s s
 | cons {a b c : Credit} : Step a b → Trace b c → Trace a c
theorem traceConserves {a b : Credit} (h : Trace a b) : total a=total b := by
 induction h with
 | nil => rfl
 | cons h _ ih => exact (stepConserves h).trans ih
-- Wait edges 0=owner,1=collector,2=scan service; declared rank decreases.
def WaitEdge (a b : Nat) := (a=0 ∧ b=1) ∨ (a=1 ∧ b=2)
def rank (n : Nat) := 2-n
theorem waitRankDecreases (a b : Nat) (h : WaitEdge a b) : rank b<rank a := by rcases h with h|h <;> rcases h with ⟨rfl,rfl⟩ <;> decide
theorem noReverseOwnerWait : ¬ WaitEdge 1 0 := by simp [WaitEdge]
theorem noServiceWaitsOwner : ¬ WaitEdge 2 0 := by simp [WaitEdge]
theorem noTwoCycle (a b : Nat) (h1 : WaitEdge a b) (h2 : WaitEdge b a) : False := by have h:=waitRankDecreases a b h1; have g:=waitRankDecreases b a h2; omega
def RollbackAllowed (created target : Nat) (known : Bool) := created=target ∧ known=true
theorem parentNotCleanupTarget (client server : Nat) (h : client≠server) (k : Bool) : ¬ RollbackAllowed client server k := by simp [RollbackAllowed,h]
def RefundAllowed (dispositionKnown noReaders noChildren : Bool) := dispositionKnown=true ∧ noReaders=true ∧ noChildren=true
theorem unknownDispositionKeepsTicket (a b : Bool) : ¬ RefundAllowed false a b := by simp [RefundAllowed]
theorem readersKeepTicket (a b : Bool) : ¬ RefundAllowed a false b := by simp [RefundAllowed]
theorem replayNotRecovery (calls : Nat) (h : calls=1) : ¬ calls+1≤1 := by omega
theorem rootComposition {α : Type} (dependencies registered traced : α→Prop) (a : ∀x,dependencies x→registered x) (b : ∀x,registered x→traced x) : ∀x,dependencies x→traced x := by intro x hx; exact b x (a x hx)
end GambitSMP.ConstructorDebtClosure
