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

-- A closed, deterministic adaptive reader. Real Scheme macro evaluation has
-- NOT been translated into this datatype. Ask includes every mediated effect
-- that can influence the result, not just successful file reads.
inductive ReadProgram (Input Value Output : Type) where
  | done : Output → ReadProgram Input Value Output
  | ask : Input → (Value → ReadProgram Input Value Output) →
      ReadProgram Input Value Output

inductive ReadRun {Input Value Output : Type} (image : Input → Value) :
    ReadProgram Input Value Output → List Input → Output → Prop where
  | done (o) : ReadRun image (.done o) [] o
  | ask (i next rest o) : ReadRun image (next (image i)) rest o →
      ReadRun image (.ask i next) (i :: rest) o

-- Agreement on the OLD successful trace preserves the adaptive requests too.
-- This avoids assuming a static set of future reads is known in advance.
theorem adaptiveTraceReplay {Input Value Output : Type}
    {old fresh : Input → Value} {program : ReadProgram Input Value Output}
    {trace : List Input} {o : Output} (run : ReadRun old program trace o)
    (agreement : ∀ i ∈ trace, old i = fresh i) :
    ReadRun fresh program trace o := by
  induction run with
  | done o => exact .done o
  | ask i next rest o tail ih =>
    have first : old i = fresh i := agreement i (by simp)
    apply ReadRun.ask
    rw [← first]
    apply ih
    intro j hj
    exact agreement j (by simp [hj])

theorem adaptiveOutputUnique {Input Value Output : Type} {image : Input → Value}
    {program : ReadProgram Input Value Output} {trace other : List Input}
    {a b : Output} (left : ReadRun image program trace a)
    (right : ReadRun image program other b) : a = b := by
  induction left generalizing other b with
  | done o => cases right; rfl
  | ask i next rest o tail ih =>
    cases right with
    | ask _ _ _ _ run => exact ih run

theorem receiptBackedAdaptiveReuse {Input Value Output : Type}
    {old image current : Input → Value}
    {program : ReadProgram Input Value Output} {trace : List Input}
    {cached : Output} (origin : ReadRun old program trace cached)
    (traceValidated : ∀ i ∈ trace, old i = image i)
    (atCommit : ∀ i ∈ trace, image i = current i) :
    ReadRun current program trace cached := by
  apply adaptiveTraceReplay origin
  intro i hi
  exact (traceValidated i hi).trans (atCommit i hi)

-- Structural slice correspondence. Lists preserve the native template order;
-- this supplies graph facts only, not the integer calculate oracle's adequacy.
def selectedIndex (k : Nat) : Nat :=
  match k with
  | 0 => 31 | 1 => 1 | 2 => 65 | 3 => 35 | 4 => 68
  | 5 => 69 | 6 => 70 | 7 => 71 | 8 => 72 | _ => 73

def smallPredecessors (k : Nat) : List Nat :=
  match k with
  | 0 => [] | 1 => [] | 2 => [0] | 3 => [1] | 4 => [0,1]
  | 5 => [4] | 6 => [2,3,5] | 7 => [4] | 8 => [7] | _ => [6,8]

def fullPredecessors (n : Nat) : List Nat :=
  if n < 34 then [] else if n < 68 then [n-34]
  else if n = 68 then List.range 33 else if n = 69 then [68]
  else if n = 70 then (List.range 33).map (· + 34) ++ [69]
  else if n = 71 then [33,68] else if n = 72 then [71] else [67,70,72]

theorem selectedIndexInjective : ∀ a b : Fin 10,
    selectedIndex a.val = selectedIndex b.val → a = b := by decide

theorem selectedEdgesExact : ∀ a b : Fin 10,
    selectedIndex a.val ∈ fullPredecessors (selectedIndex b.val) ↔
    a.val ∈ smallPredecessors b.val := by decide

def PhaseRelated (full : Nat → Nat) (small : Fin 10 → Nat) : Prop :=
  ∀ k, small k = full (selectedIndex k.val)
