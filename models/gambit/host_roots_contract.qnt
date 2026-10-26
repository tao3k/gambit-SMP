module host_roots_contract {
  // TARGET root/entry contract: owner 1 symbolizes a nonzero processor.
  // registered is a complete root lease premise, not the current RC scan census.
  type State = { owner: int, registered: bool, marker: bool, frozen: bool,
    acquired: bool, moved: bool, reloaded: bool, depth: int, returned: bool,
    writer: bool, closing: bool, conversions: int, argumentStores: int }
  var s: State
  action init = s' = { owner: 1, registered: false, marker: false, frozen: false,
    acquired: false, moved: false, reloaded: false, depth: 0, returned: false,
    writer: false, closing: false, conversions: 0, argumentStores: 0 }
  action protect = all { not(s.registered),not(s.returned),not(s.closing), s' = { ...s, registered: true } }
  action allocateMarker = all { s.registered,not(s.frozen),not(s.writer),not(s.closing),not(s.marker), s' = { ...s, marker: true } }
  action enter = all { s.registered, s.marker, not(s.frozen),not(s.writer), not(s.closing),s.depth<2, s' = { ...s, depth: s.depth + 1 } }
  // Writer is an atomic root-store/conversion-boundary permit, not a lock held
  // across a collecting converter. Raw SCMOBJ inputs enter before marker GC.
  action acquireWriter = all { s.registered, not(s.frozen),not(s.closing),not(s.writer),
    s'={...s,writer:true} }
  action convert = all{s.writer,not(s.frozen),s.conversions<2,s'={...s,conversions:s.conversions+1}}
  action storeArgument = all{s.writer,not(s.frozen),s.argumentStores<2,s'={...s,argumentStores:s.argumentStores+1}}
  action releaseWriter = all{s.writer,s'={...s,writer:false}}
  action closeWriters = s'={...s,closing:true}
  action freeze = all { s.registered,not(s.returned),not(s.frozen),not(s.writer), s' = { ...s, frozen: true,closing:true } }
  action acquire = all { s.frozen, s' = { ...s, acquired: true } }
  action relocate = all { s.acquired,s.frozen, s' = { ...s, moved: true, reloaded: false } }
  action reload = all { s.moved,s.frozen,s.acquired, s' = { ...s, reloaded: true, frozen: false, closing:false } }
  action leave = all { s.depth > 0, not(s.frozen),not(s.writer), not(s.moved) or s.reloaded,
    s' = { ...s, depth: s.depth - 1 } }
  action release = all { s.depth == 0, not(s.frozen),not(s.writer), s' = { ...s, registered: false, returned: true } }
  action badMarker = s' = { ...s, marker: true }
  action badResume = s' = { ...s, depth: 0, returned: true }
  val safe = (not(s.marker and not(s.returned)) or s.registered) and
    (not(s.acquired) or s.registered or s.returned) and
    (not(s.returned and s.moved) or s.reloaded) and s.depth >= 0 and
    (not(s.frozen) or (not(s.writer) and s.registered)) and (not(s.writer) or s.registered)
  action step=any{protect,allocateMarker,enter,acquireWriter,convert,storeArgument,
    releaseWriter,closeWriters,freeze,acquire,relocate,reload,leave,release,s'=s}
  run nonzeroOwnerTest = init.then(protect).then(allocateMarker).then(enter).then(leave).then(release)
    .expect(safe and s.owner == 1 and s.returned)
  run nestedCallbackTest = init.then(protect).then(allocateMarker).then(enter).then(enter).then(leave)
    .expect(safe and s.registered and s.depth == 1)
  run relocatingWaitTest = init.then(protect).then(allocateMarker).then(enter).then(freeze).then(acquire)
    .then(relocate).then(reload).then(leave).then(release).expect(safe and s.returned)
  run markerBeforeRootControlTest = init.then(badMarker).expect(not(safe))
  run staleResumeControlTest = init.then(protect).then(allocateMarker).then(enter).then(freeze)
    .then(acquire).then(relocate).then(badResume).expect(not(safe))
  run conversionCloseRaceTest=init.then(protect).then(allocateMarker).then(enter)
    .then(acquireWriter).then(convert).then(closeWriters).then(storeArgument)
    .then(releaseWriter).then(freeze).then(acquire).then(relocate).then(reload)
    .expect(safe and s.conversions==1 and s.argumentStores==1 and s.reloaded)
  run parkedConversionTest=init.then(protect).then(allocateMarker).then(enter)
    .then(acquireWriter).then(releaseWriter).then(closeWriters).then(freeze)
    .then(acquire).then(relocate).then(reload).then(acquireWriter).then(convert)
    .then(storeArgument).then(releaseWriter).expect(safe and s.argumentStores==1)
  run freezeLiveWriterControlTest=init.then(protect).then(allocateMarker).then(enter)
    .then(acquireWriter).then(all{s'={...s,frozen:true}}).expect(not(safe))
  run preMarkerConversionTest=init.then(protect).then(acquireWriter).then(convert)
    .then(releaseWriter).then(closeWriters).then(freeze).then(acquire)
    .then(relocate).then(reload).then(allocateMarker).then(enter).then(leave)
    .then(release).expect(safe and s.returned and s.conversions==1)
  run closedEntryTest=init.then(closeWriters).then(release)
    .expect(safe and s.returned and not(s.registered))
}
