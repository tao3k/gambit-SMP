module shard_retirement_cut {
 type State={a:int,b:int,transit:int,fromA:bool,closed:bool,sealedA:bool,sealedB:bool,freed:bool}
 pure val initial:State={a:1,b:0,transit:0,fromA:true,closed:false,sealedA:false,sealedB:false,freed:false}
 var s:State
 action init=s'=initial
 val safe=all{s.a>=0,s.b>=0,s.transit>=0,s.transit<=2,
 s.sealedA implies s.a==0,s.sealedB implies s.b==0,
 s.transit==1 implies (if(s.fromA) s.a>0 else s.b>0),
 s.transit==2 implies (s.a>0 and s.b>0),
 s.freed implies (s.closed and s.sealedA and s.sealedB and s.a==0 and s.b==0 and s.transit==0)}
 action beginA=all{s.a>0,s.transit==0,not(s.freed),s'={...s,transit:1,fromA:true}}
 action beginB=all{s.b>0,s.transit==0,not(s.freed),s'={...s,transit:1,fromA:false}}
 action reserveTarget=all{s.transit==1,(if(s.fromA) not(s.sealedB) else not(s.sealedA)),s'={...s,transit:2,a:(if(s.fromA) s.a else s.a+1),b:(if(s.fromA) s.b+1 else s.b)}}
 action releaseSource=all{s.transit==2,s'={...s,transit:0,a:(if(s.fromA) s.a-1 else s.a),b:(if(s.fromA) s.b else s.b-1)}}
 action abortTransfer=all{s.transit==1,s'={...s,transit:0}}
 action finishA=all{s.a>0,s.transit==0,s'={...s,a:s.a-1}}
 action finishB=all{s.b>0,s.transit==0,s'={...s,b:s.b-1}}
 action close=all{s'={...s,closed:true}}
 action sealA=all{s.closed,s.a==0,s.transit==0,s'={...s,sealedA:true}}
 action sealB=all{s.closed,s.b==0,s.transit==0,s'={...s,sealedB:true}}
 action retire=all{s.closed,s.sealedA,s.sealedB,s.a==0,s.b==0,s.transit==0,s'={...s,freed:true}}
 action step=any{beginA,beginB,reserveTarget,releaseSource,abortTransfer,finishA,finishB,close,sealA,sealB,retire,all{s'=s}}
 run overlapTransferTest=init.then(beginA).then(reserveTarget).then(all{assert(safe and s.a+s.b==2),s'=s}).then(releaseSource).then(close).then(sealA).then(finishB).then(sealB).then(retire).then(all{assert(safe),s'=s})
 run closedTargetRetainsSourceTest=init.then(close).then(sealB).then(beginA).then(all{assert(safe and s.a==1 and s.transit==1),s'=s}).then(abortTransfer).then(finishA).then(sealA).then(retire).then(all{assert(safe),s'=s})
 run roundTripTest=init.then(beginA).then(reserveTarget).then(releaseSource).then(beginB).then(reserveTarget).then(releaseSource).then(all{assert(safe and s.a==1 and s.b==0),s'=s})
 run zeroBeforeTargetControlTest=init.then(beginA).then(all{s'={...s,a:0}}).then(all{assert(not(safe)),s'=s})
 run localZeroRetirementControlTest=init.then(close).then(sealB).then(all{s'={...s,freed:true}}).then(all{assert(not(safe)),s'=s})
 run publishIntoSealedControlTest=init.then(close).then(sealB).then(beginA).then(all{s'={...s,transit:2,b:1}}).then(all{assert(not(safe)),s'=s})
}
