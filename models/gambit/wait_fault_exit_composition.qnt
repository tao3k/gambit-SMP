// One bounded transition system for native wait -> unlocked coordinator -> VM exit.
// Source-required mechanisms remain premises to implement, not existing guarantees.
module wait_fault_exit_composition {
 type State={path:int,bug:int,phase:int,pLock:bool,deviceLock:bool,
 armed:bool,fault:bool,writer:bool,selector:bool,waitInstance:int,ackInstance:int,
 originalDeadline:int,deviceDeadline:int,internalExpired:bool,timerReady:bool,
 registered:bool,vmRoot:bool,controlQueued:bool,mapped:bool,p0:bool,claims:int,
 gc:int,recordEpoch:int,frameEpoch:int,errorEpoch:int,oldCohort:int,privateWork:bool,
 jobsFailed:bool,errorRoot:bool,suffixRoot:bool,markers:int,requests:int,
 rawOpaque:bool,retained:bool,terminated:bool,freed:bool,bad:bool,handoffWitness:bool,deviceGroupOwned:bool,pendingDevices:int}
 var s:State
 pure def initial(p:int,b:int):State={path:p,bug:b,phase:0,pLock:false,deviceLock:false,
 armed:false,fault:false,writer:true,selector:false,waitInstance:2,ackInstance:2,
 originalDeadline:3,deviceDeadline:3,internalExpired:false,timerReady:false,
 registered:false,vmRoot:false,controlQueued:false,mapped:false,p0:true,claims:0,
 gc:0,recordEpoch:0,frameEpoch:0,errorEpoch:0,oldCohort:2,privateWork:true,
 jobsFailed:false,errorRoot:false,suffixRoot:true,markers:1,requests:2,
 rawOpaque:p==4,retained:false,terminated:false,freed:false,bad:false,handoffWitness:false,deviceGroupOwned:true,pendingDevices:2}
 action initDevices=s'=initial(0,0)
 action initIdle=s'=initial(1,0)
 action initJobsFail=s'=initial(2,0)
 action initWorkerFault=s'=initial(3,0)
 action initOpaqueRetain=s'=initial(4,0)
 action initJoinFailureRetain=s'=initial(5,0)
 action initNativeCloseFailureRetain=s'=initial(6,0)
 action initNoPrearmedReturn=s'=initial(0,1)
 action initEarlyDeviceTimer=s'=initial(0,2)
 action initOverwriteDeadline=s'=initial(0,3)
 action initPStillLocked=s'=initial(0,4)
 action initUnregisteredCarrier=s'=initial(0,5)
 action initDuplicateCoordinator=s'=initial(0,6)
 action initWrongProcessor=s'=initial(3,7)
 action initRecordUnrooted=s'=initial(0,8)
 action initGcStaleFrame=s'=initial(0,9)
 action initShrinkBeforeGc=s'=initial(0,10)
 action initDropPrivateWork=s'=initial(0,11)
 action initLoseExitSuffix=s'=initial(2,12)
 action initLoseCaughtError=s'=initial(2,13)
 action initStaleWaitAck=s'=initial(0,14)
 action initKillReturnableMarker=s'=initial(0,15)
 action initFreeWithWriter=s'=initial(0,16)
 action initOpaqueFakeExit=s'=initial(4,17)
 action initStaleCaughtError=s'=initial(2,18)
 action initNoPrivateHandoffWitness=s'=initial(0,19)
 action initFreeDeviceGroupEarly=s'=initial(0,20)
 action registerCarrier=all{s.phase==0,
 s'={...s,phase:1,registered:s.bug!=5,vmRoot:true,pLock:s.path!=1}}
 action commitNativeWait=all{s.phase==1,
 s'={...s,phase:2,armed:s.bug!=1,selector:true}}
 action hardWriteFailure=all{s.phase==2,not(s.fault),s'={...s,fault:true}}
 action returnNative=all{s.phase==2,s.fault,s.armed,
 s'={...s,phase:3,internalExpired:true,deviceLock:s.path!=1,
 timerReady:s.bug==2,deviceDeadline:if(s.bug==3) 1 else s.deviceDeadline}}
 action finishCondvarProtocol=all{s.phase==3,
 s'={...s,phase:4,deviceLock:false}}
 action finishIdleListProtocol=all{s.phase==4,
 s'={...s,phase:5,selector:false,ackInstance:if(s.bug==14) 1 else s.waitInstance}}
 action releaseCallerP=all{s.phase==5,
 s'={...s,phase:6,pLock:s.bug==4}}
 action claimFaultDomain=all{s.phase==6,
 s'={...s,phase:7,claims:if(s.bug==6) 2 else 1,vmRoot:s.bug!=8}}
 // Real implementation must enqueue a registered pinned Scheme thread, not call
 // a procedure from an idle native selector or use another result-mutex request.
 action queueControlThread=all{s.phase==7,
 s'={...s,phase:8,controlQueued:true,p0:s.bug!=7}}
 action restoreControlThread=all{s.phase==8,s.controlQueued,
 s'={...s,phase:9,controlQueued:false,mapped:true,
 oldCohort:if(s.bug==10) 1 else s.oldCohort,
 privateWork:s.bug!=11,markers:if(s.bug==15) 3 else s.markers}}
 action gcRound=all{s.phase==9,s.gc<2,
 s'={...s,gc:s.gc+1,recordEpoch:s.gc+1,
 frameEpoch:if(s.bug==9) s.frameEpoch else s.gc+1}}
 action runExitJobs=all{s.phase==9,s.gc==2,
 s'={...s,phase:10,jobsFailed:s.path==2,
 errorRoot:s.path==2 and s.bug!=13,errorEpoch:s.gc,suffixRoot:s.bug!=12}}
 action gcAfterJobs=all{s.phase==10,s.gc==2,
 s'={...s,gc:3,recordEpoch:3,frameEpoch:3,
 errorEpoch:if(s.bug==18) s.errorEpoch else 3}}
 action retainOpaque=all{s.phase==10,s.gc==3,s.rawOpaque,s.bug!=17,
 s'={...s,phase:99,retained:true}}
 action prepareControlledExit=all{s.phase==10,s.gc==3,not(s.rawOpaque) or s.bug==17,
 s'={...s,phase:11,bad:s.bug==17}}
 // Each real host invocation needs its own matching, all-path finalizer.
 action invocationBecomesNonreturnable=all{s.phase==11,
 s'={...s,phase:12,markers:2}}
 action finishInvocationFinalizers=all{s.phase==12,
 s'={...s,phase:13,markers:3,mapped:false}}
 action collectiveCommit=all{s.phase==13,
 s'={...s,phase:14,oldCohort:1,privateWork:false,handoffWitness:s.bug!=19}}
 action retainJoinFailure=all{s.phase==14,s.path==5 or s.path==6,
 s'={...s,phase:98,retained:true}}
 action writerFinishes=all{s.fault,s.writer,s'={...s,writer:false}}
 // No fabricated per-request reply: VM terminal disposition consumes the scope.
 action deviceCloseOne=all{s.phase==14,s.path!=5,s.path!=6,s.pendingDevices>0,
 s'={...s,pendingDevices:s.pendingDevices-1,deviceGroupOwned:s.bug!=20}}
 action markVmTerminated=all{s.phase==14,s.path!=5,s.path!=6,s.pendingDevices==0,
 s'={...s,phase:15,terminated:true,requests:0,deviceGroupOwned:false}}
 action releaseVmStorage=all{s.phase==15,not(s.writer) or s.bug==16,
 s'={...s,phase:16,vmRoot:false,errorRoot:false,suffixRoot:false,freed:true}}
 val safe=all{
 not(s.phase==2 and s.fault and not(s.armed)),
 not(s.timerReady) or not(s.internalExpired),
 s.deviceDeadline==s.originalDeadline,
 s.claims==0 or (not(s.pLock) and not(s.deviceLock)),
 s.claims<=1,
 s.phase<7 or s.requests==0 or s.vmRoot,
 not(s.controlQueued or s.mapped) or s.registered,
 not(s.mapped) or (s.p0 and s.vmRoot and s.frameEpoch==s.gc),
 s.phase!=9 or (s.oldCohort==2 and s.privateWork),
 s.phase<10 or s.freed or s.suffixRoot,
 not(s.jobsFailed) or s.freed or (s.errorRoot and s.errorEpoch==s.gc),
 not(s.claims>0) or s.ackInstance==s.waitInstance,
 s.markers!=3 or s.phase>=13,
 not(s.freed) or (not(s.writer) and not(s.selector) and s.markers==3 and s.terminated and s.requests==0),
 s.oldCohort==2 or s.handoffWitness,
 not(s.retained) or (s.vmRoot and s.requests==2 and
 ((s.rawOpaque and s.markers==1 and s.oldCohort==2) or
 ((s.path==5 or s.path==6) and s.markers==3 and s.oldCohort==1))),
 s.pendingDevices==0 or s.deviceGroupOwned,
 not(s.bad)}
 val done=s.freed
 action step=any{registerCarrier,commitNativeWait,hardWriteFailure,returnNative,
 finishCondvarProtocol,finishIdleListProtocol,releaseCallerP,claimFaultDomain,
 queueControlThread,restoreControlThread,gcRound,runExitJobs,gcAfterJobs,retainOpaque,
 prepareControlledExit,invocationBecomesNonreturnable,finishInvocationFinalizers,
 collectiveCommit,retainJoinFailure,writerFinishes,deviceCloseOne,markVmTerminated,releaseVmStorage,
 all{done or s.retained,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
