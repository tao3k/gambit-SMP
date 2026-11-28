// Narrow fd/fault lifetime contract; not request-thunk or whole lifecycle proof.
// One writer, one existing selector, one cleanup and one bounded EINTR.
module abort_fd_last_consumer {
 type State={policy:int,scenario:int,instance:int,gate:bool,open:bool,
 controlUsed:bool,w:int,wref:bool,rref:bool,cref:bool,cached:int,attempts:int,pipe:bool,
 asleep:bool,acked:bool,ackInstance:int,cleanup:int,locks:bool,fault:bool,faultInstance:int,
 saved:bool,observed:bool,refused:bool,staleUse:bool,unsafeHandle:bool}
 var s:State
 pure def initial(p:int,sc:int):State={policy:p,scenario:sc,instance:1,
 gate:true,open:true,controlUsed:false,w:0,wref:false,rref:true,cref:false,cached:0,
 attempts:0,pipe:false,asleep:true,acked:false,ackInstance:0,cleanup:0,locks:true,
 fault:false,faultInstance:0,saved:false,observed:false,refused:false,
 staleUse:false,unsafeHandle:false}
 action initLive=s'=initial(0,0)
 action initEintr=s'=initial(0,1)
 action initHardFault=s'={...initial(0,2),w:1,wref:true,cached:1}
 action initCloseWithWriter=s'=initial(1,0)
 action initDropRefForRetry=s'=initial(2,1)
 action initCloseWithSelector=s'=initial(3,0)
 action initRecordAfterRelease=s'={...initial(4,2),rref:false,asleep:false,acked:true,ackInstance:1}
 action initHandleUnderLock=s'=initial(5,2)
 action initResetFault=s'={...initial(6,2),rref:false,asleep:false,acked:true,ackInstance:1}
 action initLoadBeforePin=s'=initial(7,0)
 action initStaleSelectorAck=s'={...initial(8,0),acked:true}
 action initClearFaultOnSuccess=s'={...initial(9,2),w:1,wref:true,cached:1}
 action initPartialFault=s'={...initial(10,2),w:1,wref:true,cached:1}
 action acquireWriter=all{s.w==0,s.gate,s.cleanup==0,
 s'={...s,w:1,wref:true,cached:s.instance}}
 action refuseWriter=all{s.w==0,(not(s.gate) or s.cleanup!=0),s.policy!=7,
 s'={...s,w:8,locks:false,refused:true}}
 // Late unpinned load is a negative variant, not a legal acquire.
 action loadWithoutPin=all{s.policy==7,s.w==0,s.cleanup==0,
 s'={...s,w:1,cached:s.instance}}
 action firstWrite=all{s.w==1,
 s'={...s,w:if(s.scenario==1) 2 else 3,attempts:1,
 pipe:if(s.scenario==0 and s.open and s.cached==s.instance) true else s.pipe,
 staleUse:s.staleUse or not(s.open) or s.cached!=s.instance,
 wref:if(s.scenario==1 and s.policy==2) false else s.wref}}
 action retryWrite=all{s.w==2,
 s'={...s,w:3,attempts:2,
 pipe:if(s.open and s.cached==s.instance) true else s.pipe,
 staleUse:s.staleUse or not(s.open) or s.cached!=s.instance}}
 // Fault is recorded while its fd/instance lease is still held.
 action recordOutcome=all{s.w==3,s.policy!=4,
 s'={...s,w:4,saved:true,fault:s.scenario==2 and s.policy!=10,
 faultInstance:if(s.scenario==2) s.cached else 0,
 wref:s.wref}}
 action releaseWithoutRecord=all{s.w==3,s.policy==4,s'={...s,w:9,wref:false}}
 action recordTooLate=all{s.w==9,s'={...s,w:5,saved:true,fault:true,faultInstance:s.cached}}
 action releaseWriter=all{s.w==4,s'={...s,w:5,wref:false}}
 action releaseLocks=all{s.w==5,s'={...s,w:6,locks:false}}
 action handleFault=all{s.fault,not(s.observed),
 (not(s.locks) and s.w>=6) or s.policy==5,
 s'={...s,observed:true,unsafeHandle:s.locks}}
 action finishWriter=all{s.w==6,not(s.fault) or s.observed,s'={...s,w:8}}
 action retireIntent=all{s.cleanup==0,s'={...s,cleanup:1}}
 // Cleanup uses the same live-fd discipline for its final cancellation wake.
 action acquireControl=all{s.cleanup==1,s.gate,not(s.cref),not(s.controlUsed),s.asleep,
 s'={...s,cref:true,controlUsed:true}}
 action cancellationWrite=all{s.cref,s.scenario!=2,s.open,
 s'={...s,pipe:true,cref:false}}
 action selectorReturn=all{s.rref,s.pipe,
 s'={...s,rref:false,asleep:false,acked:true,ackInstance:s.instance,pipe:false}}
 action freezeAdmission=all{s.cleanup==1,s.acked,(s.ackInstance==s.instance or s.policy==8),not(s.cref),
 s'={...s,gate:false,cleanup:2}}
 action closeFd=all{s.cleanup==2,not(s.cref),
 (not(s.wref) and not(s.rref)) or s.policy==1,
 s'={...s,open:false,cleanup:3}}
 action earlySelectorClose=all{s.policy==3,s.cleanup==1,not(s.wref),
 s'={...s,gate:false,open:false,cleanup:3}}
 action resetInstance=all{s.cleanup==3,
 (not(s.fault) and s.w==8) or s.policy==6 or s.policy==4 or s.policy==7,
 s'={...s,instance:2,cleanup:4,
 fault:if(s.policy==6) false else s.fault}}
 action clearOnLaterSuccess=all{s.policy==9,s.fault,s'={...s,fault:false}}
 val faultRetained=s.fault and s.observed and s.w==8
 val done=s.cleanup==4 and s.w==8 and not(s.fault)
 val safe=all{not(s.staleUse),not(s.unsafeHandle),
 s.open or (not(s.wref) and not(s.rref) and not(s.cref)),
 s.w!=2 or s.wref,
 s.cleanup<2 or s.cleanup>=4 or s.ackInstance==s.instance,
 not(s.fault) or s.faultInstance==s.instance,
 not(s.saved and s.scenario==2) or s.fault,
 not(s.cleanup==4 and s.fault)}
 action step=any{acquireWriter,refuseWriter,loadWithoutPin,firstWrite,
 retryWrite,recordOutcome,releaseWithoutRecord,recordTooLate,releaseWriter,releaseLocks,handleFault,finishWriter,
 retireIntent,acquireControl,cancellationWrite,selectorReturn,freezeAdmission,
 closeFd,earlySelectorClose,resetInstance,clearOnLaterSuccess,
 all{done or faultRetained,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
