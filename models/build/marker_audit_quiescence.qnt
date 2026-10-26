module marker_audit_quiescence {
 // SC design model; closure/HB/GC receipts are explicit premises, not source proofs.
 type State={count:int,drops:int,extra:int,foreignWrite:bool,invalid:bool,
 gateOpen:bool,oldLive:bool,oldLease:bool,aliasLease:bool,joined:bool,joinFailed:bool,
 arenaVm:bool,root:bool,session:bool,scanActive:bool,gcReceipt:bool,sourceClosed:bool,
 hb:bool,generation:int,receiptGen:int,exclusive:bool,auditor:int,auditLive:bool,
 auditLease:bool,observed:int,recorded:bool,known:bool,callerDone:bool,
 rootGrace:bool,freed:bool,vm:bool}
 pure val initial:State={count:1,drops:0,extra:0,foreignWrite:false,invalid:false,
 gateOpen:true,oldLive:true,oldLease:true,aliasLease:false,joined:false,joinFailed:false,
 arenaVm:false,root:true,session:true,scanActive:false,gcReceipt:false,sourceClosed:false,
 hb:false,generation:1,receiptGen:0,exclusive:false,auditor:0,auditLive:false,
 auditLease:false,observed:-1,recorded:false,known:false,callerDone:false,
 rootGrace:false,freed:false,vm:true}
 var s:State
 action init=s'=initial
 def writersDrained=not(s.oldLease) and not(s.aliasLease) and not(s.auditLease)
 def qualified=s.sourceClosed and not(s.gateOpen) and s.joined and writersDrained and s.arenaVm and s.root and s.gcReceipt and s.hb and not(s.scanActive) and not(s.foreignWrite)
 val safe=all{s.count==1+s.extra-s.drops,s.drops>=0 and s.drops<=1,s.count>=0,
 (s.exclusive implies (s.receiptGen==s.generation and s.sourceClosed and not(s.gateOpen) and s.joined and s.arenaVm and s.root and s.hb and not(s.oldLease) and not(s.aliasLease) and not(s.scanActive))),
 (s.auditLease implies (s.root and s.session and s.exclusive)),
 (s.recorded implies (s.drops==1 and s.invalid and s.count==0)),
 (not(s.callerDone) implies (s.root and s.session)),
 (s.scanActive implies (s.root and s.arenaVm and not(s.auditLease))),
 (s.freed implies (s.callerDone and s.rootGrace and not(s.root) and not(s.auditLease) and s.arenaVm)),
 s.session implies s.vm}
 action closeWriters=all{s.session,s'={...s,gateOpen:false}}
 action handoffArena=all{s.oldLive,s.root,s.session,s'={...s,arenaVm:true}}
 action aliasEnter=all{s.gateOpen,not(s.aliasLease),s'={...s,aliasLease:true}}
 action aliasInc=all{s.aliasLease,s'={...s,count:s.count+1,extra:s.extra+1,foreignWrite:true,gcReceipt:false}}
 action aliasExit=all{s.aliasLease,s'={...s,aliasLease:false}}
 action oldInvalidate=all{s.oldLive,s.oldLease,s'={...s,invalid:true}}
 action oldDrop=all{s.oldLive,s.oldLease,s.invalid,s.drops==0,s'={...s,count:s.count-1,drops:1}}
 action oldExit=all{s.oldLive,s'={...s,oldLive:false}}
 action joinSuccess=all{not(s.oldLive),s'={...s,joined:true,oldLease:false,hb:true}}
 action joinFailure=all{s'={...s,joinFailed:true}}
 // Profile closure excludes unmanaged paths; cannot be inferred from zero grep matches.
 action admitClosedProfile=all{not(s.gateOpen),s.joined,not(s.aliasLease),not(s.foreignWrite),s'={...s,sourceClosed:true}}
 action beginGcCut=all{s.arenaVm,s.root,writersDrained,not(s.gateOpen),s.joined,s'={...s,scanActive:true,gcReceipt:false,exclusive:false}}
 action finishGcCut=all{s.scanActive,s'={...s,scanActive:false,gcReceipt:true}}
 action certifyAudit=all{qualified,s'={...s,exclusive:true,receiptGen:s.generation}}
 action enterAudit(a)=all{s.exclusive,s.receiptGen==s.generation,not(s.auditLease),not(s.scanActive),s.auditor==0 or a!=s.auditor,s'={...s,auditor:a,auditLive:true,auditLease:true,observed:-1}}
 action readCount=all{s.auditLease,s.auditLive,s.hb,s'={...s,observed:s.count}}
 action auditInvalidate=all{s.auditLease,s.auditLive,s.observed==1,s'={...s,invalid:true}}
 action auditDrop=all{s.auditLease,s.auditLive,s.observed==1,s.count==1,s.drops==0,s.invalid,s'={...s,count:0,drops:1,observed:-1}}
 action publishAudit=all{s.auditLease,s.auditLive,s.observed==0,s.count==0,s.invalid,s'={...s,recorded:true,known:true}}
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
 action step=any{closeWriters,handoffArena,aliasEnter,aliasInc,aliasExit,oldInvalidate,oldDrop,oldExit,joinSuccess,joinFailure,admitClosedProfile,beginGcCut,finishGcCut,certifyAudit,enterAudit(1),enterAudit(2),readCount,auditInvalidate,auditDrop,publishAudit,loseReply,auditExit,confirmAuditExit,normalAuditReturn,queryAudit,admitCallerSettlement,retireRoots,reclaim,retireVm,all{s'=s}}
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
 run lateLeaseIgnoredControlTest=init.then(aliasEnter).then(closeWriters).then(all{s'={...s,exclusive:true,receiptGen:1}}).then(all{assert(not(safe)),s'=s})
 run joinOnlyReceiptControlTest=init.then(closeWriters).then(oldExit).then(joinSuccess).then(all{s'={...s,exclusive:true,receiptGen:1}}).then(all{assert(not(safe)),s'=s})
 run prematureStorageFreeControlTest=init.then(closeWriters).then(oldExit).then(joinSuccess).then(all{s'={...s,freed:true}}).then(all{assert(not(safe)),s'=s})
 run nativeRootPinChangesCountControlTest=init.then(base).then(enterAudit(1)).then(all{s'={...s,count:2}}).then(all{assert(not(safe)),s'=s})
 run replacementBeforeConfirmedExitControlTest=init.then(base).then(enterAudit(1)).then(auditExit).then(all{s'={...s,exclusive:false}}).then(all{assert(not(safe)),s'=s})
 run missingVisibilityControlTest=init.then(base).then(all{s'={...s,hb:false}}).then(all{assert(not(safe)),s'=s})
 run secondAuditDropControlTest=init.then(base).then(enterAudit(1)).then(dropAndRead).then(all{s'={...s,count:-1,drops:2}}).then(all{assert(not(safe)),s'=s})
 run unknownCustodyLostControlTest=init.then(base).then(enterAudit(1)).then(auditExit).then(all{s'={...s,root:false,session:false}}).then(all{assert(not(safe)),s'=s})
 run staleGenerationControlTest=init.then(base).then(all{s'={...s,generation:2}}).then(all{assert(not(safe)),s'=s})
}
