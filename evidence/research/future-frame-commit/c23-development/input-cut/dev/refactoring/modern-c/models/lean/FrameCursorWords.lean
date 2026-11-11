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

theorem castModOne (a : Nat) : (a : Int)%2=1 ↔ a%2=1 := by omega

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
   change ((window b w k : Nat) : Int)%2=1 ↔ ((b/2^k : Nat) : Int)%2=1
   rw [castModOne,castModOne]
   exact bits

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
       · have load : q.slot%q.scanWidth=0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_eq_zero,Int.natCast_ne_zero] using boundary
         simp [advanceCursor,inOld,load,next,boundaryCoordinates w k width boundary]
       · have noLoad : q.slot%q.scanWidth≠0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_eq_zero,Int.natCast_ne_zero] using boundary
         simp [advanceCursor,inOld,noLoad,next,(insideCoordinates w k width boundary).1]
     · by_cases boundary : (k+1)%w=0
       · have load : q.slot%q.scanWidth=0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_eq_zero,Int.natCast_ne_zero] using boundary
         simp only [advanceCursor,ite_eq_left (And.intro inOld load)]
         rw [bitmap,scanWidth,next,refillWindow b w k width boundary]
         simp only [←Int.natCast_add,←Int.natCast_mul,Int.toNat_natCast]
         rfl
       · have noLoad : q.slot%q.scanWidth≠0 := by simpa only [slot,scanWidth,←Int.natCast_emod,Int.natCast_eq_zero,Int.natCast_ne_zero] using boundary
         simp only [advanceCursor,ite_eq_right (show ¬(q.slot<q.fs ∧ q.slot%q.scanWidth=0) by omega)]
         rw [word,shiftWindow b w k width boundary]
         rfl
theorem wordStep (q : Scan) (good : WordGood q) : WordGood (runNext q) := by
 unfold runNext
 split
 · split
   · simpa only [WordGood,WordShape] using good
   · split
     · simpa only [WordGood,WordShape] using good
     · exact advanceWord q good
 · split
   · dsimp
     split
     · exact advanceWord q good
     · simpa only [WordGood,WordShape] using advanceWord q good
   · split <;> simpa only [WordGood,WordShape] using good

theorem advanceDomain (q : Scan) (domain : ProjectionDomain q) : ProjectionDomain (advanceCursor q) := by
 have power : 0<(2 : Int)^q.scanWidth.toNat := Int.pow_pos (by decide)
 have nonnegativeMod : 0≤q.bitmap / 2^((q.next+1)*q.scanWidth).toNat % 2^q.scanWidth.toNat := Int.emod_nonneg _ (by omega)
 have nonnegativeDiv : 0≤q.word/2 := Int.ediv_nonneg domain.2.1 (by decide)
 unfold ProjectionDomain advanceCursor
 dsimp
 refine ⟨domain.1,?_,?_,domain.2.2.2.1,?_⟩
 · split <;> assumption
 · split <;> have := domain.2.2.1 <;> omega
 · have := domain.2.2.2.2;omega

theorem domainStep (q : Scan) (domain : ProjectionDomain q) : ProjectionDomain (runNext q) := by
 unfold runNext
 split
 · split
   · simpa only [ProjectionDomain] using domain
   · split
     · simpa only [ProjectionDomain] using domain
     · exact advanceDomain q domain
 · split
   · dsimp
     split
     · exact advanceDomain q domain
     · simpa only [ProjectionDomain] using advanceDomain q domain
   · split <;> simpa only [ProjectionDomain] using domain

structure Qualified (fs : Nat) (q : Scan) : Prop where
 size : q.fs=(fs : Int)
 modes : 0≤q.mode ∧ q.mode≤3
 domain : ProjectionDomain q
 word : WordGood q
 safe : Safe fs (rootFn q) (encode q)

