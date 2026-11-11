module marker_alias_revocation {
 // SC design model; closure/HB/GC receipts are explicit premises, not source proofs.
 type State={epoch:int,receiptEpoch:int,revoking:bool,rawEscape:bool,count:int,drops:int,extra:int,foreignWrite:bool,invalid:bool,
 gateOpen:bool,oldLive:bool,oldLease:bool,aliasLease:bool,joined:bool,joinFailed:bool,
 arenaVm:bool,root:bool,session:bool,scanActive:bool,gcReceipt:bool,sourceClosed:bool,
 hb:bool,generation:int,receiptGen:int,exclusive:bool,auditor:int,auditLive:bool,
 auditLease:bool,observed:int,recorded:bool,known:bool,callerDone:bool,
 rootGrace:bool,freed:bool,vm:bool}
 pure val initial:State={epoch:1,receiptEpoch:0,revoking:false,rawEscape:false,count:1,drops:0,extra:0,foreignWrite:false,invalid:false,
 gateOpen:true,oldLive:true,oldLease:true,aliasLease:false,joined:false,joinFailed:false,
 arenaVm:false,root:true,session:true,scanActive:false,gcReceipt:false,sourceClosed:false,
 hb:false,generation:1,receiptGen:0,exclusive:false,auditor:0,auditLive:false,
 auditLease:false,observed:-1,recorded:false,known:false,callerDone:false,
 rootGrace:false,freed:false,vm:true}
 var s:State
 action init=s'=initial
 def writersDrained=not(s.oldLease) and not(s.aliasLease) and not(s.auditLease)
 def qualified=s.sourceClosed and not(s.gateOpen) and s.joined and writersDrained and s.arenaVm and s.root and s.gcReceipt and s.hb and not(s.scanActive) and not(s.foreignWrite) and not(s.rawEscape) and not(s.revoking)
 val safe=all{s.count==1+s.extra-s.drops,s.drops>=0 and s.drops<=1,s.count>=0,
 (s.exclusive implies (s.receiptGen==s.generation and s.receiptEpoch==s.epoch and not(s.rawEscape) and s.sourceClosed and not(s.gateOpen) and s.joined and s.arenaVm and s.root and s.hb and not(s.oldLease) and not(s.aliasLease) and not(s.scanActive))),
 (s.auditLease implies (s.root and s.session and s.exclusive)),
 (s.recorded implies (s.drops==1 and s.invalid and s.count==0)),
 (not(s.callerDone) implies (s.root and s.session)),
 (s.scanActive implies (s.root and s.arenaVm and not(s.auditLease))),
 (s.freed implies (s.callerDone and s.rootGrace and not(s.root) and not(s.auditLease) and s.arenaVm)),
 s.session implies s.vm,
  (s.aliasLease implies not(s.exclusive)),
  (s.revoking implies not(s.gateOpen)),
  (s.rawEscape implies not(s.exclusive))}
 action closeWriters=all{s.session,s'={...s,gateOpen:false}}
 action handoffArena=all{s.oldLive,s.root,s.session,s'={...s,arenaVm:true}}
 action aliasEnter=all{s.gateOpen,not(s.exclusive),not(s.revoking),not(s.recorded),not(s.aliasLease),s'={...s,aliasLease:true}}
 action aliasInc=all{s.aliasLease,s'={...s,count:s.count+1,extra:s.extra+1,foreignWrite:true,gcReceipt:false}}
 action aliasExit=all{s.aliasLease,s'={...s,aliasLease:false}}
 action oldInvalidate=all{s.oldLive,s.oldLease,s'={...s,invalid:true}}
 action oldDrop=all{s.oldLive,s.oldLease,s.invalid,s.drops==0,s'={...s,count:s.count-1,drops:1}}
 action oldExit=all{s.oldLive,s'={...s,oldLive:false}}
 action joinSuccess=all{not(s.oldLive),s'={...s,joined:true,oldLease:false,hb:true}}
 action joinFailure=all{s'={...s,joinFailed:true}}
 // Profile closure excludes unmanaged paths; cannot be inferred from zero grep matches.
 action admitClosedProfile=all{not(s.rawEscape),not(s.revoking),not(s.gateOpen),s.joined,not(s.aliasLease),not(s.foreignWrite),s'={...s,sourceClosed:true}}
 action beginGcCut=all{s.arenaVm,s.root,writersDrained,not(s.gateOpen),s.joined,s'={...s,scanActive:true,gcReceipt:false,exclusive:false}}
 action finishGcCut=all{s.scanActive,s'={...s,scanActive:false,gcReceipt:true}}
 action certifyAudit=all{qualified,s'={...s,exclusive:true,receiptGen:s.generation,receiptEpoch:s.epoch}}
 action enterAudit(a)=all{not(s.revoking),s.receiptEpoch==s.epoch,s.exclusive,s.receiptGen==s.generation,not(s.auditLease),not(s.scanActive),s.auditor==0 or a!=s.auditor,s'={...s,auditor:a,auditLive:true,auditLease:true,observed:-1}}
 action readCount=all{not(s.revoking),s.receiptEpoch==s.epoch,s.auditLease,s.auditLive,s.hb,s'={...s,observed:s.count}}
 action auditInvalidate=all{not(s.revoking),s.receiptEpoch==s.epoch,s.auditLease,s.auditLive,s.observed==1,s'={...s,invalid:true}}
 action auditDrop=all{not(s.revoking),s.receiptEpoch==s.epoch,s.auditLease,s.auditLive,s.observed==1,s.count==1,s.drops==0,s.invalid,s'={...s,count:0,drops:1,observed:-1}}
 action publishAudit=all{not(s.revoking),s.receiptEpoch==s.epoch,s.auditLease,s.auditLive,s.observed==0,s.count==0,s.invalid,s'={...s,recorded:true,known:true}}
 action loseReply=all{s.auditLease,s'={...s,known:false}}
 // Exit does not drain its write lease. Replacement needs confirmed cessation + new cut.
 action auditExit=all{s.auditLease,s.auditLive,s'={...s,auditLive:false,known:false}}
 action confirmAuditExit=all{s.auditLease,not(s.auditLive),s'={...s,auditLease:false,exclusive:false,gcReceipt:false,hb:true,observed:-1}}
 action normalAuditReturn=all{s.auditLease,s.auditLive,s.recorded,s'={...s,auditLive:false,auditLease:false,exclusive:false,gcReceipt:false,observed:-1}}
 action queryAudit=all{s.recorded,s.root,s'={...s,known:true}}
 action admitCallerSettlement=all{s.recorded,not(s.auditLease),s'={...s,callerDone:true}}
 action retireRoots=all{s.callerDone,s.known,s.arenaVm,writersDrained,not(s.scanActive),s'={...s,rootGrace:true,root:false,session:false,exclusive:false,gcReceipt:false}}
 action reclaim=all{s.rootGrace,not(s.root),not(s.session),s'={...s,freed:true}}
 action retireVm=all{not(s.session),s.callerDone,s'={...s,vm:false}}
 // Revocation blocks new audit steps. It does not force cessation of an in-flight C access.
 action requestRevoke=all{not(s.gateOpen),s.root,s.session,s'={...s,revoking:true}}
 action yieldAudit=all{s.revoking,s.auditLease,s.auditLive,s'={...s,auditLease:false,auditLive:false,exclusive:false,gcReceipt:false,observed:-1}}
 action completeRevoke=all{s.revoking,not(s.auditLease),not(s.aliasLease),s'={...s,exclusive:false,receiptGen:0,receiptEpoch:0,gcReceipt:false,sourceClosed:false,observed:-1}}
 action reopenWriters=all{s.revoking,not(s.exclusive),not(s.auditLease),s.receiptEpoch==0,not(s.recorded),s'={...s,epoch:s.epoch+1,gateOpen:true,revoking:false}}
 action managedDec=all{s.aliasLease,s.extra>0,s'={...s,extra:s.extra-1,count:s.count-1,foreignWrite:true,gcReceipt:false}}
 action exposeRaw=all{s.gateOpen,not(s.exclusive),s'={...s,rawEscape:true,foreignWrite:true,gcReceipt:false}}
 action repeatReadAlias=all{s.root,s.session,s'=s}
 action step=any{requestRevoke,yieldAudit,completeRevoke,reopenWriters,managedDec,exposeRaw,repeatReadAlias,closeWriters,handoffArena,aliasEnter,aliasInc,aliasExit,oldInvalidate,oldDrop,oldExit,joinSuccess,joinFailure,admitClosedProfile,beginGcCut,finishGcCut,certifyAudit,enterAudit(1),enterAudit(2),readCount,auditInvalidate,auditDrop,publishAudit,loseReply,auditExit,confirmAuditExit,normalAuditReturn,queryAudit,admitCallerSettlement,retireRoots,reclaim,retireVm,all{s'=s}}
 action base=handoffArena.then(closeWriters).then(oldExit).then(joinSuccess).then(admitClosedProfile).then(beginGcCut).then(finishGcCut).then(certifyAudit)
 action dropAndRead=readCount.then(auditInvalidate).then(auditDrop).then(readCount)
 action cutAgain=beginGcCut.then(finishGcCut).then(certifyAudit)
 run completeUndroppedTest=init.then(base).then(enterAudit(1)).then(dropAndRead).then(publishAudit).then(normalAuditReturn).then(admitCallerSettlement).then(retireRoots).then(reclaim).then(all{assert(safe and s.drops==1),s'=s})
 run alreadyDroppedTest=init.then(oldInvalidate).then(oldDrop).then(base).then(enterAudit(1)).then(readCount).then(publishAudit).then(all{assert(safe and s.drops==1),s'=s})
 run auditorExitBeforeDropTest=init.then(base).then(enterAudit(1)).then(readCount).then(auditExit).then(confirmAuditExit).then(cutAgain).then(enterAudit(2)).then(dropAndRead).then(publishAudit).then(all{assert(safe),s'=s})
 run auditorExitAfterDropTest=init.then(base).then(enterAudit(1)).then(dropAndRead).then(auditExit).then(confirmAuditExit).then(cutAgain).then(enterAudit(2)).then(readCount).then(publishAudit).then(all{assert(safe and s.drops==1 and s.session),s'=s})
 run unknownReplyKeepsLeaseTest=init.then(base).then(enterAudit(1)).then(dropAndRead).then(publishAudit).then(loseReply).then(all{assert(safe and s.auditLive and s.auditLease and s.root),s'=s})
 run lateWriterDrainTest=init.then(aliasEnter).then(closeWriters).then(aliasInc).then(aliasExit).then(all{assert(safe and s.foreignWrite and not(s.exclusive) and s.root),s'=s})
 run failedJoinKeepsCustodyTest=init.then(closeWriters).then(joinFailure).then(all{assert(safe and s.oldLease and not(s.joined) and s.root),s'=s})
 run gcSeesIndependentRootTest=init.then(oldInvalidate).then(oldDrop).then(handoffArena).then(closeWriters).then(oldExit).then(joinSuccess).then(beginGcCut).then(finishGcCut).then(all{assert(safe and s.count==0 and s.root and not(s.freed)),s'=s})
 run invalidOnlyNeedsDropTest=init.then(oldInvalidate).then(base).then(enterAudit(1)).then(dropAndRead).then(publishAudit).then(all{assert(safe and s.drops==1),s'=s})
 run untransferredExitKeptTest=init.then(closeWriters).then(oldExit).then(joinSuccess).then(all{assert(safe and not(s.arenaVm) and s.root and s.session),s'=s})
 run extraCreditMasksDropControlTest=init.then(aliasEnter).then(oldInvalidate).then(oldDrop).then(aliasInc).then(all{s'={...s,count:0,drops:2}}).then(all{assert(not(safe)),s'=s})
 run lateLeaseIgnoredControlTest=init.then(aliasEnter).then(closeWriters).then(all{s'={...s,exclusive:true,receiptGen:1,receiptEpoch:1}}).then(all{assert(not(safe)),s'=s})
 run joinOnlyReceiptControlTest=init.then(closeWriters).then(oldExit).then(joinSuccess).then(all{s'={...s,exclusive:true,receiptGen:1,receiptEpoch:1}}).then(all{assert(not(safe)),s'=s})
 run prematureStorageFreeControlTest=init.then(closeWriters).then(oldExit).then(joinSuccess).then(all{s'={...s,freed:true}}).then(all{assert(not(safe)),s'=s})
 run nativeRootPinChangesCountControlTest=init.then(base).then(enterAudit(1)).then(all{s'={...s,count:2}}).then(all{assert(not(safe)),s'=s})
 run replacementBeforeConfirmedExitControlTest=init.then(base).then(enterAudit(1)).then(auditExit).then(all{s'={...s,exclusive:false}}).then(all{assert(not(safe)),s'=s})
 run missingVisibilityControlTest=init.then(base).then(all{s'={...s,hb:false}}).then(all{assert(not(safe)),s'=s})
 run secondAuditDropControlTest=init.then(base).then(enterAudit(1)).then(dropAndRead).then(all{s'={...s,count:-1,drops:2}}).then(all{assert(not(safe)),s'=s})
 run unknownCustodyLostControlTest=init.then(base).then(enterAudit(1)).then(auditExit).then(all{s'={...s,root:false,session:false}}).then(all{assert(not(safe)),s'=s})
 run staleGenerationControlTest=init.then(base).then(all{s'={...s,generation:2}}).then(all{assert(not(safe)),s'=s})

 run readAliasKeepsCreditTest=init.then(repeatReadAlias).then(repeatReadAlias).then(all{assert(safe and s.count==1 and not(s.foreignWrite)),s'=s})
 run closeDoesNotDrainAliasTest=init.then(aliasEnter).then(closeWriters).then(all{assert(safe and s.aliasLease and not(qualified)),s'=s})
 run balancedWriterStillNeedsProvenanceTest=init.then(aliasEnter).then(aliasInc).then(managedDec).then(aliasExit).then(handoffArena).then(closeWriters).then(oldExit).then(joinSuccess).then(all{assert(safe and s.count==1 and s.foreignWrite and not(qualified)),s'=s})
 run rawEscapeRejectsProfileTest=init.then(exposeRaw).then(handoffArena).then(closeWriters).then(oldExit).then(joinSuccess).then(all{assert(safe and not(qualified) and s.rawEscape),s'=s})
 run revokeBeforeAuditEntryTest=init.then(base).then(requestRevoke).then(completeRevoke).then(reopenWriters).then(all{assert(safe and s.epoch==2 and s.receiptEpoch==0),s'=s})
 run revokeWaitsLiveAuditorTest=init.then(base).then(enterAudit(1)).then(readCount).then(requestRevoke).then(all{assert(safe and s.auditLease and s.observed==1),s'=s})
 run yieldDiscardsSnapshotTest=init.then(base).then(enterAudit(1)).then(readCount).then(requestRevoke).then(yieldAudit).then(completeRevoke).then(reopenWriters).then(aliasEnter).then(aliasInc).then(all{assert(safe and s.observed== -1 and s.count==2),s'=s})
 run unknownAuditorBlocksReopenTest=init.then(base).then(enterAudit(1)).then(requestRevoke).then(auditExit).then(all{assert(safe and s.auditLease and s.root and s.session),s'=s})
 run revokedLeaseReopenControlTest=init.then(base).then(enterAudit(1)).then(requestRevoke).then(all{s'={...s,exclusive:false,gateOpen:true}}).then(all{assert(not(safe)),s'=s})
 run rawDuringAuditControlTest=init.then(base).then(enterAudit(1)).then(all{s'={...s,rawEscape:true}}).then(all{assert(not(safe)),s'=s})
 run oldEpochReceiptControlTest=init.then(base).then(all{s'={...s,epoch:2}}).then(all{assert(not(safe)),s'=s})
 run lateAliasDuringAuditControlTest=init.then(base).then(enterAudit(1)).then(all{s'={...s,aliasLease:true}}).then(all{assert(not(safe)),s'=s})
 run receiptRetainedOnReopenControlTest=init.then(base).then(all{s'={...s,gateOpen:true}}).then(all{assert(not(safe)),s'=s})
 run balancedCreditsHideOwnedDropControlTest=init.then(aliasEnter).then(aliasInc).then(oldInvalidate).then(oldDrop).then(all{s'={...s,count:0,drops:2}}).then(all{assert(not(safe)),s'=s})
}
