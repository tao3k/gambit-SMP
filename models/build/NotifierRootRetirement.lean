import Std.Tactic
namespace NotifierRootRetirement
structure Roots where
  reg : Bool
  saved : Bool
  stack : Bool
  capture : Bool
  deriving DecidableEq
def restore (r : Roots) : Roots := { r with saved := false, reg := r.reg || r.saved }
theorem savedClearTransfers (r : Roots) (h : r.saved = true) :
    (restore r).saved = false ∧ (restore r).reg = true := by simp [restore, h]
def copyCont (r : Roots) : Roots := r
theorem copyRetains (r : Roots) (h : r.capture = true) : (copyCont r).capture = true := h
def returnAction (r : Roots) : Roots := r
theorem returnNotRetired (r : Roots) (h : r.reg = true) : (returnAction r).reg = true := h
inductive Event where | normal | capture | failure
  deriving DecidableEq
def taint (t : Bool) (e : Event) : Bool := t || (e == .capture) || (e == .failure)
def runTaint : Bool → List Event → Bool
  | t, [] => t
  | t, e :: es => runTaint (taint t e) es
theorem taintSticky (es : List Event) : runTaint true es = true := by
  induction es with
  | nil => rfl
  | cons e es ih => simpa [runTaint, taint] using ih
def absent (r : Roots) : Prop := r.reg = false ∧ r.saved = false ∧ r.stack = false ∧ r.capture = false
def valid (r : Roots) (normal closed clean matched : Bool) : Prop :=
  absent r ∧ normal = true ∧ closed = true ∧ clean = true ∧ matched = true
theorem normalNeeded (r : Roots) (n c t m : Bool) (h : valid r n c t m) : n = true := h.2.1
theorem captureRejects (r : Roots) (n c t m : Bool) (h : r.capture = true) : ¬ valid r n c t m := by
  intro v
  have x := v.1.2.2.2
  simp [h] at x
-- Restricted post-cut steps are identities on roots: replay delivery or scalar-only publication.
-- This step relation is a design premise; actual GVM/source refinement remains open.
inductive ClosedStep : Roots → Roots → Prop where
  | deliver (r) : ClosedStep r r
  | settle (r) : ClosedStep r r
theorem closedPreserved (a b : Roots) (h : absent a) (s : ClosedStep a b) : absent b := by
  cases s <;> exact h
theorem matchRequired (r : Roots) (n c t m : Bool) (h : valid r n c t m) : m = true := h.2.2.2.2
end NotifierRootRetirement
