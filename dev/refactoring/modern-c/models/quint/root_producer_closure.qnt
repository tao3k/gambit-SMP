module root_producer_closure {
 // Two distinct slots may contain the same object. The third descriptor aliases slot 0.
 pure val descriptorSlots=List(0,1,0)
 pure val slotValues=List(7,7)
 pure val canonicalSlots=descriptorSlots.foldl(Set(), (acc, slot) => acc.union(Set(slot)))
 type State={r0:bool,r1:bool,producer:bool,copying:bool,initialized:bool,tail:bool,privateChunk:bool,queued:bool,claimed:bool,scanned:bool,consumer:bool,closed:bool,terminated:bool}
 pure val initial:State={r0:false,r1:false,producer:true,copying:false,initialized:false,tail:false,privateChunk:false,queued:false,claimed:false,scanned:false,consumer:true,closed:false,terminated:false}
 var s:State
 action init=s'=initial
 val safe=all{
  (s.copying or s.tail or s.privateChunk) implies s.producer,
  (s.queued or s.claimed or s.scanned) implies s.initialized,
  s.claimed implies s.consumer,
  not(s.queued and s.claimed),
  s.terminated implies all{s.closed,s.r0,s.r1,not(s.producer),not(s.consumer),not(s.copying),not(s.tail),not(s.privateChunk),not(s.queued),not(s.claimed),s.scanned}}
 action scanRoots=all{not(s.closed),s'={...s,r0:true,r1:true,closed:true}}
 // Forwarding becomes visible here; payload is NOT yet readable by a chunk consumer.
 action forward=all{s.producer,s.closed,not(s.copying),not(s.initialized),s'={...s,copying:true,tail:true}}
 action initializeCopy=all{s.copying,s'={...s,copying:false,initialized:true,privateChunk:true}}
 // Publication may precede Tail. PAIR chunk scanning excludes the first payload slot.
 action publish=all{s.producer,s.initialized,s.privateChunk,not(s.claimed),s'={...s,privateChunk:false,queued:true}}
 // Queue removal transfers custody to the active consumer in one abstract lock step.
 action claim=all{s.consumer,s.queued,not(s.claimed),s'={...s,queued:false,claimed:true}}
 action scanChunk=all{s.consumer,s.claimed,s'={...s,claimed:false,scanned:true}}
 action finishTail=all{s.producer,s.initialized,s.tail,s'={...s,tail:false}}
 action idleProducer=all{s.closed,s.initialized,not(s.copying),not(s.tail),not(s.privateChunk),s'={...s,producer:false}}
 action idleConsumer=all{s.scanned,not(s.queued),not(s.claimed),s'={...s,consumer:false}}
 action terminate=all{s.closed,s.r0,s.r1,s.scanned,not(s.producer),not(s.consumer),not(s.copying),not(s.tail),not(s.privateChunk),not(s.queued),not(s.claimed),s'={...s,terminated:true}}
 action step=any{scanRoots,forward,initializeCopy,publish,claim,scanChunk,finishTail,idleProducer,idleConsumer,terminate,all{s'=s}}
 action prefix=scanRoots.then(forward).then(initializeCopy).then(publish)
 action done=claim.then(scanChunk).then(finishTail).then(idleProducer).then(idleConsumer).then(terminate)
 run completeTest=init.then(prefix).then(done).then(all{assert(safe and s.terminated),s'=s})
 run publishBeforeTailTest=init.then(prefix).then(claim).then(scanChunk).then(all{assert(safe and s.tail and s.producer and s.scanned),s'=s})
 run distinctSlotsSameValueTest=init.then(all{assert(slotValues[0]==slotValues[1] and canonicalSlots==Set(0,1) and canonicalSlots.size()==2),s'=s})
 run aliasDescriptorTest=init.then(all{assert(descriptorSlots.length()==3 and canonicalSlots.size()==2),s'=s})
 run forwardingReadControlTest=init.then(scanRoots).then(forward).then(all{s'={...s,queued:true}}).then(all{assert(not(safe)),s'=s})
 run lostTailControlTest=init.then(prefix).then(all{s'={...s,producer:false}}).then(all{assert(not(safe)),s'=s})
 run dequeuedUnownedControlTest=init.then(prefix).then(claim).then(all{s'={...s,consumer:false}}).then(all{assert(not(safe)),s'=s})
 run prematureEmptyControlTest=init.then(prefix).then(claim).then(all{s'={...s,terminated:true}}).then(all{assert(not(safe)),s'=s})
 run valueDedupControlTest=init.then(prefix).then(done).then(all{s'={...s,r1:false}}).then(all{assert(not(safe)),s'=s})
 run privateChunkControlTest=init.then(scanRoots).then(forward).then(initializeCopy).then(finishTail).then(all{s'={...s,producer:false}}).then(all{assert(not(safe)),s'=s})
}
