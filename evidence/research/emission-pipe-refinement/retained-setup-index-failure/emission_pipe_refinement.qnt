module emission_pipe_refinement {
 // Product of two distinct contexts: ordinary emitter and legal debug-pipe witness.
 type State={ep:int,profile:int,demand:int,epoch:int,planEpoch:int,certEpoch:int,outputCalls:int,pc:int,wlo:int,whi:int,rlo:int,rhi:int,emitted:int,delivered:int,index:int,savedIndex:int,wgen:int,rgen:int,resumes:int,completed:int,writer:int,savedWriter:int,unknown:bool,fault:bool,attested:bool,certificate:bool,special:bool,shared:bool,locked:bool,captured:bool,custody:bool,clobbered:bool}
 pure val initial:State={ep:0,profile:0,demand:0,epoch:1,planEpoch:1,certEpoch:0,outputCalls:0,pc:0,wlo:0,whi:0,rlo:0,rhi:0,emitted:0,delivered:0,index:58,savedIndex:58,wgen:1,rgen:0,resumes:0,completed:0,writer:1,savedWriter:1,unknown:false,fault:false,attested:false,certificate:false,special:false,shared:false,locked:false,captured:false,custody:false,clobbered:false}
 var s:State
 action init=s'=initial
 val safe=all{s.ep>=0,
s.ep<=6,
s.profile>=0,
s.profile<=2,
s.demand>=0,
s.demand<=2,
s.epoch>=1,
s.planEpoch>=1,
s.certEpoch>=0,
s.outputCalls>=0,
not(s.special),
s.certificate implies ((s.ep==4 or s.ep==5) and s.attested and s.profile<=1 and s.demand==1 and s.epoch==s.planEpoch and s.certEpoch==s.epoch and not(s.unknown) and not(s.fault)),
s.pc>=0,
s.pc<=5,
s.wlo>=0,
s.wlo<=32,
s.whi>=0,
s.whi<=32,
s.rlo>=0,
s.rlo<=s.rhi,
s.rhi<=32,
s.emitted>=0,
s.delivered>=0,
s.emitted-s.delivered==s.wlo+s.whi-s.rlo,
s.emitted>=s.delivered,
s.savedIndex==58,
s.index==58 or s.index==80,
s.wgen>=1,
s.rgen>=0,
s.rgen<s.wgen+1,
s.shared implies (s.wlo==0 and s.rhi<=s.whi and s.rgen==s.wgen),
not(s.shared) implies (s.wlo==s.rhi and s.rgen<s.wgen),
s.resumes>=0,
s.completed>=0,
s.completed<=s.resumes,
(s.pc==2 or s.pc==3 or s.pc==4) implies s.completed+1==s.resumes,
(s.pc==0 or s.pc==1 or s.pc==5) implies s.completed==s.resumes,
s.writer>=0,
s.writer<=2,
s.savedWriter==1,
s.pc>=1 implies (s.captured and s.custody),
s.pc==1 implies (s.whi==32 and s.index==58 and not(s.locked)),
s.pc==2 implies (s.shared and s.rlo==s.whi and s.rhi==s.whi and s.locked and s.index==58),
s.pc==3 implies (not(s.shared) and s.whi==0 and s.locked and s.index==58),
s.pc==4 implies (not(s.shared) and s.whi==23 and s.locked and s.index==80),
s.pc==5 implies (s.whi==23 and s.index==80 and not(s.locked)),
s.pc==0 implies not(s.locked),
s.pc==0 implies (s.emitted==0 and s.delivered==0 and s.wlo==0 and s.whi==0 and s.rlo==0 and s.rhi==0 and s.resumes==0 and s.completed==0 and s.rgen==0 and s.wgen==1)}
 action first=all{s.ep==0,s'={...s,ep:1,demand:1,planEpoch:s.epoch}}
 action selectDebug=all{s.ep==0,s'={...s,profile:1}}
 action selectCustom=all{s.ep==0,s'={...s,profile:2}}
 action prmRemainder=all{s.ep==1,s'={...s,ep:2}}
 action initText=all{s.ep==2,s'={...s,ep:3}}
 action gloPrefix=all{s.ep==3,s'={...s,ep:4}}
 action scalarDispatch=all{s.ep>=1,s.ep<=4,s'={...s,outputCalls:s.outputCalls+1}}
 action namedEffect=all{s.ep>=1,s.ep<=4,s'={...s,demand:1}}
 action customRaw=all{s.ep>=1,s.ep<=4,s.profile==2,s'={...s,demand:2,attested:false,certificate:false}}
 action replaceEntry=all{s.ep>=1,s.ep<=4,s'={...s,epoch:s.epoch+1,demand:0,attested:false,certificate:false}}
 action unknownEffect=all{s.ep>=1,s.ep<=4,s'={...s,unknown:true,attested:false,certificate:false}}
 action ioAbort=all{s.ep>=1,s.ep<=4,s'={...s,ep:6,fault:true,attested:false,certificate:false}}
 action attest=all{s.ep==4,s.profile<=1,s.demand==1,s.epoch==s.planEpoch,not(s.unknown),not(s.fault),s'={...s,attested:true}}
 action issue=all{s.ep==4,s.profile<=1,s.demand==1,s.epoch==s.planEpoch,not(s.unknown),not(s.fault),s.attested,s'={...s,certificate:true,certEpoch:s.epoch}}
 action second=all{s.ep==4,s'={...s,ep:5,demand:1}}
 action omitSecond=all{s.ep==4,s.certificate,s'={...s,ep:5}}
 action pause=all{s.pc==0,s'={...s,pc:1,wlo:32,whi:32,rlo:0,rhi:32,emitted:64,captured:true,custody:true,writer:0,wgen:2,rgen:1}}
 action readChunk=all{s.pc==1,not(s.shared),s.rlo<s.rhi,s'={...s,delivered:s.delivered+s.rhi-s.rlo,rlo:s.rhi}}
 action advanceReader=all{s.pc==1 or s.pc==5,not(s.shared),s.rlo==s.rhi,s'={...s,wlo:s.wlo-s.rlo,rlo:0,rhi:0,shared:true,rgen:s.wgen}}
 action exposeWriter=all{s.pc==1 or s.pc==5,s.shared,s.rhi<s.whi,s'={...s,rhi:s.whi}}
 action consumeWriter=all{s.pc==1 or s.pc==5,s.shared,s.rlo<s.rhi,s'={...s,delivered:s.delivered+s.rhi-s.rlo,rlo:s.rhi}}
 action resume=all{s.pc==1 or s.pc==5,s.shared,s.rlo==s.whi,s.captured,s.custody,s'={...s,pc:2,locked:true,index:s.savedIndex,resumes:s.resumes+1}}
 action publish=all{s.pc==2,s.locked,s.shared,s.wlo-s.rlo<=1,s'={...s,pc:3,wlo:s.wlo+s.whi,whi:0,shared:false,wgen:s.wgen+1}}
 action appendTail=all{s.pc==3,s.index==58,s.whi==0,s'={...s,pc:4,index:80,whi:23,emitted:s.emitted+23}}
 action finish=all{s.pc==4,s'={...s,pc:5,locked:false,writer:s.savedWriter,completed:s.completed+1,clobbered:s.clobbered or s.writer==2}}
 action installNew=all{s.pc==1 or s.pc==5,s'={...s,writer:2}}
 action step=any{first,selectDebug,selectCustom,prmRemainder,initText,gloPrefix,scalarDispatch,namedEffect,customRaw,replaceEntry,unknownEffect,ioAbort,attest,issue,second,omitSecond,pause,readChunk,advanceReader,exposeWriter,consumeWriter,resume,publish,appendTail,finish,installNew,all{s'=s}}
 run defaultOrdinaryTest=init.then(first).then(prmRemainder).then(initText).then(gloPrefix).then(scalarDispatch).then(second).then(all{assert(safe and not(s.special) and not(s.certificate)),s'=s})
 run debugScalarTest=init.then(selectDebug).then(first).then(prmRemainder).then(initText).then(gloPrefix).then(scalarDispatch).then(second).then(all{assert(safe and s.profile==1 and not(s.special)),s'=s})
 run conditionalRetirementTest=init.then(first).then(prmRemainder).then(initText).then(gloPrefix).then(attest).then(issue).then(omitSecond).then(all{assert(safe and s.certificate and s.demand==1),s'=s})
 run ioFailureTest=init.then(first).then(ioAbort).then(all{assert(safe and s.ep==6 and s.fault and not(s.certificate)),s'=s})
 run customWriterTest=init.then(selectCustom).then(first).then(prmRemainder).then(initText).then(gloPrefix).then(customRaw).then(second).then(all{assert(safe and s.demand==1 and s.profile==2 and not(s.certificate)),s'=s})
 run newEntryTest=init.then(first).then(prmRemainder).then(initText).then(gloPrefix).then(replaceEntry).then(namedEffect).then(second).then(all{assert(safe and s.epoch!=s.planEpoch and not(s.certificate)),s'=s})
 run unknownCallbackTest=init.then(first).then(prmRemainder).then(initText).then(gloPrefix).then(unknownEffect).then(second).then(all{assert(safe and s.unknown and not(s.certificate)),s'=s})
 run firstPhysicalDrainTest=init.then(pause).then(readChunk).then(advanceReader).then(exposeWriter).then(consumeWriter).then(all{assert(safe and s.emitted==s.delivered and s.wlo==0 and s.rlo==32),s'=s})
 run firstRestoreTest=init.then(pause).then(installNew).then(readChunk).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(appendTail).then(finish).then(all{assert(safe and s.clobbered and s.writer==1 and s.completed==1 and s.emitted-s.delivered==23),s'=s})
 run twoRestoresTest=init.then(pause).then(installNew).then(readChunk).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(appendTail).then(finish).then(installNew).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(appendTail).then(finish).then(all{assert(safe and s.completed==2 and s.resumes==2 and s.clobbered and s.index==80),s'=s})
 run threeRestoresTest=init.then(pause).then(readChunk).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(appendTail).then(finish).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(appendTail).then(finish).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(appendTail).then(finish).then(all{assert(safe and s.completed==3 and s.emitted==133 and s.delivered==110),s'=s})
 run combinedIndependentTest=init.then(first).then(prmRemainder).then(initText).then(gloPrefix).then(second).then(pause).then(readChunk).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(appendTail).then(finish).then(all{assert(safe and s.ep==5 and s.pc==5),s'=s})
 run lostRootControlTest=init.then(pause).then(all{s'={...s,custody:false}}).then(all{assert(not(safe)),s'=s})
 run staleIndexControlTest=init.then(pause).then(readChunk).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(all{s'={...s,index:80}}).then(all{assert(not(safe)),s'=s})
 run cachedBufferControlTest=init.then(pause).then(readChunk).then(advanceReader).then(exposeWriter).then(consumeWriter).then(resume).then(publish).then(all{s'={...s,shared:true}}).then(all{assert(not(safe)),s'=s})
 run lostRebaseControlTest=init.then(pause).then(readChunk).then(advanceReader).then(all{s'={...s,wlo:32}}).then(all{assert(not(safe)),s'=s})
 run specialScalarControlTest=init.then(first).then(scalarDispatch).then(all{s'={...s,special:true}}).then(all{assert(not(safe)),s'=s})
 run wrongEpochControlTest=init.then(first).then(prmRemainder).then(initText).then(gloPrefix).then(attest).then(issue).then(all{s'={...s,epoch:s.epoch+1}}).then(all{assert(not(safe)),s'=s})
}
