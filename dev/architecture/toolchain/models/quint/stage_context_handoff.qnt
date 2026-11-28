// Interface refinement slice. Reuse the existing DAG; do not implement a second scheduler.
module stage_context_handoff {
 import incremental_build as B from "../../../../../models/build/incremental_build"
 val N=Set(0,1)
 type Node={stage:int,context:int,leaseEpoch:int,readClosed:bool,writeClosed:bool,productRoot:bool,semanticPublished:bool,published:bool,ack:bool}
 val fresh:Node={stage:0,context:-1,leaseEpoch:0,readClosed:false,writeClosed:false,productRoot:false,semanticPublished:false,published:false,ack:false}
 type Handoff={nodes:int->Node,owners:int->int,epochs:int->int}
 val base:Handoff={nodes:Map(0->fresh,1->fresh),owners:Map(0-> -1,1-> -1),epochs:Map(0->0,1->0)}
 var h:Handoff
 action init=all{B::initMacro,h'=base}
 action initUnchanged=all{B::initNoChange,h'=base}
 def canRequest(n:int,c:int):bool=h.nodes.get(n).stage==0 and h.owners.get(c)== -1 and h.epochs.get(c)<2
 action request(n,c)=all{canRequest(n,c),B::start(n),h'={...h,nodes:h.nodes.set(n,{...fresh,stage:1,context:c,leaseEpoch:h.epochs.get(c)+1}),owners:h.owners.set(c,n),epochs:h.epochs.set(c,h.epochs.get(c)+1)}}
 def canTouch(n:int,c:int,g:int):bool=h.nodes.get(n).stage==1 and h.nodes.get(n).context==c and h.nodes.get(n).leaseEpoch==g and h.owners.get(c)==n and h.epochs.get(c)==g
 action closeReads(n)=all{h.nodes.get(n).stage==1,B::s'=B::s,h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),readClosed:true})}}
 action closeWriters(n)=all{h.nodes.get(n).stage==1,B::s'=B::s,h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),writeClosed:true})}}
 def canSeal(n:int):bool=h.nodes.get(n).stage==1 and h.nodes.get(n).readClosed and h.nodes.get(n).writeClosed and B::s.stable and not(B::s.cancelled)
 action sealSemantic(n)=all{canSeal(n),B::s'=B::s,h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),stage:2,productRoot:true})}}
 def semanticReadable(n:int):bool=h.nodes.get(n).semanticPublished and h.nodes.get(n).productRoot and B::s.stable and not(B::s.cancelled)
 action publishSemantic(n)=all{h.nodes.get(n).stage==2,h.nodes.get(n).productRoot,B::s.stable,not(B::s.cancelled),B::s'=B::s,h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),semanticPublished:true})}}
 action handoffEmitter(n,c)=all{h.nodes.get(n).stage==2,semanticReadable(n),h.owners.get(c)== -1,h.epochs.get(c)<2,B::s'=B::s,h'={...h,owners:h.owners.set(h.nodes.get(n).context,-1).set(c,n),epochs:h.epochs.set(c,h.epochs.get(c)+1),nodes:h.nodes.set(n,{...h.nodes.get(n),context:c,leaseEpoch:h.epochs.get(c)+1})}}
 // Physical layout completion is separate from semantic sealing.
 action sealLayout(n)=all{h.nodes.get(n).stage==2,B::finish(n),h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),stage:3})}}
 action publish(n)=all{h.nodes.get(n).stage==3,h.nodes.get(n).productRoot,B::publish(n),h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),stage:4,published:true,ack:false})}}
 action observeCommitted(n)=all{h.nodes.get(n).published,B::s'=B::s,h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),ack:true})}}
 action invalidate=all{B::invalidate,h'=h}
 action cancel=all{B::cancel,h'=h}
 action prepareAbortOpen(n)=all{h.nodes.get(n).stage==1,not(B::s.stable) or B::s.cancelled,B::finish(n),h'=h}
 action discardOpen(n)=all{h.nodes.get(n).stage==1,B::discard(n),h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),stage:5})}}
 action discard(n)=all{h.nodes.get(n).stage==3,B::discard(n),h'={...h,nodes:h.nodes.set(n,{...h.nodes.get(n),stage:5})}}
 def canRelease(n:int):bool=Set(4,5).contains(h.nodes.get(n).stage) and (not(h.nodes.get(n).published) or h.nodes.get(n).productRoot)
 action releaseContext(n)=all{canRelease(n),B::s'=B::s,h'={...h,owners:h.owners.set(h.nodes.get(n).context,-1),nodes:h.nodes.set(n,{...h.nodes.get(n),context:-1,stage:6})}}
 action hit(n)=all{B::reuse(n),h'=h}
 val privateOwners=N.forall(n=>if(h.nodes.get(n).context>=0) h.owners.get(h.nodes.get(n).context)==n and h.epochs.get(h.nodes.get(n).context)==h.nodes.get(n).leaseEpoch else true)
 val safe=B::safe and privateOwners and N.forall(n=>(h.nodes.get(n).semanticPublished implies h.nodes.get(n).productRoot and h.nodes.get(n).readClosed and h.nodes.get(n).writeClosed) and (h.nodes.get(n).published implies B::s.phase.get(n)==2 and h.nodes.get(n).productRoot and h.nodes.get(n).readClosed and h.nodes.get(n).writeClosed) and (Set(2,3).contains(h.nodes.get(n).stage) implies h.nodes.get(n).productRoot and h.nodes.get(n).readClosed and h.nodes.get(n).writeClosed))
 action sealed(n,c)=request(n,c).then(closeReads(n)).then(closeWriters(n)).then(sealSemantic(n))
 action finished(n,c)=sealed(n,c).then(sealLayout(n)).then(publish(n))
 action step={nondet n=N.oneOf();nondet c=N.oneOf();any{request(n,c),closeReads(n),closeWriters(n),sealSemantic(n),publishSemantic(n),handoffEmitter(n,c),sealLayout(n),publish(n),observeCommitted(n),releaseContext(n),discard(n),prepareAbortOpen(n),discardOpen(n),hit(n),invalidate,cancel,all{B::s'=B::s,h'=h}}}
 run privateContextRefusesSecondOwnerTest=init.then(request(0,0)).expect(safe and not(canRequest(1,0)))
 run twoPrivateConsumersCanProceedTest=init.then(request(0,0)).then(request(1,1)).expect(safe and B::s.used==2 and h.owners.get(0)!=h.owners.get(1))
 run writersMustCloseBeforeSealTest=init.then(request(0,0)).then(closeReads(0)).expect(safe and not(canSeal(0)))
 run readersMustCloseBeforeSealTest=init.then(request(0,0)).then(closeWriters(0)).expect(safe and not(canSeal(0)))
 run semanticProductIsNotPublishedLayoutTest=init.then(sealed(0,0)).expect(safe and B::s.phase.get(0)==1 and not(h.nodes.get(0).published) and not(canRelease(0)))
 run lateDependencyBlocksPublicationTest=init.then(sealed(0,0)).then(invalidate).then(sealLayout(0)).then(discard(0)).expect(safe and not(h.nodes.get(0).published))
 run cancelKeepsContextUntilDiscardTest=init.then(sealed(0,0)).then(cancel).expect(safe and h.owners.get(0)==0 and not(canRelease(0)))
 run committedAckLossDoesNotReplayTest=init.then(finished(0,0)).expect(safe and h.nodes.get(0).published and not(h.nodes.get(0).ack) and B::s.phase.get(0)==2)
 run releaseKeepsIndependentProductRootTest=init.then(finished(0,0)).then(releaseContext(0)).expect(safe and h.owners.get(0)== -1 and h.nodes.get(0).productRoot and h.nodes.get(0).published)
 run observeAfterContextReleaseTest=init.then(finished(0,0)).then(releaseContext(0)).then(observeCommitted(0)).expect(safe and h.nodes.get(0).ack)
 run unchangedHitNeedsNoContextTest=initUnchanged.then(hit(0)).expect(safe and h.owners==base.owners and B::s.executed==Set())
 action stealContextControl=all{B::start(1),h'={...h,nodes:h.nodes.set(1,{...fresh,stage:1,context:0,leaseEpoch:1}),owners:h.owners.set(0,1)}}
 run stolenContextNegativeTest=init.then(request(0,0)).then(stealContextControl).expect(not(safe))
 action codeOnlyPublishControl=all{B::s'=B::s,h'={...h,nodes:h.nodes.set(0,{...h.nodes.get(0),published:true,stage:4})}}
 run codeOnlyPublicationNegativeTest=init.then(sealed(0,0)).then(codeOnlyPublishControl).expect(not(safe))
 run recycledContextRefusesOldEpochTest=init.then(finished(0,0)).then(releaseContext(0)).then(request(1,0)).expect(safe and not(canTouch(1,0,1)) and canTouch(1,0,2))
 run invalidationBeforeSealCanReleaseTest=init.then(request(0,0)).then(invalidate).then(prepareAbortOpen(0)).then(discardOpen(0)).then(releaseContext(0)).expect(safe and h.owners.get(0)== -1 and not(h.nodes.get(0).published))
 run semanticReadyPrecedesNativeReadyTest=init.then(sealed(0,0)).then(publishSemantic(0)).expect(safe and semanticReadable(0) and B::s.phase.get(0)==1 and not(h.nodes.get(0).published))
 run semanticHandoffReleasesFrontendContextTest=init.then(sealed(0,0)).then(publishSemantic(0)).then(handoffEmitter(0,1)).then(request(1,0)).expect(safe and h.owners.get(1)==0 and h.owners.get(0)==1 and B::s.used==2 and not(canTouch(1,0,1)))
 run lateDependencyKeepsExistingProductButRefusesNewReadTest=init.then(sealed(0,0)).then(publishSemantic(0)).then(invalidate).expect(safe and h.nodes.get(0).productRoot and not(semanticReadable(0)))
}
