module owner_notifier_closure {
  import owner_notifier_parameters.* from "./owner_notifier_parameters"
  type State = { phase: int, resourceAlias: bool, aliasProtectsOwner: bool,
    parserAlias: bool, errorAlias: bool, nativePin: bool, actionBackedge: bool, jobBackedge: bool,
    privateClosure: bool, privateHandles: bool, slot: bool, rootless: bool,
    selected: bool, gcTicket: bool, callbackActive: bool, frameAlive: bool, slotsCleared: bool,
    prepared: bool, returnedNormally: bool, frameRetired: bool, windAfter: bool,
    failed: bool, captureOccurred: bool, callbackCapture: bool, resurrected: bool,
    sealed: bool, accepted: bool, generation: int, noticeGeneration: int, epoch: int, noticeEpoch: int }
  pure val initial: State = { phase: 0, resourceAlias: true, aliasProtectsOwner: true,
    parserAlias: false, errorAlias: false, nativePin: false, actionBackedge: false, jobBackedge: false,
    privateClosure: true, privateHandles: true, slot: true, rootless: true,
    selected: false, gcTicket: false, callbackActive: false, frameAlive: false, slotsCleared: false,
    prepared: false, returnedNormally: false, frameRetired: false, windAfter: false,
    failed: false, captureOccurred: false, callbackCapture: false, resurrected: false,
    sealed: false, accepted: false, generation: OwnerGeneration, noticeGeneration: -1, epoch: 3, noticeEpoch: -1 }
  var s: State
  action init = s' = initial
  action initPublic = s' = { ...initial, privateClosure: false, privateHandles: false }
  action initNoSlot = s' = { ...initial, slot: false }
  action dropResourceAlias = s' = { ...s, resourceAlias: false }
  action keepError = all { s.resourceAlias, s' = { ...s, errorAlias: true } }
  action keepNativePin = all { s.resourceAlias, s' = { ...s, nativePin: true } }
  action keepParser = all { s.resourceAlias, s' = { ...s, parserAlias: true } }
  action captureInActionClosure = all { s.phase == 0, s.resourceAlias, s' = { ...s, actionBackedge: true } }
  action captureInJobClosure = all { s.phase == 0, s.resourceAlias, s' = { ...s, jobBackedge: true } }
  def ownerStrong = (s.resourceAlias and s.aliasProtectsOwner) or s.parserAlias or s.errorAlias or
    s.nativePin or s.actionBackedge or s.jobBackedge or s.callbackActive or s.frameAlive or s.callbackCapture
  def canSelect = s.phase == 0 and not(ownerStrong)
  action selectGC = all { canSelect, s' = { ...s, phase: 1, selected: true } }
  action dispatchGC = all { s.phase == 1, not(s.slotsCleared),
    s' = { ...s, phase: 2, gcTicket: true, callbackActive: true, frameAlive: true, slotsCleared: true } }
  action dispatchManual = all { s.phase == 0, not(s.privateHandles), not(s.slotsCleared),
    s' = { ...s, phase: 2, callbackActive: true, frameAlive: true, slotsCleared: true } }
  def canPrepare = s.callbackActive and not(s.prepared) and s.slot
  action prepareNotice = all { canPrepare,
    s' = { ...s, phase: 3, prepared: true, noticeGeneration: s.generation, noticeEpoch: s.epoch } }
  action returnAction = all { s.callbackActive, s' = { ...s, phase: 4, callbackActive: false, returnedNormally: true } }
  action retireDispatcherFrame = all { s.phase == 4, s.returnedNormally, not(s.callbackActive),
    s' = { ...s, phase: 5, frameAlive: false, frameRetired: true } }
  action captureInsideCallback = all { s.callbackActive, s' = { ...s, callbackCapture: true, captureOccurred: true } }
  action publishTestator = all { s.callbackActive, not(s.privateClosure),
    s' = { ...s, resourceAlias: true, resurrected: true } }
  action readPublicTestator = all { not(s.privateHandles), not(s.slotsCleared),
    s' = { ...s, resourceAlias: true, resurrected: true } }
  action escapeThroughWind = all { s.callbackActive,
    s' = { ...s, phase: 4, callbackActive: false, returnedNormally: false, windAfter: true } }
  action throwFromCallback = all { s.callbackActive,
    s' = { ...s, phase: 4, callbackActive: false, returnedNormally: false, failed: true, errorAlias: true } }
  action retireUnwoundFrame = all { s.phase == 4, not(s.returnedNormally),
    s' = { ...s, phase: 5, frameAlive: false, frameRetired: true } }
  action resumeCapturedCallback = all { s.callbackCapture, not(s.accepted), not(s.callbackActive),
    s' = { ...s, phase: 2, callbackActive: true, frameAlive: true, frameRetired: false, returnedNormally: false } }
  def matched = s.noticeGeneration == s.generation and s.noticeEpoch == s.epoch
  def contributionReady = s.prepared and s.slot and s.rootless and s.privateClosure and s.privateHandles and
    s.selected and s.gcTicket and s.returnedNormally and s.frameRetired and not(ownerStrong) and
    not(s.failed) and not(s.captureOccurred) and not(s.resurrected) and
    s.aliasProtectsOwner and matched
  action sealNotice = all { contributionReady, s' = { ...s, phase: 6, sealed: true } }
  action acceptNotice = all { s.sealed, contributionReady, s' = { ...s, phase: 7, accepted: true } }
  action changeGeneration = all { s.prepared, not(s.accepted), s' = { ...s, generation: s.generation + 1 } }
  def safe = (s.prepared implies s.slot) and (s.accepted implies s.sealed and contributionReady)
  action step = any { dropResourceAlias, keepError, keepNativePin, keepParser, captureInActionClosure,
    captureInJobClosure, selectGC, dispatchGC, dispatchManual, prepareNotice, returnAction,
    retireDispatcherFrame, captureInsideCallback, publishTestator, readPublicTestator,
    escapeThroughWind, throwFromCallback, retireUnwoundFrame, resumeCapturedCallback,
    sealNotice, acceptNotice, changeGeneration, s' = s }
  action acceptEarly = s' = { ...s, sealed: true, accepted: true }
  action rootPayload = s' = { ...s, rootless: false }
  action uncoveredAlias = s' = { ...s, aliasProtectsOwner: false }
  action prepareWithoutSlot = s' = { ...s, prepared: true }
  run selectedNotEvidenceTest = init.then(dropResourceAlias).then(selectGC).expect(safe and not(contributionReady))
  run clearedSlotsKeepFrameTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).expect(safe and s.slotsCleared and ownerStrong)
  run actionReturnNotFrameExitTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(returnAction).expect(safe and s.returnedNormally and not(contributionReady))
  run normalQualifiedNoticeTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(sealNotice).then(acceptNotice).expect(safe and s.accepted)
  run actionBackedgeBlocksTest = init.then(captureInActionClosure).then(dropResourceAlias).expect(safe and not(canSelect))
  run errorHolderBlocksTest = init.then(keepError).then(dropResourceAlias).expect(safe and not(canSelect))
  run nativeHolderBlocksTest = init.then(keepNativePin).then(dropResourceAlias).expect(safe and not(canSelect))
  run persistentJobBlocksTest = init.then(captureInJobClosure).then(dropResourceAlias).expect(safe and not(canSelect))
  run manualNoGCTicketTest = initPublic.then(dispatchManual).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).expect(safe and not(s.gcTicket) and not(contributionReady))
  run publicResurrectionNotEvidenceTest = initPublic.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(publishTestator).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).expect(safe and s.resurrected and not(contributionReady))
  run windAfterNotReturnTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(escapeThroughWind).then(retireUnwoundFrame).expect(safe and s.windAfter and not(contributionReady))
  run callbackFailureRetainsTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(throwFromCallback).then(retireUnwoundFrame).expect(safe and s.errorAlias and not(contributionReady))
  run capturedReentryNotEvidenceTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(captureInsideCallback).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(resumeCapturedCallback).expect(safe and s.callbackActive and not(contributionReady))
  run noSlotDeniesPrepareTest = initNoSlot.then(dropResourceAlias).then(selectGC).then(dispatchGC).expect(safe and not(canPrepare))
  run selectedEarlyAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(acceptEarly).expect(not(safe))
  run preparedEarlyAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(acceptEarly).expect(not(safe))
  run clearedSlotAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(acceptEarly).expect(not(safe))
  run liveDispatcherAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(returnAction).then(acceptEarly).expect(not(safe))
  run manualAcceptControlTest = initPublic.then(dispatchManual).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(acceptEarly).expect(not(safe))
  run resurrectionAcceptControlTest = initPublic.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(publishTestator).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(acceptEarly).expect(not(safe))
  run windAfterAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(escapeThroughWind).then(retireUnwoundFrame).then(acceptEarly).expect(not(safe))
  run capturedAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(captureInsideCallback).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(acceptEarly).expect(not(safe))
  run failedAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(throwFromCallback).then(retireUnwoundFrame).then(acceptEarly).expect(not(safe))
  run staleGenerationAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(sealNotice).then(changeGeneration).then(acceptEarly).expect(not(safe))
  run rootedPayloadAcceptControlTest = init.then(dropResourceAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(sealNotice).then(rootPayload).then(acceptEarly).expect(not(safe))
  run uncoveredOwnerAcceptControlTest = init.then(uncoveredAlias).then(selectGC).then(dispatchGC).then(prepareNotice).then(returnAction).then(retireDispatcherFrame).then(acceptEarly).expect(not(safe))
  run missingSlotControlTest = initNoSlot.then(prepareWithoutSlot).expect(not(safe))
}
