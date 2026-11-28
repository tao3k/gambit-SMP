module pipe_domain {
 // Peer-domain ownership only. Existing root/GC models retain their duties.
 type State={holders:Set[int],queue:List[int],sent:int,received:int,closed:bool,waiting:Set[int],woken:Set[int],stopped:bool}
 pure val initial:State={holders:Set(),queue:[],sent:0,received:0,closed:false,waiting:Set(),woken:Set(),stopped:false}
 var s:State
 action init=s'=initial
 val conservation=s.sent-s.received==s.queue.length()
 val bounded=s.received>=0 and s.received<=s.sent and s.sent<=3
 val uniqueOwner=s.holders.size()<=1 and s.holders.subseteq(Set(0,1))
 val waitReleased=s.waiting.intersect(s.holders).size()==0
 val closedWake=not(s.closed and s.waiting.contains(1)) or s.woken.contains(1)
 val safe=all{conservation,bounded,uniqueOwner,waitReleased,closedWake}
 action lock(e:int):bool=all{s.holders.size()==0,not(s.stopped),e>=0,e<=1,not(s.waiting.contains(e)),s'={...s,holders:Set(e)}}
 action unlock(e:int):bool=all{s.holders.contains(e),s'={...s,holders:s.holders.exclude(Set(e))}}
 action write=all{s.holders.contains(0),not(s.closed),s.sent<3,s'={...s,queue:s.queue.append(s.sent),sent:s.sent+1,woken:s.woken.union(s.waiting.intersect(Set(1)))}}
 action read=all{s.holders.contains(1),s.queue.length()>0,s'={...s,queue:s.queue.tail(),received:s.received+1,woken:s.woken.union(s.waiting.intersect(Set(0)))}}
 action wait(e:int):bool=all{s.holders.contains(e),not(s.closed),any{all{e==1,s.queue.length()==0},all{e==0,s.queue.length()>=2}},s'={...s,holders:s.holders.exclude(Set(e)),waiting:s.waiting.union(Set(e)),woken:s.woken.exclude(Set(e))}}
 action reacquire(e:int):bool=all{s.holders.size()==0,s.waiting.contains(e),s.woken.contains(e),s'={...s,holders:Set(e),waiting:s.waiting.exclude(Set(e)),woken:s.woken.exclude(Set(e))}}
 action close=all{s.holders.contains(0),not(s.closed),s'={...s,closed:true,woken:s.woken.union(s.waiting.intersect(Set(1)))}}
 action exceptionalReturn(e:int):bool=unlock(e)
 action exceptionInWaitHook(e:int):bool=all{s.holders.size()==0,s.waiting.contains(e),s'={...s,waiting:s.waiting.exclude(Set(e)),woken:s.woken.exclude(Set(e))}}
 action finish=all{s.holders.size()==0,s.closed,s.queue.length()==0,s.waiting.size()==0,s'={...s,stopped:true}}
 action step=any{lock(0),lock(1),unlock(0),unlock(1),write,read,wait(0),wait(1),reacquire(0),reacquire(1),close,exceptionalReturn(0),exceptionalReturn(1),exceptionInWaitHook(0),exceptionInWaitHook(1),finish,all{s.stopped,s'=s}}
 run deliveryTest=init.then(lock(1)).then(wait(1)).then(lock(0)).then(write).then(unlock(0)).then(reacquire(1)).then(read).then(unlock(1)).then(all{assert(safe and s.received==1),s'=s})
 run closedWakeTest=init.then(lock(1)).then(wait(1)).then(lock(0)).then(close).then(unlock(0)).then(reacquire(1)).then(unlock(1)).then(finish).then(all{assert(safe and s.stopped),s'=s})
 run hookFailureTest=init.then(lock(1)).then(wait(1)).then(exceptionInWaitHook(1)).then(lock(0)).then(write).then(unlock(0)).then(lock(1)).then(read).then(unlock(1)).then(all{assert(safe),s'=s})
 // Old per-endpoint locks admit both holders, despite shared FIFO/cursors.
 action splitLock(e:int):bool=all{e>=0,e<=1,not(s.holders.contains(e)),s'={...s,holders:s.holders.union(Set(e))}}
 run splitOwnerNegativeTest=init.then(splitLock(0)).then(splitLock(1)).then(all{assert(not(uniqueOwner)),s'=s})
 run lostWakeNegativeTest=init.then(lock(1)).then(wait(1)).then(lock(0)).then(s'={...s,closed:true}).then(all{assert(not(closedWake)),s'=s})
 run waitHoldingOwnerNegativeTest=init.then(lock(1)).then(s'={...s,waiting:Set(1)}).then(all{assert(not(waitReleased)),s'=s})
 run duplicateReadNegativeTest=init.then(lock(0)).then(write).then(unlock(0)).then(lock(1)).then(read).then(s'={...s,received:s.received+1}).then(all{assert(not(conservation)),s'=s})
 run writerWaitTest=init.then(lock(0)).then(write).then(write).then(wait(0)).then(lock(1)).then(read).then(unlock(1)).then(reacquire(0)).then(write).then(unlock(0)).then(all{assert(safe),assert(s.sent==3),s'=s})
 run writerHookFailureTest=init.then(lock(0)).then(write).then(write).then(wait(0)).then(exceptionInWaitHook(0)).then(lock(1)).then(read).then(read).then(unlock(1)).then(all{assert(safe),assert(s.received==2),s'=s})
}
