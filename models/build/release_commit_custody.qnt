module release_commit_custody {
 // This is an SC abstract model of two alternatives, not current native code.
 type State={lp:int,lowner:bool,lroot:bool,critical:bool,masked:bool,ldrops:int,
 logged:bool,ldone:bool,ldead:bool,quarantine:bool,lknown:bool,ldebt:bool,
 cancelPending:bool,cancelDelivered:bool,parked:bool,auditQualified:bool,
 token:int,tdrops:int,reply:List[int],troot:bool,towner:bool,tdebt:bool,
 tdone:bool,tdead:bool,capture:bool,vm:bool,gcRequested:bool,gcCut:bool,
 scanL:bool,scanT:bool,freedL:bool,freedT:bool}
 // lp:0 before segment,1 entered,2 decremented/unlogged,3 logged,4 Done.
 // token:1 Active,2 Released. tdrops is a GHOST event count, not a second C field.
 pure val initial:State={lp:0,lowner:true,lroot:true,critical:false,masked:false,ldrops:0,
 logged:false,ldone:false,ldead:false,quarantine:false,lknown:false,ldebt:true,
 cancelPending:false,cancelDelivered:false,parked:false,auditQualified:false,
 token:1,tdrops:0,reply:[0,0],troot:true,towner:true,tdebt:true,
 tdone:false,tdead:false,capture:false,vm:true,gcRequested:false,gcCut:false,
 scanL:false,scanT:false,freedL:false,freedT:false}
 var s:State
 val safe=all{s.logged implies s.ldrops==1,s.ldrops>=0 and s.ldrops<=1,
 (s.critical implies (s.masked and s.lowner and s.lroot)),
 (not(s.ldone) implies (s.lowner and s.lroot)),
 (s.ldead and not(s.ldone) implies s.quarantine),
 (s.ldone implies (s.logged and s.ldrops==1 and not(s.ldebt) and not(s.critical))),
 (s.cancelDelivered implies s.ldone),
 (s.token==1 implies s.tdrops==0),(s.token==2 implies s.tdrops==1),
 (not(s.tdone) implies (s.towner and s.troot)),
 (s.tdone implies (s.token==2 and not(s.tdebt))),
 (s.freedL implies (not(s.lroot) and s.ldone and not(s.scanL))),
 (s.freedT implies (not(s.troot) and s.token==2 and not(s.capture) and not(s.scanT) and s.tdone)),
 (s.lowner or s.towner or s.capture) implies s.vm}
 action init=s'=initial
 action enterSegment=all{s.lp==0,not(s.ldead),s.lroot,s.lowner,s'={...s,lp:1,critical:true,masked:true}}
 action legacyDrop=all{s.lp==1,s.critical,s.masked,not(s.ldead),s'={...s,lp:2,ldrops:1}}
 action recordDrop=all{s.lp==2,s.critical,not(s.ldead),s'={...s,lp:3,logged:true}}
 action settleLegacyCaller=all{s.lp==3,not(s.ldead),s'={...s,ldebt:false}}
 action publishLegacyDone=all{s.lp==3,s.logged,not(s.ldebt),not(s.ldead),s'={...s,lp:4,ldone:true,critical:false,lknown:true}}
 action restoreCancellation=all{s.ldone,not(s.critical),s'={...s,masked:false}}
 action requestCancel=all{s'={...s,cancelPending:true}}
 action deliverCancel=all{s.cancelPending,not(s.masked),s.ldone,s'={...s,cancelDelivered:true}}
 // Outside admitted A: model the unavoidable unresolved custody, not safe takeover.
 action abandonLegacy=all{s.lp>=1,s.lp<=3,not(s.ldead),s'={...s,ldead:true,quarantine:true}}
 // Assumes independent death + complete root/roster handoff receipts, not a timeout.
 action confirmDeathHandoff=all{s.ldead,s.quarantine,s'={...s,critical:false,parked:true}}
 // Extra-information alternative: audited exclusive single credit, not blind log retry.
 action admitQuiescentAudit=all{s.ldead,s.parked,s.quarantine,s.lroot,s.lowner,s'={...s,auditQualified:true}}
 action auditDropped=all{s.auditQualified,s.ldrops==1,s'={...s,logged:true,lknown:true}}
 action auditUndropped=all{s.auditQualified,s.ldrops==0,s'={...s,ldrops:1,logged:false,lknown:false}}
 action queryLegacy=all{s'={...s,lknown:s.logged}}
 action retireLegacy=all{s.ldone,s.lknown,not(s.masked),s'={...s,lroot:false,lowner:false,gcCut:false}}
 // One actual CAS changes authority+validity. tdrops/reply assignments are ghost observations.
 action releaseToken(a,g)=all{s.towner,s.troot,s'={...s,
 token:if(g==1)2 else s.token,
 tdrops:if(g==1 and s.token==1)1 else s.tdrops,
 reply:s.reply.replaceAt(a,if(g==1)1 else 2)}}
 action loseReply(a)=all{s'={...s,reply:s.reply.replaceAt(a,0)}}
 action queryToken(a)=all{s.troot,s'={...s,reply:s.reply.replaceAt(a,if(s.token==2)1 else 0)}}
 action abandonToken=all{not(s.tdone),s'={...s,tdead:true}}
 // Physical caller settlement is NOT helpable merely because token release is known.
 action settleTokenCaller=all{s.token==2,not(s.tdead),s'={...s,tdebt:false}}
 action publishTokenDone=all{s.token==2,not(s.tdebt),s'={...s,tdone:true}}
 action retireToken=all{s.tdone,s.reply.indices().exists(j=>s.reply[j]==1),s'={...s,troot:false,towner:false,gcCut:false}}
 action captureK=all{s.troot,not(s.tdone),s'={...s,capture:true}}
 action dropK=all{s.capture,s'={...s,capture:false,gcCut:false}}
 action requestGC=all{s'={...s,gcRequested:true}}
 // Requires full roots + old-roster readiness; dead token owner remains blocked here.
 action collectCut=all{s.gcRequested,not(s.critical),not(s.tdead),not(s.ldead) or s.parked,
 s'={...s,gcCut:true,scanL:s.lroot,scanT:s.troot or s.token==1 or s.capture}}
 action sweepLegacy=all{s.gcCut,not(s.scanL),not(s.lroot),s.ldone,s'={...s,freedL:true}}
 action sweepToken=all{s.gcCut,not(s.scanT),not(s.troot),s.token==2,not(s.capture),s.tdone,s'={...s,freedT:true}}
 action retireVm=all{not(s.lowner),not(s.towner),not(s.capture),s'={...s,vm:false}}
 action step=any{enterSegment,legacyDrop,recordDrop,settleLegacyCaller,publishLegacyDone,restoreCancellation,requestCancel,deliverCancel,abandonLegacy,confirmDeathHandoff,admitQuiescentAudit,auditDropped,auditUndropped,queryLegacy,retireLegacy,releaseToken(0,1),releaseToken(1,1),releaseToken(0,2),loseReply(0),loseReply(1),queryToken(0),queryToken(1),abandonToken,settleTokenCaller,publishTokenDone,retireToken,captureK,dropK,requestGC,collectCut,sweepLegacy,sweepToken,retireVm,all{s'=s}}
 action finishLegacy=enterSegment.then(legacyDrop).then(recordDrop).then(settleLegacyCaller).then(publishLegacyDone).then(restoreCancellation).then(retireLegacy)
 action finishToken=releaseToken(0,1).then(settleTokenCaller).then(publishTokenDone).then(retireToken)
 run legacyCompletionTest=init.then(finishLegacy).then(all{assert(safe and s.ldrops==1),s'=s})
 run pendingCancelTest=init.then(enterSegment).then(legacyDrop).then(requestCancel).then(recordDrop).then(settleLegacyCaller).then(publishLegacyDone).then(restoreCancellation).then(deliverCancel).then(all{assert(safe),s'=s})
 run unknownLegacyCustodyTest=init.then(enterSegment).then(legacyDrop).then(abandonLegacy).then(queryLegacy).then(confirmDeathHandoff).then(all{assert(safe and not(s.lknown) and s.lroot and s.quarantine),s'=s})
 run tokenRetryTest=init.then(releaseToken(0,1)).then(loseReply(0)).then(releaseToken(1,1)).then(queryToken(0)).then(all{assert(safe and s.tdrops==1 and s.reply[0]==1),s'=s})
 run tokenOwnerLossTest=init.then(releaseToken(0,1)).then(loseReply(0)).then(abandonToken).then(queryToken(1)).then(all{assert(safe and s.reply[1]==1 and s.tdebt and s.troot),s'=s})
 run staleIdentityTest=init.then(releaseToken(0,2)).then(all{assert(safe and s.token==1 and s.tdrops==0 and s.reply[0]==2),s'=s})
 run gcDuringRequestTest=init.then(enterSegment).then(legacyDrop).then(requestGC).then(recordDrop).then(settleLegacyCaller).then(publishLegacyDone).then(collectCut).then(all{assert(safe and s.scanL and s.scanT),s'=s})
 run continuationRetentionTest=init.then(captureK).then(finishLegacy).then(finishToken).then(requestGC).then(collectCut).then(all{assert(safe and s.scanT and not(s.freedT)),s'=s}).then(dropK).then(collectCut).then(sweepToken).then(all{assert(safe),s'=s})
 run auditAfterDropTest=init.then(enterSegment).then(legacyDrop).then(abandonLegacy).then(confirmDeathHandoff).then(admitQuiescentAudit).then(auditDropped).then(all{assert(safe and s.ldrops==1 and s.lknown and s.ldebt),s'=s})
 run auditBeforeDropTest=init.then(enterSegment).then(abandonLegacy).then(confirmDeathHandoff).then(admitQuiescentAudit).then(auditUndropped).then(all{assert(safe and not(s.logged) and s.lroot),s'=s}).then(auditDropped).then(all{assert(safe and s.ldrops==1 and s.lknown and s.ldebt),s'=s})
 run invalidationIsNotDropControlTest=init.then(enterSegment).then(all{s'={...s,logged:true}}).then(all{assert(not(safe)),s'=s})
 run duplicateLegacyDropControlTest=init.then(enterSegment).then(legacyDrop).then(abandonLegacy).then(all{s'={...s,ldrops:2}}).then(all{assert(not(safe)),s'=s})
 run lostKeeperControlTest=init.then(enterSegment).then(legacyDrop).then(abandonLegacy).then(all{s'={...s,lowner:false,lroot:false}}).then(all{assert(not(safe)),s'=s})
 run earlyCancelControlTest=init.then(enterSegment).then(legacyDrop).then(all{s'={...s,cancelDelivered:true}}).then(all{assert(not(safe)),s'=s})
 run fakeDoneControlTest=init.then(enterSegment).then(legacyDrop).then(all{s'={...s,ldone:true,critical:false}}).then(all{assert(not(safe)),s'=s})
 run splitTokenRecordControlTest=init.then(all{s'={...s,tdrops:1}}).then(all{assert(not(safe)),s'=s})
 run tokenDoubleDropControlTest=init.then(releaseToken(0,1)).then(all{s'={...s,tdrops:2}}).then(all{assert(not(safe)),s'=s})
 run tokenIsNotGuardDoneControlTest=init.then(releaseToken(0,1)).then(all{s'={...s,tdone:true,troot:false,towner:false}}).then(all{assert(not(safe)),s'=s})
 run capturedMarkerFreedControlTest=init.then(captureK).then(finishLegacy).then(finishToken).then(all{s'={...s,freedT:true}}).then(all{assert(not(safe)),s'=s})
}
