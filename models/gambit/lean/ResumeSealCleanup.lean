namespace GambitSMP.ResumeSealCleanup
structure SealInput where
 rootsClosed : Bool
 weakClosed : Bool
 cleanupSettled : Bool
 rootsCovered : Bool
 capacityKnown : Bool
 contextPrepared : Bool
 resultCommitted : Bool
 writersClosed : Bool
 bindingKnown : Bool
 gatesReleased : Bool
 nativeOutcomeKnown : Bool
def CanSeal (s : SealInput) := s.rootsClosed=true ∧ s.weakClosed=true ∧ s.cleanupSettled=true ∧ s.rootsCovered=true ∧ s.capacityKnown=true ∧ s.contextPrepared=true ∧ s.resultCommitted=true ∧ s.writersClosed=true ∧ s.bindingKnown=true ∧ s.gatesReleased=true
theorem missingCleanupRejects (s : SealInput) (h : s.cleanupSettled=false) : ¬ CanSeal s := by simp [CanSeal,h]
theorem missingRootsRejects (s : SealInput) (h : s.rootsCovered=false) : ¬ CanSeal s := by simp [CanSeal,h]
theorem unknownCapacityRejects (s : SealInput) (h : s.capacityKnown=false) : ¬ CanSeal s := by simp [CanSeal,h]
theorem unpreparedContextRejects (s : SealInput) (h : s.contextPrepared=false) : ¬ CanSeal s := by simp [CanSeal,h]
theorem missingResultRejects (s : SealInput) (h : s.resultCommitted=false) : ¬ CanSeal s := by simp [CanSeal,h]
theorem unknownWriterRejects (s : SealInput) (h : s.writersClosed=false) : ¬ CanSeal s := by simp [CanSeal,h]
theorem unknownBindingRejects (s : SealInput) (h : s.bindingKnown=false) : ¬ CanSeal s := by simp [CanSeal,h]
theorem heldGateRejects (s : SealInput) (h : s.gatesReleased=false) : ¬ CanSeal s := by simp [CanSeal,h]
-- Only a separately established isolated deferred-cohort relation may use CanSeal.
theorem isolatedNativeOutcomeIndependent (s : SealInput) (b : Bool) : CanSeal {s with nativeOutcomeKnown:=b} ↔ CanSeal s := by rfl
structure Handoff where
 accepted : Bool
 serviceOwns : Bool
 rootsCovered : Bool
 codeAndPayloadPinned : Bool
 effectProfile : Bool
 delaySemantics : Bool
 metadataKnown : Bool
def Settled (s : Handoff) := s.accepted=true ∧ s.serviceOwns=true ∧ s.rootsCovered=true ∧ s.codeAndPayloadPinned=true ∧ s.effectProfile=true ∧ s.delaySemantics=true ∧ s.metadataKnown=true
theorem queueOnlyInsufficient (s : Handoff) (h : s.serviceOwns=false) : ¬ Settled s := by simp [Settled,h]
theorem unknownTransferRejects (s : Handoff) (h : s.metadataKnown=false) : ¬ Settled s := by simp [Settled,h]
theorem noDelayPermissionRejects (s : Handoff) (h : s.delaySemantics=false) : ¬ Settled s := by simp [Settled,h]
structure Ledger where
 source : Nat
 service : Nat
 settled : Nat
 unknown : Bool
def total (s : Ledger) := s.source+s.service+s.settled
def accept (s : Ledger) : Ledger := {s with source:=s.source-1,service:=s.service+1}
def complete (s : Ledger) : Ledger := {s with service:=s.service-1,settled:=s.settled+1}
def retainUnknown (s : Ledger) : Ledger := {s with unknown:=true}
theorem acceptConserves (s : Ledger) (h : 0<s.source) : total (accept s)=total s := by simp [total,accept]; omega
theorem completionConserves (s : Ledger) (h : 0<s.service) : total (complete s)=total s := by simp [total,complete]; omega
theorem unknownRetainsCredit (s : Ledger) : total (retainUnknown s)=total s := by rfl
inductive Step : Ledger → Ledger → Prop
 | accept (s : Ledger) (h : 0<s.source) : Step s (ResumeSealCleanup.accept s)
 | complete (s : Ledger) (h : 0<s.service) : Step s (ResumeSealCleanup.complete s)
 | unknown (s : Ledger) : Step s (retainUnknown s)
 | stay (s : Ledger) : Step s s
theorem stepConserves {a b : Ledger} (h : Step a b) : total a=total b := by
 cases h with
 | accept p => exact (acceptConserves _ p).symm
 | complete p => exact (completionConserves _ p).symm
 | unknown => rfl
 | stay => rfl
inductive Trace : Ledger → Ledger → Prop
 | nil (s : Ledger) : Trace s s
 | cons {a b c : Ledger} : Step a b → Trace b c → Trace a c
theorem traceConserves {a b : Ledger} (h : Trace a b) : total a=total b := by
 induction h with
 | nil => rfl
 | cons h _ ih => exact (stepConserves h).trans ih
def SafeFree (known freeable _error : Bool) := known=true ∧ freeable=true
theorem unknownReleaseBlocksFree (a b : Bool) : ¬ SafeFree false a b := by simp [SafeFree]
theorem errorCodeNotFreeAuthority (a b e : Bool) : SafeFree a b e ↔ SafeFree a b false := by rfl
theorem alreadyFreedRejectsRepeat (known error : Bool) : ¬ SafeFree known false error := by simp [SafeFree]
def CallbackAllowed (permit waitingForSeal : Bool) := permit=true ∧ waitingForSeal=false
theorem waitingOwnerCannotCallback (p : Bool) : ¬ CallbackAllowed p true := by simp [CallbackAllowed]
def Cycle (ownerWaits cleanupWaits : Bool) := ownerWaits=true ∧ cleanupWaits=true
theorem deferredCleanupBreaksThisCycle (owner : Bool) : ¬ Cycle owner false := by simp [Cycle]
def SealMatches (epoch generation sealEpoch sealGeneration : Nat) := epoch=sealEpoch ∧ generation=sealGeneration
theorem staleSealRejected (e g se sg : Nat) (h : g≠sg) : ¬ SealMatches e g se sg := by simp [SealMatches,h]
theorem acknowledgementNotZeroBacking (pendingBytes : Nat) (h : 0<pendingBytes) : pendingBytes≠0 := by omega
theorem noReplayFromOutcomeLoss (calls : Nat) (h : calls=1) : ¬ calls+1≤1 := by omega
end GambitSMP.ResumeSealCleanup
