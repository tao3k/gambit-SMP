module frame_chunk_coverage {
 // Word offsets within one retained section, never C pointers.
 type State={lo:int,hi:int,ha:int,hb:int,fsa:int,fsb:int,la:int,lb:int,term:int,custody:int,ai:bool,bi:bool,ar:bool,br:bool,aseal:bool,bseal:bool,closed:bool,marker:bool,deferred:bool,aliasesClosed:bool}
 pure val initial:State={lo:101,hi:112,ha:101,hb:107,fsa:4,fsb:2,la:1,lb:0,term:111,custody:0,ai:false,bi:false,ar:false,br:false,aseal:false,bseal:false,closed:false,marker:false,deferred:false,aliasesClosed:false}
 var s:State
 action init=s'=initial
 val safe=all{
 s.lo==s.ha,s.hb==s.ha+s.fsa+2,s.term==s.hb+s.fsb+2,s.hi==s.term+1,
 s.fsa>0,s.fsb>0,s.la>=0,s.la<s.fsa,s.lb>=0,s.lb<s.fsb,
 s.custody>=0,s.custody<=3,
 s.aseal implies (s.ai and s.ar),s.bseal implies (s.bi and s.br),
 s.ar implies s.ai,s.br implies s.bi,
 s.closed implies (s.ai and s.bi and s.marker),
 s.deferred implies (s.closed and s.custody==0),
 s.custody>=1 implies (s.aseal and s.bseal and s.closed and s.marker and s.aliasesClosed and not(s.deferred))}
 action initializeA=all{s.custody==0,not(s.ai),s'={...s,ai:true}}
 action initializeB=all{s.custody==0,s.ai,not(s.bi),s'={...s,bi:true}}
 action registerA=all{s.custody==0,s.ai,s'={...s,ar:true}}
 action registerB=all{s.custody==0,s.bi,s'={...s,br:true}}
 action sealA=all{s.custody==0,s.ai,s.ar,s.bi,s'={...s,aseal:true}}
 action sealB=all{s.custody==0,s.bi,s.br,s'={...s,bseal:true}}
 action closeChunk=all{s.custody==0,s.ai,s.bi,s'={...s,closed:true,marker:true}}
 action deferClosed=all{s.custody==0,s.closed,s'={...s,deferred:true}}
 action closeAliases=all{s.custody==0,s'={...s,aliasesClosed:true}}
 action mutateA=all{s.custody==0,s.ai,not(s.aliasesClosed),s'={...s,aseal:false}}
 action publishChunk=all{s.custody==0,s.closed,s.marker,s.aseal,s.bseal,s.aliasesClosed,s'={...s,custody:1,deferred:false}}
 action claim=all{s.custody==1,s'={...s,custody:2}}
 action completeScan=all{s.custody==2,s'={...s,custody:3}}
 action step=any{initializeA,initializeB,registerA,registerB,sealA,sealB,closeChunk,deferClosed,closeAliases,mutateA,publishChunk,claim,completeScan,all{s'=s}}
 action both=initializeA.then(registerA).then(initializeB).then(registerB)
 run delayedWholeChunkTest=init.then(both).then(sealA).then(closeChunk).then(deferClosed).then(sealB).then(closeAliases).then(publishChunk).then(claim).then(completeScan).then(all{assert(safe and s.custody==3),s'=s})
 run lastFramePendingTest=init.then(both).then(sealA).then(closeChunk).then(all{assert(safe and not(s.bseal) and s.custody==0),s'=s})
 run aliasRevocationTest=init.then(both).then(sealA).then(mutateA).then(sealA).then(sealB).then(closeChunk).then(closeAliases).then(publishChunk).then(all{assert(safe),s'=s})
 run unregisteredControlTest=init.then(both).then(sealA).then(sealB).then(closeChunk).then(closeAliases).then(all{s'={...s,custody:1,br:false}}).then(all{assert(not(safe)),s'=s})
 run partialChunkControlTest=init.then(both).then(sealA).then(closeChunk).then(closeAliases).then(all{s'={...s,custody:1}}).then(all{assert(not(safe)),s'=s})
 run staleAliasControlTest=init.then(both).then(sealA).then(sealB).then(closeChunk).then(closeAliases).then(publishChunk).then(all{s'={...s,aseal:false}}).then(all{assert(not(safe)),s'=s})
 run markerLostControlTest=init.then(both).then(sealA).then(sealB).then(closeChunk).then(closeAliases).then(all{s'={...s,custody:1,marker:false}}).then(all{assert(not(safe)),s'=s})
}
