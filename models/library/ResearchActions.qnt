// Finite request identities; no claim about native admission or scheduler fairness.
module ResearchActions {
  const Mutation: str
  var generation: int
  var discovered: int
  var authorized: bool
  var reserved: bool
  var launched: int
  var complete: bool
  var failed: bool
  var sound: bool
  var observed: bool
  var causalClaim: bool
  action init = all {generation' = 0, discovered' = -1, authorized' = false,
    reserved' = false, launched' = 0, complete' = false, failed' = false, sound' = true,
    observed' = false, causalClaim' = false}
  action Discover = all {discovered' = generation, generation' = generation,
    authorized' = authorized, reserved' = reserved, launched' = launched,
    complete' = complete, failed' = failed, sound' = sound}
  action Drift = all {generation < 2, generation' = generation + 1,
    discovered' = discovered, authorized' = authorized, reserved' = reserved,
    launched' = launched, complete' = complete, failed' = failed, sound' = sound}
  action Authorize = all {authorized' = true, generation' = generation,
    discovered' = discovered, reserved' = reserved, launched' = launched,
    complete' = complete, failed' = failed, sound' = sound}
  action Select = all {authorized or Mutation == "unauthorized",
    discovered == generation or Mutation == "stale",
    not(reserved) or Mutation == "duplicate",
    reserved' = true, launched' = launched + 1, generation' = generation,
    discovered' = discovered, authorized' = authorized, complete' = complete,
    failed' = failed, sound' = (sound and authorized and discovered == generation)}
  action Finish = all {reserved, not(complete), not(failed), complete' = true,
    generation' = generation, discovered' = discovered, authorized' = authorized,
    reserved' = reserved, launched' = launched, failed' = failed, sound' = sound}
  action Fail = all {reserved, not(complete), failed' = true,
    generation' = generation, discovered' = discovered, authorized' = authorized,
    reserved' = reserved, launched' = launched, complete' = complete, sound' = sound}
  action Observe = all {generation' = generation, discovered' = discovered,
    authorized' = authorized, reserved' = reserved, launched' = launched,
    complete' = complete, failed' = failed, sound' = sound}
  action Protocol = all {any {Discover, Drift, Authorize, Select, Finish, Fail, Observe},
    observed' = observed, causalClaim' = causalClaim}
  action RecordObservation = all {observed' = true,
    causalClaim' = (causalClaim or Mutation == "false-cause"),
    generation' = generation, discovered' = discovered, authorized' = authorized,
    reserved' = reserved, launched' = launched, complete' = complete,
    failed' = failed, sound' = sound}
  action step = any {Protocol, RecordObservation}
  val Safe = all {sound, launched <= 1, launched >= 0,
    complete implies reserved, failed implies reserved, not(complete and failed),
    not(causalClaim)}
}
