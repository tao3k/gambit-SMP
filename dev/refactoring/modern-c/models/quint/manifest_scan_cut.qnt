module manifest_scan_cut {
 type State={frozen:bool,captured:bool,root0:bool,root1:bool,root2:bool,active0:bool,active1:bool,c0:int,c1:int,c2:int,debt:int,ingressClosed:bool,drained:bool,joinedB:bool,rejectedB:bool,abortB:bool,quarantinedB:bool,retiredB:bool}
 pure val initial:State={frozen:false,captured:false,root0:true,root1:true,root2:true,active0:false,active1:false,c0:0,c1:0,c2:0,debt:0,ingressClosed:false,drained:false,joinedB:false,rejectedB:false,abortB:false,quarantinedB:false,retiredB:false}
 var s:State
 action init=s'=initial
 val safe=all{s.c0>=0,s.c0<=1,s.c1>=0,s.c1<=1,s.c2>=0,s.c2<=1,s.debt>=0,s.debt<=2,
 s.captured implies (s.root0 and s.root1 and s.root2),
 (s.active0 or s.active1) implies s.frozen,
 s.drained implies (not(s.active0) and not(s.active1) and s.c0==1 and s.c1==1 and s.c2==1 and s.debt==0 and s.ingressClosed),
 s.retiredB implies ((s.joinedB or s.rejectedB) and not(s.captured)),
 s.quarantinedB implies (s.abortB and not(s.retiredB))}
 action freeze=all{not(s.frozen),not(s.drained),not(s.retiredB),s.c0==0,s.c1==0,s.c2==0,s'={...s,frozen:true,captured:true,active0:true,active1:true}}
 // Slot index mod two: 0 and 2 belong to worker 0; 1 to worker 1.
 action scan0=all{s.frozen,s.captured,s.active0,s.c0==0,s'={...s,c0:1,debt:s.debt+1}}
 action scan1=all{s.frozen,s.captured,s.active1,s.c1==0,s'={...s,c1:1}}
 action scan2=all{s.frozen,s.captured,s.active0,s.c2==0,s'={...s,c2:1}}
 // debt models a derived-copy obligation; all root producers have to finish first.
 action settleDebt=all{s.debt>0,s'={...s,debt:s.debt-1}}
 action closeIngress=all{s.c0==1,s.c1==1,s.c2==1,s'={...s,ingressClosed:true}}
 action park0=all{s.c0==1,s.c2==1,s.ingressClosed,s.debt==0,s'={...s,active0:false}}
 action park1=all{s.c1==1,s.ingressClosed,s'={...s,active1:false}}
 action drain=all{s.frozen,s.ingressClosed,s.c0==1,s.c1==1,s.c2==1,s.debt==0,not(s.active0),not(s.active1),s'={...s,drained:true}}
 action restore=all{s.drained,s'={...s,frozen:false,captured:false}}
 action rejectB=all{s'={...s,rejectedB:true}}
 action confirmJoinB=all{not(s.quarantinedB),s'={...s,joinedB:true}}
 action abortUnknownB=all{not(s.retiredB),not(s.joinedB),not(s.rejectedB),s'={...s,abortB:true,quarantinedB:true}}
 action retireB=all{not(s.captured),not(s.frozen),s.joinedB or s.rejectedB,not(s.quarantinedB),s'={...s,retiredB:true}}
 action step=any{freeze,scan0,scan1,scan2,settleDebt,closeIngress,park0,park1,drain,restore,rejectB,confirmJoinB,abortUnknownB,retireB,all{s'=s}}
 action scans=scan0.then(scan1).then(scan2).then(closeIngress)
 action finish=scans.then(settleDebt).then(park0).then(park1).then(drain).then(restore)
 run completePartitionTest=init.then(freeze).then(finish).then(all{assert(safe and s.drained),s'=s})
 run failedBWaitsForViewTest=init.then(freeze).then(rejectB).then(finish).then(retireB).then(all{assert(safe and s.retiredB),s'=s})
 run unknownAbortIsNotStopTest=init.then(freeze).then(abortUnknownB).then(finish).then(all{assert(safe and s.quarantinedB and not(s.retiredB)),s'=s})
 run omittedSlotControlTest=init.then(freeze).then(scan0).then(scan1).then(settleDebt).then(all{s'={...s,active0:false,active1:false,ingressClosed:true,drained:true}}).then(all{assert(not(safe)),s'=s})
 run duplicateSlotControlTest=init.then(freeze).then(scan0).then(all{s'={...s,c0:2}}).then(all{assert(not(safe)),s'=s})
 run unclosedDebtControlTest=init.then(freeze).then(scans).then(all{s'={...s,active0:false,active1:false,drained:true}}).then(all{assert(not(safe)),s'=s})
 run capturedFreeControlTest=init.then(freeze).then(rejectB).then(all{s'={...s,root2:false,retiredB:true}}).then(all{assert(not(safe)),s'=s})
 run abortIsNotJoinControlTest=init.then(abortUnknownB).then(all{s'={...s,retiredB:true}}).then(all{assert(not(safe)),s'=s})
}
