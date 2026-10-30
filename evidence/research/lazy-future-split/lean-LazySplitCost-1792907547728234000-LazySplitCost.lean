import Std
import LazySplit
open LazySplitAst
namespace LazySplitCost
def allocated : List State → Int
 | [] => 0
 | q::qs => q.materialized+allocated qs
def successful : List State → Int
 | [] => 0
 | q::qs => q.split+successful qs
theorem aggregateBudget (qs : List State)
 (h : ∀ q ∈ qs, LazySplit.Reachable q) :
 0≤successful qs ∧ successful qs≤allocated qs ∧ allocated qs≤Int.ofNat qs.length := by
 induction qs with
 | nil => simp [allocated,successful]
 | cons q qs ih =>
   have hq := LazySplit.materializationCharge q (h q (by simp))
   have ht : ∀ x ∈ qs, LazySplit.Reachable x := by
    intro x hx
    exact h x (by simp [hx])
   have hb := ih ht
   simp only [allocated,successful,List.length_cons,Int.natCast_add,Int.natCast_one]
   omega
-- Uncommitted allocated count includes aborted OR unresolved materializations.
theorem uncommittedCharge (qs : List State) (h : ∀ q ∈ qs, LazySplit.Reachable q) :
 0≤allocated qs-successful qs ∧
 successful qs+(allocated qs-successful qs)=allocated qs := by
 have hb := aggregateBudget qs h
 omega
-- Count laws are conditional on the declared cost baseline and cohort.
def netWork (n s a alloc marker split abort probes : Int) : Int :=
 (n-s-a)*alloc-n*marker-s*split-a*abort-probes
theorem avoidedCount (n s a : Int) (hn : 0≤n) (hs : 0≤s) (ha : 0≤a) (h : s+a≤n) :
 0≤n-s-a ∧ (n-s-a)+(s+a)=n := by omega
theorem positiveIff (n s a alloc marker split abort probes : Int) :
 0<netWork n s a alloc marker split abort probes ↔
 n*marker+s*split+a*abort+probes < (n-s-a)*alloc := by
 unfold netWork
 omega
theorem freshBeforeSpawn (id : Nat) : id+1≠id := by omega
end LazySplitCost
