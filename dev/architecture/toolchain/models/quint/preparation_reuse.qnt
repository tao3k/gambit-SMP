// Currentness/provenance companion; no alternative compiler scheduler.
module preparation_reuse {
 type Inputs={production:int,support:int,suite:int,entry:int,native:int,foundation:int}
 type LayerKey={layer:int,production:int,support:int,suite:int,native:int,foundation:int}
 val base:Inputs={production:0,support:0,suite:0,entry:0,native:0,foundation:0}
 def layerKey(x:Inputs,n:int):LayerKey={layer:n,production:x.production,support:if(n>=1) x.support else 0,suite:if(n==2) x.suite else 0,native:x.native,foundation:x.foundation}
 val L=Set(0,1,2)
 type State={input:Inputs,stored:int->LayerKey,epoch:int,pinEpoch:int,closed:bool,aliasesClosed:bool,
   selected:Set[int],producer:bool,unknown:bool,foundationBefore:int,outputs:int,observedOutputs:int,sealed:bool,owned:bool,
   attempt:int,outcome:int,writers:int,descendants:int,declared:Set[int],actual:Set[int],outputsChecked:bool,oldHeld:bool,candidateHeld:bool,childFailed:bool,members:Set[int],issued:Set[int],required:Set[int],phase:int->int,rooted:Set[int],initialized:Set[int],queue:Set[int],starts:int->int,result:int->int,conflict:bool,published:Set[int],noStart:Set[int]}
 val initial:State={input:base,stored:L.mapBy(n=>layerKey(base,n)),epoch:0,pinEpoch:0,closed:true,aliasesClosed:true,
   selected:Set(),producer:false,unknown:false,foundationBefore:0,outputs:0,observedOutputs:0,sealed:false,owned:true,
   attempt:0,outcome:0,writers:0,descendants:0,declared:Set(0),actual:Set(),outputsChecked:false,oldHeld:true,candidateHeld:false,childFailed:false,members:Set(),issued:Set(),required:Set(0),phase:Map(0->0,1->0),rooted:Set(),initialized:Set(),queue:Set(),starts:Map(0->0,1->0),result:Map(0->-1,1->-1),conflict:false,published:Set(),noStart:Set()}
 var s:State
 action init=s'=initial
 def canReuse(n:int):bool=s.closed and s.aliasesClosed and s.pinEpoch==s.epoch and s.stored.get(n)==layerKey(s.input,n)
 action admit(n)=all{canReuse(n),s'={...s,selected:s.selected.union(Set(n))}}
 action admitAll=admit(0).then(admit(1)).then(admit(2))
 action editEntry=s'={...s,input:{...s.input,entry:1},epoch:s.epoch+1,selected:Set(),sealed:false}
 action editSuite=s'={...s,input:{...s.input,suite:1},epoch:s.epoch+1,selected:Set(),sealed:false}
 action editSupport=s'={...s,input:{...s.input,support:1},epoch:s.epoch+1,selected:Set(),sealed:false}
 action editProduction=s'={...s,input:{...s.input,production:1},epoch:s.epoch+1,selected:Set(),sealed:false}
 action editNative=s'={...s,input:{...s.input,native:1},epoch:s.epoch+1,selected:Set(),sealed:false}
 action pinView=all{s.closed,s.aliasesClosed,not(s.producer),s'={...s,pinEpoch:s.epoch}}
 action unknownInputs=s'={...s,closed:false,selected:Set(),sealed:false}
 action escapedAlias=s'={...s,aliasesClosed:false,selected:Set(),sealed:false}
 action beginProducer=all{s.closed,s.aliasesClosed,s.pinEpoch==s.epoch,not(s.producer),s.owned,s.attempt<2,
   s'={...s,producer:true,foundationBefore:s.input.foundation,unknown:false,sealed:false,attempt:s.attempt+1,outcome:0,writers:1,descendants:0,actual:Set(),outputsChecked:false,candidateHeld:true,childFailed:false,members:Set(),issued:Set(),phase:Map(0->0,1->0),rooted:Set(),initialized:Set(),queue:Set(),starts:Map(0->0,1->0),result:Map(0->-1,1->-1),conflict:false,published:Set(),noStart:Set()}}
 action writePrivateOutputs=all{s.producer,Set(0,3).contains(s.outcome),s.writers>0,s'={...s,outputs:s.outputs+1,actual:s.actual.union(Set(0)),outputsChecked:false}}
 action unknownProducer=all{s.producer,s.outcome==0,s'={...s,unknown:true,outcome:3}}
 action changeFoundation=all{s.producer,s'={...s,input:{...s.input,foundation:1},epoch:s.epoch+1,selected:Set(),sealed:false}}
 def canReserveChild(attempt:int,id:int):bool=attempt==s.attempt and s.producer and not(s.issued.contains(id)) and Set(0,1).contains(id) and s.owned
 action reserveFromParent(attempt,id)=all{canReserveChild(attempt,id),Set(0,3).contains(s.outcome),s.writers>0,s'={...s,descendants:s.descendants+1,members:s.members.union(Set(id)),issued:s.issued.union(Set(id)),phase:s.phase.set(id,1),rooted:s.rooted.union(Set(id))}}
 def memberMatches(attempt:int,id:int):bool=s.producer and s.owned and attempt==s.attempt and s.members.contains(id)
 action initializeMember(attempt,id)=all{memberMatches(attempt,id),s.phase.get(id)==1,s.rooted.contains(id),s'={...s,initialized:s.initialized.union(Set(id))}}
 def canPublishMember(attempt:int,id:int):bool=memberMatches(attempt,id) and s.phase.get(id)==1 and s.initialized.contains(id) and s.rooted.contains(id)
 action publishMember(attempt,id)=all{canPublishMember(attempt,id),s'={...s,phase:s.phase.set(id,2),queue:s.queue.union(Set(id)),published:s.published.union(Set(id))}}
 def canClaimMember(attempt:int,id:int):bool=memberMatches(attempt,id) and s.phase.get(id)==2 and s.queue.contains(id) and s.initialized.contains(id) and s.rooted.contains(id) and s.starts.get(id)==0
 action claimMember(attempt,id)=all{canClaimMember(attempt,id),s'={...s,phase:s.phase.set(id,3),queue:s.queue.exclude(Set(id)),starts:s.starts.set(id,1)}}
 action spawnDescendant={val id=if(s.issued.contains(0)) 1 else 0;reserveFromParent(s.attempt,id).then(initializeMember(s.attempt,id)).then(publishMember(s.attempt,id)).then(claimMember(s.attempt,id))}
 def canDerive(attempt:int,parent:int,id:int):bool=canReserveChild(attempt,id) and s.members.contains(parent) and Set(3,6).contains(s.phase.get(parent))
 action reserveFromChild(attempt,parent,id)=all{canDerive(attempt,parent,id),s'={...s,descendants:s.descendants+1,members:s.members.union(Set(id)),issued:s.issued.union(Set(id)),phase:s.phase.set(id,1),rooted:s.rooted.union(Set(id))}}
 action deriveFromChild(attempt,parent,id)=reserveFromChild(attempt,parent,id).then(initializeMember(s.attempt,id)).then(publishMember(s.attempt,id)).then(claimMember(s.attempt,id))
 def canExecuteMember(attempt:int,id:int):bool=memberMatches(attempt,id) and Set(3,6).contains(s.phase.get(id))
 action memberUnknown(attempt,id)=all{canExecuteMember(attempt,id),s'={...s,phase:s.phase.set(id,6)}}
 action recordMemberResult(attempt,id,value)=all{canExecuteMember(attempt,id),Set(0,1).contains(value),
   s'={...s,phase:s.phase.set(id,if(value==0) 4 else 5),result:s.result.set(id,value),childFailed:s.childFailed or value==1}}
 def duplicateResult(attempt:int,id:int,value:int):bool=s.owned and attempt==s.attempt and Set(4,5,7).contains(s.phase.get(id)) and s.result.get(id)==value
 action repeatResult(attempt,id,value)=all{duplicateResult(attempt,id,value),s'=s}
 action conflictingResult(attempt,id,value)=all{s.producer,s.owned,attempt==s.attempt,Set(4,5,7).contains(s.phase.get(id)),s.result.get(id)!=value,s'={...s,conflict:true,sealed:false}}
 def canSettleChild(attempt:int,id:int):bool=memberMatches(attempt,id) and Set(4,5).contains(s.phase.get(id))
 action settleChild(attempt,id)=all{canSettleChild(attempt,id),s'={...s,descendants:s.descendants-1,members:s.members.exclude(Set(id)),phase:s.phase.set(id,7)}}
 action writeFromChild(attempt,id)=all{canExecuteMember(attempt,id),s'={...s,outputs:s.outputs+1,actual:s.actual.union(Set(0)),outputsChecked:false}}

 action finishDescendant={val id=if(s.members.contains(0)) 0 else 1;recordMemberResult(s.attempt,id,0).then(settleChild(s.attempt,id))}
 action finishFailedDescendant={val id=if(s.members.contains(0)) 0 else 1;recordMemberResult(s.attempt,id,1).then(settleChild(s.attempt,id))}
 action parentSuccess=all{s.producer,s.outcome==0,s'={...s,outcome:1,writers:0}}
 action parentFailure=all{s.producer,s.outcome==0,s'={...s,outcome:2,writers:0}}
 def canResolve(attempt:int):bool=s.producer and s.unknown and s.outcome==3 and attempt==s.attempt and s.owned
 action resolveKnownSuccess(attempt)=all{canResolve(attempt),s'={...s,outcome:1,unknown:false,writers:0}}
 action verifyOutputs=all{s.producer,s.outcome==1,s.writers==0,s.descendants==0,not(s.childFailed),s.actual.subseteq(s.declared),s.required.subseteq(s.actual),s'={...s,outputsChecked:true}}
 val canDiscardFailure=s.producer and s.outcome==2 and s.writers==0 and s.descendants==0 and s.owned and s.oldHeld and s.aliasesClosed
 action discardFailedCandidate=all{canDiscardFailure,
   s'={...s,producer:false,candidateHeld:false,outputsChecked:false}}
 action undeclaredWrite=all{s.producer,Set(0,3).contains(s.outcome),s.writers>0,s'={...s,actual:s.actual.union(Set(9)),outputsChecked:false}}
 val canSeal=s.producer and not(s.conflict) and s.outcome==1 and s.writers==0 and s.descendants==0 and not(s.childFailed) and s.outputsChecked and s.actual.subseteq(s.declared) and s.required.subseteq(s.actual) and s.candidateHeld and not(s.unknown) and s.owned and s.closed and s.aliasesClosed and s.pinEpoch==s.epoch and s.foundationBefore==s.input.foundation
 action sealSuccessor=all{canSeal,s'={...s,producer:false,sealed:true,observedOutputs:s.outputs}}
 val safe=s.members.forall(id=>s.rooted.contains(id)) and Set(0,1).forall(id=>s.starts.get(id)<=1 and (Set(2,3,4,5,6,7).contains(s.phase.get(id)) implies (s.initialized.contains(id) or s.noStart.contains(id)) and s.rooted.contains(id))) and s.descendants==s.members.size() and s.members.subseteq(s.issued) and s.selected.forall(n=>canReuse(n)) and (s.producer implies s.owned and s.oldHeld and s.candidateHeld) and (s.sealed implies not(s.conflict) and not(s.producer) and not(s.unknown) and s.owned and s.outcome==1 and s.writers==0 and s.descendants==0 and not(s.childFailed) and s.outputsChecked and s.actual.subseteq(s.declared) and s.required.subseteq(s.actual) and s.observedOutputs==s.outputs)
 action prematureSeal=s'={...s,sealed:true,producer:false,observedOutputs:s.outputs}
 run entryOnlyRetainsLibrariesTest=init.then(editEntry).then(pinView).then(admitAll).expect(safe and s.selected==L)
 run suiteChangeRetainsOtherLayersTest=init.then(editSuite).then(pinView).then(admit(0)).then(admit(1)).expect(safe and not(canReuse(2)))
 run supportChangeInvalidatesDependentsTest=init.then(editSupport).then(pinView).then(admit(0)).expect(safe and not(canReuse(1)) and not(canReuse(2)))
 run productionChangeInvalidatesAllTest=init.then(editProduction).then(pinView).expect(safe and L.forall(n=>not(canReuse(n))))
 run nativeToolInvalidatesLibrariesTest=init.then(editNative).then(pinView).expect(safe and L.forall(n=>not(canReuse(n))))
 run oldViewRefusesTest=init.then(editEntry).expect(safe and not(canReuse(0)))
 run opaqueInputsRefuseReuseTest=init.then(unknownInputs).expect(safe and not(canReuse(0)))
 run escapedAliasRefusesTest=init.then(escapedAlias).expect(safe and not(canReuse(0)))
 run privateOutputSuccessorTest=init.then(beginProducer).then(writePrivateOutputs).then(parentSuccess).then(verifyOutputs).then(sealSuccessor).expect(safe and s.sealed and s.observedOutputs==1)
 run unknownProducerRetainsCustodyTest=init.then(beginProducer).then(writePrivateOutputs).then(unknownProducer).expect(safe and not(canSeal) and s.owned and s.producer)
 run foundationChangeRefusesSuccessorTest=init.then(beginProducer).then(changeFoundation).expect(safe and not(canSeal) and s.owned)
 run unknownCannotPublishControlTest=init.then(beginProducer).then(unknownProducer).then(prematureSeal).expect(not(safe))
 run oldImmediateSealControlTest=init.then(beginProducer).then(writePrivateOutputs).then(prematureSeal).expect(not(safe))
 run parentSuccessNotGroupQuiescenceTest=init.then(beginProducer).then(spawnDescendant).then(parentSuccess).expect(safe and not(canSeal) and s.owned and s.candidateHeld)
 run descendantsDrainBeforePublishTest=init.then(beginProducer).then(writePrivateOutputs).then(spawnDescendant).then(parentSuccess).then(finishDescendant).then(verifyOutputs).then(sealSuccessor).expect(safe and s.sealed)
 run failedParentRetainsSiblingTest=init.then(beginProducer).then(spawnDescendant).then(parentFailure).expect(safe and s.producer and s.descendants==1 and s.oldHeld and s.candidateHeld)
 run failedCandidateDiscardAfterDrainTest=init.then(beginProducer).then(spawnDescendant).then(parentFailure).then(finishDescendant).then(discardFailedCandidate).expect(safe and not(s.producer) and s.oldHeld and not(s.candidateHeld))
 run staleAttemptCannotResolveTest=init.then(beginProducer).then(unknownProducer).expect(safe and not(canResolve(0)) and canResolve(1))
 run resolvedSuccessStillNeedsChildDrainTest=init.then(beginProducer).then(spawnDescendant).then(unknownProducer).then(resolveKnownSuccess(1)).expect(safe and not(canSeal) and s.descendants==1)
 run undeclaredWriterRefusesTest=init.then(beginProducer).then(undeclaredWrite).then(parentSuccess).expect(safe and not(s.actual.subseteq(s.declared)) and not(canSeal))

 // Finite actual-read closure companion. Resource IDs classify read capabilities,
 // not package names. Source extraction and opaque native reads remain open.
 val Q=Set(0,1,2,3)
 val parents=Map(0->Set(),1->Set(0),2->Set(1),3->Set(2))
 val direct=Map(0->Set(0,4,5,6,7,8,10,11,12),1->Set(1,9),2->Set(2),3->Set(3))
 def expandQueries(xs:Set[int],ps:int->Set[int]):Set[int]=xs.union(xs.fold(Set(),(acc,n)=>acc.union(ps.get(n))))
 def closure(xs:Set[int],ps:int->Set[int]):Set[int]=expandQueries(expandQueries(expandQueries(expandQueries(xs,ps),ps),ps),ps)
 def footprint(n:int,ds:int->Set[int],ps:int->Set[int]):Set[int]=closure(Set(n),ps).fold(Set(),(acc,q)=>acc.union(ds.get(q)))
 def impacted(changed:Set[int],ds:int->Set[int],ps:int->Set[int]):Set[int]=Q.filter(q=>footprint(q,ds,ps).intersect(changed)!=Set())
 def acyclic(ps:int->Set[int]):bool=Q.forall(q=>not(closure(ps.get(q),ps).contains(q)))
 run entryTraceOnlyInvalidatesEntryTest=all{impacted(Set(3),direct,parents)==Set(3),acyclic(parents)}
 run suiteTraceInvalidatesConsumersTest=all{impacted(Set(2),direct,parents)==Set(2,3)}
 run macroExecutableTraceInvalidatesAllTest=all{impacted(Set(4),direct,parents)==Q}
 run negativeLookupTraceInvalidatesAllTest=all{impacted(Set(5),direct,parents)==Q}
 run readerTraceInvalidatesAllTest=all{impacted(Set(7),direct,parents)==Q}
 run optimizerTraceInvalidatesSupportTest=all{impacted(Set(9),direct,parents)==Set(1,2,3)}
 run declaredExtraInputTraceInvalidatesAllTest=all{impacted(Set(10),direct,parents)==Q}
 run macroReadsEntryInvalidatesLibrariesTest=all{val dynamic=direct.set(0,direct.get(0).union(Set(3)));impacted(Set(3),dynamic,parents)==Q}
 run queryCycleRefusesReusablePlanTest=all{not(acyclic(parents.set(0,Set(3))))}
 run packageMetadataTraceInvalidatesAllTest=all{impacted(Set(8),direct,parents)==Q}
 run nativePackageQueryTraceInvalidatesAllTest=all{impacted(Set(11),direct,parents)==Q}
 run failedDescendantRefusesGroupTest=init.then(beginProducer).then(spawnDescendant).then(parentSuccess).then(finishFailedDescendant).expect(safe and s.childFailed and not(canSeal) and s.candidateHeld)
 run unknownAliasPreventsDiscardTest=init.then(beginProducer).then(parentFailure).then(escapedAlias).expect(safe and not(canDiscardFailure) and s.candidateHeld)
 run compilerContextPolicyInvalidatesGenerationTest=all{impacted(Set(12),direct,parents)==Q}
 run childDerivesAfterParentReturnTest=init.then(beginProducer).then(spawnDescendant).then(parentSuccess).then(deriveFromChild(1,0,1)).then(writeFromChild(1,1)).then(recordMemberResult(1,0,0)).then(settleChild(1,0)).then(recordMemberResult(1,1,0)).then(settleChild(1,1)).then(verifyOutputs).then(sealSuccessor).expect(safe and s.sealed)
 run childDerivesAfterFailureKeepsCustodyTest=init.then(beginProducer).then(spawnDescendant).then(parentFailure).then(deriveFromChild(1,0,1)).then(writeFromChild(1,1)).expect(safe and s.members==Set(0,1) and s.candidateHeld and not(canDiscardFailure))
 run childReleaseRevokesDerivationTest=init.then(beginProducer).then(spawnDescendant).then(parentSuccess).then(recordMemberResult(1,0,0)).then(settleChild(1,0)).expect(safe and not(canDerive(1,0,1)) and not(canSeal))
 run duplicateMemberResultCannotDrainSiblingTest=init.then(beginProducer).then(spawnDescendant).then(spawnDescendant).then(parentSuccess).then(recordMemberResult(1,0,0)).then(settleChild(1,0)).expect(safe and not(canSettleChild(1,0)) and s.members==Set(1) and not(canSeal))
 run staleChildAttemptCannotSettleNewTest=init.then(beginProducer).then(spawnDescendant).then(parentFailure).then(finishDescendant).then(discardFailedCandidate).then(beginProducer).then(spawnDescendant).then(recordMemberResult(2,0,0)).expect(safe and not(canSettleChild(1,0)) and canSettleChild(2,0))
 run requiredOutputMissingRefusesTest=init.then(beginProducer).then(parentSuccess).expect(safe and not(s.required.subseteq(s.actual)) and not(canSeal))
 // Registration/publication/claim are one-group-lock abstract operations.
 run reservedMemberBlocksSuccessorTest=init.then(beginProducer).then(reserveFromParent(1,0)).then(parentSuccess).expect(safe and s.members==Set(0) and not(canSeal))
 run initializeBeforePublishTest=init.then(beginProducer).then(reserveFromParent(1,0)).expect(safe and not(canPublishMember(1,0)))
 run publishedNotStartedIsOwnedTest=init.then(beginProducer).then(reserveFromParent(1,0)).then(initializeMember(1,0)).then(publishMember(1,0)).expect(safe and s.starts.get(0)==0 and s.members.contains(0))
 run duplicateClaimRefusesTest=init.then(beginProducer).then(spawnDescendant).expect(safe and not(canClaimMember(1,0)) and s.starts.get(0)==1)
 run runningCannotSettleTest=init.then(beginProducer).then(spawnDescendant).expect(safe and not(canSettleChild(1,0)))
 run unknownMemberRetainsGrantTest=init.then(beginProducer).then(spawnDescendant).then(memberUnknown(1,0)).expect(safe and canDerive(1,0,1) and not(canSettleChild(1,0)))
 run duplicateResultIsNoOpTest=init.then(beginProducer).then(spawnDescendant).then(recordMemberResult(1,0,0)).then(repeatResult(1,0,0)).then(settleChild(1,0)).then(repeatResult(1,0,0)).expect(safe and s.descendants==0)
 run conflictingResultsBlockSealTest=init.then(beginProducer).then(spawnDescendant).then(writeFromChild(1,0)).then(recordMemberResult(1,0,0)).then(settleChild(1,0)).then(parentSuccess).then(verifyOutputs).then(conflictingResult(1,0,1)).expect(safe and s.conflict and not(canSeal))
 run parentUnknownIsNotGrantRevocationTest=init.then(beginProducer).then(unknownProducer).then(spawnDescendant).expect(safe and s.members.contains(0) and not(canSeal))
 def publicationKnown(attempt:int,id:int):bool=s.owned and attempt==s.attempt and s.published.contains(id)
 action repeatedPublishLookup(attempt,id)=all{publicationKnown(attempt,id),s'=s}
 action constructorFailedBeforePublish(attempt,id)=all{memberMatches(attempt,id),s.phase.get(id)==1,not(s.published.contains(id)),
   s'={...s,phase:s.phase.set(id,5),noStart:s.noStart.union(Set(id)),result:s.result.set(id,1),childFailed:true}}
 run constructorFailureSettlesWithoutStartTest=init.then(beginProducer).then(reserveFromParent(1,0)).then(constructorFailedBeforePublish(1,0)).then(settleChild(1,0)).then(parentFailure).then(discardFailedCandidate).expect(safe and s.starts.get(0)==0 and s.oldHeld and not(s.candidateHeld))
 run publicationAckLossLookupTest=init.then(beginProducer).then(reserveFromParent(1,0)).then(initializeMember(1,0)).then(publishMember(1,0)).then(repeatedPublishLookup(1,0)).then(claimMember(1,0)).then(repeatedPublishLookup(1,0)).expect(safe and s.starts.get(0)==1 and not(canClaimMember(1,0)))
 run settledRecordRetainsExactReplyTest=init.then(beginProducer).then(spawnDescendant).then(recordMemberResult(1,0,0)).then(settleChild(1,0)).expect(safe and duplicateResult(1,0,0) and not(duplicateResult(0,0,0)) and publicationKnown(1,0))
 action loseCarrierRootControl(id)=s'={...s,rooted:s.rooted.exclude(Set(id))}
 run unrootedCarrierCannotPublishControlTest=init.then(beginProducer).then(reserveFromParent(1,0)).then(initializeMember(1,0)).then(loseCarrierRootControl(0)).expect(not(safe) and not(canPublishMember(1,0)))
 run wrongAttemptCannotPublishMemberTest=init.then(beginProducer).then(reserveFromParent(1,0)).then(initializeMember(1,0)).expect(safe and not(canPublishMember(0,0)))
 run sameDiagnosticNameDoesNotMergeMembersTest=init.then(beginProducer).then(spawnDescendant).then(spawnDescendant).expect(safe and s.members==Set(0,1) and s.starts.get(0)==1 and s.starts.get(1)==1)
 run staleRootAndChildGrantCannotRegisterNewTest=init.then(beginProducer).then(spawnDescendant).then(parentFailure).then(finishDescendant).then(discardFailedCandidate).then(beginProducer).then(spawnDescendant).expect(safe and not(canReserveChild(1,1)) and not(canDerive(1,0,1)) and canDerive(2,0,1))
}
