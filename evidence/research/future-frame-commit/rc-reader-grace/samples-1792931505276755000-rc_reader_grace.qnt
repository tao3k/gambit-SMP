module rc_reader_grace {
// Lookup/claim leases are ghost obligations of an enclosing live VM/round.
// Fault has no recovery action: current fatal paths do not issue recovery receipts.
type State={admission:int,lookup:int,claimed:int,done:int,domainLive:int,registered:int,scan:int,saved:int,diagLease:int,diagGate:int,fault:int,escrow:int,retired:int,denied:int}
pure val initial:State={admission:1,lookup:0,claimed:0,done:0,domainLive:1,registered:1,scan:0,saved:0,diagLease:0,diagGate:1,fault:0,escrow:0,retired:0,denied:0}
var s:State
action init=s'=initial
val safe=all{s.admission>=0,s.lookup>=0,s.claimed>=0,s.done>=0,s.domainLive>=0,s.registered>=0,s.scan>=0,s.saved>=0,s.diagLease>=0,s.diagGate>=0,s.fault>=0,s.escrow>=0,s.retired>=0,s.denied>=0,s.admission<=1,s.lookup<=1,s.claimed<=1,s.done<=1,s.domainLive<=1,s.registered<=1,s.scan<=1,s.saved<=1,s.diagLease<=1,s.diagGate<=1,s.fault<=1,s.escrow<=1,s.retired<=1,s.denied<=1,s.scan==1 implies all{s.claimed==1,s.registered==1,s.domainLive==1},s.saved==s.fault,s.escrow==s.fault,s.fault==1 implies all{s.scan==1,s.claimed==1,s.registered==1,s.domainLive==1},s.diagLease==1 implies all{s.saved==1,s.domainLive==1},s.lookup==1 implies s.domainLive==1,s.claimed==1 implies all{s.domainLive==1,s.done==0},s.done==1 implies all{s.claimed==0,s.scan==0,s.fault==0},s.admission==1 implies s.domainLive==1,s.domainLive==0 implies all{s.admission==0,s.lookup==0,s.claimed==0,s.scan==0,s.fault==0,s.registered==0,s.diagLease==0,s.diagGate==0,s.done==1,s.retired==1},s.retired==1 implies s.domainLive==0}
action enterLookup=all{s.admission==1 and s.lookup==0 and s.domainLive==1,s'={...s,lookup:1}}
action claimLookup=all{s.lookup==1 and s.done==0 and s.claimed==0,s'={...s,lookup:0,claimed:1}}
action failClaim=all{s.lookup==1 and (s.done==1 or s.claimed==1),s'={...s,lookup:0}}
action completeClaim=all{s.claimed==1 and s.scan==0 and s.fault==0,s'={...s,claimed:0,done:1}}
action closeAdmission=all{s.admission==1,s'={...s,admission:0}}
action rejectLate=all{s.admission==0 and s.denied==0,s'={...s,denied:1}}
action beginScan=all{s.claimed==1 and s.registered==1 and s.scan==0 and s.fault==0,s'={...s,scan:1}}
action endScan=all{s.scan==1 and s.fault==0,s'={...s,scan:0}}
action saveDiagnostic=all{s.scan==1 and s.saved==0 and s.fault==0,s'={...s,saved:1,fault:1,escrow:1}}
action borrowDiagnostic=all{s.saved==1 and s.diagGate==1 and s.diagLease==0 and s.domainLive==1,s'={...s,diagLease:1}}
action returnDiagnostic=all{s.diagLease==1,s'={...s,diagLease:0}}
action closeDiagnostic=all{s.diagGate==1,s'={...s,diagGate:0}}
action unlinkNode=all{s.registered==1 and s.scan==0 and s.fault==0,s'={...s,registered:0}}
action retireDomain=all{s.admission==0 and s.lookup==0 and s.claimed==0 and s.done==1 and s.scan==0 and s.fault==0 and s.registered==0 and s.diagLease==0 and s.diagGate==0 and s.domainLive==1,s'={...s,domainLive:0,retired:1}}
action step=any{enterLookup,claimLookup,failClaim,completeClaim,closeAdmission,rejectLate,beginScan,endScan,saveDiagnostic,borrowDiagnostic,returnDiagnostic,closeDiagnostic,unlinkNode,retireDomain,all{s'=s}}
run normalRoundTest=init.then(enterLookup).then(claimLookup).then(beginScan).then(endScan).then(completeClaim).then(closeAdmission).then(closeDiagnostic).then(unlinkNode).then(retireDomain).then(all{assert(safe),s'=s})
run lateMetadataTest=init.then(enterLookup).then(claimLookup).then(enterLookup).then(completeClaim).then(closeAdmission).then(unlinkNode).then(failClaim).then(closeDiagnostic).then(retireDomain).then(all{assert(safe),s'=s})
run closeBeforeClaimTest=init.then(enterLookup).then(closeAdmission).then(claimLookup).then(beginScan).then(endScan).then(completeClaim).then(closeDiagnostic).then(unlinkNode).then(rejectLate).then(retireDomain).then(all{assert(safe),s'=s})
run faultCustodyTest=init.then(enterLookup).then(claimLookup).then(beginScan).then(saveDiagnostic).then(borrowDiagnostic).then(closeAdmission).then(closeDiagnostic).then(returnDiagnostic).then(all{assert(safe),s'=s})
run nodeBeforeMetadataDrainTest=init.then(enterLookup).then(closeAdmission).then(unlinkNode).then(claimLookup).then(completeClaim).then(closeDiagnostic).then(retireDomain).then(all{assert(safe),s'=s})
}
