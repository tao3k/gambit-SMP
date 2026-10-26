module capacity_collective {
 // Two-member publication/consumption slice. C11 reads-from and real native failure paths remain open.
 type State={generation:int,decision:int,vote0:int,vote1:int,seen0:int,seen1:int,result0:int,result1:int,published:bool,poolReady:bool,ack0:bool,ack1:bool,reader0:bool,reader1:bool,released:bool,flip0:bool,flip1:bool,retained:bool,freed:bool}
 pure val initial:State={generation:7,decision:0,vote0:0,vote1:0,seen0: -1,seen1: -1,result0:0,result1:0,published:false,poolReady:false,ack0:false,ack1:false,reader0:false,reader1:false,released:false,flip0:false,flip1:false,retained:false,freed:false}
 var s:State
 action init=s'=initial
 val safe=all{
 s.generation==7,s.decision>=0,s.decision<=2,s.vote0>=0,s.vote0<=2,s.vote1>=0,s.vote1<=2,s.result0>=0,s.result0<=2,s.result1>=0,s.result1<=2,
 s.vote0>0 implies (s.published and s.seen0==s.generation),s.vote1>0 implies (s.published and s.seen1==s.generation),
 s.vote0==1 implies s.poolReady,s.vote1==1 implies s.poolReady,
 s.vote0==0 implies s.seen0== -1,s.vote1==0 implies s.seen1== -1,
 s.decision>0 implies (s.vote0>0 and s.vote1>0),
 s.decision==1 implies (s.poolReady and s.vote0==1 and s.vote1==1),
 s.decision==2 implies (s.vote0==2 or s.vote1==2),
 s.ack0 implies (s.decision>0 and not(s.reader0)),s.ack1 implies (s.decision>0 and not(s.reader1)),
 s.reader0 implies (s.vote0>0 and not(s.ack0)),s.reader1 implies (s.vote1>0 and not(s.ack1)),
 s.released implies (s.ack0 and s.ack1),
 (s.flip0 or s.flip1) implies (s.released and s.decision==1 and not(s.freed)),
 s.result0>0 implies (s.released and s.result0==s.decision),s.result1>0 implies (s.released and s.result1==s.decision),
 s.freed implies (s.released and s.decision==2 and s.result0==2 and s.result1==2 and not(s.reader0) and not(s.reader1))}
 action publishReady=all{not(s.published),s'={...s,published:true,poolReady:true}}
 action publishFailure=all{not(s.published),s'={...s,published:true,poolReady:false}}
 action accept0=all{s.published,s.poolReady,s.vote0==0,s'={...s,vote0:1,seen0:s.generation,reader0:true}}
 action accept1=all{s.published,s.poolReady,s.vote1==0,s'={...s,vote1:1,seen1:s.generation,reader1:true}}
 action reject0=all{s.published,s.vote0==0,s'={...s,vote0:2,seen0:s.generation,reader0:true}}
 action reject1=all{s.published,s.vote1==0,s'={...s,vote1:2,seen1:s.generation,reader1:true}}
 action decideAccept=all{s.decision==0,s.vote0==1,s.vote1==1,s'={...s,decision:1}}
 action decideReject=all{s.decision==0,s.vote0>0,s.vote1>0,(s.vote0==2 or s.vote1==2),s'={...s,decision:2}}
 action acknowledge0=all{s.decision>0,not(s.ack0),s'={...s,ack0:true,reader0:false}}
 action acknowledge1=all{s.decision>0,not(s.ack1),s'={...s,ack1:true,reader1:false}}
 action release=all{s.decision>0,s.ack0,s.ack1,s'={...s,released:true}}
 action flip0=all{s.released,s.decision==1,not(s.flip0),s'={...s,flip0:true}}
 action flip1=all{s.released,s.decision==1,not(s.flip1),s'={...s,flip1:true}}
 action deliver0=all{s.released,s.decision>0,s.result0==0,s'={...s,result0:s.decision}}
 action deliver1=all{s.released,s.decision>0,s.result1==0,s'={...s,result1:s.decision}}
 action retainUnknown=all{s.published,not(s.ack0 and s.ack1),s'={...s,retained:true}}
 action retainSetupUnknown=all{s.released,s.decision==1,not(s.flip0 and s.flip1),s'={...s,retained:true}}
 action freeRejected=all{not(s.freed),s.released,s.decision==2,s.result0==2,s.result1==2,not(s.reader0),not(s.reader1),s'={...s,freed:true}}
 action step=any{publishReady,publishFailure,accept0,accept1,reject0,reject1,decideAccept,decideReject,acknowledge0,acknowledge1,release,flip0,flip1,deliver0,deliver1,retainUnknown,retainSetupUnknown,freeRejected,all{s'=s}}
 run acceptedTest=init.then(publishReady).then(accept1).then(accept0).then(decideAccept).then(acknowledge0).then(acknowledge1).then(release).then(flip0).then(flip1).then(all{assert(safe and s.decision==1),s'=s})
 run oomCollectiveTest=init.then(publishFailure).then(reject0).then(reject1).then(decideReject).then(acknowledge0).then(acknowledge1).then(release).then(deliver0).then(deliver1).then(freeRejected).then(all{assert(safe and s.freed and not(s.flip0)),s'=s})
 run memberRejectTest=init.then(publishReady).then(accept0).then(reject1).then(decideReject).then(all{assert(safe and s.decision==2 and not(s.released)),s'=s})
 run lostAckTest=init.then(publishReady).then(accept0).then(accept1).then(decideAccept).then(acknowledge0).then(retainUnknown).then(all{assert(safe and s.reader1 and not(s.released) and not(s.freed)),s'=s})
 run partialFailureDeliveryTest=init.then(publishFailure).then(reject0).then(reject1).then(decideReject).then(acknowledge0).then(acknowledge1).then(release).then(deliver0).then(all{assert(safe and s.result1==0 and not(s.freed)),s'=s})
 run partialSetupRetainsTest=init.then(publishReady).then(accept0).then(accept1).then(decideAccept).then(acknowledge0).then(acknowledge1).then(release).then(flip0).then(retainSetupUnknown).then(all{assert(safe and s.retained and s.flip0 and not(s.flip1) and not(s.freed)),s'=s})
 run earlyFlipControlTest=init.then(publishReady).then(accept0).then(all{s'={...s,flip0:true}}).then(all{assert(not(safe)),s'=s})
 run mixedDecisionControlTest=init.then(publishReady).then(accept0).then(reject1).then(all{s'={...s,decision:1}}).then(all{assert(not(safe)),s'=s})
 run staleGenerationControlTest=init.then(publishReady).then(accept0).then(all{s'={...s,seen0:6}}).then(all{assert(not(safe)),s'=s})
 run earlyFreeControlTest=init.then(publishFailure).then(reject0).then(all{s'={...s,freed:true}}).then(all{assert(not(safe)),s'=s})
}
