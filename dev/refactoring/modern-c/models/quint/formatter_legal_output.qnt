module formatter_legal_output {
 // Legal VAR/string-pipe source witness abstraction; byte/frontier and C23 refinement remain external.
 type State={pc:int,writer:int,savedWriter:int,generation:int,capacity:int,produced:int,consumed:int,callbacks:int,resumes:int,epoch:int,planEpoch:int,lastWriteEpoch:int,writes:int,demand:int,certGen:int,certEpoch:int,attempts:int,validVar:bool,pipe:bool,handler:bool,captured:bool,custody:bool,newer:bool,clobbered:bool,closed:bool,fault:bool,equivalent:bool,certificate:bool,alive:bool,raw:bool,locked:bool}
 pure val initial:State={pc:0,writer:1,savedWriter:1,generation:1,capacity:1,produced:0,consumed:0,callbacks:0,resumes:0,epoch:1,planEpoch:1,lastWriteEpoch:0,writes:0,demand:1,certGen:0,certEpoch:0,attempts:0,validVar:false,pipe:false,handler:false,captured:false,custody:false,newer:false,clobbered:false,closed:false,fault:false,equivalent:false,certificate:false,alive:true,raw:false,locked:false}
 var s:State
 action init=s'=initial
 val safe=all{s.pc>=0,
s.pc<=8,
s.writer>=0,
s.writer<=2,
s.savedWriter>=0,
s.savedWriter<=2,
s.generation>=1,
s.capacity==1,
s.produced>=0,
s.produced<=64,
s.consumed>=0,
s.consumed<=s.produced,
s.callbacks>=0,
s.callbacks<=1,
s.resumes>=0,
s.epoch>=1,
s.planEpoch>=1,
s.lastWriteEpoch>=0,
s.lastWriteEpoch<=s.epoch,
s.writes>=0,
s.demand>=0,
s.demand<=2,
s.certGen>=0,
s.certEpoch>=0,
s.attempts>=0,
s.captured implies s.custody,
s.pc>=2 implies s.custody,
(s.pc==3 or s.pc==5 or s.pc==6) implies s.callbacks==1,
(s.pc==4 or s.pc==7 or s.pc==8) implies s.callbacks==0,
s.locked implies s.pc==8,
s.pc==8 implies s.locked,
s.certificate implies (s.pc==7 and s.closed and not(s.captured) and s.callbacks==0 and s.alive and s.epoch==s.planEpoch and s.demand==1 and not(s.raw) and not(s.clobbered) and s.writer==s.savedWriter and s.generation==s.certGen and s.epoch==s.certEpoch and s.equivalent)}
 action prepare=all{s.pc==0,s'={...s,pc:1,validVar:true,pipe:true,handler:true}}
 action enter=all{s.pc==1,s.validVar,s.pipe,s.handler,s'={...s,pc:2,writer:0,savedWriter:s.writer,generation:s.generation+1,custody:true,planEpoch:s.epoch}}
 action fill=all{s.pc==2,s.produced==0,s'={...s,produced:64}}
 action timeout=all{s.pc==2,s.produced-s.consumed>32+s.capacity,s'={...s,pc:3,callbacks:1,fault:true}}
 action captureEscape=all{s.pc==3,s'={...s,pc:4,captured:true,callbacks:0}}
 action publish=all{s.pc==4 or s.pc==7,s'={...s,writer:2,generation:s.generation+1,newer:true,certificate:false,equivalent:false}}
 action drain=all{s.pc==4 or s.pc==7,s'={...s,consumed:s.produced}}
 action resume=all{s.pc==4 or s.pc==7,s.captured,s.consumed==s.produced,s'={...s,pc:5,callbacks:1,resumes:s.resumes+1,equivalent:false,certificate:false}}
 action returnHandler=all{s.pc==3,s'={...s,pc:5}}
 action namedTail=all{s.pc==5,s.alive,s'={...s,pc:6,writes:s.writes+1,lastWriteEpoch:s.epoch,demand:1}}
 action rawTail=all{s.pc==5,s.alive,s'={...s,pc:6,writes:s.writes+1,lastWriteEpoch:s.epoch,demand:2,raw:true}}
 action rejectDead=all{s.pc==5,not(s.alive),s'={...s,pc:4,callbacks:0,captured:true,equivalent:false,certificate:false}}
 action resetRegistry=all{s.pc==4 or s.pc==7,s'={...s,epoch:s.epoch+1,demand:0,alive:true,certificate:false,equivalent:false}}
 action endRegistry=all{s.pc==4 or s.pc==7,s'={...s,alive:false,certificate:false,equivalent:false}}
 action callbackReturns=all{s.pc==6,s'={...s,pc:8,callbacks:0,locked:true}}
 action finish=all{s.pc==8,s'={...s,pc:7,writer:s.savedWriter,generation:s.generation+1,locked:false,clobbered:s.clobbered or (s.newer and s.writer==2)}}
 action closeAdmission=all{s.pc==4 or s.pc==7,s'={...s,closed:true}}
 action detach=all{s.pc==7,s.captured,s'={...s,captured:false}}
 action attest=all{s.pc==7,s.closed,not(s.captured),s.callbacks==0,s.alive,s.epoch==s.planEpoch,s.demand==1,not(s.raw),not(s.clobbered),s.writer==s.savedWriter,s'={...s,equivalent:true}}
 action issue=all{s.pc==7,s.closed,not(s.captured),s.callbacks==0,s.alive,s.epoch==s.planEpoch,s.demand==1,not(s.raw),not(s.clobbered),s.writer==s.savedWriter,s.equivalent,s'={...s,certificate:true,certGen:s.generation,certEpoch:s.epoch}}
 action attemptStale=all{s.pc==4 or s.pc==7,s.captured,s'={...s,attempts:s.attempts+1}}
 action step=any{prepare,enter,fill,timeout,captureEscape,publish,drain,resume,returnHandler,namedTail,rawTail,rejectDead,resetRegistry,endRegistry,callbackReturns,finish,closeAdmission,detach,attest,issue,attemptStale,all{s'=s}}
 run sourceEscapeTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(all{assert(safe and s.writer==0 and s.captured and not(s.locked)),s'=s})
 run overwriteTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(publish).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(all{assert(safe and s.clobbered and s.writer==1 and s.writes==1),s'=s})
 run multiShotTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(publish).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(publish).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(all{assert(safe and s.clobbered and s.resumes==2 and s.writes==2 and s.captured),s'=s})
 run sameEntryTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(all{assert(safe and s.lastWriteEpoch==s.planEpoch and s.demand==1),s'=s})
 run differentEntryTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(resetRegistry).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(all{assert(safe and s.lastWriteEpoch!=s.planEpoch and s.demand==1),s'=s})
 run deadRegistryTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(endRegistry).then(drain).then(resume).then(rejectDead).then(all{assert(safe and s.captured and s.custody and not(s.certificate)),s'=s})
 run rawWriterTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(drain).then(resume).then(rawTail).then(callbackReturns).then(finish).then(all{assert(safe and s.raw and s.demand==2),s'=s})
 run qualifiedReturnTest=init.then(prepare).then(enter).then(fill).then(timeout).then(returnHandler).then(namedTail).then(callbackReturns).then(finish).then(closeAdmission).then(attest).then(issue).then(all{assert(safe and s.certificate and s.fault),s'=s})
 run retainedCaptureTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(closeAdmission).then(attemptStale).then(attemptStale).then(all{assert(safe and s.captured and s.attempts==2 and not(s.certificate)),s'=s})
 run qualifiedDetachTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(closeAdmission).then(detach).then(attest).then(issue).then(all{assert(safe and s.certificate),s'=s})
 run newRegistrationRevokesTest=init.then(prepare).then(enter).then(fill).then(timeout).then(returnHandler).then(namedTail).then(callbackReturns).then(finish).then(closeAdmission).then(attest).then(issue).then(publish).then(all{assert(safe and not(s.certificate)),s'=s})
 run captureForgedControlTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(closeAdmission).then(all{s'={...s,equivalent:true,certificate:true,certGen:s.generation,certEpoch:s.epoch}}).then(all{assert(not(safe)),s'=s})
 run epochForgedControlTest=init.then(prepare).then(enter).then(fill).then(timeout).then(returnHandler).then(namedTail).then(callbackReturns).then(finish).then(resetRegistry).then(closeAdmission).then(all{s'={...s,equivalent:true,demand:1,certificate:true,certGen:s.generation,certEpoch:s.epoch}}).then(all{assert(not(safe)),s'=s})
 run clobberForgedControlTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(publish).then(drain).then(resume).then(namedTail).then(callbackReturns).then(finish).then(closeAdmission).then(detach).then(all{s'={...s,equivalent:true,certificate:true,certGen:s.generation,certEpoch:s.epoch}}).then(all{assert(not(safe)),s'=s})
 run lostRootControlTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(all{s'={...s,custody:false}}).then(all{assert(not(safe)),s'=s})
 run lockLeakControlTest=init.then(prepare).then(enter).then(fill).then(timeout).then(captureEscape).then(all{s'={...s,locked:true}}).then(all{assert(not(safe)),s'=s})
}
