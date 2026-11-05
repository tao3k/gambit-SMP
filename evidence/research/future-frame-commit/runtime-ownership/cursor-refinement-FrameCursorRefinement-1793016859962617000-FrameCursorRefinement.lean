import FrameCursorAst
import FrameCursorClosure
namespace Gambit.FrameCursorRefinement
open FrameCursorAst FrameCursorClosure
noncomputable section
attribute [local instance] Classical.propDecidable

def rootFn (q : Scan) (i : Nat) : Bool := decide (eligible q (i : Int))
def encode (q : Scan) : State :=
 {mode:=if q.mode=0 then .skip else if q.mode=1 then .run else if q.mode=2 then .pending else .done,
  pos:=q.slot.toNat,first:=q.first.toNat,past:=q.past.toNat,
  delivered:=fun i => decide (q.delivered (i : Int))}

theorem advanceProjection (q : Scan) (positive : 0≤q.slot) :
 encode (advanceCursor q) = {encode q with pos:=(encode q).pos+1} := by
 simp [encode,advanceCursor]
 exact ⟨rfl,by omega,rfl⟩

theorem advancePreservesRoot (q : Scan) : rootFn (advanceCursor q)=rootFn q := by
 rfl

theorem observedGuard (q : Scan) (positive : 0≤q.slot) (word : runWord q)
 (inside : q.slot≤q.fs) :
 rootFn q q.slot.toNat=true ↔ q.word%2=1 ∧ q.slot≠q.excluded := by
 have bits : q.word%2=1 ↔ root q.bitmap q.slot := word.resolve_left (by omega)
 simp only [rootFn,decide_eq_true_eq,Int.toNat_of_nonneg positive,eligible]
 exact and_congr bits.symm Iff.rfl

theorem prefixReflection (q : Scan) (bound : Int)
 (view : q.delivered=fun i => (1≤i ∧ i≤bound-1) ∧ eligible q i) :
 FrameRoots.Prefix (rootFn q) (encode q).delivered bound.toNat := by
 intro i
 simp only [encode,rootFn,decide_eq_true_eq]
 rw [view]
 constructor
 · intro h;exact ⟨by omega,by omega,h.2⟩
 · intro h;exact ⟨⟨by omega,by omega⟩,h.2.2⟩

theorem coverageReflects (q : Scan) (fs : Nat) (size : q.fs=(fs : Int))
 (coverage : runCoverage q) (current : runCurrent q) :
 Safe fs (rootFn q) (encode q) := by
 unfold runCoverage at coverage
 rcases coverage with ⟨lo,hi,next0,nextBound,width,before,segment,pending,done,noControl⟩
 unfold runCurrent at current
 rcases current with ⟨modeLo,modeHi,current,ended⟩
 have positive : 0≤q.slot := by omega
 have low : 0<q.slot.toNat := by omega
 have high : q.slot.toNat≤fs+1 := by omega
 by_cases m0 : q.mode=0
 · have pref := prefixReflection q q.slot (by simpa [m0] using before)
   simpa [Safe,encode,m0] using And.intro low (And.intro high pref)
 · by_cases m1 : q.mode=1
   · have first := (segment (Or.inl m1)).1
     have ordered := (segment (Or.inl m1)).2.1
     have pref := prefixReflection q q.first (by simpa [m1] using before)
     have inside := (current m1).1
     have live : ∀ i : Nat, q.first.toNat≤i → i≤q.slot.toNat → rootFn q i=true := by
       intro i hf hp
       simp only [rootFn,decide_eq_true_eq]
       by_cases last : (i : Int)=q.slot
       · simpa [last] using (current m1).2
       · exact (segment (Or.inl m1)).2.2 (i : Int) (by omega)
     simp only [Safe,encode,ite_eq_right m0,ite_eq_left m1]
     exact ⟨low,high,by omega,by omega,by omega,pref,live⟩
   · by_cases m2 : q.mode=2
     · have first := (segment (Or.inr m2)).1
       have ordered := (segment (Or.inr m2)).2.1
       have facts := pending m2
       have pref := prefixReflection q q.first (by simpa [m2] using before)
       have live : ∀ i : Nat, q.first.toNat≤i → i<q.slot.toNat → rootFn q i=true := by
         intro i hf hp
         simp only [rootFn,decide_eq_true_eq]
         exact (segment (Or.inr m2)).2.2 (i : Int) (by omega)
       have stop : fs<q.slot.toNat ∨ rootFn q q.slot.toNat=false := by
         rcases facts.2.2 with out | dead
         · exact Or.inl (by omega)
         · exact Or.inr (by simp [rootFn,Int.toNat_of_nonneg positive,dead])
       have bounds : 0<q.first.toNat ∧ q.first.toNat<q.slot.toNat ∧ q.past.toNat=q.slot.toNat := by omega
       simp only [Safe,encode,ite_eq_right m0,ite_eq_right m1,ite_eq_left m2]
       exact ⟨low,high,bounds.1,bounds.2.1,bounds.2.2,pref,live,stop⟩
     · have m3 : q.mode=3 := by omega
       have eq : q.slot.toNat=fs+1 := by have := ended m3;omega
       have pref := prefixReflection q q.slot (by simpa [m3,ended m3] using before)
       simpa [Safe,encode,m0,m1,m2] using And.intro low (And.intro high ⟨eq,pref⟩)

