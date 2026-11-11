namespace GambitSMP.EscrowPublicationReentry
structure View where
 registered : Nat
 described : Nat
 outstandingWriters : Nat
 epoch : Nat
 generation : Nat
 scannedEpoch : Nat
 scannedGeneration : Nat
 scanPins : Nat
 metadataKnown : Bool
def Published (s : View) := s.registered=s.described ∧ s.outstandingWriters=0 ∧ s.metadataKnown=true
def CanReenter (s : View) := Published s ∧ s.epoch=s.scannedEpoch ∧ s.generation=s.scannedGeneration ∧ s.scanPins=0
theorem writerRejectsPublication (s : View) (h : 0<s.outstandingWriters) : ¬ Published s := by simp [Published]; omega
theorem incompleteViewRejects (s : View) (h : s.registered≠s.described) : ¬ Published s := by simp [Published,h]
theorem scanPinRejectsReentry (s : View) (h : 0<s.scanPins) : ¬ CanReenter s := by simp [CanReenter]; omega
theorem staleEpochRejects (s : View) (h : s.epoch≠s.scannedEpoch) : ¬ CanReenter s := by simp [CanReenter,h]
theorem staleGenerationRejects (s : View) (h : s.generation≠s.scannedGeneration) : ¬ CanReenter s := by simp [CanReenter,h]
structure RootCell where
 location : Nat
 value : Nat
def relocate (c : RootCell) (v : Nat) := {c with value:=v}
theorem relocationPreservesDescriptor (c : RootCell) (v : Nat) : (relocate c v).location=c.location := by rfl
def reload (c : RootCell) : Nat := c.value
theorem reloadedValueCurrent (c : RootCell) (v : Nat) : reload (relocate c v)=v := by rfl
structure Commit where
 bodyReady : Bool
 resultRoot : Bool
 escrowOwner : Bool
 tokenFresh : Bool
def CanCommit (s : Commit) := s.bodyReady=true ∧ s.resultRoot=true ∧ s.escrowOwner=true ∧ s.tokenFresh=true
theorem uninitializedRejects (s : Commit) (h : s.bodyReady=false) : ¬ CanCommit s := by simp [CanCommit,h]
theorem unrootedRejects (s : Commit) (h : s.resultRoot=false) : ¬ CanCommit s := by simp [CanCommit,h]
theorem oldTokenRejects (s : Commit) (h : s.tokenFresh=false) : ¬ CanCommit s := by simp [CanCommit,h]
structure Custody where
 escrow : Nat
 wrapper : Nat
 retired : Nat
def total (s : Custody) := s.escrow+s.wrapper+s.retired
def commit (s : Custody) := {s with escrow:=s.escrow-1,wrapper:=s.wrapper+1}
def retire (s : Custody) := {s with wrapper:=s.wrapper-1,retired:=s.retired+1}
theorem commitConserves (s : Custody) (h : 0<s.escrow) : total (commit s)=total s := by simp [total,commit]; omega
theorem retireConserves (s : Custody) (h : 0<s.wrapper) : total (retire s)=total s := by simp [total,retire]; omega
inductive Step : Custody → Custody → Prop
 | commit (s : Custody) (h : 0<s.escrow) : Step s (EscrowPublicationReentry.commit s)
 | retire (s : Custody) (h : 0<s.wrapper) : Step s (EscrowPublicationReentry.retire s)
 | query (s : Custody) : Step s s
theorem stepConserves {a b : Custody} (h : Step a b) : total a=total b := by cases h with
 | commit p => exact (commitConserves _ p).symm
 | retire p => exact (retireConserves _ p).symm
 | query => rfl
inductive Trace : Custody → Custody → Prop
 | nil (s : Custody) : Trace s s
 | cons {a b c : Custody} : Step a b → Trace b c → Trace a c
theorem traceConserves {a b : Custody} (h : Trace a b) : total a=total b := by induction h with
 | nil => rfl
 | cons h _ ih => exact (stepConserves h).trans ih
-- Parent/child slots are separate functions of invocation identity.
def writeSlot (slots : Nat→Nat) (id value : Nat) := fun k => if k=id then value else slots k
theorem otherInvocationUnaffected (slots : Nat→Nat) (parent child value : Nat) (h : parent≠child) : writeSlot slots parent value child=slots child := by simp [writeSlot,Ne.symm h]
theorem sameInvocationReadsCommitted (slots : Nat→Nat) (id value : Nat) : writeSlot slots id value id=value := by simp [writeSlot]
structure RetireGate where
 dispositionKnown : Bool
 readers : Nat
 borrowers : Nat
 descendants : Nat
 initOwnerKnown : Bool
def CanRetire (s : RetireGate) := s.dispositionKnown=true ∧ s.readers=0 ∧ s.borrowers=0 ∧ s.descendants=0 ∧ s.initOwnerKnown=true
theorem readerBlocksRetirement (s : RetireGate) (h : 0<s.readers) : ¬ CanRetire s := by simp [CanRetire]; omega
theorem borrowerBlocksRetirement (s : RetireGate) (h : 0<s.borrowers) : ¬ CanRetire s := by simp [CanRetire]; omega
theorem childBlocksRetirement (s : RetireGate) (h : 0<s.descendants) : ¬ CanRetire s := by simp [CanRetire]; omega
theorem unknownInitKeepsDuty (s : RetireGate) (h : s.initOwnerKnown=false) : ¬ CanRetire s := by simp [CanRetire,h]
theorem invalidMarkerCannotReturn (markerLive : Bool) (h : markerLive=false) : ¬ markerLive=true := by simp [h]
theorem secondCommitRejected (count : Nat) (h : count=1) : ¬ count+1≤1 := by omega
end GambitSMP.EscrowPublicationReentry
