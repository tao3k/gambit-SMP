import Std.Tactic
namespace SpecializerProviderSemantics
inductive Mode | generic | fixnum | flonum deriving DecidableEq
def selectSafe (spec : α) := spec
def selectUnsafe (self spec : α) (safe : Bool) := if safe then self else spec
def selectArith [DecidableEq α] (self fix flo unsafeChoice : α) (safe : Bool) (mode : Mode) :=
 if safe=false ∧ unsafeChoice≠self then unsafeChoice else
 match mode with | .fixnum => fix | .flonum => flo | .generic => self
theorem safeTransport (rho : α → β) (spec : α) : rho (selectSafe spec) = selectSafe (rho spec) := rfl
theorem unsafeTransport (rho : α → β) (self spec : α) (safe : Bool) :
 rho (selectUnsafe self spec safe) = selectUnsafe (rho self) (rho spec) safe := by cases safe <;> rfl
theorem arithTransport [DecidableEq α] [DecidableEq β] (rho : α → β) (inj : Function.Injective rho)
 (self fix flo unsafeChoice : α) (safe : Bool) (mode : Mode) :
 rho (selectArith self fix flo unsafeChoice safe mode) = selectArith (rho self) (rho fix) (rho flo) (rho unsafeChoice) safe mode := by
 have ne : rho unsafeChoice ≠ rho self ↔ unsafeChoice ≠ self := by
  constructor
  · intro h e; exact h (congrArg rho e)
  · intro h e; exact h (inj e)
 by_cases h : safe=false ∧ unsafeChoice≠self
 · have h' : safe=false ∧ rho unsafeChoice≠rho self := ⟨h.1,ne.mpr h.2⟩
   simp [selectArith,h,h']
 · have h' : ¬ (safe=false ∧ rho unsafeChoice≠rho self) := by intro k; exact h ⟨k.1,ne.mp k.2⟩
   cases mode <;> simp [selectArith,h,h']
def capture (self : Option α) (name : Option Nat) (lookup : Nat → Option α) :=
 match name with | none => self | some n => lookup n
theorem captureTransport (rho : α → β) (self : Option α) (name : Option Nat) (lookup : Nat → Option α) :
 Option.map rho (capture self name lookup) = capture (Option.map rho self) name (fun n => Option.map rho (lookup n)) := by cases name <;> rfl
theorem missingDifferent : capture (some 0) none (fun _ => (none : Option Nat)) ≠ capture (some 0) (some 1) (fun _ => (none : Option Nat)) := by decide
def addr (w n : Nat) := 100+10*w+n
theorem relocationInjective (w v i j : Nat) (hi : i<10) (hj : j<10) (h : addr w i=addr v j) : w=v ∧ i=j := by unfold addr at h; omega
def lookup (name : Nat) (fallback : Mode) : List (Nat × Mode) → Mode
 | [] => fallback
 | (n,m)::rest => if n=name then m else lookup name fallback rest
theorem namedDeclarations : lookup 1 .generic [(1,.fixnum),(2,.flonum)] ≠ lookup 2 .generic [(1,.fixnum),(2,.flonum)] := by decide
theorem declarationOrder : lookup 1 .generic [(1,.fixnum),(1,.flonum)] ≠ lookup 1 .generic [(1,.flonum),(1,.fixnum)] := by decide
theorem costPositive (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end SpecializerProviderSemantics
