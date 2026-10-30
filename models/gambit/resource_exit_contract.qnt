module resource_exit_contract {
  // TARGET last-user permit. Native destructors and physical release not modeled.
  type State = { epoch: int, permit: int, ingress: bool, users: int,
    strong: bool, weak: bool, cleanup: bool, unknown: bool, reclaimed: bool }
  var s: State
  action init = s' = { epoch: 0, permit: -1, ingress: true, users: 1,
    strong: false, weak: false, cleanup: false, unknown: false, reclaimed: false }
  action closeIngress = s' = { ...s, ingress: false }
  action dropUser = all { s.users > 0, s' = { ...s, users: s.users - 1 } }
  action strong = s' = { ...s, strong: true }
  action weak = all { s.strong, s' = { ...s, weak: true } }
  action cleanup = all { s.weak, s' = { ...s, cleanup: true } }
  action loseOutcome = s' = { ...s, unknown: true }
  action resolve = s' = { ...s, unknown: false }
  def drained: bool = not(s.ingress) and s.users == 0 and s.strong and s.weak and s.cleanup and not(s.unknown)
  action issue = all { drained, s' = { ...s, permit: s.epoch } }
  action reopen = all { not(s.reclaimed), s' = { ...s, epoch: s.epoch + 1, ingress: true, users: s.users + 1 } }
  action reclaim = all { drained, s.permit == s.epoch, s' = { ...s, reclaimed: true } }
  action badReclaim = s' = { ...s, reclaimed: true }
  val safe = not(s.reclaimed) or (drained and s.permit == s.epoch)
  run completeDrainTest = init.then(closeIngress).then(dropUser).then(strong).then(weak).then(cleanup)
    .then(issue).then(reclaim).expect(safe and s.reclaimed)
  run unknownRetainsCustodyTest = init.then(closeIngress).then(dropUser).then(strong).then(weak).then(cleanup)
    .then(loseOutcome).expect(safe and not(drained))
  run unknownResolvedTest = init.then(closeIngress).then(dropUser).then(strong).then(weak).then(cleanup)
    .then(loseOutcome).then(resolve).then(issue).then(reclaim).expect(safe and s.reclaimed)
  run stalePermitControlTest = init.then(closeIngress).then(dropUser).then(strong).then(weak).then(cleanup)
    .then(issue).then(reopen).then(badReclaim).expect(not(safe))
  run phaseOmissionControlTest = init.then(closeIngress).then(dropUser).then(strong).then(badReclaim)
    .expect(not(safe))
}