def FullReady (full : Nat → Nat) (k : Fin 10) : Prop :=
  ∀ d ∈ fullPredecessors (selectedIndex k.val), full d = 2
def SmallReady (small : Fin 10 → Nat) (k : Fin 10) : Prop :=
  ∀ d : Fin 10, d.val ∈ smallPredecessors k.val → small d = 2
def BoundaryReady (full : Nat → Nat) (k : Fin 10) : Prop :=
  ∀ d ∈ fullPredecessors (selectedIndex k.val),
    (¬ ∃ j : Fin 10, selectedIndex j.val = d) → full d = 2

theorem fullReadyProjects {full : Nat → Nat} {small : Fin 10 → Nat}
    {k : Fin 10} (related : PhaseRelated full small) (ready : FullReady full k) :
    SmallReady small k := by
  intro d edge
  rw [related d]
  exact ready _ ((selectedEdgesExact d k).mpr edge)

theorem selectedAndBoundaryReady {full : Nat → Nat} {small : Fin 10 → Nat}
    {k : Fin 10} (related : PhaseRelated full small) (localReady : SmallReady small k)
    (boundary : BoundaryReady full k) : FullReady full k := by
  classical
  intro d edge
  by_cases h : ∃ j : Fin 10, selectedIndex j.val = d
  · obtain ⟨j,hj⟩ := h
    subst d
    rw [← related j]
    exact localReady j ((selectedEdgesExact j k).mp edge)
  · exact boundary d edge h

theorem fullBudgetBoundsSelected {full selected omitted limit : Nat}
    (decomposition : full = selected + omitted) (admitted : full ≤ limit) :
    selected ≤ limit := by omega

def FrozenBoundary {View : Type} (old fresh : Fin 10 → Nat → View) : Prop :=
  ∀ k d, d ∈ fullPredecessors (selectedIndex k.val) →
    (¬ ∃ j : Fin 10, selectedIndex j.val = d) → old k d = fresh k d

theorem changedBoundaryRejectsFrozen {View : Type}
    {old fresh : Fin 10 → Nat → View} {k : Fin 10} {d : Nat}
    (edge : d ∈ fullPredecessors (selectedIndex k.val))
    (outside : ¬ ∃ j : Fin 10, selectedIndex j.val = d)
    (changed : old k d ≠ fresh k d) : ¬ FrozenBoundary old fresh := by
  intro frozen
  exact changed (frozen k d edge outside)

-- A relational step-or-stutter premise, instead of assuming real output groups
-- have an already-known functional quotient into the ten-node integer oracle.
inductive FiniteSteps {State : Type} (step : State → State → Prop) :
    State → State → Prop where
  | refl (s) : FiniteSteps step s s
  | next {a b c} : FiniteSteps step a b → step b c → FiniteSteps step a c

theorem relationalTraceSafety {Concrete Abstract : Type}
    (concreteStep : Concrete → Concrete → Prop)
    (abstractStep : Abstract → Abstract → Prop)
    (related : Concrete → Abstract → Prop) (safe : Abstract → Prop)
    (simulation : ∀ c a c', related c a → concreteStep c c' →
      ∃ a', related c' a' ∧ (abstractStep a a' ∨ a = a'))
    (preserve : ∀ a a', safe a → abstractStep a a' → safe a')
    {c c' : Concrete} {a : Abstract} (initial : related c a) (initialSafe : safe a)
    (trace : FiniteSteps concreteStep c c') :
    ∃ a', related c' a' ∧ safe a' := by
  induction trace with
  | refl => exact ⟨a,initial,initialSafe⟩
  | next priorTrace hop ih =>
    obtain ⟨b,rb,sb⟩ := ih
    obtain ⟨b',rb',choice⟩ := simulation _ _ _ rb hop
    refine ⟨b',rb',?_⟩
    rcases choice with h | h
    · exact preserve _ _ sb h
    · rw [← h]; exact sb

end GambitBuild
