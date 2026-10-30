module frame_seal_root_scope {
 // One symbolic request stands for any origin, including one outside participant_count.
 // Root closure and ABI matching remain external premises; constants are model witnesses.
 type State={live:int,snap:int,rootEpoch:int,seen:int,request:int,Q:int,A:int,T:int,B:int,denied:int,owner:bool,aliases:bool,sealedView:bool,frozen:bool,covered:bool,modulePinned:bool,moduleClosed:bool,ledger:bool,receipt:bool,started:bool,alternative:bool,retained:bool}
 pure val initial:State={live:1,snap:0,rootEpoch:1,seen:0,request:0,Q:0,A:0,T:0,B:0,denied:0,owner:false,aliases:false,sealedView:false,frozen:false,covered:false,modulePinned:true,moduleClosed:true,ledger:false,receipt:false,started:false,alternative:false,retained:false}
 var s:State
 action init=s'=initial
 val safe=all{s.live>=1,
 s.snap>=0,
 s.snap<=s.live,
 s.rootEpoch>=1,
 s.seen>=0,
 s.seen<=s.rootEpoch,
 s.request>=0,
 s.request<=5,
 s.Q>=0,
 s.A>=0,
 s.T>=0,
 s.B>=0,
 s.denied>=0,
 s.sealedView implies (s.aliases and s.snap>=1),
 s.frozen implies (s.request!=1 and s.seen==s.rootEpoch),
 s.covered implies (s.frozen and s.moduleClosed and s.modulePinned and s.B>=s.Q+s.A+s.T),
 s.receipt implies (s.sealedView and s.covered and s.frozen and s.modulePinned and s.moduleClosed and not(s.alternative)),
 s.started implies s.receipt,
 s.alternative implies (s.retained and not(s.receipt) and not(s.started)),
 (s.request>=1 or s.ledger) implies s.modulePinned}
 action own=all{not(s.sealedView),not(s.alternative),s'={...s,owner:true,aliases:true}}
 action mutateLive=all{not(s.owner),s'={...s,live:s.live+1}}
 action seal=all{s.owner,s.aliases,not(s.sealedView),not(s.alternative),s'={...s,sealedView:true,snap:s.live,owner:false}}
 action beginRequest=all{not(s.frozen),not(s.alternative),s.request==0,s.modulePinned,s'={...s,request:1}}
 action publishRequest=all{s.request==1,not(s.frozen),s'={...s,request:2,rootEpoch:s.rootEpoch+1}}
 action selectRequest=all{s.request==2,not(s.frozen),s'={...s,request:3,ledger:true}}
 action unknownRequest=all{(s.request==2 or s.request==3),s.modulePinned,not(s.frozen),s'={...s,request:5,retained:true}}
 action completeRequest=all{s.request==3,s.ledger,not(s.frozen),s'={...s,request:4}}
 action ackSource=all{s.request==4,s.ledger,not(s.frozen),s'={...s,request:0,rootEpoch:s.rootEpoch+1}}
 action freeze=all{s.request!=1,not(s.frozen),not(s.alternative),s.modulePinned,s.moduleClosed,s'={...s,frozen:true,seen:s.rootEpoch}}
 action coverSource=all{s.frozen,not(s.covered),s.moduleClosed,s.modulePinned,s'={...s,covered:true,Q:510,A:0,T:2,B:512}}
 action issue=all{s.sealedView,s.covered,s.frozen,s.modulePinned,s.moduleClosed,s.seen==s.rootEpoch,not(s.alternative),not(s.receipt),s'={...s,receipt:true}}
 action start=all{s.receipt,not(s.started),s'={...s,started:true}}
 action relocate=all{s.started,s'={...s,denied:s.denied+0}}
 action deferRootWriter=all{s.frozen,s'={...s,denied:s.denied+1}}
 action revokeBeforeCopy=all{not(s.started),not(s.alternative),s'={...s,receipt:false,covered:false,frozen:false,alternative:true,retained:true}}
 action finishRound=all{s.started,s'={...s,started:false,receipt:false,covered:false,frozen:false}}
 action closeLedger=all{not(s.frozen),s.request==0,s.ledger,s'={...s,ledger:false,rootEpoch:s.rootEpoch+1}}
 action retireModule=all{not(s.frozen),not(s.receipt),not(s.started),s.request==0,not(s.ledger),s'={...s,modulePinned:false}}
 action rejectOpaque=all{not(s.frozen),not(s.started),not(s.alternative),s'={...s,moduleClosed:false,alternative:true,retained:true,receipt:false,covered:false}}
 action step=any{own,mutateLive,seal,beginRequest,publishRequest,selectRequest,unknownRequest,completeRequest,ackSource,freeze,coverSource,issue,start,relocate,deferRootWriter,revokeBeforeCopy,finishRound,closeLedger,retireModule,rejectOpaque,all{s'=s}}
 run selectedRootTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(selectRequest).then(freeze).then(coverSource).then(issue).then(start).then(relocate).then(all{assert(safe and s.ledger and s.request==3),s'=s})
 run retainedRootTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(unknownRequest).then(freeze).then(coverSource).then(issue).then(start).then(all{assert(safe and s.request==5 and s.retained),s'=s})
 run privateAliasTest=init.then(own).then(seal).then(mutateLive).then(freeze).then(coverSource).then(issue).then(all{assert(safe and s.live==2 and s.snap==1),s'=s})
 run sourceAckTest=init.then(beginRequest).then(publishRequest).then(selectRequest).then(completeRequest).then(ackSource).then(all{assert(safe and s.request==0 and s.ledger),s'=s})
 run revocationTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(selectRequest).then(freeze).then(coverSource).then(issue).then(revokeBeforeCopy).then(all{assert(safe and s.alternative and not(s.receipt)),s'=s})
 run deferredWriterTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(selectRequest).then(freeze).then(coverSource).then(issue).then(start).then(deferRootWriter).then(all{assert(safe and s.rootEpoch==2 and s.denied==1),s'=s})
 run roundFinishTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(selectRequest).then(freeze).then(coverSource).then(issue).then(start).then(finishRound).then(completeRequest).then(ackSource).then(closeLedger).then(retireModule).then(all{assert(safe and not(s.modulePinned)),s'=s})
 run opaqueAlternativeTest=init.then(own).then(seal).then(rejectOpaque).then(all{assert(safe and s.alternative),s'=s})
 run writingFreezeControlTest=init.then(beginRequest).then(all{s'={...s,frozen:true,seen:s.rootEpoch}}).then(all{assert(not(safe)),s'=s})
 run missingPinControlTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(selectRequest).then(freeze).then(coverSource).then(issue).then(all{s'={...s,modulePinned:false}}).then(all{assert(not(safe)),s'=s})
 run staleRootControlTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(selectRequest).then(freeze).then(coverSource).then(issue).then(all{s'={...s,rootEpoch:s.rootEpoch+1}}).then(all{assert(not(safe)),s'=s})
 run underBudgetControlTest=init.then(own).then(seal).then(beginRequest).then(publishRequest).then(selectRequest).then(freeze).then(coverSource).then(issue).then(all{s'={...s,B:511}}).then(all{assert(not(safe)),s'=s})
 run earlyAckControlTest=init.then(beginRequest).then(publishRequest).then(all{s'={...s,request:0,modulePinned:false,ledger:true}}).then(all{assert(not(safe)),s'=s})
}
