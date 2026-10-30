module repair9_new_data_boundaries {
  // Evidence admission controls, not C memory or scheduler refinement.
  // location: 0 processor queue, 1 dispatcher local, 2 thread queue,
  // 3 executing action, 4 result published. All retain one request owner.
  type State = { mode:int, bad:bool, phase:int, session:int, recRun:int,
    seq:int, commit:int, location:int, pending:bool, accepted:bool }
  var s: State
  pure def initial(m:int,b:bool):State = { mode:m, bad:b, phase:0,
    session:1, recRun:1, seq:1, commit:1, location:0,
    pending:true, accepted:false }
  action initCarrier = s' = initial(1,false)
  action initRequest = s' = initial(2,false)
  action initStaleAccept = s' = initial(1,true)
  action initQueueVerdict = s' = initial(2,true)
  action reopen = all { s.mode == 1, s.phase == 0,
    s' = {...s, session:2, phase:1} }
  action inspect = all { s.mode == 1, s.phase == 1,
    s' = {...s, phase:2, accepted:s.seq == s.commit and
      (s.bad or s.recRun == s.session)} }
  action dequeue = all { s.mode == 2, s.phase == 0,
    s' = {...s, phase:1, location:1} }
  action inspectQueues = all { s.mode == 2, s.phase == 1,
    s' = {...s, phase:2, accepted:s.bad} }
  action route = all { s.mode == 2, s.phase == 2,
    s' = {...s, phase:3, location:2} }
  action executeAction = all { s.mode == 2, s.phase == 3,
    s' = {...s, phase:4, location:3} }
  action publishResult = all { s.mode == 2, s.phase == 4,
    s' = {...s, phase:5, location:4, pending:false, accepted:true} }
  val done = (s.mode == 1 and s.phase == 2) or
    (s.mode == 2 and s.phase == 5)
  action step = any { reopen,inspect,dequeue,inspectQueues,route,
    executeAction,publishResult,all { done,s' = s } }
  val safe = all {
    s.mode != 1 or not(s.accepted) or s.recRun == s.session,
    s.mode != 2 or not(s.accepted) or
      (not(s.pending) and s.location == 4)
  }
}
