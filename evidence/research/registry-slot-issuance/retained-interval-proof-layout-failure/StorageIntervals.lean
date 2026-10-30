import SlotCensus
namespace StorageIntervals
structure Span where
 lo : Int
 hi : Int
 deriving DecidableEq
def Valid (a : Span) : Prop := a.lo < a.hi
def Disjoint (a b : Span) : Prop := a.hi ≤ b.lo ∨ b.hi ≤ a.lo
def Inside (a b : Span) : Prop := b.lo ≤ a.lo ∧ a.hi ≤ b.hi
theorem adjacencyDisjoint (a b : Span) (h : a.hi = b.lo) : Disjoint a b := by
 unfold Disjoint; omega
theorem overlapCannotMintFresh (a b : Span) (h0 : a.lo < b.hi) (h1 : b.lo < a.hi) : ¬ Disjoint a b := by
 unfold Disjoint; omega
theorem subviewOffsetInside (parent child : Span) (p : Valid parent) (c : Valid child) (h : Inside child parent) : 0 ≤ child.lo-parent.lo ∧ child.hi-parent.lo ≤ parent.hi-parent.lo := by
 simp_all [Valid,Inside]; omega
theorem exactUnownedRangeOverlaps (a : Span) (h : Valid a) : ¬ Disjoint a a := by
 simp_all [Disjoint,Valid]
theorem pointInBothContradictsDisjoint (a b : Span) (x : Int) (h : Disjoint a b)
 (a0 : a.lo ≤ x) (a1 : x < a.hi) (b0 : b.lo ≤ x) (b1 : x < b.hi) : False := by
 unfold Disjoint at h; omega
theorem generationSeparatesKey (k : SlotCensus.SlotKey) (g : Nat) (h : g ≠ k.generation) : {k with generation := g} ≠ k := by
 intro eq
 have same := congrArg SlotCensus.SlotKey.generation eq
 simp only at same
 exact h same
end StorageIntervals
