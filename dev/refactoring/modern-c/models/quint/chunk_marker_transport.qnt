module chunk_marker_transport {
 // 0 legacy shared/plain; 1 shared/all-atomic; 2 immutable marker plus distinct queue node.
 type State={mode:int,reader:int,writer:int,link:int,exposed:bool,alive:bool,atomicStorage:bool,tagged:bool,gate:bool}
 pure val initial:State={mode:0,reader:0,writer:0,link:0,exposed:false,alive:true,atomicStorage:false,tagged:true,gate:false}
 var s:State
 action init=s'=initial
 val safe=s.mode>=1 implies all{
 s.mode<=2,s.reader>=0,s.reader<=2,s.writer>=0,s.writer<=2,
 s.mode==1 implies s.atomicStorage,
 (s.mode==1 and s.reader>0) implies s.reader==2,
 (s.mode==1 and s.writer>0) implies s.writer==2,
 (s.reader>0 or s.writer>0) implies (s.alive and s.exposed),
 s.writer>0 implies s.gate,s.tagged}
 action chooseAtomic=all{not(s.exposed),s.alive,s.reader==0,s.writer==0,not(s.gate),s.tagged,s'={...s,mode:1,atomicStorage:true}}
 action chooseSplit=all{not(s.exposed),s.alive,s.reader==0,s.writer==0,not(s.gate),s.tagged,s'={...s,mode:2}}
 action expose=all{s.alive,s'={...s,exposed:true}}
 action plainRead=all{s.mode!=1,s.alive,s.exposed,s.reader==0,s'={...s,reader:1}}
 action atomicRead=all{s.mode==1,s.atomicStorage,s.alive,s.exposed,s.reader==0,s'={...s,reader:2}}
 action acquireGate=all{not(s.gate),s.alive,s'={...s,gate:true}}
 action plainWrite=all{s.mode!=1,s.alive,s.exposed,s.gate,s.writer==0,s'={...s,writer:1,link:1}}
 action atomicWrite=all{s.mode==1,s.atomicStorage,s.alive,s.exposed,s.gate,s.writer==0,s'={...s,writer:2,link:1}}
 action finishRead=all{s.reader>0,s'={...s,reader:0}}
 action finishWrite=all{s.writer>0,s'={...s,writer:0}}
 action releaseGate=all{s.gate,s.writer==0,s'={...s,gate:false}}
 action retireStorage=all{s.alive,s.reader==0,s.writer==0,not(s.gate),s'={...s,alive:false}}
 action step=any{chooseAtomic,chooseSplit,expose,plainRead,atomicRead,acquireGate,plainWrite,atomicWrite,finishRead,finishWrite,releaseGate,retireStorage,all{s'=s}}
 run legacyOverlapTest=init.then(expose).then(plainRead).then(acquireGate).then(plainWrite).then(all{assert(s.reader==1 and s.writer==1 and s.gate and s.mode==0),s'=s})
 run atomicOverlapTest=init.then(chooseAtomic).then(expose).then(atomicRead).then(acquireGate).then(atomicWrite).then(finishRead).then(finishWrite).then(releaseGate).then(retireStorage).then(all{assert(safe and not(s.alive)),s'=s})
 run splitOverlapTest=init.then(chooseSplit).then(expose).then(plainRead).then(acquireGate).then(plainWrite).then(all{assert(safe and s.reader==1 and s.writer==1),s'=s})
 run classifierControlTest=init.then(chooseAtomic).then(expose).then(all{s'={...s,reader:1}}).then(all{assert(not(safe)),s'=s})
 run atomicStorageControlTest=init.then(chooseAtomic).then(all{s'={...s,atomicStorage:false}}).then(all{assert(not(safe)),s'=s})
 run earlyFreeControlTest=init.then(chooseSplit).then(expose).then(plainRead).then(all{s'={...s,alive:false}}).then(all{assert(not(safe)),s'=s})
 run markerTagControlTest=init.then(chooseSplit).then(expose).then(all{s'={...s,tagged:false}}).then(all{assert(not(safe)),s'=s})
}
