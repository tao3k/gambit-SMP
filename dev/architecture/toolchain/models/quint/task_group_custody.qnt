// Family adapter for the actual preparation ledger, not another scheduler.
module task_group_custody {
 import preparation_reuse as P from "./preparation_reuse"
 type C={source:bool,target:bool,targetReady:bool,sourceOpen:bool,sourcePins:int,
   process:int,exited:bool,effects:bool,observing:bool,pins:Set[int],issued:Set[int],rawAlias:bool,
   rootsDropped:bool,releaseStage:int,delivered:bool}
 val empty:C={source:true,target:false,targetReady:false,sourceOpen:true,sourcePins:0,
   process:0,exited:false,effects:false,observing:true,pins:Set(),issued:Set(),rawAlias:false,
   rootsDropped:false,releaseStage:0,delivered:false}
 type Family={anchor:bool,cells:int->C,frozen:bool,manifest:Set[int],scanned:bool}
 val initial:Family={anchor:true,cells:Map(0->empty,1->empty),frozen:false,manifest:Set(),scanned:false}
 var g:Family
 val M=Set(0,1)
 def live(m:int):bool=P::s.issued.contains(m)
 def covered(m:int):bool=g.anchor and not(g.cells.get(m).rootsDropped) and (g.cells.get(m).source or (g.cells.get(m).target and g.cells.get(m).targetReady))
 def localKnown(m:int):bool=g.cells.get(m).exited and g.cells.get(m).process!=1 and g.cells.get(m).effects
 def contextHeld(c:int):bool=M.exists(m=>live(m) and (if(c==0) g.cells.get(m).source or g.cells.get(m).sourcePins>0 or g.cells.get(m).process==1 else g.cells.get(m).target))
 val safe=P::safe and
   M.forall(m=>live(m) implies
     ((P::s.members.contains(m) implies covered(m)) and
      (Set(4,5,7).contains(P::s.phase.get(m)) implies localKnown(m)) and
      (g.cells.get(m).process==1 implies g.anchor and covered(m)) and
      (g.cells.get(m).target implies g.cells.get(m).targetReady) and
      (g.cells.get(m).rootsDropped implies localKnown(m) and not(P::s.members.contains(m)) and not(g.cells.get(m).observing) and g.cells.get(m).pins==Set() and not(g.cells.get(m).rawAlias)) and
      (g.cells.get(m).releaseStage>0 implies g.cells.get(m).rootsDropped and g.cells.get(m).pins==Set()))) and
   (g.frozen implies g.manifest==M.filter(m=>live(m) and not(g.cells.get(m).rootsDropped))) and
   (not(g.anchor) implies M.forall(m=>not(live(m)) or g.cells.get(m).releaseStage==2))
 action init=all{P::init,g'=initial}
 action begin=all{g.anchor,not(g.frozen),P::s.attempt==0,P::beginProducer,g'=g}
 action reserve(m)=all{not(g.frozen),g.anchor,P::reserveFromParent(1,m),g'=g}
 action initialize(m)=all{P::initializeMember(1,m),g'=g}
 action publish(m)=all{covered(m),P::publishMember(1,m),g'=g}
 action claim(m)=all{P::claimMember(1,m),g'=g}
 action spawn(m)=reserve(m).then(initialize(m)).then(publish(m)).then(claim(m))
 action derive(parent,m)=all{not(g.frozen),g.anchor,P::reserveFromChild(1,parent,m),g'=g}
 action write(m)=all{P::writeFromChild(1,m),g'=g}
 action parentSuccess=all{P::parentSuccess,g'=g}
 action parentFailure=all{P::parentFailure,g'=g}
 action launch(m)=all{live(m),not(g.cells.get(m).exited),g.cells.get(m).process==0,P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),process:1})}}
 action exit(m)=all{live(m),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),exited:true})}}
 action terminal(m)=all{g.cells.get(m).process==1,P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),process:2})}}
 action closeEffects(m)=all{g.cells.get(m).process!=1,g.cells.get(m).exited,P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),effects:true})}}
 action record(m,v)=all{localKnown(m),covered(m),P::recordMemberResult(1,m,v),g'=g}
 action settle(m)=all{P::settleChild(1,m),g'=g}
 action finish(m)=exit(m).then(closeEffects(m)).then(record(m,0)).then(settle(m))
 action verify=all{P::verifyOutputs,g'=g}
 action seal=all{M.forall(m=>not(live(m)) or localKnown(m)),P::sealSuccessor,g'=g}
 action targetRegister(m)=all{live(m),not(g.frozen),not(g.cells.get(m).rootsDropped),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),target:true,targetReady:true})}}
 action closeSource(m)=all{P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),sourceOpen:false})}}
 action sourcePin(m)=all{g.cells.get(m).sourceOpen,g.cells.get(m).source,not(g.frozen),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),sourcePins:g.cells.get(m).sourcePins+1})}}
 action sourceReturn(m)=all{g.cells.get(m).sourcePins>0,P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),sourcePins:g.cells.get(m).sourcePins-1})}}
 def canDetachSource(m:int):bool=not(g.frozen) and not(g.cells.get(m).sourceOpen) and g.cells.get(m).sourcePins==0 and g.cells.get(m).target and g.cells.get(m).targetReady
 action detachSource(m)=all{canDetachSource(m),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),source:false})}}
 def canObserve(m:int,p:int):bool=g.anchor and live(m) and g.cells.get(m).observing and not(g.cells.get(m).issued.contains(p)) and not(g.cells.get(m).rootsDropped)
 action observe(m,p)=all{canObserve(m,p),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),pins:g.cells.get(m).pins.union(Set(p)),issued:g.cells.get(m).issued.union(Set(p))})}}
 action closeObservers(m)=all{P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),observing:false})}}
 action deliver(m,p)=all{g.cells.get(m).pins.contains(p),localKnown(m),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),pins:g.cells.get(m).pins.exclude(Set(p)),delivered:true})}}
 def canDropRoots(m:int):bool=live(m) and not(g.frozen) and not(P::s.members.contains(m)) and localKnown(m) and not(g.cells.get(m).observing) and g.cells.get(m).pins==Set() and not(g.cells.get(m).rawAlias) and not(g.cells.get(m).sourceOpen) and g.cells.get(m).sourcePins==0
 action dropRoots(m)=all{canDropRoots(m),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),source:false,target:false,rootsDropped:true})}}
 // releaseStage lives OUTSIDE the device being freed. Unknown stage1 is opaque.
 def canBeginRelease(m:int):bool=g.cells.get(m).rootsDropped and g.cells.get(m).releaseStage==0 and not(g.frozen)
 action beginRelease(m)=all{canBeginRelease(m),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),releaseStage:1})}}
 action knownRelease(m)=all{g.cells.get(m).releaseStage==1,P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),releaseStage:2})}}
 action unknownRelease(m)=all{g.cells.get(m).releaseStage==1,P::s'=P::s,g'=g}
 val canDropAnchor=not(P::s.producer) and not(g.frozen) and M.forall(m=>not(live(m)) or g.cells.get(m).releaseStage==2)
 action dropAnchor=all{canDropAnchor,P::s'=P::s,g'={...g,anchor:false}}
 action freeze=all{g.anchor,not(g.frozen),P::s'=P::s,g'={...g,frozen:true,manifest:M.filter(m=>live(m) and not(g.cells.get(m).rootsDropped)),scanned:false}}
 action scan=all{g.frozen,P::s'=P::s,g'={...g,scanned:true}}
 action thaw=all{g.frozen,g.scanned,P::s'=P::s,g'={...g,frozen:false}}
 action escape(m)=all{live(m),not(g.cells.get(m).rootsDropped),P::s'=P::s,g'={...g,cells:g.cells.set(m,{...g.cells.get(m),rawAlias:true})}}
 action start=init.then(begin).then(spawn(0)).then(spawn(1))
 action closeMember(m)=closeSource(m).then(closeObservers(m)).then(dropRoots(m)).then(beginRelease(m)).then(knownRelease(m))
 run wholeGroupRootCoverageTest=start.expect(safe and M.forall(m=>covered(m)))
 run siblingUnknownBlocksSealTest=start.then(write(0)).then(finish(0)).then(launch(1)).then(exit(1)).then(parentSuccess).expect(safe and not(P::canSeal) and covered(1))
 run parentExceptionKeepsFamilyTest=start.then(launch(1)).then(parentFailure).expect(safe and g.anchor and covered(0) and covered(1))
 run targetBeforeSourceDetachTest=start.then(closeSource(0)).expect(safe and not(canDetachSource(0)))
 run targetReadyPreservesCoverageTest=start.then(targetRegister(0)).then(closeSource(0)).then(detachSource(0)).expect(safe and covered(0) and not(g.cells.get(0).source))
 run oldBorrowBlocksDetachTest=start.then(sourcePin(0)).then(targetRegister(0)).then(closeSource(0)).expect(safe and not(canDetachSource(0)))
 run unknownKeepsOriginContextTest=start.then(launch(0)).then(targetRegister(0)).then(closeSource(0)).then(detachSource(0)).expect(safe and contextHeld(0))
 run frozenFamilyBlocksHandoffTest=start.then(targetRegister(0)).then(closeSource(0)).then(freeze).expect(safe and not(canDetachSource(0)) and g.manifest==M)
 run lateObserverBlocksPhysicalReleaseTest=start.then(finish(0)).then(closeSource(0)).then(observe(0,0)).then(closeObservers(0)).expect(safe and not(canDropRoots(0)))
 run sameObserverNumberDifferentMembersTest=start.then(observe(0,0)).then(observe(1,0)).then(finish(0)).then(deliver(0,0)).expect(safe and g.cells.get(1).pins==Set(0))
 run rawAliasRefusesReclamationTest=start.then(finish(0)).then(closeSource(0)).then(closeObservers(0)).then(escape(0)).expect(safe and not(canDropRoots(0)))
 run successorRetainsPinnedFamilyTest=start.then(write(0)).then(finish(0)).then(finish(1)).then(observe(1,0)).then(parentSuccess).then(verify).then(seal).expect(safe and P::s.sealed and g.anchor and not(canDropRoots(1)))
 run knownFamilyPhysicalReleaseTest=start.then(write(0)).then(finish(0)).then(finish(1)).then(parentSuccess).then(verify).then(seal).then(closeMember(0)).then(closeMember(1)).then(dropAnchor).expect(safe and not(g.anchor))
 run unknownReleaseRetainsExternalLedgerTest=start.then(finish(0)).then(closeSource(0)).then(closeObservers(0)).then(dropRoots(0)).then(beginRelease(0)).then(unknownRelease(0)).expect(safe and g.anchor and g.cells.get(0).releaseStage==1 and not(canDropAnchor))
 action uncheckedSourceDrop=all{P::s'=P::s,g'={...g,cells:g.cells.set(0,{...g.cells.get(0),source:false})}}
 run prematureSourceDropNegativeTest=start.then(uncheckedSourceDrop).expect(not(safe))
 action uncheckedKnown=all{P::recordMemberResult(1,1,0),g'=g}
 run oneKnownIsNotAllKnownNegativeTest=start.then(finish(0)).then(launch(1)).then(exit(1)).then(uncheckedKnown).expect(not(safe))
 action discardFailure=all{P::discardFailedCandidate,g'=g}
 run derivedMemberAfterParentErrorTest=init.then(begin).then(spawn(0)).then(parentFailure).then(derive(0,1)).then(initialize(1)).then(publish(1)).then(claim(1)).expect(safe and M.forall(m=>covered(m)))
 run targetRefusalRetainsSourceTest=start.then(closeSource(0)).expect(safe and g.cells.get(0).source and not(canDetachSource(0)))
 run gcScansBothContextsTest=start.then(targetRegister(0)).then(freeze).then(scan).then(thaw).expect(safe and M.forall(m=>covered(m)))
 run exceptionalDrainThenReleaseTest=start.then(parentFailure).then(finish(0)).then(finish(1)).then(discardFailure).then(closeMember(0)).then(closeMember(1)).then(dropAnchor).expect(safe and not(P::s.sealed) and not(g.anchor))
 run unknownReleaseCannotRetryTest=start.then(finish(0)).then(closeSource(0)).then(closeObservers(0)).then(dropRoots(0)).then(beginRelease(0)).then(unknownRelease(0)).expect(safe and not(canBeginRelease(0)) and not(canObserve(0,1)))
 run knownReleaseCannotRetryTest=start.then(finish(0)).then(closeMember(0)).expect(safe and not(canBeginRelease(0)) and not(canObserve(0,1)))
 action step={nondet m=M.oneOf();nondet p=Set(0,1).oneOf();any{begin,reserve(m),initialize(m),publish(m),claim(m),write(m),parentSuccess,parentFailure,launch(m),exit(m),terminal(m),closeEffects(m),record(m,0),record(m,1),settle(m),verify,seal,targetRegister(m),closeSource(m),sourcePin(m),sourceReturn(m),detachSource(m),observe(m,p),closeObservers(m),deliver(m,p),dropRoots(m),beginRelease(m),knownRelease(m),unknownRelease(m),dropAnchor,freeze,scan,thaw,escape(m),discardFailure,all{P::s'=P::s,g'=g}}}
}
