module ffi_publication_cut {
 type State={prepared:bool,published:bool,seen:bool,read:bool,closed:bool,lease:bool,scanner:bool,removed:bool,freed:bool}
 pure val initial:State={prepared:false,published:false,seen:false,read:false,closed:false,lease:false,scanner:false,removed:false,freed:false}
 var s:State
 action init=s'=initial
 val safe=all{s.read implies (s.prepared and s.published and s.seen and s.lease and not(s.freed)),s.lease implies not(s.removed),s.scanner implies not(s.removed),s.freed implies (s.removed and not(s.lease) and not(s.scanner) and not(s.read))}
 action prepare=all{not(s.removed),not(s.freed),s'={...s,prepared:true}}
 // release publication and matching acquire are explicit reference premises.
 action publish=all{s.prepared,not(s.closed),not(s.removed),s'={...s,published:true}}
 // One serialized roster/admission decision; not independent load then increment.
 action admit=all{s.published,not(s.closed),not(s.removed),not(s.lease),s'={...s,lease:true}}
 action observe=all{s.lease,s.published,s'={...s,seen:true}}
 action readPayload=all{s.lease,s.seen,s.published,not(s.freed),s'={...s,read:true}}
 action finishRead=all{s'={...s,read:false}}
 action clearLease=all{not(s.read),s'={...s,lease:false}}
 action scanEnter=all{s.published,not(s.removed),s'={...s,scanner:true}}
 action scanExit=all{s'={...s,scanner:false}}
 action close=all{s'={...s,closed:true}}
 action withdraw=all{s.closed,not(s.lease),not(s.scanner),not(s.read),s'={...s,removed:true,published:false}}
 action free=all{s.removed,not(s.lease),not(s.scanner),not(s.read),s'={...s,freed:true}}
 action step=any{prepare,publish,admit,observe,readPayload,finishRead,clearLease,scanEnter,scanExit,close,withdraw,free,all{s'=s}}
 run normalPublicationTest=init.then(prepare).then(publish).then(admit).then(observe).then(readPayload).then(finishRead).then(clearLease).then(close).then(withdraw).then(free).then(all{assert(safe),s'=s})
 run closeRetainsReaderTest=init.then(prepare).then(publish).then(admit).then(close).then(observe).then(readPayload).then(all{assert(safe and s.lease),s'=s})
 run scanRetainsSlotTest=init.then(prepare).then(publish).then(scanEnter).then(close).then(all{assert(safe and s.scanner),s'=s}).then(scanExit).then(withdraw).then(free).then(all{assert(safe),s'=s})
 run unpreparedPublishControlTest=init.then(all{s'={...s,published:true,seen:true,lease:true,read:true}}).then(all{assert(not(safe)),s'=s})
 run unleasedReadControlTest=init.then(prepare).then(publish).then(all{s'={...s,seen:true,read:true}}).then(all{assert(not(safe)),s'=s})
 run freeWithLeaseControlTest=init.then(prepare).then(publish).then(admit).then(all{s'={...s,removed:true,freed:true}}).then(all{assert(not(safe)),s'=s})
 run removeWithScanControlTest=init.then(prepare).then(publish).then(scanEnter).then(all{s'={...s,removed:true}}).then(all{assert(not(safe)),s'=s})
}
