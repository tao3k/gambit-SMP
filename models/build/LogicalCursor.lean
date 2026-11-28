import Std.Tactic

namespace LogicalCursor

-- Coordinates are decoded-character boundaries, not UTF-8 byte offsets.
theorem partition {A : Type} (xs : List A) (cut : Nat) :
    xs.take cut ++ xs.drop cut = xs := List.take_append_drop cut xs

theorem spanLength (a b : Nat) (ordered : a ≤ b) : a + (b - a) = b :=
  Nat.add_sub_of_le ordered

structure Domain where
  current : Nat
  pins : Nat
  errors : Nat
  borrows : Nat
  unknown : Nat
  deriving DecidableEq

-- Capture stores a domain reference. Its historical coordinate is diagnostic only.
def resume (live : Domain) (_captureCoordinate : Nat) : Nat := live.current
theorem resumeCurrent (d : Domain) (saved : Nat) : resume d saved = d.current := rfl
def capture (d : Domain) : Domain := { d with pins := d.pins + 1 }
theorem rootedCapture (d : Domain) : (capture d).pins > 0 := Nat.zero_lt_succ _

inductive Delivery where | pending | value | error | escape
  deriving DecidableEq
def deliver (d : Delivery) (result : Delivery) : Delivery :=
  match d with | .pending => result | other => other
theorem settlementNoRetry (d r : Delivery) (done : d ≠ .pending) : deliver d r = d := by
  cases d <;> simp_all [deliver]

def drained (d : Domain) : Prop := d.pins = 0 ∧ d.errors = 0 ∧ d.borrows = 0 ∧ d.unknown = 0
theorem retireNeedsDrain (d : Domain) (canRetire : drained d) : d.pins = 0 ∧ d.unknown = 0 :=
  ⟨canRetire.1, canRetire.2.2.2⟩
theorem netWork (required avoided spans pins adapter checking : Nat)
    (positive : spans + pins + adapter + checking < avoided) :
    required + (spans + pins + adapter + checking) < required + avoided :=
  Nat.add_lt_add_left positive required

-- These kernels are premises, not a proof of dynamic-wind, port adaptation,
-- source-to-QNT refinement, C memory ordering, or full reader equivalence.
end LogicalCursor
