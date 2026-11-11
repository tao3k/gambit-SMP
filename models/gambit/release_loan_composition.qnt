module release_loan_composition {
  // One wrapper; two independently admitted C calls; token 3 is an exported loan.
  // Atomic transitions assume full-K stable descriptors and existing mapped roots.
  type S={mode:int,bug:int,op:int,closed:bool,vmFree:bool,pin:bool,refs:int,
    entered:Set[int],scopes:Set[int],loans:Set[int],started:Set[int],using:Set[int],
    results:Set[int],ended:Set[int],tails:Set[int],alias:bool,aliasDone:bool,
    busy:bool,callback:bool,calls:int,freed:bool,bad:bool,raw:bool}
  var s:S
  pure def initial(m:int,b:int):S={mode:m,bug:b,op:0,closed:false,vmFree:false,
    pin:true,refs:1,entered:Set(),scopes:Set(),loans:Set(),started:Set(),using:Set(),
    results:Set(),ended:Set(),tails:Set(),alias:false,aliasDone:false,busy:false,
    callback:false,calls:0,freed:false,bad:false,raw:false}
  action initConcurrent=s'=initial(0,0)
  action initExport=s'=initial(1,0)
  action initPrefixFailure=s'=initial(2,0)
  action initSupportedUnwind=s'=initial(3,0)
  action initUnknownCallback=s'=initial(4,0)
  action initRawSnapshot=s'=initial(5,0)
  action initClaimWithLoan=s'=initial(0,1)
  action initEarlyLoanEnd=s'=initial(0,2)
  action initEarlyVmDrop=s'=initial(0,3)
  action initPrefixLeak=s'=initial(2,4)
  action initAliasWithoutLoan=s'=initial(1,5)
  action initDoubleClaim=s'=initial(0,6)
  action initRetryUnknown=s'=initial(4,7)
  action initRawUseAfterRelease=s'=initial(5,8)
  action initCheckThenBorrow=s'=initial(0,9)
  action initWrongUnwindFrame=s'=initial(3,10)
  action initStaleLoanToken=s'=initial(1,11)
  action initLastLoanCallback=s'=initial(0,12)
  action enter={
    nondet i=Set(1,2).oneOf()
    all {not(s.closed),not(s.entered.contains(i)),
    s'={...s,entered:s.entered.union(Set(i)),scopes:s.scopes.union(Set(i)),refs:s.refs+1}}}
  action borrow={
    nondet i=s.scopes.oneOf()
    all {s.op==0,not(s.started.contains(i)),not(s.ended.contains(i)),not(s.loans.contains(i)),
    s'={...s,loans:s.loans.union(Set(i))}}}
  action refused={
    nondet i=s.scopes.oneOf()
    all {s.op!=0,not(s.loans.contains(i)),not(s.started.contains(i)),
    s'={...s,ended:s.ended.union(Set(i))}}}
  action beginCall={
    nondet i=s.loans.exclude(Set(3)).oneOf()
    all {not(s.started.contains(i)),
    s'={...s,started:s.started.union(Set(i)),using:s.using.union(Set(i))}}}
  action result={
    nondet i=s.using.exclude(Set(3)).oneOf()
    all {not(s.results.contains(i)),
    s'={...s,results:s.results.union(Set(i))}}}
  action exportAlias=all {s.mode==1,s.results.contains(1),s.loans.contains(1),not(s.alias),
    s'={...s,alias:true,loans:s.loans.union(Set(3)),using:s.using.union(Set(3)),refs:s.refs+1}}
  action finish={
    nondet i=s.results.oneOf()
    all {s.loans.contains(i),s.mode!=1 or i!=1 or s.alias,
    s'={...s,loans:s.loans.exclude(Set(i)),using:s.using.exclude(Set(i)),ended:s.ended.union(Set(i))}}}
  action prefixOrUnwind=all {s.mode==2 or s.mode==3,s.loans.contains(1),not(s.results.contains(1)),
    s'={...s,loans:s.loans.exclude(Set(1)),using:s.using.exclude(Set(1)),ended:s.ended.union(Set(1))}}
  action completeTail={
    nondet i=s.ended.oneOf()
    all {s.scopes.contains(i),not(s.tails.contains(i)),
    s'={...s,tails:s.tails.union(Set(i))}}}
  action leave={
    nondet i=s.tails.oneOf()
    all {s.scopes.contains(i),
    s'={...s,scopes:s.scopes.exclude(Set(i)),refs:s.refs-1}}}
  action aliasEnd=all {s.alias,not(s.aliasDone),s.loans.contains(3),
    s'={...s,aliasDone:true,loans:s.loans.exclude(Set(3)),using:s.using.exclude(Set(3)),refs:s.refs-1}}
  action explicitBusy=all {s.op==0,s.loans.size()>0,not(s.busy),s'={...s,busy:true}}
  // 0 live,1 drain,2 claimed,3 complete,4 unknown effects retained.
  action closeVm=all {not(s.closed),s'={...s,closed:true}}
  action deferredClose=all {s.closed,s.op==0,s'={...s,op:1}}
  action claim=all {s.op==0 or s.op==1,s.loans.size()==0,s'={...s,op:2}}
  action invoke=all {s.op==2,s.calls==0,s'={...s,callback:true,calls:1}}
  action callbackEnd=all {s.callback,s.mode!=4,
    s'={...s,callback:false,op:3,freed:true,pin:false,refs:s.refs-1}}
  action callbackUnknown=all {s.callback,s.mode==4,
    s'={...s,callback:false,op:4,freed:true}}
  action reclaimVm=all {s.closed,s.refs==0,not(s.vmFree),s'={...s,vmFree:true}}
  action addressSnapshot=all {s.mode==5,s.op==0,not(s.raw),s'={...s,raw:true}}
  action mutant=any {
    all {s.bug==1,s.loans.size()>0,s.op<2,s'={...s,op:2}},
    all {s.bug==2,s.using.contains(1),s.loans.contains(1),s'={...s,loans:s.loans.exclude(Set(1))}},
    all {s.bug==3,s.scopes.contains(1),not(s.tails.contains(1)),s'={...s,scopes:s.scopes.exclude(Set(1)),refs:s.refs-1,bad:true}},
    all {s.bug==4,s.loans.contains(1),not(s.started.contains(1)),s'={...s,ended:s.ended.union(Set(1)),bad:true}},
    all {s.bug==5,s.results.contains(1),not(s.alias),s'={...s,alias:true,using:s.using.union(Set(3))}},
    all {s.bug==6,s.calls==1,s'={...s,calls:2}},
    all {s.bug==7,s.op==4,s'={...s,op:2,calls:0,bad:true}},
    all {s.bug==8,s.raw,s.freed,s'={...s,bad:true}},
    all {s.bug==9,s.scopes.contains(1),s.op>=2,not(s.ended.contains(1)),s'={...s,loans:s.loans.union(Set(1))}},
    all {s.bug==10,s.using.contains(2),s.loans.contains(2),s'={...s,loans:s.loans.exclude(Set(2))}},
    all {s.bug==11,s.alias,s.aliasDone,s'={...s,refs:s.refs-1}},
    all {s.bug==12,s.loans.size()==1,s'={...s,bad:true}}
  }
  action step=any {enter,borrow,refused,beginCall,result,exportAlias,finish,prefixOrUnwind,completeTail,leave,aliasEnd,explicitBusy,closeVm,deferredClose,claim,invoke,callbackEnd,callbackUnknown,reclaimVm,addressSnapshot,mutant}
  val safe=all {not(s.bad),s.calls<=1,s.refs==s.scopes.size()+(if(s.pin) 1 else 0)+(if(s.alias and not(s.aliasDone)) 1 else 0),
    s.using.subseteq(s.loans),s.loans.exclude(Set(3)).subseteq(s.scopes),
    s.op<2 or s.loans.size()==0,not(s.freed) or s.loans.size()==0,
    not(s.vmFree) or (s.closed and s.refs==0),s.ended.intersect(s.loans).size()==0,
    not(s.callback) or (s.op==2 and s.pin),s.op!=4 or s.pin}
}
