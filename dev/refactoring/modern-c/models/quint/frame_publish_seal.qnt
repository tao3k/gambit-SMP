module frame_publish_seal {
 // A is a nonterminal copied frame after one capacity rollover; cursor stays in chunk 0.
 // link: 0 old stack link, 1 hidden, 2 fixed forwarding, 3 old retag, 4 fixed retag.
 type State={managed:bool,chunk:int,cursor:int,initialized:bool,ready:bool,pending:bool,queued:bool,deferred:bool,scan:int,link:int,snapshot:int,fixed:bool,copier:bool,closed:bool}
 pure val initial:State={managed:true,chunk:0,cursor:0,initialized:false,ready:false,pending:false,queued:false,deferred:false,scan:0,link:0,snapshot: -1,fixed:false,copier:true,closed:false}
 var s:State
 action init=s'=initial
 action initLegacy=s'={...initial,managed:false}
 val safe=s.managed implies all{
 s.chunk>=0,s.chunk<=2,s.cursor==0,s.scan>=0,s.scan<=4,
 s.ready implies (s.initialized and not(s.pending) and s.fixed),
 (s.pending or s.deferred) implies s.copier,
 (s.queued or s.scan>=1) implies s.ready,
 s.scan>=2 implies s.snapshot==2,
 s.fixed implies (s.initialized and not(s.pending) and (s.link==1 or s.link==2 or s.link==4)),
(s.fixed and s.scan<=1) implies s.link==2,
s.scan==2 implies s.link==2,
s.scan==3 implies s.link==1,
s.scan==4 implies s.link==4,
 s.closed implies (not(s.copier) and not(s.pending) and not(s.deferred) and s.scan==4 and s.link==4)}
 action rollInitial=all{s.chunk==0,s'={...s,chunk:1}}
 action copyA=all{s.chunk==1,not(s.initialized),s.copier,s'={...s,initialized:true,pending:true}}
 action readyEarly=all{not(s.managed),s.initialized,not(s.ready),s'={...s,ready:true}}
 action publishEarly=all{not(s.managed),s.ready,s.chunk==1,s.cursor!=s.chunk,s'={...s,queued:true,chunk:2}}
 // Candidate: retain closed chunk locally so allocation can progress without exposing A.
 action deferChunk=all{s.managed,s.chunk==1,s.pending,not(s.ready),s'={...s,deferred:true,chunk:2}}
 action fillLink=all{s.initialized,s.pending,s.chunk==2,s.copier,s'={...s,pending:false,fixed:true,link:2}}
 action sealReady=all{s.managed,s.initialized,not(s.pending),s.fixed,not(s.ready),s'={...s,ready:true}}
 action publishDeferred=all{s.managed,s.deferred,s.ready,not(s.pending),s'={...s,deferred:false,queued:true}}
 action claim=all{s.queued,s.ready,s.scan==0,s'={...s,queued:false,scan:1}}
 action readLink=all{s.scan==1,s'={...s,scan:2,snapshot:s.link}}
 action hideLink=all{s.scan==2,(s.snapshot==0 or s.snapshot==2),s'={...s,scan:3,link:1}}
 action restoreOld=all{s.scan==3,s.snapshot==0,s'={...s,scan:4,link:3}}
 action restoreFixed=all{s.scan==3,s.snapshot==2,s'={...s,scan:4,link:4}}
 action releaseCopier=all{s.ready,not(s.pending),not(s.deferred),s'={...s,copier:false}}
 action close=all{not(s.copier),s.scan==4,s'={...s,closed:true}}
 action step=any{rollInitial,copyA,readyEarly,publishEarly,deferChunk,fillLink,sealReady,publishDeferred,claim,readLink,hideLink,restoreOld,restoreFixed,releaseCopier,close,all{s'=s}}
 action prefix=rollInitial.then(copyA)
 run managedCompleteTest=init.then(prefix).then(deferChunk).then(fillLink).then(sealReady).then(publishDeferred).then(claim).then(readLink).then(hideLink).then(restoreFixed).then(releaseCopier).then(close).then(all{assert(safe and s.closed),s'=s})
 run legacyLostFixupTest=initLegacy.then(prefix).then(readyEarly).then(publishEarly).then(claim).then(readLink).then(hideLink).then(fillLink).then(restoreOld).then(all{assert(s.fixed and s.link==3),s'=s})
 run firstChunkPrivateTest=init.then(all{assert(s.cursor==s.chunk),s'=s}).then(rollInitial).then(all{assert(s.cursor!=s.chunk),s'=s})
 run managedPendingBlocksReadyTest=init.then(prefix).then(deferChunk).then(all{assert(s.pending and not(s.ready) and s.copier),s'=s})
 run legacyFixBeforeScanTest=initLegacy.then(prefix).then(readyEarly).then(publishEarly).then(fillLink).then(claim).then(readLink).then(hideLink).then(restoreFixed).then(all{assert(s.link==4),s'=s})
 run earlyReadyControlTest=init.then(prefix).then(all{s'={...s,ready:true}}).then(all{assert(not(safe)),s'=s})
 run deferredOwnerLostControlTest=init.then(prefix).then(deferChunk).then(all{s'={...s,copier:false}}).then(all{assert(not(safe)),s'=s})
 run staleRestoreControlTest=init.then(prefix).then(deferChunk).then(fillLink).then(sealReady).then(publishDeferred).then(claim).then(all{s'={...s,snapshot:0,scan:2}}).then(all{assert(not(safe)),s'=s})
}
