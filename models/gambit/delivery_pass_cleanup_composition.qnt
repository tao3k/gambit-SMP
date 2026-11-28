// Two accepted passes, one VM, two native callers, repeatable GC.
// Source projection: release/acquire visibility is explicit, not a C11 proof.
// Healthy liveness assumes finite existing VM-lock holders and fair servicing.
// It is not a wall-clock bound or a proof that arbitrary callbacks terminate.
module delivery_pass_cleanup_composition {
 type State={bug:int,permanent:bool,supported:bool,
   active:Set[int],issued:Set[int],handed:Set[int],visible:Set[int],
   roots:Set[int],charged:Set[int],done:Set[int],
   sealed:bool,claim:bool,ticketBorrow:bool,publicBorrow:bool,publicTried:bool,
   publicChecked:bool,publicCritical:bool,
   vmLocked:bool,holderWaitsGc:bool,leaf:bool,selected:int,cacheValid:bool,
   gc:bool,gcParity:bool,debt:bool,busySeen:bool,
   budget:int,retained:bool,lastRead:bool,freed:bool,ownerReleased:bool,
   debits:int,unsafeRead:bool,staleUse:bool,lateAccepted:bool,afterFreeUse:bool}
 var h:State
 pure def initial(bug:int,permanent:bool,supported:bool):State={
   bug:bug,permanent:permanent,supported:supported,
   active:if(supported) Set(1,2) else Set(1),issued:Set(),
   handed:if(supported) Set() else Set(2),visible:if(supported) Set() else Set(2),
   roots:Set(1,2),charged:Set(1,2),done:Set(),
   sealed:not(supported),claim:not(supported),ticketBorrow:not(supported),
   publicBorrow:false,publicTried:false,publicChecked:false,publicCritical:false,
   vmLocked:true,holderWaitsGc:false,leaf:false,selected:0,cacheValid:true,
   gc:false,gcParity:false,debt:false,busySeen:false,budget:2,
   retained:false,lastRead:false,freed:false,ownerReleased:false,
   debits:0,unsafeRead:false,staleUse:false,lateAccepted:false,afterFreeUse:false}
 action initFixed=any{h'=initial(0,false,true),h'=initial(0,true,true),h'=initial(0,false,false)}
 action initPlain=h'=initial(1,false,true)
 action initActiveFinish=h'=initial(2,false,true)
 action initBusyFatal=h'=initial(3,false,true)
 action initStale=h'=initial(4,false,true)
 action initBorrowIgnored=h'=initial(5,false,true)
 action initAfterRelease=h'=initial(6,false,true)
 action initReopen=h'=initial(7,false,true)
 action initGcPriority=h'=initial(8,false,true)
 action initLockWaitGc=h'=initial(9,false,true)
 action initFaultDrop=h'=initial(10,true,true)
 action initGlobalClaim=h'=initial(11,false,true)
 action initDoubleDebit=h'=initial(12,false,true)
 pure val ids=Set(1,2)
 action bodyEnd(p:int):bool=all{h.supported,h.active.contains(p),not(h.sealed),
   h'={...h,active:h.active.exclude(Set(p)),issued:h.issued.union(Set(p))}}
 action publish(p:int):bool=all{h.issued.contains(p),not(h.sealed),
   h'={...h,issued:h.issued.exclude(Set(p)),handed:h.handed.union(Set(p)),
     visible:if(h.bug==1) h.visible else h.visible.union(Set(p))}}
 // Old plain publication permits the flag to become visible first.
 action propagatePayload(p:int):bool=all{h.handed.contains(p),not(h.visible.contains(p)),
   h'={...h,visible:h.visible.union(Set(p))}}
 action seal=all{not(h.sealed),(h.handed==ids or h.bug==2),
   h'={...h,sealed:true,claim:true,ticketBorrow:true}}
 // Exactly one pre-existing holder. No new unbounded locker source is assumed.
 action holderRelease=all{h.vmLocked,not(h.permanent),not(h.holderWaitsGc),
   h'={...h,vmLocked:false}}
 action holderWaitGc=all{h.bug==9,h.vmLocked,not(h.holderWaitsGc),
   h'={...h,holderWaitsGc:true}}
 action publicEnter=all{h.sealed,not(h.freed),not(h.retained),not(h.publicTried),
   h'={...h,publicBorrow:true,publicTried:true}}
 action publicTry=all{h.publicBorrow,not(h.publicChecked),
   h'={...h,publicChecked:true,publicCritical:h.bug==11 and h.claim}}
 action publicReturn=all{h.publicBorrow,h.publicChecked,
   h'={...h,publicBorrow:false,publicCritical:false}}
 // Request storms may request GC forever. A completed GC owes one service window.
 action gcStart=all{h.sealed,h.supported,not(h.retained),not(h.freed),
   h.charged.size()>0,not(h.gc),not(h.leaf),not(h.vmLocked),
   (not(h.debt) or h.bug==8),h'={...h,gc:true}}
 action gcEnd=all{h.gc,h'={...h,gc:false,debt:true,gcParity:not(h.gcParity),cacheValid:false}}
 action beginFor(p:int):bool=all{h.sealed,h.claim,h.ticketBorrow,h.supported,
   not(h.gc),not(h.leaf),not(h.retained),not(h.freed),not(h.permanent and h.budget==0),h.charged.contains(p),
   (h.handed.contains(p) or h.bug==2),
   h'={...h,leaf:true,selected:p,cacheValid:if(h.bug==4) h.cacheValid else true}}
 action beginAttempt=any{beginFor(1),beginFor(2)}
 // A failed trylock owns no VM lock and consumes no original pass charge.
 action busyReturn=all{h.leaf,h.vmLocked,
   h'={...h,leaf:false,selected:0,busySeen:true,
     retained:h.retained or (h.bug==3 and not(h.permanent))}}
 action finish=all{h.leaf,not(h.vmLocked),not(h.gc),h.claim,h.ticketBorrow,
   h.charged.contains(h.selected),
   h'={...h,leaf:false,selected:0,
     roots:h.roots.exclude(Set(h.selected)),charged:h.charged.exclude(Set(h.selected)),
     done:h.done.union(Set(h.selected)),debits:h.debits+1,debt:false,
     unsafeRead:h.unsafeRead or not(h.visible.contains(h.selected)),
     staleUse:h.staleUse or not(h.cacheValid)}}
 action unsupported=all{h.sealed,not(h.supported),not(h.retained),not(h.leaf),
   h'={...h,retained:true}}
 // Abstract expiry units; NOT elapsed seconds and never a proof of timely completion.
 action tick=all{h.permanent,h.sealed,not(h.retained),h.budget>0,
   h'={...h,budget:h.budget-1}}
 action expire=all{h.permanent,h.sealed,h.budget==0,not(h.retained),not(h.leaf),
   h'={...h,retained:true,roots:if(h.bug==10) Set() else h.roots}}
 action lastVmRead=all{h.sealed,h.claim,h.ticketBorrow,not(h.retained),
   (h.charged.size()==0),not(h.publicBorrow),not(h.gc),not(h.leaf),not(h.lastRead),
   h'={...h,lastRead:true}}
 action reclaim=all{h.lastRead,h.claim,h.ticketBorrow,not(h.retained),not(h.freed),
   (not(h.publicBorrow) or h.bug==5),h'={...h,freed:true}}
 action releaseOwner=all{h.freed,h.ticketBorrow,not(h.publicBorrow),
   h'={...h,ticketBorrow:false,claim:false,ownerReleased:true}}
 action staleVmRead=all{h.bug==6,h.ownerReleased,not(h.afterFreeUse),
   h'={...h,afterFreeUse:true}}
 action lateEnter=all{h.bug==7,h.sealed,not(h.freed),not(h.lateAccepted),
   h'={...h,lateAccepted:true,roots:h.roots.union(Set(3)),charged:h.charged.union(Set(3))}}
 action secondDebit=all{h.bug==12,h.done.size()>0,h.debits<3,
   h'={...h,debits:h.debits+1}}
 action idle=h'=h
 action step=any{bodyEnd(1),bodyEnd(2),publish(1),publish(2),propagatePayload(1),propagatePayload(2),
   seal,holderRelease,holderWaitGc,publicEnter,publicTry,publicReturn,gcStart,gcEnd,
   beginAttempt,busyReturn,finish,unsupported,tick,expire,lastVmRead,reclaim,
   releaseOwner,staleVmRead,lateEnter,secondDebit,idle}
 val publicationSafe=h.handed.subseteq(h.visible) and not(h.unsafeRead)
 val handoffSafe=h.done.subseteq(h.handed) and (h.done.intersect(h.active).size()==0)
 val busySafe=not(h.retained) or h.permanent or not(h.supported)
 val cacheSafe=not(h.staleUse)
 val rootSafe=h.charged.subseteq(h.roots) and (h.done.intersect(h.roots).size()==0)
 val borrowerSafe=not(h.freed) or not(h.publicBorrow)
 val useSafe=not(h.afterFreeUse)
 val closedSafe=not(h.lateAccepted)
 val gcDebtSafe=not(h.gc and h.debt)
 val lockSafe=not(h.vmLocked and h.holderWaitsGc)
 val claimSafe=not(h.publicCritical and h.claim)
 val debitSafe=h.debits==h.done.size()
 val lifeSafe=all{not(h.freed) or ((h.charged.size()==0) and (h.roots.size()==0) and not(h.leaf) and h.lastRead),
   not(h.leaf) or (h.claim and h.ticketBorrow and not(h.freed)),
   not(h.retained) or (not(h.freed) and h.ticketBorrow and h.claim)}
 val safe=publicationSafe and handoffSafe and busySafe and cacheSafe and rootSafe and borrowerSafe and
   useSafe and closedSafe and gcDebtSafe and lockSafe and claimSafe and debitSafe and lifeSafe
 val safeExceptDebt=publicationSafe and handoffSafe and busySafe and cacheSafe and rootSafe and borrowerSafe and
   useSafe and closedSafe and lockSafe and claimSafe and debitSafe and lifeSafe
 temporal fair=weakFair(bodyEnd(1),Set(h)) and weakFair(bodyEnd(2),Set(h)) and
   weakFair(publish(1),Set(h)) and weakFair(publish(2),Set(h)) and weakFair(seal,Set(h)) and
   weakFair(holderRelease,Set(h)) and weakFair(publicTry,Set(h)) and weakFair(publicReturn,Set(h)) and
   weakFair(gcEnd,Set(h)) and weakFair(beginAttempt,Set(h)) and weakFair(busyReturn,Set(h)) and
   weakFair(finish,Set(h)) and weakFair(unsupported,Set(h)) and weakFair(tick,Set(h)) and
   weakFair(expire,Set(h)) and weakFair(lastVmRead,Set(h)) and weakFair(reclaim,Set(h)) and weakFair(releaseOwner,Set(h))
 temporal progress=fair.implies(eventually(if(h.permanent or not(h.supported)) h.retained else h.ownerReleased))
 // Source-constrained profile for the exact P0 native cleanup slice.
 // GC requests may remain pending (idle); actual GC cannot start until P0
 // explicitly participates. This profile is valid ONLY after checking the
 // transitive drain leaf has no allocation, callback, poll or SYNC.
 // It does not assert that GC is disabled before/after that native slice.
 // Original step/initGcPriority and its GC-starvation control are retained.
 action nativeDrainStep=any{bodyEnd(1),bodyEnd(2),publish(1),publish(2),propagatePayload(1),propagatePayload(2),
   seal,holderRelease,holderWaitGc,publicEnter,publicTry,publicReturn,
   beginAttempt,busyReturn,finish,unsupported,tick,expire,lastVmRead,reclaim,
   releaseOwner,staleVmRead,lateEnter,secondDebit,idle}

}
