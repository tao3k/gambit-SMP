module target_stage_sealing {
  import target_sealing_parameters.* from "./target_sealing_parameters"
  pure val N=0.to(Capacity-1)
  type Observation = { decl: List[int], identity: int, origin: int }
  type State = { admission: bool, writers: Set[int], aliases: Set[int], snapshot: bool,
    frozen: Observation, now: Observation, copies: Set[int], consumed: Set[int], snapshotIntact: bool,
    exclusive: bool, exclusiveConsumed: bool, cacheCredential: bool, known: bool, success: bool,
    contextLive: bool, published: bool, errorDelivered: bool }
  pure val observation:Observation={decl:List(1,2),identity:0,origin:0}
  pure val initial:State={admission:true,writers:Set(0),aliases:Set(0),snapshot:false,
    frozen:observation,now:observation,copies:Set(),consumed:Set(),snapshotIntact:true,
    exclusive:false,exclusiveConsumed:false,cacheCredential:false,known:true,success:true,
    contextLive:true,published:false,errorDelivered:false}
  var s: State
  action init=s'=initial
  action joinWriter(n)=all {s.admission,s.contextLive,not(s.writers.contains(n)),s'={...s,writers:s.writers.union(Set(n))}}
  action closeAdmission=all {s.contextLive,s.admission,s'={...s,admission:false}}
  action settleWriter(n)=all {s.writers.contains(n),s'={...s,writers:s.writers.exclude(Set(n))}}
  action closeAlias(n)=all {s.aliases.contains(n),s'={...s,aliases:s.aliases.exclude(Set(n))}}
  def freezeReady=not(s.admission) and s.writers.size()==0 and s.aliases.size()==0 and s.contextLive and s.known and s.success
  action sealSnapshot=all {freezeReady,not(s.exclusive),s'={...s,snapshot:true,frozen:s.now,cacheCredential:true}}
  action materialize(n)=all {s.snapshot,s.snapshotIntact,not(s.copies.contains(n)),
    s'={...s,copies:s.copies.union(Set(n))}}
  action consumePrivate(n)=all {s.copies.contains(n),not(s.consumed.contains(n)),s'={...s,consumed:s.consumed.union(Set(n))}}
  action transferExclusive=all {freezeReady,not(s.snapshot),not(s.exclusive),s'={...s,exclusive:true,cacheCredential:false}}
  action consumeExclusive=all {s.exclusive,not(s.exclusiveConsumed),s'={...s,exclusiveConsumed:true}}
  action unknownOutcome=all {not(s.published),s.contextLive,s'={...s,known:false,success:false}}
  action settleOutcome=all {not(s.known),s'={...s,known:true,success:false}}
  action deliverError=all {s.known,not(s.success),s'={...s,errorDelivered:true}}
  def canRelease=not(s.admission) and s.writers.size()==0 and s.aliases.size()==0 and s.known and
    (not(s.exclusive) or s.exclusiveConsumed) and (s.success or s.errorDelivered)
  action releaseContext=all {s.contextLive,canRelease,s'={...s,contextLive:false}}
  def canPublish=s.snapshot and s.snapshotIntact and s.consumed.size()>0 and s.known and s.success and s.frozen==s.now
  action publish=all {canPublish,s'={...s,published:true}}
  action changeOrigin=all {not(s.published),s'={...s,now:{...s.now,origin:1}}}
  action changeIdentity=all {not(s.published),s'={...s,now:{...s.now,identity:1}}}
  action changeDeclaration=all {not(s.published),s'={...s,now:{...s.now,decl:List(2,1)}}}
  def safe=(s.snapshot implies not(s.admission) and s.writers.size()==0 and s.aliases.size()==0 and s.snapshotIntact and not(s.exclusive)) and
    (s.cacheCredential implies s.snapshot and not(s.exclusive)) and (s.published implies canPublish) and
    (not(s.contextLive) implies canRelease)
  action step={
    nondet n=N.oneOf()
    any {joinWriter(n),closeAdmission,settleWriter(n),closeAlias(n),sealSnapshot,materialize(n),consumePrivate(n),
      transferExclusive,consumeExclusive,unknownOutcome,settleOutcome,deliverError,releaseContext,
      publish,changeOrigin,changeIdentity,changeDeclaration,s'=s}
  }
  action forceSeal=s'={...s,snapshot:true,cacheCredential:true}
  action mutateSnapshot=s'={...s,snapshotIntact:false}
  action cacheExclusive=s'={...s,cacheCredential:true}
  action forcePublish=s'={...s,published:true}
  action forceRelease=s'={...s,contextLive:false}
  run writerDrainTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).expect(safe and s.snapshot)
  run lateWriterDeniedTest=init.then(closeAdmission).expect(safe and not(s.admission))
  run twoPrivateConsumersTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).then(materialize(0)).then(materialize(1)).then(consumePrivate(0)).then(consumePrivate(1)).expect(safe and s.snapshotIntact and s.consumed.size()==2)
  run releaseAfterSealTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).then(releaseContext).then(materialize(0)).then(consumePrivate(0)).then(publish).expect(safe and s.published)
  run exclusiveSingleTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(transferExclusive).then(consumeExclusive).then(releaseContext).expect(safe and not(s.cacheCredential))
  run unknownHoldsTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(unknownOutcome).expect(safe and not(canRelease))
  run errorDeliveryTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(unknownOutcome).then(settleOutcome).then(deliverError).then(releaseContext).expect(safe and not(s.published))
  run originRejectTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).then(materialize(0)).then(consumePrivate(0)).then(changeOrigin).expect(safe and not(canPublish))
  run declarationRejectTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).then(changeDeclaration).expect(safe and s.frozen!=s.now)
  run identityRejectTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).then(changeIdentity).expect(safe and s.frozen!=s.now)
  run activeWriterSealControlTest=init.then(closeAlias(0)).then(closeAdmission).then(forceSeal).expect(not(safe))
  run retainedAliasSealControlTest=init.then(closeAdmission).then(settleWriter(0)).then(forceSeal).expect(not(safe))
  run snapshotMutationControlTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).then(mutateSnapshot).expect(not(safe))
  run exclusiveCacheControlTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(transferExclusive).then(cacheExclusive).expect(not(safe))
  run originIgnoredControlTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(sealSnapshot).then(materialize(0)).then(consumePrivate(0)).then(changeOrigin).then(forcePublish).expect(not(safe))
  run unknownReleaseControlTest=init.then(closeAdmission).then(settleWriter(0)).then(closeAlias(0)).then(unknownOutcome).then(forceRelease).expect(not(safe))
}
