module source_pin_handoff {
 // Two fixed PinIds; real issuer, storage lifetime and C23 refinement remain premises.
 type State={gate:int,alive:int,sourceRoot:int,epoch:int,gc:int,pin0:int,pin1:int,accepted0:int,accepted1:int,carrier0:int,carrier1:int,value0:int,value1:int,guard0:int,guard1:int,ack0:int,ack1:int,dups:int,rejected:int}
 pure val initial:State={gate:1,alive:1,sourceRoot:1,epoch:0,gc:0,pin0:0,pin1:0,accepted0:0,accepted1:0,carrier0:0,carrier1:0,value0:0,value1:0,guard0:0,guard1:0,ack0:0,ack1:0,dups:0,rejected:0}
 var s:State
 action init=s'=initial
 val safe=all{s.gate>=0,
s.gate<=1,
s.alive>=0,
s.alive<=1,
s.sourceRoot>=0,
s.sourceRoot<=1,
s.gc>=0,
s.gc<=1,
s.pin0>=0,
s.pin0<=1,
s.pin1>=0,
s.pin1<=1,
s.accepted0>=0,
s.accepted0<=1,
s.accepted1>=0,
s.accepted1<=1,
s.carrier0>=0,
s.carrier0<=2,
s.carrier1>=0,
s.carrier1<=2,
s.guard0>=0,
s.guard0<=4,
s.guard1>=0,
s.guard1<=4,
s.ack0>=0,
s.ack0<=1,
s.ack1>=0,
s.ack1<=1,
s.epoch>=0,
s.value0>=0,
s.value1>=0,
s.dups>=0,
s.rejected>=0,
s.sourceRoot==s.alive,
s.alive==0 implies (s.gate==0 and s.pin0==0 and s.pin1==0),
s.gc==1 implies (s.sourceRoot==1 or s.carrier0==2 or s.carrier1==2),
s.pin0==1 implies (s.alive==1 and s.sourceRoot==1 and s.accepted0==1),
s.carrier0==1 implies (s.pin0==1 and s.guard0==0),
s.carrier0==2 implies s.value0==s.epoch,
s.guard0>0 implies s.accepted0==1,
(s.guard0==1 or s.guard0==2 or s.guard0==3) implies s.carrier0==2,
s.ack0==1 implies (s.guard0==2 or s.guard0==4),
s.carrier0>0 implies s.accepted0==1,
s.guard0==0 implies s.ack0==0,
s.guard0==3 implies s.pin0==1,
s.pin1==1 implies (s.alive==1 and s.sourceRoot==1 and s.accepted1==1),
s.carrier1==1 implies (s.pin1==1 and s.guard1==0),
s.carrier1==2 implies s.value1==s.epoch,
s.guard1>0 implies s.accepted1==1,
(s.guard1==1 or s.guard1==2 or s.guard1==3) implies s.carrier1==2,
s.ack1==1 implies (s.guard1==2 or s.guard1==4),
s.carrier1>0 implies s.accepted1==1,
s.guard1==0 implies s.ack1==0,
s.guard1==3 implies s.pin1==1,
(s.guard0==1 or s.guard0==3) implies s.pin0==1,
(s.guard1==1 or s.guard1==3) implies s.pin1==1,
(s.carrier0>0 and s.guard0==0) implies s.pin0==1,
(s.carrier1>0 and s.guard1==0) implies s.pin1==1}
 action pinOuter=all{(s.gate==1),(s.alive==1),(s.accepted0==0),(s.gc==0),s'={...s,pin0:1,accepted0:1}}
 action pinNested=all{(s.gate==1),(s.alive==1),(s.accepted1==0),(s.guard0==2),(s.gc==0),s'={...s,pin1:1,accepted1:1}}
 action closeSource=all{(s.gate==1),s'={...s,gate:0}}
 action rejectLatePin=all{(s.gate==0),s'={...s,rejected:s.rejected+1}}
 action copy0=all{(s.guard0==0),(s.pin0==1),(s.carrier0==0),(s.gc==0),s'={...s,carrier0:1,value0:s.epoch}}
 action refresh0=all{(s.pin0==1),(s.carrier0==1),(s.gc==0),s'={...s,value0:s.epoch}}
 action enroll0=all{(s.pin0==1),(s.carrier0==1),(s.value0==s.epoch),(s.gc==0),s'={...s,carrier0:2}}
 action reserveGuard0=all{(s.carrier0==2),(s.guard0==0),(s.gc==0),s'={...s,guard0:1}}
 action commitGuard0=all{(s.guard0==1),s'={...s,guard0:2}}
 action lostReservation0=all{(s.guard0==1),s'={...s,guard0:3}}
 action resolveCommitted0=all{(s.guard0==3),s'={...s,guard0:2}}
 action resolveFailed0=all{(s.guard0==3),s'={...s,guard0:4}}
 action queryAck0=all{(s.guard0==2 or s.guard0==4),s'={...s,ack0:1}}
 action returnPin0=all{(s.pin0==1),(s.carrier0==2),(s.ack0==1),(s.guard0==2 or s.guard0==4),s'={...s,pin0:0}}
 action repeatReturn0=all{(s.pin0==0),(s.accepted0==1),s'={...s,dups:s.dups+1}}
 action abortBeforeGuard0=all{(s.pin0==1),(s.guard0==0),(s.gc==0),s'={...s,pin0:0,carrier0:0}}
 action outerExit0=all{(s.guard0==2),s'={...s,guard0:4}}
 action retireCarrier0=all{(s.pin0==0),(s.guard0==4),(s.ack0==1),(s.gc==0),s'={...s,carrier0:0}}
 action copy1=all{(s.guard1==0),(s.pin1==1),(s.carrier1==0),(s.gc==0),s'={...s,carrier1:1,value1:s.epoch}}
 action refresh1=all{(s.pin1==1),(s.carrier1==1),(s.gc==0),s'={...s,value1:s.epoch}}
 action enroll1=all{(s.pin1==1),(s.carrier1==1),(s.value1==s.epoch),(s.gc==0),s'={...s,carrier1:2}}
 action reserveGuard1=all{(s.carrier1==2),(s.guard1==0),(s.gc==0),s'={...s,guard1:1}}
 action commitGuard1=all{(s.guard1==1),s'={...s,guard1:2}}
 action lostReservation1=all{(s.guard1==1),s'={...s,guard1:3}}
 action resolveCommitted1=all{(s.guard1==3),s'={...s,guard1:2}}
 action resolveFailed1=all{(s.guard1==3),s'={...s,guard1:4}}
 action queryAck1=all{(s.guard1==2 or s.guard1==4),s'={...s,ack1:1}}
 action returnPin1=all{(s.pin1==1),(s.carrier1==2),(s.ack1==1),(s.guard1==2 or s.guard1==4),s'={...s,pin1:0}}
 action repeatReturn1=all{(s.pin1==0),(s.accepted1==1),s'={...s,dups:s.dups+1}}
 action abortBeforeGuard1=all{(s.pin1==1),(s.guard1==0),(s.gc==0),s'={...s,pin1:0,carrier1:0}}
 action outerExit1=all{(s.guard1==2),s'={...s,guard1:4}}
 action retireCarrier1=all{(s.pin1==0),(s.guard1==4),(s.ack1==1),(s.gc==0),s'={...s,carrier1:0}}
 action retireSource=all{(s.gate==0),(s.alive==1),(s.pin0==0),(s.pin1==0),(s.gc==0),s'={...s,alive:0,sourceRoot:0}}
 action freezeGc=all{(s.gc==0),(s.sourceRoot==1 or s.carrier0==2 or s.carrier1==2),s'={...s,gc:1}}
 action finishGcNone=all{(s.gc==1),(s.carrier0!=2),(s.carrier1!=2),s'={...s,gc:0,epoch:s.epoch+1}}
 action finishGcOuter=all{(s.gc==1),(s.carrier0==2),(s.carrier1!=2),s'={...s,gc:0,epoch:s.epoch+1,value0:s.value0+1}}
 action finishGcNested=all{(s.gc==1),(s.carrier0!=2),(s.carrier1==2),s'={...s,gc:0,epoch:s.epoch+1,value1:s.value1+1}}
 action finishGcBoth=all{(s.gc==1),(s.carrier0==2),(s.carrier1==2),s'={...s,gc:0,epoch:s.epoch+1,value0:s.value0+1,value1:s.value1+1}}
 action step=any{pinOuter,pinNested,closeSource,rejectLatePin,copy0,refresh0,enroll0,reserveGuard0,commitGuard0,lostReservation0,resolveCommitted0,resolveFailed0,queryAck0,returnPin0,repeatReturn0,abortBeforeGuard0,outerExit0,retireCarrier0,copy1,refresh1,enroll1,reserveGuard1,commitGuard1,lostReservation1,resolveCommitted1,resolveFailed1,queryAck1,returnPin1,repeatReturn1,abortBeforeGuard1,outerExit1,retireCarrier1,retireSource,freezeGc,finishGcNone,finishGcOuter,finishGcNested,finishGcBoth,all{s'=s}}
 run normalTest=init.then(pinOuter).then(copy0).then(enroll0).then(reserveGuard0).then(commitGuard0).then(queryAck0).then(returnPin0).then(closeSource).then(retireSource).then(freezeGc).then(finishGcOuter).then(all{assert(s.alive==0 and s.carrier0==2 and s.value0==s.epoch and safe),s'=s})
 run privateGcRefreshTest=init.then(pinOuter).then(copy0).then(freezeGc).then(finishGcNone).then(refresh0).then(enroll0).then(all{assert(s.value0==s.epoch and s.carrier0==2 and safe),s'=s})
 run stalePrivateControlTest=init.then(pinOuter).then(copy0).then(freezeGc).then(finishGcNone).then(all{assert(s.carrier0==1 and s.value0<s.epoch and safe),s'=s})
 run deleteWaitsTest=init.then(pinOuter).then(closeSource).then(copy0).then(enroll0).then(reserveGuard0).then(commitGuard0).then(all{assert(s.alive==1 and s.pin0==1 and s.gate==0 and safe),s'=s})
 run latePinTest=init.then(closeSource).then(rejectLatePin).then(retireSource).then(rejectLatePin).then(all{assert(s.accepted0==0 and s.alive==0 and s.rejected==2 and safe),s'=s})
 run nestedTest=init.then(pinOuter).then(copy0).then(enroll0).then(reserveGuard0).then(commitGuard0).then(queryAck0).then(pinNested).then(copy1).then(enroll1).then(reserveGuard1).then(commitGuard1).then(queryAck1).then(closeSource).then(returnPin0).then(freezeGc).then(finishGcBoth).then(all{assert(s.pin1==1 and s.alive==1 and s.carrier0==2 and s.carrier1==2 and safe),s'=s})
 run bothHandoffTest=init.then(pinOuter).then(copy0).then(enroll0).then(reserveGuard0).then(commitGuard0).then(queryAck0).then(pinNested).then(copy1).then(enroll1).then(reserveGuard1).then(commitGuard1).then(queryAck1).then(closeSource).then(returnPin0).then(returnPin1).then(retireSource).then(freezeGc).then(finishGcBoth).then(all{assert(s.alive==0 and s.carrier0==2 and s.carrier1==2 and safe),s'=s})
 run unknownTest=init.then(pinOuter).then(copy0).then(enroll0).then(reserveGuard0).then(lostReservation0).then(closeSource).then(freezeGc).then(finishGcOuter).then(all{assert(s.guard0==3 and s.pin0==1 and s.carrier0==2 and s.alive==1 and safe),s'=s})
 run failedResolutionTest=init.then(pinOuter).then(copy0).then(enroll0).then(reserveGuard0).then(lostReservation0).then(closeSource).then(resolveFailed0).then(queryAck0).then(returnPin0).then(retireSource).then(retireCarrier0).then(all{assert(s.alive==0 and s.carrier0==0 and safe),s'=s})
 run preGuardAbortTest=init.then(pinOuter).then(copy0).then(closeSource).then(abortBeforeGuard0).then(retireSource).then(all{assert(s.alive==0 and s.guard0==0 and safe),s'=s})
 run duplicatePinReturnTest=init.then(pinOuter).then(copy0).then(enroll0).then(reserveGuard0).then(commitGuard0).then(queryAck0).then(returnPin0).then(repeatReturn0).then(repeatReturn0).then(all{assert(s.pin0==0 and s.dups==2 and safe),s'=s})
 run exitDrainTest=init.then(pinOuter).then(copy0).then(enroll0).then(reserveGuard0).then(commitGuard0).then(queryAck0).then(pinNested).then(copy1).then(enroll1).then(reserveGuard1).then(commitGuard1).then(queryAck1).then(returnPin1).then(outerExit1).then(retireCarrier1).then(returnPin0).then(outerExit0).then(retireCarrier0).then(closeSource).then(retireSource).then(all{assert(s.alive==0 and s.carrier0==0 and s.carrier1==0 and safe),s'=s})
}
