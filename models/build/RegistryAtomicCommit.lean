import Std.Tactic
namespace RegistryAtomicCommit
structure Bundle where
 registry : List Nat
 events : List (Nat × Nat)
 deriving DecidableEq
def publish (_old candidate : Bundle) : Bundle := candidate
theorem wholeBundle (old candidate : Bundle) : (publish old candidate).registry=candidate.registry ∧ (publish old candidate).events=candidate.events := by simp [publish]
-- Existing receipt lookup precedes checks that apply only to fresh writes.
def decideReceipt (existing : Option Nat) (baseOK fenceOK : Bool) : Option Nat :=
 match existing with | some seq => some seq | none => if baseOK && fenceOK then some 0 else none
theorem existingFirst (seq : Nat) (baseOK fenceOK : Bool) : decideReceipt (some seq) baseOK fenceOK=some seq := rfl
def payloadOK (stored requested : Nat) := stored==requested
theorem payloadConflict (stored requested : Nat) (h : stored≠requested) : payloadOK stored requested=false := by simp [payloadOK,h]
theorem baseReject (fenceOK : Bool) : decideReceipt none false fenceOK=none := by simp [decideReceipt]
theorem fenceReject (baseOK : Bool) : decideReceipt none baseOK false=none := by simp [decideReceipt]
theorem distinctOccurrences (activation ordinal : Nat) : (activation+1,ordinal)≠(activation,ordinal) := by
 intro h
 have e := congrArg Prod.fst h
 simp only [Prod.fst] at e
 omega
theorem lookupUnchanged (old candidate : Bundle) (h : candidate=old) : publish old candidate=old := by simp [publish,h]
def retain (pending saved unknown : Bool) := pending || saved || unknown
theorem retainedRoots (pending saved unknown : Bool) (h : pending=true ∨ saved=true ∨ unknown=true) : retain pending saved unknown=true := by
 rcases h with h|h|h <;> simp [retain,h]
def abortCandidate (old _candidate : Bundle) := old
theorem abortUnpublished (old candidate : Bundle) : abortCandidate old candidate=old := rfl
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end RegistryAtomicCommit
