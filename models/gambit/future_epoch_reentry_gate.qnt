// One owned asynchronous task, producer publication and two epochs; native/source gates are premises.
module future_epoch_reentry_gate {
  // loc: absent0, queued1, claimed2, running3, parked-current4, future5, completed6.
  type S={loc:int,epoch:int,phase:int,gate:bool,producer:bool,pub:bool,issued:bool,
    write:bool,park:bool,vm:bool,root:bool,resource:bool,manifest:bool,asyncOk:bool,
    futureSeal:bool,oldSeal:bool,roundDone:bool,notified:bool,ctx:bool,bound:bool,reload:int,rootVersion:int,
    lease:int,starts:int,escaped:bool,lost:bool}
  var s:S
  action init=s'={loc:1,epoch:0,phase:0,gate:true,producer:true,pub:false,issued:false,
    write:false,park:false,vm:true,root:true,resource:true,manifest:true,asyncOk:true,
    futureSeal:false,oldSeal:false,roundDone:false,notified:false,ctx:true,bound:true,reload:0,rootVersion:0,
    lease:-1,starts:0,escaped:false,lost:false}
  action runningInit=init.then(all{s'={...s,loc:3,write:true,lease:0,starts:1}})
  action absentInit=init.then(all{s'={...s,loc:0}})
  action reservePublication=all{s.loc==0,s.producer,not(s.pub),s'={...s,pub:true}}
  action publishTask=all{s.loc==0,s.pub,s'={...s,loc:1}}
  // Ticket covers h->nextReady writes, queue publication and later PSTATE wakeup.
  action finishPublication=all{s.pub,s.loc==1,s'={...s,pub:false}}
  action closeProducer=all{s.producer,s'={...s,producer:false}}
  action closeEntry=all{s.epoch==0,s.phase==0,s'={...s,gate:false,phase:1}}
  action claimCurrent=all{s.loc==1,s.gate,s.phase==0,s'={...s,loc:2,lease:0}}
  action issueNative=all{s.loc==2,not(s.issued),s'={...s,issued:true}}
  val fresh=s.ctx and s.bound and s.reload==s.rootVersion and s.lease==s.epoch
  action start=all{s.loc==2,s.issued,fresh,s.phase!=2,
    s'={...s,loc:3,write:true,starts:s.starts+1}}
  action writeEffect=all{s.loc==3,s.write,fresh,s.phase!=2,s'=s}
  action finish=all{s.loc==3,s'={...s,loc:6,write:false,issued:false}}
  // Parked is an existing native activation; it is never reclassified as an unstarted task.
  action parkCurrent=all{s.loc==3,s.epoch==0,s.vm,s.root,
    s'={...s,loc:4,write:false,park:true,issued:false}}
  action deferQueued=all{s.loc==1,not(s.gate),not(s.producer),not(s.pub),s.asyncOk,s.manifest,s.vm,s.root,s.resource,not(s.issued),
    s'={...s,loc:5,futureSeal:true}}
  // Cancel versus issue must be one exclusion domain; unknown already-issued invocation cannot use this edge.
  action cancelUnissuedClaim=all{s.loc==2,not(s.issued),not(s.gate),not(s.producer),not(s.pub),s.asyncOk,s.manifest,
    s'={...s,loc:5,lease:-1,futureSeal:true}}
  val currentClosed=s.loc==0 or s.loc==5 or s.loc==6 or (s.loc==4 and s.park and not(s.write))
  action freeze=all{s.phase==1,not(s.gate),not(s.producer),not(s.pub),not(s.issued),currentClosed,s.vm,(s.loc==0 or s.loc==6 or (s.root and s.resource)),s.manifest,
    s'={...s,phase:2,oldSeal:true,ctx:false,bound:false}}
  // Separate GC completion from entry closure; neither notification nor seal prepares context.
  action collectRound=all{s.phase==2,not(s.roundDone),s'={...s,roundDone:true,rootVersion:1}}
  action notifyGc=all{s.phase==2,s.roundDone,s'={...s,notified:true}}
  action prepareContext=all{s.phase==2,s.roundDone,s'={...s,ctx:true}}
  action bindOwner=all{s.phase==2,s.ctx,s'={...s,bound:true}}
  action reloadRoots=all{s.phase==2,s.ctx,s.bound,s'={...s,reload:s.rootVersion}}
  action publishNext=all{s.phase==2,s.roundDone,s.ctx,s.bound,s.reload==s.rootVersion,s.oldSeal,
    s'={...s,phase:4,epoch:1,gate:true}}
  action claimFuture=all{s.phase==4,s.epoch==1,s.loc==5,s.futureSeal,s.gate,
    s'={...s,loc:2,lease:1,futureSeal:false}}
  action resumeParked=all{s.phase==4,s.epoch==1,s.loc==4,s.park,s.ctx,s.bound,s.reload==s.rootVersion,
    s'={...s,loc:3,lease:1,park:false,write:true}}
  // Observing a claim/result never invokes the callback again.
  action query=s'=s
  action releaseCustody=all{s.loc==6,not(s.issued),not(s.write),s'={...s,root:false,resource:false}}
  val admitted=all{
    s.loc==0 or s.loc==6 or (s.vm and s.root and s.resource),
    not(s.futureSeal) or (s.loc==5 and s.starts==0 and not(s.park) and not(s.issued) and not(s.write) and s.asyncOk and s.manifest),
    s.phase!=2 or (s.oldSeal and not(s.gate) and not(s.producer) and not(s.pub) and not(s.issued) and currentClosed),
    not(s.write) or (s.loc==3 and s.phase!=2 and fresh),
    s.epoch!=1 or (s.oldSeal and s.roundDone and s.ctx and s.bound and s.reload==s.rootVersion),
    s.starts<=1,not(s.escaped),not(s.lost)}
  action step=any{reservePublication,publishTask,finishPublication,closeProducer,closeEntry,
    claimCurrent,issueNative,start,writeEffect,finish,parkCurrent,deferQueued,cancelUnissuedClaim,
    freeze,collectRound,notifyGc,prepareContext,bindOwner,reloadRoots,publishNext,claimFuture,resumeParked,query,releaseCustody}
  action shut=init.then(closeEntry).then(closeProducer)
  action future=shut.then(deferQueued)
  action frozen=future.then(freeze).then(collectRound)
  action nextReady=frozen.then(prepareContext).then(bindOwner).then(reloadRoots).then(publishNext)
  action claimed=init.then(claimCurrent)
  action running=claimed.then(issueNative).then(start)
  action parked=running.then(closeEntry).then(closeProducer).then(parkCurrent).then(freeze).then(collectRound)
  action badDefer=s'={...s,loc:5,futureSeal:true}
  action badFreeze=s'={...s,phase:2,oldSeal:true}
  action badNext=s'={...s,phase:4,epoch:1,gate:true}
  action badOldClaim=s'={...s,loc:3,write:true,lease:0}
  action badDrop=s'={...s,root:false,resource:false}
  action badEscape=s'={...s,escaped:true}
  action badLose=s'={...s,lost:true}
  action badReplay=s'={...s,starts:s.starts+1}
  action badSync=s'={...s,asyncOk:false}
  run deferBeforeGcTest=future.then(freeze).then(all{assert(s.loc==5 and s.root and s.resource and admitted),s'=s})
  run claimWinsCutTest=claimed.then(closeEntry).then(closeProducer).then(issueNative).then(start).then(finish).then(freeze).then(all{assert(admitted),s'=s})
  run cutWinsClaimTest=shut.then(deferQueued).then(all{assert(s.loc==5 and s.lease==(-1) and admitted),s'=s})
  run unissuedClaimCanDeferTest=claimed.then(closeEntry).then(closeProducer).then(cancelUnissuedClaim).then(freeze).then(all{assert(admitted),s'=s})
  run issuedClaimMustDrainTest=claimed.then(issueNative).then(closeEntry).then(closeProducer).then(start).then(finish).then(freeze).then(all{assert(admitted),s'=s})
  run dequeueNotCompletionTest=claimed.then(closeEntry).then(all{assert(not(currentClosed) and s.loc==2 and admitted),s'=s})
  run runningWriteAfterCloseBeforeGcTest=running.then(closeEntry).then(writeEffect).then(finish).then(closeProducer).then(freeze).then(all{assert(admitted),s'=s})
  run parkedActivationAllowsGcTest=parked.then(all{assert(s.loc==4 and s.starts==1 and admitted),s'=s})
  run parkedResumeDoesNotReinvokeTest=parked.then(prepareContext).then(bindOwner).then(reloadRoots).then(publishNext).then(resumeParked).then(writeEffect).then(finish).then(all{assert(s.starts==1 and admitted),s'=s})
  run futureFreshClaimTest=nextReady.then(claimFuture).then(issueNative).then(start).then(writeEffect).then(finish).then(all{assert(s.lease==1 and s.starts==1 and admitted),s'=s})
  run oldSealRemainsClosedTest=nextReady.then(claimFuture).then(issueNative).then(start).then(all{assert(s.oldSeal and s.epoch==1 and admitted),s'=s})
  run publicationDebtCoversWakeupTest=absentInit.then(reservePublication).then(closeEntry).then(closeProducer).then(publishTask).then(finishPublication).then(deferQueued).then(freeze).then(all{assert(admitted),s'=s})
  run claimQueryNoReplayTest=claimed.then(query).then(query).then(all{assert(s.starts==0 and s.loc==2 and admitted),s'=s})
  run retainedFutureTaskAcrossGcTest=frozen.then(query).then(all{assert(s.loc==5 and s.root and s.resource and admitted),s'=s})
  run knownCompletionReleaseTest=running.then(finish).then(releaseCustody).then(all{assert(admitted),s'=s})
  run resumePreparationSeparateTest=frozen.then(prepareContext).then(all{assert(not(s.bound) and s.reload!=s.rootVersion and admitted),s'=s})
  run runningCannotBecomeFutureCounterexampleTest=running.then(closeEntry).then(closeProducer).then(badDefer).then(all{assert(not(admitted)),s'=s})
  run issuedCannotBecomeFutureCounterexampleTest=claimed.then(issueNative).then(closeEntry).then(closeProducer).then(badDefer).then(all{assert(not(admitted)),s'=s})
  run queueEmptyClaimStillBlocksCounterexampleTest=claimed.then(closeEntry).then(closeProducer).then(badFreeze).then(all{assert(not(admitted)),s'=s})
  run gateDoesNotRevokeWriterCounterexampleTest=running.then(closeEntry).then(closeProducer).then(badFreeze).then(all{assert(not(admitted)),s'=s})
  run producerOpenBlocksFreezeCounterexampleTest=init.then(closeEntry).then(badFreeze).then(all{assert(not(admitted)),s'=s})
  run publicationPostludeBlocksFreezeCounterexampleTest=absentInit.then(reservePublication).then(closeEntry).then(closeProducer).then(publishTask).then(badFreeze).then(all{assert(not(admitted)),s'=s})
  run syncCallbackCannotDeferCounterexampleTest=shut.then(badSync).then(badDefer).then(all{assert(not(admitted)),s'=s})
  run rootDropWhileFutureCounterexampleTest=future.then(badDrop).then(all{assert(not(admitted)),s'=s})
  run rootDropWhileParkedCounterexampleTest=parked.then(badDrop).then(all{assert(not(admitted)),s'=s})
  run missingContextBlocksNextCounterexampleTest=frozen.then(badNext).then(all{assert(not(admitted)),s'=s})
  run missingBindingBlocksNextCounterexampleTest=frozen.then(prepareContext).then(badNext).then(all{assert(not(admitted)),s'=s})
  run staleRootsBlockNextCounterexampleTest=frozen.then(prepareContext).then(bindOwner).then(badNext).then(all{assert(not(admitted)),s'=s})
  run staleEpochClaimCounterexampleTest=nextReady.then(badOldClaim).then(all{assert(not(admitted)),s'=s})
  run rawAliasEscapeCounterexampleTest=future.then(badEscape).then(all{assert(not(admitted)),s'=s})
  run lostResultCannotDropDutyCounterexampleTest=claimed.then(badLose).then(all{assert(not(admitted)),s'=s})
  run parkedResumeReplayCounterexampleTest=parked.then(prepareContext).then(bindOwner).then(reloadRoots).then(publishNext).then(resumeParked).then(badReplay).then(all{assert(not(admitted)),s'=s})
  run parkedCannotBecomeUnstartedCounterexampleTest=parked.then(badDefer).then(all{assert(not(admitted)),s'=s})
  run completedReleaseBeforeGcTest=running.then(finish).then(releaseCustody).then(closeEntry).then(closeProducer).then(freeze).then(all{assert(s.loc==6 and not(s.root) and admitted),s'=s})
  run gcNotificationIsNotContextReadyTest=frozen.then(notifyGc).then(all{assert(s.notified and not(s.ctx) and not(s.bound) and admitted),s'=s})
  run notificationCannotOpenNextCounterexampleTest=frozen.then(notifyGc).then(badNext).then(all{assert(not(admitted)),s'=s})
  run currentSealIsNotRoundCompleteCounterexampleTest=future.then(freeze).then(badNext).then(all{assert(not(admitted)),s'=s})
  action negativeInit=

claimed.then(closeEntry).then(closeProducer)
  action negativeStep=badFreeze
}
