module snapshot_observer {
 type State={head:int,loaded:bool,hazard:bool,validated:bool,removed:bool,scanClear:bool,snapshotFreed:bool,reading:bool,observerOpen:bool,observer:bool,pending:bool,unknown:bool,exec:int,producerClosed:bool,detached:bool,codeFreed:bool,receiptFreed:bool}
 pure val initial:State={head:0,loaded:false,hazard:false,validated:false,removed:false,scanClear:false,snapshotFreed:false,reading:false,observerOpen:true,observer:false,pending:true,unknown:false,exec:1,producerClosed:false,detached:false,codeFreed:false,receiptFreed:false}
 var s:State
 action init=s'=initial
 val safe=all{s.validated implies (s.hazard and not(s.snapshotFreed)),s.reading implies (s.validated and not(s.snapshotFreed)),
 s.receiptFreed implies (not(s.observerOpen) and not(s.observer) and not(s.pending) and not(s.unknown)),
 s.codeFreed implies (s.producerClosed and s.exec==0 and not(s.pending) and not(s.unknown) and (s.detached or (not(s.observerOpen) and not(s.observer))))}
 action load=all{s.head==0,not(s.loaded),s'={...s,loaded:true}}
 action publishPin=all{s.loaded,not(s.validated),s'={...s,hazard:true}}
 action validatePin=all{s.loaded,s.hazard,s.head==0,not(s.snapshotFreed),s'={...s,validated:true}}
 action enterRead=all{s.validated,not(s.snapshotFreed),s'={...s,reading:true}}
 action finishRead=all{s'={...s,reading:false}}
 action clearPin=all{not(s.reading),s'={...s,hazard:false,validated:false,loaded:false}}
 action remove=all{s.head==0,s'={...s,head:1,removed:true}}
 action scan=all{s.removed,not(s.hazard),s'={...s,scanClear:true}}
 action freeSnapshot=all{s.removed,s.scanClear,s'={...s,snapshotFreed:true}}
 action beginObserver=all{s.observerOpen,not(s.receiptFreed),not(s.observer),s'={...s,observer:true}}
 action endObserver=all{s'={...s,observer:false}}
 action closeObservers=all{s'={...s,observerOpen:false}}
 action settle=all{s'={...s,pending:false}}
 action lose=all{s.pending,s'={...s,unknown:true}}
 action finishExec=all{s'={...s,exec:0}}
 action closeProducers=all{s'={...s,producerClosed:true}}
 // detached is an external semantic certificate, not inferred from idle state.
 action certifyDetached=all{s.exec==0,not(s.unknown),s'={...s,detached:true}}
 action freeCode=all{s.producerClosed,s.exec==0,not(s.pending),not(s.unknown),(s.detached or (not(s.observerOpen) and not(s.observer))),s'={...s,codeFreed:true}}
 action freeReceipt=all{not(s.observerOpen),not(s.observer),not(s.pending),not(s.unknown),s'={...s,receiptFreed:true}}
 action step=any{load,publishPin,validatePin,enterRead,finishRead,clearPin,remove,scan,freeSnapshot,beginObserver,endObserver,closeObservers,settle,lose,finishExec,closeProducers,certifyDetached,freeCode,freeReceipt,all{s'=s}}
 run protectedReadTest=init.then(load).then(publishPin).then(validatePin).then(enterRead).then(remove).then(all{assert(safe and not(s.scanClear)),s'=s}).then(finishRead).then(clearPin).then(scan).then(freeSnapshot).then(all{assert(safe),s'=s})
 run latePinAfterScanTest=init.then(load).then(remove).then(scan).then(publishPin).then(freeSnapshot).then(all{assert(safe and not(s.validated)),s'=s})
 run closedObserverDrainTest=init.then(beginObserver).then(closeObservers).then(settle).then(finishExec).then(closeProducers).then(all{assert(safe and s.observer and not(s.receiptFreed)),s'=s}).then(endObserver).then(freeReceipt).then(freeCode).then(all{assert(safe),s'=s})
 run dataOnlyOutlivesCodeTest=init.then(beginObserver).then(finishExec).then(settle).then(closeProducers).then(certifyDetached).then(freeCode).then(all{assert(safe and s.observer and not(s.receiptFreed)),s'=s}).then(closeObservers).then(endObserver).then(freeReceipt).then(all{assert(safe),s'=s})
 run pendingKeepsCustodyTest=init.then(finishExec).then(closeProducers).then(closeObservers).then(all{assert(safe and s.pending and not(s.codeFreed) and not(s.receiptFreed)),s'=s})
 run barePointerControlTest=init.then(load).then(remove).then(scan).then(freeSnapshot).then(all{s'={...s,reading:true}}).then(all{assert(not(safe)),s'=s})
 run weakScanMissControlTest=init.then(load).then(publishPin).then(validatePin).then(remove).then(all{s'={...s,scanClear:true}}).then(freeSnapshot).then(all{assert(not(safe)),s'=s})
 run earlyClearControlTest=init.then(load).then(publishPin).then(validatePin).then(enterRead).then(all{s'={...s,hazard:false}}).then(all{assert(not(safe)),s'=s})
 run liveObserverReceiptControlTest=init.then(beginObserver).then(closeObservers).then(settle).then(all{s'={...s,receiptFreed:true}}).then(all{assert(not(safe)),s'=s})
 run undetachedCodeControlTest=init.then(beginObserver).then(finishExec).then(closeProducers).then(settle).then(all{s'={...s,codeFreed:true}}).then(all{assert(not(safe)),s'=s})
 run lateObserverControlTest=init.then(closeObservers).then(settle).then(freeReceipt).then(all{s'={...s,observer:true}}).then(all{assert(not(safe)),s'=s})
 run unknownFreeControlTest=init.then(finishExec).then(closeProducers).then(closeObservers).then(lose).then(settle).then(all{s'={...s,codeFreed:true}}).then(all{assert(not(safe)),s'=s})
}
