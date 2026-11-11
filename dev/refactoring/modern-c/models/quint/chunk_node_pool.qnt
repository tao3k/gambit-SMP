module chunk_node_pool {
 // Aggregate finite-epoch pool. Integers are mathematical, not C machine words.
 type State={phase:int,capacity:int,budget:int,issued:int,privateNodes:int,sealedNodes:int,queued:int,owned:int,done:int,debt:int,receipts:int,borrowers:int,kind:int,rootsClosed:bool,usersClosed:bool,headAttached:bool,admitted:bool,alive:bool}
 pure val initial:State={phase:0,capacity:3,budget:3,issued:0,privateNodes:0,sealedNodes:0,queued:0,owned:0,done:0,debt:0,receipts:0,borrowers:0,kind: -1,rootsClosed:false,usersClosed:false,headAttached:true,admitted:false,alive:true}
 var s:State
 action init=s'=initial
 val safe=all{
 s.phase>=0,s.phase<=5,s.capacity>=0,s.budget>=0,s.issued>=0,s.issued<=s.capacity,s.issued<=s.budget,
 s.privateNodes>=0,s.sealedNodes>=0,s.queued>=0,s.owned>=0,s.done>=0,s.receipts>=0,s.receipts<=s.issued,s.borrowers>=0,
 s.issued==s.privateNodes+s.sealedNodes+s.queued+s.owned+s.done,
 s.debt==s.privateNodes+s.sealedNodes+s.queued+s.owned,
 s.kind>= -1,s.kind<=4,
 s.admitted implies s.capacity>=s.budget,
 (s.phase>=1 and s.phase<=4) implies s.admitted,
 (s.phase==0 or s.phase==5) implies (s.issued==0 and not(s.admitted)),
 (s.phase>=2 and s.phase<=4) implies (s.rootsClosed and s.debt==0),
 s.usersClosed implies (s.phase>=2 and s.phase<=4),
 not(s.headAttached) implies s.usersClosed,
 (s.phase==3 or s.phase==4) implies (s.usersClosed and not(s.headAttached) and s.receipts==0 and s.borrowers==0),
 s.phase!=4 implies s.alive,
 s.phase==4 implies not(s.alive)}
 action admit=all{s.phase==0,s.capacity>=s.budget,s'={...s,phase:1,admitted:true}}
 action reject=all{s.phase==0,s.capacity<s.budget,s'={...s,phase:5}}
 action reserve=all{s.phase==1,not(s.rootsClosed),s.issued<s.budget,s'={...s,issued:s.issued+1,privateNodes:s.privateNodes+1,debt:s.debt+1,receipts:s.receipts+1,kind:4}}
 action derive=all{s.phase==1,s.debt>0,s.issued<s.budget,s'={...s,issued:s.issued+1,privateNodes:s.privateNodes+1,debt:s.debt+1,receipts:s.receipts+1}}
 action seal=all{s.phase==1,s.privateNodes>0,s'={...s,privateNodes:s.privateNodes-1,sealedNodes:s.sealedNodes+1}}
 action publish=all{s.phase==1,s.sealedNodes>0,s'={...s,sealedNodes:s.sealedNodes-1,queued:s.queued+1}}
 action claim=all{s.phase==1,s.queued>0,s'={...s,queued:s.queued-1,owned:s.owned+1}}
 action finish=all{s.phase==1,s.owned>0,s'={...s,owned:s.owned-1,done:s.done+1,debt:s.debt-1}}
 action observe=all{s.phase>=1,s.phase<=2,s.receipts>0,s'={...s,receipts:s.receipts-1}}
 action borrow=all{s.phase==1,s'={...s,borrowers:s.borrowers+1}}
 action returnBorrow=all{s.phase>=1,s.phase<=2,s.borrowers>0,s'={...s,borrowers:s.borrowers-1}}
 action closeRoots=all{s.phase==1,s'={...s,rootsClosed:true}}
 action complete=all{s.phase==1,s.rootsClosed,s.debt==0,s'={...s,phase:2}}
 action closeUsers=all{s.phase==2,s'={...s,usersClosed:true}}
 action detachHead=all{s.phase==2,s.usersClosed,s'={...s,headAttached:false}}
 action certify=all{s.phase==2,s.usersClosed,not(s.headAttached),s.receipts==0,s.borrowers==0,s'={...s,phase:3}}
 action reclaim=all{s.phase==3,s'={...s,phase:4,alive:false}}
 action step=any{admit,reject,reserve,derive,seal,publish,claim,finish,observe,borrow,returnBorrow,closeRoots,complete,closeUsers,detachHead,certify,reclaim,all{s'=s}}
 action scan=seal.then(publish).then(claim).then(finish)
 run fullEpochTest=init.then(admit).then(reserve).then(scan).then(observe).then(closeRoots).then(complete).then(closeUsers).then(detachHead).then(certify).then(reclaim).then(all{assert(safe and s.phase==4),s'=s})
 run childAfterCloseTest=init.then(admit).then(reserve).then(closeRoots).then(derive).then(all{assert(safe and s.debt==2 and s.issued==2),s'=s})
 run retainedFullPoolTest=init.then(admit).then(reserve).then(scan).then(reserve).then(scan).then(reserve).then(scan).then(closeRoots).then(complete).then(all{assert(safe and s.issued==s.capacity and s.debt==0 and s.receipts==3 and s.headAttached),s'=s})
 run retainedStrongEntryTest=init.then(all{s'={...s,phase:1,admitted:true,issued:1,done:1,receipts:1}}).then(reserve).then(scan).then(closeRoots).then(complete).then(all{assert(safe and s.issued==2 and s.done==2 and s.receipts==2),s'=s})
 run rejectBeforeAdmissionTest=init.then(all{s'={...s,capacity:1}}).then(reject).then(all{assert(safe and s.phase==5 and s.issued==0),s'=s})
 run borrowerBlocksReceiptTest=init.then(admit).then(borrow).then(closeRoots).then(complete).then(closeUsers).then(detachHead).then(all{assert(safe and s.borrowers==1 and s.phase==2),s'=s})
 run undersizedAdmissionControlTest=init.then(all{s'={...s,capacity:1}}).then(all{s'={...s,phase:1,admitted:true}}).then(all{assert(not(safe)),s'=s})
 run doubleDebtControlTest=init.then(admit).then(reserve).then(seal).then(publish).then(all{s'={...s,debt:s.debt+1}}).then(all{assert(not(safe)),s'=s})
 run earlyReclaimControlTest=init.then(admit).then(reserve).then(scan).then(closeRoots).then(complete).then(all{s'={...s,phase:4,alive:false}}).then(all{assert(not(safe)),s'=s})
 run lostBorrowerControlTest=init.then(admit).then(borrow).then(closeRoots).then(complete).then(closeUsers).then(detachHead).then(all{s'={...s,phase:3}}).then(all{assert(not(safe)),s'=s})
}
