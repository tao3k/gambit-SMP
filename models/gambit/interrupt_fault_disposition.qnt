// One native node or one Scheme result-mutex obligation.
// Models callback execute/release distinction and authorized target abandonment.
module interrupt_fault_disposition {
 type State={scenario:int,policy:int,kind:int,phase:int,owner:int,lock:bool,
 activeBorrow:bool,closed:bool,executions:int,releases:int,callbackError:bool,
 releaseMayReenter:bool,badUnlock:bool,callbackUnderLock:bool,reported:bool,root:bool,
 errorImmediate:bool,rawErrorStored:bool,nonPrimordial:bool,targetAuthorized:bool,ended:bool,reply:int,wrongTerminal:bool}
 var s:State
 pure def initial(sc:int,p:int):State={scenario:sc,policy:p,
 kind:if(sc>=3) 1 else 0,phase:0,owner:1,lock:false,activeBorrow:false,
 closed:false,executions:0,releases:0,callbackError:false,releaseMayReenter:false,badUnlock:false,
 callbackUnderLock:false,reported:false,root:true,errorImmediate:true,rawErrorStored:false,nonPrimordial:true,targetAuthorized:p!=6,
 ended:false,reply:0,wrongTerminal:false}
 action initCallbackSuccess=s'=initial(0,0)
 action initCallbackError=s'=initial(1,0)
 action initPendingCleanup=s'=initial(2,0)
 action initAuthorizedTargetEnd=s'=initial(3,0)
 action initAcceptedHardFault=s'=initial(4,0)
 action initDoubleUnlock=s'=initial(1,1)
 action initReleaseUnderMutex=s'={...initial(2,2),releaseMayReenter:true}
 action initReleaseActive=s'=initial(0,3)
 action initReplayError=s'=initial(1,4)
 action initReleaseExecuted=s'=initial(1,5)
 action initWrongTargetEnd=s'=initial(3,6)
 action initFakeAbandon=s'=initial(4,7)
 action initUnrootedEnd=s'={...initial(3,8),root:false}
 action initMovingErrorStored=s'={...initial(1,9),errorImmediate:false}
 action initMovingErrorNormalized=s'={...initial(1,10),errorImmediate:false}
 action initPrimordialRetained=s'={...initial(3,11),nonPrimordial:false}
 action initFakePrimordialAbandon=s'={...initial(3,12),nonPrimordial:false}
 action initReentrantDetachedCleanup=s'={...initial(2,0),releaseMayReenter:true}
 action lockQueue=all{s.phase==0,s.scenario!=2,s.scenario!=4,
 s'={...s,phase:1,lock:true}}
 action detachForCallback=all{s.phase==1,s.lock,
 s'={...s,phase:2,owner:2,activeBorrow:true}}
 action unlockBeforeCallback=all{s.phase==2,s.lock,
 s'={...s,phase:3,lock:false}}
 // callback owns the detached node. Runtime must not inspect/free it afterward.
 action callbackReturns=all{s.kind==0,s.phase==3,
 s'={...s,phase:4,owner:4,activeBorrow:false,executions:1,
 callbackError:s.scenario==1,rawErrorStored:s.policy==9}}
 action returnError=all{s.phase==4,s.callbackError,
 s'={...s,phase:5,badUnlock:s.policy==1}}
 action reacquireForSuccess=all{s.phase==4,not(s.callbackError),
 s'={...s,phase:6,lock:true}}
 action unlockSuccess=all{s.phase==6,s.lock,s'={...s,phase:5,lock:false}}
 action reportCallbackError=all{s.phase==5,s.callbackError,not(s.lock),
 not(s.reported),s'={...s,reported:true}}
 action replayCallback=all{s.policy==4,s.callbackError,s.executions==1,
 s'={...s,executions:2}}
 action releaseExecuted=all{s.policy==5,s.executions==1,s.releases==0,
 s'={...s,releases:1}}
 action closeAndDetachBatch=all{s.scenario==2,s.phase==0,
 s'={...s,phase:10,owner:3,closed:true,lock:true}}
 action unlockBatch=all{s.phase==10,s'={...s,phase:11,lock:false}}
 action releasePending=all{s.owner==3,(s.phase==11 or (s.phase==10 and not(s.releaseMayReenter)) or s.policy==2),
 s'={...s,phase:12,owner:4,releases:1,callbackUnderLock:s.lock and s.releaseMayReenter}}
 action unlockReleaseEpilogue=all{s.phase==12,s.lock,s'={...s,phase:15,lock:false}}
 action cleanupActive=all{s.policy==3,s.owner==2,
 s'={...s,releases:1,owner:4}}
 action targetEnd=all{s.kind==1,s.scenario==3,s.phase==3,
 (s.targetAuthorized and s.nonPrimordial) or s.policy==6 or s.policy==12,
 s'={...s,phase:12,ended:true,reply:2,owner:4,activeBorrow:false,
 wrongTerminal:not(s.targetAuthorized) or not(s.root) or not(s.nonPrimordial)}}
 action exitPrimordial=all{s.scenario==3,not(s.nonPrimordial),s.phase==3,
 s'={...s,phase:13,reported:true}}
 action retainHardFault=all{s.scenario==4,s.phase==0,
 s'={...s,phase:13,reported:true}}
 action fakeAbandon=all{s.policy==7,s.phase==13,
 s'={...s,reply:2,owner:4}}
 val done=(s.kind==0 and s.phase==5 and
 (not(s.callbackError) or s.reported)) or (s.phase==12 and not(s.lock)) or s.phase==15
 val retained=s.phase==13 and s.reply==0 and
 ((s.scenario==4 and s.owner==1) or (s.scenario==3 and not(s.nonPrimordial) and s.owner==2))
 val safe=all{not(s.rawErrorStored) or s.errorImmediate,not(s.badUnlock),not(s.callbackUnderLock),
 s.executions+s.releases<=1,
 not(s.activeBorrow) or s.owner==2,
 s.reply!=2 or (s.ended and s.targetAuthorized and s.root and s.nonPrimordial),
 not(s.wrongTerminal),s.kind!=1 or not(s.activeBorrow) or s.root}
 action step=any{lockQueue,detachForCallback,unlockBeforeCallback,
 callbackReturns,returnError,reacquireForSuccess,unlockSuccess,
 reportCallbackError,replayCallback,releaseExecuted,closeAndDetachBatch,
 unlockBatch,releasePending,unlockReleaseEpilogue,cleanupActive,targetEnd,retainHardFault,
 fakeAbandon,exitPrimordial,all{done or retained,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
