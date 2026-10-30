import FrameActivation
namespace FrameActivation
open FrameActivationAst

-- Update commutation is paired with guard preservation: completion is not
-- permission to change the parent's already reserved return route.
theorem completionCommitCommute (q : State) :
 doneSplitNext (commitNext q) = commitNext (doneSplitNext q) := by rfl

theorem completionCommitGuards (q : State) (c : commitGuard q) (d : doneSplitGuard q) :
 doneSplitGuard (commitNext q) ∧ commitGuard (doneSplitNext q) := by
 dsimp only [commitGuard] at c
 dsimp only [doneSplitGuard] at d
 dsimp only [doneSplitGuard,commitNext,commitGuard,doneSplitNext]
 omega

theorem commitRequiresRuntime (q : State) (g : commitGuard q) :
 q.n_gate=1 ∧ q.p_gcOpen=1 := by
 dsimp only [commitGuard] at g
 omega

theorem unknownRetryStutters (q : State) :
 native (publicationUnknownNext q)=native q ∧
 queue (publicationUnknownNext q)=queue q := by exact ⟨rfl,rfl⟩

theorem failedActivationStutters (q : State) :
 native (activationFailedNext q)=native q ∧
 queue (activationFailedNext q)=queue q := by exact ⟨rfl,rfl⟩

def retryWake : Nat → State → State
 | 0,q => q
 | k+1,q => wakeFailedNext (retryWake k q)

theorem wakeRetriesStutter (k : Nat) (q : State) :
 native (retryWake k q)=native q ∧ queue (retryWake k q)=queue q := by
 induction k with
 | zero => exact ⟨rfl,rfl⟩
 | succ k ih =>
   change native (retryWake k q)=native q ∧ queue (retryWake k q)=queue q
   exact ih

-- This is a safety consequence, not an eventual-delivery or memory bound.
theorem earlyResultRemainsRooted (q : State) (h : Safe q) (d : q.n_done=1) :
 q.n_resultRoot=1 ∧ q.p_resultRoot=1 := by
 have hn := ((safeEquivalent q).mp h).1
 have hc := ((safeEquivalent q).mp h).2.2
 have result : q.n_done=1 → q.n_resultRoot=1 := hn.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.2.1
 clear hn h
 unfold Aligned at hc
 omega
end FrameActivation
