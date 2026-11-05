import Std.Tactic

namespace GerbilSessionClosure

def write {Location Value : Type} [DecidableEq Location]
    (heap : Location → Value) (address : Location) (value : Value) : Location → Value :=
  fun l => if l = address then value else heap l

theorem writePreservesOther {Location Value : Type} [DecidableEq Location]
    (heap : Location → Value) (a b : Location) (value : Value) (separate : b ≠ a) :
    write heap a value b = heap b := by simp [write, separate]

theorem writesCommute {Location Value : Type} [DecidableEq Location]
    (heap : Location → Value) (a b : Location) (va vb : Value) (separate : a ≠ b) :
    write (write heap a va) b vb = write (write heap b vb) a va := by
  funext l
  by_cases hla : l = a
  · subst l
    simp [write, separate]
  · by_cases hlb : l = b
    · subst l
      simp [write, Ne.symm separate]
    · simp [write, hla, hlb]

def DisjointWrites {Location : Type} (left right : Location → Prop) : Prop :=
  ∀ l, left l → ¬right l

theorem noCrossOwnership {Location : Type} (left right : Location → Prop)
    (separate : DisjointWrites left right) (l : Location) (owned : left l) : ¬right l :=
  separate l owned

-- Complete is a source-issued premise, not derivable from a finite file list.
def ExecutableCut {Node : Type} (root : Node → Prop) (edge : Node → Node → Prop)
    (required : Node → Prop) (sealed : Node → Prop) (complete : Prop) : Prop :=
  complete ∧ (∀ n, root n → required n) ∧
  (∀ a b, required a → edge a b → required b) ∧ (∀ n, required n → sealed n)

theorem closedRequired {Node : Type} {root : Node → Prop} {edge : Node → Node → Prop}
    {required sealed : Node → Prop} {complete : Prop}
    (cut : ExecutableCut root edge required sealed complete)
    {a b : Node} (needed : required a) (call : edge a b) : sealed b :=
  cut.2.2.2 b (cut.2.2.1 a b needed call)

theorem unknownRejects {Node : Type} {root : Node → Prop} {edge : Node → Node → Prop}
    {required sealed : Node → Prop} {complete : Prop} (unknown : ¬complete) :
    ¬ExecutableCut root edge required sealed complete := fun cut => unknown cut.1

-- Comparing duplicated isolated program production only. Existing batch cache
-- savings and extra instance work must not be counted as newly removed work.
theorem sharingPositive {mandatory program overhead : Nat} (h : overhead < program) :
    mandatory + program + overhead < mandatory + program + program :=
  Nat.add_lt_add_left h (mandatory + program)

theorem publicationRequiresEpoch {Epoch : Type} {session current : Epoch}
    (h : session = current) : current = session := h.symm

end GerbilSessionClosure
