module pin_roster_lifecycle {
 type State={open:bool,registered:bool,generation:int,view:int,captured:bool,pin:bool,access:bool,scanner:bool,closing:bool,requested:bool,stopped:bool,joined:bool,custodian:bool,unknown:bool,retired:bool}
 pure val initial:State={open:true,registered:false,generation:1,view:0,captured:false,pin:false,access:false,scanner:false,closing:false,requested:false,stopped:false,joined:false,custodian:false,unknown:false,retired:false}
 var s:State
 action init=s'=initial
 val safe=all{s.generation>=1,s.generation<=2,
 s.pin implies (s.registered and s.view==s.generation and not(s.retired)),
 s.access implies (s.pin and not(s.stopped)),
 s.scanner implies (s.registered and not(s.retired)),
 s.retired implies (not(s.registered) and not(s.pin) and not(s.access) and not(s.scanner) and s.closing and s.stopped and s.joined and not(s.unknown))}
 action register=all{s.open,not(s.registered),not(s.closing),not(s.retired),s'={...s,registered:true}}
 action loadHandle=all{s.registered,not(s.closing),s'={...s,captured:true,view:s.generation}}
 action publishPin=all{s.registered,s.captured,s.view==s.generation,not(s.closing),not(s.retired),not(s.stopped),s'={...s,pin:true}}
 action beginAccess=all{s.pin,s.view==s.generation,not(s.stopped),s'={...s,access:true}}
 action finishAccess=all{s'={...s,access:false}}
 action clearPin=all{not(s.access),s'={...s,pin:false}}
 action scanEnter=all{s.registered,not(s.retired),s'={...s,scanner:true}}
 action scanExit=all{s'={...s,scanner:false}}
 action close=all{s'={...s,open:false,closing:true}}
 action requestExit=all{s'={...s,requested:true}}
 // A qualified stop receipt, not a timeout or failed join observation.
 action confirmStop=all{s.requested,not(s.access),s'={...s,stopped:true}}
 action failJoin=all{s.requested,not(s.joined),s'={...s,unknown:true}}
 action joinSuccess=all{s.stopped,s'={...s,joined:true,unknown:false}}
 action acceptCustody=all{s.stopped,s.pin,s'={...s,custodian:true}}
 action custodianClear=all{s.custodian,s.stopped,not(s.access),s'={...s,pin:false}}
 action withdraw=all{s.registered,s.closing,not(s.pin),not(s.access),not(s.scanner),s.stopped,s.joined,not(s.unknown),s'={...s,registered:false}}
 action retire=all{not(s.registered),s.closing,not(s.pin),not(s.access),not(s.scanner),s.stopped,s.joined,not(s.unknown),s'={...s,retired:true}}
 action recycle=all{s.retired,s.generation<2,s'={...s,generation:s.generation+1,retired:false,open:true,closing:false,requested:false,stopped:false,joined:false,custodian:false}}
 action staleRelease=all{s.view!=s.generation,s'=s}
 action step=any{register,loadHandle,publishPin,beginAccess,finishAccess,clearPin,scanEnter,scanExit,close,requestExit,confirmStop,failJoin,joinSuccess,acceptCustody,custodianClear,withdraw,retire,recycle,staleRelease,all{s'=s}}
 run normalDrainTest=init.then(register).then(loadHandle).then(publishPin).then(beginAccess).then(close).then(finishAccess).then(clearPin).then(requestExit).then(confirmStop).then(joinSuccess).then(withdraw).then(retire).then(all{assert(safe),s'=s})
 run exceptionCustodyTest=init.then(register).then(loadHandle).then(publishPin).then(close).then(requestExit).then(failJoin).then(all{assert(safe and s.pin and s.unknown),s'=s}).then(confirmStop).then(acceptCustody).then(custodianClear).then(joinSuccess).then(withdraw).then(retire).then(all{assert(safe),s'=s})
 run scannerAfterCloseTest=init.then(register).then(close).then(scanEnter).then(requestExit).then(confirmStop).then(joinSuccess).then(all{assert(safe and s.registered and s.scanner),s'=s}).then(scanExit).then(withdraw).then(retire).then(all{assert(safe),s'=s})
 run generationStaleTest=init.then(register).then(loadHandle).then(close).then(requestExit).then(confirmStop).then(joinSuccess).then(withdraw).then(retire).then(recycle).then(register).then(staleRelease).then(all{assert(safe and s.view!=s.generation and not(s.pin)),s'=s})
 run rawPointerPinControlTest=init.then(all{s'={...s,pin:true}}).then(all{assert(not(safe)),s'=s})
 run clearDuringAccessControlTest=init.then(register).then(loadHandle).then(publishPin).then(beginAccess).then(all{s'={...s,pin:false}}).then(all{assert(not(safe)),s'=s})
 run failedJoinRetireControlTest=init.then(register).then(close).then(requestExit).then(failJoin).then(all{s'={...s,registered:false,retired:true}}).then(all{assert(not(safe)),s'=s})
 run scannerWithdrawControlTest=init.then(register).then(scanEnter).then(all{s'={...s,registered:false}}).then(all{assert(not(safe)),s'=s})
 run staleAdmissionControlTest=init.then(register).then(loadHandle).then(close).then(requestExit).then(confirmStop).then(joinSuccess).then(withdraw).then(retire).then(recycle).then(register).then(all{s'={...s,pin:true}}).then(all{assert(not(safe)),s'=s})
}
