// Extracted RETI word-coordinate protocol; finite histories, not native C execution.
// Point163 is NOT a tagged pointer value. IRA7006 and +1000 are abstract GC witnesses.
module rationaldict_return163 {
 type State={phase:int,nextReg:int,depth:int,slots:int->int,regs:int->int,ira:int,nargs:int,fp:int,target:int,checked:bool,root:int,heap:bool,published:bool}
 val initialRegs=0.to(4).mapBy(i=>100+i)
 var s:State
 action init=s'={phase:0,nextReg:0,depth:0,slots:1.to(9).mapBy(i=>900+i),regs:initialRegs,ira:7006,nargs:1,fp:120,target:163,checked:false,root:1,heap:false,published:false}
 action pushRegister=all{s.phase==0,s.nextReg<5,s'={...s,slots:s.slots.set(s.nextReg+1,s.regs.get(s.nextReg)),nextReg:s.nextReg+1,depth:s.depth+1}}
 action pushReturn=all{s.phase==0,s.nextReg==5,s'={...s,slots:s.slots.set(6,s.ira),depth:s.depth+1,phase:1}}
 action reservePadding=all{s.phase==1,s'={...s,depth:s.depth+6,fp:s.fp-12,phase:2}}
 action publishRootFrame=all{s.phase==2,s'={...s,published:true}}
 val scanReady=s.phase==2 and s.published
 val normalRoots=Set(2,3,4,5,6)
 def scan(slots:int->int,roots:Set[int]):int->int=1.to(9).mapBy(i=>if(roots.contains(i)) slots.get(i)+1000 else slots.get(i))
 action scanFrame=all{scanReady,s'={...s,slots:scan(s.slots,normalRoots),phase:3}}
 action scanWithoutRa=all{scanReady,s'={...s,slots:scan(s.slots,Set(2,3,4,5)),phase:3}}
 action scanLinkToo=all{scanReady,s'={...s,slots:scan(s.slots,Set(1,2,3,4,5,6)),phase:3}}
 action rebuildHeap=all{s.phase==3,s'={...s,slots:s.slots.set(1,777),heap:true,root:777}}
 action restoreFrame=all{s.phase==3,s'={...s,regs:0.to(4).mapBy(r=>s.slots.get(r+1)),ira:s.slots.get(6),fp:s.fp+12,depth:0,phase:4}}
 action singleTail=all{s.phase==4,s'={...s,target:150,checked:false,phase:5}}
 action multipleTail=all{s.phase==4,s'={...s,target:150,nargs:2,checked:true,phase:5}}
 action wrongSingleNargs=all{s.phase==4,s'={...s,target:150,nargs:2,checked:true,phase:5}}
 val restored=s.regs.get(0)==(if(s.heap) 777 else 100) and 1.to(4).forall(r=>s.regs.get(r)==100+r+1000) and s.ira==8006 and s.fp==120
 run reserved=init.then(pushRegister).then(pushRegister).then(pushRegister).then(pushRegister).then(pushRegister).then(pushReturn).then(reservePadding)
 run prepared=reserved.then(publishRootFrame)
 run unpublishedRootRefusalTest=reserved.expect(not(scanReady))
 run saveAndScanTest=prepared.then(scanFrame).expect(s.slots.get(1)==100 and s.slots.get(2)==1101 and s.slots.get(6)==8006 and s.depth==12)
 run roundTripTest=prepared.then(scanFrame).then(restoreFrame).expect(restored)
 run heapLinkRewriteTest=prepared.then(scanFrame).then(rebuildHeap).then(restoreFrame).expect(restored and s.regs.get(0)!=100)
 run ordinaryRootOmissionCounterexampleTest=prepared.then(scanWithoutRa).then(restoreFrame).expect(not(restored) and s.ira==7006)
 run structuralLinkScanCounterexampleTest=prepared.then(scanLinkToo).then(restoreFrame).expect(not(restored))
 run singleHostTailTest=prepared.then(scanFrame).then(restoreFrame).then(singleTail).expect(restored and s.nargs==1 and s.target==150 and not(s.checked))
 run multipleHostTailTest=prepared.then(scanFrame).then(restoreFrame).then(multipleTail).expect(restored and s.nargs==2 and s.target==150 and s.checked)
 run forcedNargsCounterexampleTest=prepared.then(scanFrame).then(restoreFrame).then(wrongSingleNargs).expect(s.nargs!=1)
 run physicalCoordinatesTest=init.expect((120-12)-(-6)==120-6 and (10-6)==4 and 2.to(6).map(i=>10-i)==Set(8,7,6,5,4))
}
