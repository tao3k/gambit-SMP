import TicketIdentityAlgebra
namespace RestoreGuardAlgebra
open TicketIdentityAlgebra
structure GuardId where
 ticket : Key
 serial : Nat
 owner : Nat
 deriving DecidableEq
structure GuardRecord where
 id : GuardId
 terminal : Option Int
 deriving DecidableEq
structure ExitWitness where
 id : GuardId
 restored : Bool
 markerClosed : Bool
 value : Int
 deriving DecidableEq
-- Witness provenance is a source obligation; equality/cleanup checks are mathematical here.
def accept (guard : GuardRecord) (w : ExitWitness) : GuardRecord :=
 if w.id=guard.id ∧ w.restored=true ∧ w.markerClosed=true then
  match guard.terminal with
  | some _ => guard
  | none => {guard with terminal:=some w.value}
 else guard
theorem wrongTicketRetained (g : GuardRecord) (w : ExitWitness)
 (different : w.id.ticket≠g.id.ticket) : accept g w=g := by
 have h : w.id≠g.id := by intro e; exact different (congrArg GuardId.ticket e)
 simp [accept,h]
theorem wrongSerialRetained (g : GuardRecord) (w : ExitWitness)
 (different : w.id.serial≠g.id.serial) : accept g w=g := by
 have h : w.id≠g.id := by intro e; exact different (congrArg GuardId.serial e)
 simp [accept,h]
theorem wrongOwnerRetained (g : GuardRecord) (w : ExitWitness)
 (different : w.id.owner≠g.id.owner) : accept g w=g := by
 have h : w.id≠g.id := by intro e; exact different (congrArg GuardId.owner e)
 simp [accept,h]
theorem markerStillLiveRetained (g : GuardRecord) (w : ExitWitness)
 (live : w.markerClosed=false) : accept g w=g := by simp [accept,live]
theorem unrestoredRetained (g : GuardRecord) (w : ExitWitness)
 (u : w.restored=false) : accept g w=g := by simp [accept,u]
theorem existingOutcomeRetained (g : GuardRecord) (w : ExitWitness) (v : Int)
 (done : g.terminal=some v) : accept g w=g := by simp [accept,done]
theorem acceptIdempotent (g : GuardRecord) (w : ExitWitness) :
 accept (accept g w) w=accept g w := by
 cases g with
 | mk id terminal =>
  cases terminal with
  | some v => simp [accept]
  | none =>
   by_cases h : w.id=id ∧ w.restored=true ∧ w.markerClosed=true
   · simp [accept,h]
   · simp [accept,h]
-- The mutable ambient binding is deliberately not used to select a receipt target.
def dispatch (records : GuardId → GuardRecord) (_ambient : Option GuardId)
 (w : ExitWitness) : GuardId → GuardRecord :=
 fun key => if key=w.id then accept (records key) w else records key
theorem ambientCannotRetarget (records : GuardId → GuardRecord)
 (a b : Option GuardId) (w : ExitWitness) : dispatch records a w=dispatch records b w := by rfl
theorem otherGuardUntouched (records : GuardId → GuardRecord) (ambient : Option GuardId)
 (w : ExitWitness) (key : GuardId) (other : key≠w.id) :
 dispatch records ambient w key=records key := by simp [dispatch,other]
end RestoreGuardAlgebra
