// Abstract gate operations are linearizable. This is not a C weak-memory model.
// One call/view, one layout operation, one ticket, one collector, one GC; route=0/1/2.
module rest_allocator_root_publication {
 type S={route:int,view:bool,published:bool,rootHB:bool,closing:bool,op:int,unknown:bool,
  layout:int,ticket:int,stamp:int,acquired:bool,active:bool,full:bool,hp:int,used:int,
  frozen:bool,scanned:bool,epoch:int,rootEpoch:int,reloaded:bool,resumeHB:bool,escrow:bool,evals:int}
 var s:S
 action init=s'={route:0,view:false,published:false,rootHB:false,closing:false,op:0,unknown:false,
  layout:0,ticket:0,stamp:-1,acquired:false,active:false,full:true,hp:8,used:0,
  frozen:false,scanned:false,epoch:0,rootEpoch:0,reloaded:true,resumeHB:true,escrow:false,evals:1}
 action directInit=init.then(all{s'={...s,route:1}})
 action nativeInit=init.then(all{s'={...s,route:2}})
 action prepare=all{not(s.view),s'={...s,view:true}}
 // Release root registration and acquire gate observation are folded here, not inferred from plain fields.
 action publish=all{s.view,not(s.published),not(s.closing),s'={...s,published:true,rootHB:true}}
 action beginLayout=all{s.published,s.rootHB,not(s.closing),s.op==0,s.ticket==0,not(s.active),s.layout<2,s.reloaded,
  s'={...s,op:1,escrow:true}}
 action knownLayout=all{s.op==1,not(s.unknown),s'={...s,op:0,escrow:false,layout:s.layout+1}}
 // Denial may follow a known layout mutation; roots survive but the old layout does not.
 action knownDeny=all{s.op==1,not(s.unknown),s'={...s,op:0,escrow:false,layout:s.layout+1,ticket:0}}
 action loseLayoutResult=all{s.op==1,s'={...s,unknown:true}}
 action reconcileKnownDeny=all{s.op==1,s.unknown,s'={...s,op:0,unknown:false,escrow:false,layout:s.layout+1}}
 action grant=all{s.published,s.rootHB,not(s.closing),s.op==0,not(s.unknown),s.ticket==0,s.full,
  not(s.frozen),s.reloaded,s.resumeHB,s.rootEpoch==s.epoch,s'={...s,ticket:1,stamp:s.layout,acquired:false}}
 action acquireGrant=all{s.ticket==1,s'={...s,acquired:true}}
 // enter and close share the gate; a stale acquire load alone is not an entry permit.
 action enter=all{s.ticket==1,s.acquired,s.stamp==s.layout,not(s.closing),not(s.frozen),s.op==0,
  s'={...s,ticket:2,active:true,full:false}}
 action initialize=all{s.active,s.ticket==2,s.used==0,s'={...s,used:14,hp:s.hp+14}}
 action finish=all{s.active,s.used==14,s'={...s,active:false,full:true,ticket:0,acquired:false}}
 action close=all{not(s.closing),s'={...s,closing:true}}
 action cancelUnused=all{s.ticket==1,not(s.active),s'={...s,ticket:0,acquired:false}}
 action freeze=all{s.closing,s.published,s.op==0,not(s.unknown),not(s.escrow),s.ticket==0,not(s.active),s.full,
  not(s.frozen),s'={...s,frozen:true}}
 action scan=all{s.frozen,not(s.scanned),s.rootHB,s'={...s,scanned:true}}
 action relocate=all{s.scanned,s.epoch==0,s'={...s,epoch:1,rootEpoch:1,layout:s.layout+1,hp:8,used:0,reloaded:false,resumeHB:false}}
 action resume=all{s.scanned,s.epoch==1,not(s.reloaded),s.op==0,not(s.active),s.ticket==0,
  s'={...s,reloaded:true,resumeHB:true,scanned:false,frozen:false,closing:false}}
 action idle=s'=s
 val safe=all{
  s.evals==1,s.hp==8+s.used,
  not(s.published) or (s.view and s.rootHB),
  s.op==0 or (s.published and s.escrow and not(s.frozen)),
  not(s.unknown) or (s.op==1 and s.escrow),
  s.ticket==0 or (s.published and s.stamp==s.layout and s.reloaded and s.resumeHB and s.rootEpoch==s.epoch),
  not(s.active) or (s.ticket==2 and not(s.full) and not(s.frozen) and s.acquired),
  s.full or s.active,
  not(s.frozen) or (s.closing and s.full and not(s.active) and s.ticket==0 and s.op==0 and not(s.unknown)),
  not(s.scanned) or s.frozen}
 action step=any{prepare,publish,beginLayout,knownLayout,knownDeny,loseLayoutResult,reconcileKnownDeny,
  grant,acquireGrant,enter,initialize,finish,close,cancelUnused,freeze,scan,relocate,resume,idle}
 action rooted=init.then(prepare).then(publish)
 action leased=rooted.then(grant).then(acquireGrant)
 action building=leased.then(enter)
 action completed=building.then(initialize).then(finish)
 action parked=rooted.then(close).then(freeze).then(scan)
 action check=all{assert(safe),s'=s}
 action reject=all{assert(not(safe)),s'=s}
 action badScan=s'={...s,scanned:true,frozen:true}
 action badLateEnter=s'={...s,ticket:2,active:true,full:false}
 action badPublish=s'={...s,published:true}
 action badRefund=s'={...s,op:0,escrow:false}
 action badReset=s'={...s,layout:s.layout+1}
 action badDrop=s'={...s,view:false}
 action badResume=s'={...s,frozen:false,scanned:false,closing:false,ticket:1,stamp:s.layout,reloaded:true}
 run knownDenyKeepsRootsTest=rooted.then(beginLayout).then(knownDeny).then(check)
 run grantDoesNotAdvanceCursorTest=leased.then(all{assert(s.hp==8 and safe),s'=s})
 run closeWaitsForLayoutTest=rooted.then(beginLayout).then(close).then(knownLayout).then(freeze).then(scan).then(check)
 run closeCancelsUnusedTest=leased.then(close).then(cancelUnused).then(freeze).then(scan).then(check)
 run enteredWriterDrainsTest=building.then(close).then(initialize).then(finish).then(freeze).then(scan).then(check)
 run unknownResultRemainsEscrowedTest=rooted.then(beginLayout).then(loseLayoutResult).then(close).then(idle).then(check)
 run reconcileAfterCloseTest=rooted.then(beginLayout).then(loseLayoutResult).then(close).then(reconcileKnownDeny).then(freeze).then(scan).then(check)
 run relocateReloadReissueTest=parked.then(relocate).then(resume).then(grant).then(acquireGrant).then(enter).then(check)
 run directCallProfileTest=directInit.then(prepare).then(publish).then(grant).then(acquireGrant).then(enter).then(check)
 run nativeCallProfileTest=nativeInit.then(prepare).then(publish).then(beginLayout).then(knownDeny).then(check)
 run fullFrameScanTest=completed.then(close).then(freeze).then(scan).then(check)
 run rootPublicationCounterexampleTest=init.then(prepare).then(badPublish).then(reject)
 run concurrentLayoutScanCounterexampleTest=rooted.then(beginLayout).then(close).then(badScan).then(reject)
 run partialFrameScanCounterexampleTest=building.then(close).then(badScan).then(reject)
 run unknownRefundCounterexampleTest=rooted.then(beginLayout).then(loseLayoutResult).then(badRefund).then(reject)
 run layoutAbaCounterexampleTest=leased.then(badReset).then(reject)
 run rootDropOnDenyCounterexampleTest=rooted.then(beginLayout).then(knownDeny).then(badDrop).then(reject)
 run staleRootReloadCounterexampleTest=parked.then(relocate).then(badResume).then(reject)
 run closeEnterSplitCounterexampleTest=leased.then(close).then(cancelUnused).then(freeze).then(badLateEnter).then(reject)
 action negativeInit=building.then(close)
 action negativeStep=badScan
}
