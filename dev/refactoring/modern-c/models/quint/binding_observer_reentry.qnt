module binding_observer_reentry {
 // Interpass slice only. Callback capability and capture-retirement qualification external.
 type State={stage:int,mode:int,writers:int,demand:int,epoch:int,planEpoch:int,depth:int,observerSafe:bool,first:bool,second:bool,custody:bool,errorSeen:bool,stable:bool,closed:bool,receipt:bool,captured:bool}
 pure val initial:State={stage:0,mode:0,writers:0,demand:0,epoch:1,planEpoch:0,depth:0,observerSafe:false,first:false,second:false,custody:false,errorSeen:false,stable:true,closed:false,receipt:false,captured:false}
 var s:State
 action init=s'=initial
 val safe=all{s.stage>=0,
s.stage<=5,
s.mode>=0,
s.mode<=2,
s.writers>=0,
s.writers<=2,
s.demand>=0,
s.demand<=2,
s.epoch>=1,
s.planEpoch>=0,
s.depth>=0,
s.stage>=1 implies (s.custody and s.mode>=1),
s.first implies (s.stage>=2 and s.custody),
s.second implies (s.stage>=3 and s.first),
s.stage==2 implies s.first,
(s.stage==3 or s.stage==4) implies s.second,
s.closed implies (s.stage>=3 and s.second),
s.mode==1 implies (s.observerSafe and s.writers==0),
(s.stage>=1 and s.stable) implies s.planEpoch==s.epoch,
s.depth>0 implies s.stage==2,
((s.stage==3 or s.stage==4) and s.mode==2) implies s.demand==1,
s.captured implies s.custody,
s.receipt implies (s.stage==4 and s.closed and not(s.errorSeen) and s.stable and s.depth==0 and s.planEpoch==s.epoch and not(s.captured)),
s.stage==4 implies s.receipt}
 action plainProfile=all{s.stage==0,s'={...s,mode:1,writers:0,observerSafe:true}}
 action useOnlyProfile=all{s.stage==0,s'={...s,mode:2,writers:1,observerSafe:false}}
 action rawProfile=all{s.stage==0,s'={...s,mode:2,writers:2,observerSafe:false}}
 action seal=all{s.stage==0,s.mode>=1,s.mode<=2,s'={...s,stage:1,custody:true,planEpoch:s.epoch}}
 action firstElide=all{s.stage==1,s.mode==1,s.observerSafe,s.stable,s.planEpoch==s.epoch,s'={...s,stage:2,first:true}}
 action firstRetain=all{s.stage==1,s.mode==2,s.stable,s.planEpoch==s.epoch,s'={...s,stage:2,first:true,demand:1}}
 action enterFormatter=all{s.stage==2,s.depth>=0,s.stable,s'={...s,depth:s.depth+1}}
 action enterIOHandler=all{s.stage==2,s.depth>=0,s.stable,s.errorSeen,s'={...s,depth:s.depth+1}}
 action enterTimeout=all{s.stage==2,s.depth>=0,s.stable,s'={...s,depth:s.depth+1}}
 action enterGC=all{s.stage==2,s.depth>=0,s.stable,s'={...s,depth:s.depth+1}}
 action readObserver=all{s.stage==2,s.depth>=1,s.mode==2,s'={...s,demand:s.demand}}
 action namedDemand=all{s.stage==2,s.depth>=1,s.writers>=1,s.stable,s'={...s,demand:1}}
 action namedSupply=all{s.stage==2,s.depth>=1,s.writers>=1,s.stable,s'={...s,demand:s.demand}}
 action rawWrite=all{s.stage==2,s.depth>=1,s.writers==2,s.stable,s'={...s,demand:2}}
 action leaveHook=all{s.stage==2,s.depth>=1,s.stable,s'={...s,depth:s.depth-1}}
 action secondReadonly=all{s.stage==2,s.mode==2,s.demand==1,s.depth==0,s.stable,s.planEpoch==s.epoch,s'={...s,stage:3,second:true}}
 action secondUnobserved=all{s.stage==2,s.mode==1,s.observerSafe,s.depth==0,s.stable,s.planEpoch==s.epoch,s'={...s,stage:3,second:true}}
 action secondNormalize=all{s.stage==2,s.mode==2,s.depth==0,s.stable,s.planEpoch==s.epoch,s'={...s,stage:3,second:true,demand:1}}
 action ioFailure=all{s.stage>=1,s.stage<=3,s'={...s,errorSeen:true}}
 action compilerAbort=all{s.stage>=1,s.stage<=3,s'={...s,stage:5,depth:0,errorSeen:true}}
 action nestedCompilation=all{s.stage==2,s.depth>=1,s'={...s,epoch:s.epoch+1,stable:false}}
 action rejectStale=all{s.stage==2,not(s.stable),s'={...s,stage:5,depth:0}}
 action capture=all{s.stage==2,s.depth>=1,s'={...s,captured:true}}
 action resumeCaptured=all{s.stage==2,s.depth>=1,s.captured,s.stable,s.planEpoch==s.epoch,s'={...s,demand:s.demand}}
 action certifyNoResume=all{s.stage==3,s.captured,s'={...s,captured:false}}
 action closeOutput=all{s.stage==3,s.stable,s.depth==0,s.planEpoch==s.epoch,s'={...s,closed:true}}
 action issue=all{s.stage==3,s.closed,s.stable,s.depth==0,s.planEpoch==s.epoch,not(s.errorSeen),not(s.captured),s'={...s,stage:4,receipt:true}}
 action unknownExit=all{s.stage>=1,s.stage<=3,s'={...s,stage:5,depth:0}}
 action debugScalarPass=all{s.stage==2,s.depth>=1,s'={...s,demand:s.demand}}
 action step=any{plainProfile,useOnlyProfile,rawProfile,seal,firstElide,firstRetain,enterFormatter,enterIOHandler,enterTimeout,enterGC,readObserver,namedDemand,namedSupply,rawWrite,leaveHook,secondReadonly,secondUnobserved,secondNormalize,ioFailure,compilerAbort,nestedCompilation,rejectStale,capture,resumeCaptured,certifyNoResume,closeOutput,issue,unknownExit,debugScalarPass,all{s'=s}}
 run plainTest=init.then(plainProfile).then(seal).then(firstElide).then(enterFormatter).then(leaveHook).then(secondUnobserved).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.demand==0),s'=s})
 run readerTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(readObserver).then(leaveHook).then(secondReadonly).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.demand==1),s'=s})
 run canonicalWritersTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(namedSupply).then(namedDemand).then(namedSupply).then(leaveHook).then(secondReadonly).then(closeOutput).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run rawThenNormalizeTest=init.then(rawProfile).then(seal).then(firstRetain).then(enterFormatter).then(rawWrite).then(leaveHook).then(secondNormalize).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.demand==1),s'=s})
 run rawThenRestoreTest=init.then(rawProfile).then(seal).then(firstRetain).then(enterFormatter).then(rawWrite).then(namedDemand).then(leaveHook).then(secondReadonly).then(closeOutput).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run ioHandlerReturnsTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(ioFailure).then(enterIOHandler).then(namedDemand).then(leaveHook).then(secondReadonly).then(closeOutput).then(all{assert(safe and s.errorSeen and not(s.receipt)),s'=s})
 run timeoutTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterTimeout).then(namedSupply).then(leaveHook).then(secondReadonly).then(closeOutput).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run gcJobTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterGC).then(namedDemand).then(leaveHook).then(secondReadonly).then(closeOutput).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run nestedTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(nestedCompilation).then(rejectStale).then(all{assert(safe and s.custody and not(s.receipt)),s'=s})
 run compilerEscapeTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(compilerAbort).then(all{assert(safe and s.custody and s.stage==5),s'=s})
 run multiShotTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(capture).then(resumeCaptured).then(resumeCaptured).then(leaveHook).then(secondReadonly).then(closeOutput).then(all{assert(safe and s.captured and not(s.receipt)),s'=s})
 run qualifiedRetirementTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(capture).then(leaveHook).then(secondReadonly).then(certifyNoResume).then(closeOutput).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run rawSkipControlTest=init.then(rawProfile).then(seal).then(firstRetain).then(enterFormatter).then(rawWrite).then(leaveHook).then(all{s'={...s,stage:3,second:true}}).then(all{assert(not(safe)),s'=s})
 run staleControlTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(all{s'={...s,epoch:s.epoch+1}}).then(all{assert(not(safe)),s'=s})
 run returnedErrorControlTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(ioFailure).then(secondReadonly).then(closeOutput).then(all{s'={...s,stage:4,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run captureDebtControlTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(capture).then(leaveHook).then(secondReadonly).then(closeOutput).then(all{s'={...s,stage:4,receipt:true}}).then(all{assert(not(safe)),s'=s})
 run firstElisionControlTest=init.then(plainProfile).then(seal).then(all{s'={...s,observerSafe:false}}).then(all{assert(not(safe)),s'=s})
 run debugScalarTest=init.then(plainProfile).then(seal).then(firstElide).then(enterFormatter).then(debugScalarPass).then(leaveHook).then(secondUnobserved).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.demand==0),s'=s})
 run nestedFormatterTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(enterFormatter).then(namedDemand).then(leaveHook).then(leaveHook).then(secondReadonly).then(closeOutput).then(issue).then(all{assert(safe and s.receipt and s.depth==0),s'=s})
 run nestedErrorHandlerTest=init.then(useOnlyProfile).then(seal).then(firstRetain).then(enterFormatter).then(ioFailure).then(enterIOHandler).then(readObserver).then(leaveHook).then(leaveHook).then(secondReadonly).then(closeOutput).then(all{assert(safe and s.depth==0 and s.errorSeen and not(s.receipt)),s'=s})
}
