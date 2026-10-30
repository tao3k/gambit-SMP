module continuation_restore_plan {
 // Offsets in words; H=64,F=8,quarter reservation=20. Proposed guards, not current runtime.
 type State={r0:int,r1:int,mode0:int,mode1:int,cap0:int,cap1:int,outcome:int,denied:int,frozen:bool,retained:bool}
 pure val initial:State={r0:0,r1:0,mode0:0,mode1:0,cap0:0,cap1:0,outcome:0,denied:0,frozen:false,retained:false}
 var s:State
 action init=s'=initial
 val safe=all{s.r0>=0,
 s.r1>=0,
 s.mode0>=0,
 s.mode0<=3,
 s.mode1>=0,
 s.mode1<=3,
 s.outcome>=0,
 s.outcome<=2,
 s.denied>=0,
 (s.mode0>0 or s.mode1>0 or s.outcome>0) implies s.frozen,
 not(s.frozen) implies (s.r0==0 and s.r1==0 and s.mode0==0 and s.mode1==0 and s.outcome==0),
 s.frozen implies (s.r0>=4 and s.r1>=4),
 s.mode0==0 implies s.cap0==0,
 s.mode1==0 implies s.cap1==0,
 s.mode0==1 implies (s.cap0==20 and s.r0+8<=s.cap0),
 s.mode1==1 implies (s.cap1==20 and s.r1+8<=s.cap1),
 s.mode0==2 implies (s.cap0==64 and s.r0+8<=s.cap0),
 s.mode1==2 implies (s.cap1==64 and s.r1+8<=s.cap1),
 s.mode0==3 implies (s.cap0==0 and s.r0+8>64),
 s.mode1==3 implies (s.cap1==0 and s.r1+8>64),
 s.outcome==1 implies (s.mode0>0 and s.mode0<3 and s.mode1>0 and s.mode1<3)}
 action freezeSmall=all{not(s.frozen),s'={...s,r0:8,r1:12,frozen:true}}
 action freezeLarge=all{not(s.frozen),s'={...s,r0:8,r1:24,frozen:true}}
 action freezeOversize=all{not(s.frozen),s'={...s,r0:8,r1:68,frozen:true}}
 action share0=all{s.frozen,s.outcome==0,s.mode0==0,s.r0+8<=20,s'={...s,mode0:1,cap0:20}}
 action share1=all{s.frozen,s.outcome==0,s.mode1==0,s.r1+8<=20,s'={...s,mode1:1,cap1:20}}
 action dedicate0=all{s.frozen,s.outcome==0,s.mode0==0,s.r0+8<=64,s'={...s,mode0:2,cap0:64}}
 action dedicate1=all{s.frozen,s.outcome==0,s.mode1==0,s.r1+8<=64,s'={...s,mode1:2,cap1:64}}
 action reject0=all{s.frozen,s.outcome==0,s.mode0==0,s.r0+8>64,s'={...s,mode0:3}}
 action reject1=all{s.frozen,s.outcome==0,s.mode1==0,s.r1+8>64,s'={...s,mode1:3}}
 action sealAccept=all{s.frozen,s.outcome==0,s.mode0>0,s.mode0<3,s.mode1>0,s.mode1<3,s'={...s,outcome:1}}
 action sealReject=all{s.frozen,s.outcome==0,s.mode0>0,s.mode1>0,(s.mode0==3 or s.mode1==3),s'={...s,outcome:2}}
 action allocationFailure=all{s.frozen,s.outcome==0,s'={...s,outcome:2}}
 action denyMutation=all{s.frozen,s'={...s,denied:s.denied+1}}
 action retainUnknown=all{s.frozen,s'={...s,retained:true}}
 action step=any{freezeSmall,freezeLarge,freezeOversize,share0,share1,dedicate0,dedicate1,reject0,reject1,sealAccept,sealReject,allocationFailure,denyMutation,retainUnknown,all{s'=s}}
 run sharedPlanTest=init.then(freezeSmall).then(share0).then(share1).then(sealAccept).then(all{assert(safe and s.outcome==1 and s.mode1==1),s'=s})
 run largeDedicatedTest=init.then(freezeLarge).then(share0).then(dedicate1).then(sealAccept).then(all{assert(safe and s.outcome==1 and s.mode1==2),s'=s})
 run oversizeRejectedTest=init.then(freezeOversize).then(share0).then(reject1).then(sealReject).then(all{assert(safe and s.outcome==2),s'=s})
 run oomRejectedTest=init.then(freezeLarge).then(share0).then(allocationFailure).then(all{assert(safe and s.outcome==2),s'=s})
 run unknownRetainsTest=init.then(freezeLarge).then(share0).then(retainUnknown).then(all{assert(safe and s.retained and s.outcome==0),s'=s})
 run deniedMutationTest=init.then(freezeLarge).then(share0).then(dedicate1).then(sealAccept).then(denyMutation).then(all{assert(safe and s.r1==24 and s.denied==1),s'=s})
 run forceShareControlTest=init.then(freezeLarge).then(share0).then(all{s'={...s,mode1:1,cap1:20,outcome:1}}).then(all{assert(not(safe)),s'=s})
 run staleRestoreControlTest=init.then(freezeSmall).then(share0).then(share1).then(sealAccept).then(all{s'={...s,r1:24}}).then(all{assert(not(safe)),s'=s})
 run acceptIncompleteControlTest=init.then(freezeLarge).then(share0).then(all{s'={...s,outcome:1}}).then(all{assert(not(safe)),s'=s})
 run oversizeDedicatedControlTest=init.then(freezeOversize).then(share0).then(all{s'={...s,mode1:2,cap1:64}}).then(all{assert(not(safe)),s'=s})
}
