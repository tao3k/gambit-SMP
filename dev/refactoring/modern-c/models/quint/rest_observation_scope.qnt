// Evidence identity and completeness only. No allocator or GC algorithm is
// simulated here; physical geometry remains owned by FrameContract.lean.
module rest_observation_scope {
  type Scope = {
    image: int, command: int, spelling: int, caseId: int,
    owner: int, activation: int, attempt: int, generation: int
  }
  pure def sameAttempt(a: Scope, b: Scope): bool = a == b
  pure def completeCut(closed: bool, noLoss: bool, natural: bool,
                       quiescent: bool, allPremises: bool): bool =
    closed and noLoss and natural and quiescent and allPremises
  pure val a = {image: 1, command: 1, spelling: 1, caseId: 1,
                owner: 1, activation: 1, attempt: 1, generation: 1}
  run anotherCommandCannotFillMissingPremiseTest =
    assert(not(sameAttempt(a, a.with("command", 2))))
  run anotherOwnerCannotSupplyRootReloadTest =
    assert(not(sameAttempt(a, a.with("owner", 2))))
  run anotherAttemptCannotSupplyDeliveryTest =
    assert(not(sameAttempt(a, a.with("attempt", 2))))
  run timeoutOrLossCannotCompleteCutTest =
    assert(not(completeCut(true, true, false, true, true)) and
           not(completeCut(true, false, true, true, true)) and
           not(completeCut(true, true, true, true, false)))
  run completeCutIsOnlyAnObservationTest =
    assert(completeCut(true, true, true, true, true))
}
