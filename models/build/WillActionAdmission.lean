import Std.Tactic
namespace WillActionAdmission
inductive Point where | entry | test | finalized | released | cleared | returned
  deriving DecidableEq
def needsSelf : Point → Bool
  | .cleared | .returned => false
  | _ => true
theorem preStoreLive : needsSelf .finalized = true ∧ needsSelf .released = true := by decide
def finalize (_status : Nat) : Bool := true
theorem finalizeErrorStillDestroys (errorCode : Nat) : finalize errorCode = true := rfl
structure Evidence where
  hashMatch : Bool
  uuidMatch : Bool
  generation : Bool
  maps : Bool
  rootRetired : Bool
  restricted : Bool
  restoreClosed : Bool
  deriving DecidableEq
def justHash : Evidence := ⟨true,false,false,false,false,false,false⟩
def justUuid : Evidence := ⟨false,true,false,false,false,false,false⟩
theorem matchedNotGenerated : justHash.hashMatch = true ∧ justHash.generation = false := by decide
theorem uuidNotMap : justUuid.uuidMatch = true ∧ justUuid.maps = false := by decide
def semanticLastUse (e : Evidence) : Evidence := e
theorem lastUseNotRetired (e : Evidence) : (semanticLastUse e).rootRetired = e.rootRetired := rfl
def valid (e : Evidence) : Prop := e.generation = true ∧ e.maps = true ∧
  e.rootRetired = true ∧ e.restricted = true ∧ e.restoreClosed = true
theorem cleanupNotNotifier (e : Evidence) (h : e.restricted = false) : ¬ valid e := by
  intro v
  have x := v.2.2.2.1
  simp [h] at x
theorem receiptNeedsMaps (e : Evidence) (h : valid e) : e.maps = true := h.2.1
theorem receiptNeedsRestore (e : Evidence) (h : valid e) : e.restoreClosed = true := h.2.2.2.2
-- Conditional support kernels only. SQLite library effects and actual GVM masks
-- are not modeled by Evidence, and no binary/source equivalence follows.
end WillActionAdmission
