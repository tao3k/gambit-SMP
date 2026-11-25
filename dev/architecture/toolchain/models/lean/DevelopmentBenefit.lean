import IncrementalCompilerArchitecture

-- Conditional accounting, not timings or a C/native source-refinement proof.
namespace Gambit.DevelopmentBenefit

-- All arguments to a ledger use ONE metric/unit. CPU work, wall span, bytes
-- and authority counts are separate projections, never interchangeable terms.
theorem repeatedWorkBalance (n k cost overhead : Nat) (hk : k ≤ n) :
    (k*cost+overhead)+(n-k)*cost = n*cost+overhead := by
  have e : k+(n-k)=n := by omega
  have h := congrArg (fun x : Nat => x*cost) e
  simp only [Nat.add_mul] at h
  omega

theorem reuseThreshold (n k cost overhead : Nat) (hk : k ≤ n) :
    k*cost+overhead < n*cost ↔ overhead < (n-k)*cost := by
  have h := repeatedWorkBalance n k cost overhead hk
  omega

theorem noDuplicateNoGain (n cost overhead : Nat) :
    ¬ n*cost+overhead < n*cost := by omega

-- An independent two-branch region with enough resource capacity; shared
-- mandatory prefix stays in both arms. Other critical paths are not modeled.
theorem overlapThreshold (serial a b added : Nat) :
    serial+max a b+added < serial+a+b ↔ added < min a b := by
  by_cases h : a ≤ b
  · rw [Nat.max_eq_right h, Nat.min_eq_left h]; omega
  · have h' : b ≤ a := by omega
    rw [Nat.max_eq_left h', Nat.min_eq_right h']; omega

theorem nonRegressionThreshold (oldWork newWork removed added : Nat)
    (balance : newWork+removed=oldWork+added) :
    newWork ≤ oldWork ↔ added ≤ removed := by omega

theorem couplingThreshold (oldWork newWork removedA removedB overhead interaction : Nat)
    (disjointBalance : newWork+(removedA+removedB)=oldWork+(overhead+interaction)) :
    newWork < oldWork ↔ overhead+interaction < removedA+removedB := by omega

-- Signed differences decompose the PLATFORM GAP, not the sum of parallel wall
-- times. Cost/event matching and platform identity must be established outside.
theorem platformGap (nD nL cD cL hD hL : Int) :
    (nD*cD+hD)-(nL*cL+hL) =
      (nD-nL)*cL+nD*(cD-cL)+(hD-hL) := by
  simp only [Int.sub_mul, Int.mul_sub]
  omega

theorem darwinGainDoesNotCloseLinux (removedD addedD removedL addedL : Nat)
    (darwin : addedD < removedD) (linux : removedL ≤ addedL) :
    addedD < removedD ∧ ¬ addedL < removedL := by omega

-- Reuse the existing accounting owner, rather than add another gain definition.
theorem existingWorkLaw (oldWork newWork removed added : Nat)
    (balance : newWork+removed=oldWork+added) (positive : added < removed) :
    newWork < oldWork :=
  IncrementalCompilerArchitecture.workPositive oldWork newWork removed added balance positive

-- Whole-request elapsed accounting must come from a schedule projection, not
-- from adding CPU savings or overlapping component timers. LinuxAfter is the
-- contemporaneous comparator; holding the old Linux time fixed is not assumed.
theorem twofoldTarget (before after linuxAfter removed added : Nat)
    (balance : after+removed=before+added) :
    after ≤ 2*linuxAfter ↔ before+added ≤ 2*linuxAfter+removed := by omega

theorem threeHalvesTarget (before after linuxAfter removed added : Nat)
    (balance : after+removed=before+added) :
    2*after ≤ 3*linuxAfter ↔ 2*before+2*added ≤ 3*linuxAfter+2*removed := by omega

theorem fourToTwoBudget (linux after removed added : Nat)
    (balance : after+removed=4*linux+added) :
    after ≤ 2*linux ↔ 2*linux+added ≤ removed := by omega

theorem fiveToTwoBudget (linux after removed added : Nat)
    (balance : after+removed=5*linux+added) :
    after ≤ 2*linux ↔ 3*linux+added ≤ removed := by omega

theorem fourToThreeHalvesBudget (linux after removed added : Nat)
    (balance : after+removed=4*linux+added) :
    2*after ≤ 3*linux ↔ 5*linux+2*added ≤ 2*removed := by omega

theorem fiveToThreeHalvesBudget (linux after removed added : Nat)
    (balance : after+removed=5*linux+added) :
    2*after ≤ 3*linux ↔ 7*linux+2*added ≤ 2*removed := by omega

theorem floorRejectsTwofold (floor after linuxAfter : Nat)
    (retained : floor ≤ after) (tooLarge : 2*linuxAfter < floor) :
    ¬ after ≤ 2*linuxAfter := by omega

theorem floorRejectsThreeHalves (floor after linuxAfter : Nat)
    (retained : floor ≤ after) (tooLarge : 3*linuxAfter < 2*floor) :
    ¬ 2*after ≤ 3*linuxAfter := by omega

theorem oldLinuxTargetNotEnough (linux delta : Nat)
    (improvement : 0<delta) (domain : delta ≤ linux) :
    ¬ 2*linux ≤ 2*(linux-delta) := by omega

-- Speedup D_before/D_after differs from residual Darwin/Linux cost.
theorem twofoldAcceleration (before after removed added : Nat)
    (balance : after+removed=before+added) :
    2*after ≤ before ↔ before+2*added ≤ 2*removed := by omega

theorem singleStageRemainder (before stagePart after removed added : Nat)
    (partition : stagePart ≤ before) (onlyThisStage : removed ≤ stagePart)
    (balance : after+removed=before+added) :
    before-stagePart+added ≤ after := by omega

theorem singleStageCannotDouble (before stagePart after removed added : Nat)
    (minority : 2*stagePart < before) (onlyThisStage : removed ≤ stagePart)
    (balance : after+removed=before+added) : ¬ 2*after ≤ before := by omega

theorem additionalRemovalForTwofold (before firstStage after removed extra added : Nat)
    (coverage : removed ≤ firstStage+extra)
    (balance : after+removed=before+added) (target : 2*after ≤ before) :
    before+2*added ≤ 2*firstStage+2*extra := by omega

theorem halfTimeAtFiveStillAboveTwoLinux (linux after : Nat) (hL : 0<linux)
    (half : 2*after=5*linux) : ¬ after ≤ 2*linux := by omega

end Gambit.DevelopmentBenefit