-- This statement exposes the exact word-guard fidelity premises. It does not
-- assume the step refines Move; the actual extracted six branches are checked.
theorem actualStepSimulation (q : Scan) (fs : Nat)
 (size : q.fs=(fs : Int)) (mode : 0≤q.mode ∧ q.mode≤3)
 (safe : Safe fs (rootFn q) (encode q)) (word : runWord q)
 (nextWord : runWord (advanceCursor q)) :
 Move fs (rootFn q) (encode q) (encode (runNext q)) ∨
   ((encode q).mode=.done ∧ encode (runNext q)=encode q) := by
 have positive : 0≤q.slot := by have := safe.1; simp only [encode] at this; omega
 have sourcePos : (q.slot.toNat : Int)=q.slot := Int.toNat_of_nonneg positive
 have advancePos := advanceProjection q positive
 have rootStable := advancePreservesRoot q
 by_cases m0 : q.mode=0
 · by_cases outside : q.fs<q.slot
   · have output : encode (runNext q)={encode q with mode:=.done} := by simp [runNext,m0,outside,encode]
     rw [output];exact Or.inl (Move.endFrame _ (by simp [encode,m0]) (by change fs<q.slot.toNat;omega))
   · have inFrame : q.slot≤q.fs := by omega
     have guard := observedGuard q positive word inFrame
     by_cases live : q.word%2=1 ∧ q.slot≠q.excluded
     · have output : encode (runNext q)={encode q with mode:=.run,first:=(encode q).pos} := by simp [runNext,m0,show ¬q.slot>q.fs by omega,live,encode]
       rw [output];exact Or.inl (Move.startRun _ (by simp [encode,m0]) (by change q.slot.toNat≤fs;omega) (guard.mpr live))
     · have output : encode (runNext q)={encode q with pos:=(encode q).pos+1} := by simpa [runNext,m0,show ¬q.slot>q.fs by omega,live] using advancePos
       rw [output]
       have dead : rootFn q (encode q).pos=false := by
         have no : rootFn q q.slot.toNat≠true := by intro yes; exact live (guard.mp yes)
         simpa [encode,Bool.not_eq_true] using no
       exact Or.inl (Move.skipDead _ (by simp [encode,m0]) (by change q.slot.toNat≤fs;omega) dead)
 · by_cases m1 : q.mode=1
   · let a:=advanceCursor q
     have apos : a.slot=q.slot+1 := by rfl
     have afs : a.fs=q.fs := by rfl
     have aexcluded : a.excluded=q.excluded := by rfl
     by_cases keep : a.slot≤a.fs ∧ a.word%2=1 ∧ a.slot≠a.excluded
     · have nextGuard := observedGuard a (by dsimp [a];simp [advanceCursor];omega) nextWord keep.1
       have rootLive : rootFn q ((encode q).pos+1)=true := by
         have live := nextGuard.mpr keep.2
         rw [rootStable] at live
         have idx : a.slot.toNat=(encode q).pos+1 := by change (q.slot+1).toNat=q.slot.toNat+1;omega
         simpa [idx] using live
       have actual : ((advanceCursor q).slot≤(advanceCursor q).fs ∧ (advanceCursor q).word%2=1) ∧ (advanceCursor q).slot≠(advanceCursor q).excluded := ⟨⟨keep.1,keep.2.1⟩,keep.2.2⟩
       have nextEq : runNext q=a := by
         simp only [runNext,ite_eq_right m0,ite_eq_left m1,ite_eq_left actual]
         rfl
       have output : encode (runNext q)={encode q with pos:=(encode q).pos+1} := by
         rw [nextEq];exact advancePos
       rw [output];exact Or.inl (Move.continueRun _ (by simp [encode,m0,m1]) (by simp only [encode];omega) rootLive)
     · have stop : fs<(encode q).pos+1 ∨ rootFn q ((encode q).pos+1)=false := by
         by_cases out : q.fs<q.slot+1
         · exact Or.inl (by simp only [encode];omega)
         · have inNext : a.slot≤a.fs := by omega
           have guard := observedGuard a (by rw [apos];omega) nextWord inNext
           have dead : rootFn a a.slot.toNat≠true := by intro yes;exact keep ⟨inNext,(guard.mp yes).1,(guard.mp yes).2⟩
           have idx : a.slot.toNat=(encode q).pos+1 := by change (q.slot+1).toNat=q.slot.toNat+1;omega
           rw [rootStable,idx] at dead
           exact Or.inr (by simpa only [Bool.not_eq_true] using dead)
       have notkeep : ¬(((advanceCursor q).slot≤(advanceCursor q).fs ∧ (advanceCursor q).word%2=1) ∧ (advanceCursor q).slot≠(advanceCursor q).excluded) := by simpa only [a,and_assoc] using keep
       have nextEq : runNext q={a with mode:=2,past:=a.slot} := by
         simp only [runNext,ite_eq_right m0,ite_eq_left m1,ite_eq_right notkeep]
         rfl
       have output : encode (runNext q)={encode q with mode:=.pending,pos:=(encode q).pos+1,past:=(encode q).pos+1} := by
         rw [nextEq];simp [encode,a,advanceCursor]
         all_goals first | rfl | omega
       rw [output];exact Or.inl (Move.returnRun _ (by simp [encode,m0,m1]) stop)
   · by_cases m2 : q.mode=2
     · have h:=safe
       simp only [Safe,encode,m0,m1,m2,if_false,if_true] at h
       have firstPos : 0≤q.first := by have := h.2.2.1;omega
       have pastPos : 0≤q.past := by have := h.2.2.2.2.1;omega
       have pastSlot : q.past=q.slot := by have := h.2.2.2.2.1;omega
       have membership (i : Nat) :
         decide (q.delivered (i : Int) ∨ (q.first≤(i : Int) ∧ (i : Int)≤q.past-1)) =
           (if q.first.toNat≤i ∧ i<q.slot.toNat then true else decide (q.delivered (i : Int))) := by
         by_cases inside : q.first.toNat≤i ∧ i<q.slot.toNat
         · have range : q.first≤(i : Int) ∧ (i : Int)≤q.past-1 := by omega
           simp only [ite_eq_left inside,decide_eq_true_eq]
           exact Or.inr range
         · have range : ¬(q.first≤(i : Int) ∧ (i : Int)≤q.past-1) := by omega
           simp only [ite_eq_right inside]
           apply decide_eq_decide.mpr
           constructor
           · intro h;rcases h with old | invalid
             · exact old
             · exact False.elim (range invalid)
           · exact Or.inl
       have output : encode (runNext q)={encode q with mode:=.skip,delivered:=deliver (encode q)} := by
         simp only [runNext,ite_eq_right m0,ite_eq_right m1,ite_eq_left m2,encode,deliver]
         congr 1
         funext i
         exact membership i
       rw [output];exact Or.inl (Move.deliverRun _ (by simp [encode,m0,m1,m2]))
     · have m3 : q.mode=3 := by omega
       exact Or.inr ⟨by simp [encode,m0,m1,m2],by simp [runNext,m0,m1,m2]⟩
