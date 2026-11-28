// Finite contract experiment, not C refinement. Positive VM landing is proposed.
module accepted_interrupt_terminal {
 type State={mode:int,bug:int,phase:int,queue:int,executed:int,released:int,
 lock:bool,debt:bool,borrow:bool,writer:bool,fdOpen:bool,root:bool,
 reply:int,suffix:bool,errorSaved:bool,nonreturnable:bool,markerLive:bool,
 rawExit:bool,retained:bool,bad:bool}
 var s:State
 pure def initial(m:int,b:int):State={mode:m,bug:b,phase:0,queue:2,
 executed:0,released:0,lock:false,debt:true,borrow:false,writer:true,
 fdOpen:true,root:true,reply:0,suffix:true,errorSaved:false,
 nonreturnable:false,markerLive:true,rawExit:false,retained:false,bad:false}
 action initCallbackError=s'=initial(0,0)
 action initOrdinaryEnd=s'=initial(1,0)
 action initVmLanding=s'=initial(2,0)
 action initJobsFailureLanding=s'=initial(3,0)
 action initHardWakeRetained=s'=initial(4,0)
 action initClearRemainingDebt=s'=initial(0,1)
 action initReplayExecuted=s'=initial(0,2)
 action initPrimordialFakeAbandon=s'=initial(2,3)
 action initLostJobSuffix=s'=initial(3,4)
 action initEarlyFdClose=s'=initial(2,5)
 action initEarlyMarkerKill=s'=initial(2,6)
 action initFailedCleanupFrees=s'=initial(4,7)
 action initDropActiveRoot=s'=initial(1,8)
 // Publisher owns the wake outcome after queue acceptance, even on hard failure.
 action writerFinishes=all{s.writer,s'={...s,writer:false}}
 action callback=all{s.mode==0,s.phase==0,
 s'={...s,phase:1,queue:1,executed:1,lock:false,debt:s.bug!=1}}
 // non-NO_ERR leaves the flag/trip set. Never requeue the executed header.
 action nextService=all{s.mode==0,s.phase==1,s.debt,
 s'={...s,phase:2,queue:0,executed:if(s.bug==2) 3 else 2,debt:false}}
 action enterTarget=all{s.mode==1,s.phase==0,
 s'={...s,phase:1,queue:1,borrow:true,root:s.bug!=8}}
 action ordinaryAbandon=all{s.mode==1,s.phase==1,s.root,
 s'={...s,phase:2,reply:2,queue:0,borrow:false,released:2}}
 // These are extra VM coordinator premises, absent from current raw-exit path.
 action claimVmLanding=all{(s.mode==2 or s.mode==3),s.phase==0,
 s'={...s,phase:1,borrow:true,reply:if(s.bug==3) 2 else 0}}
 action finishJobs=all{(s.mode==2 or s.mode==3),s.phase==1,
 s'={...s,phase:2,errorSaved:s.mode==3,suffix:s.bug!=4,
 bad:s.bug==4,nonreturnable:false}}
 action settleVmRequests=all{(s.mode==2 or s.mode==3),s.phase==2,
 s'={...s,phase:3,queue:0,released:2,borrow:false,debt:false}}
 action matchingBoundary=all{(s.mode==2 or s.mode==3),s.phase==3,
 s'={...s,phase:4,nonreturnable:true}}
 action finalizeMarker=all{s.phase==4,s.nonreturnable,
 s'={...s,phase:5,markerLive:false}}
 action closeResources=all{s.phase==5,not(s.writer),not(s.borrow),s.queue==0,
 s'={...s,phase:6,fdOpen:false,rawExit:true}}
 action retainHardFault=all{s.mode==4,s.phase==0,
 s'={...s,phase:7,retained:true}}
 action earlyClose=all{s.bug==5,s.phase==1,s'={...s,fdOpen:false}}
 action earlyKill=all{s.bug==6,s.phase==1,s'={...s,markerLive:false}}
 action falseCleanup=all{s.bug==7,s.phase==7,
 s'={...s,fdOpen:false,root:false,rawExit:true}}
 val done=(s.mode<=1 and s.phase==2 and not(s.writer)) or s.phase==6
 val safe=all{
 s.queue==0 or s.debt,
 s.executed+s.released<=2,
 s.reply!=2 or s.mode==1,
 not(s.borrow) or s.root,
 s.fdOpen or (not(s.writer) and not(s.borrow) and s.queue==0),
 s.markerLive or s.nonreturnable,
 not(s.rawExit) or (not(s.markerLive) and s.nonreturnable and s.queue==0),
 not(s.bad)}
 action step=any{writerFinishes,callback,nextService,enterTarget,ordinaryAbandon,
 claimVmLanding,finishJobs,settleVmRequests,matchingBoundary,finalizeMarker,
 closeResources,retainHardFault,earlyClose,earlyKill,falseCleanup,
 all{done or s.retained,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
