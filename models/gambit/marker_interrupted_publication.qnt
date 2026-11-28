module marker_interrupted_publication {
  // One operation in physical domain 1; original writer0 and potential helper1.
  // Abstract atomic pointer stores, not arbitrary C-machine interruption/weak memory.
  type State={intent:bool,valid:bool,head:int,next:int,nextAck:bool,headAck:bool,
    root:bool,prepared:bool,decision:int,commitAck:bool,events:int,
    writers:Set[int],closed:Set[int],dead:Set[int],pending:int->int,generation:int,
    authority:int,permit:bool,input:bool,phase:int,lost:bool,record:bool,
    recordPins:int,late:bool,counter:int,freed:bool,unrootedAccess:bool}
  var s:State
  val actors=Set(0,1)
  val drained=s.writers.subseteq(s.closed) and actors.forall(a=>s.pending.get(a)==0)
  val safe=s.events<=1 and s.counter==0 and not(s.late) and not(s.freed) and not(s.unrootedAccess) and
    (s.head!=1 or (s.intent and s.valid and s.next==0)) and
    (not(s.nextAck) or s.next==0) and (not(s.headAck) or s.head==1) and
    (s.decision!=1 or (s.root and s.prepared and s.head==1 and s.events==1)) and
    (not(s.commitAck) or s.decision==1) and
    (s.permit or (s.decision==1 and s.root and drained)) and
    (s.phase!=2 or (not(s.permit) and drained and s.root)) and
    s.closed.forall(a=>s.pending.get(a)==0) and
    (s.record or s.recordPins==0) and (not(s.permit) or s.input)
  action init=s'={intent:false,valid:true,head:0,next:(-1),nextAck:false,headAck:false,
    root:false,prepared:false,decision:0,commitAck:false,events:0,writers:Set(0),
    closed:Set(),dead:Set(),pending:actors.mapBy(a=>0),generation:1,authority:0,
    permit:true,input:true,phase:0,lost:false,record:true,recordPins:1,late:false,
    counter:0,freed:false,unrootedAccess:false}
  def allowed(a)=s.permit and s.authority==a and not(s.closed.contains(a)) and
    not(s.dead.contains(a)) and s.pending.get(a)==0
  action publishIntent=all{allowed(s.authority),s.permit,not(s.intent),s.valid,s'={...s,intent:true}}
  action issueNext(a)=all{allowed(a),s.intent,s.head==0,
    s'={...s,pending:s.pending.set(a,1)}}
  action issueHead(a)=all{allowed(a),s.intent,s.head==0,s.next==0,
    s'={...s,pending:s.pending.set(a,2)}}
  action issueCommit(a)=all{allowed(a),s.root,s.prepared,s.decision==0,
    s'={...s,pending:s.pending.set(a,3)}}
  // An already-issued store does not re-check generation at its physical effect.
  action applyStore(a)=all{s.pending.get(a)>0,not(s.closed.contains(a)),
    s'={...s,next:if(s.pending.get(a)==1) 0 else s.next,
      head:if(s.pending.get(a)==2) 1 else s.head,
      decision:if(s.pending.get(a)==3) 1 else s.decision,
      events:if(s.pending.get(a)==3 and s.decision==0) s.events+1 else s.events,
      pending:s.pending.set(a,0),late:s.late or not(s.permit) or s.phase==2}}
  // Interrupted private next-write can be unreadable; helper overwrites only if head remains old.
  action interruptNext(a)=all{s.pending.get(a)==1,s.head==0,
    s'={...s,next:(-7),pending:s.pending.set(a,0)}}
  action acknowledgeNext=all{s.next==0,s'={...s,nextAck:true}}
  action acknowledgeHead=all{s.head==1,s.next==0,s'={...s,headAck:true}}
  action installRoot=all{allowed(s.authority),s.head==1,s.next==0,s.permit,s'={...s,root:true}}
  action prepareDecision=all{allowed(s.authority),s.root,s.permit,s'={...s,prepared:true}}
  action partialDecision=all{allowed(s.authority),s.root,s.permit,s.decision==0,s'={...s,prepared:false}}
  action acknowledgeCommit=all{s.decision==1,s'={...s,commitAck:true}}
  action logicalDeath(a)=all{s.writers.contains(a),s'={...s,dead:s.dead.union(Set(a))}}
  // Successful exact native termination/join is an EXTERNAL premise and drains final pending effects.
  // Other histories applyStore first, then terminate: commit/link ACK may still be absent.
  action joinedStop(a)=all{s.dead.contains(a),s.record,s.valid,
    s'={...s,closed:s.closed.union(Set(a)),pending:s.pending.set(a,0)}}
  action cooperativeStop(a)=all{s.writers.contains(a),s.pending.get(a)==0,
    s'={...s,closed:s.closed.union(Set(a))}}
  action revokeGeneration=all{s.permit,s'={...s,generation:s.generation+1}}
  action takeOver=all{s.authority==0,s.closed.contains(0),s.pending.get(0)==0,s.record,s.valid,
    s'={...s,authority:1,writers:s.writers.union(Set(1)),generation:s.generation+1}}
  action loseResponse=all{s.decision==1,s'={...s,lost:true}}
  action query=all{s.record,s.recordPins>0,s'={...s,lost:false}}
  action closeGc=all{s.phase==0,s'={...s,phase:1}}
  action releasePermit=all{s.permit,s.decision==1,s.root,drained,
    s'={...s,permit:false,input:false}}
  action freeze=all{s.phase==1,not(s.permit),drained,s.root,s'={...s,phase:2}}
  action metadataPin=all{s.record,s'={...s,recordPins:s.recordPins+1}}
  action metadataUnpin=all{s.recordPins>0,s'={...s,recordPins:s.recordPins-1}}
  action retireRecord=all{not(s.permit),drained,s.recordPins==0,s'={...s,record:false}}
  action stutter=s'=s
  action step={nondet a=actors.oneOf();any{publishIntent,issueNext(a),issueHead(a),issueCommit(a),
    applyStore(a),interruptNext(a),acknowledgeNext,acknowledgeHead,installRoot,prepareDecision,
    partialDecision,acknowledgeCommit,logicalDeath(a),joinedStop(a),cooperativeStop(a),
    revokeGeneration,takeOver,loseResponse,query,closeGc,releasePermit,freeze,
    metadataPin,metadataUnpin,retireRecord,stutter}}
  action nextStore(a)=issueNext(a).then(applyStore(a))
  action headStore(a)=issueHead(a).then(applyStore(a))
  action commitStore(a)=issueCommit(a).then(applyStore(a))
  action linked=init.then(publishIntent).then(nextStore(0)).then(headStore(0))
  action ready=linked.then(installRoot).then(prepareDecision)
  action complete=ready.then(commitStore(0)).then(cooperativeStop(0)).then(releasePermit)
  action helperInit=init.then(publishIntent).then(logicalDeath(0)).then(joinedStop(0)).then(takeOver)
  action badJournalLead=s'={...s,headAck:true}
  action badPushAgain=all{s.head==1,s'={...s,next:1}}
  action badCounterReplay=s'={...s,counter:s.counter+1}
  action badRelease=all{s.decision==1,s'={...s,permit:false,input:false}}
  action badFree=all{s.head==1,s'={...s,freed:true}}
  action badDecisionNoRoot=s'={...s,decision:1,events:1,root:false}
  action badTrustLogicalDeath=all{s.dead.contains(0),s.pending.get(0)>0,
    s'={...s,closed:s.closed.union(Set(0))}}
  action badTakeover=all{not(s.closed.contains(0)),s'={...s,authority:1,writers:s.writers.union(Set(1))}}
  action badHelperStop=all{s.pending.get(1)>0,s'={...s,closed:s.closed.union(Set(1))}}
  action badFreeRecord=s'={...s,record:false}
  action badRawAccess=s'={...s,unrootedAccess:true}
  action badUncertainHead=s'={...s,head:2,valid:false}
  // source-admitted invariant additionally refuses lost domain/intent provenance.
  val admitted=safe and s.valid and (s.authority!=1 or s.closed.contains(0))
  run ordinaryCommitTest=complete.then(closeGc).then(freeze).then(all{assert(admitted),s'=s})
  run nextStoreAckLossTest=init.then(publishIntent).then(nextStore(0)).then(logicalDeath(0)).then(joinedStop(0)).then(takeOver).then(nextStore(1)).then(headStore(1)).then(all{assert(not(s.nextAck) and admitted),s'=s})
  run headStoreAckLossTest=linked.then(logicalDeath(0)).then(joinedStop(0)).then(takeOver).then(acknowledgeHead).then(all{assert(s.head==1 and s.next==0 and admitted),s'=s})
  run interruptedNextReconstructionTest=init.then(publishIntent).then(issueNext(0)).then(interruptNext(0)).then(logicalDeath(0)).then(joinedStop(0)).then(takeOver).then(nextStore(1)).then(headStore(1)).then(all{assert(admitted),s'=s})
  run deathBeforeIssuedHeadTest=init.then(publishIntent).then(nextStore(0)).then(issueHead(0)).then(logicalDeath(0)).then(joinedStop(0)).then(takeOver).then(headStore(1)).then(all{assert(admitted),s'=s})
  run storeAfterLogicalDeathTest=init.then(publishIntent).then(nextStore(0)).then(issueHead(0)).then(logicalDeath(0)).then(applyStore(0)).then(joinedStop(0)).then(takeOver).then(all{assert(s.head==1 and admitted),s'=s})
  run generationDoesNotDrainTest=init.then(publishIntent).then(nextStore(0)).then(issueHead(0)).then(revokeGeneration).then(all{assert(s.pending.get(0)==2 and admitted),s'=s})
  run lateStoreUnderRetainedLeaseTest=init.then(publishIntent).then(nextStore(0)).then(issueHead(0)).then(revokeGeneration).then(applyStore(0)).then(all{assert(admitted),s'=s})
  run unknownStopBlocksGcTest=linked.then(logicalDeath(0)).then(closeGc).then(all{assert(s.permit and not(s.closed.contains(0)) and admitted),s'=s})
  run partialDecisionRebuiltTest=linked.then(installRoot).then(partialDecision).then(logicalDeath(0)).then(joinedStop(0)).then(takeOver).then(prepareDecision).then(commitStore(1)).then(all{assert(admitted),s'=s})
  run commitStoreAckLossTest=ready.then(commitStore(0)).then(logicalDeath(0)).then(joinedStop(0)).then(takeOver).then(query).then(acknowledgeCommit).then(all{assert(s.events==1 and admitted),s'=s})
  run commitNotAppliedBeforeStopTest=ready.then(issueCommit(0)).then(logicalDeath(0)).then(joinedStop(0)).then(takeOver).then(commitStore(1)).then(all{assert(s.events==1 and admitted),s'=s})
  run commitAppliedBeforeStopTest=ready.then(issueCommit(0)).then(logicalDeath(0)).then(applyStore(0)).then(joinedStop(0)).then(takeOver).then(query).then(all{assert(s.events==1 and admitted),s'=s})
  run nullBeforeStopIsPendingTest=ready.then(issueCommit(0)).then(query).then(all{assert(s.decision==0 and s.pending.get(0)==3 and admitted),s'=s})
  run queryDoesNotReplayTest=complete.then(loseResponse).then(query).then(query).then(all{assert(s.events==1 and s.counter==0 and admitted),s'=s})
  run helperWriterMustStopTest=helperInit.then(nextStore(1)).then(headStore(1)).then(installRoot).then(prepareDecision).then(commitStore(1)).then(closeGc).then(all{assert(s.permit and not(s.closed.contains(1)) and admitted),s'=s})
  run helperClosureAllowsGcTest=helperInit.then(nextStore(1)).then(headStore(1)).then(installRoot).then(prepareDecision).then(commitStore(1)).then(cooperativeStop(1)).then(releasePermit).then(closeGc).then(freeze).then(all{assert(admitted),s'=s})
  run metadataReaderDoesNotBlockGcTest=complete.then(metadataPin).then(closeGc).then(freeze).then(all{assert(s.recordPins==2 and admitted),s'=s})
  run recordRetirementTest=complete.then(metadataUnpin).then(retireRecord).then(all{assert(not(s.record) and admitted),s'=s})
  run journalLeadsDataCounterexampleTest=init.then(publishIntent).then(badJournalLead).then(all{assert(not(admitted)),s'=s})
  run repeatedHeadPushCounterexampleTest=linked.then(badPushAgain).then(all{assert(not(admitted)),s'=s})
  run numericReplayCounterexampleTest=complete.then(badCounterReplay).then(all{assert(not(admitted)),s'=s})
  run decisionWithoutStopCounterexampleTest=ready.then(commitStore(0)).then(badRelease).then(all{assert(not(admitted)),s'=s})
  run freeLinkedCounterexampleTest=linked.then(badFree).then(all{assert(not(admitted)),s'=s})
  run unrootedDecisionCounterexampleTest=ready.then(badDecisionNoRoot).then(all{assert(not(admitted)),s'=s})
  run logicalDeathIsNotStopCounterexampleTest=ready.then(issueCommit(0)).then(logicalDeath(0)).then(badTrustLogicalDeath).then(all{assert(not(admitted)),s'=s})
  run takeoverWithoutStopCounterexampleTest=linked.then(logicalDeath(0)).then(badTakeover).then(all{assert(not(admitted)),s'=s})
  run helperPendingStopCounterexampleTest=helperInit.then(issueNext(1)).then(badHelperStop).then(all{assert(not(admitted)),s'=s})
  run reclaimPinnedRecordCounterexampleTest=complete.then(badFreeRecord).then(all{assert(not(admitted)),s'=s})
  run rawPointerAccessCounterexampleTest=complete.then(badRawAccess).then(all{assert(not(admitted)),s'=s})
  run unexpectedHeadCounterexampleTest=linked.then(badUncertainHead).then(all{assert(not(admitted)),s'=s})
  run lateIssuedHeadAfterRevokeCounterexampleTest=init.then(publishIntent).then(nextStore(0)).then(issueHead(0)).then(logicalDeath(0)).then(revokeGeneration).then(badTakeover).then(headStore(1)).then(installRoot).then(prepareDecision).then(commitStore(1)).then(cooperativeStop(1)).then(badRelease).then(applyStore(0)).then(all{assert(s.late and not(admitted)),s'=s})
  action negativeInit=ready.then(commitStore(0))
  action negativeStep=badRelease
}
