module fdset_abort_setup_ownership {
  type State = { policy: str, fault: int, async: bool, parts: int,
    phase: str, scratch: int, buffers: int, allocated: int, freed: int,
    pipe: bool, ready: bool, failed: bool, cleanups: int }
  var s: State
  pure def initial(policy: str, fault: int, async: bool, parts: int): State = {
    policy:policy,fault:fault,async:async,parts:parts,phase:"allocate",
    scratch:0,buffers:0,allocated:0,freed:0,pipe:false,ready:false,
    failed:false,cleanups:0
  }
  action init = {
    nondet parts=Set(2,3).oneOf()
    nondet async=Set(false,true).oneOf()
    nondet fault=(if (async) Set(0,1,2,4,5,6).union(if (parts==3) Set(3) else Set())
                 else Set(0,1,2).union(if (parts==3) Set(3) else Set())).oneOf()
    s'=initial("owned",fault,async,parts)
  }
  action initOldCleanup=s'=initial("old",0,true,3)
  action initReadyOnly=s'=initial("ready-only",4,true,3)
  action initForgotReset=s'=initial("forget-reset",0,true,3)
  action allocate=all { s.phase=="allocate",s.scratch<s.parts,
    s'=if (s.fault==s.scratch+1) { ...s,phase:"partial-failure",failed:true }
       else { ...s,scratch:s.scratch+1,allocated:s.allocated+1 } }
  action partialRollback=all { s.phase=="partial-failure",
    s'={ ...s,freed:s.freed+s.scratch,scratch:0,phase:"returned-failure" } }
  action commitBuffers=all { s.phase=="allocate",s.scratch==s.parts,
    s'={ ...s,buffers:s.scratch,scratch:0,phase:if (s.async) "pipe" else "publish" } }
  action openPipe=all { s.phase=="pipe",
    s'=if (s.fault==4) { ...s,phase:"rollback",failed:true }
       else { ...s,pipe:true,phase:"fcntl-write" } }
  action configureWrite=all { s.phase=="fcntl-write",
    s'=if (s.fault==5) { ...s,pipe:false,phase:"rollback",failed:true }
       else { ...s,phase:"fcntl-read" } }
  action configureRead=all { s.phase=="fcntl-read",
    s'=if (s.fault==6) { ...s,pipe:false,phase:"rollback",failed:true }
       else { ...s,phase:"publish" } }
  action rollback=all { s.phase=="rollback",
    s'=if (Set("old","ready-only").contains(s.policy)) { ...s,phase:"returned-failure" }
       else { ...s,freed:s.freed+s.buffers,buffers:0,phase:"returned-failure" } }
  action publish=all { s.phase=="publish",s'={ ...s,ready:true,phase:"use" } }
  action cleanup=all { Set("use","cleaned").contains(s.phase),s.cleanups<2,
    s'={ ...s,phase:"cleaned",cleanups:s.cleanups+1,
      pipe:if (s.async and s.ready) false else s.pipe,
      ready:if (s.async) false else s.ready,
      freed:if (s.policy=="old") s.freed else s.freed+s.buffers,
      buffers:if (Set("old","forget-reset").contains(s.policy)) s.buffers else 0 } }
  val terminal=s.phase=="returned-failure" or (s.phase=="cleaned" and s.cleanups==2)
  action hold=all { terminal,s'=s }
  action step=any { allocate,partialRollback,commitBuffers,openPipe,
    configureWrite,configureRead,rollback,publish,cleanup,hold }
  val balance=s.allocated==s.freed+s.scratch+s.buffers
  val readyOwnsPipe=not(s.async and s.ready) or s.pipe
  val rollbackComplete=(s.phase=="returned-failure").implies(
    s.failed and s.scratch==0 and s.buffers==0 and not(s.pipe) and not(s.ready))
  val cleanupComplete=(s.phase=="cleaned").implies(s.buffers==0 and not(s.pipe))
  val safe=balance and readyOwnsPipe and rollbackComplete and cleanupComplete
}
