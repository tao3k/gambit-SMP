module tfib_scan_origin {
  // Observation protocol, NOT a model that declares native memory corruption safe.
  // cursor 1 heap, 2 frame, 3 root; layout 1 F64, 2 refs, 3 frame, 4 pair.
  // No classifier reads the scenario identifier. Unknown first writer stays unknown.
  type Context = { entry:int, cursor:int, layout:int, object:int, slot:int,
    words:int, frameEpoch:int, frameData:bool, ra:int, map:int,
    wordClass:int, writerObject:int, objectGeneration:int, writerGeneration:int,
    writerCovers:bool, writerPrecedes:bool }
  type State = { policy:int, scenario:int, epoch:int, owner:int, phase:int,
    seq:int, actual:Context, record:Context, recSeq:int, recEpoch:int,
    recOwner:int, recOp:int, committed:bool, persistent:bool, rawKnown:bool,
    fault:bool, faultOp:int, faultSeq:int, frozen:bool, overwritten:bool,
    secondary:bool, resumed:bool, attemptedCovered:bool,
    reported:bool, accepted:bool, diagnosis:int }
  var s: State
  pure def context(k:int,e:int):Context = {
    entry:if(k == 5 or k == 7 or k == 0) 3 else if(k == 2 or k == 3) 2 else 1,
    cursor:if(k == 2 or k == 3) 2 else if(k == 0 or k == 7) 3 else 1,
    layout:if(k == 1) 1 else if(k == 2 or k == 3) 3 else if(k == 6) 4
      else if(k == 0 or k == 7) 0 else 2,
    object:if(k == 2 or k == 3) 20 else if(k == 0 or k == 7) 0 else 10,
    slot:if(k == 9 or k == 10) 3 else 1,
    words:if(k == 1) 7 else if(k == 2 or k == 3) 4 else 2,
    frameEpoch:if(k == 3) e-1 else e,
    frameData:k == 2 or k == 3,
    ra:if(k == 2 or k == 3) 100 else 0,
    map:if(k == 2 or k == 3) 1 else 0,
    wordClass:if(k == 0) 0 else 1,
    writerObject:if(k == 4 or k >= 11) 10 else 0,
    objectGeneration:e, writerGeneration:if(k == 11) e-1 else e,
    writerCovers:k != 12, writerPrecedes:k != 13 }
  pure def initial(p:int,k:int):State = { policy:p, scenario:k, epoch:1,
    owner:0, phase:0, seq:0, actual:context(0,1), record:context(0,1),
    recSeq:0, recEpoch:0, recOwner:0, recOp:0, committed:false,
    persistent:true, rawKnown:false, fault:false, faultOp:0, faultSeq:0,
    frozen:false, overwritten:false, secondary:false, resumed:false,
    attemptedCovered:true, reported:false, accepted:false, diagnosis:0 }
  action init = {
    nondet k = 1.to(13).oneOf()
    all { s' = initial(0,k) }
  }
  action initNormal = all { s' = initial(0,0) }
  action initUnavailableRetains = all { s' = initial(15,2) }
  action initLostTail = all { s' = initial(1,5) }
  action initStalePair = all { s' = initial(2,6) }
  action initFrameFieldsMissing = all { s' = initial(3,2) }
  action initLateHeaderRecord = all { s' = initial(4,1) }
  action initMixedWorker = all { s' = initial(5,2) }
  action initTornRecord = all { s' = initial(6,1) }
  action initUnsafePrettyPrint = all { s' = initial(7,1) }
  action initInventedWriter = all { s' = initial(8,8) }
  action initRangeMeansCurrent = all { s' = initial(9,3) }
  action initOverwriteFault = all { s' = initial(10,1) }
  action initPrivateRecordLost = all { s' = initial(11,2) }
  action initStaleEpochRecord = all { s' = initial(12,2) }
  action initSkipAndContinue = all { s' = initial(13,1) }
  action initMissingCellRecord = all { s' = initial(14,10) }
  action initWordOnly = all { s' = initial(16,2) }
  action initStaleWriter = all { s' = initial(17,11) }
  action initWrongWriteRange = all { s' = initial(18,12) }
  action initUnorderedWriter = all { s' = initial(19,13) }
  pure def capture(c:Context,p:int,e:int):Context = if(e == 1) c else {
    ...c, cursor:if(p == 1) c.entry else if(p == 16) 0 else c.cursor,
    layout:if(p == 2) 1 else c.layout,
    frameData:if(p == 3) false else c.frameData,
    ra:if(p == 3) 0 else c.ra,
    frameEpoch:if(p == 9) e else c.frameEpoch }
  pure def cellContext(c:Context):Context = {...c,wordClass:-1}
  pure def classify(c:Context,raw:bool):int =
    if(c.slot >= c.words) 4
    else if(not(raw)) 0
    else if(c.wordClass == 0) 7
    else if(c.cursor == 2) 2
    else if(c.cursor == 3) 3
    else if(c.cursor == 1 and c.layout == 1) 1
    else if(c.cursor == 1 and c.writerObject == c.object and c.object > 0
      and c.writerGeneration == c.objectGeneration and c.writerCovers and c.writerPrecedes) 5
    else if(c.cursor == 1) 6 else 0
  // diagnoses: 0 unavailable, 1 scalar-layout route, 2 frame route (not proof
  // compiler map is wrong), 3 root route, 4 extent, 5 matched writer witness,
  // 6 heap field with writer unresolved, 7 valid reference. Same bad word can
  // reach 1/2/3/5/6: floating-point-looking bits alone cannot decide the origin.
  pure def complete(c:Context):bool = c.cursor > 0 and
    (c.cursor != 2 or (c.frameData and c.ra > 0))
  pure def identityReady(st:State,op:int):bool = st.committed and
    st.recSeq == st.seq and st.recEpoch == st.epoch and
    st.recOwner == st.owner and st.recOp == op
  action selectEntry = all { s.phase == 0,
    s' = {...s, phase:1, seq:s.epoch*2-1,
      actual:context(if(s.epoch == 1) 0 else s.scenario,s.epoch),
      reported:false,accepted:false,diagnosis:0,rawKnown:false} }
  action commitCell = all { s.phase == 1,
    s' = {...s, phase:2, record:cellContext(capture(s.actual,s.policy,s.epoch)),
      recSeq:s.seq, recEpoch:s.epoch, recOwner:s.owner, recOp:1,
      committed:not(s.policy == 14 and s.epoch == 2),
      persistent:not((s.policy == 11 or s.policy == 15) and s.epoch == 2)} }
  action readCell = all { s.phase == 2,
    s' = {...s, phase:if(s.epoch == 2 and s.scenario == 10) 5 else 3,
      attemptedCovered:s.attemptedCovered and identityReady(s,1),
      rawKnown:not(s.epoch == 2 and s.scenario == 10),
      fault:s.epoch == 2 and s.scenario == 10,
      faultOp:if(s.epoch == 2 and s.scenario == 10) 1 else 0,
      faultSeq:if(s.epoch == 2 and s.scenario == 10) s.seq else 0,
      frozen:s.epoch == 2 and s.scenario == 10} }
  action commitHeader = all { s.phase == 3,
    s' = {...s, phase:4, seq:s.seq+1,
      record:capture(s.actual,s.policy,s.epoch), recSeq:s.seq+1,
      recEpoch:if(s.policy == 12 and s.epoch == 2) 1 else s.epoch,
      recOwner:if(s.policy == 5 and s.epoch == 2) 0 else s.owner,
      recOp:if(s.policy == 4 and s.epoch == 2) 1 else 2,
      committed:not(s.policy == 6 and s.epoch == 2),
      secondary:s.policy == 7 and s.epoch == 2} }
  action readHeader = all { s.phase == 4,
    s' = {...s,phase:5,
      attemptedCovered:s.attemptedCovered and identityReady(s,2),
      fault:s.actual.wordClass == 1,
      faultOp:if(s.actual.wordClass == 1) 2 else 0,
      faultSeq:if(s.actual.wordClass == 1) s.seq else 0,
      frozen:s.actual.wordClass == 1} }
  action overwrite = all { s.phase == 5, s.fault, s.policy == 10,
    not(s.overwritten), s' = {...s, recSeq:s.seq+1,
      record:context(0,s.epoch),overwritten:true} }
  action postmortem = all { s.phase == 5,
    s.policy != 10 or not(s.fault) or s.overwritten,
    s' = {...s,phase:6,reported:true,
      accepted:if(s.policy == 15 and s.epoch == 2) false else true,
      diagnosis:if(s.policy == 15 and s.epoch == 2) 0
        else if((s.policy == 8 or s.policy >= 17) and s.epoch == 2) 5
        else classify(s.record,s.rawKnown),
      resumed:s.policy == 13 and s.epoch == 2} }
  action nextEpoch = all { s.phase == 6, s.epoch == 1, not(s.fault),
    s' = {...s,epoch:2,owner:1,phase:0,reported:false,accepted:false,diagnosis:0} }
  action terminal = all { s.phase == 6, s.epoch == 2, s' = s }
  action step = any { selectEntry,commitCell,readCell,commitHeader,readHeader,
    overwrite,postmortem,nextEpoch,terminal }
  val recordIdentity = not(s.reported and s.accepted) or
    identityReady(s,if(s.faultOp == 1) 1 else 2)
  val accurateContext = not(s.reported and s.accepted) or
    s.record == (if(s.faultOp == 1) cellContext(s.actual) else s.actual)
  val metadataPresent = not(s.reported and s.accepted) or complete(s.record)
  val conservativeDiagnosis = not(s.reported and s.accepted) or
    (s.diagnosis == classify(s.actual,s.rawKnown) and s.diagnosis != 0)
  val crashSurvival = not(s.reported and s.accepted) or s.persistent
  val primaryPreserved = not(s.secondary) and
    (not(s.frozen) or s.recSeq == s.faultSeq)
  val failClosed = not(s.resumed)
  val safe = s.attemptedCovered and recordIdentity and accurateContext and
    metadataPresent and conservativeDiagnosis and crashSurvival and
    primaryPreserved and failClosed
  val done = s.phase == 6 and s.epoch == 2
  val nativeSuccess = done and not(s.fault) and s.scenario == 0
  temporal completion = weakFair(step,Set(s)).implies(eventually(done))
}
