// Subordinate root-enumeration contract; declared families are explicit premises, not discovered native roots.
module root_enumeration {
 type State={phase:int,pc:int,open:bool,writer:bool,unknown:bool,abi:int,recipeAbi:int,
  version:int,cutVersion:int,dynamic:bool,pin:bool,roots:Set[int],links:Set[int],published:bool,done:bool}
 pure val initial:State={phase:0,pc:0,open:true,writer:false,unknown:false,abi:1,recipeAbi:1,
  version:0,cutVersion:0,dynamic:false,pin:false,roots:Set(),links:Set(),published:false,done:false}
 var s:State
 action init=s'=initial
 pure def expected(x:State):Set[int]=if(x.dynamic) Set(0,1,2) else Set(0,1)
 val immutableCut=s.phase<1 or s.phase>3 or (not(s.open) and not(s.writer) and not(s.unknown) and s.abi==s.recipeAbi and s.version==s.cutVersion and s.pin)
 val roleSafe=not(s.roots.contains(3))
 val outputCoverage=not(s.published) or (expected(s).subseteq(s.roots) and s.links.contains(3) and s.pc==4)
 val currentCredential=not(s.published) or (not(s.unknown) and s.version==s.cutVersion and s.abi==s.recipeAbi)
 val safe=all{immutableCut,roleSafe,outputCoverage,currentCredential,s.pc>=0,s.pc<=4}
 action addDynamic=all{s.phase==0,s.open,not(s.dynamic),not(s.writer),s'={...s,dynamic:true,version:s.version+1}}
 action removeDynamic=all{s.phase==0,s.open,s.dynamic,not(s.writer),s'={...s,dynamic:false,version:s.version+1}}
 action beginWriter=all{s.phase==0,s.open,not(s.writer),s'={...s,writer:true}}
 action finishWriter=all{s.phase==0,s.writer,s'={...s,writer:false}}
 action discoverUnknown=all{s.phase==0,s'={...s,unknown:true}}
 action changeAbi=all{s.phase==0,s.open,s.abi==1,s'={...s,abi:2}}
 action rebuildStaticRecipe=all{s.phase==0,s'={...s,recipeAbi:s.abi}}
 action close=all{s.phase==0,s.open,s'={...s,open:false}}
 action begin=all{s.phase==0,not(s.open),not(s.writer),not(s.unknown),s.abi==s.recipeAbi,
  s'={...s,phase:1,pin:true,cutVersion:s.version}}
 action emitFixed=all{s.phase==1,s.pc==0,s'={...s,pc:1,roots:s.roots.union(Set(0))}}
 action emitFrame=all{s.phase==1,s.pc==1,s'={...s,pc:2,roots:s.roots.union(Set(1))}}
 action emitDynamic=all{s.phase==1,s.pc==2,s'={...s,pc:3,roots:if(s.dynamic) s.roots.union(Set(2)) else s.roots}}
 action traverseControl=all{s.phase==1,s.pc==3,s'={...s,pc:4,links:Set(3)}}
 action publish=all{s.phase==1,s.pc==4,s.version==s.cutVersion,s.abi==s.recipeAbi,
  expected(s).subseteq(s.roots),s.links.contains(3),s'={...s,phase:2,published:true}}
 action consume=all{s.phase==2,s.published,s.pin,s'={...s,phase:3,done:true}}
 action release=all{s.phase==3,s.done,s'={...s,phase:4,pin:false}}
 action failPrivate=all{s.phase==1,not(s.published),s'={...s,phase:5,pin:false,roots:Set(),links:Set()}}
 action step=any{addDynamic,removeDynamic,beginWriter,finishWriter,discoverUnknown,changeAbi,rebuildStaticRecipe,close,begin,emitFixed,emitFrame,emitDynamic,traverseControl,publish,consume,release,failPrivate,s'=s}
 action ready=close.then(begin)
 action enumerate=emitFixed.then(emitFrame).then(emitDynamic).then(traverseControl)
 // Mutations challenge this architecture; native reachability is not asserted.
 action staleDynamic=s'={...s,dynamic:true,version:s.version+1}
 action omitDynamic=s'={...s,pc:3}
 action omitControl=s'={...s,pc:4}
 action treatLinkAsRoot=s'={...s,roots:s.roots.union(Set(3))}
 action releaseDescriptor=s'={...s,pin:false}
 action publishPrefix=s'={...s,published:true,phase:2}
 action forceBegin=s'={...s,phase:1,pin:true,cutVersion:s.version}
 action forcePublish=s'={...s,phase:2,published:true}
 run staticAndDynamicTest=init.then(addDynamic).then(ready).then(enumerate).then(publish).then(consume).then(release).then(all{assert(safe),s'=s})
 run absentDynamicTest=init.then(ready).then(enumerate).then(publish).then(consume).then(release).then(all{assert(safe),assert(not(s.roots.contains(2))),s'=s})
 run recipeRebuildTest=init.then(changeAbi).then(rebuildStaticRecipe).then(ready).then(enumerate).then(publish).then(all{assert(safe),s'=s})
 run writerDrainsTest=init.then(beginWriter).then(close).then(finishWriter).then(begin).then(enumerate).then(publish).then(all{assert(safe),s'=s})
 run privateFailureTest=init.then(ready).then(emitFixed).then(failPrivate).then(all{assert(safe),assert(not(s.published)),s'=s})
 run lateDynamicNegativeTest=init.then(ready).then(enumerate).then(publish).then(staleDynamic).then(all{assert(not(safe)),s'=s})
 run dynamicOmittedNegativeTest=init.then(addDynamic).then(ready).then(emitFixed).then(emitFrame).then(omitDynamic).then(traverseControl).then(forcePublish).then(all{assert(not(safe)),s'=s})
 run linkOmittedNegativeTest=init.then(ready).then(emitFixed).then(emitFrame).then(emitDynamic).then(omitControl).then(forcePublish).then(all{assert(not(safe)),s'=s})
 run linkAsRootNegativeTest=init.then(ready).then(treatLinkAsRoot).then(all{assert(not(safe)),s'=s})
 run descriptorReleasedNegativeTest=init.then(ready).then(releaseDescriptor).then(all{assert(not(safe)),s'=s})
 run partialPublishedNegativeTest=init.then(ready).then(emitFixed).then(publishPrefix).then(all{assert(not(safe)),s'=s})
 run unknownWriterNegativeTest=init.then(discoverUnknown).then(close).then(forceBegin).then(all{assert(not(safe)),s'=s})
 run staleAbiNegativeTest=init.then(changeAbi).then(close).then(forceBegin).then(all{assert(not(safe)),s'=s})
}
