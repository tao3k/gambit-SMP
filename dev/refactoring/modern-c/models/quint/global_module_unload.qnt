module global_module_unload {
 // Two owner slots abstract an image membership product; not a full C11 memory model.
 // return/issue actions accept independent valid detachment receipts.
 type State={epoch:int,phase:int,users0:int,users1:int,nativeUsers:int,tasks:int,observers:int,stamp0:int,stamp1:int,denied:int,closed0:bool,closed1:bool,ready0:bool,ready1:bool,receipt0:bool,receipt1:bool,pendingChild:bool,unknownResult:bool,scopeComplete:bool,teardownQualified:bool,loaderPin:bool}
 pure val initial:State={epoch:1,phase:0,users0:1,users1:1,nativeUsers:0,tasks:0,observers:0,stamp0:0,stamp1:0,denied:0,closed0:false,closed1:false,ready0:false,ready1:false,receipt0:false,receipt1:false,pendingChild:false,unknownResult:false,scopeComplete:true,teardownQualified:true,loaderPin:false}
 var s:State
 action init=s'=initial
 val safe=all{s.epoch>=1,
 s.epoch<=2,
 s.phase>=0,
 s.phase<=5,
 s.users0>=0,
 s.users1>=0,
 s.nativeUsers>=0,
 s.tasks>=0,
 s.observers>=0,
 s.stamp0>=0,
 s.stamp1>=0,
 s.denied>=0,
 s.users0<=1,
 s.users1<=1,
 s.nativeUsers<=1,
 s.tasks<=1,
 s.observers<=1,
 s.stamp0<=s.epoch,
 s.stamp1<=s.epoch,
 s.pendingChild implies s.users0==1,
 s.ready0 implies (s.phase>=1 and s.closed0 and s.users0==0 and s.stamp0==s.epoch),
 s.ready1 implies (s.phase>=1 and s.closed1 and s.users1==0 and s.stamp1==s.epoch),
 s.receipt0 implies s.ready0,
 s.receipt1 implies s.ready1,
 (s.phase>=2 and s.phase<=4) implies (s.closed0 and s.closed1 and s.receipt0 and s.receipt1 and s.nativeUsers==0 and s.tasks==0 and s.observers==0 and not(s.pendingChild) and not(s.unknownResult) and s.scopeComplete and s.teardownQualified),
 s.phase==3 implies s.loaderPin,
 s.phase==4 implies not(s.loaderPin),
 s.phase==5 implies (s.unknownResult and s.loaderPin)}
 action borrow0=all{s.phase==0,not(s.closed0),s.users0==0,s'={...s,users0:1}}
 action borrow1=all{s.phase==0,not(s.closed1),s.users1==0,s'={...s,users1:1}}
 action observe=all{s.phase==0,s.observers==0,s'={...s,observers:1}}
 action closeGlobal=all{s.phase==0,s'={...s,phase:1,epoch:2}}
 action closeLocal0=all{s.phase==1,s'={...s,closed0:true}}
 action closeLocal1=all{s.phase==1,s'={...s,closed1:true}}
 action return0=all{s.users0==1,not(s.pendingChild),s'={...s,users0:0}}
 action return1=all{s.users1==1,s'={...s,users1:0}}
 action issueLocal0=all{s.phase==1,s.closed0,s.users0==0,s'={...s,ready0:true,stamp0:s.epoch}}
 action issueLocal1=all{s.phase==1,s.closed1,s.users1==0,s'={...s,ready1:true,stamp1:s.epoch}}
 action deliver0=all{s.ready0,s.stamp0==s.epoch,s'={...s,receipt0:true}}
 action deliver1=all{s.ready1,s.stamp1==s.epoch,s'={...s,receipt1:true}}
 action rejectStale=all{s.phase==1,s'={...s,denied:s.denied+1}}
 action rejectLate=all{s.phase>=1,s'={...s,denied:s.denied+1}}
 action nativeBorrow=all{s.phase==0,s.nativeUsers==0,s'={...s,nativeUsers:1}}
 action nativeReturn=all{s.nativeUsers==1,not(s.unknownResult),s'={...s,nativeUsers:0}}
 action unknownNative=all{s.nativeUsers==1,s.phase<=1,s'={...s,unknownResult:true}}
 action observerRetire=all{s.observers==1,s'={...s,observers:0}}
 action beginChild=all{s.users0==1,not(s.ready0),s.phase<=1,s.tasks==0,s'={...s,pendingChild:true}}
 action commitChild=all{s.pendingChild,s.users0==1,s.tasks==0,not(s.unknownResult),s'={...s,pendingChild:false,users0:0,tasks:1}}
 action rejectChild=all{s.pendingChild,s'={...s,pendingChild:false}}
 action unknownChild=all{s.pendingChild,s.phase<=1,s'={...s,unknownResult:true}}
 action taskDone=all{s.tasks==1,not(s.unknownResult),s'={...s,tasks:0}}
 action permit=all{s.phase==1,s.closed0,s.closed1,s.receipt0,s.receipt1,s.stamp0==s.epoch,s.stamp1==s.epoch,s.nativeUsers==0,s.tasks==0,s.observers==0,not(s.pendingChild),not(s.unknownResult),s.scopeComplete,s.teardownQualified,s'={...s,phase:2}}
 action beginUnload=all{s.phase==2,s'={...s,phase:3,loaderPin:true}}
 action closeKnown=all{s.phase==3,s'={...s,phase:4,loaderPin:false}}
 action closeUnknown=all{s.phase==3,s'={...s,phase:5,unknownResult:true}}
 action rejectIncomplete=all{s.phase<=1,s'={...s,scopeComplete:false}}
 action step=any{borrow0,borrow1,observe,closeGlobal,closeLocal0,closeLocal1,return0,return1,issueLocal0,issueLocal1,deliver0,deliver1,rejectStale,rejectLate,nativeBorrow,nativeReturn,unknownNative,observerRetire,beginChild,commitChild,rejectChild,unknownChild,taskDone,permit,beginUnload,closeKnown,closeUnknown,rejectIncomplete,all{s'=s}}
 run allOwnersCloseTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(permit).then(beginUnload).then(closeKnown).then(all{assert(safe and s.phase==4),s'=s})
 run duplicateReceiptTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(deliver0).then(deliver0).then(permit).then(all{assert(safe and s.receipt0 and s.receipt1),s'=s})
 run lateBorrowTest=init.then(observe).then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(rejectLate).then(observerRetire).then(permit).then(all{assert(safe and s.phase==2 and s.denied==1),s'=s})
 run nativeDrainTest=init.then(nativeBorrow).then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(nativeReturn).then(permit).then(all{assert(safe and s.phase==2),s'=s})
 run nativeUnknownTest=init.then(nativeBorrow).then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(unknownNative).then(all{assert(safe and s.unknownResult and s.phase==1),s'=s})
 run childTransferTest=init.then(closeGlobal).then(beginChild).then(closeLocal0).then(closeLocal1).then(commitChild).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(taskDone).then(permit).then(all{assert(safe and s.phase==2),s'=s})
 run childRejectTest=init.then(beginChild).then(closeGlobal).then(rejectChild).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(permit).then(all{assert(safe and s.phase==2),s'=s})
 run unloadUnknownTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(permit).then(beginUnload).then(closeUnknown).then(all{assert(safe and s.phase==5 and s.loaderPin),s'=s})
 run incompleteScopeTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(rejectIncomplete).then(all{assert(safe and not(s.scopeComplete) and s.phase==1),s'=s})
 run missingVMControlTest=init.then(closeGlobal).then(closeLocal0).then(return0).then(issueLocal0).then(deliver0).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
 run staleStampControlTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(all{s'={...s,stamp0:1}}).then(all{assert(not(safe)),s'=s})
 run lateBorrowControlTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(permit).then(all{s'={...s,nativeUsers:1}}).then(all{assert(not(safe)),s'=s})
 run observerLostControlTest=init.then(observe).then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
 run parentLostControlTest=init.then(beginChild).then(closeGlobal).then(all{s'={...s,users0:0}}).then(all{assert(not(safe)),s'=s})
 run unknownFreedControlTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(permit).then(beginUnload).then(closeUnknown).then(all{s'={...s,loaderPin:false}}).then(all{assert(not(safe)),s'=s})
 run opaqueGroupControlTest=init.then(closeGlobal).then(closeLocal0).then(closeLocal1).then(return0).then(return1).then(issueLocal0).then(issueLocal1).then(deliver0).then(deliver1).then(rejectIncomplete).then(all{s'={...s,phase:2}}).then(all{assert(not(safe)),s'=s})
}
