module emission_view_correspondence {
 // External premises: complete writer/alias closure and qualified emitter witness verifier.
 type State={phase:int,generation:int,snapshot:int,pending:int,writers:int,cGen:int,mGen:int,frontCaptured:bool,lateCaptured:bool,aliasesClosed:bool,inputFrozen:bool,fragmentsOwned:bool,layoutDone:bool,escaped:bool,opaqueSeen:bool,nativeQualified:bool,verifierQualified:bool,cDone:bool,mDone:bool,coverage:bool,ioComplete:bool,receipt:bool,nativeReady:bool}
 pure val initial:State={phase:0,generation:1,snapshot:0,pending:0,writers:0,cGen:0,mGen:0,frontCaptured:false,lateCaptured:false,aliasesClosed:false,inputFrozen:false,fragmentsOwned:false,layoutDone:false,escaped:false,opaqueSeen:false,nativeQualified:false,verifierQualified:false,cDone:false,mDone:false,coverage:false,ioComplete:false,receipt:false,nativeReady:false}
 var s:State
 action init=s'=initial
 val safe=all{s.phase>=0,
 s.phase<=4,
 s.generation>=1,
 s.snapshot>=0,
 s.pending>=0,
 s.pending<=2,
 s.writers>=0,
 s.writers<=1,
 s.cGen>=0,
 s.mGen>=0,
 (s.phase==2 or s.phase==3) implies (s.frontCaptured and s.lateCaptured and s.aliasesClosed and s.inputFrozen and s.fragmentsOwned and s.layoutDone and s.pending==0 and s.writers==0 and not(s.escaped) and s.snapshot==s.generation),
 s.aliasesClosed implies (s.phase>=1 and s.writers==0),
 s.inputFrozen implies s.aliasesClosed,
 s.fragmentsOwned implies s.aliasesClosed,
 s.layoutDone implies (s.aliasesClosed and s.inputFrozen and s.fragmentsOwned and s.pending==0 and s.writers==0),
 s.cDone implies (s.phase>=2 and s.cGen==s.snapshot),
 s.mDone implies (s.phase>=2 and s.mGen==s.snapshot),
 s.coverage implies (s.cDone and s.mDone and s.verifierQualified),
 s.ioComplete implies (s.cDone and s.mDone),
 s.receipt implies (s.phase==3 and s.coverage and s.ioComplete and s.cGen==s.generation and s.mGen==s.generation),
 s.phase==3 implies s.receipt,
 s.nativeReady implies (s.receipt and (not(s.opaqueSeen) or s.nativeQualified))}
 action captureFront=all{s.phase==0,not(s.frontCaptured),s.pending<2,s'={...s,frontCaptured:true,pending:s.pending+1,generation:s.generation+1}}
 action captureLate=all{s.phase==0,not(s.lateCaptured),s.pending<2,s'={...s,lateCaptured:true,pending:s.pending+1,generation:s.generation+1}}
 action discoverChild=all{s.phase<=1,s.pending>0,s.pending<2,s'={...s,pending:s.pending+1,generation:s.generation+1}}
 action drainOne=all{s.phase<=1,s.pending>0,s'={...s,pending:s.pending-1,generation:s.generation+1}}
 action reserveWriter=all{s.phase==0,s.writers==0,s'={...s,writers:1}}
 action writerPublish=all{s.phase<=1,s.writers==1,s.pending<2,s'={...s,pending:s.pending+1,generation:s.generation+1}}
 action writerDone=all{s.phase<=1,s.writers==1,s'={...s,writers:0}}
 action unknownWriter=all{s.phase<=1,s.writers==1,s'={...s,phase:4}}
 action escapeAlias=all{s.phase<=1,not(s.aliasesClosed),s'={...s,escaped:true}}
 action beginClose=all{s.phase==0,s.frontCaptured,s.lateCaptured,s'={...s,phase:1}}
 action closeAliases=all{s.phase==1,s.writers==0,not(s.escaped),s'={...s,aliasesClosed:true}}
 action freezeInputs=all{s.phase==1,s.aliasesClosed,not(s.inputFrozen),s'={...s,inputFrozen:true,generation:s.generation+1}}
 action declareOpaque=all{s.phase<=1,not(s.fragmentsOwned),s'={...s,opaqueSeen:true,generation:s.generation+1}}
 action copyFragments=all{s.phase==1,s.aliasesClosed,s.inputFrozen,not(s.fragmentsOwned),s'={...s,fragmentsOwned:true,generation:s.generation+1}}
 action qualifyNative=all{s.phase==1,s'={...s,nativeQualified:true,generation:s.generation+1,layoutDone:false}}
 action qualifyVerifier=all{s.phase==1,s'={...s,verifierQualified:true,generation:s.generation+1,layoutDone:false}}
 action resolveLayout=all{s.phase==1,s.aliasesClosed,s.inputFrozen,s.fragmentsOwned,s.pending==0,s.writers==0,not(s.layoutDone),s'={...s,layoutDone:true,generation:s.generation+1}}
 action lateLayoutWrite=all{s.phase==1,s.layoutDone,s'={...s,layoutDone:false,pending:1,generation:s.generation+1}}
 action freeze=all{s.phase==1,s.frontCaptured,s.lateCaptured,s.aliasesClosed,s.inputFrozen,s.fragmentsOwned,s.layoutDone,s.pending==0,s.writers==0,not(s.escaped),s'={...s,phase:2,snapshot:s.generation}}
 action emitC=all{s.phase==2,not(s.cDone),s'={...s,cDone:true,cGen:s.snapshot}}
 action emitSpec=all{s.phase==2,not(s.mDone),s'={...s,mDone:true,mGen:s.snapshot}}
 action verifyCoverage=all{s.phase==2,s.cDone,s.mDone,s.verifierQualified,s'={...s,coverage:true}}
 action closeOutputs=all{s.phase==2,s.cDone,s.mDone,s'={...s,ioComplete:true}}
 action issue=all{s.phase==2,s.coverage,s.ioComplete,s.cGen==s.generation,s.mGen==s.generation,s'={...s,phase:3,receipt:true}}
 action nativePermit=all{s.phase==3,s.receipt,(not(s.opaqueSeen) or s.nativeQualified),s'={...s,nativeReady:true}}
 action rejectSnapshot=all{s.phase==2,s'={...s,phase:4,generation:s.generation+1}}
 action unknownOutput=all{s.phase==2,s'={...s,phase:4}}
 action rejectLateWriter=all{s.phase>=1,s'={...s,writers:s.writers}}
 action step=any{captureFront,captureLate,discoverChild,drainOne,reserveWriter,writerPublish,writerDone,unknownWriter,escapeAlias,beginClose,closeAliases,freezeInputs,declareOpaque,copyFragments,qualifyNative,qualifyVerifier,resolveLayout,lateLayoutWrite,freeze,emitC,emitSpec,verifyCoverage,closeOutputs,issue,nativePermit,rejectSnapshot,unknownOutput,rejectLateWriter,all{s'=s}}
 run completeEmissionTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(nativePermit).then(all{assert(safe and s.receipt and s.nativeReady),s'=s})
 run lateRootsFixedPointTest=init.then(captureFront).then(drainOne).then(captureLate).then(discoverChild).then(drainOne).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(all{assert(safe and s.pending==0 and s.receipt),s'=s})
 run emptyQueueNotClosureTest=init.then(captureFront).then(drainOne).then(all{assert(safe and not(s.lateCaptured) and not(s.receipt)),s'=s})
 run acceptedWriterAfterCloseTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(reserveWriter).then(beginClose).then(writerPublish).then(writerDone).then(drainOne).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run layoutReopenTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(lateLayoutWrite).then(drainOne).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(all{assert(safe and s.receipt),s'=s})
 run opaqueTextOnlyTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(declareOpaque).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(all{assert(safe and s.receipt and not(s.nativeReady) and not(s.nativeQualified)),s'=s})
 run opaqueQualifiedTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(declareOpaque).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(qualifyNative).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(nativePermit).then(all{assert(safe and s.nativeReady and s.nativeQualified),s'=s})
 run escapedAliasRetainedTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(escapeAlias).then(beginClose).then(all{assert(safe and s.escaped and not(s.aliasesClosed)),s'=s})
 run unknownWriterTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(reserveWriter).then(beginClose).then(unknownWriter).then(all{assert(safe and s.writers==1 and s.phase==4 and not(s.receipt)),s'=s})
 run unknownOutputTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(unknownOutput).then(all{assert(safe and s.phase==4 and not(s.receipt)),s'=s})
 run snapshotRejectedTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(rejectSnapshot).then(all{assert(safe and s.phase==4 and not(s.receipt)),s'=s})
 run lateWriterRejectedTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(rejectLateWriter).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(all{assert(safe and s.receipt and s.writers==0),s'=s})
 run missingLateRootsControlTest=init.then(captureFront).then(drainOne).then(all{s'={...s,phase:2,snapshot:s.generation}}).then(all{assert(not(safe)),s'=s})
 run inflightWriterControlTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(reserveWriter).then(all{s'={...s,phase:2,snapshot:s.generation}}).then(all{assert(not(safe)),s'=s})
 run shallowAliasControlTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(escapeAlias).then(all{s'={...s,phase:2,snapshot:s.generation}}).then(all{assert(not(safe)),s'=s})
 run layoutUnresolvedControlTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(all{s'={...s,phase:2,snapshot:s.generation}}).then(all{assert(not(safe)),s'=s})
 run mismatchedGenerationControlTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(all{s'={...s,mGen:s.snapshot+1}}).then(all{assert(not(safe)),s'=s})
 run unverifiedCoverageControlTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(closeOutputs).then(all{s'={...s,receipt:true,phase:3}}).then(all{assert(not(safe)),s'=s})
 run truncatedOutputControlTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(all{s'={...s,receipt:true,phase:3}}).then(all{assert(not(safe)),s'=s})
 run opaqueOwnershipControlTest=init.then(captureFront).then(drainOne).then(captureLate).then(drainOne).then(declareOpaque).then(beginClose).then(closeAliases).then(freezeInputs).then(copyFragments).then(qualifyVerifier).then(resolveLayout).then(freeze).then(emitC).then(emitSpec).then(verifyCoverage).then(closeOutputs).then(issue).then(all{s'={...s,nativeReady:true}}).then(all{assert(not(safe)),s'=s})
}
