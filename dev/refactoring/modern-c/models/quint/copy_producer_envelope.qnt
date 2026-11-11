module copy_producer_envelope {
 // Representative static constructor max=300, RETI stored=28 => effective=37 at five registers.
 // sourceWitness is an external proof premise, not a model-derived native source partition.
 type State={epoch:int,seenEpoch:int,objectMax:int,frameFs:int,cap:int,q:int,u:int,align:int,threshold:int,budget:int,spent:int,phase:int,denied:int,objects:bool,frames:bool,abi:bool,oldPinned:bool,sourceWitness:bool,source:bool,frozen:bool,sealed:bool,started:bool,alternative:bool,retained:bool}
 pure val initial:State={epoch:1,seenEpoch:0,objectMax:300,frameFs:37,cap:0,q:510,u:0,align:0,threshold:0,budget:0,spent:0,phase:0,denied:0,objects:false,frames:false,abi:true,oldPinned:true,sourceWitness:true,source:false,frozen:false,sealed:false,started:false,alternative:false,retained:false}
 var s:State
 action init=s'=initial
 val safe=all{not(s.started) implies s.spent==0,s.epoch>=1,
 s.epoch<=2,
 s.objectMax==300,
 s.frameFs==37,
 s.q==510,
 s.cap>=0,
 s.spent>=0,
 s.spent<=s.u,
 s.denied>=0,
 s.phase>=0,
 s.phase<=1,
 s.u>=0,
 s.align>=0,
 s.align<=s.q,
 s.u<=s.q+s.align,
 s.threshold>=0,
 s.budget>=s.u+s.threshold,
 s.seenEpoch>=0,
 s.seenEpoch<=s.epoch,
 s.frozen implies (s.objects and s.frames and s.sourceWitness),
 s.source implies s.frozen,
 s.alternative implies (s.retained and not(s.sealed) and not(s.started)),
 s.sealed implies (s.objects and s.frames and s.abi and s.oldPinned and s.source and s.frozen and s.sourceWitness and not(s.alternative) and s.seenEpoch==s.epoch and s.cap>=s.objectMax and s.cap>=s.frameFs+2),
 s.started implies s.sealed,
 s.phase==1 implies s.started}
 action coverObjects=all{not(s.frozen),not(s.alternative),s'={...s,objects:true}}
 action coverFrames=all{not(s.frozen),not(s.alternative),s'={...s,frames:true}}
 action chooseCap=all{not(s.frozen),not(s.alternative),s'={...s,cap:300}}
 action abiMismatch=all{not(s.frozen),not(s.alternative),s'={...s,abi:false,alternative:true,retained:true}}
 action opaqueProducer=all{not(s.frozen),not(s.alternative),s'={...s,objects:false,alternative:true,retained:true}}
 action missingOldModule=all{not(s.started),not(s.alternative),s'={...s,oldPinned:false,sealed:false,alternative:true,retained:true}}
 action missingSourceWitness=all{not(s.frozen),not(s.alternative),s'={...s,sourceWitness:false,alternative:true,retained:true}}
 action freeze64=all{not(s.frozen),not(s.alternative),s.objects,s.frames,s.sourceWitness,s'={...s,frozen:true,source:true,seenEpoch:s.epoch,u:510,align:0,threshold:2,budget:512}}
 action freeze32=all{not(s.frozen),not(s.alternative),s.objects,s.frames,s.sourceWitness,s'={...s,frozen:true,source:true,seenEpoch:s.epoch,u:1020,align:510,threshold:4,budget:1024}}
 action issue=all{s.frozen,s.objects,s.frames,s.abi,s.oldPinned,s.source,s.sourceWitness,not(s.alternative),not(s.sealed),s.seenEpoch==s.epoch,s.cap>=s.objectMax,s.cap>=s.frameFs+2,s.budget>=s.u+s.threshold,s'={...s,sealed:true}}
 action start=all{s.sealed,not(s.started),not(s.alternative),s'={...s,started:true}}
 action consume=all{s.started,s.spent+1<=s.u,s'={...s,spent:s.spent+1}}
 action weakCut=all{s.started,s.phase==0,s'={...s,phase:1}}
 action deferLateModule=all{s.started,s'={...s,denied:s.denied+1}}
 action replaceBeforeStart=all{not(s.started),not(s.alternative),s'={...s,epoch:2,sealed:false,alternative:true,retained:true}}
 action step=any{coverObjects,coverFrames,chooseCap,abiMismatch,opaqueProducer,missingOldModule,missingSourceWitness,freeze64,freeze32,issue,start,consume,weakCut,deferLateModule,replaceBeforeStart,all{s'=s}}
 run complete64Test=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(start).then(consume).then(weakCut).then(consume).then(all{assert(safe and s.sealed and s.budget==512 and s.spent==2),s'=s})
 run complete32Test=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze32).then(issue).then(start).then(all{assert(safe and s.sealed and s.budget==1024),s'=s})
 run abiAlternativeTest=init.then(coverObjects).then(abiMismatch).then(all{assert(safe and s.alternative and not(s.sealed)),s'=s})
 run opaqueAlternativeTest=init.then(coverFrames).then(opaqueProducer).then(all{assert(safe and s.alternative and not(s.objects)),s'=s})
 run oldModuleAlternativeTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(missingOldModule).then(all{assert(safe and s.alternative and s.retained and not(s.sealed)),s'=s})
 run sourceAlternativeTest=init.then(coverObjects).then(missingSourceWitness).then(all{assert(safe and s.alternative and not(s.sourceWitness)),s'=s})
 run revokedBeforeStartTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(replaceBeforeStart).then(all{assert(safe and s.epoch==2 and s.seenEpoch==1 and not(s.sealed)),s'=s})
 run lateModuleDeferredTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(start).then(deferLateModule).then(all{assert(safe and s.epoch==1 and s.denied==1),s'=s})
 run smallFamilyOnlyControlTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(all{s'={...s,cap:255}}).then(all{assert(not(safe)),s'=s})
 run missingOldControlTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(all{s'={...s,oldPinned:false}}).then(all{assert(not(safe)),s'=s})
 run staleEpochControlTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(all{s'={...s,epoch:2}}).then(all{assert(not(safe)),s'=s})
 run weakRefundControlTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze64).then(issue).then(start).then(consume).then(weakCut).then(all{s'={...s,u:0}}).then(all{assert(not(safe)),s'=s})
 run wrongBudgetControlTest=init.then(coverObjects).then(coverFrames).then(chooseCap).then(freeze32).then(issue).then(all{s'={...s,budget:512}}).then(all{assert(not(safe)),s'=s})
}
