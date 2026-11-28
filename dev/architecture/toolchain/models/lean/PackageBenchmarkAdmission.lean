import Std
namespace Gambit.PackageBenchmarkAdmission
-- Total legacy configuration semantics over all natural budgets, not a temporal model.
def sourceBudget : Option Nat → Nat
 | none => 0
 | some n => n
def producerWorkers (budget : Option Nat) : Nat := max 1 (sourceBudget budget)
theorem missingBudgetIsSerial : producerWorkers none=1 := rfl
theorem explicitBudgetNormalization (n : Nat) : producerWorkers (some n)=max 1 n := rfl
theorem normalizedWorkersPositive (b : Option Nat) : 0 < producerWorkers b := by
 unfold producerWorkers
 exact Nat.lt_of_lt_of_le (by decide : 0 < 1) (Nat.le_max_left _ _)

-- Native strings and unbounded generations are related to symbolic model keys.
-- Injective interning is an explicit premise, not a digest collision proof.
structure ConcreteKey where
 repo : Nat
 generation : Nat
 source : String
 sdk : String
 graph : String
 profile : String
structure ModelKey where
 repo : Nat
 generation : Nat
 source : Nat
 sdk : Nat
 graph : Nat
 profile : Nat
def abstractKey (intern : String → Nat) (k : ConcreteKey) : ModelKey :=
 ⟨k.repo,k.generation,intern k.source,intern k.sdk,intern k.graph,intern k.profile⟩
theorem keyAbstractionPreservesGeneration (intern : String → Nat) (k : ConcreteKey) :
 (abstractKey intern k).generation=k.generation := rfl

theorem faithfulKeyReflection (intern : String → Nat)
 (faithful : ∀ a b, intern a=intern b → a=b) (a b : ConcreteKey)
 (h : abstractKey intern a=abstractKey intern b) :
 a.repo=b.repo ∧ a.generation=b.generation ∧ a.source=b.source ∧ a.sdk=b.sdk ∧ a.graph=b.graph ∧ a.profile=b.profile := by
 exact ⟨congrArg ModelKey.repo h,congrArg ModelKey.generation h,
   faithful _ _ (congrArg ModelKey.source h),faithful _ _ (congrArg ModelKey.sdk h),
   faithful _ _ (congrArg ModelKey.graph h),faithful _ _ (congrArg ModelKey.profile h)⟩

theorem differentGraphCannotAlias (intern : String → Nat)
 (faithful : ∀ a b, intern a=intern b → a=b) (a b : ConcreteKey)
 (different : a.graph≠b.graph) : abstractKey intern a≠abstractKey intern b := by
 intro h
 exact different (faithfulKeyReflection intern faithful a b h).2.2.2.2.1
end Gambit.PackageBenchmarkAdmission
