// Native ownership/interleaving only. C source and atomic refinement are separate.
module native_device_monitor {
  type S={owner:int,depth:int,pending:bool,closed:bool,alive:bool,
    linked:bool,allocated:bool,registered:bool,terminal:bool,consumed:bool,ready:bool,borrowed:bool,cleaning:bool}
  val initial:S={owner:0,depth:0,pending:false,closed:false,alive:true,
    linked:false,allocated:false,registered:false,terminal:false,consumed:false,ready:false,borrowed:false,cleaning:false}
  var s:S
  action init=s'=initial
  action enter=all{s.owner==0,not(s.pending) or s.closed,
    s'={...s,owner:1,depth:1}}
  action nest=all{s.owner==1,s.depth<2,s'={...s,depth:s.depth+1}}
  action exit=all{s.owner==1,s.depth>0,
    s'=if(s.depth==1){...s,owner:0,depth:0}else{...s,depth:s.depth-1}}
  action spawn=all{s.owner==1,not(s.registered),s'={...s,allocated:true}}
  action commit=all{s.owner==1,s.allocated,not(s.closed),
    s'={...s,registered:true,linked:true}}
  action childExit=all{s.allocated,s'={...s,terminal:true}}
  action signal=s'={...s,pending:true}
  action beginReap=all{s.owner==0,s.pending,not(s.closed),s.alive,
    s'={...s,owner:2,pending:false,borrowed:s.linked or s.cleaning}}
  action reap=all{s.owner==2,s.terminal,
    s'={...s,consumed:true,ready:s.registered}}
  action retryReap=all{s.owner==2,s.pending,s'={...s,pending:false}}
  action endReap=all{s.owner==2,not(s.pending),s'={...s,owner:0,borrowed:false}}
  action unlink=all{s.owner==1,s.linked,s'={...s,linked:false}}
  action free=all{s.owner==1,not(s.linked),not(s.cleaning),s'={...s,allocated:false}}
  action close=all{s.owner==1,s'={...s,closed:true}}
  action destroy=all{s.owner==1,s.closed,not(s.linked),not(s.cleaning),s'={...s,alive:false}}
  action beginCleanup=all{s.owner==1,s.linked,not(s.cleaning),s'={...s,linked:false,cleaning:true}}
  action failCleanup=all{s.owner==1,s.cleaning,s'={...s,linked:true,cleaning:false}}
  action settleCleanup=all{s.owner==1,s.cleaning,s'={...s,allocated:false,cleaning:false}}
  val safe=(s.owner!=2 or s.alive) and
    (not(s.linked) or s.allocated) and
    (s.depth==0 or s.owner==1) and (not(s.borrowed) or (s.owner==2 and s.allocated)) and (not(s.cleaning) or (s.alive and s.allocated))
  // Successful creation is serialized through registration. Error-without-port
  // keeps kernel-parent reaping responsibility; it is not a successful delivery.
  val delivered=not(s.consumed) or s.ready
  action step=any{enter,nest,exit,spawn,commit,childExit,signal,beginReap,reap,
    retryReap,endReap,unlink,free,close,destroy,beginCleanup,failCleanup,settleCleanup,s'=s}
  run earlyExitRegisteredBeforeReapTest=init.then(enter).then(spawn).then(childExit)
    .then(signal).then(commit).then(exit).then(beginReap).then(reap).then(endReap)
    .expect(safe and delivered and s.ready)
  run nestedRegistrationTest=init.then(enter).then(spawn).then(nest).then(commit)
    .then(signal).then(exit).expect(safe and s.owner==1 and s.pending and s.depth==1)
  run pendingSurvivesUnlockTest=init.then(enter).then(signal).then(exit)
    .then(beginReap).expect(safe and s.owner==2)
  run signalAtReaperExitTest=init.then(signal).then(beginReap).then(signal)
    .then(retryReap).then(endReap).expect(safe and s.owner==0)
  run closePreventsLateReaderTest=init.then(enter).then(close).then(destroy)
    .then(exit).then(signal).expect(safe and s.closed and not(s.alive))
  run unknownCleanupRetainedTest=init.then(enter).then(spawn).then(commit).then(beginCleanup)
    .then(exit).then(enter).then(close).expect(safe and s.cleaning and s.alive and s.allocated)
  run failedCloseReturnsOwnershipTest=init.then(enter).then(spawn).then(commit).then(beginCleanup)
    .then(failCleanup).expect(safe and s.linked and not(s.cleaning))
  run finalReleaseSettlesTest=init.then(enter).then(spawn).then(commit).then(beginCleanup)
    .then(settleCleanup).then(close).then(destroy).then(exit).expect(safe and not(s.alive))
  // Retain legacy counterexamples instead of deleting the histories.
  action legacyEarlyReap=s'={...s,consumed:true,ready:s.registered}
  run legacyBirthRejectsTest=init.then(enter).then(spawn)
    .then(legacyEarlyReap).expect(not(delivered))
  action legacyFreeWhileRead=s'={...s,linked:false,allocated:false}
  run legacyReaderLifetimeRejectsTest=init.then(enter).then(spawn).then(commit).then(exit)
    .then(signal).then(beginReap).then(legacyFreeWhileRead).expect(not(safe))
  action legacyLostPending=s'={...s,pending:false,owner:0,depth:0}
  run legacyUnlockLosesWakeTest=init.then(enter).then(signal).then(legacyLostPending)
    .expect(not(s.pending))
}
