-- Arithmetic of the measured guard. Quint owns the refresh history.
-- These equalities are not a native admission and not a sealed GSI.
namespace Gambit.GuardPublication

def half : Nat := 65536
def fudge : Nat := 9222
def breakWords : Nat := 4

def burst (soft words : Nat) : Nat := soft + words

theorem measuredBurstLeavesMappedHalf :
    burst (half - 9221) fudge = half + 1 := by
  decide

theorem fudgeBeforeHardEndLandsOnHardEnd (hard : Nat) (room : fudge ≤ hard) :
    burst (hard - fudge) fudge = hard :=
  Nat.sub_add_cancel room

theorem measuredHardEndIsInsidePast :
    half - 1 ≤ half := by
  decide

theorem breakFromBaseIsFourBelow (base : Int) :
    base - (breakWords : Int) = base - 4 := by
  simp [breakWords]

theorem measuredCensusOffsetIsBelowBase :
    ((0 : Int) - 4) < 0 := by
  decide

def poll (fp trip : Int) : Prop := fp < trip

theorem staleTripMissesRaisedLimit :
    poll 4 100 ∧ ¬ poll 4 0 := by
  unfold poll
  constructor
  · decide
  · decide

theorem refreshedTripStopsAtTheLimit :
    ¬ poll (9222 : Int) (9222 : Int) := by
  unfold poll
  decide

end Gambit.GuardPublication
