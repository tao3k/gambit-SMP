import Std.Tactic
namespace GambitSMP.PromotionIntervalHandoff
structure Extent where
  lo : Nat
  hi : Nat
def Valid (e : Extent) (cap : Nat) := e.lo ≤ e.hi ∧ e.hi ≤ cap
def SplitAt (e : Extent) (p : Nat) := e.lo ≤ p ∧ p ≤ e.hi
theorem splitConserves (e : Extent) (p : Nat) (h : SplitAt e p) :
    (p-e.lo)+(e.hi-p)=e.hi-e.lo := by simp_all [SplitAt]; omega
theorem noCrossBoundary (base limit n cap : Nat) (h : base ≤ limit) (endBound : limit ≤ cap)
    (fits : n ≤ limit-base) : base+n ≤ cap := by omega
theorem sumDoesNotFitFragment : 4+4 ≥ (6:Nat) ∧ ¬(6 ≤ (4:Nat)) := by omega
structure Ownership where
  worker : Bool
  context : Bool
def Exclusive (s : Ownership) := ¬(s.worker=true ∧ s.context=true)
def commit (_s : Ownership) : Ownership := ⟨false,true⟩
theorem commitExclusive (s : Ownership) : Exclusive (commit s) := by simp [Exclusive,commit]
theorem ackDoesNotRestoreWorker (s : Ownership) : (commit s).worker=false := rfl
structure Readers (Id : Type) where
  pins : Id → Prop
  queued : Id → Prop
  running : Id → Prop
def Covered {Id} (s : Readers Id) := ∀ i, s.queued i ∨ s.running i → s.pins i
def dequeue {Id} [DecidableEq Id] (s : Readers Id) (i : Id) : Readers Id :=
  { s with queued := fun j => j≠i ∧ s.queued j, running := fun j => j=i ∨ s.running j }
theorem dequeuePreservesPin {Id} [DecidableEq Id] (s : Readers Id) (i : Id)
    (h : Covered s) (q : s.queued i) : Covered (dequeue s i) := by
  intro j hj
  rcases hj with queued | run
  · exact h j (Or.inl queued.2)
  · rcases run with eq | old
    · subst j; exact h i (Or.inl q)
    · exact h j (Or.inr old)
theorem noReadersNoTasks {Id} (s : Readers Id) (h : Covered s) (none : ∀ i, ¬s.pins i) :
    ∀ i, ¬(s.queued i ∨ s.running i) := by
  intro i task; exact none i (h i task)
theorem handoffNoZeroGap (old children : Nat) (oldPositive : 0<old) :
    0 < old+children := by omega
-- Retirement is permission to reclaim metadata only after readers close.
-- Payload death and interval ownership are independent required predicates.
theorem liveOwnerForbidsFree (contextOwns dead allowed : Prop)
    (freeLaw : allowed → dead ∧ ¬contextOwns) (owner : contextOwns) : ¬allowed := by
  intro ha; exact (freeLaw ha).2 owner
theorem reuseBound (tail resume reused : Nat) (a : reused ≤ tail) (b : reused ≤ resume) :
    reused ≤ min tail resume := Nat.le_min.mpr ⟨a,b⟩
theorem peakReuse (base fresh metadata reused : Nat) (h : reused ≤ fresh) :
    base+(fresh-reused)+metadata+reused = base+fresh+metadata := by omega
theorem lateRefundCannotBeatPre (pre post refund : Nat) : pre ≤ max pre (post-refund) :=
  Nat.le_max_left _ _
theorem peakBelowRequiresBoth (pre post cap : Nat) (h : max pre post < cap) :
    pre < cap ∧ post < cap := by omega
end GambitSMP.PromotionIntervalHandoff
