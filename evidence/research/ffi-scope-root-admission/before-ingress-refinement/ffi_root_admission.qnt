module ffi_root_admission {
 type State={borrow:bool,guardLive:bool,scope:bool,root:bool,allocated:bool,marker:bool,active:bool,done:bool,unknown:bool,scanner:bool,closed:bool,retired:bool,epoch:int,slot:int,local:int,markerVersion:int}
 pure val initial:State={borrow:true,guardLive:false,scope:false,root:false,allocated:false,marker:false,active:false,done:false,unknown:false,scanner:false,closed:false,retired:false,epoch:1,slot:0,local:0,markerVersion:0}
 var s:State
 action init=s'=initial
 val safe=all{s.epoch>=1,s.epoch<=2,
 s.scope implies s.guardLive,
 s.root implies (s.guardLive and s.slot==s.epoch),
 s.marker implies (s.root and s.scope and s.guardLive and s.markerVersion==s.epoch),
 s.active implies (s.marker and s.root and s.scope and s.guardLive and not(s.done)),
 s.retired implies (not(s.guardLive) and not(s.scope) and not(s.root) and not(s.active) and not(s.scanner) and not(s.unknown)),
 s.guardLive implies s.borrow,
 s.scanner implies (s.root and s.guardLive)}
 action registerGuard=all{s.borrow,not(s.guardLive),not(s.closed),not(s.retired),s'={...s,guardLive:true}}
 action acquireScope=all{s.guardLive,not(s.done),not(s.closed),s'={...s,scope:true}}
 action publishRoots=all{s.guardLive,s.scope,not(s.done),not(s.root),s'={...s,root:true,slot:s.epoch}}
 // Qualified collector rendezvous; active Scheme execution is outside this pre-entry model.
 action collect=all{not(s.active),s.epoch<2,s'={...s,epoch:s.epoch+1,slot:if(s.root) s.epoch+1 else s.slot,markerVersion:if(s.marker) s.epoch+1 else s.markerVersion}}
 action allocateMarker=all{s.guardLive,s.scope,s.root,not(s.done),not(s.active),s'={...s,allocated:true}}
 action reloadRoot=all{s.root,not(s.active),s'={...s,local:s.slot}}
 action initializeMarker=all{s.allocated,s.root,s.scope,not(s.done),s.local==s.epoch,s'={...s,marker:true,markerVersion:s.local}}
 action enter=all{s.guardLive,s.scope,s.root,s.marker,not(s.active),not(s.done),not(s.unknown),s'={...s,active:true}}
 action normalReturn=all{s.active,s'={...s,active:false,done:true}}
 action throwExit=all{s.active,s'={...s,active:false,unknown:true}}
 // Only a qualified owner receipt, never a timeout, may settle this state.
 action settleException=all{s.guardLive,s.unknown,not(s.active),s'={...s,unknown:false,done:true}}
 action allocationFailure=all{s.guardLive,s.root,not(s.marker),not(s.active),not(s.done),s'={...s,allocated:false,done:true}}
 action invalidateMarker=all{s.done,not(s.active),s'={...s,marker:false}}
 action releaseScope=all{s.guardLive,s.scope,s.done,not(s.active),not(s.marker),not(s.unknown),s'={...s,scope:false}}
 action scanEnter=all{s.root,s.guardLive,not(s.retired),s'={...s,scanner:true}}
 action scanExit=all{s'={...s,scanner:false}}
 action dropRoots=all{s.root,s.done,not(s.scope),not(s.active),not(s.scanner),s'={...s,root:false}}
 action retireGuard=all{s.guardLive,s.done,not(s.scope),not(s.root),not(s.scanner),not(s.unknown),s'={...s,guardLive:false,retired:true}}
 action close=all{s'={...s,closed:true}}
 action step=any{registerGuard,acquireScope,publishRoots,collect,allocateMarker,reloadRoot,initializeMarker,enter,normalReturn,throwExit,settleException,allocationFailure,invalidateMarker,releaseScope,scanEnter,scanExit,dropRoots,retireGuard,close,all{s'=s}}
 action prepare=registerGuard.then(acquireScope).then(publishRoots).then(allocateMarker).then(reloadRoot).then(initializeMarker)
 action complete=normalReturn.then(invalidateMarker).then(releaseScope).then(dropRoots).then(retireGuard)
 run movingInputTest=init.then(registerGuard).then(acquireScope).then(publishRoots).then(allocateMarker).then(collect).then(reloadRoot).then(initializeMarker).then(enter).then(complete).then(all{assert(safe and s.retired),s'=s})
 run exceptionCustodyTest=init.then(prepare).then(enter).then(throwExit).then(close).then(all{assert(safe and s.guardLive and s.root and s.scope and s.unknown),s'=s}).then(settleException).then(invalidateMarker).then(releaseScope).then(dropRoots).then(retireGuard).then(all{assert(safe),s'=s})
 run allocationFailureTest=init.then(registerGuard).then(acquireScope).then(publishRoots).then(allocationFailure).then(releaseScope).then(dropRoots).then(retireGuard).then(all{assert(safe),s'=s})
 run maintenanceAfterCloseTest=init.then(prepare).then(enter).then(close).then(normalReturn).then(invalidateMarker).then(scanEnter).then(releaseScope).then(all{assert(safe and s.root and s.scanner),s'=s}).then(scanExit).then(dropRoots).then(retireGuard).then(all{assert(safe),s'=s})
 run missingRootControlTest=init.then(registerGuard).then(acquireScope).then(all{s'={...s,allocated:true,marker:true,markerVersion:1}}).then(all{assert(not(safe)),s'=s})
 run lostGuardControlTest=init.then(prepare).then(enter).then(throwExit).then(all{s'={...s,guardLive:false}}).then(all{assert(not(safe)),s'=s})
 run earlyReleaseControlTest=init.then(prepare).then(all{s'={...s,scope:false}}).then(all{assert(not(safe)),s'=s})
 run staleLocalControlTest=init.then(registerGuard).then(acquireScope).then(publishRoots).then(allocateMarker).then(reloadRoot).then(collect).then(all{s'={...s,marker:true,markerVersion:s.local}}).then(all{assert(not(safe)),s'=s})
 run scanRetireControlTest=init.then(prepare).then(scanEnter).then(all{s'={...s,guardLive:false,root:false,scope:false,marker:false,retired:true}}).then(all{assert(not(safe)),s'=s})
}
