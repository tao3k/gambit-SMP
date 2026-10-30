import FrameCursorRefinement
namespace Gambit.FrameCursorWords
open FrameCursorAst FrameCursorRefinement FrameCursorClosure FrameBitmapComposition
noncomputable section
attribute [local instance] Classical.propDecidable

def Width (w : Nat) : Prop := w=4 ∨ w=32 ∨ w=64
def window (b w k : Nat) : Nat := wordAt b w (k/w) / 2^(k%w)

theorem wordObservation (b w k : Nat) (positive : 0<w) :
 window b w k %2=1 ↔ (b/2^k)%2=1 := by
 have word:=wordBitCorrespondence b w k positive
 have query : (window b w k).testBit 0=b.testBit k := by
   simpa only [window,Nat.testBit_div_two_pow,Nat.zero_add] using word
 rw [Nat.mod_two_eq_one_iff_testBit_zero,Nat.mod_two_eq_one_iff_testBit_zero,query,Nat.testBit_div_two_pow,Nat.zero_add]

theorem boundaryCoordinates (w k : Nat) (width : Width w) (boundary : (k+1)%w=0) :
 (k+1)/w=k/w+1 := by
 rcases width with rfl | rfl | rfl <;> omega

theorem insideCoordinates (w k : Nat) (width : Width w) (inside : (k+1)%w≠0) :
 (k+1)/w=k/w ∧ (k+1)%w=k%w+1 := by
 rcases width with rfl | rfl | rfl <;> omega

theorem shiftWindow (b w k : Nat) (width : Width w) (inside : (k+1)%w≠0) :
 window b w (k+1)=window b w k/2 := by
 have coords:=insideCoordinates w k width inside
 simp only [window,coords.1,coords.2,Nat.pow_succ,Nat.div_div_eq_div_mul]

theorem refillWindow (b w k : Nat) (width : Width w) (boundary : (k+1)%w=0) :
 window b w (k+1)=wordAt b w (k/w+1) := by
 simp [window,boundary,boundaryCoordinates w k width boundary]

def WordShape (q : Scan) : Prop := ∃ b w k : Nat,
 Width w ∧ q.bitmap=(b : Int) ∧ q.scanWidth=(w : Int) ∧ q.slot=((k+1 : Nat) : Int) ∧
 q.next=((k/w : Nat) : Int) ∧ q.word=((window b w k : Nat) : Int)
def WordGood (q : Scan) : Prop := q.fs<q.slot ∨ WordShape q

theorem shapeDomain (q : Scan) (shape : WordShape q) : ProjectionDomain q := by
 obtain ⟨b,w,k,width,bitmap,scanWidth,slot,next,word⟩:=shape
 have pos : 0<w := by rcases width with rfl | rfl | rfl <;> omega
 unfold ProjectionDomain
 rw [bitmap,scanWidth,slot,next,word]
 exact ⟨Int.natCast_nonneg b,Int.natCast_nonneg (window b w k),Int.natCast_nonneg (k/w),by omega,by omega⟩

theorem observedWord (q : Scan) (good : WordGood q) : runWord q := by
 rcases good with outside | ⟨b,w,k,width,bitmap,scanWidth,slot,next,word⟩
 · exact Or.inl outside
 · apply Or.inr
   have pos : 0<w := by rcases width with rfl | rfl | rfl <;> omega
   have bits:=wordObservation b w k pos
   simp only [root]
   rw [bitmap,slot,word]
   have offset : (((k+1 : Nat) : Int)-1).toNat=k := by omega
   rw [offset]
   simpa only [←Int.natCast_pow,←Int.natCast_ediv,←Int.natCast_emod,Int.natCast_inj] using bits

theorem advanceWord (q : Scan) (good : WordGood q) : WordGood (advanceCursor q) := by
 by_cases outside : q.fs<(advanceCursor q).slot
 · exact Or.inl outside
 · have inNext : q.slot+1≤q.fs := by simpa [advanceCursor] using (show (advanceCursor q).slot≤q.fs by omega)
   rcases good with priorOutside | ⟨b,w,k,width,bitmap,scanWidth,slot,next,word⟩
   · omega
   · have pos : 0<w := by rcases width with rfl | rfl | rfl <;> omega
     have inOld : q.slot<q.fs := by omega
     apply Or.inr
     refine ⟨b,w,k+1,width,?_,?_,?_,?_,?_⟩
     · simp [advanceCursor,bitmap]
     · simp [advanceCursor,scanWidth]
     · simp [advanceCursor,slot]
     · by_cases boundary : (k+1)%w=0
       · have load : q.slot%q.scanWidth=0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_inj] using boundary
         simp [advanceCursor,inOld,load,next,boundaryCoordinates w k width boundary]
       · have noLoad : q.slot%q.scanWidth≠0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_inj] using boundary
         simp [advanceCursor,inOld,noLoad,next,(insideCoordinates w k width boundary).1]
     · by_cases boundary : (k+1)%w=0
       · have load : q.slot%q.scanWidth=0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_inj] using boundary
         simp only [advanceCursor,ite_eq_left (And.intro inOld load)]
         rw [bitmap,scanWidth,next,refillWindow b w k width boundary]
         simp only [←Int.natCast_add,←Int.natCast_mul,Int.toNat_natCast]
         rfl
       · have noLoad : q.slot%q.scanWidth≠0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_inj] using boundary
         simp only [advanceCursor,ite_eq_right (show ¬(q.slot<q.fs ∧ q.slot%q.scanWidth=0) by omega)]
         rw [word,shiftWindow b w k width boundary]
         rfl
end
end Gambit.FrameCursorWords
