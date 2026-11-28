// Conditional modern C design: one owner and two successive helpers, no native runtime claim.
// Real noescape/thread-termination, complete producer census and registered root coverage are external witnesses.
module writer_stop_handoff {
 type S={gen:int,authorized:int,closing:bool,d:int,c:int,borrow:int,callbacks:int,pins:int,
  exitSeen:bool,funnel:bool,joined:bool,census:bool,dataSeal:bool,controlSeal:bool,sealGen:int,
  a:bool,b:bool,logA:bool,logB:bool,committed:bool,commits:int,reply:bool,
  source:bool,frozen:bool,rootEpoch:int,epoch:int,scan:bool,terminal:bool,ack:bool,reclaimed:bool}
 var s:S
 action init=s'={gen:0,authorized:0,closing:false,d:0,c:0,borrow:0,callbacks:0,pins:0,
  exitSeen:false,funnel:false,joined:false,census:false,dataSeal:false,controlSeal:false,sealGen:-1,
  a:false,b:false,logA:false,logB:false,committed:false,commits:0,reply:false,
  source:true,frozen:true,rootEpoch:0,epoch:0,scan:false,terminal:false,ack:false,reclaimed:false}
 val live=not(s.reclaimed) and not(s.terminal)
 action beginData=all{live,not(s.closing),not(s.committed),s.d==0,s'={...s,d:1}}
 action store=all{live,s.d==1,not(s.committed),s'={...s,a:true}}
 action drainWrite=all{s.d==1,s'={...s,d:0}}
 action beginControl=all{live,not(s.closing),s.c==0,s'={...s,c:1}}
 action logStore=all{s.c==1,s.a,s'={...s,logA:true}}
 action drainControl=all{s.c==1,s'={...s,c:0}}
 action borrow=all{live,not(s.closing),s.borrow==0,s'={...s,borrow:1}}
 action returnBorrow=all{s.borrow==1,s'={...s,borrow:0}}
 // Cleanup callbacks are pre-accounted, not created by an owner that has no admission authority.
 action beginCleanup=all{live,not(s.closing),s.callbacks==0,s'={...s,callbacks:1}}
 action settleCleanup=all{s.callbacks==1,s'={...s,callbacks:0}}
 action observeExit=all{live,s'={...s,exitSeen:true}}
 action closeEntry=all{live,s'={...s,closing:true}}
 // Abstract witnesses: generated noescape common exit, or a successful unique join with full producer census.
 action finishFunnel=all{s.closing,s.d==0,s.c==0,s.borrow==0,s.callbacks==0,
   s'={...s,funnel:true,census:true}}
 action joinSuccess=all{s.closing,s.d==0,s.c==0,s.borrow==0,s.callbacks==0,s'={...s,joined:true}}
 action closeCensus=all{s.joined,s.callbacks==0,s.borrow==0,s'={...s,census:true}}
 action joinUnknown=all{s.exitSeen,s'=s}
 val stopWitness=(s.funnel or s.joined) and s.census
 action sealData=all{s.closing,stopWitness,s.d==0,s.borrow==0,s.callbacks==0,
   s'={...s,dataSeal:true,sealGen:s.gen}}
 action sealControl=all{s.closing,stopWitness,s.c==0,s.callbacks==0,
   s'={...s,controlSeal:true,sealGen:s.gen}}
 val stopped=s.dataSeal and s.controlSeal and s.sealGen==s.gen and s.d==0 and s.c==0 and s.borrow==0 and s.callbacks==0 and stopWitness
 action pin=all{not(s.reclaimed),s.pins==0,s'={...s,pins:1}}
 action unpin=all{s.pins==1,s'={...s,pins:0}}
 action handoff=all{live,stopped,s.pins==0,s.gen<2,
   s'={...s,gen:s.gen+1,authorized:s.authorized+1,closing:false,dataSeal:false,controlSeal:false,sealGen:-1,
     exitSeen:false,funnel:false,joined:false,census:false,reply:false}}
 // Single current generation, exclusive private repair only. Root and external effects never replayed.
 action repair=all{live,not(s.closing),s.d==0,s.c==0,not(s.committed),
   s'={...s,a:true,b:true,logA:true,logB:true}}
 action commit=all{live,not(s.closing),s.d==0,s.c==0,s.a,s.b,s.logA,s.logB,not(s.committed),
   s'={...s,committed:true,commits:s.commits+1}}
 action query=all{not(s.reclaimed),s'={...s,reply:true}}
 action loseReply=all{not(s.reclaimed),s'={...s,reply:false}}
 action scanGc=all{s.source,s.frozen,not(s.scan),not(s.reclaimed),s'={...s,scan:true}}
 action relocate=all{s.scan,s.epoch==0,s'={...s,epoch:1,rootEpoch:1}}
 action endScan=all{s.scan,s'={...s,scan:false}}
 action finish=all{stopped,s.pins==0,not(s.scan),s'={...s,terminal:true}}
 action ack=all{s.terminal,s.reply,s'={...s,ack:true}}
 action release=all{s.terminal,s.ack,stopped,s.pins==0,not(s.scan),s'={...s,source:false,reclaimed:true}}
 action idle=s'=s
 val safe=all{s.gen==s.authorized,s.gen>=0,s.gen<=2,s.commits<=1,
  not(s.dataSeal) or (s.closing and s.d==0 and s.borrow==0 and s.callbacks==0 and stopWitness and s.sealGen==s.gen),
  not(s.controlSeal) or (s.closing and s.c==0 and s.callbacks==0 and stopWitness and s.sealGen==s.gen),
  not(s.committed) or (s.a and s.b and s.logA and s.logB),s.rootEpoch==s.epoch,
  s.source or (s.reclaimed and s.terminal and s.ack and stopped and s.pins==0 and not(s.scan)),
  not(s.scan) or (s.source and s.frozen),not(s.reclaimed) or (s.terminal and s.ack and stopped)}
 action step=any{beginData,store,drainWrite,beginControl,logStore,drainControl,borrow,returnBorrow,
  beginCleanup,settleCleanup,observeExit,closeEntry,finishFunnel,joinSuccess,closeCensus,sealData,sealControl,
  pin,unpin,handoff,repair,commit,query,loseReply,scanGc,relocate,endScan,finish,ack,release,idle}
 action closeAndSeal=closeEntry.then(finishFunnel).then(sealData).then(sealControl)
 action helperOne=init.then(closeAndSeal).then(handoff)
 action helperTwo=helperOne.then(closeAndSeal).then(handoff)
 action check=all{safe,s'=s}
 action unsafeSeal=all{s'={...s,dataSeal:true,sealGen:s.gen}}
 action unsafeHandoff=all{s'={...s,gen:s.gen+1}}
 action unsafeRelease=s'={...s,source:false,reclaimed:true}
 action unsafeReplayRoot=s'={...s,rootEpoch:0}
 action unsafeRecommit=s'={...s,commits:s.commits+1}
 action reject=all{not(safe),s'=s}
 action negativeInit=init.then(beginData).then(observeExit)
 action negativeStep=unsafeSeal
 run normalFunnelTest=init.then(closeAndSeal).then(check)
 run exactThreadJoinTest=init.then(closeEntry).then(joinSuccess).then(closeCensus).then(sealData).then(sealControl).then(check)
 run partialStoreTest=init.then(beginData).then(store).then(observeExit).then(closeEntry).then(drainWrite).then(finishFunnel).then(sealData).then(sealControl).then(handoff).then(repair).then(check)
 run unloggedStoreTest=init.then(beginData).then(store).then(drainWrite).then(closeAndSeal).then(handoff).then(repair).then(check)
 run lostAcquisitionReplyTest=helperOne.then(loseReply).then(observeExit).then(closeAndSeal).then(handoff).then(check)
 run repeatedHelperExitTest=helperTwo.then(observeExit).then(closeAndSeal).then(check)
 run interruptedHelperStoreTest=helperOne.then(beginData).then(store).then(observeExit).then(closeEntry).then(drainWrite).then(finishFunnel).then(sealData).then(sealControl).then(handoff).then(repair).then(check)
 run controlWriteDrainedTest=helperOne.then(beginData).then(store).then(drainWrite).then(beginControl).then(closeEntry).then(logStore).then(drainControl).then(finishFunnel).then(sealData).then(sealControl).then(handoff).then(check)
 run borrowedExitTest=init.then(borrow).then(observeExit).then(closeEntry).then(returnBorrow).then(finishFunnel).then(sealData).then(sealControl).then(check)
 run nestedCleanupDebtTest=init.then(beginCleanup).then(observeExit).then(closeEntry).then(settleCleanup).then(finishFunnel).then(sealData).then(sealControl).then(check)
 run failedJoinRetainsCustodyTest=init.then(observeExit).then(closeEntry).then(joinUnknown).then(check)
 run frozenRootScansDuringUnknownTest=init.then(beginData).then(observeExit).then(scanGc).then(relocate).then(endScan).then(check)
 run movedRootRepairTest=helperOne.then(scanGc).then(relocate).then(endScan).then(repair).then(check)
 run unknownCommitReplyTest=helperOne.then(repair).then(commit).then(loseReply).then(closeAndSeal).then(handoff).then(query).then(check)
 run singleCommitAcrossHelpersTest=helperOne.then(repair).then(commit).then(closeAndSeal).then(handoff).then(query).then(check)
 run readerDrainBeforeHandoffTest=init.then(pin).then(closeAndSeal).then(unpin).then(handoff).then(check)
 run generationExhaustionRetainsTest=helperTwo.then(closeAndSeal).then(query).then(check)
 run completedReleaseTest=helperOne.then(repair).then(commit).then(query).then(closeAndSeal).then(finish).then(ack).then(release).then(check)
 run unknownResultRetainsTest=helperOne.then(repair).then(commit).then(closeAndSeal).then(finish).then(check)
 run dataOnlyCounterexampleTest=init.then(closeEntry).then(finishFunnel).then(sealData).then(unsafeHandoff).then(reject)
 run ownerSealReusedCounterexampleTest=helperOne.then(observeExit).then(unsafeSeal).then(reject)
 run inflightStoreCounterexampleTest=init.then(beginData).then(observeExit).then(unsafeSeal).then(reject)
 run exitOnlyCounterexampleTest=init.then(observeExit).then(unsafeSeal).then(reject)
 run callbackDebtCounterexampleTest=init.then(beginCleanup).then(closeEntry).then(unsafeSeal).then(reject)
 run rawBorrowCounterexampleTest=init.then(borrow).then(closeEntry).then(unsafeSeal).then(reject)
 run unknownResultReleaseCounterexampleTest=helperOne.then(closeAndSeal).then(finish).then(unsafeRelease).then(reject)
 run movedRootReplayCounterexampleTest=helperOne.then(scanGc).then(relocate).then(endScan).then(unsafeReplayRoot).then(reject)
 run duplicateCommitCounterexampleTest=helperOne.then(repair).then(commit).then(unsafeRecommit).then(reject)
}
