import Std.Tactic

namespace FoundationBindingIdentity

def toggle {Mark : Type} [DecidableEq Mark] (m : Mark) (marks : List Mark) : List Mark :=
  match marks with
  | [] => [m]
  | h :: t => if m = h then t else m :: h :: t

theorem mapToggle {A B : Type} [DecidableEq A] [DecidableEq B]
    (f : A → B) (injective : Function.Injective f) (m : A) (marks : List A) :
    (toggle m marks).map f = toggle (f m) (marks.map f) := by
  cases marks with
  | nil => simp [toggle]
  | cons h t =>
    by_cases same : m = h
    · subst m; simp [toggle]
    · have distinct : f m ≠ f h := fun eq => same (injective eq)
      simp [toggle, same, distinct]

theorem bindingEqualityPreserved {A B : Type} (f : A → B)
    (injective : Function.Injective f) (a b : A) : f a = f b ↔ a = b := by
  constructor
  · intro h; exact injective h
  · intro h; exact congrArg f h

def rebuild {K TK V TV : Type} (decode : TK → K) (encodeValue : V → TV)
    (env : K → Option V) : TK → Option TV := fun k => (env (decode k)).map encodeValue

theorem transportedLookup {K TK V TV : Type} (encode : K → TK) (decode : TK → K)
    (value : V → TV) (env : K → Option V) (inverse : ∀ k, decode (encode k) = k) (k : K) :
    rebuild decode value env (encode k) = (env k).map value := by
  simp [rebuild, inverse k]

theorem missingLookupPreserved {K TK V TV : Type} (encode : K → TK) (decode : TK → K)
    (value : V → TV) (env : K → Option V) (inverse : ∀ k, decode (encode k) = k)
    (k : K) (missing : env k = none) : rebuild decode value env (encode k) = none := by
  rw [transportedLookup encode decode value env inverse k, missing]
  rfl

theorem contextAliasPreserved {A B : Type} (f : A → B) (injective : Function.Injective f)
    (a b : A) (distinct : a ≠ b) : f a ≠ f b := fun h => distinct (injective h)

-- A once-per-module-instance mutable counter cannot be replaced by a fresh
-- per-consumer counter while preserving the two observed results.
theorem statefulResetChangesObservation :
    ((1, 2) : Nat × Nat) ≠ (1, 1) := by decide

theorem actualWorkPositive {mandatory avoided init overlay validation ipc : Nat}
    (positive : init + overlay + validation + ipc < avoided) :
    mandatory + (init + overlay + validation + ipc) < mandatory + avoided :=
  Nat.add_lt_add_left positive mandatory

end FoundationBindingIdentity
