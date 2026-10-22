module host_roots_contract {
  // TARGET root/entry contract: owner 1 symbolizes a nonzero processor.
  // registered is a complete root lease premise, not the current RC scan census.
  type State = { owner: int, registered: bool, marker: bool, frozen: bool,
    acquired: bool, moved: bool, reloaded: bool, depth: int, returned: bool }
  var s: State
  action init = s' = { owner: 1, registered: false, marker: false, frozen: false,
    acquired: false, moved: false, reloaded: false, depth: 0, returned: false }
  action protect = all { not(s.registered), s' = { ...s, registered: true } }
  action allocateMarker = all { s.registered, not(s.marker), s' = { ...s, marker: true } }
  action enter = all { s.registered, s.marker, not(s.frozen), s' = { ...s, depth: s.depth + 1 } }
  action freeze = all { s.depth > 0, not(s.frozen), s' = { ...s, frozen: true } }
  action acquire = all { s.frozen, s' = { ...s, acquired: true } }
  action relocate = all { s.acquired, s' = { ...s, moved: true, reloaded: false } }
  action reload = all { s.moved, s' = { ...s, reloaded: true, frozen: false } }
  action leave = all { s.depth > 0, not(s.frozen), not(s.moved) or s.reloaded,
    s' = { ...s, depth: s.depth - 1 } }
  action release = all { s.depth == 0, not(s.frozen), s' = { ...s, registered: false, returned: true } }
  action badMarker = s' = { ...s, marker: true }
  action badResume = s' = { ...s, depth: 0, returned: true }
  val safe = (not(s.marker and not(s.returned)) or s.registered) and
    (not(s.acquired) or s.registered or s.returned) and
    (not(s.returned and s.moved) or s.reloaded) and s.depth >= 0
  run nonzeroOwnerTest = init.then(protect).then(allocateMarker).then(enter).then(leave).then(release)
    .expect(safe and s.owner == 1 and s.returned)
  run nestedCallbackTest = init.then(protect).then(allocateMarker).then(enter).then(enter).then(leave)
    .expect(safe and s.registered and s.depth == 1)
  run relocatingWaitTest = init.then(protect).then(allocateMarker).then(enter).then(freeze).then(acquire)
    .then(relocate).then(reload).then(leave).then(release).expect(safe and s.returned)
  run markerBeforeRootControlTest = init.then(badMarker).expect(not(safe))
  run staleResumeControlTest = init.then(protect).then(allocateMarker).then(enter).then(freeze)
    .then(acquire).then(relocate).then(badResume).expect(not(safe))
}
