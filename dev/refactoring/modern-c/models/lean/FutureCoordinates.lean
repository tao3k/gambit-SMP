import Std
namespace FutureCoordinates
-- Word coordinates, not C pointer-provenance or generated-code equivalence.
def cut (top : Int) := 4*((top+6)/4+1)
def address (fp height slot : Int) := fp+height-slot
def adjusted (fp oldHeight newHeight : Int) := fp-(newHeight-oldHeight)
def frameSpace (fs : Int) := 4*((fs+6)/4)
theorem cutAligned (t : Int) : cut t % 4=0 := by unfold cut; omega
theorem cutGap (t : Int) : 4≤cut t-(t+3) ∧ cut t-(t+3)≤7 := by unfold cut; omega
theorem cutBounds (t : Int) (ht : 0≤t) : 3<cut t ∧ t≤cut t-3 := by
 have h:=cutGap t
 omega
theorem stackAdjustPreserves (fp h h' k : Int) : address (adjusted fp h h') h' k=address fp h k := by
 unfold address adjusted
 omega
theorem childRebase (base cut j : Int) : base-cut-j=base-(cut+j) := by omega
theorem childListIndex (n cut j : Int) : (n-cut)-j=n-(cut+j) := by omega
theorem parentListIndex (n cut k : Int) : (n-cut)+(cut-k)=n-k := by omega
theorem parentChildDisjoint (base cut k j : Int) (hk : 1≤k ∧ k≤cut) (hj : 1≤j) :
 base-k≠base-cut-j := by omega
theorem completePartition (n cut k : Int) (h : 0≤cut ∧ cut≤n) (hk : 1≤k ∧ k≤n) :
 (1≤k ∧ k≤cut) ∨ (1≤k-cut ∧ k-cut≤n-cut) := by omega
theorem normalSpace (s : Int) (aligned : s%4=0) : frameSpace (s-3)=s := by
 unfold frameSpace
 omega
theorem parentScannerAddress (fp s k : Int) (aligned : s%4=0) :
 fp+frameSpace (s-3)-k=address fp s k := by
 have hs:=normalSpace s aligned
 unfold address
 omega
def ordinaryIndex (fs link i : Nat) : Prop := i<fs ∧ i≠link
def ordinarySlot (fs link k : Nat) : Prop := 0<k ∧ k≤fs ∧ k≠link+1
theorem rootIndexSlot (fs link i : Nat) : ordinaryIndex fs link i ↔ ordinarySlot fs link (i+1) := by
 unfold ordinaryIndex ordinarySlot
 omega
theorem forwardRun (base first past slot : Int) (h : first≤slot ∧ slot<past) :
 0≤(past-1)-slot ∧ (past-1)-slot<past-first ∧
 (base-(past-1))+((past-1)-slot)=base-slot := by omega
def heapIndex (fs slot : Int) := 1+fs-slot
theorem heapInverse (fs slot : Int) : 1+fs-heapIndex fs slot=slot := by unfold heapIndex; omega
theorem heapBounds (fs slot : Int) (h : 1≤slot ∧ slot≤fs) : 1≤heapIndex fs slot ∧ heapIndex fs slot≤fs := by
 unfold heapIndex
 omega
def ordinaryRoots (fs map link : Nat) : List Nat :=
 (List.range fs).filterMap fun i => if map.testBit i && (i != link) then some (i+1) else none
theorem workedCut : cut 5=12 := by decide
theorem workedNormalFs : cut 5-3=9 := by decide
theorem workedRoots : ordinaryRoots 9 22 2=[2,5] := by decide
theorem workedAddresses : address 88 12 2=98 ∧ address 88 12 3=97 ∧ address 88 12 5=95 := by decide
end FutureCoordinates
