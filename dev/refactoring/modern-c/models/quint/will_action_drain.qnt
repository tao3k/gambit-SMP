module will_action_drain {
 // Bounded vocabulary, unbounded ticket counts. Capture retirement and reconciliation
 // are external receipts, not source-provided actions or termination assumptions.
 type State={weak:int,ready:int,claimed:int,loaded:int,runnable:int,active:int,unknown:int,pins:int,captures:int,created:int,retired:int,epoch:int,sealedEpoch:int,uses:int,closed:bool,mapped:bool,aliases:bool,issued:bool}
 pure val initial:State={weak:0,ready:0,claimed:0,loaded:0,runnable:0,active:0,unknown:0,pins:0,captures:0,created:0,retired:0,epoch:1,sealedEpoch:0,uses:0,closed:false,mapped:false,aliases:false,issued:false}
 var s:State
 action init=s'=initial
 val safe=all{s.weak>=0,
s.ready>=0,
s.claimed>=0,
s.loaded>=0,
s.runnable>=0,
s.active>=0,
s.unknown>=0,
s.pins>=0,
s.captures>=0,
s.created>=0,
s.retired>=0,
s.epoch>=0,
s.sealedEpoch>=0,
s.uses>=0,
s.epoch>=1,
s.retired<=s.created,
s.created-s.retired==s.weak+s.ready+s.claimed+s.loaded+s.runnable+s.active+s.unknown,
s.issued implies (s.closed and s.mapped and s.aliases and s.sealedEpoch==s.epoch and s.weak==0 and s.ready==0 and s.claimed==0 and s.loaded==0 and s.runnable==0 and s.active==0 and s.unknown==0 and s.pins==0 and s.captures==0)}
 action reserveExternal=all{not(s.closed),s'={...s,pins:s.pins+1}}
 action reserveChild=all{s.active>0,s'={...s,pins:s.pins+1}}
 action commitWill=all{s.pins>0,s'={...s,pins:s.pins-1,weak:s.weak+1,created:s.created+1,epoch:s.epoch+1,issued:false,aliases:false}}
 action abortReservation=all{s.pins>0,s'={...s,pins:s.pins-1}}
 action unknownCommit=all{s.pins>0,s'={...s,pins:s.pins-1,unknown:s.unknown+1,created:s.created+1,epoch:s.epoch+1,issued:false,aliases:false}}
 action closeExternal=all{not(s.closed),s'={...s,closed:true}}
 action makeExecutable=all{s.weak>0,s'={...s,weak:s.weak-1,ready:s.ready+1}}
 action dequeue=all{s.ready>0,s'={...s,ready:s.ready-1,claimed:s.claimed+1}}
 action loadOperands=all{s.claimed>0,s'={...s,claimed:s.claimed-1,loaded:s.loaded+1}}
 action zapWillFields=all{s.loaded>0,s'={...s,loaded:s.loaded-1,runnable:s.runnable+1}}
 action enterAction=all{s.runnable>0,s'={...s,runnable:s.runnable-1,active:s.active+1}}
 action capture=all{s.active>0,s'={...s,captures:s.captures+1}}
 action returnAction=all{s.active>0,s'={...s,active:s.active-1,retired:s.retired+1}}
 action escapeAction=all{s.active>0,s'={...s,active:s.active-1,unknown:s.unknown+1}}
 action resumeCapture=all{s.captures>0,s'={...s,active:s.active+1,created:s.created+1,epoch:s.epoch+1,issued:false,aliases:false}}
 action retireOneCapture=all{s.captures>0,s'={...s,captures:s.captures-1}}
 action resolveUnknownDone=all{s.unknown>0,s'={...s,unknown:s.unknown-1,retired:s.retired+1}}
 action resolveUnknownReady=all{s.unknown>0,s'={...s,unknown:s.unknown-1,ready:s.ready+1}}
 action attestRootMaps=all{true,s'={...s,mapped:true}}
 action attestAliasClosure=all{s.closed,s.weak==0,s.ready==0,s.claimed==0,s.loaded==0,s.runnable==0,s.active==0,s.unknown==0,s.pins==0,s.captures==0,s'={...s,aliases:true}}
 action issue=all{s.closed,s.mapped,s.aliases,s.weak==0,s.ready==0,s.claimed==0,s.loaded==0,s.runnable==0,s.active==0,s.unknown==0,s.pins==0,s.captures==0,s'={...s,issued:true,sealedEpoch:s.epoch}}
 action reuse=all{s.issued,s.sealedEpoch==s.epoch,s'={...s,uses:s.uses+1}}
 action unmanagedInterference=all{true,s'={...s,epoch:s.epoch+1,aliases:false,issued:false}}
 action step=any{reserveExternal,reserveChild,commitWill,abortReservation,unknownCommit,closeExternal,makeExecutable,dequeue,loadOperands,zapWillFields,enterAction,capture,returnAction,escapeAction,resumeCapture,retireOneCapture,resolveUnknownDone,resolveUnknownReady,attestRootMaps,attestAliasClosure,issue,reuse,unmanagedInterference,all{s'=s}}
 run normalDrainTest=init.then(reserveExternal).then(commitWill).then(makeExecutable).then(dequeue).then(loadOperands).then(zapWillFields).then(enterAction).then(closeExternal).then(returnAction).then(attestRootMaps).then(attestAliasClosure).then(issue).then(reuse).then(all{assert(s.uses==1 and safe),s'=s})
 run pendingAfterCloseControlTest=init.then(reserveExternal).then(closeExternal).then(commitWill).then(all{assert(s.weak==1 and not(s.issued) and safe),s'=s})
 run lateEligibilityControlTest=init.then(reserveExternal).then(commitWill).then(closeExternal).then(makeExecutable).then(all{assert(s.ready==1 and not(s.issued) and safe),s'=s})
 run zappedStillRootedControlTest=init.then(reserveExternal).then(commitWill).then(makeExecutable).then(dequeue).then(loadOperands).then(zapWillFields).then(closeExternal).then(all{assert(s.runnable==1 and not(s.issued) and safe),s'=s})
 run multiShotControlTest=init.then(reserveExternal).then(commitWill).then(makeExecutable).then(dequeue).then(loadOperands).then(zapWillFields).then(enterAction).then(capture).then(closeExternal).then(returnAction).then(resumeCapture).then(returnAction).then(resumeCapture).then(returnAction).then(all{assert(s.active==0 and s.captures==1 and s.created==3 and s.retired==3 and not(s.issued) and safe),s'=s})
 run unknownExitControlTest=init.then(reserveExternal).then(commitWill).then(makeExecutable).then(dequeue).then(loadOperands).then(zapWillFields).then(enterAction).then(closeExternal).then(escapeAction).then(all{assert(s.unknown==1 and not(s.issued) and safe),s'=s})
 run childHandoffTest=init.then(reserveExternal).then(commitWill).then(makeExecutable).then(dequeue).then(loadOperands).then(zapWillFields).then(enterAction).then(closeExternal).then(reserveChild).then(returnAction).then(commitWill).then(all{assert(s.pins==0 and s.weak==1 and not(s.issued) and safe),s'=s})
 run unknownCommitTest=init.then(reserveExternal).then(closeExternal).then(unknownCommit).then(resolveUnknownReady).then(all{assert(s.ready==1 and s.created==1 and safe),s'=s})
 run captureReceiptTest=init.then(reserveExternal).then(commitWill).then(makeExecutable).then(dequeue).then(loadOperands).then(zapWillFields).then(enterAction).then(capture).then(closeExternal).then(returnAction).then(retireOneCapture).then(attestRootMaps).then(attestAliasClosure).then(issue).then(all{assert(s.issued and safe),s'=s})
 run staleEpochControlTest=init.then(closeExternal).then(attestRootMaps).then(attestAliasClosure).then(issue).then(unmanagedInterference).then(all{assert(not(s.issued) and safe),s'=s})
 run unknownReconciledTest=init.then(reserveExternal).then(commitWill).then(makeExecutable).then(dequeue).then(loadOperands).then(zapWillFields).then(enterAction).then(closeExternal).then(escapeAction).then(resolveUnknownDone).then(attestRootMaps).then(attestAliasClosure).then(issue).then(all{assert(s.issued and safe),s'=s})
}