theorem qualifiedNext (fs : Nat) (q : Scan) (inv : Qualified fs q) : Qualified fs (runNext q) := by
 have identity:=stepIdentity q inv.modes
 refine ⟨identity.1.trans inv.size,⟨identity.2.2.2.1,identity.2.2.2.2⟩,domainStep q inv.domain,wordStep q inv.word,?_⟩
 rw [stepRootIdentity q inv.modes]
 rcases actualStepSimulation q fs inv.size inv.domain inv.modes inv.safe (observedWord q inv.word) (observedWord _ (advanceWord q inv.word)) with move | done
 · exact preserves fs (rootFn q) _ _ inv.safe move
 · rw [done.2];exact inv.safe

def entry (fs b excluded w : Nat) : Scan := startRun (fs : Int) (b : Int) (excluded : Int) (w : Int)

theorem entryShape (fs b excluded w : Nat) (width : Width w) : WordShape (entry fs b excluded w) := by
 refine ⟨b,w,0,width,?_,?_,?_,?_,?_⟩ <;> simp [entry,startRun,start,window,wordAt]

theorem entryProjection (fs b excluded w : Nat) : encode (entry fs b excluded w)=initial := by
 simp [encode,entry,startRun,start,initial]
 funext i
 exact decide_false _

theorem entryQualified (fs b excluded w : Nat) (width : Width w) : Qualified fs (entry fs b excluded w) := by
 refine ⟨rfl,by simp [entry,startRun,start],shapeDomain _ (entryShape fs b excluded w width),Or.inr (entryShape fs b excluded w width),?_⟩
 rw [entryProjection]
 exact initialSafe fs (rootFn (entry fs b excluded w))

def execute : Nat → Scan → Scan
 | 0,q => q
 | fuel+1,q => execute fuel (runNext q)

theorem executionQualified (fs : Nat) (q : Scan) (inv : Qualified fs q) (fuel : Nat) : Qualified fs (execute fuel q) := by
 induction fuel generalizing q with
 | zero => exact inv
 | succ fuel ih => exact ih _ (qualifiedNext fs q inv)

theorem executionRootStable (fs : Nat) (q : Scan) (inv : Qualified fs q) (fuel : Nat) : rootFn (execute fuel q)=rootFn q := by
 induction fuel generalizing q with
 | zero => rfl
 | succ fuel ih => exact (ih _ (qualifiedNext fs q inv)).trans (stepRootIdentity q inv.modes)

theorem sourceTermination (fs : Nat) (q : Scan) (inv : Qualified fs q) :
 ∃ fuel, fuel≤rank fs (encode q) ∧ (encode (execute fuel q)).mode=.done := by
 have close : ∀ n, ∀ q : Scan, rank fs (encode q)=n → Qualified fs q →
   ∃ fuel, fuel≤rank fs (encode q) ∧ (encode (execute fuel q)).mode=.done := by
   intro n
   induction n using Nat.strongRecOn with
   | ind n ih =>
     intro q eq inv
     by_cases done : (encode q).mode=.done
     · exact ⟨0,by omega,done⟩
     · have sim:=actualStepSimulation q fs inv.size inv.domain inv.modes inv.safe (observedWord q inv.word) (observedWord _ (advanceWord q inv.word))
       have step : Move fs (rootFn q) (encode q) (encode (runNext q)) := sim.resolve_right (by intro h;exact done h.1)
       have lower:=rankDecreases fs (rootFn q) _ _ inv.safe step
       obtain ⟨fuel,bound,ended⟩:=ih (rank fs (encode (runNext q))) (by omega) (runNext q) rfl (qualifiedNext fs q inv)
       exact ⟨fuel+1,by omega,ended⟩
 exact close (rank fs (encode q)) q rfl inv

