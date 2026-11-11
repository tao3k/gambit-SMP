module repair_9_12_observation_grain {
  // Finer grain for the repair-9-12 observations ASCENT already keeps apart.
  // Each witness has its own identity. A pre-join flag is not an OS join
  // recovery. A scheme writer dumping an f64 or u8 vector is not a
  // ##wr-structure TYPEID cause. A non-symbol binding id is not that cause.
  // Seeing one grain does not close another, and the milestone stays 8.
  // This is not a source patch and not 9/12.
  type State = {
    control: int,
    joinFlag: bool, symkey: bool, binding: bool, exacttime: bool,
    vectorDump: bool, typeidKnown: bool,
    joinClosed: bool, vectorClosed: bool, typeidClosed: bool,
    bindingClosed: bool, milestone: int
  }
  var s: State
  pure def initial(control: int): State = {
    control: control,
    joinFlag: false, symkey: false, binding: false, exacttime: false,
    vectorDump: false, typeidKnown: false,
    joinClosed: false, vectorClosed: false, typeidClosed: false,
    bindingClosed: false, milestone: 8
  }
  action initObserve = s' = initial(0)
  action initJoinFlag = s' = initial(1)
  action initVectorAsTypeid = s' = initial(2)
  action initBindingAsFix = s' = initial(3)
  action initConjoin = s' = initial(4)
  action seeJoinFlag = all {
    s.control == 0, not(s.joinFlag),
    s' = { ...s, joinFlag: true }
  }
  action seeSymkey = all {
    s.control == 0, not(s.symkey),
    s' = { ...s, symkey: true }
  }
  action seeBinding = all {
    s.control == 0, not(s.binding),
    s' = { ...s, binding: true }
  }
  action seeExactTime = all {
    s.control == 0, not(s.exacttime),
    s' = { ...s, exacttime: true }
  }
  action seeVector = all {
    s.control == 0, not(s.vectorDump),
    s' = { ...s, vectorDump: true }
  }
  action closeJoinFromFlag = all {
    s.control == 1, not(s.joinClosed),
    s' = { ...s, joinFlag: true, joinClosed: true }
  }
  action closeTypeidFromVector = all {
    s.control == 2, not(s.typeidClosed),
    s' = { ...s, vectorDump: true, typeidKnown: true, typeidClosed: true,
           vectorClosed: true }
  }
  action closeBindingAsClass = all {
    s.control == 3, not(s.bindingClosed),
    s' = { ...s, binding: true, bindingClosed: true }
  }
  action conjoinGrains = all {
    s.control == 4, not(s.joinClosed),
    s' = { ...s, joinFlag: true, vectorDump: true, joinClosed: true,
           typeidClosed: true }
  }
  val terminal =
    s.control == 0 and s.joinFlag and s.symkey and s.binding and s.exacttime and
    s.vectorDump and not(s.typeidKnown) and s.milestone == 8 and
    not(s.joinClosed) and not(s.vectorClosed) and not(s.typeidClosed) and
    not(s.bindingClosed)
  action done = all { terminal, s' = s }
  action step = any {
    seeJoinFlag, seeSymkey, seeBinding, seeExactTime, seeVector,
    closeJoinFromFlag, closeTypeidFromVector, closeBindingAsClass,
    conjoinGrains, done
  }
  val separate =
    s.milestone == 8 and not(s.joinClosed) and not(s.vectorClosed) and
    not(s.typeidClosed) and not(s.bindingClosed) and not(s.typeidKnown)
  val joinFlagIsNotRecovery = not(s.joinClosed)
  val vectorIsNotTypeid = not(s.typeidClosed)
  val bindingIsNotAClassRepair = not(s.bindingClosed)
  val grainsStaySeparate = not(s.joinClosed and s.typeidClosed)
  temporal progress = weakFair(step, Set(s)).implies(eventually(terminal))
}
