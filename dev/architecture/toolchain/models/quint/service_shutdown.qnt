// Refines the family owner with service writers, foreign custody and cleanup cuts.
module service_shutdown {
 import preparation_reuse as P from "./preparation_reuse"
 import task_group_custody as F from "./task_group_custody"
 type Cursor={stage:int,claimed:bool,unknown:bool,error:bool,logicalReadClosed:bool,readDone:bool,writeDone:bool,childrenSettled:bool}
 val fresh:Cursor={stage:0,claimed:false,unknown:false,error:false,logicalReadClosed:false,readDone:false,writeDone:false,childrenSettled:false}
 type Host={admitting:bool,writers:Set[int],issuedWriters:Set[int],rawWriter:bool,vmLive:bool,ioLive:bool,signalsLive:bool,moduleLive:bool,cursor:int->Cursor}
 val base:Host={admitting:true,writers:Set(),issuedWriters:Set(),rawWriter:false,vmLive:true,ioLive:true,signalsLive:true,moduleLive:true,cursor:Map(0->fresh,1->fresh)}
 var h:Host
 val M=Set(0,1)
 action init=all{F::init,h'=base}
 action begin=all{F::begin,h'=h}
 def canWriter(i:int):bool=h.admitting and h.vmLive and not(h.issuedWriters.contains(i))
 action writer(i)=all{canWriter(i),P::s'=P::s,F::g'=F::g,h'={...h,writers:h.writers.union(Set(i)),issuedWriters:h.issuedWriters.union(Set(i))}}
 action writerReturn(i)=all{h.writers.contains(i),P::s'=P::s,F::g'=F::g,h'={...h,writers:h.writers.exclude(Set(i))}}
 action closeAdmission=all{P::s'=P::s,F::g'=F::g,h'={...h,admitting:false}}
 action deriveWriter(parent,m)=all{h.vmLive,F::g.anchor,P::canDerive(1,parent,m),not(h.issuedWriters.contains(m)),P::s'=P::s,F::g'=F::g,h'={...h,writers:h.writers.union(Set(m)),issuedWriters:h.issuedWriters.union(Set(m))}}
 action derive(parent,m)=all{h.writers.contains(m),F::derive(parent,m),h'=h}
 action reserve(m)=all{h.writers.contains(m),h.vmLive,F::reserve(m),h'=h}
 action initialize(m)=all{F::initialize(m),h'=h}
 action publish(m)=all{F::publish(m),h'=h}
 action claim(m)=all{F::claim(m),h'=h}
 action spawn(m)=writer(m).then(reserve(m)).then(initialize(m)).then(publish(m)).then(claim(m)).then(writerReturn(m))
 action launch(m)=all{h.ioLive,h.signalsLive,F::launch(m),h'=h}
 action write(m)=all{F::write(m),h'=h}
 action exit(m)=all{F::exit(m),h'=h}
 action terminal(m)=all{h.ioLive,h.signalsLive,F::terminal(m),h'=h}
 // A stable external escrow precedes the wrapper's existing clear-before-call cut.
 def canClaimWrapper(m:int):bool=F::live(m) and F::g.cells.get(m).exited and F::g.cells.get(m).process!=1 and not(h.cursor.get(m).claimed) and h.vmLive and h.ioLive and h.moduleLive
 action claimWrapper(m)=all{canClaimWrapper(m),P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),claimed:true})}}
 action detachIntent(m)=all{h.cursor.get(m).claimed,h.cursor.get(m).stage==0,P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:1})}}
 action detached(m)=all{h.cursor.get(m).stage==1,not(h.cursor.get(m).unknown),P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:2})}}
 action readIntent(m)=all{h.cursor.get(m).stage==2,P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:3,logicalReadClosed:true})}}
 action partialError(m)=all{Set(1,3,5,7).contains(h.cursor.get(m).stage),P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),error:true})}}
 action unknown(m)=all{Set(1,3,5,7).contains(h.cursor.get(m).stage),P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),unknown:true})}}
 def canReadDone(m:int):bool=h.cursor.get(m).stage==3 and not(h.cursor.get(m).unknown) and not(h.cursor.get(m).error)
 action readDone(m)=all{canReadDone(m),P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:4,readDone:true})}}
 action writeIntent(m)=all{h.cursor.get(m).stage==4,P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:5})}}
 action writeDone(m)=all{h.cursor.get(m).stage==5,not(h.cursor.get(m).unknown),not(h.cursor.get(m).error),P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:6,writeDone:true})}}
 action effects(m)=all{h.cursor.get(m).stage==6,F::closeEffects(m),h'=h}
 action record(m)=all{F::record(m,0),h'=h}
 action settle(m)=all{F::settle(m),h'=h}
 action closeSource(m)=all{F::closeSource(m),h'=h}
 action closeObservers(m)=all{F::closeObservers(m),h'=h}
 action observe(m,p)=all{F::observe(m,p),h'=h}
 action deliver(m,p)=all{F::deliver(m,p),h'=h}
 action dropRoots(m)=all{h.cursor.get(m).claimed,h.cursor.get(m).stage==6,F::dropRoots(m),h'=h}
 action releaseIntent(m)=all{h.cursor.get(m).stage==6,F::beginRelease(m),h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:7})}}
 // Known release error may still mean native memory was freed: no replay.
 action releaseKnown(m)=all{h.cursor.get(m).stage==7,not(h.cursor.get(m).unknown),F::knownRelease(m),h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),stage:8})}}
 // Logical IDs here are fixture identities, not native authentication.
 type ChildCertificate={attempt:int,member:int,generation:int,provider:int,issuer:int,closed:bool,observed:bool,required:Set[int],settled:Set[int],transferred:Set[int]}
 def expectedChildren(m:int):Set[int]=Set(10*m,10*m+1,10*m+2,10*m+3)
 def certFor(attempt:int,m:int):ChildCertificate={attempt:attempt,member:m,generation:attempt,provider:100+m,issuer:200+m,closed:true,observed:true,required:expectedChildren(m),settled:expectedChildren(m),transferred:Set()}
 def certified(attempt:int,m:int,r:ChildCertificate):bool=r.attempt==attempt and r.member==m and r.generation==attempt and r.provider==100+m and r.issuer==200+m and r.closed and r.observed and r.required==expectedChildren(m) and r.settled==r.required and r.transferred==Set()
 // Transfer can settle a source lease, but is not final VM-wide discharge.
 def canChildReceipt(attempt:int,m:int,r:ChildCertificate):bool=attempt==P::s.attempt and F::live(m) and h.cursor.get(m).stage==8 and not(h.cursor.get(m).unknown) and certified(attempt,m,r)
 action childReceipt(attempt,m,r)=all{canChildReceipt(attempt,m,r),P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(m,{...h.cursor.get(m),childrenSettled:true})}}
 action target(m)=all{F::targetRegister(m),h'=h}
 action sourceDetach(m)=all{F::detachSource(m),h'=h}
 action parentSuccess=all{F::parentSuccess,h'=h}
 action parentFailure=all{F::parentFailure,h'=h}
 action verify=all{F::verify,h'=h}
 action seal=all{F::seal,h'=h}
 action discard=all{F::discardFailure,h'=h}
 val serviceDrained=not(h.admitting) and h.writers==Set() and not(h.rawWriter) and not(P::s.producer) and M.forall(m=>not(F::live(m)) or h.cursor.get(m).stage==8 and h.cursor.get(m).childrenSettled)
 action unroot=all{serviceDrained,F::dropAnchor,h'=h}
 val canStopVm=serviceDrained and not(F::g.anchor)
 action stopVm=all{canStopVm,P::s'=P::s,F::g'=F::g,h'={...h,vmLive:false,signalsLive:false}}
 action stopIo=all{not(h.vmLive),serviceDrained,P::s'=P::s,F::g'=F::g,h'={...h,ioLive:false}}
 action unload=all{not(h.vmLive),not(h.ioLive),serviceDrained,P::s'=P::s,F::g'=F::g,h'={...h,moduleLive:false}}
 val safe=F::safe and
   (not(h.vmLive) implies serviceDrained and not(F::g.anchor)) and
   (not(h.moduleLive) implies not(h.vmLive) and not(h.ioLive) and serviceDrained) and
   (not(F::g.anchor) implies not(h.admitting) and h.writers==Set() and not(h.rawWriter)) and
   M.forall(m=>F::live(m) implies
    ((h.cursor.get(m).stage==8 implies h.cursor.get(m).claimed and h.cursor.get(m).readDone and h.cursor.get(m).writeDone and F::g.cells.get(m).releaseStage==2) and
     (F::g.cells.get(m).rootsDropped implies h.cursor.get(m).claimed and h.cursor.get(m).readDone and h.cursor.get(m).writeDone) and
     (h.cursor.get(m).stage>0 and h.cursor.get(m).stage<8 implies h.vmLive and h.ioLive and h.moduleLive) and
     (h.cursor.get(m).unknown implies F::g.anchor and h.vmLive and h.ioLive and h.moduleLive) and
     (F::g.cells.get(m).effects implies h.cursor.get(m).readDone and h.cursor.get(m).writeDone)))
 action start=init.then(begin).then(spawn(0)).then(spawn(1))
 action closeDirections(m)=claimWrapper(m).then(detachIntent(m)).then(detached(m)).then(readIntent(m)).then(readDone(m)).then(writeIntent(m)).then(writeDone(m))
 action finish(m)=exit(m).then(closeDirections(m)).then(effects(m)).then(record(m)).then(settle(m))
 action retire(m)=closeSource(m).then(closeObservers(m)).then(dropRoots(m)).then(releaseIntent(m)).then(releaseKnown(m)).then(childReceipt(1,m,certFor(1,m)))
 action finishAll=start.then(write(0)).then(finish(0)).then(finish(1)).then(parentSuccess)
 run closeKeepsGrantedWriterTest=init.then(writer(0)).then(closeAdmission).expect(safe and h.writers==Set(0) and not(canWriter(1)))
 run grantedWriterAfterCloseTest=init.then(begin).then(writer(0)).then(closeAdmission).then(reserve(0)).expect(safe and F::covered(0))
 run unknownProcessBlocksCleanupEntryTest=start.then(launch(0)).then(exit(0)).expect(safe and not(canClaimWrapper(0)) and not(canStopVm))
 run wrapperClaimBeforeDetachTest=start.then(exit(0)).then(claimWrapper(0)).then(detachIntent(0)).expect(safe and h.cursor.get(0).claimed and F::covered(0))
 run detachAckLossRetainsServiceTest=start.then(exit(0)).then(claimWrapper(0)).then(detachIntent(0)).then(unknown(0)).expect(safe and not(canStopVm) and h.moduleLive)
 run logicalClosedIsNotPhysicalDoneTest=start.then(exit(0)).then(claimWrapper(0)).then(detachIntent(0)).then(detached(0)).then(readIntent(0)).then(partialError(0)).expect(safe and h.cursor.get(0).logicalReadClosed and not(h.cursor.get(0).readDone) and not(canReadDone(0)))
 run unknownReadCannotAdvanceTest=start.then(exit(0)).then(claimWrapper(0)).then(detachIntent(0)).then(detached(0)).then(readIntent(0)).then(unknown(0)).expect(safe and not(canReadDone(0)) and F::g.anchor)
 run knownReadAdvancesWithoutRedetachTest=start.then(exit(0)).then(claimWrapper(0)).then(detachIntent(0)).then(detached(0)).then(readIntent(0)).then(readDone(0)).expect(safe and h.cursor.get(0).stage==4)
 run lateObserverBlocksReleaseTest=finishAll.then(observe(1,0)).then(closeSource(1)).then(closeObservers(1)).expect(safe and not(F::canDropRoots(1)))
 run targetReadyDoesNotDrainCleanupTest=start.then(target(0)).then(closeSource(0)).then(sourceDetach(0)).expect(safe and not(serviceDrained) and h.vmLive)
 run nativeUnknownAfterSourceHandoffTest=start.then(launch(0)).then(target(0)).then(closeSource(0)).then(sourceDetach(0)).expect(safe and F::contextHeld(0) and not(canStopVm))
 run releaseErrorIsKnownNoReplayTest=finishAll.then(closeSource(0)).then(closeObservers(0)).then(dropRoots(0)).then(releaseIntent(0)).then(partialError(0)).then(releaseKnown(0)).expect(safe and h.cursor.get(0).stage==8 and not(F::canBeginRelease(0)))
 run unknownFreeKeepsModuleTest=finishAll.then(closeSource(0)).then(closeObservers(0)).then(dropRoots(0)).then(releaseIntent(0)).then(unknown(0)).then(closeAdmission).expect(safe and not(serviceDrained) and h.moduleLive)
 run allStagesThenStopTest=finishAll.then(verify).then(seal).then(retire(0)).then(retire(1)).then(closeAdmission).then(unroot).then(stopVm).then(stopIo).then(unload).expect(safe and not(h.moduleLive))
 run exceptionStillNeedsBothCursorsTest=start.then(parentFailure).then(finish(0)).then(finish(1)).then(discard).then(retire(0)).then(closeAdmission).expect(safe and not(serviceDrained))
 action loseAnchorControl=all{P::s'=P::s,F::g'={...F::g,anchor:false},h'=h}
 run rawGlobalClearNegativeTest=start.then(loseAnchorControl).expect(not(safe))
 action earlyVmControl=all{P::s'=P::s,F::g'=F::g,h'={...h,vmLive:false}}
 run vmRetainedShellNegativeTest=start.then(launch(0)).then(earlyVmControl).expect(not(safe))
 action rawWriter=all{F::g.anchor,P::s'=P::s,F::g'=F::g,h'={...h,rawWriter:true}}
 run indirectWriterRefusesSealTest=finishAll.then(retire(0)).then(retire(1)).then(closeAdmission).then(rawWriter).expect(safe and not(serviceDrained))
 action step={nondet m=M.oneOf();nondet p=M.oneOf();any{begin,deriveWriter(0,m),deriveWriter(1,m),derive(0,m),derive(1,m),writer(m),writerReturn(m),closeAdmission,reserve(m),initialize(m),publish(m),claim(m),write(m),launch(m),exit(m),terminal(m),claimWrapper(m),detachIntent(m),detached(m),readIntent(m),partialError(m),unknown(m),readDone(m),writeIntent(m),writeDone(m),effects(m),record(m),settle(m),closeSource(m),closeObservers(m),observe(m,p),deliver(m,p),dropRoots(m),releaseIntent(m),releaseKnown(m),childReceipt(1,m,certFor(1,m)),target(m),sourceDetach(m),parentSuccess,parentFailure,verify,seal,discard,unroot,stopVm,stopIo,unload,rawWriter,all{P::s'=P::s,F::g'=F::g,h'=h}}}
 run normalGcReturnIsNotResourceDoneTest=start.then(exit(0)).then(claimWrapper(0)).then(detachIntent(0)).then(detached(0)).then(readIntent(0)).then(partialError(0)).expect(safe and h.cursor.get(0).stage==3 and not(serviceDrained))
 action eraseOnCallbackReturnControl=all{P::s'=P::s,F::g'=F::g,h'={...h,cursor:h.cursor.set(0,{...h.cursor.get(0),stage:8})}}
 run callbackReturnCannotEraseCursorNegativeTest=start.then(exit(0)).then(claimWrapper(0)).then(detachIntent(0)).then(detached(0)).then(readIntent(0)).then(partialError(0)).then(eraseOnCallbackReturnControl).expect(not(safe))
 run liveChildDerivesAfterExternalCloseTest=init.then(begin).then(spawn(0)).then(closeAdmission).then(parentFailure).then(deriveWriter(0,1)).then(derive(0,1)).then(initialize(1)).then(publish(1)).then(claim(1)).then(writerReturn(1)).expect(safe and F::covered(0) and F::covered(1) and not(serviceDrained))
 // Orthogonal result facts: status is not native storage or resource disposition.
 type Outcome={observed:bool,qualified:bool,ownLeaseDone:bool,containerFreed:bool,childrenKnown:bool,error:bool}
 def receipt(o:Outcome):bool=o.observed and o.qualified and o.ownLeaseDone and o.childrenKnown
 val borrowed:Outcome={observed:true,qualified:true,ownLeaseDone:true,containerFreed:false,childrenKnown:true,error:false}
 action productFinished=finishAll.then(verify).then(seal)
 action releaseWithNoChildren(m)=closeSource(m).then(closeObservers(m)).then(dropRoots(m)).then(releaseIntent(m)).then(releaseKnown(m))
 run freedContainerDebtBlocksStopTest=productFinished.then(retire(0)).then(releaseWithNoChildren(1)).then(closeAdmission).expect(safe and h.cursor.get(1).stage==8 and F::g.cells.get(1).releaseStage==2 and not(serviceDrained))
 run nonzeroWithChildrenWitnessCanDrainTest=productFinished.then(retire(0)).then(closeSource(1)).then(closeObservers(1)).then(dropRoots(1)).then(releaseIntent(1)).then(partialError(1)).then(releaseKnown(1)).then(childReceipt(1,1,certFor(1,1))).then(closeAdmission).expect(safe and serviceDrained and not(F::canBeginRelease(1)))
 run zeroStatusWithoutChildrenStillBlocksTest=productFinished.then(retire(0)).then(releaseWithNoChildren(1)).then(closeAdmission).expect(safe and not(h.cursor.get(1).error) and not(serviceDrained))
 run wrongAttemptChildReceiptRefusedTest=productFinished.then(releaseWithNoChildren(0)).expect(safe and not(canChildReceipt(0,0,certFor(0,0))) and canChildReceipt(1,0,certFor(1,0)))
 run borrowedSuccessDoesNotFreeStorageTest=init.expect(safe and receipt(borrowed) and not(borrowed.containerFreed))
 run unqualifiedSuccessIsNotReceiptTest=init.expect(safe and not(receipt({...borrowed,qualified:false})))
 run unknownOutcomeIsNotReceiptTest=init.expect(safe and not(receipt({...borrowed,observed:false})))
 run nonzeroCertifiedOutcomeCanSettleTest=init.expect(safe and receipt({...borrowed,error:true,containerFreed:true}))
 run freedMemoryIsNotDescendantClosureTest=init.expect(safe and not(receipt({...borrowed,error:true,containerFreed:true,childrenKnown:false})))

 // These adversarial histories validate the model guard, not provider source completeness.
 run missingChildRefusesReceiptTest=productFinished.then(releaseWithNoChildren(0)).expect(not(canChildReceipt(1,0,{...certFor(1,0),settled:Set(0,1,2)})))
 run extraChildRefusesReceiptTest=init.expect(not(certified(1,0,{...certFor(1,0),required:Set(0,1,2,3,4),settled:Set(0,1,2,3,4)})))
 run wrongProviderRefusesReceiptTest=init.expect(not(certified(1,0,{...certFor(1,0),provider:101})))
 run wrongIssuerRefusesReceiptTest=init.expect(not(certified(1,0,{...certFor(1,0),issuer:201})))
 run reusedGenerationRefusesReceiptTest=init.expect(not(certified(1,0,{...certFor(1,0),generation:0})))
 run openManifestRefusesReceiptTest=init.expect(not(certified(1,0,{...certFor(1,0),closed:false})))
 run lostDispositionRefusesReceiptTest=init.expect(not(certified(1,0,{...certFor(1,0),observed:false})))
 run transferredDebtRefusesVmReceiptTest=init.expect(not(certified(1,0,{...certFor(1,0),transferred:Set(3),settled:Set(0,1,2)})))
 run canonicalAliasIdempotentTest=init.expect(certified(1,0,{...certFor(1,0),required:Set(0,1,2,3,3),settled:Set(0,1,2,3,3)}))
 run duplicateChildReceiptIdempotentTest=productFinished.then(releaseWithNoChildren(0)).then(childReceipt(1,0,certFor(1,0))).then(childReceipt(1,0,certFor(1,0))).expect(safe and h.cursor.get(0).childrenSettled and not(serviceDrained))
}
