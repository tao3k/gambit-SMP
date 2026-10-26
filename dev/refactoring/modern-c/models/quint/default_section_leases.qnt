module default_section_leases {
 // Identity-aware two-worker representative slice: stacks 0/2, initial heaps 1/3, fresh 4/5.
 type State={n:int,p:int,cursor:int,fresh:int,shared:int,visits:int,owner4:int,owner5:int,heap0:int,heap1:int,denied:int,shared0:bool,shared1:bool,certified:bool,retained:bool,closed:bool}
 pure val initial:State={n:6,p:2,cursor:4,fresh:0,shared:0,visits:2,owner4: -1,owner5: -1,heap0:1,heap1:3,denied:0,shared0:false,shared1:false,certified:true,retained:false,closed:false}
 var s:State
 action init=s'=initial
 val safe=all{
 s.n==6,s.p==2,s.cursor>=4,s.cursor<=6,s.fresh==s.cursor-4,s.shared>=0,s.shared<=2,s.visits==2+s.fresh+s.shared,s.denied>=0,
 s.owner4>= -1,s.owner4<=1,s.owner5>= -1,s.owner5<=1,
 s.cursor==4 implies (s.owner4== -1 and s.owner5== -1),s.cursor==5 implies (s.owner4>=0 and s.owner5== -1),s.cursor==6 implies (s.owner4>=0 and s.owner5>=0),
 (not(s.shared0) and not(s.shared1)) implies s.shared==0,(s.shared0 and not(s.shared1)) implies s.shared==1,(not(s.shared0) and s.shared1) implies s.shared==1,(s.shared0 and s.shared1) implies s.shared==2,
 (s.heap0==0 or s.heap0==1 or s.heap0==4 or s.heap0==5),(s.heap1==2 or s.heap1==3 or s.heap1==4 or s.heap1==5),
 s.heap0==0 implies s.shared0,s.shared0 implies s.heap0==0,s.heap1==2 implies s.shared1,s.shared1 implies s.heap1==2,
 s.heap0==4 implies s.owner4==0,s.heap1==4 implies s.owner4==1,s.heap0==5 implies s.owner5==0,s.heap1==5 implies s.owner5==1,
 s.shared0 implies s.cursor==6,s.shared1 implies s.cursor==6,
 s.closed implies not(s.certified),s.retained implies not(s.certified)}
 action fresh4worker0=all{s.certified,s.cursor==4,not(s.shared0),s'={...s,cursor:5,fresh:s.fresh+1,visits:s.visits+1,owner4:0,heap0:4}}
 action fresh4worker1=all{s.certified,s.cursor==4,not(s.shared1),s'={...s,cursor:5,fresh:s.fresh+1,visits:s.visits+1,owner4:1,heap1:4}}
 action fresh5worker0=all{s.certified,s.cursor==5,not(s.shared0),s'={...s,cursor:6,fresh:s.fresh+1,visits:s.visits+1,owner5:0,heap0:5}}
 action fresh5worker1=all{s.certified,s.cursor==5,not(s.shared1),s'={...s,cursor:6,fresh:s.fresh+1,visits:s.visits+1,owner5:1,heap1:5}}
 action shareWorker0=all{s.certified,s.cursor==6,not(s.shared0),s'={...s,shared0:true,heap0:0,shared:s.shared+1,visits:s.visits+1}}
 action shareWorker1=all{s.certified,s.cursor==6,not(s.shared1),s'={...s,shared1:true,heap1:2,shared:s.shared+1,visits:s.visits+1}}
 action denyStackRebind=all{s.certified,s'={...s,denied:s.denied+1}}
 action denyGrow=all{s.certified,s'={...s,denied:s.denied+1}}
 action denyReentry=all{s.certified,s'={...s,denied:s.denied+1}}
 action unknownWriter=all{s.certified,s'={...s,certified:false,retained:true}}
 action exhaustedShared0=all{s.certified,s.shared0,s'={...s,certified:false,retained:true}}
 action closeAllocators=all{s.certified,s'={...s,closed:true,certified:false}}
 action step=any{fresh4worker0,fresh4worker1,fresh5worker0,fresh5worker1,shareWorker0,shareWorker1,denyStackRebind,denyGrow,denyReentry,unknownWriter,exhaustedShared0,closeAllocators,all{s'=s}}
 action fill=fresh4worker0.then(fresh5worker1)
 run fullDefaultTest=init.then(fill).then(shareWorker0).then(shareWorker1).then(all{assert(safe and s.visits==s.n and s.heap0!=s.heap1),s'=s})
 run sameWorkerFreshTest=init.then(fresh4worker0).then(fresh5worker0).then(shareWorker0).then(shareWorker1).then(all{assert(safe and s.visits==6),s'=s})
 run deniedEntriesTest=init.then(denyStackRebind).then(denyGrow).then(denyReentry).then(all{assert(safe and s.visits==2 and s.denied==3),s'=s})
 run unknownRetainsTest=init.then(fill).then(unknownWriter).then(all{assert(safe and s.retained and s.visits==4),s'=s})
 run exhaustedRetainsTest=init.then(fill).then(shareWorker0).then(exhaustedShared0).then(all{assert(safe and s.retained and s.visits==5),s'=s})
 run duplicateFreshControlTest=init.then(fresh4worker0).then(all{s'={...s,owner4:1,heap1:4,visits:s.visits+1}}).then(all{assert(not(safe)),s'=s})
 run repeatedShareControlTest=init.then(fill).then(shareWorker0).then(all{s'={...s,shared:s.shared+1,visits:s.visits+1}}).then(all{assert(not(safe)),s'=s})
 run crossOwnerRebindControlTest=init.then(fill).then(shareWorker0).then(all{s'={...s,heap1:0}}).then(all{assert(not(safe)),s'=s})
 run staleGrowthControlTest=init.then(all{s'={...s,n:7}}).then(all{assert(not(safe)),s'=s})
}