theorem stepIdentity (q : Scan) (mode : 0≤q.mode ∧ q.mode≤3) :
 (runNext q).fs=q.fs ∧ (runNext q).bitmap=q.bitmap ∧
 (runNext q).excluded=q.excluded ∧ 0≤(runNext q).mode ∧ (runNext q).mode≤3 := by
 unfold runNext
 split
 · split
   · simp
   · split <;> simp [advanceCursor,mode.1,mode.2]
 · split
   · dsimp
     split <;> simp [advanceCursor,mode.1,mode.2]
   · split <;> simp [mode.1,mode.2]

theorem stepRootIdentity (q : Scan) (mode : 0≤q.mode ∧ q.mode≤3) :
 rootFn (runNext q)=rootFn q := by
 have facts:=stepIdentity q mode
 funext i
 unfold rootFn
 apply decide_eq_decide.mpr
 simp only [eligible,facts.2.1,facts.2.2.1]

theorem actualStepPreserves (q : Scan) (fs : Nat)
 (size : q.fs=(fs : Int)) (coverage : runCoverage q) (current : runCurrent q)
 (word : runWord q) (nextWord : runWord (advanceCursor q)) :
 Safe fs (rootFn (runNext q)) (encode (runNext q)) := by
 have safe:=coverageReflects q fs size coverage current
 have modes : 0≤q.mode ∧ q.mode≤3 := ⟨current.1,current.2.1⟩
 rw [stepRootIdentity q modes]
 rcases actualStepSimulation q fs size modes safe word nextWord with move | done
 · exact preserves fs (rootFn q) _ _ safe move
 · rw [done.2];exact safe
end
end Gambit.FrameCursorRefinement
