import Std
namespace StorageIndexAlgebra
structure Span where
 lo : Int
 hi : Int
 deriving DecidableEq
def Disjoint (a b : Span) : Prop := a.hi ≤ b.lo ∨ b.hi ≤ a.lo
def Separated (xs : List Span) : Prop := xs.Pairwise Disjoint
def Compatible (r : Span) (xs : List Span) : Prop := ∀ x ∈ xs, Disjoint r x
theorem checkedInsert (r : Span) (xs : List Span) (h : Separated xs) (g : Compatible r xs) : Separated (r :: xs) := by
 exact List.pairwise_cons.mpr ⟨g,h⟩
theorem overlapRejects (r x : Span) (xs : List Span) (m : x ∈ xs) (a : x.lo < r.hi) (b : r.lo < x.hi) : ¬ Compatible r xs := by
 intro g
 have d := g x m
 simp only [Disjoint] at d
 omega
theorem intervalAdjacency (a b : Span) (h : a.hi = b.lo) : Disjoint a b := by
 left; omega
structure LeaseKey where
 storage : Nat
 generation : Nat
 operation : Nat
 lease : Nat
 deriving DecidableEq
theorem differentGenerationDifferentLease (a b : LeaseKey) (h : a.generation ≠ b.generation) : a ≠ b := by
 intro e; exact h (congrArg LeaseKey.generation e)
theorem differentOperationDifferentLease (a b : LeaseKey) (h : a.operation ≠ b.operation) : a ≠ b := by
 intro e; exact h (congrArg LeaseKey.operation e)
theorem settlementCannotConsumeNew (old current : LeaseKey) (h : old ≠ current) : ¬ old = current := h
end StorageIndexAlgebra