theorem sourceTotalCorrect (fs b excluded w : Nat) (width : Width w) :
 ∃ fuel, fuel≤3*fs+2 ∧ (encode (execute fuel (entry fs b excluded w))).mode=.done ∧
   (∀ i : Nat, (execute fuel (entry fs b excluded w)).delivered (i : Int) ↔
      0<i ∧ i≤fs ∧ eligible (entry fs b excluded w) (i : Int)) := by
 have inv:=entryQualified fs b excluded w width
 obtain ⟨fuel,bound,done⟩:=sourceTermination fs _ inv
 have budget : fuel≤3*fs+2 := by simpa [entryProjection,rank,initial] using bound
 have finalInv:=executionQualified fs _ inv fuel
 have finalSafe:=finalInv.safe
 simp only [Safe,done] at finalSafe
 have pref : FrameRoots.Prefix (rootFn (execute fuel (entry fs b excluded w))) (encode (execute fuel (entry fs b excluded w))).delivered (fs+1) := by
   simpa only [finalSafe.2.2.1] using finalSafe.2.2.2
 have exactRoots:=FrameRoots.complete _ _ fs pref
 rw [executionRootStable fs _ inv fuel] at exactRoots
 refine ⟨fuel,budget,done,?_⟩
 intro i
 simpa only [encode,rootFn,decide_eq_true_eq] using exactRoots i
def Positive (q : Scan) : Prop := ∀ i : Int, q.delivered i → 0<i

theorem positiveStep (fs : Nat) (q : Scan) (inv : Qualified fs q) (positive : Positive q) : Positive (runNext q) := by
 by_cases pending : q.mode=2
 · have m0 : q.mode≠0 := by omega
   have m1 : q.mode≠1 := by omega
   have safe:=inv.safe
   simp only [Safe,encode,ite_eq_right m0,ite_eq_right m1,ite_eq_left pending] at safe
   have first : 0<q.first := by have := safe.2.2.1;omega
   have output : (runNext q).delivered=fun i => q.delivered i ∨ (q.first≤i ∧ i≤q.past-1) := by
     simp only [runNext,ite_eq_right m0,ite_eq_right m1,ite_eq_left pending]
   intro i delivered
   rw [output] at delivered
   rcases delivered with old | range
   · exact positive i old
   · omega
 · have output : (runNext q).delivered=q.delivered := by
     unfold runNext
     split
     · split
       · rfl
       · split <;> rfl
     · split
       · dsimp;split <;> rfl
       · simp only [ite_eq_right pending]
   intro i delivered
   rw [output] at delivered
   exact positive i delivered

theorem entryPositive (fs b excluded w : Nat) : Positive (entry fs b excluded w) := by
 intro i impossible
 exact False.elim impossible

theorem executionPositive (fs : Nat) (q : Scan) (inv : Qualified fs q) (positive : Positive q) (fuel : Nat) : Positive (execute fuel q) := by
 induction fuel generalizing q with
 | zero => exact positive
 | succ fuel ih => exact ih _ (qualifiedNext fs q inv) (positiveStep fs q inv positive)

theorem sourceTotalCorrectAll (fs b excluded w : Nat) (width : Width w) :
 ∃ fuel, fuel≤3*fs+2 ∧ (encode (execute fuel (entry fs b excluded w))).mode=.done ∧
   (∀ i : Int, (execute fuel (entry fs b excluded w)).delivered i ↔
      0<i ∧ i≤(fs : Int) ∧ eligible (entry fs b excluded w) i) := by
 obtain ⟨fuel,budget,done,roots⟩:=sourceTotalCorrect fs b excluded w width
 have positive:=executionPositive fs _ (entryQualified fs b excluded w width) (entryPositive fs b excluded w) fuel
 refine ⟨fuel,budget,done,?_⟩
 intro i
 by_cases nonnegative : 0≤i
 · have canonical : (i.toNat : Int)=i := Int.toNat_of_nonneg nonnegative
   have root:=roots i.toNat
   rw [canonical] at root
   constructor
   · intro delivered;have h:=root.mp delivered;exact ⟨by omega,by omega,h.2.2⟩
   · intro h;exact root.mpr ⟨by omega,by omega,h.2.2⟩
 · constructor
   · intro delivered;have := positive i delivered;omega
   · intro h;omega
end
end Gambit.FrameCursorWords
