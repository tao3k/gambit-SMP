import FrameRoots
import FrameContract
import FutureCoordinates
namespace Gambit.FrameBitmapComposition
-- Mathematical source correspondence; not a native shift/pointer or full cursor simulation proof.
def wordAt (bitmap width block : Nat) : Nat := (bitmap / 2^(block*width)) % 2^width

theorem wordBitCorrespondence (bitmap width index : Nat) (hw : 0<width) :
 (wordAt bitmap width (index/width)).testBit (index%width) = bitmap.testBit index := by
 have localBound := Nat.mod_lt index hw
 have position : index%width + (index/width)*width = index := by
  simpa [Nat.mul_comm] using Nat.mod_add_div index width
 simp [wordAt,Nat.testBit_mod_two_pow,Nat.testBit_div_two_pow,localBound,position]

theorem oneBasedSlotCorrespondence (bitmap width slot : Nat) (hw : 0<width) (_hs : 0<slot) :
 (wordAt bitmap width ((slot-1)/width)).testBit ((slot-1)%width) = bitmap.testBit (slot-1) :=
 wordBitCorrespondence bitmap width (slot-1) hw

-- Two 32-bit emitter chunks packed as unsigned low + high*2^32.
theorem pair32Packing (x : Nat) :
 x % 4294967296 + 4294967296*((x/4294967296)%4294967296) = x % 18446744073709551616 := by
 omega

def ordinaryLive (bitmap link slot : Nat) : Bool := bitmap.testBit (slot-1) && decide (slot≠link+1)

theorem ordinaryAndControlPartition (bitmap link slot : Nat)
 (live : bitmap.testBit (slot-1)=true) : ordinaryLive bitmap link slot=true ∨ slot=link+1 := by
 by_cases h : slot=link+1
 · exact Or.inr h
 · exact Or.inl (by simp [ordinaryLive,live,h])

theorem completeOrdinaryVisits (bitmap link fs : Nat) (seen : Nat → Bool)
 (history : FrameRoots.Prefix (ordinaryLive bitmap link) seen (fs+1)) :
 ∀ slot, seen slot=true ↔ 0<slot ∧ slot≤fs ∧ ordinaryLive bitmap link slot=true :=
 FrameRoots.complete (ordinaryLive bitmap link) seen fs history

theorem physicalRunCoverage (base first past slot : Int) (inside : first≤slot ∧ slot<past) :
 0≤(past-1)-slot ∧ (past-1)-slot<past-first ∧
 (base-(past-1))+((past-1)-slot)=base-slot :=
 FutureCoordinates.forwardRun base first past slot inside

def internalFs (stored : Nat) : Nat := ((stored+3)/4)*4+9

theorem retiFiveRegisterFormula (stored : Nat) :
 ((stored+3)/4)*4+((6+3+3)/4)*4-3 = internalFs stored := by
 unfold internalFs
 omega

theorem inlineBoundary : 20<32 ∧ 1048575<1048576 := by decide

theorem width32Boundary : (wordAt (2^31+2^32+2^63+2^64) 32 0).testBit 31=true ∧
 (wordAt (2^31+2^32+2^63+2^64) 32 1).testBit 0=true ∧
 (wordAt (2^31+2^32+2^63+2^64) 32 2).testBit 0=true := by decide

theorem width64Boundary : (wordAt (2^31+2^32+2^63+2^64) 64 0).testBit 63=true ∧
 (wordAt (2^31+2^32+2^63+2^64) 64 1).testBit 0=true := by decide

-- Grouping semantics for the two loops in ordinary next_run. Bitmap-word
-- correspondence and native cursor progress remain separate refinement legs.
def splitFlag (flag : Bool) : List Bool → List Bool × List Bool
 | [] => ([],[])
 | x::xs => if x=flag then (x::(splitFlag flag xs).1,(splitFlag flag xs).2) else ([],x::xs)

theorem splitReconstruct (flag : Bool) (xs : List Bool) :
 (splitFlag flag xs).1 ++ (splitFlag flag xs).2 = xs := by
 induction xs with
 | nil => rfl
 | cons x xs ih =>
   by_cases h : x=flag
   · simp_all [splitFlag]
   · simp [splitFlag,h]

theorem splitPrefixHasOneRole (flag : Bool) (xs : List Bool) :
 ∀ x ∈ (splitFlag flag xs).1, x=flag := by
 induction xs with
 | nil => simp [splitFlag]
 | cons x xs ih =>
   by_cases h : x=flag
   · intro y hy
     simp only [splitFlag,if_pos h,List.mem_cons] at hy
     rcases hy with head | tail
     · exact head.trans h
     · exact ih y tail
   · simp [splitFlag,h]

theorem skippedPrefixHasNoRoots (xs : List Bool) :
 ((splitFlag false xs).1).count true=0 := by
 induction xs with
 | nil => rfl
 | cons x xs ih => cases x <;> simp_all [splitFlag]

theorem runPrefixAllLive (xs : List Bool) :
 ((splitFlag true xs).1).count true=((splitFlag true xs).1).length := by
 induction xs with
 | nil => rfl
 | cons x xs ih => cases x <;> simp_all [splitFlag]

def skipped (xs : List Bool) := (splitFlag false xs).1
def afterSkip (xs : List Bool) := (splitFlag false xs).2
def rootRun (xs : List Bool) := (splitFlag true (afterSkip xs)).1
def runRest (xs : List Bool) := (splitFlag true (afterSkip xs)).2

theorem nextRunReconstructsInput (xs : List Bool) :
 skipped xs ++ (rootRun xs ++ runRest xs) = xs := by
 unfold skipped rootRun runRest afterSkip
 rw [splitReconstruct,splitReconstruct]

theorem nextRunConservesLiveSlots (xs : List Bool) :
 xs.count true = (rootRun xs).length + (runRest xs).count true := by
 have h := congrArg (fun ys : List Bool => ys.count true) (nextRunReconstructsInput xs)
 have hd : (skipped xs).count true=0 := skippedPrefixHasNoRoots xs
 have ha : (rootRun xs).count true=(rootRun xs).length := runPrefixAllLive (afterSkip xs)
 simp only [List.count_append] at h
 omega

theorem nonemptyRunMakesProgress (xs : List Bool) (nonempty : rootRun xs ≠ []) :
 (runRest xs).length < xs.length := by
 have h := congrArg List.length (nextRunReconstructsInput xs)
 have positive : 0 < (rootRun xs).length := by
  cases hrun : rootRun xs with
  | nil => exact False.elim (nonempty hrun)
  | cons x tail => simp [hrun]
 simp only [List.length_append] at h
 omega
end Gambit.FrameBitmapComposition
