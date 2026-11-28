module weak_done_coverage {
 // kind: 0 strong, 1 weak keys, 2 weak values, 3 weak both; mode: strong/weak/cleanup.
 type State={mode:int,kind:int,configured:bool,memKey:bool,keyLive:bool,valLive:bool,keyTraced:bool,valTraced:bool,tableDone:bool,registered:bool,willKind:int,actionSeen:bool,testatorSeen:bool,willFlag:bool,cleaned:bool,deleted:bool,keyResolved:bool,valResolved:bool,closed:bool}
 pure val initial:State={mode:0,kind:0,configured:false,memKey:true,keyLive:true,valLive:true,keyTraced:false,valTraced:false,tableDone:false,registered:false,willKind:0,actionSeen:false,testatorSeen:false,willFlag:false,cleaned:false,deleted:false,keyResolved:false,valResolved:false,closed:false}
 var s:State
 action init=s'=initial
 val safe=all{s.mode>=0,s.mode<=2,s.kind>=0,s.kind<=3,s.willKind>=0,s.willKind<=2,
 s.keyTraced implies (s.configured and s.memKey and s.keyLive and (s.kind==0 or s.kind==2)),
 s.valTraced implies (s.configured and s.valLive and (s.kind==0 or s.kind==1)),
 s.tableDone implies all{s.configured,s.registered,((s.kind==0 or s.kind==2) and s.memKey) implies s.keyTraced,(s.kind==0 or s.kind==1) implies s.valTraced},
 s.willKind==0 implies (not(s.actionSeen) and not(s.testatorSeen) and not(s.willFlag)),
 s.willKind==1 implies (s.actionSeen and (s.willFlag or s.testatorSeen)),
 s.willKind==2 implies (s.actionSeen and s.testatorSeen),
 s.willFlag implies (s.willKind==1 and not(s.testatorSeen)),
 s.mode>=1 implies s.tableDone,
 s.mode==2 implies (s.actionSeen and s.testatorSeen),
 s.cleaned implies all{s.mode==2,s.keyResolved,s.valResolved,s.deleted==(((s.kind==1 or s.kind==3) and s.memKey and not(s.keyLive)) or ((s.kind==2 or s.kind==3) and not(s.valLive)))},
 s.closed implies (s.mode==2 and s.cleaned and s.keyResolved and s.valResolved)}
 action configStrong=all{not(s.configured),s'={...s,configured:true,kind:0}}
 action configWeakKey=all{not(s.configured),s'={...s,configured:true,kind:1}}
 action configWeakVal=all{not(s.configured),s'={...s,configured:true,kind:2}}
 action configWeakBoth=all{not(s.configured),s'={...s,configured:true,kind:3}}
 action configRawKey=all{not(s.configured),s'={...s,configured:true,kind:3,memKey:false}}
 action deadKey=all{not(s.configured),s'={...s,keyLive:false}}
 action deadVal=all{not(s.configured),s'={...s,valLive:false}}
 action traceKey=all{s.configured,not(s.tableDone),s.memKey,(s.kind==0 or s.kind==2),s'={...s,keyTraced:true,keyLive:true}}
 action traceVal=all{s.configured,not(s.tableDone),(s.kind==0 or s.kind==1),s'={...s,valTraced:true,valLive:true}}
 action tableScanDone=all{s.configured,not(s.tableDone),(((s.kind==0 or s.kind==2) and s.memKey) implies s.keyTraced),((s.kind==0 or s.kind==1) implies s.valTraced),s'={...s,tableDone:true,registered:true}}
 action strongWill=all{s.mode==0,s.willKind==0,s'={...s,willKind:1,actionSeen:true,willFlag:true}}
 action enterWeak=all{s.mode==0,s.tableDone,s'={...s,mode:1}}
 action repairWill=all{s.mode==1,s.willKind==1,s.willFlag,s'={...s,testatorSeen:true,willFlag:false}}
 action freshWeakWill=all{s.mode==1,s.willKind==0,s'={...s,willKind:2,actionSeen:true,testatorSeen:true}}
 action skipDone=all{s.mode==1,(s.willKind==1 or s.tableDone),s'=s}
 action finishWeak=all{s.mode==1,s.actionSeen,s.testatorSeen,s'={...s,mode:2}}
 // Resolve means forward-or-retain-or-delete; weak entries do not become tracing roots.
 action cleanupTable=all{s.mode==2,s.registered,not(s.cleaned),s'={...s,cleaned:true,keyResolved:true,valResolved:true,deleted:(((s.kind==1 or s.kind==3) and s.memKey and not(s.keyLive)) or ((s.kind==2 or s.kind==3) and not(s.valLive)))}}
 action close=all{s.mode==2,s.cleaned,s.keyResolved,s.valResolved,s'={...s,closed:true}}
 action step=any{configStrong,configWeakKey,configWeakVal,configWeakBoth,configRawKey,deadKey,deadVal,traceKey,traceVal,tableScanDone,strongWill,enterWeak,repairWill,freshWeakWill,skipDone,finishWeak,cleanupTable,close,all{s'=s}}
 action listedWill=strongWill.then(enterWeak).then(skipDone).then(repairWill).then(finishWeak).then(cleanupTable).then(close)
 run strongTableTest=init.then(configStrong).then(traceKey).then(traceVal).then(tableScanDone).then(listedWill).then(all{assert(safe and s.closed),s'=s})
 run weakKeyTest=init.then(configWeakKey).then(traceVal).then(tableScanDone).then(listedWill).then(all{assert(safe and not(s.keyTraced) and not(s.deleted)),s'=s})
 run weakValTest=init.then(configWeakVal).then(traceKey).then(tableScanDone).then(listedWill).then(all{assert(safe and not(s.valTraced)),s'=s})
 run deadWeakBothTest=init.then(deadKey).then(configWeakBoth).then(tableScanDone).then(listedWill).then(all{assert(safe and s.deleted and not(s.keyTraced)),s'=s})
 run rawKeyTest=init.then(configRawKey).then(tableScanDone).then(listedWill).then(all{assert(safe and not(s.memKey) and not(s.keyTraced)),s'=s})
 run freshWeakWillTest=init.then(configWeakBoth).then(tableScanDone).then(enterWeak).then(freshWeakWill).then(finishWeak).then(cleanupTable).then(close).then(all{assert(safe and s.willKind==2),s'=s})
 run doneRetainsRepairDebtTest=init.then(configWeakBoth).then(tableScanDone).then(strongWill).then(enterWeak).then(skipDone).then(all{assert(safe and s.willFlag and not(s.testatorSeen)),s'=s})
 run omittedWillRepairControlTest=init.then(configWeakBoth).then(tableScanDone).then(strongWill).then(enterWeak).then(all{s'={...s,mode:2}}).then(all{assert(not(safe)),s'=s})
 run weakEdgeStrongTraceControlTest=init.then(configWeakBoth).then(all{s'={...s,keyTraced:true,keyLive:true}}).then(all{assert(not(safe)),s'=s})
 run lostTableRegistrationControlTest=init.then(configWeakBoth).then(tableScanDone).then(all{s'={...s,registered:false}}).then(all{assert(not(safe)),s'=s})
}
