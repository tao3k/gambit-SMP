module module_spec_handle {
 // Controlled migration model; complete native coverage is an external qualification obligation.
 type State={phase:int,ticket:int,stage:int,aliases:int,loans:int,entry:int,reply:int,leaf:bool,edges:bool,hasOpaque:bool,qualified:bool,sealed:bool,handle:bool,raw:bool,effects:bool,unknown:bool,privateRoot:bool,publishedRoot:bool,payloadRetired:bool,receipt:bool}
 pure val initial:State={phase:0,ticket:0,stage:0,aliases:0,loans:0,entry:0,reply:0,leaf:false,edges:false,hasOpaque:false,qualified:false,sealed:false,handle:false,raw:false,effects:false,unknown:false,privateRoot:false,publishedRoot:false,payloadRetired:false,receipt:false}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,
 s.phase<=2,
 s.ticket>=0,
 s.ticket<=4,
 s.stage>=0,
 s.stage<=5,
 s.aliases>=0,
 s.aliases<=2,
 s.loans>=0,
 s.loans<=1,
 s.entry>=0,
 s.entry<=1,
 s.reply>=0,
 s.reply<=1,
 s.sealed implies (s.leaf and s.edges and (not(s.hasOpaque) or s.qualified)),
 s.ticket==2 implies s.handle,
 (s.ticket==2 and not(s.payloadRetired)) implies s.publishedRoot,
 s.reply==1 implies s.ticket==2,
 (s.stage==1 or s.stage==3) implies s.entry==1,
 (s.ticket==1 and s.effects) implies s.privateRoot,
 s.payloadRetired implies (s.phase>=1 and s.stage==4 and s.aliases==0 and s.loans==0 and s.entry==0 and not(s.privateRoot) and not(s.unknown) and not(s.raw)),
 s.receipt implies (s.phase>=1 and s.sealed and s.aliases==0 and s.loans==0 and s.entry==0 and not(s.privateRoot) and not(s.raw) and not(s.unknown) and (s.ticket==3 or (s.ticket==2 and s.payloadRetired))),
 s.phase==2 implies s.receipt,
 s.effects implies s.ticket>=1,
 s.payloadRetired implies s.ticket==2}
 action recordLeaf=all{s.phase==0,not(s.sealed),s'={...s,leaf:true}}
 action recordEdges=all{s.phase==0,not(s.sealed),s'={...s,edges:true}}
 action declareOpaque=all{s.phase==0,not(s.sealed),s'={...s,hasOpaque:true}}
 action qualifyNative=all{s.phase==0,not(s.sealed),s'={...s,qualified:true}}
 action sealSpec=all{s.phase==0,s.leaf,s.edges,(not(s.hasOpaque) or s.qualified),s'={...s,sealed:true}}
 action reserve=all{s.phase==0,s.ticket==0,s'={...s,ticket:1}}
 action protectCandidate=all{s.ticket==1,s.phase<=1,s'={...s,privateRoot:true}}
 action startEffects=all{s.ticket==1,s.privateRoot,s.phase<=1,s'={...s,effects:true}}
 action commit=all{s.ticket==1,s.sealed,s.privateRoot,s.phase<=1,s'={...s,ticket:2,handle:true,publishedRoot:true,aliases:2}}
 action acknowledge=all{s.ticket==2,s.phase<=1,s'={...s,reply:1}}
 action retryReply=all{s.ticket==2,s.reply==1,s.phase<=1,s'={...s,reply:1}}
 action dropCandidate=all{s.ticket==2,s.publishedRoot,s.phase<=1,s'={...s,privateRoot:false}}
 action abortBeforeEffects=all{s.ticket==1,not(s.effects),s.phase<=1,s'={...s,ticket:3,privateRoot:false}}
 action unknownReserved=all{s.ticket==1,s.phase<=1,s'={...s,ticket:4,unknown:true}}
 action unknownCommitted=all{s.ticket==2,not(s.payloadRetired),s.phase<=1,s'={...s,unknown:true}}
 action exposeRaw=all{s.ticket==2,s.phase==0,s'={...s,raw:true}}
 action borrowNative=all{s.ticket==2,s.phase==0,s.loans==0,s'={...s,loans:1}}
 action returnBorrow=all{s.loans==1,s'={...s,loans:0}}
 action beginNativeInit=all{s.ticket==2,s.stage==0,s.entry==0,s.phase<=1,s'={...s,stage:1,entry:1}}
 action returnNativeInit=all{s.ticket==2,s.stage==1,s.entry==1,s'={...s,stage:2,entry:0}}
 action beginSchemeInit=all{s.ticket==2,s.stage==2,s.entry==0,s.phase<=1,s'={...s,stage:3,entry:1}}
 action returnSchemeInit=all{s.ticket==2,s.stage==3,s.entry==1,s'={...s,stage:4,entry:0}}
 action failInit=all{s.ticket==2,(s.stage==1 or s.stage==3),s.phase<=1,s'={...s,stage:5,entry:0,unknown:true}}
 action removeAlias=all{s.aliases>0,s.phase==1,s'={...s,aliases:s.aliases-1}}
 action publishAlias=all{s.ticket==2,s.phase==0,s.aliases<2,s'={...s,aliases:s.aliases+1}}
 action close=all{s.phase==0,s.sealed,s'={...s,phase:1}}
 action retirePayload=all{s.phase==1,s.ticket==2,s.stage==4,s.aliases==0,s.loans==0,s.entry==0,not(s.privateRoot),not(s.unknown),not(s.raw),s'={...s,publishedRoot:false,payloadRetired:true}}
 action issue=all{s.phase==1,s.sealed,s.aliases==0,s.loans==0,s.entry==0,not(s.privateRoot),not(s.raw),not(s.unknown),(s.ticket==3 or (s.ticket==2 and s.payloadRetired)),s'={...s,receipt:true}}
 action permit=all{s.phase==1,s.receipt,s'={...s,phase:2}}
 action rejectLate=all{s.phase>=1,s'={...s,phase:s.phase}}
 action step=any{recordLeaf,recordEdges,declareOpaque,qualifyNative,sealSpec,reserve,protectCandidate,startEffects,commit,acknowledge,retryReply,dropCandidate,abortBeforeEffects,unknownReserved,unknownCommitted,exposeRaw,borrowNative,returnBorrow,beginNativeInit,returnNativeInit,beginSchemeInit,returnSchemeInit,failInit,removeAlias,publishAlias,close,retirePayload,issue,permit,rejectLate,all{s'=s}}
 run controlledMigrationTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(acknowledge).then(close).then(removeAlias).then(removeAlias).then(retirePayload).then(issue).then(permit).then(all{assert(safe and s.phase==2 and not(s.raw)),s'=s})
 run postcloseSettlementTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(close).then(commit).then(dropCandidate).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(removeAlias).then(removeAlias).then(retirePayload).then(issue).then(permit).then(all{assert(safe and s.phase==2),s'=s})
 run lostReplyTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(close).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(acknowledge).then(retryReply).then(retryReply).then(removeAlias).then(removeAlias).then(retirePayload).then(issue).then(permit).then(all{assert(safe and s.reply==1 and s.phase==2),s'=s})
 run knownAllocationFailureTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(abortBeforeEffects).then(close).then(issue).then(permit).then(all{assert(safe and s.ticket==3 and s.phase==2),s'=s})
 run opaqueQualifiedTest=init.then(recordLeaf).then(recordEdges).then(declareOpaque).then(qualifyNative).then(sealSpec).then(reserve).then(abortBeforeEffects).then(close).then(issue).then(permit).then(all{assert(safe and s.hasOpaque and s.qualified and s.phase==2),s'=s})
 run rawRetainedTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(exposeRaw).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(close).then(removeAlias).then(removeAlias).then(all{assert(safe and s.raw and not(s.receipt)),s'=s})
 run borrowDrainTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(borrowNative).then(close).then(removeAlias).then(removeAlias).then(returnBorrow).then(retirePayload).then(issue).then(permit).then(all{assert(safe and s.loans==0 and s.phase==2),s'=s})
 run unknownEffectTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(startEffects).then(close).then(unknownReserved).then(all{assert(safe and s.privateRoot and s.unknown and s.ticket==4),s'=s})
 run initFailureTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(beginNativeInit).then(close).then(failInit).then(all{assert(safe and s.unknown and s.stage==5 and not(s.receipt)),s'=s})
 run rejectedLateBorrowTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(close).then(rejectLate).then(removeAlias).then(removeAlias).then(retirePayload).then(issue).then(permit).then(all{assert(safe and s.phase==2),s'=s})
 run missingEdgesControlTest=init.then(recordLeaf).then(all{s'={...s,sealed:true}}).then(all{assert(not(safe)),s'=s})
 run unqualifiedNativeControlTest=init.then(recordLeaf).then(recordEdges).then(declareOpaque).then(all{s'={...s,sealed:true}}).then(all{assert(not(safe)),s'=s})
 run publicationRootGapControlTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(all{s'={...s,ticket:2,handle:true,aliases:2}}).then(all{assert(not(safe)),s'=s})
 run unknownAsAbortControlTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(startEffects).then(unknownReserved).then(close).then(all{s'={...s,receipt:true,phase:2}}).then(all{assert(not(safe)),s'=s})
 run rawFacadeControlTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(exposeRaw).then(close).then(removeAlias).then(removeAlias).then(all{s'={...s,payloadRetired:true,publishedRoot:false,receipt:true,phase:2}}).then(all{assert(not(safe)),s'=s})
 run prematureInitReceiptControlTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(beginNativeInit).then(close).then(removeAlias).then(removeAlias).then(all{s'={...s,payloadRetired:true,receipt:true,phase:2}}).then(all{assert(not(safe)),s'=s})
 run lostLoanControlTest=init.then(recordLeaf).then(recordEdges).then(sealSpec).then(reserve).then(protectCandidate).then(commit).then(dropCandidate).then(beginNativeInit).then(returnNativeInit).then(beginSchemeInit).then(returnSchemeInit).then(borrowNative).then(close).then(removeAlias).then(removeAlias).then(all{s'={...s,payloadRetired:true,receipt:true,phase:2}}).then(all{assert(not(safe)),s'=s})
}
