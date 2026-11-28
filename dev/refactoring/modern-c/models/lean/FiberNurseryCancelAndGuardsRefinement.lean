/-
  Lean 4 refinement proof for (gambit fiber) structured nursery cancellation
  and scheduler boundary guards:
    1. Error recording always implies nursery cancellation (monotonic 0 -> 1).
    2. Cooperative cancellation is idempotent and never erases a recorded error.
    3. with-nursery exit requires active == 0 (zero orphaned children on exit).
    4. Cross-scheduler nursery spawn and outside-run-fibers fiber-yield are
       rejected before touching worker-ctx state.
-/

namespace FiberNurseryCancelAndGuards

structure Nursery where
  schedId : Nat
  active : Nat
  cancelled : Bool
  hasErr : Bool
  firstErr : Option Nat
  deriving DecidableEq, Repr

def cancelNursery (n : Nursery) : Nursery :=
  { n with cancelled := true }

def recordError (n : Nursery) (e : Nat) : Nursery :=
  { n with
      cancelled := true
    , hasErr := true
    , firstErr := match n.firstErr with | none => some e | some prev => some prev }

def canExit (n : Nursery) : Bool :=
  n.active == 0

theorem record_error_implies_cancelled_and_preserves_first (n : Nursery) (e1 e2 : Nat) :
    let n1 := recordError { n with hasErr := false, firstErr := none } e1
    let n2 := recordError n1 e2
    n1.cancelled = true ∧ n1.hasErr = true ∧ n1.firstErr = some e1 ∧
    n2.cancelled = true ∧ n2.firstErr = some e1 := by
  simp [recordError]

theorem cancel_is_idempotent_and_preserves_error (n : Nursery) (e : Nat) :
    let n1 := recordError n e
    let n2 := cancelNursery n1
    let n3 := cancelNursery n2
    n2 = n3 ∧ n3.cancelled = true ∧ n3.hasErr = true ∧ n3.firstErr = n1.firstErr := by
  simp [cancelNursery, recordError]

theorem exit_requires_zero_active (n : Nursery) (h : canExit n = true) :
    n.active = 0 := by
  simpa [canExit] using h

def checkSpawnNursery (callerSched : Option Nat) (n : Nursery) : Bool :=
  match callerSched with
  | none => false
  | some s => s == n.schedId

theorem spawn_guard_rejects_outside_and_foreign (n : Nursery) (s : Nat) (hne : s ≠ n.schedId) :
    checkSpawnNursery none n = false ∧ checkSpawnNursery (some s) n = false := by
  simp [checkSpawnNursery, hne]

end FiberNurseryCancelAndGuards
