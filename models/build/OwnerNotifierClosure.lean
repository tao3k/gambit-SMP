import Std.Tactic

namespace OwnerNotifierClosure

structure WillFrame where
  slot : Bool
  localArgument : Bool
def clearSlots (f : WillFrame) : WillFrame := { f with slot := false }
theorem clearSlotsKeepsLocal (f : WillFrame) : (clearSlots f).localArgument = f.localArgument := rfl

inductive Dispatch where | gc | manual
  deriving DecidableEq
def hasTicket (d : Dispatch) : Bool := d == .gc
theorem manualHasNoTicket : hasTicket .manual = false := by decide

structure Notice where
  prepared : Bool
  sealed : Bool
def prepare : Notice := ⟨true, false⟩
theorem preparedNotSealed : prepare.prepared = true ∧ prepare.sealed = false := by decide

inductive Exit where | normal | escape
  deriving DecidableEq
def afterRuns (_ : Exit) : Bool := true
def normalReturn (e : Exit) : Bool := e == .normal
theorem afterIsNotReturn : afterRuns .escape = true ∧ normalReturn .escape = false := by decide

theorem jobBackedge (registry job owner : Prop) (root : registry)
    (registered : registry → job) (captures : job → owner) : owner := captures (registered root)
def valid (ticket returned frameRetired uncaptured rootless matched : Bool) : Prop :=
  ticket = true ∧ returned = true ∧ frameRetired = true ∧ uncaptured = true ∧ rootless = true ∧ matched = true
theorem validNeedsExit (t r f c p m : Bool) (h : valid t r f c p m) :
    r = true ∧ f = true := ⟨h.2.1, h.2.2.1⟩
theorem captureRejects (t r f p m : Bool) : ¬ valid t r f false p m := by simp [valid]

structure RootlessPayload where
  ownerIdentity : Nat
  generation : Nat
  closeEpoch : Nat
def enqueue (p : RootlessPayload) : RootlessPayload := p
theorem stablePayload (p : RootlessPayload) : (enqueue p).ownerIdentity = p.ownerIdentity := rfl

-- A Nat-only record models the desired payload, not actual C pointer contents.
-- Dispatcher provenance, lexical/transitive closure, GC frame roots and aliases
-- remain source/native premises; these kernels do not establish notification latency.
end OwnerNotifierClosure
