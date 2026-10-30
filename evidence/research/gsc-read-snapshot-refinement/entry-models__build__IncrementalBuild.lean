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

-- Increasing a conservative cut preserves extensional completeness. Finding
-- a finite fixed point is separate from proving this semantic premise.
theorem agreementOnSmallerCut {Input Value : Type} {small large : Input → Prop}
    {a b : Input → Value} (included : ∀ i, small i → large i)
    (agreement : CutAgreement large a b) : CutAgreement small a b := by
  intro i hi
  exact agreement i (included i hi)

theorem completeCutCanGrow {Input Value Output : Type}
    {small large : Input → Prop} {produce : (Input → Value) → Output}
    (included : ∀ i, small i → large i) (complete : CutComplete small produce) :
    CutComplete large produce := by
  intro a b agreement
  exact complete a b (agreementOnSmallerCut included agreement)

-- An extension cannot remove an already required downstream invalidation.
theorem affectedEdgeExtension {Node : Type} {before after : Node → Node → Prop}
    {changed : Node → Prop} {n : Node}
    (included : ∀ a b, before a b → after a b)
    (affected : Affected before changed n) : Affected after changed n := by
  induction affected with
  | source h => exact .source h
  | consumer _ edge ih => exact .consumer ih (included _ _ edge)

def ObservationAgreement {Input Value : Type} (image : Input → Value)
    (trace : List (Input × Value)) : Prop := ∀ p ∈ trace, p.2 = image p.1

theorem immutableReadExtendsTrace {Input Value : Type} {image : Input → Value}
    {trace : List (Input × Value)} (sound : ObservationAgreement image trace)
    (i : Input) : ObservationAgreement image ((i, image i) :: trace) := by
  intro p hp
  rcases List.mem_cons.mp hp with hp | hp
  · subst p; rfl
  · exact sound p hp

-- A linearized epoch check is useful only if its issuer proves the following
-- agreement. End-of-run equal hashes do not construct this premise.
theorem receiptReuseMatchesClean {Input Value Output : Type}
    {cut : Input → Prop} {produce : (Input → Value) → Output}
    {previous image current : Input → Value} {cached : Output}
    (complete : CutComplete cut produce) (origin : cached = produce previous)
    (traceValid : CutAgreement cut previous image)
    (receipt : CutAgreement cut image current) : cached = produce current := by
  apply reuseMatchesClean complete origin
  intro i hi
  exact (traceValid i hi).trans (receipt i hi)

-- A family of observations, not one arbitrarily chosen metadata projection.
theorem allConsumerCutoff {Consumer Output View : Type}
    (observe : Consumer → Output → View) {old fresh : Output}
    (same : ∀ c, observe c old = observe c fresh)
    (c : Consumer) (consume : View → View) :
    consume (observe c old) = consume (observe c fresh) := by
  exact congrArg consume (same c)

-- Conditional forward simulation preserves a safety invariant. This reusable
-- lemma supplies NO relation between actual GSC processes and either QNT model.
theorem projectedStepPreserves {Concrete Abstract : Type}
    (project : Concrete → Abstract) (step : Concrete → Concrete → Prop)
    (abstractStep : Abstract → Abstract → Prop) (safe : Abstract → Prop)
    (simulate : ∀ a b, step a b →
      abstractStep (project a) (project b) ∨ project a = project b)
    (preserve : ∀ a b, safe a → abstractStep a b → safe b)
    {a b : Concrete} (ha : safe (project a)) (hab : step a b) :
    safe (project b) := by
  rcases simulate a b hab with move | idle
  · exact preserve _ _ ha move
  · rw [← idle]; exact ha

end GambitBuild
