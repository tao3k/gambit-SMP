// Subordinate root-slot realization of runtime_ownership; no native pointer/weak-memory claim.
module root_store_projection {
 type State={phase:int,admission:bool,writer:bool,contextLive:bool,storageLive:bool,
  generation:int,leaseGeneration:int,aliases:int->int,values:int->int,
  selected:Set[int],scanned:Set[int],pin:int,done:bool,loaded:int->int}
 pure val aliases=Set(0,1,2)
 pure val cells=Set(0,1)
 pure val initial:State={phase:0,admission:true,writer:false,contextLive:true,storageLive:true,
  generation:1,leaseGeneration:0,aliases:Map(0->0,1->0,2->1),values:Map(0->7,1->7),
  selected:Set(),scanned:Set(),pin:0,done:false,loaded:Map(0->0,1->0,2->0)}
 var s:State
 action init=s'=initial
 val storageCustody=(s.phase>=1 and s.phase<=3) implies (s.storageLive and s.pin==1 and s.leaseGeneration==s.generation)
 val closedWriters=s.phase>=1 implies (not(s.admission) and not(s.writer))
 val canonicalCoverage=s.phase<2 or cells.subseteq(s.selected)
 val updatedActual=s.scanned.forall(c=>s.values.get(c)==107)
 val complete=s.done implies (cells.subseteq(s.scanned) and aliases.forall(a=>s.values.get(s.aliases.get(a))==107))
 val restored=s.phase!=4 or aliases.forall(a=>s.loaded.get(a)==107)
 val safe=all{storageCustody,closedWriters,canonicalCoverage,updatedActual,complete,restored,s.pin>=0,s.pin<=1}
 action beginWriter=all{s.phase==0,s.admission,not(s.writer),s'={...s,writer:true}}
 action finishWriter=all{s.writer,s'={...s,writer:false}}
 action closeAdmission=all{s.phase==0,s.admission,s'={...s,admission:false}}
 action freeze=all{s.phase==0,not(s.admission),not(s.writer),s.storageLive,
  s'={...s,phase:1,pin:1,leaseGeneration:s.generation}}
 action enumerate=all{s.phase==1,s'={...s,phase:2,selected:aliases.map(a=>s.aliases.get(a))}}
 action retireContext=all{s.phase>=1,s.contextLive,s'={...s,contextLive:false}}
 action scan(c:int):bool=all{s.phase==2,s.selected.contains(c),not(s.scanned.contains(c)),
  s'={...s,values:s.values.set(c,s.values.get(c)+100),scanned:s.scanned.union(Set(c))}}
 action finishScan=all{s.phase==2,s.selected.subseteq(s.scanned),
  s'={...s,phase:3,done:true}}
 action restore=all{s.phase==3,s.storageLive,s.pin==1,s.leaseGeneration==s.generation,
  s'={...s,phase:4,loaded:Map(0->s.values.get(s.aliases.get(0)),1->s.values.get(s.aliases.get(1)),2->s.values.get(s.aliases.get(2))),pin:0}}
 action releaseStorage=all{s.phase==4,s.pin==0,s.storageLive,s'={...s,storageLive:false}}
 action step=any{beginWriter,finishWriter,closeAdmission,freeze,enumerate,retireContext,scan(0),scan(1),finishScan,restore,releaseStorage,s'=s}
 // Alternatives rejected by this contract; not claims of native fault reachability.
 action dedupByValue=s'={...s,phase:2,selected:Set(0)}
 action scanAliasTwice=s'={...s,values:s.values.set(0,s.values.get(0)+100)}
 action freeWithLease=s'={...s,storageLive:false}
 action reuseAddress=s'={...s,generation:2}
 action lateWrite=s'={...s,values:s.values.set(0,8)}
 action freezeWithWriter=s'={...s,phase:1,admission:false,pin:1,leaseGeneration:s.generation}
 action ready=closeAdmission.then(freeze).then(enumerate)
 action both=scan(0).then(scan(1)).then(finishScan).then(restore)
 run aliasAndEqualValuesTest=init.then(ready).then(both).then(all{assert(safe),assert(s.loaded.get(0)==s.loaded.get(1)),assert(s.loaded.get(2)==107),s'=s})
 run originRetiresStorageRemainsTest=init.then(ready).then(retireContext).then(both).then(releaseStorage).then(all{assert(safe),assert(not(s.contextLive)),assert(not(s.storageLive)),s'=s})
 run writerDrainTest=init.then(beginWriter).then(closeAdmission).then(finishWriter).then(freeze).then(enumerate).then(both).then(all{assert(safe),s'=s})
 run equalValueDedupNegativeTest=init.then(closeAdmission).then(freeze).then(dedupByValue).then(all{assert(not(safe)),s'=s})
 run doubleRewriteNegativeTest=init.then(ready).then(scan(0)).then(scanAliasTwice).then(all{assert(not(safe)),s'=s})
 run earlyFreeNegativeTest=init.then(ready).then(retireContext).then(freeWithLease).then(all{assert(not(safe)),s'=s})
 run generationReuseNegativeTest=init.then(ready).then(reuseAddress).then(all{assert(not(safe)),s'=s})
 run lateWriterNegativeTest=init.then(ready).then(scan(0)).then(lateWrite).then(all{assert(not(safe)),s'=s})
 run activeWriterNegativeTest=init.then(beginWriter).then(freezeWithWriter).then(all{assert(not(safe)),s'=s})
}
