module vm_root_registry {
 import vm_registry_parameters.* from "./vm_registry_parameters"
 // GC phase: 0 open; 1 close admission/drain old permits; 2 frozen scan.
 type State={phase:int,epoch:int,vm:int,processors:Set[int],vmStorage:Set[int],live:Set[int],closed:Set[int],values:int->int,domains:int->int,
  leases:Set[int],deref:Set[int],writers:Set[int],snapshot:Set[int],seen:Set[int],scanBase:int->int,
  pending:bool,producerRoot:bool,producerValue:int,unacked:Set[int],lastSnapshot:Set[int],lastSeen:Set[int],badRead:bool,rawAddress:int}
 pure val initial:State={phase:0,epoch:0,vm:0,processors:Set(0,1),vmStorage:Set(0),live:Set(0),closed:Set(),values:Map(0->100,1->200),domains:Map(0->0,1->0),
  leases:Set(),deref:Set(),writers:Set(),snapshot:Set(),seen:Set(),scanBase:Map(0->100,1->200),
  pending:false,producerRoot:false,producerValue:200,unacked:Set(),lastSnapshot:Set(),lastSeen:Set(),badRead:false,rawAddress:-1}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,vm:WorkspaceCount-1,domains:Map(0->WorkspaceCount-1,1->WorkspaceCount-1)}
 action prepareRegister=all {not(s.live.contains(1)),not(s.closed.contains(1)),not(s.pending),s.processors.contains(1),s'={...s,pending:true,producerRoot:true}}
 action commitRegister=all {s.phase==0,s.pending,s.producerRoot,s.domains.get(1)==s.vm,
  s'={...s,live:s.live.union(Set(1)),values:s.values.set(1,s.producerValue),pending:false,producerRoot:false,unacked:s.unacked.union(Set(1))}}
 action ackRegister=all {s.unacked.contains(1),s'={...s,unacked:s.unacked.exclude(Set(1))}}
 action borrow(i)=all {s.phase==0,s.live.contains(i),not(s.closed.contains(i)),not(s.leases.contains(i)),s'={...s,leases:s.leases.union(Set(i))}}
 action releaseLease(i)=all {s.leases.contains(i),not(s.deref.contains(i)),s'={...s,leases:s.leases.exclude(Set(i))}}
 action beginDeref(i)=all {s.phase==0,s.leases.contains(i),not(s.deref.contains(i)),s'={...s,deref:s.deref.union(Set(i))}}
 action readSlot(i)=all {s.phase==0,s.deref.contains(i),s'={...s,badRead:not(s.live.contains(i))}}
 action endDeref(i)=all {s.deref.contains(i),s'={...s,deref:s.deref.exclude(Set(i))}}
 action beginUpdate(i)=all {s.phase==0,s.live.contains(i),not(s.closed.contains(i)),not(s.writers.contains(i)),s'={...s,writers:s.writers.union(Set(i))}}
 // Preaccepted writer can drain during closing, before snapshot freeze.
 action commitUpdate(i)=all {s.phase<=1,s.writers.contains(i),s'={...s,values:s.values.set(i,s.values.get(i)+1),writers:s.writers.exclude(Set(i))}}
 action cancelUpdate(i)=all {s.writers.contains(i),s'={...s,writers:s.writers.exclude(Set(i))}}
 action closeGC=all {s.phase==0,s'={...s,phase:1}}
 action startScan=all {s.phase==1,s.writers==Set(),s.deref==Set(),s'={...s,phase:2,snapshot:s.live,seen:Set(),scanBase:s.values}}
 action scanSlot(i)=all {s.phase==2,s.snapshot.contains(i),not(s.seen.contains(i)),
  s'={...s,seen:s.seen.union(Set(i)),values:s.values.set(i,s.scanBase.get(i)+10)}}
 action endScan=all {s.phase==2,s.seen==s.snapshot,
  s'={...s,phase:0,epoch:s.epoch+1,producerValue:if(s.pending) s.producerValue+10 else s.producerValue,lastSnapshot:s.snapshot,lastSeen:s.seen,snapshot:Set(),seen:Set()}}
 action requestRetire(i)=all {s.live.contains(i),s'={...s,closed:s.closed.union(Set(i))}}
 action reclaim(i)=all {s.phase==0,s.closed.contains(i),not(s.leases.contains(i)),not(s.deref.contains(i)),not(s.writers.contains(i)),not(s.unacked.contains(i)),
  s'={...s,live:s.live.exclude(Set(i))}}
 action handoffStorage=all {s.phase==0,s.writers==Set(),s.deref==Set(),s.live.contains(1),s.processors.contains(1),s'={...s,vmStorage:s.vmStorage.union(Set(1))}}
 action departOne=all {s.phase==0,not(s.pending),s.writers==Set(),s.deref==Set(),s.live.subseteq(s.vmStorage),s'={...s,processors:s.processors.exclude(Set(1))}}
 def safe=(s.live.exclude(s.vmStorage)==Set() or s.processors.contains(1)) and s.leases.subseteq(s.live) and s.deref.subseteq(s.leases) and s.writers.subseteq(s.live) and
  s.unacked.subseteq(s.live) and (s.pending implies s.producerRoot) and
  s.live.forall(i=>s.domains.get(i)==s.vm) and s.lastSnapshot==s.lastSeen and not(s.badRead) and
  (s.phase==2 implies s.live==s.snapshot and s.writers==Set() and s.deref==Set() and
   s.seen.forall(i=>s.values.get(i)==s.scanBase.get(i)+10))
 action step={nondet i=0.to(1).oneOf();any {prepareRegister,commitRegister,ackRegister,borrow(i),releaseLease(i),beginDeref(i),readSlot(i),endDeref(i),
  beginUpdate(i),commitUpdate(i),cancelUpdate(i),closeGC,startScan,scanSlot(i),endScan,requestRetire(i),reclaim(i),handoffStorage,departOne,s'=s}}
 action forceEnd=s'={...s,phase:0,epoch:s.epoch+1,producerValue:if(s.pending) s.producerValue+10 else s.producerValue,lastSnapshot:s.snapshot,lastSeen:s.seen,snapshot:Set(),seen:Set()}
 action mutateScanned=s'={...s,values:s.values.set(0,s.values.get(0)+1)}
 action registerFrozen=s'={...s,live:s.live.union(Set(1)),pending:false,producerRoot:false}
 action forceFree(i)=s'={...s,live:s.live.exclude(Set(i))}
 action dropProducer=s'={...s,producerRoot:false}
 action cacheRaw=all {s.phase==0,s.deref.contains(0),s'={...s,rawAddress:s.values.get(0)}}
 action staleRaw=s'={...s,badRead:s.rawAddress!=s.values.get(0)}
 action forceScan=s'={...s,phase:2,snapshot:s.live,scanBase:s.values,seen:Set()}
 action forceCreatorExit=s'={...s,processors:s.processors.exclude(Set(1))}
 action wrongVM=s'={...s,domains:s.domains.set(0,s.vm+1)}
 run nonzeroCoverageTest=init.then(prepareRegister).then(commitRegister).then(ackRegister).then(closeGC).then(startScan).then(scanSlot(0)).then(scanSlot(1)).then(endScan).expect(safe and s.values.get(1)==210)
 run acceptedWriterDrainTest=init.then(beginUpdate(0)).then(closeGC).then(commitUpdate(0)).then(startScan).then(scanSlot(0)).then(endScan).expect(safe and s.values.get(0)==111)
 run canceledWriterTest=init.then(beginUpdate(0)).then(closeGC).then(cancelUpdate(0)).then(startScan).then(scanSlot(0)).then(endScan).expect(safe and s.values.get(0)==110)
 run leaseAcrossGcTest=init.then(borrow(0)).then(closeGC).then(startScan).then(scanSlot(0)).then(endScan).then(beginDeref(0)).then(readSlot(0)).expect(safe)
 run derefDrainTest=init.then(borrow(0)).then(beginDeref(0)).then(closeGC).then(endDeref(0)).then(startScan).then(scanSlot(0)).then(endScan).expect(safe)
 run retireDuringScanTest=init.then(closeGC).then(startScan).then(requestRetire(0)).then(scanSlot(0)).then(endScan).then(reclaim(0)).expect(safe and s.live==Set())
 run deferredRegistrationTest=init.then(closeGC).then(prepareRegister).then(startScan).then(scanSlot(0)).then(endScan).then(commitRegister).expect(safe and s.live.contains(1) and s.values.get(1)==210)
 run creatorDepartureTest=init.then(prepareRegister).then(commitRegister).then(ackRegister).then(handoffStorage).then(departOne).then(closeGC).then(startScan).then(scanSlot(0)).then(scanSlot(1)).then(endScan).expect(safe and not(s.processors.contains(1)) and s.live.contains(1))
 run unknownAckRetainsTest=init.then(prepareRegister).then(commitRegister).then(requestRetire(1)).then(closeGC).then(startScan).then(scanSlot(0)).then(scanSlot(1)).then(endScan).expect(safe and s.unacked.contains(1) and s.live.contains(1))
 run leaseRetireDrainTest=init.then(borrow(0)).then(requestRetire(0)).then(releaseLease(0)).then(reclaim(0)).expect(safe and s.live==Set())
 run otherVmTest=initOther.then(prepareRegister).then(commitRegister).then(closeGC).then(startScan).then(scanSlot(0)).then(scanSlot(1)).then(endScan).expect(safe and s.vm==1)
 run closedAdmissionTest=init.then(requestRetire(0)).expect(safe and s.closed.contains(0))
 run omittedNonzeroControlTest=init.then(prepareRegister).then(commitRegister).then(closeGC).then(startScan).then(scanSlot(0)).then(forceEnd).expect(not(safe))
 run scanUpdateControlTest=init.then(closeGC).then(startScan).then(scanSlot(0)).then(mutateScanned).expect(not(safe))
 run frozenRegisterControlTest=init.then(closeGC).then(prepareRegister).then(startScan).then(registerFrozen).expect(not(safe))
 run scannerFreeControlTest=init.then(closeGC).then(startScan).then(forceFree(0)).expect(not(safe))
 run leasedFreeControlTest=init.then(borrow(0)).then(forceFree(0)).expect(not(safe))
 run producerGapControlTest=init.then(prepareRegister).then(dropProducer).expect(not(safe))
 run staleAddressControlTest=init.then(borrow(0)).then(beginDeref(0)).then(cacheRaw).then(closeGC).then(endDeref(0)).then(startScan).then(scanSlot(0)).then(endScan).then(staleRaw).expect(not(safe))
 run prematureScanControlTest=init.then(beginUpdate(0)).then(closeGC).then(forceScan).expect(not(safe))
 run unknownFreeControlTest=init.then(prepareRegister).then(commitRegister).then(requestRetire(1)).then(forceFree(1)).expect(not(safe))
 run storageExitControlTest=init.then(prepareRegister).then(commitRegister).then(ackRegister).then(forceCreatorExit).expect(not(safe))
 run wrongVmControlTest=init.then(wrongVM).expect(not(safe))
}
