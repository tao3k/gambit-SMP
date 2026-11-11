module callback_carry_closure {
 // Internal carry state is not asserted reachable by the ordinary public reader.
 // attest* actions require external receipts; source never supplies them here.
 type State={pc:int,wlo:int,whi:int,rlo:int,rhi:int,carry:int,physical:int,bias:int,roots:int,active:int,epoch:int,sealedEpoch:int,closed:bool,mapped:bool,released:bool,permit:bool,unknown:bool}
 pure val initial:State={pc:0,wlo:0,whi:0,rlo:0,rhi:0,carry:0,physical:0,bias:0,roots:0,active:0,epoch:1,sealedEpoch:0,closed:false,mapped:false,released:false,permit:false,unknown:false}
 var s:State
 action init=s'=initial
 val safe=all{s.pc>=0,
s.pc<=6,
s.wlo>=0,
s.whi>=0,
s.rlo>=0,
s.rhi>=0,
s.roots>=0,
s.active>=0,
s.epoch>=1,
s.sealedEpoch>=0,
s.carry==0 or s.carry==4,
s.pc==1 implies (s.wlo==32 and s.whi==8 and s.rhi==32 and s.rlo==32-s.carry and s.physical==8+s.carry),
(s.pc==2 or s.pc==3 or s.pc==6) implies (s.wlo==s.carry and s.whi==8 and s.rlo==32-s.carry and s.physical==8+s.carry),
(s.pc==4 or s.pc==5) implies (s.wlo==s.carry and s.whi==8+s.carry and s.rlo==0 and s.bias==s.carry and s.physical==s.wlo+s.whi-s.rlo-s.bias),
s.released implies (s.closed and s.mapped and s.roots==0 and s.active==0),
s.closed implies (s.mapped and s.roots==0 and s.active==0),
s.permit implies (s.sealedEpoch==s.epoch and not(s.unknown))}
 action beginLegal=all{s.pc==0,not(s.released),s'={...s,pc:1,wlo:32,whi:8,rlo:32,rhi:32,carry:0,physical:8}}
 action beginInternalCarry=all{s.pc==0,not(s.released),s'={...s,pc:1,wlo:32,whi:8,rlo:28,rhi:32,carry:4,physical:12}}
 action advanceFifo=all{s.pc==1,s'={...s,pc:2,wlo:s.wlo-s.rlo}}
 action allocateCandidate=all{s.pc==2,s'={...s,pc:3}}
 action installShared=all{s.pc==3,s'={...s,pc:4,whi:s.whi+s.carry,rlo:0,rhi:0,bias:s.carry}}
 action expose=all{s.pc==4,s'={...s,pc:5,rhi:s.whi}}
 action allocationFailure=all{s.pc==2,s'={...s,pc:6}}
 action capture=all{s.pc>=1,not(s.closed),not(s.released),s'={...s,roots:s.roots+1}}
 action resume=all{s.roots>0,not(s.closed),not(s.released),s'={...s,active:s.active+1}}
 action returnActivation=all{s.active>0,s'={...s,active:s.active-1}}
 action attestRootRetirement=all{s.active==0,s'={...s,closed:true,mapped:true,roots:0}}
 action release=all{s.closed,s.mapped,s.roots==0,s.active==0,s'={...s,released:true}}
 action changeRegistration=all{not(s.closed),s'={...s,epoch:s.epoch+1,permit:false}}
 action unknownCallback=all{not(s.closed),s'={...s,unknown:true,permit:false}}
 action attestEffects=all{not(s.unknown),s'={...s,sealedEpoch:s.epoch,permit:true}}
 action step=any{beginLegal,beginInternalCarry,advanceFifo,allocateCandidate,installShared,expose,allocationFailure,capture,resume,returnActivation,attestRootRetirement,release,changeRegistration,unknownCallback,attestEffects,all{s'=s}}
 run noCarryTest=init.then(beginLegal).then(advanceFifo).then(allocateCandidate).then(installShared).then(expose).then(all{assert(s.physical==s.wlo+s.whi-s.rlo),assert(safe)})
 run carryCounterControlTest=init.then(beginInternalCarry).then(advanceFifo).then(allocateCandidate).then(installShared).then(expose).then(all{assert(s.physical==12),assert(s.wlo+s.whi-s.rlo==16),assert(safe)})
 run failedAllocationTest=init.then(beginInternalCarry).then(capture).then(advanceFifo).then(allocationFailure).then(all{assert(s.pc==6),assert(s.roots==1),assert(not(s.released)),assert(safe)})
 run multiShotTest=init.then(beginLegal).then(capture).then(resume).then(returnActivation).then(resume).then(returnActivation).then(all{assert(s.roots==1),assert(not(s.released)),assert(safe)})
 run lateRegistrationControlTest=init.then(attestEffects).then(changeRegistration).then(all{assert(not(s.permit)),assert(safe)})
 run unknownCallbackControlTest=init.then(attestEffects).then(unknownCallback).then(all{assert(not(s.permit)),assert(safe)})
 run rootReceiptTest=init.then(beginLegal).then(capture).then(resume).then(returnActivation).then(attestRootRetirement).then(release).then(all{assert(s.released),assert(safe)})
}
