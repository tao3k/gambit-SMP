// Explicit reader visibility litmus, not a complete C/ARM memory model.
module ForwardingVisibility {
  type State = { policy: str, initialized: bool, published: bool,
    visiblePayload: bool, read: bool, wrongPayload: bool }
  var s: State
  pure def initial(policy: str): State = { policy: policy, initialized: false,
    published: false, visiblePayload: false, read: false, wrongPayload: false }
  action init = s' = initial("release-acquire")
  action initNoRelease = s' = initial("no-release")
  action initNoAcquire = s' = initial("no-acquire")
  action initialize = all { not(s.initialized),
    s' = { ...s, initialized: true } }
  action publish = all { s.initialized, not(s.published),
    s' = { ...s, published: true } }
  action propagate = all { s.initialized, not(s.visiblePayload),
    s' = { ...s, visiblePayload: true } }
  action load = all { s.published, not(s.read),
    val synchronized = s.policy == "release-acquire"
    s' = { ...s, read: true,
      wrongPayload: not(s.visiblePayload or synchronized) } }
  action step = any { initialize, publish, propagate, load }
  val Safe = not(s.wrongPayload)
}
