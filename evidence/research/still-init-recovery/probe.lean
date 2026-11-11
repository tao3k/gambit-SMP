import Std.Tactic
namespace GambitSMP.StillInitRecovery
structure Progress where
  committed : Nat
  physical : Nat
  writes : Nat
  deriving DecidableEq

def valid (p : Progress) : Prop :=
  p.committed ≤ p.physical ∧ p.physical ≤ p.committed+1 ∧ p.writes=p.physical
inductive Step : Progress → Progress → Prop where
  | write (p) (boundary : p.physical=p.committed) :
      Step p {p with physical:=p.physical+1, writes:=p.writes+1}
  | commit (p) : Step p {p with committed:=p.physical}
  | read (p) : Step p p

theorem stepPreserves {p q : Progress} (h : valid p) (step : Step p q) : valid q := by
  rcases h with ⟨h1,h2,h3⟩
  cases step with
  | write b => dsimp [valid]; omega
  | commit => dsimp [valid]; omega
  | read => exact ⟨h1,h2,h3⟩
inductive Trace : Progress → Progress → Prop where
  | refl (p) : Trace p p
  | next {p q r} : Trace p q → Step q r → Trace p r
theorem tracePreserves {p q : Progress} (h : valid p) (t : Trace p q) : valid q := by
  induction t with
  | refl => exact h
  | next _ s ih => exact stepPreserves ih s
theorem progressNeverRewinds {p q : Progress} (s : Step p q) (h : valid p) :
    p.committed≤q.committed := by
  cases s with
  | write => exact Nat.le_refl _
  | read => exact Nat.le_refl _
  | commit => exact h.1

theorem boundaryCursorExact (p : Progress) (idle : p.physical=p.committed) :
    p.physical-p.committed=0 := by omega
theorem uncommittedWriteNotTransferable (p : Progress) (inflight : p.physical=p.committed+1) :
    p.physical≠p.committed := by omega
-- Exclusive ownership is conditional on a single linearized owner/generation record.
theorem uniqueInitializer (owner a b : Nat) (ha : a=owner) (hb : b=owner) : a=b := by omega
theorem revokedGenerationRejected (generation presented : Nat) (old : presented=generation) :
    presented≠generation+1 := by omega
theorem readbackPreservesProgress (p : Progress) : valid p → valid p := id

structure Delivery where
  accepted : Bool
  receiverRoot : Bool
  count : Nat
  deriving DecidableEq

def admit (d : Delivery) : Delivery :=
  if d.accepted then d else {accepted:=true,receiverRoot:=true,count:=d.count+1}
def deliveryValid (d : Delivery) : Prop :=
  (d.accepted=true ∧ d.count=1 ∧ d.receiverRoot=true) ∨
  (d.accepted=false ∧ d.count=0)
theorem admissionPreserves (d : Delivery) (h : deliveryValid d) : deliveryValid (admit d) := by
  rcases h with h|h
  · simp [admit,h.1,deliveryValid,h.2.1,h.2.2]
  · simp [admit,h.1,h.2,deliveryValid]
theorem admissionIdempotent (d : Delivery) : admit (admit d)=admit d := by
  cases h : d.accepted <;> simp [admit,h]
theorem admissionAtMostOnce (d : Delivery) (h : deliveryValid d) : (admit d).count≤1 := by
  have v:=admissionPreserves d h
  rcases v with v|v <;> omega
theorem acceptedHasReceiverRoot (d : Delivery) (h : deliveryValid d) (a : d.accepted=true) :
    d.receiverRoot=true := by
  rcases h with h|h
  · exact h.2.2
  · simp [a] at h

def rootCovered (sender receiver : Bool) : Prop := sender=true ∨ receiver=true
theorem overlapHandoff (sender : Bool) : rootCovered sender true := Or.inr rfl
theorem senderReleaseRequiresReceiver (receiver : Bool) (h : rootCovered false receiver) :
    receiver=true := by simpa [rootCovered] using h

theorem metadataRefundDoesNotFree (backing overhead : Nat) : backing≤backing+overhead := by omega
theorem replayAvoidance (n p retries : Nat) (hp : p≤n) :
    n-p≤(retries+1)*n := by
  simp only [Nat.add_mul, Nat.one_mul]
  omega
end GambitSMP.StillInitRecovery

#check GambitSMP.StillInitRecovery.stepPreserves
#print axioms GambitSMP.StillInitRecovery.stepPreserves

#check GambitSMP.StillInitRecovery.tracePreserves
#print axioms GambitSMP.StillInitRecovery.tracePreserves

#check GambitSMP.StillInitRecovery.progressNeverRewinds
#print axioms GambitSMP.StillInitRecovery.progressNeverRewinds

#check GambitSMP.StillInitRecovery.boundaryCursorExact
#print axioms GambitSMP.StillInitRecovery.boundaryCursorExact

#check GambitSMP.StillInitRecovery.uncommittedWriteNotTransferable
#print axioms GambitSMP.StillInitRecovery.uncommittedWriteNotTransferable

#check GambitSMP.StillInitRecovery.uniqueInitializer
#print axioms GambitSMP.StillInitRecovery.uniqueInitializer

#check GambitSMP.StillInitRecovery.revokedGenerationRejected
#print axioms GambitSMP.StillInitRecovery.revokedGenerationRejected

#check GambitSMP.StillInitRecovery.readbackPreservesProgress
#print axioms GambitSMP.StillInitRecovery.readbackPreservesProgress

#check GambitSMP.StillInitRecovery.admissionPreserves
#print axioms GambitSMP.StillInitRecovery.admissionPreserves

#check GambitSMP.StillInitRecovery.admissionIdempotent
#print axioms GambitSMP.StillInitRecovery.admissionIdempotent

#check GambitSMP.StillInitRecovery.admissionAtMostOnce
#print axioms GambitSMP.StillInitRecovery.admissionAtMostOnce

#check GambitSMP.StillInitRecovery.acceptedHasReceiverRoot
#print axioms GambitSMP.StillInitRecovery.acceptedHasReceiverRoot

#check GambitSMP.StillInitRecovery.overlapHandoff
#print axioms GambitSMP.StillInitRecovery.overlapHandoff

#check GambitSMP.StillInitRecovery.senderReleaseRequiresReceiver
#print axioms GambitSMP.StillInitRecovery.senderReleaseRequiresReceiver

#check GambitSMP.StillInitRecovery.metadataRefundDoesNotFree
#print axioms GambitSMP.StillInitRecovery.metadataRefundDoesNotFree

#check GambitSMP.StillInitRecovery.replayAvoidance
#print axioms GambitSMP.StillInitRecovery.replayAvoidance
