module native_prefix_permission {
// Profiles represent certified effect summaries, not detected properties of a loaded binary.
type State={phase:int,profile:int,identity:int,bindingEpoch:int,sealEpoch:int,fast:int,durable:int,sourceRoot:int,carrierRoot:int,intent:int,allocation:int,recorded:int,hook:int,unknown:int,custodian:int,epoch:int,rootEpoch:int,localEpoch:int,gate:int}
pure val initial:State={phase:0,profile:0,identity:1,bindingEpoch:0,sealEpoch:0,fast:0,durable:0,sourceRoot:0,carrierRoot:0,intent:0,allocation:0,recorded:0,hook:0,unknown:0,custodian:0,epoch:0,rootEpoch:0,localEpoch:0,gate:1}
var s:State
action init=s'=initial
val safe=all{s.phase>=0,s.phase<=9,s.profile>=0,s.profile<=6,s.custodian>=0,s.custodian<=3,s.epoch>=0,s.rootEpoch>=0,s.rootEpoch<=s.epoch,s.localEpoch>=0,s.localEpoch<=s.epoch,s.identity>=0,s.identity<=1,s.bindingEpoch>=0,s.bindingEpoch<=1,s.sealEpoch>=0,s.sealEpoch<=1,s.fast>=0,s.fast<=1,s.durable>=0,s.durable<=1,s.sourceRoot>=0,s.sourceRoot<=1,s.carrierRoot>=0,s.carrierRoot<=1,s.intent>=0,s.intent<=1,s.allocation>=0,s.allocation<=1,s.recorded>=0,s.recorded<=1,s.hook>=0,s.hook<=1,s.unknown>=0,s.unknown<=1,s.gate>=0,s.gate<=1,s.phase<=1 implies all{s.fast==0,s.durable==0,s.sourceRoot==0,s.carrierRoot==0,s.intent==0,s.allocation==0,s.recorded==0,s.hook==0,s.unknown==0,s.custodian==0,s.epoch==0,s.rootEpoch==0,s.localEpoch==0},s.fast==1 implies all{s.profile==0,s.phase>=2,s.phase<=5,s.identity==1,s.intent==1,s.hook==0,s.sourceRoot==0,s.carrierRoot==0,s.localEpoch==s.epoch,s.custodian==1},s.durable==1 implies all{s.profile>=1,s.profile<=3,s.phase>=2,s.phase<=8,s.sourceRoot==1,s.intent==1},s.phase>=2 and s.phase<=6 implies all{s.intent==1,s.identity==1,s.bindingEpoch==s.sealEpoch,s.custodian==1},s.phase>=2 and s.phase<=5 implies s.fast+s.durable==1,s.phase>=4 and s.phase<=6 implies s.allocation==1,s.phase>=5 and s.phase<=6 implies s.recorded==1,s.phase==6 implies all{s.carrierRoot==1,s.fast==0,s.durable==0,s.hook==0,s.unknown==0},s.unknown==1 implies all{s.phase==8,s.intent==1,s.sourceRoot+s.carrierRoot>=1,s.custodian==2,s.hook==0},s.phase==8 implies all{s.unknown==1,s.profile>=0,s.profile<=3,s.identity==1,s.bindingEpoch==s.sealEpoch},s.sourceRoot+s.carrierRoot>=1 implies s.rootEpoch==s.epoch,s.recorded<=s.allocation,s.hook==1 implies all{s.profile>=2,s.profile<=3,s.durable==1,s.phase>=3,s.phase<=4},s.carrierRoot==1 implies all{s.profile<=3,s.fast==0,s.durable==0,s.recorded==1,s.allocation==1,s.identity==1},s.phase==7 implies all{s.fast==0,s.durable==0,s.hook==0,s.unknown==0,s.intent==0,s.sourceRoot==0},s.phase==9 implies all{s.fast==0,s.durable==0,s.sourceRoot==0,s.carrierRoot==0,s.intent==0,s.allocation==0,s.recorded==0,s.hook==0,s.unknown==0,s.custodian==0},s.phase==2 implies all{s.allocation==0,s.recorded==0,s.hook==0},s.phase==3 implies all{s.allocation==0,s.recorded==0},s.phase==4 implies s.recorded==0}
action selectPlain=all{s.phase==0,s'={...s,phase:1,profile:0,identity:1}}
action selectCollecting=all{s.phase==0,s'={...s,phase:1,profile:1,identity:1}}
action selectReentrant=all{s.phase==0,s'={...s,phase:1,profile:2,identity:1}}
action selectAbandoning=all{s.phase==0,s'={...s,phase:1,profile:3,identity:1}}
action selectOpaque=all{s.phase==0,s'={...s,phase:1,profile:4,identity:1}}
action selectWrongSelf=all{s.phase==0,s'={...s,phase:1,profile:5,identity:0}}
action selectDebugIO=all{s.phase==0,s'={...s,phase:1,profile:6,identity:1}}
action replaceBeforeGrant=all{s.phase==1 and s.bindingEpoch==0,s'={...s,bindingEpoch:1}}
action grantFast=all{s.phase==1 and s.profile==0 and s.identity==1 and s.bindingEpoch==s.sealEpoch and s.gate==1,s'={...s,phase:2,fast:1,intent:1,custodian:1,localEpoch:s.epoch}}
action grantDurable=all{s.phase==1 and s.profile>=1 and s.profile<=3 and s.identity==1 and s.bindingEpoch==s.sealEpoch and s.gate==1,s'={...s,phase:2,durable:1,sourceRoot:1,intent:1,custodian:1,rootEpoch:s.epoch,localEpoch:s.epoch}}
action denyProfile=all{s.phase==1 and (s.profile>=4 or s.bindingEpoch!=s.sealEpoch or s.gate==0),s'={...s,phase:9}}
action closeAdmission=all{s.gate==1,s'={...s,gate:0}}
action beginAllocation=all{s.phase==2 and s.intent==1,s'={...s,phase:3}}
action obtainNativeMemory=all{s.phase==3 and s.allocation==0,s'={...s,phase:4,allocation:1}}
action enterHook=all{(s.phase==3 or s.phase==4) and s.profile>=2 and s.profile<=3 and s.durable==1 and s.hook==0,s'={...s,hook:1}}
action returnHook=all{(s.phase==3 or s.phase==4) and s.hook==1,s'={...s,hook:0}}
action gcRound=all{s.phase>=2 and s.phase<=8 and s.phase!=7 and s.sourceRoot+s.carrierRoot>=1,s'={...s,epoch:s.epoch+1,rootEpoch:s.epoch+1}}
action reloadRoot=all{s.phase>=2 and s.phase<=6 and s.sourceRoot+s.carrierRoot>=1 and s.hook==0,s'={...s,localEpoch:s.rootEpoch}}
action captureOutcome=all{s.phase==4 and s.hook==0,s'={...s,phase:5,recorded:1}}
action publishInputs=all{s.phase==5 and s.recorded==1 and s.hook==0 and s.localEpoch==s.epoch and s.identity==1,s'={...s,phase:6,carrierRoot:1,rootEpoch:s.epoch,fast:0,durable:0}}
action abandonBeforeRecord=all{(s.phase==3 or s.phase==4) and s.profile==3 and s.durable==1,s'={...s,phase:8,unknown:1,custodian:2,hook:0}}
action loseRecordedResponse=all{(s.phase==5 and s.sourceRoot==1) or s.phase==6,s'={...s,phase:8,unknown:1,custodian:2,fast:0,durable:0}}
action recoverPrivateRecord=all{s.phase==8 and s.profile>=1 and s.profile<=3 and s.recorded==1 and s.carrierRoot==0 and s.sourceRoot==1,s'={...s,phase:5,unknown:0,custodian:1,durable:1,localEpoch:s.rootEpoch}}
action recoverPublishedRecord=all{s.phase==8 and s.recorded==1 and s.carrierRoot==1,s'={...s,phase:6,unknown:0,custodian:1,localEpoch:s.rootEpoch}}
action releaseSource=all{s.phase==6 and s.carrierRoot==1 and s.localEpoch==s.epoch,s'={...s,sourceRoot:0}}
action handoffBank=all{s.phase==6 and s.carrierRoot==1 and s.recorded==1 and s.rootEpoch==s.epoch,s'={...s,phase:7,custodian:3,intent:0,sourceRoot:0}}
action rollbackPlain=all{s.phase==5 and s.profile==0 and s.fast==1 and s.hook==0,s'={...s,phase:7,allocation:0,recorded:0,intent:0,fast:0,custodian:0}}
action step=any{selectPlain,selectCollecting,selectReentrant,selectAbandoning,selectOpaque,selectWrongSelf,selectDebugIO,replaceBeforeGrant,grantFast,grantDurable,denyProfile,closeAdmission,beginAllocation,obtainNativeMemory,enterHook,returnHook,gcRound,reloadRoot,captureOutcome,publishInputs,abandonBeforeRecord,loseRecordedResponse,recoverPrivateRecord,recoverPublishedRecord,releaseSource,handoffBank,rollbackPlain,all{s'=s}}
run plainTest=init.then(selectPlain).then(grantFast).then(beginAllocation).then(obtainNativeMemory).then(captureOutcome).then(publishInputs).then(handoffBank).then(all{assert(s.phase==7 and s.sourceRoot==0),assert(safe),s'=s})
run collectingTest=init.then(selectCollecting).then(grantDurable).then(beginAllocation).then(gcRound).then(obtainNativeMemory).then(captureOutcome).then(reloadRoot).then(publishInputs).then(handoffBank).then(all{assert(s.phase==7),assert(safe),s'=s})
run reentrantTest=init.then(selectReentrant).then(grantDurable).then(beginAllocation).then(obtainNativeMemory).then(enterHook).then(gcRound).then(returnHook).then(captureOutcome).then(reloadRoot).then(publishInputs).then(all{assert(s.phase==6),assert(safe),s'=s})
run lostBeforeCaptureTest=init.then(selectAbandoning).then(grantDurable).then(beginAllocation).then(obtainNativeMemory).then(enterHook).then(abandonBeforeRecord).then(gcRound).then(all{assert(s.phase==8 and s.recorded==0 and s.intent==1),assert(safe),s'=s})
run lostPublishedTest=init.then(selectCollecting).then(grantDurable).then(beginAllocation).then(obtainNativeMemory).then(captureOutcome).then(publishInputs).then(loseRecordedResponse).then(gcRound).then(recoverPublishedRecord).then(handoffBank).then(all{assert(s.phase==7),assert(safe),s'=s})
run wrongSelfTest=init.then(selectWrongSelf).then(denyProfile).then(all{assert(s.phase==9),assert(safe),s'=s})
run revokedBindingTest=init.then(selectPlain).then(replaceBeforeGrant).then(denyProfile).then(all{assert(s.phase==9),assert(safe),s'=s})
run acceptedBeforeCloseTest=init.then(selectPlain).then(grantFast).then(closeAdmission).then(beginAllocation).then(obtainNativeMemory).then(captureOutcome).then(publishInputs).then(handoffBank).then(all{assert(s.phase==7),assert(safe),s'=s})
run opaqueTest=init.then(selectOpaque).then(denyProfile).then(all{assert(s.phase==9),assert(safe),s'=s})
}
