import Std
namespace RcStorageBoundary
structure Key where
 domain : Nat
 storage : Nat
 generation : Nat
 deriving DecidableEq
theorem checkedTotal (bytes header limit : Int) (b : 0 ≤ bytes) (h : 0 < header) (g : bytes ≤ limit - header) : 0 < bytes + header ∧ bytes + header ≤ limit := by omega
theorem zeroPayloadStillOwnsHeader (header : Int) (h : 0 < header) : 0 < 0 + header := by omega
theorem staleKeyNotCurrent (old current : Key) (h : old.generation ≠ current.generation) : old ≠ current := by
 intro e; exact h (congrArg Key.generation e)
theorem addressOnlyCannotSeparate (authorize : Nat → Bool) (oldAddress newAddress : Nat) (same : oldAddress = newAddress) (rejectOld : authorize oldAddress = false) (acceptNew : authorize newAddress = true) : False := by
 simp_all
theorem metadataDoesNotFixMissingExpectedIdentity (authorize : Nat → Nat → Bool) (indexGeneration address : Nat) (rejectOld : authorize indexGeneration address = false) (acceptNew : authorize indexGeneration address = true) : False := by
 simp_all
def LinkedRelease (linked : Bool) (refcount : Int) : Prop := linked = true ∧ refcount > 0
theorem unregisteredNeedsPrivateAbort (refs : Int) : ¬ LinkedRelease false refs := by simp [LinkedRelease]
def FreePermit (closed : Bool) (accepted scans nativePins : Nat) (resultKnown effectsSettled grace : Bool) : Prop := closed = true ∧ accepted = 0 ∧ scans = 0 ∧ nativePins = 0 ∧ resultKnown = true ∧ effectsSettled = true ∧ grace = true
theorem countZeroAloneInsufficient : ¬ FreePermit false 0 0 0 true true true := by simp [FreePermit]
theorem unknownOutcomeCannotFree (closed : Bool) (accepted scans nativePins : Nat) (effects grace : Bool) : ¬ FreePermit closed accepted scans nativePins false effects grace := by simp [FreePermit]
theorem unknownNativeBorrowCannotFree (closed : Bool) (accepted scans : Nat) (pins : Nat) (p : pins > 0) (known effects grace : Bool) : ¬ FreePermit closed accepted scans pins known effects grace := by
 intro e
 simp only [FreePermit] at e
 rcases e with ⟨_,_,_,zero,_,_,_⟩
 omega
end RcStorageBoundary
