module span_storage_handoff {
  import span_storage_parameters.* from "./span_storage_parameters"
  type State = { raw: List[int], exposed: List[int], exposedId: int,
    captureReach: bool, traceReach: bool, beforeRead: bool, resumes: int,
    active: Set[int], executed: Set[int], effects: int, reads: int, cursor: int,
    phase: int, original: bool, replacement: bool, secondary: bool, handoffUnknown: bool,
    nativeStatus: int, nativeAttempts: int, borrows: int, spanViews: int,
    streamReleased: bool, rawReleased: bool }
  var s: State
  pure def initial(beforeRead: bool): State = { raw: List(97,98), exposed: List(97,98), exposedId: 7,
    captureReach: false, traceReach: false, beforeRead: beforeRead, resumes: 0,
    active: Set(), executed: Set(), effects: 0, reads: 1, cursor: 4,
    phase: 0, original: false, replacement: false, secondary: false, handoffUnknown: false,
    nativeStatus: 0, nativeAttempts: 0, borrows: 0, spanViews: 1,
    streamReleased: false, rawReleased: false }
  action init = s' = initial(false)
  action initBeforeRead = s' = initial(true)
  action capture = all { not(s.streamReleased), not(s.captureReach), s' = { ...s, captureReach: true } }
  action mutateExposed = s' = { ...s, exposed: List(120,98) }
  action resume = all { s.captureReach, s.resumes < MaximumResumptions,
    s' = { ...s, active: s.active.union(Set(s.resumes)), resumes: s.resumes + 1 } }
  action executeSuffix = {
    nondet i = s.active.oneOf()
    all { not(s.executed.contains(i)), s' = { ...s, executed: s.executed.union(Set(i)), effects: s.effects + 1,
      reads: s.reads + (if (s.beforeRead) 1 else 0), cursor: s.cursor + (if (s.beforeRead) 1 else 0) } }
  }
  action finishResume = {
    nondet i = s.active.oneOf()
    all { s.executed.contains(i), s' = { ...s, active: s.active.exclude(Set(i)) } }
  }
  // Environmental reachability witnesses, not automatic count-based release.
  action captureUnreachable = s' = { ...s, captureReach: false }
  action traceUnreachable = s' = { ...s, traceReach: false }
  action raiseOriginal = all { s.phase == 0, not(s.streamReleased), s' = { ...s, phase: 1, original: true } }
  action beginPrepare = all { s.phase == 1, s' = { ...s, phase: 2 } }
  action prepareReplacement = all { s.phase == 2, s' = { ...s, phase: 3, replacement: true } }
  action failPrepare = all { s.phase == 2, s' = { ...s, phase: 5, secondary: true } }
  action commit = all { s.phase == 3, s.replacement, s' = { ...s, phase: 4, original: false } }
  action commitUnknown = all { s.phase == 3, s.replacement,
    s' = { ...s, phase: 4, original: false, handoffUnknown: true } }
  action settleHandoff = all { s.handoffUnknown, s' = { ...s, handoffUnknown: false } }
  action deliverReplacement = all { s.phase == 4, s.replacement,
    s' = { ...s, phase: 6, replacement: false, traceReach: true } }
  action deliverSecondary = all { s.phase == 5, s.secondary,
    s' = { ...s, phase: 6, original: false, secondary: false, traceReach: true } }
  action issueNative = all { s.nativeStatus == 0, not(s.streamReleased),
    s' = { ...s, nativeStatus: 1, nativeAttempts: 1 } }
  action completeNativeUnknown = all { s.nativeStatus == 1, s' = { ...s, nativeStatus: 2 } }
  action settleNative = all { s.nativeStatus == 2, s' = { ...s, nativeStatus: 3 } }
  action borrow = all { not(s.streamReleased), s.borrows == 0, s' = { ...s, borrows: 1 } }
  action releaseBorrow = all { s.borrows == 1, s' = { ...s, borrows: 0 } }
  action detachLastSpan = s' = { ...s, spanViews: 0 }
  def pending = s.handoffUnknown or Set(1,2).contains(s.nativeStatus)
  def rootsDrained = not(s.captureReach) and not(s.traceReach) and s.active == Set() and
    not(s.original) and not(s.replacement) and not(s.secondary) and s.borrows == 0 and not(pending)
  action releaseStream = all { rootsDrained, s' = { ...s, streamReleased: true } }
  action releaseRaw = all { s.streamReleased, rootsDrained, s.spanViews == 0, s' = { ...s, rawReleased: true } }
  def safe = s.raw == List(97,98) and s.exposedId == 7 and
    s.effects == s.executed.size() and
    s.reads == (if (s.beforeRead) 1 + s.effects else 1) and
    s.cursor == 4 + (if (s.beforeRead) s.effects else 0) and
    (Set(1,2,3,5).contains(s.phase) implies s.original) and
    (s.phase == 3 implies s.replacement) and
    (s.streamReleased implies rootsDrained) and
    (s.rawReleased implies s.streamReleased and rootsDrained and s.spanViews == 0) and s.nativeAttempts <= 1
  action step = any { capture, mutateExposed, resume, executeSuffix, finishResume,
    captureUnreachable, traceUnreachable, raiseOriginal, beginPrepare, prepareReplacement,
    failPrepare, commit, commitUnknown, settleHandoff, deliverReplacement, deliverSecondary,
    issueNative, completeNativeUnknown, settleNative, borrow, releaseBorrow, detachLastSpan,
    releaseStream, releaseRaw, s' = s }
  action corruptRaw = s' = { ...s, raw: s.exposed }
  action cloneExposed = s' = { ...s, exposedId: 8 }
  action dropOriginalEarly = s' = { ...s, original: false }
  action releaseStreamEarly = s' = { ...s, streamReleased: true }
  action releaseRawEarly = s' = { ...s, rawReleased: true }
  action retryTransport = s' = { ...s, nativeAttempts: s.nativeAttempts + 1 }
  action memoizeUserEffects = s' = { ...s, effects: 0 }
  action rewindCursor = s' = { ...s, cursor: 4 }
  run isolatedMutationTest = init.then(mutateExposed).expect(safe and s.raw == List(97,98))
  run sameExposedObjectTest = init.then(capture).then(mutateExposed).then(resume).expect(safe and s.exposedId == 7 and s.exposed == List(120,98))
  run twoAfterReadResumptionsTest = init.then(capture).then(resume).then(executeSuffix).then(finishResume).then(resume).then(executeSuffix).then(finishResume).expect(safe and s.effects == 2 and s.reads == 1)
  run twoBeforeReadResumptionsTest = initBeforeRead.then(capture).then(resume).then(executeSuffix).then(finishResume).then(resume).then(executeSuffix).then(finishResume).expect(safe and s.effects == 2 and s.reads == 3)
  run failedPrepareCustodyTest = init.then(raiseOriginal).then(beginPrepare).then(failPrepare).expect(safe and s.original and s.secondary)
  run preparedBeforeReleaseTest = init.then(raiseOriginal).then(beginPrepare).then(prepareReplacement).then(commit).expect(safe and s.replacement and not(s.original))
  run deliveredTracePinsTest = init.then(raiseOriginal).then(beginPrepare).then(prepareReplacement).then(commit).then(deliverReplacement).expect(safe and not(rootsDrained))
  run nativeUnknownPinsTest = init.then(issueNative).then(completeNativeUnknown).expect(safe and pending)
  run detachedSpanOutlivesStreamTest = init.then(releaseStream).expect(safe and s.streamReleased and s.spanViews == 1 and not(s.rawReleased))
  run rawDrainTest = init.then(detachLastSpan).then(releaseStream).then(releaseRaw).expect(safe and s.rawReleased)
  run handoffUnknownPinsTest = init.then(raiseOriginal).then(beginPrepare).then(prepareReplacement).then(commitUnknown).expect(safe and pending)
  run resumesDoNotDrainCaptureTest = init.then(capture).then(resume).then(executeSuffix).then(finishResume).then(resume).then(executeSuffix).then(finishResume).expect(safe and not(rootsDrained))
  run mutableRawAliasControlTest = init.then(mutateExposed).then(corruptRaw).expect(not(safe))
  run exposedIdentityCloneControlTest = init.then(capture).then(cloneExposed).expect(not(safe))
  run originalDropControlTest = init.then(raiseOriginal).then(beginPrepare).then(dropOriginalEarly).expect(not(safe))
  run tracePrematureReleaseControlTest = init.then(raiseOriginal).then(beginPrepare).then(prepareReplacement).then(commit).then(deliverReplacement).then(releaseStreamEarly).expect(not(safe))
  run spanPrematureReleaseControlTest = init.then(releaseRawEarly).expect(not(safe))
  run unknownRetryControlTest = init.then(issueNative).then(completeNativeUnknown).then(retryTransport).expect(not(safe))
  run userEffectMemoizationControlTest = init.then(capture).then(resume).then(executeSuffix).then(memoizeUserEffects).expect(not(safe))
  run savedCursorRollbackControlTest = initBeforeRead.then(capture).then(resume).then(executeSuffix).then(rewindCursor).expect(not(safe))
  run resumeCountReleaseControlTest = init.then(capture).then(resume).then(executeSuffix).then(finishResume).then(resume).then(executeSuffix).then(finishResume).then(releaseStreamEarly).expect(not(safe))
}
