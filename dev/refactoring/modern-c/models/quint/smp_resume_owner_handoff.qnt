module smp_resume_owner_handoff {
  // Closed-epoch abstraction of the production owner/context guard. It does
  // not model the actual collective barrier or C memory ordering.
  type State = { owner: bool, contextMatches: bool, callerMatches: bool, published: bool }
  var s: State
  action init = s' = { owner: true, contextMatches: true, callerMatches: true, published: false }
  action loseOwner = s' = {...s, owner: false}
  action changeContext = s' = {...s, contextMatches: false}
  action changeCaller = s' = {...s, callerMatches: false}
  action handoff = all { s.owner, s.contextMatches, s.callerMatches, s' = {...s, published: true} }
  val safe = not(s.published) or (s.owner and s.contextMatches and s.callerMatches)
  run validOwnerTest = init.then(handoff).expect(s.published and safe)
  run missingOwnerNegativeTest = init.then(loseOwner).expect(not(s.published) and safe)
  run wrongContextNegativeTest = init.then(changeContext).expect(not(s.published) and safe)
  run wrongCallerNegativeTest = init.then(changeCaller).expect(not(s.published) and safe)
  run unguardedControlTest = init.then(changeContext)
    .then(all { s' = {...s, published: true} }).expect(not(safe))
}
