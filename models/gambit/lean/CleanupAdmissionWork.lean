import LeanPoo.Functional.TransformationResources

namespace GambitSMP.CleanupAdmissionWork

-- Bounds on counted source operations, not on seconds, lock acquisition delay,
-- OS scheduling or GC. Members and processor populations are arbitrary naturals.
def cost (frameProbes gateAttempts rollbackReopens busyReopens : Nat) : Nat :=
  frameProbes + gateAttempts + rollbackReopens + busyReopens

theorem linearAdmissionWork
    (populations : List Nat)
    (frameProbes gateAttempts rollbackReopens busyReopens : Nat)
    (frames : frameProbes ≤ populations.sum)
    (visits : gateAttempts ≤ populations.length)
    (singleReopen : rollbackReopens + busyReopens ≤ gateAttempts) :
    cost frameProbes gateAttempts rollbackReopens busyReopens ≤
      populations.sum + 2 * populations.length := by
  unfold cost
  omega

-- Exact equality only for one processor per visited VM, with the busy frame on
-- that processor. General populations use linearAdmissionWork above.
theorem singleProcessorRejectedPrefixWork (closedMembers frameProbes : Nat)
    (singleProcessorVisits : frameProbes = closedMembers + 1) :
    cost frameProbes (closedMembers + 1) closedMembers 1 = 3 * (closedMembers + 1) := by
  unfold cost
  omega

-- Sequential attempts compose by addition: retry is not a claim that old work
-- disappears, even though the QNT counters are local to one attempt.
theorem retriesPreserveAccounting (first second firstBound secondBound : Nat)
    (hFirst : first ≤ firstBound) (hSecond : second ≤ secondBound) :
    first + second ≤ firstBound + secondBound := Nat.add_le_add hFirst hSecond

theorem attemptWorkSum (costs : List Nat) (bound : Nat)
    (perAttempt : ∀ c ∈ costs, c ≤ bound) :
    costs.sum ≤ costs.length * bound := by
  induction costs with
  | nil => simp
  | cons head tail ih =>
    have headBound := perAttempt head (by simp)
    have tailBound : ∀ c ∈ tail, c ≤ bound := by
      intro c hc
      exact perAttempt c (by simp [hc])
    have rest := ih tailBound
    simp only [List.sum_cons, List.length_cons, Nat.succ_mul]
    omega

theorem redundantScanViolatesSingleVisit (members : Nat) :
    ¬ members + 1 ≤ members := by omega

#print axioms linearAdmissionWork
#print axioms singleProcessorRejectedPrefixWork
#print axioms retriesPreserveAccounting
#print axioms attemptWorkSum
#print axioms redundantScanViolatesSingleVisit

end GambitSMP.CleanupAdmissionWork
