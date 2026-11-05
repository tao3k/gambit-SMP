import Std

namespace GambitBuild

/- Pure contract theory. There is no filesystem, compiler, cryptographic hash,
   native scheduler or QNT refinement theorem in this file. -/

inductive Affected {Node : Type} (dep : Node → Node → Prop)
    (changed : Node → Prop) : Node → Prop where
  | source {n} : changed n → Affected dep changed n
  | consumer {d n} : Affected dep changed d → dep d n → Affected dep changed n

theorem unaffectedDependency {Node : Type} {dep : Node → Node → Prop}
    {changed : Node → Prop} {d n : Node}
    (outside : ¬ Affected dep changed n) (edge : dep d n) :
    ¬ Affected dep changed d := by
  intro hd
  exact outside (.consumer hd edge)

theorem emptyChangeHasNoAffected {Node : Type} {dep : Node → Node → Prop}
    {n : Node} : ¬ Affected dep (fun _ => False) n := by
  intro h
  induction h with
  | source h => exact h
  | consumer _ _ ih => exact ih

-- A producer consumes a declared input cut. Extensionality of that cut is a
-- source obligation; collision-free hashing is deliberately not assumed.
def CutAgreement {Input Value : Type} (cut : Input → Prop)
    (a b : Input → Value) : Prop := ∀ i, cut i → a i = b i

def CutComplete {Input Value Output : Type} (cut : Input → Prop)
    (produce : (Input → Value) → Output) : Prop :=
  ∀ a b, CutAgreement cut a b → produce a = produce b

theorem reuseMatchesClean {Input Value Output : Type}
    {cut : Input → Prop} {produce : (Input → Value) → Output}
    {previous current : Input → Value} {cached : Output}
    (complete : CutComplete cut produce)
    (origin : cached = produce previous)
    (agreement : CutAgreement cut previous current) : cached = produce current := by
  exact origin.trans (complete previous current agreement)

-- Cutoff must preserve every projection consumed by a particular successor.
theorem projectionCutoff {Output View Result : Type}
    (observe : Output → View) (consume : View → Result)
    {old fresh : Output} (same : observe old = observe fresh) :
    consume (observe old) = consume (observe fresh) := by
  exact congrArg consume same

def runWork (keyMatches : Bool) : Nat := if keyMatches then 0 else 1

theorem validNoOpWork (keys : List Bool) (allMatch : ∀ b ∈ keys, b = true) :
    (keys.map runWork).sum = 0 := by
  induction keys with
  | nil => rfl
  | cons b bs ih =>
    have hb : b = true := allMatch b (by simp)
    have hs : ∀ x ∈ bs, x = true := by
      intro x hx
      exact allMatch x (by simp [hx])
    simp [hb, runWork, ih hs]

structure Budget where
  used : Nat
  limit : Nat

inductive BudgetStep : Budget → Budget → Prop where
  | start (used limit weight : Nat) (admitted : used + weight ≤ limit) :
      BudgetStep ⟨used, limit⟩ ⟨used + weight, limit⟩
  | finish (used limit weight : Nat) (owned : weight ≤ used) :
      BudgetStep ⟨used, limit⟩ ⟨used - weight, limit⟩

theorem budgetStepPreserves {a b : Budget} (safe : a.used ≤ a.limit)
    (step : BudgetStep a b) : b.used ≤ b.limit := by
  cases step with
  | start _ _ _ admitted => exact admitted
  | finish _ _ _ _ => exact Nat.le_trans (Nat.sub_le _ _) safe

inductive BudgetTrace : Budget → Budget → Prop where
  | refl (a) : BudgetTrace a a
  | step {a b c} : BudgetTrace a b → BudgetStep b c → BudgetTrace a c

theorem budgetTracePreserves {a b : Budget} (safe : a.used ≤ a.limit)
    (trace : BudgetTrace a b) : b.used ≤ b.limit := by
  induction trace with
  | refl => exact safe
  | step _ step ih => exact budgetStepPreserves ih step

-- Credits are held by running jobs, not by finished staged or published jobs.
-- This algebra does not prove parent/child progress or actual RSS bounds.
theorem returnedCreditCannotIncrease (used credit : Nat) : used - credit ≤ used :=
  Nat.sub_le _ _

end GambitBuild
