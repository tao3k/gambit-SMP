module thread_thunk_root {
 type State={parent:bool,registered:bool,future:bool,launched:bool,started:bool,syncDone:bool,entered:bool,unknown:bool,aborted:bool,rawUsed:bool,epoch:int,slot:int,localStamp:int}
 pure val initial:State={parent:true,registered:false,future:false,launched:false,started:false,syncDone:false,entered:false,unknown:false,aborted:false,rawUsed:false,epoch:0,slot:0,localStamp:0}
 var s:State
 action init=s'=initial
 val safe=all{s.parent or s.registered,s.registered implies (s.future and s.slot==s.epoch),s.launched implies s.registered,s.started implies s.launched,s.entered implies (s.syncDone and s.registered),s.unknown implies s.parent,s.rawUsed implies s.localStamp==s.epoch}
 // Certificate supplied by the frozen-bundle protocol, not mere target allocation.
 action registerStartup=all{s.parent,not(s.launched),not(s.aborted),s'={...s,registered:true,future:true,slot:s.epoch}}
 action launch=all{s.registered,s.future,not(s.aborted),s'={...s,launched:true}}
 action launchUnknown=all{s.parent,s.registered,not(s.aborted),s'={...s,launched:true,unknown:true}}
 action start=all{s.launched,not(s.aborted),s'={...s,started:true}}
 action copyRaw=all{s.started,not(s.entered),s'={...s,localStamp:s.slot}}
 action syncCollect=all{not(s.entered),not(s.syncDone),s.epoch<2,s'={...s,epoch:s.epoch+1,slot:if(s.registered) s.epoch+1 else s.slot}}
 action completeSync=all{s.started,s'={...s,syncDone:true}}
 action resolveLaunch=all{s.launched,s.unknown,s'={...s,unknown:false}}
 action releaseParent=all{s.registered,s.future,not(s.unknown),s'={...s,parent:false}}
 action enterFromHandle=all{s.registered,s.future,s.syncDone,not(s.unknown),s'={...s,entered:true}}
 action rejectCreate=all{s.parent,not(s.launched),not(s.started),s'={...s,registered:false,future:false,aborted:true}}
 action step=any{registerStartup,launch,launchUnknown,start,copyRaw,syncCollect,completeSync,resolveLaunch,releaseParent,enterFromHandle,rejectCreate,all{s'=s}}
 run rootedAcrossSyncTest=init.then(registerStartup).then(launch).then(start).then(copyRaw).then(releaseParent).then(syncCollect).then(completeSync).then(enterFromHandle).then(all{assert(safe and s.localStamp!=s.epoch),s'=s})
 run unknownLaunchCustodyTest=init.then(registerStartup).then(launchUnknown).then(start).then(syncCollect).then(all{assert(safe and s.parent and s.unknown),s'=s}).then(resolveLaunch).then(releaseParent).then(completeSync).then(enterFromHandle).then(all{assert(safe),s'=s})
 run rejectedCreateKeepsParentTest=init.then(registerStartup).then(rejectCreate).then(syncCollect).then(all{assert(safe and s.parent and s.aborted),s'=s})
 run staleRawControlTest=init.then(registerStartup).then(launch).then(start).then(copyRaw).then(syncCollect).then(all{s'={...s,rawUsed:true}}).then(all{assert(not(safe)),s'=s})
 run unrootedLaunchControlTest=init.then(all{s'={...s,launched:true}}).then(all{assert(not(safe)),s'=s})
 run unknownParentReleaseControlTest=init.then(registerStartup).then(launchUnknown).then(all{s'={...s,parent:false}}).then(all{assert(not(safe)),s'=s})
}
