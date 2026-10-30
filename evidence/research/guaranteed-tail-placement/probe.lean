import Std.Tactic
namespace GambitSMP.GuaranteedTailPlacement
-- Per-span ordered high-water bounds, not a global primitive size constant.
theorem spanContained (h limit bound last : Nat) (atEntry : h ≤ limit)
    (guard : limit+bound ≤ last) : h+bound ≤ last := by omega
theorem copyAndFutureDisjoint (copyEnd futureStart futureEnd : Nat)
    (fence : copyEnd ≤ futureStart) (valid : futureStart ≤ futureEnd) :
    ∀ x : Nat, x < copyEnd → ¬(futureStart ≤ x ∧ x < futureEnd) := by
  intro x copied future
  omega
theorem restoreAllowance (start allowance guard last : Nat)
    (fits : start+allowance+guard ≤ last) : start+allowance ≤ last-guard := by omega
theorem sequentialBound (h delta w1 w2 b last : Nat)
    (entry : h+b ≤ last) (a : w1 ≤ b) (c : delta+w2 ≤ b) :
    h+w1 ≤ last ∧ h+delta+w2 ≤ last := by omega
theorem vectorBoxBoundMonotone (n d more : Nat) (boxes : d ≤ more) :
    n+1+2*d ≤ n+1+2*more := by omega
theorem noDoubleReserve (fresh demand q : Nat) (h : fresh+q=demand) :
    fresh=demand-q := by omega
theorem guardCannotBeCountedAsAllowance (allowance guard : Nat) (positive : 0<guard) :
    allowance < allowance+guard := by omega
theorem lateRefundKeepsRecordedPeak (previous current refund : Nat) :
    previous ≤ max previous (current-refund) := Nat.le_max_left _ _
theorem threePhasePeakBelow (a b c ceiling : Nat)
    (ha : a<ceiling) (hb : b<ceiling) (hc : c<ceiling) : max a (max b c)<ceiling := by omega
theorem dominantUnchangedNoStrictGain (oldPeak unchanged candidateOther : Nat)
    (h : unchanged=oldPeak) : ¬max unchanged candidateOther<oldPeak := by omega
theorem creditNeedsNetGain (base saving added : Nat) (admitted : saving ≤ base)
    (positive : added<saving) : base-saving+added<base := by omega
theorem largerDestinationCancelsCredit (base saving : Nat) (h : saving ≤ base) :
    base-saving+saving=base := by omega
end GambitSMP.GuaranteedTailPlacement
#check GambitSMP.GuaranteedTailPlacement.spanContained
#print axioms GambitSMP.GuaranteedTailPlacement.spanContained
#check GambitSMP.GuaranteedTailPlacement.copyAndFutureDisjoint
#print axioms GambitSMP.GuaranteedTailPlacement.copyAndFutureDisjoint
#check GambitSMP.GuaranteedTailPlacement.restoreAllowance
#print axioms GambitSMP.GuaranteedTailPlacement.restoreAllowance
#check GambitSMP.GuaranteedTailPlacement.sequentialBound
#print axioms GambitSMP.GuaranteedTailPlacement.sequentialBound
#check GambitSMP.GuaranteedTailPlacement.vectorBoxBoundMonotone
#print axioms GambitSMP.GuaranteedTailPlacement.vectorBoxBoundMonotone
#check GambitSMP.GuaranteedTailPlacement.noDoubleReserve
#print axioms GambitSMP.GuaranteedTailPlacement.noDoubleReserve
#check GambitSMP.GuaranteedTailPlacement.guardCannotBeCountedAsAllowance
#print axioms GambitSMP.GuaranteedTailPlacement.guardCannotBeCountedAsAllowance
#check GambitSMP.GuaranteedTailPlacement.lateRefundKeepsRecordedPeak
#print axioms GambitSMP.GuaranteedTailPlacement.lateRefundKeepsRecordedPeak
#check GambitSMP.GuaranteedTailPlacement.threePhasePeakBelow
#print axioms GambitSMP.GuaranteedTailPlacement.threePhasePeakBelow
#check GambitSMP.GuaranteedTailPlacement.dominantUnchangedNoStrictGain
#print axioms GambitSMP.GuaranteedTailPlacement.dominantUnchangedNoStrictGain
#check GambitSMP.GuaranteedTailPlacement.creditNeedsNetGain
#print axioms GambitSMP.GuaranteedTailPlacement.creditNeedsNetGain
#check GambitSMP.GuaranteedTailPlacement.largerDestinationCancelsCredit
#print axioms GambitSMP.GuaranteedTailPlacement.largerDestinationCancelsCredit
