module dedicated_copy_capacity {
 // Representative envelope P=2,H=16,C=13,G=5,B=14,terminal/execution reserve E=1.
 // sourceN stays old epoch; actual target growth never increases the source envelope.
 type State={sourceN:int,actual:int,target:int,extra:int,strategy:int,outcome:int,retired:int,charged:int,frozen:bool,attempted:bool,unknown:bool,retained:bool,sealed:bool,collecting:bool,cleaned:bool}
 pure val initial:State={sourceN:4,actual:4,target:6,extra:0,strategy:0,outcome:0,retired:0,charged:0,frozen:false,attempted:false,unknown:false,retained:false,sealed:false,collecting:false,cleaned:false}
 var s:State
 action init=s'=initial
 val safe=all{s.sourceN==4,
 s.target==6,
 s.actual>=4,
 s.actual<=6,
 s.actual==4+s.extra,
 s.strategy==0 or s.strategy==2,
 s.outcome>=0,
 s.outcome<=2,
 s.charged>=0,
 s.charged<=14,
 s.retired>=0,
 9*s.retired<=s.charged,
 s.strategy==2 implies s.frozen,
 s.attempted implies s.frozen,
 s.unknown implies (s.attempted and s.retained and not(s.sealed) and not(s.cleaned)),
 s.sealed implies (s.frozen and s.strategy==2 and s.outcome==1 and not(s.unknown) and s.actual>=s.target and not(s.cleaned)),
 s.outcome==1 implies s.sealed,
 s.outcome==2 implies (s.attempted and not(s.sealed) and not(s.unknown) and s.retained),
 s.collecting implies s.sealed,
 s.cleaned implies (s.outcome==2 and s.actual==4 and s.extra==0 and not(s.unknown))}
 action freeze=all{not(s.frozen),s'={...s,frozen:true}}
 action sharedUnsuitable=all{s.frozen,not(s.sealed),s.strategy==0,s'={...s,strategy:2}}
 action growFull=all{s.frozen,s.strategy==2,not(s.sealed),not(s.attempted),not(s.unknown),not(s.cleaned),s'={...s,actual:6,extra:2,attempted:true}}
 action growPartial=all{s.frozen,s.strategy==2,not(s.sealed),not(s.attempted),not(s.unknown),not(s.cleaned),s.actual<=5,s'={...s,actual:5,extra:1,attempted:true}}
 action growFailed=all{s.frozen,s.strategy==2,not(s.sealed),not(s.attempted),not(s.unknown),not(s.cleaned),s'={...s,attempted:true}}
 action growUnknown=all{s.frozen,s.strategy==2,not(s.sealed),not(s.attempted),not(s.unknown),not(s.cleaned),s'={...s,attempted:true,unknown:true,retained:true}}
 action resolveFull=all{s.unknown,not(s.sealed),not(s.cleaned),s'={...s,actual:6,extra:2,unknown:false}}
 action resolvePartial=all{s.unknown,not(s.sealed),not(s.cleaned),s.actual<=5,s'={...s,actual:5,extra:1,unknown:false}}
 action chooseDedicated=all{s.frozen,s.strategy==2,not(s.sealed),s.outcome==0,s.attempted,not(s.unknown),not(s.cleaned),s.actual>=s.target,s'={...s,sealed:true,outcome:1}}
 action planUnavailable=all{s.frozen,s.strategy==2,not(s.sealed),s.outcome==0,s.attempted,not(s.unknown),not(s.cleaned),s.actual<s.target,s'={...s,outcome:2,retained:true}}
 action retryPlan=all{s.outcome==2,not(s.sealed),not(s.unknown),not(s.cleaned),s'={...s,outcome:0,attempted:false}}
 action beginCopy=all{s.sealed,s.outcome==1,not(s.collecting),s'={...s,collecting:true}}
 action retireCharged=all{s.collecting,s.charged+9<=14,s'={...s,retired:s.retired+1,charged:s.charged+9}}
 action consumeOne=all{s.collecting,s.charged+1<=14,s'={...s,charged:s.charged+1}}
 action retainUnknown=all{s.frozen,not(s.cleaned),s'={...s,retained:true}}
 action cleanupKnownBatch=all{s.outcome==2,not(s.sealed),not(s.unknown),not(s.cleaned),s'={...s,actual:4,extra:0,cleaned:true}}
 action step=any{freeze,sharedUnsuitable,growFull,growPartial,growFailed,growUnknown,resolveFull,resolvePartial,chooseDedicated,planUnavailable,retryPlan,beginCopy,retireCharged,consumeOne,retainUnknown,cleanupKnownBatch,all{s'=s}}
 run dedicatedReadyTest=init.then(freeze).then(sharedUnsuitable).then(growFull).then(chooseDedicated).then(beginCopy).then(retireCharged).then(consumeOne).then(all{assert(safe and s.outcome==1 and s.retired==1),s'=s})
 run partialRetainsTest=init.then(freeze).then(sharedUnsuitable).then(growPartial).then(planUnavailable).then(all{assert(safe and s.outcome==2 and s.actual==5 and s.retained),s'=s})
 run retryCompletesTest=init.then(freeze).then(sharedUnsuitable).then(growPartial).then(planUnavailable).then(retryPlan).then(growFull).then(chooseDedicated).then(all{assert(safe and s.outcome==1 and s.actual==6),s'=s})
 run unknownRetainsTest=init.then(freeze).then(sharedUnsuitable).then(growUnknown).then(retainUnknown).then(all{assert(safe and s.unknown and s.actual==4 and s.retained and not(s.sealed)),s'=s})
 run unknownResolvedTest=init.then(freeze).then(sharedUnsuitable).then(growUnknown).then(resolveFull).then(chooseDedicated).then(all{assert(safe and s.outcome==1 and not(s.unknown)),s'=s})
 run knownCleanupTest=init.then(freeze).then(sharedUnsuitable).then(growPartial).then(planUnavailable).then(cleanupKnownBatch).then(all{assert(safe and s.cleaned and s.actual==4),s'=s})
 run failureInternalTest=init.then(freeze).then(sharedUnsuitable).then(growFailed).then(planUnavailable).then(all{assert(safe and s.outcome==2 and not(s.collecting)),s'=s})
 run partialAcceptControlTest=init.then(freeze).then(sharedUnsuitable).then(growPartial).then(all{s'={...s,sealed:true,outcome:1}}).then(all{assert(not(safe)),s'=s})
 run unknownAcceptControlTest=init.then(freeze).then(sharedUnsuitable).then(growUnknown).then(all{s'={...s,sealed:true,outcome:1}}).then(all{assert(not(safe)),s'=s})
 run feedbackCensusControlTest=init.then(freeze).then(sharedUnsuitable).then(growFull).then(all{s'={...s,sourceN:6}}).then(all{assert(not(safe)),s'=s})
 run unknownFreeControlTest=init.then(freeze).then(sharedUnsuitable).then(growUnknown).then(all{s'={...s,cleaned:true,actual:4,extra:0}}).then(all{assert(not(safe)),s'=s})
 run doubleRetirementControlTest=init.then(freeze).then(sharedUnsuitable).then(growFull).then(chooseDedicated).then(beginCopy).then(retireCharged).then(all{s'={...s,retired:2}}).then(all{assert(not(safe)),s'=s})
}
