// Finite transport/selection contract; not a proof of scientific root cause.
module ActionEvidence {
  const Mutation: str
  var generation: int
  var snapshot: int
  var reference: bool
  var needsSatisfied: bool
  var authorized: bool
  var reserved: bool
  var launched: int
  var explanationBound: bool
  var observation: bool
  var refuted: bool
  var failedAt: int

  action init = all {generation' = 0, snapshot' = -1, reference' = true,
    needsSatisfied' = false, authorized' = false, reserved' = false,
    launched' = 0, explanationBound' = false, observation' = false,
    refuted' = false, failedAt' = -1}
  action Discover = all {snapshot' = generation,
    explanationBound' = (reference or Mutation == "missing-reference"),
    generation' = generation, reference' = reference, needsSatisfied' = needsSatisfied,
    authorized' = authorized, reserved' = reserved, launched' = launched,
    observation' = observation, refuted' = refuted, failedAt' = failedAt}
  action Drift = all {generation < 2, generation' = generation + 1,
    snapshot' = snapshot, explanationBound' = false, reference' = reference,
    needsSatisfied' = needsSatisfied, authorized' = authorized, reserved' = reserved,
    launched' = launched, observation' = observation, refuted' = refuted, failedAt' = failedAt}
  action Withdraw = all {reference' = false, explanationBound' = false,
    generation' = generation, snapshot' = snapshot, needsSatisfied' = needsSatisfied,
    authorized' = authorized, reserved' = reserved, launched' = launched,
    observation' = observation, refuted' = refuted, failedAt' = failedAt}
  action Prepare = all {needsSatisfied' = true, authorized' = true,
    generation' = generation, snapshot' = snapshot, reference' = reference,
    explanationBound' = explanationBound, reserved' = reserved, launched' = launched,
    observation' = observation, refuted' = refuted, failedAt' = failedAt}
  action Select = all {needsSatisfied, reference, snapshot == generation or Mutation == "stale",
    authorized or Mutation == "unauthorized", not(reserved) or Mutation == "duplicate",
    failedAt != generation or Mutation == "failed-route",
    reserved' = true, launched' = launched + 1, generation' = generation,
    snapshot' = snapshot, reference' = reference, needsSatisfied' = needsSatisfied,
    authorized' = authorized, explanationBound' = explanationBound,
    observation' = observation, refuted' = refuted, failedAt' = failedAt}
  action Fail = all {failedAt' = generation, generation' = generation,
    snapshot' = snapshot, reference' = reference, needsSatisfied' = needsSatisfied,
    authorized' = authorized, explanationBound' = explanationBound, reserved' = reserved,
    launched' = launched, observation' = observation, refuted' = refuted}
  action Observe = all {observation' = true, refuted' = Mutation == "false-refutation",
    generation' = generation, snapshot' = snapshot, reference' = reference,
    needsSatisfied' = needsSatisfied, authorized' = authorized, reserved' = reserved,
    explanationBound' = explanationBound, launched' = launched, failedAt' = failedAt}
  action step = any {Discover, Drift, Withdraw, Prepare, Select, Fail, Observe}
  val Safe = all {explanationBound implies (reference and snapshot == generation), not(refuted),
    launched <= 1, launched > 0 implies authorized}
}
